import { SongItem, RepeatMode } from '../models/music';
import { LyricLine } from '../models/lyric';
import { MusicStore } from '../services/MusicStore';
import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';

@Builder
export function PlayBuilder() {
  Play()
}

@Component
struct Play {
  @Prop store: MusicStore = MusicStore.getInstance();
  @State isPlaying: boolean = false;
  @State currentTime: number = 0;
  @State duration: number = 0;
  @State showLyrics: boolean = false;
  @State currentLyricIndex: number = 0;
  @State scrollOffset: number = 0;
  @State avPlayer: media.AVPlayer | null = null;
  @State timerTimer: number = -1;

  pathStack: NavPathStack = new NavPathStack();

  sampleLyrics: LyricLine[] = [
    { time: 0, text: '♪ 欢迎使用 HM_Music ' },
    { time: 3000, text: '♪ 正在播放本地音乐 ' },
    { time: 6000, text: '' },
    { time: 9000, text: '这一首歌' },
    { time: 12000, text: '献给你' },
    { time: 15000, text: '' },
    { time: 18000, text: '让旋律' },
    { time: 21000, text: '带走烦恼' },
    { time: 24000, text: '' },
    { time: 27000, text: '让音符' },
    { time: 30000, text: '陪伴时光' },
    { time: 33000, text: '' },
    { time: 36000, text: '在音乐的世界里' },
    { time: 39000, text: '感受生活的美好' },
    { time: 42000, text: '' },
    { time: 45000, text: '每一个音符' },
    { time: 48000, text: '都是心灵的慰藉' },
    { time: 51000, text: '' },
    { time: 54000, text: '愿你享受这段旋律' },
    { time: 57000, text: '♪ 纯音乐，请欣赏 ♪' }
  ];

  async aboutToAppear(): Promise<void> {
    this.isPlaying = this.store.isPlaying;
    await this.initMediaPlayer();
    this.startProgressTimer();
  }

  aboutToDisappear(): void {
    this.stopProgressTimer();
    this.releaseMediaPlayer();
  }

  private async initMediaPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      if (this.avPlayer) {
        this.avPlayer.on('stateChange', (state: string, reason: media.StateChangeReason) => {
          if (state === 'completed') {
            this.handleTrackComplete();
          }
        });
        this.avPlayer.on('error', (err: BusinessError) => {
          console.error(`AVPlayer error: ${err.code} - ${err.message}`);
        });
        this.avPlayer.on('timeUpdate', (time: number) => {
          this.currentTime = time;
          this.updateCurrentLyric();
        });
        this.avPlayer.on('durationUpdate', (dur: number) => {
          this.duration = dur;
        });
      }
    } catch (err) {
      const be = err as BusinessError;
      console.error(`createAVPlayer failed: code=${be.code}, message=${be.message}`);
    }
  }

  private async playCurrentTrack(): Promise<void> {
    if (!this.avPlayer || this.store.playList.length === 0) {
      return;
    }

    const currentSong: SongItem = this.store.playList[this.store.currentIndex];
    if (!currentSong) {
      return;
    }

    try {
      await this.avPlayer.stop();
      await this.avPlayer.reset();
      this.avPlayer.fdSrc = { fd: await this.openFd(currentSong.uri) };
      await this.avPlayer.prepare();

      await this.avPlayer.play();
      this.isPlaying = true;
      this.store.setIsPlaying(true);
      this.store.addToRecentlyPlayed(currentSong);
    } catch (err) {
      const be = err as BusinessError;
      console.error(`playCurrentTrack failed: code=${be.code}, message=${be.message}`);
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

  private async pausePlayback(): Promise<void> {
    if (!this.avPlayer) {
      return;
    }

    try {
      await this.avPlayer.pause();
      this.isPlaying = false;
      this.store.setIsPlaying(false);
    } catch (err) {
      console.error('pausePlayback failed');
    }
  }

  private async togglePlayPause(): Promise<void> {
    if (this.isPlaying) {
      await this.pausePlayback();
    } else {
      await this.playCurrentTrack();
    }
  }

  private async playTrack(index: number): Promise<void> {
    if (index < 0 || index >= this.store.playList.length) {
      return;
    }

    this.store.currentIndex = index;
    this.isPlaying = false;
    this.currentTime = 0;
    await this.playCurrentTrack();
  }

  private async playNext(): Promise<void> {
    if (this.store.playList.length === 0) {
      return;
    }

    let nextIndex: number;
    switch (this.store.repeatMode) {
      case 'single':
        nextIndex = this.store.currentIndex;
        break;
      case 'list':
        nextIndex = (this.store.currentIndex + 1) % this.store.playList.length;
        break;
      case 'none':
      default:
        nextIndex = this.store.currentIndex + 1;
        if (nextIndex >= this.store.playList.length) {
          nextIndex = this.store.playList.length - 1;
          this.isPlaying = false;
          this.store.setIsPlaying(false);
        }
        break;
    }

    await this.playTrack(nextIndex);
  }

  private async playPrevious(): Promise<void> {
    if (this.store.playList.length === 0) {
      return;
    }

    if (this.currentTime > 3000) {
      await this.playTrack(this.store.currentIndex);
      return;
    }

    let prevIndex: number;
    switch (this.store.repeatMode) {
      case 'single':
        prevIndex = this.store.currentIndex;
        break;
      case 'list':
        prevIndex = (this.store.currentIndex - 1 + this.store.playList.length) % this.store.playList.length;
        break;
      case 'none':
      default:
        prevIndex = this.store.currentIndex - 1;
        if (prevIndex < 0) {
          prevIndex = 0;
        }
        break;
    }

    await this.playTrack(prevIndex);
  }

  private handleTrackComplete(): void {
    this.playNext();
  }

  private async seekTo(position: number): Promise<void> {
    if (!this.avPlayer) {
      return;
    }

    try {
      await this.avPlayer.seek(position, media.SeekMode.SEEK_CLOSEST);
      this.currentTime = position;
    } catch (err) {
      console.error('seekTo failed');
    }
  }

  private toggleRepeatMode(): void {
    const modes: RepeatMode[] = ['none', 'list', 'single'];
    const currentIndex: number = modes.indexOf(this.store.repeatMode);
    const nextIndex: number = (currentIndex + 1) % modes.length;
    this.store.setRepeatMode(modes[nextIndex]);
  }

  private toggleFavorite(): void {
    if (this.store.playList.length > 0) {
      const currentSong: SongItem = this.store.playList[this.store.currentIndex];
      if (currentSong) {
        this.store.toggleFavorite(currentSong.id);
      }
    }
  }

  private releaseMediaPlayer(): void {
    if (this.avPlayer) {
      try {
        this.avPlayer.stop();
        this.avPlayer.release();
      } catch (err) {
        console.error('releaseMediaPlayer failed');
      }
      this.avPlayer = null;
    }
  }

  private formatTime(ms: number): string {
    if (ms <= 0) {
      return '0:00';
    }
    const totalSeconds: number = Math.floor(ms / 1000);
    const minutes: number = Math.floor(totalSeconds / 60);
    const seconds: number = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }

  private updateCurrentLyric(): void {
    for (let i: number = 0; i < this.sampleLyrics.length; i++) {
      if (this.currentTime >= this.sampleLyrics[i].time) {
        this.currentLyricIndex = i;
      } else {
        break;
      }
    }
  }

  private startProgressTimer(): void {
    this.timerTimer = setInterval(() => {
      if (this.isPlaying && this.avPlayer) {
        try {
          const currentTime: number = this.avPlayer.currentTime;
          this.currentTime = currentTime;
          this.updateCurrentLyric();
        } catch {
          this.currentTime += 100;
          this.updateCurrentLyric();
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

  @Builder
  buildShimmerLyric(text: string, isCurrent: boolean) {
    if (isCurrent && text) {
      Stack({ alignContent: Alignment.Center }) {
        Text(text)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .margin({ bottom: 16 })

        Stack({ alignContent: Alignment.Center }) {
          Text(text)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ bottom: 16 })

          Row() {
            ForEach([0, 1, 2, 3, 4], () => {
              Blank()
                .width(60)
                .linearGradient({
                  direction: GradientDirection.Right,
                  colors: [
                    [Color.Transparent, 0],
                    [Color.White, 0.3],
                    [Color.White, 0.7],
                    [Color.Transparent, 1]
                  ]
                })
                .animation({
                  duration: 2000,
                  iterations: Infinity,
                  playMode: PlayMode.Normal
                })
            })
          }
          .width('200%')
          .animation({
            duration: 3000,
            iterations: Infinity,
            curve: Curve.Linear
          })
          .blendMode(BlendMode.DST_IN)
        }
        .clip(true)
      }
      .layoutWeight(1)
    } else {
      Column() {
        Blank()
          .height(16)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
  }

  build() {
    NavDestination() {
      Stack() {
        if (this.store.playList.length > 0) {
          Image(this.store.playList[this.store.currentIndex]?.coverUri || $r('app.media.QQ1'))
            .width('100%')
            .height('100%')
            .blur(100)
            .scale({ x: 1.2, y: 1.2 })
            .opacity(0.5)
            .position({ x: 0, y: 0 })
        }

        Column() {
          Row() {
            Image($r('app.media.ic_back'))
              .width(24)
              .fillColor(Color.White)
              .onClick(() => {
                this.pathStack.pop();
              })

            Blank()

            Button(this.showLyrics ? '歌词' : '播放')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.showLyrics = !this.showLyrics;
              })

            Blank()

            Image($r('app.media.ic_more'))
              .width(24)
              .fillColor(Color.White)
              .onClick(() => {})
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })

          if (this.showLyrics) {
            List() {
              ForEach(this.sampleLyrics, (line: LyricLine, index: number) => {
                ListItem() {
                  this.buildShimmerLyric(line.text, index === this.currentLyricIndex)
                }
              })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .alignListItem(ListItemAlign.Center)
            .offset({ x: 0, y: -this.scrollOffset })
            .onScrollIndex((firstIndex: number, lastIndex: number) => {
              this.scrollOffset = firstIndex * 60;
            })
          } else {
            Column() {
              Stack({ alignContent: Alignment.Center }) {
                Circle()
                  .width(280)
                  .height(280)
                  .fill(Color.Transparent)
                  .stroke(Color.White)
                  .strokeWidth(1)
                  .opacity(0.1)

                if (this.store.playList.length > 0) {
                  Image(this.store.playList[this.store.currentIndex]?.coverUri || $r('app.media.QQ1'))
                    .width(240)
                    .height(240)
                    .borderRadius(120)
                    .clip(true)
                } else {
                  Image($r('app.media.QQ1'))
                    .width(240)
                    .height(240)
                    .borderRadius(120)
                    .clip(true)
                }

                Circle()
                  .width(30)
                  .height(30)
                  .fill('#1C1C1E')

                Row()
                  .width(240)
                  .height(240)
                  .rotate({
                    angle: this.isPlaying ? 360 : 0,
                    centerX: 120,
                    centerY: 120
                  })
                  .animation({
                    duration: 10000,
                    iterations: this.isPlaying ? Infinity : 1,
                    playMode: PlayMode.Normal
                  })
              }
              .width('100%')
              .layoutWeight(1)

              Column() {
                Text(this.store.playList.length > 0 ? this.store.playList[this.store.currentIndex]?.title : '未知歌曲')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .margin({ bottom: 8 })

                Text(this.store.playList.length > 0 ? this.store.playList[this.store.currentIndex]?.artist : '未知艺术家')
                  .fontSize(16)
                  .fontColor('#8E8E93')
              }
              .width('100%')
              .padding({ left: 40, right: 40, bottom: 30 })

              Column() {
                Slider({
                  value: this.currentTime,
                  min: 0,
                  max: this.duration || 1
                })
                  .width('100%')
                  .blockColor('#FFFFFF')
                  .selectedColor('#FA2759')
                  .trackColor('rgba(255, 255, 255, 0.2)')
                  .trackThickness(3)
                  .blockSize({ width: 14, height: 14 })
                  .onChange((value: number) => {
                    this.currentTime = value;
                    this.seekTo(value);
                  })

                Row() {
                  Text(this.formatTime(this.currentTime))
                    .fontSize(12)
                    .fontColor('#8E8E93')

                  Blank()

                  Text(this.formatTime(this.duration))
                    .fontSize(12)
                    .fontColor('#8E8E93')
                }
                .width('100%')
                .margin({ top: 8 })
              }
              .width('100%')
              .padding({ left: 30, right: 30, bottom: 30 })

              Row() {
                Image($r('app.media.ic_random'))
                  .width(28)
                  .fillColor(this.store.repeatMode === 'none' ? '#8E8E93' : Color.White)
                  .onClick(() => {
                    this.toggleRepeatMode();
                  })

                Blank()

                Image($r('app.media.ic_prev'))
                  .width(40)
                  .fillColor(Color.White)
                  .onClick(() => {
                    this.playPrevious();
                  })

                Blank()

                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(72)
                    .height(72)
                    .fill('rgba(255, 255, 255, 0.1)')

                  Image(this.isPlaying ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
                    .width(40)
                    .fillColor(Color.White)
                }
                .onClick(() => {
                  this.togglePlayPause();
                })

                Blank()

                Image($r('app.media.ic_next'))
                  .width(40)
                  .fillColor(Color.White)
                  .onClick(() => {
                    this.playNext();
                  })

                Blank()

                Image(this.store.isFavorite(
                  this.store.playList.length > 0 ? this.store.playList[this.store.currentIndex]?.id : ''
                ) ? $r('app.media.ic_favorite') : $r('app.media.ic_collect'))
                  .width(28)
                  .fillColor(this.store.isFavorite(
                    this.store.playList.length > 0 ? this.store.playList[this.store.currentIndex]?.id : ''
                  ) ? '#FA2759' : '#8E8E93')
                  .onClick(() => {
                    this.toggleFavorite();
                  })
              }
              .width('100%')
              .padding({ left: 30, right: 30, bottom: 40 })
            }
            .layoutWeight(1)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}
