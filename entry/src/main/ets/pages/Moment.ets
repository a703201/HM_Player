import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';

interface FolderItem {
  name: string;
  count: number;
  icon: ResourceStr;
}

@Entry
@Component
export struct Moment {
  @Prop store: MusicStore = MusicStore.getInstance();
  pathStack: NavPathStack = new NavPathStack();

  folders: FolderItem[] = [
    { name: '我的收藏', count: this.store.getFavoriteSongs().length, icon: $r('app.media.ic_favorite') },
    { name: '本地音乐', count: this.store.songs.length, icon: $r('app.media.ic_music') },
    { name: '最近添加', count: this.store.recentlyPlayed.length, icon: $r('app.media.ic_list') },
    { name: '已下载', count: 0, icon: $r('app.media.ic_download') }
  ];

  @Builder
  buildFolderItem(name: string, count: number, icon: ResourceStr) {
    Row() {
      Image(icon)
        .width(24)
        .fillColor('#FA2759')
        .margin({ right: 14 })

      Text(name)
        .fontSize(16)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      Text(`${count}`)
        .fontSize(15)
        .fontColor('#8E8E93')

      Image($r('app.media.ic_more'))
        .width(16)
        .fillColor('#636366')
        .margin({ left: 8 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#2C2C2E')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  build() {
    NavDestination() {
      Column() {
        Text('音乐库')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 20 })
          .margin({ left: 16, right: 16 })

        List() {
          ForEach(this.folders, (folder: FolderItem, index: number) => {
            ListItem() {
              this.buildFolderItem(folder.name, folder.count, folder.icon)
            }
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .hideTitleBar(true)
  }
}
