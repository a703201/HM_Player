@Component
  // export导出，使别的组件可以导入使用
export struct About{
  build(){
    Text('关于')
      .fontColor(Color.Black)
  }
}