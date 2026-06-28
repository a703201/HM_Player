import { MusicStore } from '../services/MusicStore';

@Entry
@Component
export struct Mine {
  store: MusicStore = MusicStore.getInstance();
  pathStack: NavPathStack = new NavPathStack();

  @Builder
  buildMenuItem(icon: ResourceStr, title: string, showArrow: boolean = true, onClick: () => void = () => {}) {
    Row() {
      Image(icon)
        .width(24)
        .fillColor('#1C1C1E')
        .margin({ right: 14 })

      Text(title)
        .fontSize(16)
        .fontColor('#1C1C1E')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      if (showArrow) {
        Image($r('app.media.ic_more'))
          .width(16)
          .fillColor('#636366')
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F2F2F7')
    .borderRadius(12)
    .onClick(onClick)
  }

  build() {
    Column() {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(80)
            .height(80)
            .fill('#E5E5EA')
            .stroke('#1C1C1E')
            .strokeWidth(2)

          Image($r('app.media.ic_mine'))
            .width(40)
            .fillColor('#1C1C1E')
        }
        .margin({ bottom: 12 })

        Text('本地音乐用户')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .margin({ bottom: 4 })

        Text(`已收藏 ${this.store.getFavoriteSongs().length} 首歌曲`)
          .fontSize(14)
          .fontColor('#8E8E93')
      }
      .width('100%')
      .padding({ top: 40, bottom: 30 })
      .justifyContent(FlexAlign.Center)

      Column() {
        this.buildMenuItem(
          $r('app.media.ic_favorite'),
          '我的收藏',
          true,
          () => {}
        )

        this.buildMenuItem(
          $r('app.media.ic_list'),
          '播放历史',
          true,
          () => {}
        )

        this.buildMenuItem(
          $r('app.media.ic_download'),
          '已下载',
          true,
          () => {}
        )

        this.buildMenuItem(
          $r('app.media.ic_music'),
          '本地音乐库',
          true,
          () => {}
        )

        this.buildMenuItem(
          $r('app.media.ic_code'),
          '设置',
          true,
          () => {
            this.pathStack.pushPathByName('Settings', null, false);
          }
        )

        this.buildMenuItem(
          $r('app.media.ic_logo'),
          '关于',
          true,
          () => {
            this.pathStack.pushPathByName('About', null, false);
          }
        )
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
