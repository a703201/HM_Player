import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';

interface FolderItem {
  name: string;
  count: number;
  icon: ResourceStr;
  targetPage: string;
  songs: SongItem[];
}

@Entry
@Component
export struct Moment {
  @StorageLink('navPathStack') pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();

  @State folders: FolderItem[] = [];

  aboutToAppear(): void {
    this.updateFolders();
  }

  updateFolders(): void {
    this.folders = [
      { name: '我的收藏', count: this.store.getFavoriteSongs().length, icon: $r('app.media.ic_favorite'), targetPage: 'Favorites', songs: this.store.getFavoriteSongs() },
      { name: '本地音乐', count: this.store.songs.length, icon: $r('app.media.ic_music'), targetPage: 'LocalLibrary', songs: [...this.store.songs] },
      { name: '最近播放', count: this.store.recentlyPlayed.length, icon: $r('app.media.ic_list'), targetPage: 'PlayHistory', songs: [...this.store.recentlyPlayed] }
    ];
  }

  @Builder
  buildFolderItem(folder: FolderItem) {
    Row() {
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
      }
      .layoutWeight(1)
      .height('100%')
      .onClick(() => {
        this.pathStack.pushPathByName(folder.targetPage, null, false);
      })

      Image($r('app.media.ic_more'))
        .width(16)
        .height(16)
        .fillColor('#636366')
        .padding(8)
        .bindMenu(this.buildFolderMenu(folder))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 8 })
    .backgroundColor('#F2F2F7')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  buildFolderMenu(folder: FolderItem) {
    Column() {
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
      })
    }
    .width(140)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
  }

  build() {
    Column() {
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
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
