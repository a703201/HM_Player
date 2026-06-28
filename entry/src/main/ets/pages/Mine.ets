import { MusicStore } from '../services/MusicStore';

@Entry
@Component
export struct Mine {
  @Prop parentPathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();

  @Builder
  buildMenuItem(icon: ResourceStr, title: string, subtitle: string = '', showArrow: boolean = true, onClick: () => void = () => {}) {
    Row() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor('#1C1C1E')
        .margin({ right: 14 })

      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#1C1C1E')
          .fontWeight(FontWeight.Medium)

        if (subtitle) {
          Text(subtitle)
            .fontSize(12)
            .fontColor('#8E8E93')
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (showArrow) {
        Image($r('app.media.ic_more'))
          .width(16)
          .height(16)
          .fillColor('#636366')
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#F2F2F7')
    .borderRadius(12)
    .margin({ bottom: 8 })
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
            .stroke('#FA2759')
            .strokeWidth(2)

          Image($r('app.media.ic_mine'))
            .width(40)
            .height(40)
            .fillColor('#FA2759')
        }
        .margin({ bottom: 12 })

        Text('本地音乐用户')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .margin({ bottom: 4 })

        Text(`已收藏 ${this.store.getFavoriteSongs().length} 首 · 共 ${this.store.songs.length} 首歌曲`)
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
          `${this.store.getFavoriteSongs().length} 首歌曲`,
          true,
          () => {}
        )

        this.buildMenuItem(
          $r('app.media.ic_list'),
          '播放历史',
          `${this.store.recentlyPlayed.length} 首歌曲`,
          true,
          () => {}
        )

        this.buildMenuItem(
          $r('app.media.ic_download'),
          '已下载',
          '0 首歌曲',
          true,
          () => {}
        )
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 })

      Text('更多')
        .fontSize(13)
        .fontColor('#8E8E93')
        .margin({ top: 16, bottom: 12, left: 16 })
        .textAlign(TextAlign.Start)
        .width('100%')

      Column() {
        this.buildMenuItem(
          $r('app.media.ic_music'),
          '本地音乐库',
          `${this.store.songs.length} 首歌曲`,
          true,
          () => {}
        )

        this.buildMenuItem(
          $r('app.media.ic_code'),
          '设置',
          '',
          true,
          () => {
            this.parentPathStack.pushPathByName('Settings', null, false);
          }
        )

        this.buildMenuItem(
          $r('app.media.ic_logo'),
          '关于',
          'HM_Music v1.0.0',
          true,
          () => {
            this.parentPathStack.pushPathByName('About', null, false);
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
