/*
 * Copyright 2026 何宇翔
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { StartupTask, Context } from '@kit.AbilityKit';
import dataPreferences from '@ohos.data.preferences';
import { fileIo } from '@kit.CoreFileKit';
// 共享常量 / 接口 / 纯函数：经 import 引入后，方可在 @Sendable 类内作为「导入变量」安全引用
import {
  PREF_NAME,
  KEY_SONGS,
  KEY_FAVORITES,
  KEY_RECENTLY_PLAYED,
  KEY_PLAYLISTS,
  APP_STORAGE_KEY,
  MAX_PER_PLAYLIST,
  MAX_TOTAL,
  SongDataLite,
  PlaylistLite,
  PrewarmResult,
  addUniqueId
} from './coverPreloadShared';

/**
 * AppStartup 启动任务（方向 B）：
 * 在 taskPool 上并行做"可序列化"的数据采集——读 music_store preferences 解析出
 * 「高频」歌曲 src 列表（收藏 + 最近播放 + 各歌单前 N 首，去重保序），再用
 * fileIo.accessSync 在 worker 线程同步校验文件存在性，过滤掉已删除的歌曲，
 * 最后把校验后的 src 列表写入 sendable AppStorage。
 *
 * 主线程（EntryAbility.initStore）随后读取这份 AppStorage 作为优先预热清单，
 * 先跑 CoverCache.preload(高频子集)，再跑全量；CoverCache 单例（非 sendable，
 * 持有 PixelMap Map）只在主线程访问。
 *
 * 约束：
 * - 所有常量 / 纯函数均来自 import 的 coverPreloadShared 模块（满足 arkts-sendable-imported-variables）。
 * - 不使用 Map/Set（在 @Sendable 上下文有约束），改用并行数组 + 线性扫描。
 * - 不用 for...of，统一用 C 风格 for (let i=0; i<arr.length; i++)。
 * - 不用解构、any、unknown、内联对象字面量类型。
 * - 不触碰项目单例（MusicStore / CoverCache），不调用 Logger 等全局类。
 * - 异常一律静默吞掉，启动关键路径不能崩；最终 AppStorage 写空数组即视为"无数据"。
 */

@Sendable
export default class LumioCoverPreloadTask extends StartupTask {
  override async init(context: Context): Promise<Object | void> {
    const result: PrewarmResult = { candidates: 0, validated: 0 };
    const validated: string[] = [];
    try {
      const prefs = await dataPreferences.getPreferences(context, PREF_NAME);
      const songsStr = await prefs.get(KEY_SONGS, '[]') as string;
      const favStr = await prefs.get(KEY_FAVORITES, '[]') as string;
      const recentStr = await prefs.get(KEY_RECENTLY_PLAYED, '[]') as string;
      const playlistStr = await prefs.get(KEY_PLAYLISTS, '[]') as string;
      const songsData: SongDataLite[] = JSON.parse(songsStr) as SongDataLite[];
      const favArr: number[] = JSON.parse(favStr) as number[];
      const recentData: SongDataLite[] = JSON.parse(recentStr) as SongDataLite[];
      const playlistsRaw: PlaylistLite[] = JSON.parse(playlistStr) as PlaylistLite[];

      // 构造去重保序的 id 列表：收藏 > 最近播放 > 各歌单前 N 首
      // addUniqueId 是经 import 引入的纯函数，在 @Sendable 上下文可安全调用
      const orderedIds: number[] = [];
      const seenIds: number[] = [];
      for (let i = 0; i < favArr.length && orderedIds.length < MAX_TOTAL; i++) {
        addUniqueId(seenIds, orderedIds, favArr[i]);
      }
      for (let i = 0; i < recentData.length && orderedIds.length < MAX_TOTAL; i++) {
        const s: SongDataLite = recentData[i];
        if (s !== undefined && s !== null) {
          addUniqueId(seenIds, orderedIds, s.id);
        }
      }
      const playlists: PlaylistLite[] = Array.isArray(playlistsRaw) ? playlistsRaw : [];
      for (let i = 0; i < playlists.length && orderedIds.length < MAX_TOTAL; i++) {
        const pl: PlaylistLite = playlists[i];
        if (pl === undefined || pl === null) {
          continue;
        }
        const ids: number[] = Array.isArray(pl.songIds) ? pl.songIds : [];
        for (let j = 0; j < ids.length && j < MAX_PER_PLAYLIST && orderedIds.length < MAX_TOTAL; j++) {
          addUniqueId(seenIds, orderedIds, ids[j]);
        }
      }
      result.candidates = orderedIds.length;

      // id -> src：扫描 songsData（sendable 安全，避免 Map）
      const candidateSrcs: string[] = [];
      for (let i = 0; i < orderedIds.length; i++) {
        const id: number = orderedIds[i];
        let foundSrc: string = '';
        for (let m = 0; m < songsData.length; m++) {
          const s: SongDataLite = songsData[m];
          if (s !== undefined && s !== null && s.id === id) {
            foundSrc = s.src;
            break;
          }
        }
        if (foundSrc.length > 0) {
          candidateSrcs.push(foundSrc);
        }
      }

      // worker 线程同步校验文件存在：避免主线程 CoverCache 抽取时撞到已删歌曲
      for (let i = 0; i < candidateSrcs.length; i++) {
        const src: string = candidateSrcs[i];
        try {
          if (fileIo.accessSync(src)) {
            validated.push(src);
          }
        } catch (_) {
          // 跳过不可访问/已删除的歌曲
        }
      }
      result.validated = validated.length;
    } catch (_) {
      // 静默：启动关键路径不能崩；空 manifest 由主线程兜底
    }
    try {
      // 写回 sendable 安全的 AppStorage；若 taskPool 线程不可用 AppStorage，静默回退到主线程实时计算
      AppStorage.setOrCreate<string[]>(APP_STORAGE_KEY, validated);
    } catch (_) {
      // 主线程 EntryAbility.initStore 会检测到 highFreqCoverSrcs 为空，回退 store.getHighFrequencySongSrcs()
    }
    return result;
  }
}
