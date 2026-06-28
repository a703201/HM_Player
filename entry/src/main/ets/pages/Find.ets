import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';

@Entry
@Component
export struct Find {
  @Prop store: MusicStore = MusicStore.getInstance();
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.store.setSongs(this.store.songs);
  }

  @Builder
  buildSongCard(song: SongItem) {
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
      }

      Column() {
        Text(song.title)
          .fontSize(15)
          .fontColor(Color.White)
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
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#2C2C2E')
    .borderRadius(12)
    .onClick(() => {
      const index: number = this.store.songs.findIndex(s => s.id === song.id);
      if (index >= 0) {
        this.store.currentIndex = index;
        this.pathStack.pushPathByName('Play', null, false);
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        Text('最近播放')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 16 })
          .margin({ left: 16, right: 16 })

        if (this.store.recentlyPlayed.length === 0) {
          Column() {
            Image($r('app.media.ic_music'))
              .width(64)
              .fillColor('#8E8E93')
              .margin({ bottom: 16 })

            Text('暂无最近播放记录')
              .fontSize(15)
              .fontColor('#8E8E93')

            Text('播放歌曲后将在这里显示')
              .fontSize(13)
              .fontColor('#636366')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.store.recentlyPlayed, (song: SongItem, index: number) => {
              ListItem() {
                this.buildSongCard(song)
              }
            })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
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
