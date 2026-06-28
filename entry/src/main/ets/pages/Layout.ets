//导入
import { Mine } from "./Mine"
import { Moment } from "./Moment"
import { Songs } from "./Songs"

interface TabClass{
  text:string
  icon:ResourceStr
}

//跳转页面入口函数
@Builder
export function LayoutBuilder(){
  Layout()
}

@Component
struct Layout{
  @State currentIndex: number = 0
  //控制跳转的对象
  pathStack: NavPathStack = new NavPathStack()

  tabData:TabClass[] = [
    {text:'歌曲',icon:$r('app.media.ic_recommend')},
    {text:'动态',icon:$r('app.media.ic_moment')},
    {text:'我的',icon:$r('app.media.ic_mine')}
  ]

  @Builder tabBuilder (item:TabClass, index:number) {
    Column({space : 5}){
      Image(item.icon)
        .width(24)
        .fillColor(this.currentIndex === index ? '#0F0F0F':'#F4F4F4')
      Text(item.text)
        .fontSize(14)
        .fontColor(this.currentIndex === index ? '#0F0F0F':'#F4F4F4')
    }
  }

  build(){
    NavDestination(){
      Tabs({ barPosition : BarPosition.End }){
        ForEach(this.tabData,(item:TabClass,index:number) => {
          TabContent() {
            if (this.currentIndex === 0) {
              Songs()
            } else if (this.currentIndex === 1) {
              Moment()
            } else if (this.currentIndex === 2) {
              Mine()
            }
          }
          .tabBar(this.tabBuilder(item,index)) //自定义导航栏 @Builder
        })
      }
      .onChange((index:number) => {
        this.currentIndex = index
      })
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    }
    // .title('布局页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}


