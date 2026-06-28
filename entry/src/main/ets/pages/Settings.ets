import { MusicStore } from '../services/MusicStore';

@Entry
@Component
export struct Settings {
  @Prop store: MusicStore = MusicStore.getInstance();
  pathStack: NavPathStack = new NavPathStack();

  @State scanProgress: number = 0;
  @State isScanning: boolean = false;

  @Builder
  buildSettingItem(icon: ResourceStr, title: string, subtitle: string = '', onClick: () => void = () => {}) {
    Column() {
      Row() {
        Image(icon)
          .width(24)
          .fillColor(Color.White)
          .margin({ right: 14 })

        Column() {
          Text(title)
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: subtitle ? 4 : 0 })

          if (subtitle) {
            Text(subtitle)
              .fontSize(13)
              .fontColor('#8E8E93')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('app.media.ic_more'))
          .width(16)
          .fillColor('#636366')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .onClick(onClick)
    }
    .width('100%')
    .backgroundColor('#2C2C2E')
    .borderRadius(12)
  }

  build() {
    NavDestination() {
      Column() {
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ bottom: 24, left: 16, right: 16 })

        Scroll() {
          Column() {
            Column() {
              this.buildSettingItem(
                $r('app.media.ic_music'),
                '扫描本地音乐',
                '扫描设备中的音频文件',
                () => {
                  this.isScanning = true;
                  setTimeout(() => {
                    this.isScanning = false;
                    this.scanProgress = 100;
                  }, 2000);
                }
              )
            }
            .margin({ bottom: 12 })

            if (this.isScanning) {
              Progress({ style: ProgressStyle.Linear, value: this.scanProgress })
                .width('90%')
                .color('#FA2759')
            }

            Text('播放设置')
              .fontSize(14)
              .fontColor('#8E8E93')
              .margin({ left: 16, top: 20, bottom: 12 })

            Column() {
              this.buildSettingItem(
                $r('app.media.ic_repeat'),
                '默认播放模式',
                `当前: ${this.store.repeatMode === 'list' ? '列表循环' : this.store.repeatMode === 'single' ? '单曲循环' : '顺序播放'}`,
                () => {
                  const modes: ('none' | 'list' | 'single')[] = ['none', 'list', 'single'];
                  const currentIndex: number = modes.indexOf(this.store.repeatMode);
                  const nextIndex: number = (currentIndex + 1) % modes.length;
                  this.store.setRepeatMode(modes[nextIndex]);
                }
              )
            }
            .margin({ bottom: 12 })

            Text('关于')
              .fontSize(14)
              .fontColor('#8E8E93')
              .margin({ left: 16, top: 20, bottom: 12 })

            Column() {
              this.buildSettingItem(
                $r('app.media.ic_logo'),
                '版本信息',
                'HM_Music v1.0.0',
                () => {
                  this.pathStack.pushPathByName('About', null, false);
                }
              )
            }
            .margin({ bottom: 12 })

            Column() {
              this.buildSettingItem(
                $r('app.media.ic_code'),
                '开发者',
                'Lumio',
                () => {}
              )
            }
            .margin({ bottom: 12 })

            Column() {
              this.buildSettingItem(
                $r('app.media.ic_collect'),
                '清空缓存',
                '清除播放历史和缓存数据',
                () => {}
              )
            }
            .margin({ bottom: 12 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 40 })
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
