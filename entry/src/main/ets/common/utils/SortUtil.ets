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

import { SongItem } from '../../models/music';

/**
 * 歌曲列表排序公共工具（B3）。
 * 由播放队列面板（ControlAreaComponent）与曲库页（LocalLibrary）共用，
 * 保证两处排序语义一致；不修改入参，总是返回新数组。
 *
 * mode 约定（数值与既有队列面板保持一致，专辑为新增 5）：
 * - 0 默认：保持入参顺序（曲库页=库内顺序；队列面板=曲库顺序）
 * - 1 标题：按 title 中文 locale 排序
 * - 2 歌手：按 singer 中文 locale 排序
 * - 3 最近播放：按 recentlyPlayed 中的先后（越新越靠前）
 * - 4 随机：Fisher-Yates 原地洗牌
 * - 5 专辑：按 album 中文 locale 排序
 */
export function sortSongs(songs: SongItem[], mode: number, recentlyPlayed: SongItem[]): SongItem[] {
  if (!songs) {
    return [];
  }
  switch (mode) {
    case 1:
      return [...songs].sort((a: SongItem, b: SongItem) => a.title.localeCompare(b.title, 'zh'));
    case 2:
      return [...songs].sort((a: SongItem, b: SongItem) => a.singer.localeCompare(b.singer, 'zh'));
    case 3: {
      const order: Map<number, number> = new Map<number, number>();
      recentlyPlayed.forEach((s: SongItem, i: number) => {
        order.set(s.id, i);
      });
      return [...songs].sort((a: SongItem, b: SongItem) => {
        const ia: number = order.has(a.id) ? order.get(a.id)! : Number.MAX_SAFE_INTEGER;
        const ib: number = order.has(b.id) ? order.get(b.id)! : Number.MAX_SAFE_INTEGER;
        return ia - ib;
      });
    }
    case 4: {
      const sorted: SongItem[] = [...songs];
      for (let i: number = sorted.length - 1; i > 0; i--) {
        const j: number = Math.floor(Math.random() * (i + 1));
        const tmp: SongItem = sorted[i];
        sorted[i] = sorted[j];
        sorted[j] = tmp;
      }
      return sorted;
    }
    case 5:
      return [...songs].sort((a: SongItem, b: SongItem) => a.album.localeCompare(b.album, 'zh'));
    default:
      return [...songs];
  }
}
