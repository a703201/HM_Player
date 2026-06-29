import { Mine } from "./Mine"
import { Moment } from "./Moment"
import { Songs } from "./Songs"
import { MusicStore } from "../services/MusicStore"

interface TabClass{
  text:string
  icon:ResourceStr
}

@Builder
export function LayoutBuilder(){
  Layout()
}

@Entry
@Component
struct Layout{
  @State currentIndex: number = 0
  @State pathStack: NavPathStack = new NavPathStack()
  store: MusicStore = MusicStore.getInstance()

  tabData:TabClass[] = [
    {text:'歌曲',icon:$r('app.media.ic_recommend')},
    {text:'音乐库',icon:$r('app.media.ic_moment')},
    {text:'我的',icon:$r('app.media.ic_mine')}
  ]

  @Builder tabBuilder (item:TabClass, index:number) {
    Column({space : 4}){
      Image(item.icon)
        .width(22)
        .fillColor(this.currentIndex === index ? '#FA2759':'#8E8E93')
      Text(item.text)
        .fontSize(11)
        .fontColor(this.currentIndex === index ? '#FA2759':'#8E8E93')
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width(64)
    .height(44)
    .justifyContent(FlexAlign.Center)
  }

  build(){
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Tabs({ barPosition : BarPosition.End, index: this.currentIndex }){
          TabContent() {
            Songs()
          }
          .tabBar(this.tabBuilder(this.tabData[0], 0))

          TabContent() {
            Moment()
          }
          .tabBar(this.tabBuilder(this.tabData[1], 1))

          TabContent() {
            Mine()
          }
          .tabBar(this.tabBuilder(this.tabData[2], 2))
        }
        .onChange((index:number) => {
          this.currentIndex = index
        })
        .barMode(BarMode.Fixed)
        .barWidth('100%')
        .barHeight(0)
        .scrollable(false)
        .width('100%')
        .height('100%')

        Row() {
          ForEach(this.tabData, (item: TabClass, index: number) => {
            Column({space: 4}) {
              Image(item.icon)
                .width(22)
                .fillColor(this.currentIndex === index ? '#FA2759' : '#8E8E93')
              Text(item.text)
                .fontSize(11)
                .fontColor(this.currentIndex === index ? '#FA2759' : '#8E8E93')
                .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
            }
            .width(64)
            .height(44)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.currentIndex = index;
            })
          })
        }
        .width('85%')
        .height(52)
        .backgroundColor(Color.White)
        .borderRadius(26)
        .shadow({
          radius: 12,
          color: 'rgba(0, 0, 0, 0.08)',
          offsetX: 0,
          offsetY: 4
        })
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      AppStorage.setOrCreate('navPathStack', context.pathStack)
    })
  }
}