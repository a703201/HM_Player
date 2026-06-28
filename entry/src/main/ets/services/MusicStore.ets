import { SongItem } from '../models/music';
import { RepeatMode, Playlist } from '../models/music';

export class MusicStore {
  private static instance: MusicStore | null = null;

  public songs: SongItem[] = [];
  public playList: SongItem[] = [];
  public currentIndex: number = 0;
  public isPlaying: boolean = false;
  public repeatMode: RepeatMode = 'list';
  public favorites: Set<string> = new Set();
  public playlists: Playlist[] = [];
  public recentlyPlayed: SongItem[] = [];

  private constructor() {
    this.loadState();
  }

  static getInstance(): MusicStore {
    if (!MusicStore.instance) {
      MusicStore.instance = new MusicStore();
    }
    return MusicStore.instance;
  }

  setSongs(songs: SongItem[]) {
    this.songs = songs;
    this.playList = [...songs];
  }

  setCurrentIndex(index: number) {
    this.currentIndex = index;
  }

  setIsPlaying(isPlaying: boolean) {
    this.isPlaying = isPlaying;
  }

  setRepeatMode(mode: RepeatMode) {
    this.repeatMode = mode;
  }

  toggleFavorite(songId: string) {
    if (this.favorites.has(songId)) {
      this.favorites.delete(songId);
    } else {
      this.favorites.add(songId);
    }
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
    return playlist;
  }

  deletePlaylist(id: string) {
    this.playlists = this.playlists.filter(p => p.id !== id);
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
  }

  getRecentlyPlayed(): SongItem[] {
    return this.recentlyPlayed;
  }

  getFavoriteSongs(): SongItem[] {
    return this.songs.filter(s => this.favorites.has(s.id));
  }

  private loadState() {
    this.favorites = new Set();
    this.playlists = [];
    this.recentlyPlayed = [];
  }
}
