import { SongItem } from '../models/music';
import { SongItem as PlaySongItem } from '../songdatacontroller/SongData';
import { MusicStore } from '../services/MusicStore';
import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { BreakpointSystem } from '../common/utils/BreakpointSystem';
import { PlayerInfoComponent } from '../components/PlayerInfoComponent';

@Builder
export function PlayerPageBuilder() {
  PlayerPage();
}

@Entry
@Component
struct PlayerPage {
  @StorageLink('navPathStack') pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  @State isPlaying: boolean = false;
  @State currentTime: number = 0;
  @State duration: number = 0;
  @State avPlayer: media.AVPlayer | null = null;
  @State timerTimer: number = -1;
  @State isShowPlay: boolean = false;
  @StorageProp(BreakpointConstants.CURRENT_BREAKPOINT) currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  async aboutToAppear(): Promise<void> {
    this.syncSongList();
    this.breakpointSystem.register();
    await this.initPlayer();
    this.startProgressTimer();
  }

  aboutToDisappear(): void {
    this.breakpointSystem.unregister();
    this.stopProgressTimer();
    this.releasePlayer();
  }

  syncSongList(): void {
    const list: SongItem[] = this.store.playList.length > 0 ? [...this.store.playList] : [];
    AppStorage.setOrCreate('songList', this.convertSongList(list));
    AppStorage.setOrCreate('selectIndex', this.store.currentIndex);
    AppStorage.setOrCreate('isPlay', this.store.isPlaying);
    AppStorage.setOrCreate('isFavorite', this.store.isFavorite(
      this.store.playList.length > 0 ? this.store.playList[this.store.currentIndex]?.id : ''
    ));
  }

  convertSongList(songs: SongItem[]): PlaySongItem[] {
    return songs.map((song, index) => ({
      id: index,
      title: song.title,
      singer: song.artist,
      mark: $r('app.media.ic_sq'),
      label: $r('app.media.QQ1'),
      src: song.uri,
      index: index,
      lyric: '',
      isDarkBackground: true
    } as PlaySongItem));
  }

  private async initPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      if (this.avPlayer) {
        this.avPlayer.on('stateChange', (state: string) => {
          if (state === 'completed') {
            this.playNext();
          }
        });
        this.avPlayer.on('error', (err: BusinessError) => {
          console.error(`AVPlayer error: ${err.code} - ${err.message}`);
        });
        this.avPlayer.on('timeUpdate', (time: number) => {
          this.currentTime = time;
          AppStorage.setOrCreate('progress', time);
          AppStorage.setOrCreate('currentTime', this.formatTime(time));
        });
        this.avPlayer.on('durationUpdate', (dur: number) => {
          this.duration = dur;
          AppStorage.setOrCreate('progressMax', dur);
          AppStorage.setOrCreate('totalTime', this.formatTime(dur));
        });
      }
      if (this.store.playList.length > 0) {
        await this.playCurrentTrack();
      }
    } catch (err) {
      const e = err as BusinessError;
      console.error(`initPlayer failed: ${e.message}`);
    }
  }

  private async playCurrentTrack(): Promise<void> {
    if (!this.avPlayer || this.store.playList.length === 0) return;
    const song = this.store.playList[this.store.currentIndex];
    if (!song) return;
    try {
      await this.avPlayer.stop();
      await this.avPlayer.reset();
      this.avPlayer.fdSrc = { fd: await this.openFd(song.uri) };
      await this.avPlayer.prepare();
      await this.avPlayer.play();
      this.isPlaying = true;
      AppStorage.setOrCreate('isPlay', true);
      AppStorage.setOrCreate('selectIndex', this.store.currentIndex);
      AppStorage.setOrCreate('isFavorite', this.store.isFavorite(song.id));
      this.store.setIsPlaying(true);
      this.store.addToRecentlyPlayed(song);
      this.syncSongList();
    } catch (err) {
      const e = err as BusinessError;
      console.error(`playCurrentTrack failed: ${e.message}`);
    }
  }

  private async openFd(uri: string): Promise<number> {
    try {
      const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      return file.fd;
    } catch {
      return -1;
    }
  }

  private async togglePlayPause(): Promise<void> {
    if (this.isPlaying) {
      if (this.avPlayer) {
        try {
          await this.avPlayer.pause();
          this.isPlaying = false;
          AppStorage.setOrCreate('isPlay', false);
          this.store.setIsPlaying(false);
        } catch (err) {}
      }
    } else {
      await this.playCurrentTrack();
    }
  }

  private async playNext(): Promise<void> {
    if (this.store.playList.length === 0) return;
    let nextIndex: number;
    switch (this.store.repeatMode) {
      case 'single': nextIndex = this.store.currentIndex; break;
      case 'list': nextIndex = (this.store.currentIndex + 1) % this.store.playList.length; break;
      case 'none':
      default:
        nextIndex = this.store.currentIndex + 1;
        if (nextIndex >= this.store.playList.length) {
          nextIndex = this.store.playList.length - 1;
          this.isPlaying = false;
          AppStorage.setOrCreate('isPlay', false);
          this.store.setIsPlaying(false);
        }
        break;
    }
    await this.playTrack(nextIndex);
  }

  private async playPrevious(): Promise<void> {
    if (this.store.playList.length === 0) return;
    if (this.currentTime > 3000) {
      await this.playTrack(this.store.currentIndex);
      return;
    }
    let prevIndex: number;
    switch (this.store.repeatMode) {
      case 'single': prevIndex = this.store.currentIndex; break;
      case 'list': prevIndex = (this.store.currentIndex - 1 + this.store.playList.length) % this.store.playList.length; break;
      case 'none':
      default:
        prevIndex = this.store.currentIndex - 1;
        if (prevIndex < 0) prevIndex = 0;
        break;
    }
    await this.playTrack(prevIndex);
  }

  private async playTrack(index: number): Promise<void> {
    if (index < 0 || index >= this.store.playList.length) return;
    this.store.currentIndex = index;
    this.isPlaying = false;
    this.currentTime = 0;
    AppStorage.setOrCreate('progress', 0);
    AppStorage.setOrCreate('selectIndex', index);
    this.syncSongList();
    await this.playCurrentTrack();
  }

  private async seekTo(position: number): Promise<void> {
    if (!this.avPlayer) return;
    try {
      this.avPlayer.seek(position, media.SeekMode.SEEK_CLOSEST);
      this.currentTime = position;
      AppStorage.setOrCreate('progress', position);
    } catch (err) {}
  }

  private releasePlayer(): void {
    if (this.avPlayer) {
      try { this.avPlayer.stop(); } catch (err) {}
      try { this.avPlayer.release(); } catch (err) {}
      this.avPlayer = null;
    }
  }

  private formatTime(ms: number): string {
    if (ms <= 0) return '0:00';
    const totalSeconds = Math.floor(ms / 1000);
    return `${Math.floor(totalSeconds / 60)}:${(totalSeconds % 60).toString().padStart(2, '0')}`;
  }

  private startProgressTimer(): void {
    this.timerTimer = setInterval(() => {
      if (this.isPlaying && this.avPlayer) {
        try {
          this.currentTime = this.avPlayer.currentTime;
          AppStorage.setOrCreate('progress', this.currentTime);
          AppStorage.setOrCreate('currentTime', this.formatTime(this.currentTime));
        } catch {
          this.currentTime += 100;
        }
      }
    }, 100);
  }

  private stopProgressTimer(): void {
    if (this.timerTimer !== -1) {
      clearInterval(this.timerTimer);
      this.timerTimer = -1;
    }
  }

  build() {
    NavDestination() {
      PlayerInfoComponent({ isShowPlay: this.isShowPlay });
    }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .hideTitleBar(true)
  }
}