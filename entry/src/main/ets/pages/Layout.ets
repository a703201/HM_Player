import { Mine } from "./Mine"
import { Moment } from "./Moment"
import { Songs } from "./Songs"
import { Find } from "./Find"
import { MusicStore } from "../services/MusicStore"

interface TabClass{
  text:string
  icon:ResourceStr
}

@Builder
export function LayoutBuilder(){
  Layout()
}

@Component
struct Layout{
  @State currentIndex: number = 0
  pathStack: NavPathStack = new NavPathStack()
  store: MusicStore = MusicStore.getInstance()

  tabData:TabClass[] = [
    {text:'歌曲',icon:$r('app.media.ic_recommend')},
    {text:'发现',icon:$r('app.media.ic_find')},
    {text:'音乐库',icon:$r('app.media.ic_moment')},
    {text:'我的',icon:$r('app.media.ic_mine')}
  ]

  @Builder tabBuilder (item:TabClass, index:number) {
    Column({space : 5}){
      Image(item.icon)
        .width(24)
        .fillColor(this.currentIndex === index ? '#FA2759':'#8E8E93')
      Text(item.text)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#FA2759':'#8E8E93')
    }
  }

  build(){
    NavDestination(){
      Tabs({ barPosition : BarPosition.End }){
        TabContent() {
          Songs()
        }
        .tabBar(this.tabBuilder(this.tabData[0], 0))

        TabContent() {
          Find()
        }
        .tabBar(this.tabBuilder(this.tabData[1], 1))

        TabContent() {
          Moment()
        }
        .tabBar(this.tabBuilder(this.tabData[2], 2))

        TabContent() {
          Mine()
        }
        .tabBar(this.tabBuilder(this.tabData[3], 3))
      }
      .onChange((index:number) => {
        this.currentIndex = index
      })
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
