import pathlib

base = pathlib.Path('D:/Codes/Project/Lumio_Music/entry/src/main/ets')

# AddToPlaylistSheet.ets — SheetScaffold close
p = base / 'components/AddToPlaylistSheet.ets'
s = p.read_text(encoding='utf-8')
old = """    .width('100%')
    .layoutWeight(1)
    })"""
new = """    .width('100%')
    .layoutWeight(1)
    }"""
print("AddToPlaylistSheet close replaced:", s.count(old))
s = s.replace(old, new)
p.write_text(s, encoding='utf-8')

# OnboardingSheet.ets — SheetScaffold close
p = base / 'components/OnboardingSheet.ets'
s = p.read_text(encoding='utf-8')
old = """    .justifyContent(FlexAlign.Center)
    })"""
new = """    .justifyContent(FlexAlign.Center)
    }"""
print("OnboardingSheet close replaced:", s.count(old))
s = s.replace(old, new)
p.write_text(s, encoding='utf-8')

# Settings.ets — SheetScaffold close
p = base / 'pages/Settings.ets'
s = p.read_text(encoding='utf-8')
old = """    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    })"""
new = """    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }"""
print("Settings close replaced:", s.count(old))
s = s.replace(old, new)
p.write_text(s, encoding='utf-8')

print("DONE")
