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
import { MusicStore } from './MusicStore';

/**
 * 端侧智能歌单：完全基于本地元数据（收藏、播放次数、年份、专辑、歌手）规则聚类，
 * 不联网、不上云，契合 Lumio Music 的隐私优先定位。所有方法在主线程调用（访问 MusicStore 单例）。
 */
export interface SmartPlaylist {
  id: string;
  name: string;
  songs: SongItem[];
}

export class SmartPlaylistService {
  static readonly FAVORITES_MIX: string = 'smart_favorites';
  static readonly RECENT_HEAVY: string = 'smart_recent_heavy';
  static readonly ERA_MIX: string = 'smart_era';
  static readonly DISCOVERY: string = 'smart_discovery';

  static getFavoritesMix(): SmartPlaylist {
    const store: MusicStore = MusicStore.getInstance();
    return { id: SmartPlaylistService.FAVORITES_MIX, name: '我的红心', songs: store.getFavoriteSongs() };
  }

  static getRecentHeavy(limit: number = 30): SmartPlaylist {
    const store: MusicStore = MusicStore.getInstance();
    return { id: SmartPlaylistService.RECENT_HEAVY, name: '最近常听', songs: store.getMostPlayed(limit) };
  }

  static getEraMix(): SmartPlaylist {
    const store: MusicStore = MusicStore.getInstance();
    const byYear: Map<string, SongItem[]> = new Map<string, SongItem[]>();
    store.songs.forEach((s: SongItem) => {
      const y: string = (s.year && s.year.length > 0) ? s.year : '未知年代';
      const arr: SongItem[] = byYear.get(y) ?? [];
      arr.push(s);
      byYear.set(y, arr);
    });
    const picks: SongItem[] = [];
    byYear.forEach((arr: SongItem[]) => {
      picks.push(arr[0]);
    });
    return { id: SmartPlaylistService.ERA_MIX, name: '年代回忆', songs: picks };
  }

  static getDiscovery(limit: number = 30): SmartPlaylist {
    const store: MusicStore = MusicStore.getInstance();
    const favIds: Set<number> = store.favorites;
    const candidates: SongItem[] = store.songs.filter((s: SongItem) => !favIds.has(s.id));
    for (let i = candidates.length - 1; i > 0; i--) {
      const j: number = Math.floor(Math.random() * (i + 1));
      const tmp: SongItem = candidates[i];
      candidates[i] = candidates[j];
      candidates[j] = tmp;
    }
    return { id: SmartPlaylistService.DISCOVERY, name: '发现惊喜', songs: candidates.slice(0, limit) };
  }

  static all(): SmartPlaylist[] {
    return [
      SmartPlaylistService.getFavoritesMix(),
      SmartPlaylistService.getRecentHeavy(),
      SmartPlaylistService.getEraMix(),
      SmartPlaylistService.getDiscovery()
    ];
  }
}
