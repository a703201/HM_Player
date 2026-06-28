import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';

@Entry
@Component
export struct Find {
  @StorageLink('navPathStack') pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();

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
      .padding({ left: 12 })
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F2F2F7')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .onClick(() => {
      const index: number = this.store.songs.findIndex(s => s.id === song.id);
      if (index >= 0) {
        this.store.currentIndex = index;
        this.pathStack.pushPathByName('PlayerPage', null, false);
      }
    })
  }

  build() {
    Column() {
      Text('发现')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .margin({ bottom: 20, left: 16, right: 16 })

      Scroll() {
        Column() {
          if (this.store.recentlyPlayed.length > 0) {
            Text('最近播放')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1C1E')
              .margin({ bottom: 12, left: 16, right: 16 })

            List() {
              ForEach(this.store.recentlyPlayed, (song: SongItem) => {
                ListItem() {
                  this.buildSongCard(song)
                }
              })
            }
            .width('100%')
            .height('auto')
            .scrollBar(BarState.Off)
          }

          if (this.store.songs.length > 0) {
            Text('全部歌曲')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1C1E')
              .margin({ top: 20, bottom: 12, left: 16, right: 16 })

            List() {
              ForEach(this.store.songs, (song: SongItem) => {
                ListItem() {
                  this.buildSongCard(song)
                }
              })
            }
            .width('100%')
            .height('auto')
            .scrollBar(BarState.Off)
          }

          if (this.store.recentlyPlayed.length === 0 && this.store.songs.length === 0) {
            Column() {
              Image($r('app.media.ic_music'))
                .width(64)
                .fillColor('#8E8E93')
                .margin({ bottom: 16 })

              Text('暂无内容')
                .fontSize(15)
                .fontColor('#8E8E93')

              Text('前往歌曲页面导入音乐')
                .fontSize(13)
                .fontColor('#636366')
                .margin({ top: 8 })
            }
            .width('100%')
            .height(300)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
        .padding({ bottom: 80 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
