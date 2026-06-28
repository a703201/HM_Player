@Component
  // export导出，使别的组件可以导入使用
export struct Moment{
  build(){
    Column(){
      //  搜索区域
      Row(){
        Image($r('app.media.ic_search'))
          .width(22)
          .fillColor('#817D83')
        TextInput({placeholder:'搜索你想要找的动态'})
          .placeholderColor('#817D83')
          .padding({left:5})
          .fontColor('#999')
          .layoutWeight(1)
        Image($r('app.media.ic_code'))
          .width(20)
          .fillColor('#817D83')
      }
      .width('100%')
      .backgroundColor('#ffcdcdcd')
      .border({radius:20})
      .padding({left:5,right:8})
    }
    .width('100%')
    .height('100%')
    .padding({left:10,right:10,top:5,bottom:5})
  }
}