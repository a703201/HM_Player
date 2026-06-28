import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';

@Entry
@Component
export struct Find {
  store: MusicStore = MusicStore.getInstance();
  pathStack: NavPathStack = new NavPathStack();

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
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F2F2F7')
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
    Column() {
      Text('最近播放')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .margin({ bottom: 16, left: 16, right: 16 })

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
          ForEach(this.store.recentlyPlayed, (song: SongItem) => {
            ListItem() {
              this.buildSongCard(song)
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
