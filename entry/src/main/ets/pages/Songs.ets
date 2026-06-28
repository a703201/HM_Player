import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';
import { scanLocalMusic } from '../services/MusicScanner';

@Entry
@Component
export struct Songs {
  store: MusicStore = MusicStore.getInstance();
  @State searchText: string = '';
  @State filteredSongs: SongItem[] = [];
  @State isLoading: boolean = false;
  @State isScanning: boolean = false;

  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.filteredSongs = [...this.store.songs];
    this.isLoading = this.store.songs.length === 0;
  }

  onSearchChange(text: string): void {
    this.searchText = text;
    if (text.trim() === '') {
      this.filteredSongs = [...this.store.songs];
    } else {
      this.filteredSongs = this.store.songs.filter(song =>
        song.title.includes(text) ||
        song.artist.includes(text) ||
        song.album.includes(text)
      );
    }
  }

  async onScanMusic(): Promise<void> {
    this.isScanning = true;
    this.isLoading = true;
    try {
      const songs: SongItem[] = await scanLocalMusic(getContext());
      this.store.setSongs(songs);
      this.filteredSongs = [...this.store.songs];
    } catch (err) {
      console.error('Scan failed');
    } finally {
      this.isScanning = false;
      this.isLoading = false;
    }
  }

  @Builder
  buildSongItem(song: SongItem, index: number) {
    Row() {
      Stack() {
        if (song.coverUri) {
          Image(song.coverUri)
            .width(56)
            .height(56)
            .borderRadius(8)
            .clip(true)
        } else {
          Image($r('app.media.QQ1'))
            .width(56)
            .height(56)
            .borderRadius(8)
            .clip(true)
        }

        if (this.store.currentIndex === index && this.store.isPlaying) {
          Image($r('app.media.ic_playing'))
            .width(20)
            .position({ x: 18, y: 18 })
        }
      }

      Column() {
        Text(song.title)
          .fontSize(16)
          .fontColor('#1C1C1E')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(song.artist)
          .fontSize(13)
          .fontColor('#8E8E93')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_more'))
        .width(20)
        .fillColor('#8E8E93')
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F2F2F7')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.store.currentIndex = index;
      this.pathStack.pushPathByName('Play', null, false);
    })
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_search'))
          .width(18)
          .fillColor('#8E8E93')
          .margin({ right: 8 })

        TextInput({ placeholder: '搜索歌曲、艺术家' })
          .placeholderColor('#8E8E93')
          .backgroundColor('#E5E5EA')
          .fontColor('#1C1C1E')
          .fontSize(15)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.onSearchChange(value);
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#E5E5EA')
      .borderRadius(10)
      .margin({ left: 16, right: 16, bottom: 12 })

      Row() {
        Text(`共 ${this.filteredSongs.length} 首歌曲`)
          .fontSize(13)
          .fontColor('#8E8E93')
          .layoutWeight(1)

        Button('扫描本地音乐')
          .fontSize(13)
          .fontColor('#FA2759')
          .backgroundColor(Color.Transparent)
          .enabled(!this.isScanning)
          .onClick(() => {
            this.onScanMusic();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 12 })

      if (this.isLoading) {
        Column() {
          if (this.isScanning) {
            Text('正在扫描本地音乐...')
              .fontSize(14)
              .fontColor('#8E8E93')
              .margin({ top: 100 })
          } else {
            Text('正在加载...')
              .fontSize(14)
              .fontColor('#8E8E93')
              .margin({ top: 100 })
          }
        }
        .layoutWeight(1)
      } else if (this.filteredSongs.length === 0) {
        Column() {
          Image($r('app.media.ic_music'))
            .width(64)
            .fillColor('#8E8E93')
            .margin({ bottom: 16 })

          Text('未找到本地音乐')
            .fontSize(15)
            .fontColor('#8E8E93')

          Text('点击"扫描本地音乐"按钮查找设备中的音频文件')
            .fontSize(13)
            .fontColor('#636366')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.filteredSongs, (song: SongItem, index: number) => {
            ListItem() {
              this.buildSongItem(song, index)
            }
          })
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
