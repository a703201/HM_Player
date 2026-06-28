@Component
  // export导出，使别的组件可以导入使用
export struct Mine{
  build(){
    Text('我的')
      .fontColor(Color.Black)

  }
}