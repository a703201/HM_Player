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

import { SongItem } from '../models/music';

/**
 * 重复歌曲检测：基于归一化标题 + 歌手相似度聚类，纯本地、无网络依赖。
 * 用于「清理重复」场景，识别同名/近似同名的不同文件（例如不同码率副本）。
 */
export interface DuplicateGroup {
  key: string;
  songs: SongItem[];
}

export class DuplicateDetector {
  static normalizeTitle(title: string): string {
    return (title ?? '')
      .toLowerCase()
      .replace(/[\s\-_()\[\]【】（），。、！？!?.,~]+/g, '')
      .replace(/^(the|a|an)\s+/, '');
  }

  static similarity(a: string, b: string): number {
    const m: number = a.length;
    const n: number = b.length;
    if (m === 0 && n === 0) {
      return 1;
    }
    if (m === 0 || n === 0) {
      return 0;
    }
    const dp: number[][] = [];
    for (let i = 0; i <= m; i++) {
      dp[i] = [i];
    }
    for (let j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (let i = 1; i <= m; i++) {
      for (let j = 1; j <= n; j++) {
        const cost: number = a.charAt(i - 1) === b.charAt(j - 1) ? 0 : 1;
        const v1: number = dp[i - 1][j] + 1;
        const v2: number = dp[i][j - 1] + 1;
        const v3: number = dp[i - 1][j - 1] + cost;
        dp[i][j] = Math.min(v1, v2, v3);
      }
    }
    const dist: number = dp[m][n];
    return 1 - dist / Math.max(m, n);
  }

  static sameTitle(a: SongItem, b: SongItem): boolean {
    if (!a || !b) {
      return false;
    }
    const ta: string = DuplicateDetector.normalizeTitle(a.title);
    const tb: string = DuplicateDetector.normalizeTitle(b.title);
    if (ta.length === 0 || tb.length === 0) {
      return false;
    }
    if (ta === tb) {
      return true;
    }
    return DuplicateDetector.similarity(ta, tb) >= 0.85;
  }

  static findDuplicates(songs: SongItem[]): DuplicateGroup[] {
    const groups: DuplicateGroup[] = [];
    const used: Set<number> = new Set<number>();
    for (let i = 0; i < songs.length; i++) {
      const a: SongItem = songs[i];
      if (used.has(a.id)) {
        continue;
      }
      const grp: SongItem[] = [a];
      for (let j = i + 1; j < songs.length; j++) {
        const b: SongItem = songs[j];
        if (used.has(b.id)) {
          continue;
        }
        if (a.singer && b.singer && a.singer !== b.singer) {
          continue;
        }
        if (DuplicateDetector.sameTitle(a, b)) {
          grp.push(b);
          used.add(b.id);
        }
      }
      used.add(a.id);
      if (grp.length > 1) {
        groups.push({ key: DuplicateDetector.normalizeTitle(a.title), songs: grp });
      }
    }
    return groups;
  }
}
