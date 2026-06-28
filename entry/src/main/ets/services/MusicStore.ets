import { SongItem } from '../models/music';
import { RepeatMode, Playlist } from '../models/music';
import dataPreferences from '@ohos.data.preferences';

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
  public favorites: Set<string> = new Set();
  public playlists: Playlist[] = [];
  public recentlyPlayed: SongItem[] = [];

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
    } catch (err) {
      console.error('Failed to init preferences');
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

  toggleFavorite(songId: string) {
    if (this.favorites.has(songId)) {
      this.favorites.delete(songId);
    } else {
      this.favorites.add(songId);
    }
    this.saveFavorites();
  }

  isFavorite(songId: string): boolean {
    return this.favorites.has(songId);
  }

  addPlaylist(name: string, songIds: string[]): Playlist {
    const playlist: Playlist = {
      id: Date.now().toString(),
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

  getFavoriteSongs(): SongItem[] {
    return this.songs.filter(s => this.favorites.has(s.id));
  }

  removeSong(songId: string) {
    this.songs = this.songs.filter(s => s.id !== songId);
    this.playList = this.playList.filter(s => s.id !== songId);
    this.favorites.delete(songId);
    this.recentlyPlayed = this.recentlyPlayed.filter(s => s.id !== songId);
    this.saveSongs();
    this.saveFavorites();
    this.saveRecentlyPlayed();
  }

  private async loadState(): Promise<void> {
    if (!this.preferences) return;
    try {
      const songsStr = await this.preferences.get(KEY_SONGS, '[]') as string;
      this.songs = JSON.parse(songsStr) as SongItem[];
      this.playList = [...this.songs];

      const favStr = await this.preferences.get(KEY_FAVORITES, '[]') as string;
      const favArr = JSON.parse(favStr) as string[];
      this.favorites = new Set(favArr);

      const recentStr = await this.preferences.get(KEY_RECENTLY_PLAYED, '[]') as string;
      this.recentlyPlayed = JSON.parse(recentStr) as SongItem[];

      const playlistStr = await this.preferences.get(KEY_PLAYLISTS, '[]') as string;
      this.playlists = JSON.parse(playlistStr) as Playlist[];

      const repeatMode = await this.preferences.get(KEY_REPEAT_MODE, 'list') as string;
      this.repeatMode = repeatMode as RepeatMode;

      const currentIndex = await this.preferences.get(KEY_CURRENT_INDEX, 0) as number;
      this.currentIndex = currentIndex;
    } catch (err) {
      console.error('Failed to load state');
    }
  }

  private async saveSongs(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_SONGS, JSON.stringify(this.songs));
      await this.preferences.flush();
    } catch (err) {
      console.error('Failed to save songs');
    }
  }

  private async saveFavorites(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_FAVORITES, JSON.stringify(Array.from(this.favorites)));
      await this.preferences.flush();
    } catch (err) {
      console.error('Failed to save favorites');
    }
  }

  private async saveRecentlyPlayed(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_RECENTLY_PLAYED, JSON.stringify(this.recentlyPlayed));
      await this.preferences.flush();
    } catch (err) {
      console.error('Failed to save recently played');
    }
  }

  private async savePlaylists(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_PLAYLISTS, JSON.stringify(this.playlists));
      await this.preferences.flush();
    } catch (err) {
      console.error('Failed to save playlists');
    }
  }

  private async saveRepeatMode(): Promise<void> {
    if (!this.preferences) return;
    try {
      await this.preferences.put(KEY_REPEAT_MODE, this.repeatMode);
      await this.preferences.flush();
    } catch (err) {
      console.error('Failed to save repeat mode');
    }
  }
}
