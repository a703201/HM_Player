import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';

interface FolderItem {
  name: string;
  count: number;
  icon: ResourceStr;
  songs: SongItem[];
}

@Entry
@Component
export struct Moment {
  @Prop parentPathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();

  @State folders: FolderItem[] = [];
  @State currentFolderSongs: SongItem[] | null = null;
  @State currentFolderName: string = '';

  aboutToAppear(): void {
    this.updateFolders();
  }

  updateFolders(): void {
    this.folders = [
      { name: '我的收藏', count: this.store.getFavoriteSongs().length, icon: $r('app.media.ic_favorite'), songs: this.store.getFavoriteSongs() },
      { name: '本地音乐', count: this.store.songs.length, icon: $r('app.media.ic_music'), songs: [...this.store.songs] },
      { name: '最近播放', count: this.store.recentlyPlayed.length, icon: $r('app.media.ic_list'), songs: [...this.store.recentlyPlayed] },
      { name: '已下载', count: 0, icon: $r('app.media.ic_download'), songs: [] }
    ];
  }

  @Builder
  buildFolderItem(folder: FolderItem) {
    Row() {
      Image(folder.icon)
        .width(24)
        .height(24)
        .fillColor('#FA2759')
        .margin({ right: 14 })

      Text(folder.name)
        .fontSize(16)
        .fontColor('#1C1C1E')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      Text(`${folder.count}`)
        .fontSize(15)
        .fontColor('#8E8E93')
        .margin({ right: 8 })

      Image($r('app.media.ic_more'))
        .width(16)
        .height(16)
        .fillColor('#636366')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F2F2F7')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => {
      if (folder.songs.length > 0) {
        this.currentFolderName = folder.name;
        this.currentFolderSongs = [...folder.songs];
      }
    })
  }

  @Builder
  buildSongItem(song: SongItem, index: number) {
    Row() {
      Stack() {
        if (song.coverUri) {
          Image(song.coverUri)
            .width(48)
            .height(48)
            .borderRadius(8)
            .clip(true)
        } else {
          Image($r('app.media.QQ1'))
            .width(48)
            .height(48)
            .borderRadius(8)
            .clip(true)
        }
      }

      Column() {
        Text(song.title)
          .fontSize(15)
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
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F2F2F7')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => {
      const globalIndex = this.store.songs.findIndex(s => s.id === song.id);
      if (globalIndex >= 0) {
        this.store.currentIndex = globalIndex;
      }
      this.parentPathStack.pushPathByName('Play', null, false);
    })
  }

  build() {
    Column() {
      if (this.currentFolderSongs !== null) {
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .onClick(() => {
              this.currentFolderSongs = null;
              this.updateFolders();
            })

          Text(this.currentFolderName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
            .margin({ left: 12 })
            .layoutWeight(1)

          Text(`${this.currentFolderSongs.length} 首`)
            .fontSize(13)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })

        List() {
          ForEach(this.currentFolderSongs, (song: SongItem, index: number) => {
            ListItem() {
              this.buildSongItem(song, index)
            }
          })
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      } else {
        Text('音乐库')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .margin({ bottom: 20, left: 16, right: 16 })

        List() {
          ForEach(this.folders, (folder: FolderItem) => {
            ListItem() {
              this.buildFolderItem(folder)
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
