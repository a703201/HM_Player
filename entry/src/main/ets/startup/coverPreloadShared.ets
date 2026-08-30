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

/**
 * 封面预热采集共享模块（被 @Sendable 的 LumioCoverPreloadTask 引用）。
 *
 * 重要：ArkTS 的 arkts-sendable-imported-variables 规则要求 @Sendable 类只能捕获
 * 「经 import 引入」的变量，同文件顶层 const / 顶层函数不被视为已导入，会触发编译错误。
 * 因此这里把所有常量、接口与纯函数集中导出，供 LumioCoverPreloadTask 通过 import 引用，
 * 使其成为合法的「导入变量」。
 *
 * 这些纯函数不捕获任何外部可变状态，仅用 C 风格 for 循环 + 线性扫描，可在 taskPool 线程安全调用。
 */

export const PREF_NAME = 'music_store';
export const KEY_SONGS = 'songs';
export const KEY_FAVORITES = 'favorites';
export const KEY_RECENTLY_PLAYED = 'recently_played';
export const KEY_PLAYLISTS = 'playlists';
export const APP_STORAGE_KEY = 'highFreqCoverSrcs';
export const MAX_PER_PLAYLIST = 5;
export const MAX_TOTAL = 200;

export interface SongDataLite {
  id: number;
  src: string;
}

export interface PlaylistLite {
  id: string;
  songIds: number[];
}

export interface PrewarmResult {
  candidates: number;
  validated: number;
}

// 线性扫描判断 id 是否已出现在去重列表（避开 Set / for...of）
export function isSeenId(seenIds: number[], id: number): boolean {
  for (let k = 0; k < seenIds.length; k++) {
    if (seenIds[k] === id) {
      return true;
    }
  }
  return false;
}

// 去重保序插入：已存在则跳过；id 非法（undefined/null）则跳过
export function addUniqueId(seenIds: number[], orderedIds: number[], id: number): void {
  if (id === undefined || id === null) {
    return;
  }
  if (isSeenId(seenIds, id)) {
    return;
  }
  seenIds.push(id);
  orderedIds.push(id);
}
