import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';
import { scanLocalMusic } from '../services/MusicScanner';
import { picker } from '@kit.CoreFileKit';

interface MenuItem {
  value: string;
  action: () => void;
}

@Entry
@Component
export struct Songs {
  @StorageLink('navPathStack') pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  @State searchText: string = '';
  @State filteredSongs: SongItem[] = [];
  @State isLoading: boolean = false;
  @State isScanning: boolean = false;

  aboutToAppear(): void {
    this.filteredSongs = [...this.store.songs];
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

  async onPickMusic(): Promise<void> {
    try {
      const audioPicker = new picker.AudioViewPicker();
      const result = await audioPicker.select();
      if (result && result.length > 0) {
        this.isLoading = true;
        const newSongs: SongItem[] = [];
        for (const uri of result) {
          const existingIndex = this.store.songs.findIndex(s => s.uri === uri);
          if (existingIndex < 0) {
            const fileName = decodeURIComponent(uri.substring(uri.lastIndexOf('/') + 1));
            const title = fileName.includes('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
            newSongs.push({
              id: Math.abs(hashCode(uri)).toString(),
              title: title,
              artist: '未知艺术家',
              album: '未知专辑',
              duration: 0,
              uri: uri,
              dateAdded: Date.now()
            });
          }
        }
        if (newSongs.length > 0) {
          this.store.setSongs([...this.store.songs, ...newSongs]);
          this.filteredSongs = [...this.store.songs];
        }
        this.isLoading = false;
      }
    } catch (err) {
      console.error('Pick music failed');
      this.isLoading = false;
    }
  }

  playSong(song: SongItem): void {
    const index = this.store.songs.findIndex(s => s.id === song.id);
    if (index >= 0) {
      this.store.currentIndex = index;
      this.pathStack.pushPathByName('PlayerPage', null, false);
    }
  }

  deleteSong(song: SongItem): void {
    this.store.removeSong(song.id);
    this.filteredSongs = [...this.store.songs];
  }

  @Builder
  buildSongItem(song: SongItem, index: number) {
    Row() {
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
        .padding({ left: 12 })
      }
      .layoutWeight(1)
      .height('100%')
      .onClick(() => {
        this.playSong(song);
      })

      Image($r('app.media.ic_more'))
        .width(20)
        .height(20)
        .fillColor('#8E8E93')
        .padding(8)
        .bindMenu(this.buildSongMenu(song))
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 8 })
    .backgroundColor('#F2F2F7')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  buildSongMenu(song: SongItem) {
    Column() {
      Row() {
        Image($r('app.media.ic_play'))
          .width(18)
          .fillColor('#1C1C1E')
          .margin({ right: 12 })
        Text('播放')
          .fontSize(14)
          .fontColor('#1C1C1E')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.playSong(song);
      })

      Divider().color('#E5E5EA').strokeWidth(0.5)

      Row() {
        Image($r('app.media.ic_list'))
          .width(18)
          .fillColor('#1C1C1E')
          .margin({ right: 12 })
        Text('添加至播放列表')
          .fontSize(14)
          .fontColor('#1C1C1E')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
      })

      Divider().color('#E5E5EA').strokeWidth(0.5)

      Row() {
        Image($r('app.media.ic_more'))
          .width(18)
          .fillColor('#1C1C1E')
          .margin({ right: 12 })
        Text('编辑')
          .fontSize(14)
          .fontColor('#1C1C1E')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
      })

      Divider().color('#E5E5EA').strokeWidth(0.5)

      Row() {
        Image($r('app.media.ic_close'))
          .width(18)
          .fillColor('#FA2759')
          .margin({ right: 12 })
        Text('删除')
          .fontSize(14)
          .fontColor('#FA2759')
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.deleteSong(song);
      })
    }
    .width(180)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_search'))
          .width(18)
          .height(18)
          .fillColor('#8E8E93')

        TextInput({ placeholder: '搜索歌曲、艺术家' })
          .placeholderColor('#8E8E93')
          .backgroundColor(Color.Transparent)
          .fontColor('#1C1C1E')
          .fontSize(15)
          .layoutWeight(1)
          .margin({ left: 8 })
          .onChange((value: string) => {
            this.onSearchChange(value);
          })
      }
      .width('100%')
      .height(40)
      .padding({ left: 14, right: 14 })
      .backgroundColor('#E5E5EA')
      .borderRadius(20)
      .margin({ left: 16, right: 16, top: 8, bottom: 12 })

      Row() {
        Text(`共 ${this.filteredSongs.length} 首歌曲`)
          .fontSize(13)
          .fontColor('#8E8E93')
          .layoutWeight(1)

        Row({ space: 4 }) {
          Image($r('app.media.ic_music'))
            .width(14)
            .height(14)
            .fillColor('#FA2759')

          Text('导入音乐')
            .fontSize(13)
            .fontColor('#FA2759')
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('rgba(250, 39, 89, 0.08)')
        .borderRadius(16)
        .enabled(!this.isScanning)
        .onClick(() => {
          this.onPickMusic();
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

          Text('点击"导入音乐"按钮添加音频文件')
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

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return hash;
}
