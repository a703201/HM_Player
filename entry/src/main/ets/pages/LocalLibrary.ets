import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';

@Builder
export function LocalLibraryBuilder() {
  LocalLibrary()
}

@Entry
@Component
struct LocalLibrary {
  store: MusicStore = MusicStore.getInstance();
  pathStack: NavPathStack = new NavPathStack();

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
      this.pathStack.pushPathByName('PlayerPage', null, false);
    })
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor('#1C1C1E')
            .onClick(() => {
              this.pathStack.pop();
            })

          Text('本地音乐库')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
            .margin({ left: 12 })
            .layoutWeight(1)

          Text(`${this.store.songs.length} 首`)
            .fontSize(13)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })

        if (this.store.songs.length === 0) {
          Column() {
            Image($r('app.media.ic_music'))
              .width(64)
              .fillColor('#8E8E93')
              .margin({ bottom: 16 })

            Text('暂无本地音乐')
              .fontSize(15)
              .fontColor('#8E8E93')

            Text('前往歌曲页面导入音乐')
              .fontSize(13)
              .fontColor('#636366')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.store.songs, (song: SongItem, index: number) => {
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
      .padding({ top: 16 })
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}
