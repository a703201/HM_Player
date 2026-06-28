@Entry
@Component
export struct About {
  pathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Circle()
              .width(100)
              .height(100)
              .fill('#2C2C2E')
              .stroke(Color.White)
              .strokeWidth(2)
              .opacity(0.3)

            Image($r('app.media.ic_logo'))
              .width(50)
              .fillColor(Color.White)
          }
          .margin({ top: 60, bottom: 24 })

          Text('HM_Music')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ bottom: 8 })

          Text('本地音乐播放器')
            .fontSize(16)
            .fontColor('#8E8E93')
            .margin({ bottom: 40 })

          Column() {
            this.buildAboutItem('应用版本', '1.0.0')
            this.buildAboutItem('开发者', 'Lumio')
            this.buildAboutItem('技术支持', 'HarmonyOS SDK')
            this.buildAboutItem('架构', 'ArkTS + ArkUI')
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          Text('一款简洁的本地音乐播放器，支持扫描设备音频文件、播放控制、歌词显示等功能。')
            .fontSize(14)
            .fontColor('#636366')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 40, bottom: 40 })
            .padding({ left: 30, right: 30 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .hideTitleBar(true)
  }

  @Builder
  buildAboutItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#8E8E93')
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      Text(value)
        .fontSize(15)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#2C2C2E')
    .borderRadius(12)
    .margin({ bottom: 1 })
  }
}
