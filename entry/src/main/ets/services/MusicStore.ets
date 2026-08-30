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

import { Logger } from '../utils/Logger';
import { CoverCache } from '../utils/CoverCache';
import { EmbeddedLyricReader } from '../utils/EmbeddedLyricReader';
import { AudioMetaReader } from '../utils/AudioMeta';
import { SongItem } from '../models/music';
import { RepeatMode, Playlist } from '../models/music';
import dataPreferences from '@ohos.data.preferences';

interface SongData {
  id: number;
  title: string;
  singer: string;
  src: string;
  index: number;
  album?: string;
  author?: string;
  year?: string;
  lyric?: string;
}

const PREF_NAME = 'music_store';
const KEY_SONGS = 'songs';
const KEY_FAVORITES = 'favorites';
const KEY_RECENTLY_PLAYED = 'recently_played';
const KEY_PLAYLISTS = 'playlists';
const KEY_REPEAT_MODE = 'repeat_mode';
const KEY_CURRENT_INDEX = 'current_index';

export class MusicStore {
  private static instance: MusicStore | null = null;
  private preferences: dataPreferences.Preferences | null = null;

  public songs: SongItem[] = [];
  public playList: SongItem[] = [];
  public currentIndex: number = 0;
  public isPlaying: boolean = false;
  public repeatMode: RepeatMode = 'list';
  public favorites: Set<number> = new Set();
  public playlists: Playlist[] = [];
  public recentlyPlayed: SongItem[] = [];
  /** 持久化加载失败标记：页面据此展示错误态+重试按钮 */
  public loadError: boolean = false;

  private constructor() {
  }

  static getInstance(): MusicStore {
    if (!MusicStore.instance) {
      MusicStore.instance = new MusicStore();
    }
    return MusicStore.instance;
  }

  async init(context: Context): Promise<void> {
    try {
      this.preferences = await dataPreferences.getPreferences(context, PREF_NAME);
      await this.loadState();
      this.loadError = false;
    } catch (err) {
      this.loadError = true;
      Logger.error('Failed to init preferences');
    }
  }

  setSongs(songs: SongItem[]) {
    this.songs = songs;
    this.playList = [...songs];
    this.saveSongs();
  }

  setCurrentIndex(index: number) {
    this.currentIndex = index;
  }

  setIsPlaying(isPlaying: boolean) {
    this.isPlaying = isPlaying;
  }

  setRepeatMode(mode: RepeatMode) {
    this.repeatMode = mode;
    this.saveRepeatMode();
  }

  toggleFavorite(songId: number) {
    if (this.favorites.has(songId)) {
      this.favorites.delete(songId);
    } else {
      this.favorites.add(songId);
    }
    this.saveFavorites();
  }

  isFavorite(songId: number): boolean {
    return this.favorites.has(songId);
  }

  addPlaylist(name: string, songIds: number[]): Playlist {
    const playlist: Playlist = {
      // P2-3：同一毫秒内连续创建会产生重复 id，deletePlaylist 会一次删掉两个；加随机后缀
      id: `${Date.now()}_${Math.floor(Math.random() * 1e6)}`,
      name: name,
      songIds: songIds
    };
    this.playlists.push(playlist);
    this.savePlaylists();
    return playlist;
  }

  deletePlaylist(id: string) {
    this.playlists = this.playlists.filter(p => p.id !== id);
    this.savePlaylists();
  }

  getPlaylistSongs(playlist: Playlist): SongItem[] {
    return this.songs.filter(s => playlist.songIds.includes(s.id));
  }

  /**
   * 按 id 取歌单。歌单页与详情页之间只传 id，避免传对象副本导致的状态不同步。
   */
  getPlaylistById(id: string): Playlist | undefined {
    return this.playlists.find(p => p.id === id);
  }

  /**
   * 歌单是否已存在同名项（创建/重命名时做去重校验）。
   */
  hasPlaylistName(name: string, excludeId: string = ''): boolean {
    const target: string = name.trim();
    return this.playlists.some(p => p.id !== excludeId && p.name === target);
  }

  renamePlaylist(id: string, name: string): void {
    const target: Playlist | undefined = this.playlists.find(p => p.id === id);
    if (!target) {
      return;
    }
    target.name = name.trim();
    this.savePlaylists();
  }

  /**
   * 向歌单批量追加歌曲，自动去重并保持原有顺序。
   * @returns 实际新增条数
   */
  addSongsToPlaylist(playlistId: string, songIds: number[]): number {
    const target: Playlist | undefined = this.playlists.find(p => p.id === playlistId);
    if (!target) {
      return 0;
    }
    const existing: Set<number> = new Set<number>(target.songIds);
    let added: number = 0;
    songIds.forEach((id: number) => {
      if (!existing.has(id)) {
        existing.add(id);
        target.songIds.push(id);
        added++;
      }
    });
    if (added > 0) {
      this.savePlaylists();
    }
    return added;
  }

  removeSongFromPlaylist(playlistId: string, songId: number): void {
    const target: Playlist | undefined = this.playlists.find(p => p.id === playlistId);
    if (!target) {
      return;
    }
    const before: number = target.songIds.length;
    target.songIds = target.songIds.filter(id => id !== songId);
    if (target.songIds.length !== before) {
      this.savePlaylists();
    }
  }

  /**
   * 歌单内歌曲拖拽排序：将 songIds 中 from 位置移动到 to 位置（FR-24）。
   * 直接操作权威数据数组并持久化，页面按 songIds 顺序渲染即可联动刷新。
   */
  reorderPlaylistSongs(playlistId: string, from: number, to: number): void {
    const target: Playlist | undefined = this.playlists.find(p => p.id === playlistId);
    if (!target) {
      return;
    }
    const ids: number[] = target.songIds;
    if (from < 0 || from >= ids.length || to < 0 || to > ids.length || from === to) {
      return;
    }
    const removed: number[] = ids.splice(from, 1);
    const moved: number = removed[0];
    ids.splice(to, 0, moved);
    this.savePlaylists();
  }

  addToRecentlyPlayed(song: SongItem) {
    this.recentlyPlayed = this.recentlyPlayed.filter(s => s.id !== song.id);
    this.recentlyPlayed.unshift(song);
    if (this.recentlyPlayed.length > 50) {
      this.recentlyPlayed = this.recentlyPlayed.slice(0, 50);
    }
    this.saveRecentlyPlayed();
  }

  getRecentlyPlayed(): SongItem[] {
    return this.recentlyPlayed;
  }

  /**
   * 取「高频」歌曲 src 列表：收藏 + 最近播放 + 各歌单前 N 首，去重保序，上限 totalLimit。
   * 主线程专用（非 sendable）——EntryAbility 启动预热的回退路径，当
   * LumioCoverPreloadTask（taskPool 异步）尚未把 AppStorage('highFreqCoverSrcs') 写好时使用。
   * 与 task 内同名逻辑保持一致，便于两路结果互为兜底。
   */
  getHighFrequencySongSrcs(perPlaylistLimit: number = 5, totalLimit: number = 200): string[] {
    const idToSrc: Map<number, string> = new Map<number, string>();
    for (let i = 0; i < this.songs.length; i++) {
      const s: SongItem = this.songs[i];
      idToSrc.set(s.id, s.src);
    }
    const orderedIds: number[] = [];
    const seen: Set<number> = new Set<number>();
    const pushId = (id: number): void => {
      if (id === undefined || id === null) {
        return;
      }
      if (seen.has(id) || !idToSrc.has(id)) {
        return;
      }
      seen.add(id);
      orderedIds.push(id);
    };
    const favArr: number[] = Array.from(this.favorites);
    for (let i = 0; i < favArr.length && orderedIds.length < totalLimit; i++) {
      pushId(favArr[i]);
    }
    for (let i = 0; i < this.recentlyPlayed.length && orderedIds.length < totalLimit; i++) {
      pushId(this.recentlyPlayed[i].id);
    }
    for (let i = 0; i < this.playlists.length && orderedIds.length < totalLimit; i++) {
      const pl: Playlist = this.playlists[i];
      const ids: number[] = pl.songIds;
      for (let j = 0; j < ids.length && j < perPlaylistLimit && orderedIds.length < totalLimit; j++) {
        pushId(ids[j]);
      }
    }
    const out: string[] = [];
    for (let i = 0; i < orderedIds.length; i++) {
      const src: string | undefined = idToSrc.get(orderedIds[i]);
      if (src !== undefined) {
        out.push(src);
      }
    }
    return out;
  }

  getFavoriteSongs(): SongItem[] {
    return this.songs.filter(s => this.favorites.has(s.id));
  }

  clearRecentlyPlayed() {
    this.recentlyPlayed = [];
    this.saveRecentlyPlayed();
  }

  removeSong(songId: number) {
    // 先取出 src 再过滤，顺带清掉封面 / 歌词缓存，避免删歌后仍占内存
    const removed: SongItem | undefined = this.songs.find(s => s.id === songId);
    if (removed && removed.src) {
      CoverCache.getInstance().evict(removed.src);
      EmbeddedLyricReader.evict(removed.src);
    }
    this.songs = this.songs.filter(s => s.id !== songId);
    this.playList = this.playList.filter(s => s.id !== songId);
    this.favorites.delete(songId);
    this.recentlyPlayed = this.recentlyPlayed.filter(s => s.id !== songId);
    // 同步清理自建歌单中的悬挂引用，避免删歌后歌单数量虚高
    let playlistChanged: boolean = false;
    this.playlists.forEach((p: Playlist) => {
      const before: number = p.songIds.length;
      p.songIds = p.songIds.filter(id => id !== songId);
      if (p.songIds.length !== before) {
        playlistChanged = true;
      }
    });
    this.saveSongs();
    this.saveFavorites();
    this.saveRecentlyPlayed();
    if (playlistChanged) {
      this.savePlaylists();
    }
  }

  /**
   * 一次性补扫已入库歌曲的文本元数据（标题 / 艺术家 / 专辑 / 作者）。
   * 历史版本导入时未读取元数据，导致「未知艺术家」等问题；升级后用本方法在
   * 首次启动时补扫一次，之后通过偏好标记跳过，避免每次启动都做 I/O。
   */
  async refreshMetadataIfNeeded(): Promise<void> {
    if (!this.preferences) {
      return;
    }
    let scanned: boolean = false;
    try {
      scanned = await this.preferences.get('meta_scanned_v1', false) as boolean;
    } catch (e) {
      scanned = false;
    }
    if (scanned) {
      return;
    }
    let changed: boolean = false;
    for (const song of this.songs) {
      const meta = await AudioMetaReader.read(song.src);
      if (meta) {
        if (meta.title && meta.title.trim().length > 0) {
          song.title = meta.title;
          changed = true;
        }
        if (meta.artist && meta.artist.trim().length > 0) {
          song.singer = meta.artist;
          changed = true;
        }
        if (meta.album) {
          song.album = meta.album;
          changed = true;
        }
        if (meta.author) {
          song.author = meta.author;
          changed = true;
        }
        // 发行年份：一次性补扫路径也回填，保证历史入库歌曲升级后可直读 SongItem.year
        if (meta.year && meta.year.trim().length > 0) {
          song.year = meta.year;
          changed = true;
        }
      }
    }
    if (changed) {
      this.saveSongs();
    }
    try {
      await this.preferences.put('meta_scanned_v1', true);
      await this.preferences.flush();
    } catch (e) {
      Logger.error('Failed to mark metadata scanned');
    }
  }

  private async loadState(): Promise<void> {
    if (!this.preferences) return;
    this.loadError = false;
    try {
      const songsStr = await this.preferences.get(KEY_SONGS, '[]') as string;
      const songsData = JSON.parse(songsStr) as SongData[];
      this.songs = songsData.map((data) => {
        const song = new SongItem();
        song.id = data.id;
        song.title = data.title;
        song.singer = data.singer;
        song.src = data.src;
        song.index = data.index;
        song.album = data.album ?? '';
        song.author = data.author ?? '';
        song.year = data.year ?? '';
        song.lyric = data.lyric ?? '';
        return song;
      });
      this.playList = [...this.songs];

      const favStr = await this.preferences.get(KEY_FAVORITES, '[]') as string;
      const favArr = JSON.parse(favStr) as number[];
      this.favorites = new Set(favArr);

      const recentStr = await this.preferences.get(KEY_RECENTLY_PLAYED, '[]') as string;
      const recentData = JSON.parse(recentStr) as SongData[];
      this.recentlyPlayed = recentData.map((data) => {
        const song = new SongItem();
        song.id = data.id;
        song.title = data.title;
        song.singer = data.singer;
        song.src = data.src;
        song.index = data.index;
        song.album = data.album ?? '';
        song.author = data.author ?? '';
        song.year = data.year ?? '';
        song.lyric = data.lyric ?? '';
        return song;
      });

      const playlistStr = await this.preferences.get(KEY_PLAYLISTS, '[]') as string;
      // P1-10：反序列化做字段校验，脏数据（缺 id / songIds）不进内存，避免 build() 内取 .length 崩
      const rawPlaylists = JSON.parse(playlistStr) as Playlist[];
      this.playlists = (Array.isArray(rawPlaylists) ? rawPlaylists : [])
        .filter((p: Playlist) => p !== null && p !== undefined && typeof p.id === 'string')
        .map((p: Playlist) => {
          const item: Playlist = {
            id: p.id,
            name: p.name ?? '未命名歌单',
            songIds: Array.isArray(p.songIds)
              ? p.songIds.filter((n: number) => typeof n === 'number')
              : []
          };
          return item;
        });

      const repeatMode = await this.preferences.get(KEY_REPEAT_MODE, 'list') as string;
      this.repeatMode = repeatMode as RepeatMode;

      const currentIndex = await this.preferences.get(KEY_CURRENT_INDEX, 0) as number;
      this.currentIndex = currentIndex;
    } catch (err) {
      this.loadError = true;
      Logger.error('Failed to load state');
    }
  }

  private async saveSongs(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_SONGS, JSON.stringify(this.songs));
      await this.preferences.flush();
    } catch (err) {
      Logger.error('Failed to save songs');
    }
  }

  private async saveFavorites(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_FAVORITES, JSON.stringify(Array.from(this.favorites)));
      await this.preferences.flush();
    } catch (err) {
      Logger.error('Failed to save favorites');
    }
  }

  private async saveRecentlyPlayed(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_RECENTLY_PLAYED, JSON.stringify(this.recentlyPlayed));
      await this.preferences.flush();
    } catch (err) {
      Logger.error('Failed to save recently played');
    }
  }

  private async savePlaylists(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_PLAYLISTS, JSON.stringify(this.playlists));
      await this.preferences.flush();
    } catch (err) {
      Logger.error('Failed to save playlists');
    }
  }

  private async saveRepeatMode(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_REPEAT_MODE, this.repeatMode);
      await this.preferences.flush();
    } catch (err) {
      Logger.error('Failed to save repeat mode');
    }
  }
}
