import pathlib

gs = pathlib.Path('D:/Codes/Project/Lumio_Music/entry/src/main/ets/common/components/GroupedSheet.ets')
g = gs.read_text(encoding='utf-8')
old = """    Divider()
      .strokeWidth(0.5)
      .color(color)
      .startMargin(startMargin)
      .endMargin(endMargin)
      .width('100%');"""
new = """    Divider()
      .strokeWidth(0.5)
      .color(color)
      .width('100%')
      .margin({ left: startMargin, right: endMargin });"""
n = g.count(old)
g = g.replace(old, new)
gs.write_text(g, encoding='utf-8')
print("hairline replaced:", n, "; startMargin remaining:", g.count(".startMargin("))
print("DONE")
