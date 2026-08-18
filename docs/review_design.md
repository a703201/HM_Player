# Lumio Music · 设计规范与一致性体检报告

> 审查对象：`D:\Codes\Project\Lumio_Music`（HarmonyOS NEXT / ArkUI 声明式，ets 源码 + resources）
> 审查基准：HarmonyOS Design（ArkUI 设计规范）—— 设计系统一致性 / 组件选型复用 / 交互动效 / 多端响应式 / 无障碍
> 审查人：蓝绘心（UI/UX Designer，鸿蒙）
> 范围：`entry/src/main/ets/{pages,components,utils,widget}`、`resources/{base,dark}/element/*`
> 说明：本报告为独立复核，所有结论均基于本次实际阅读源码与资源文件；行号以本次读取为准。

---

## 0. 结论速览

- **整体设计成熟度：7 / 10（中等偏上）**。主题门面（`ThemeManager.lightColors/darkColors` + `@StorageProp('isDark')`）、响应式断点体系、播放页「一镜到底」共享元素转场、组件拆分（`CoverImageView`/`SongDetailSheet`/`AddToPlaylistSheet`/`ControlAreaComponent` 等）基础扎实，方向符合 HarmonyOS Design。
- **关键设计风险（用户可感知）**：
  1. **P0**：播放队列半模态面板（`ControlAreaComponent`）整片硬编码 `Color.White` 背景 + `Color.Black/Red/Gray` 文字，且**未引入 ThemeManager、无 `@StorageProp('isDark')`**，深色模式下为刺眼纯白卡——全应用唯一明确的明暗断裂点。
  2. **P1**：品牌色 `#FA2759` 散落内联约 50+ 处，且被**重复定义为 `const ACCENT`**（`Layout.ets:26` 与 `LocalLibrary.ets:32` 各一份）；`ThemeManager.accent` 令牌几乎未被引用；颜色系统存在「ThemeManager 语义令牌 / resources color.json 资源令牌」**双源**，`dark/color.json` 仅一项。
  3. **P1**：桌面播控卡片 `WidgetCard.ets` 主按钮使用 Material 蓝 `#1E88E5`（非品牌粉红）、整卡硬编码深色 `#1A1A2E`，既不跟随主题又**严重偏离品牌识别**。
  4. **P1**：歌曲列表项 + 长按菜单在 `LocalLibrary`/`Favorites`/`PlaylistDetail` **三处近乎复制**；分类图标 / 统计数字使用 **Apple HIG 调色板**（`#34C759/#FF9500/#007AFF/#5E5CE6/#FFCC00/#5856D6`），削弱 HarmonyOS 品牌。
- **做对的地方**：播放页沉浸态（`ignoreLayoutSafeArea` + 取色渐变 + 模糊）、`geometryTransition('player_cover')` 一镜到底、折叠屏/平板下播放页双栏（`isFoldFull` / `lg` GridRow）、`fp` 字号、详情/添加面板已正确主题化（`getThemeColors()`）、断点常量体系完整。

---

## 1. 设计系统现状

### 1.1 颜色令牌
- **语义令牌（ThemeManager）**：`bg / secondaryBg / cardBg / primaryText / secondaryText / separator / accent`，light/dark 两套（ThemeManager.ets:42-60）。页面经 `@StorageProp('isDark')` + 本地 `getThemeColors()`（`return isDark ? darkColors : lightColors`）取用，切换写 AppStorage 后自动重渲——**机制正确**。
- **资源令牌（color.json）**：`base` 定义 8 项（`start_window_background / select_swiper / slider_track / slider_select / play_text_color / singer_text / shadow_color / list_divider`）；**`dark/element/color.json` 仅 `start_window_background`**（`#000000`）→ 深色下其余 `$r('app.color.*')` 全部回退浅色值（结构性缺口，见 F-03）。
- **品牌色 `#FA2759`**：ThemeManager 中定义为 `accent`（两处），但页面几乎不引用，改为约 50+ 处内联 `#FA2759`/`rgba(250,39,89,...)`，并有**两份** `const ACCENT='#FA2759'` 本地常量（F-02）。`ThemeManager.getColors()` 仅出现在注释，从未被调用（F-04）。

### 1.2 圆角 / 间距 / 字号
- 大量走 `float.json`（`common_padding=16vp`、`cover_radius=16vp`、`cover_radius_label=12vp`、`play_all_border_radius=12vp` 等），方向正确。
- **圆角尺度发散**：页面内 `borderRadius` 出现 10/12/14/15/16/20/21/22/24/32 等（F-10），未收敛到统一半径令牌。
- 间距混用 `$r('app.float.*')` 与内联 `{left:16,right:16}`；字号统一 `fp`（无障碍友好），但多处固定 `height(64/60/76)` 在超大字体下可能挤压多行文本。

### 1.3 图标
- 资源 120+，`png`（`ic_*.png`）与 `svg`（`ic_*.svg`/`heart*.svg`）混存，并与 **HarmonyOS SymbolGlyph**（`sys.symbol.music_square_stack_fill`/`person`/`pause_fill`，Layout.ets:64-65,186）混用。png 不利着色与光学对齐（F-12）。

### 1.4 桌面卡片（Widget）
- `WidgetCard.ets` 完全独立、硬编码：**背景 `#1A1A2E`**、播放按钮 **`#1E88E5`（Material 蓝）**、文字 `#FFFFFF`/`#AAFFFFFF`、圆角 `8`——既不跟随深浅主题，也偏离品牌 `#FA2759`（F-08）。

---

## 2. 页面树与核心路径

```
Index(NavDestination 根, 经 navPathStack 路由)
└─ Layout (自建 Tab 壳: 音乐库 / 我的 + 底部迷你播放条胶囊栏)
   ├─ LocalLibrary        音乐库（搜索/导入/列表）──push──▶ PlayerPage
   ├─ Mine                我的（头像/统计/菜单）──push──▶ Favorites / Playlists / PlayHistory / Settings
   │   └─ Settings ─▶ SettingsCategory(appearance=深色模式 / accessibility=降低动态效果)
   ├─ Favorites           收藏列表 ─▶ PlayerPage / SongDetailSheet / AddToPlaylistSheet
   ├─ Playlists           我的歌单 ─▶ PlaylistDetail
   ├─ PlaylistDetail      歌单详情（拖拽排序/添加歌曲/移出）
   ├─ PlayHistory         播放历史
   ├─ ManageSongs         本地歌曲管理
   ├─ About / PrivacyPolicy
   └─ PlayerPage (NavDestination, 沉浸态, 一镜到底)
       └─ PlayerInfoComponent(单栏 Swiper / lg 双栏 / 折叠屏 FULL 双栏)
```

**核心路径**：音乐库 → 点歌（`interpolatingSpring` 转场 + `geometryTransition('player_cover')`）→ 播放页（封面模糊+取色渐变+暗化蒙层+歌词 Swiper）→ 底部队列/控制。

---

## 3. 组件选用表（ArkUI → 场景 → 状态）

| 区域 / 页面 | 选用组件 | 场景 | 状态 / 备注 |
|---|---|---|---|
| 根导航 | `NavDestination` + `@Consume('navPathStack')` | 应用级路由 | 自建 Layout 壳，隐藏 TitleBar ✅ |
| 底部 Tab | 自建胶囊栏 `Row`+`SymbolGlyph`（`barHeight(0)` Tabs） | 双 Tab 切换 | 非标准 TabBar，玻璃态 `BlurStyle.COMPONENT_ULTRA_THICK`；图标色用 `ACCENT` 本地常量（F-02） |
| 列表页 | `List`+`ForEach`+`ListItem` | 歌曲/歌单/历史 | 单列；lg 未多列（F-05） |
| 播放队列 | `List`+`.lanes()`+`@Reusable MusicListContainer`+`bindSheet` | 队列面板 | **深色断裂**（F-01） |
| 搜索 | `TextInput`+`Row` | 音乐库搜索 | OK |
| 空/加载/错误 | `Column`+`Image`+`LoadingProgress`/`Button` | 各空态 | OK，但次要灰 `#636366` 硬编码（F-14） |
| 详情面板 | `bindSheet`+`@Builder` | SongDetail/AddToPlaylist | **已主题化** `getThemeColors()` ✅ |
| 命名弹窗 | `CustomDialogController` | 新建/重命名歌单 | OK，按钮色 `#FA2759` 内联（F-02） |
| 播放页 | `Stack`/`GridRow`/`GridCol`/`Swiper`/`Slider` | 沉浸播放 | lg+折叠屏双栏 ✅；`ignoreLayoutSafeArea` ✅；强制暗化蒙层（F-18） |
| 进度 | `Slider(OutSet)` | 播放进度 | 用 `$r('app.color.slider_*')`，受 F-03 影响 |
| 头像/封面 | `CoverImageView`（`@State`+缓存刷新） | 列表封面 | 抽取得当 ✅ |
| 设置项 | `Toggle(Switch)`/`Select`/`Row` | 开关/选择 | `Toggle.selectedColor=accent` ✅（唯一用令牌处） |
| 统计/菜单项 | `Column`/`Row` 数字卡/图标卡 | Mine/Settings | 多色分散（F-07） |
| 桌面卡片 | `WidgetCard`（`@Entry` 动态卡片） | 播控 | 硬编码蓝+深色，未主题化（F-08） |

---

## 4. 交互与动效清单

| 交互 | 实现 | 规范符合度 |
|---|---|---|
| 页面转场「一镜到底」 | `geometryTransition('player_cover',{follow:true})` + `animateTo(interpolatingSpring(0,1,328,36/342,38))` | ✅ 符合 HarmonyOS 共享元素转场 |
| 列表项入场 | `TransitionEffect.OPACITY.combine(translateY)` + `.animation({duration:300, delay:index*50})` | ✅ 错峰入场 |
| 按压反馈 | 手写 `.onTouch` 缩放（0.96/0.85/0.75）+ `.animation({duration:120/150})` | ⚠️ 重复度高、时长不统一（F-11） |
| 空态呼吸 | `UIContext.animateTo` 循环（PLAYLISTS 明确避开属性动画冲突） | ✅ 优于 setInterval 驱动属性 |
| 歌词流光 / 控制条显隐 | `pageShowTime` 定时计数控制显隐 | ✅ 有「降低动态效果」开关但**未消费**（F-13） |
| 播放页沉浸 | `ignoreLayoutSafeArea` + 取色渐变 + `rgba(0,0,0,0.35)` 蒙层 | ✅ 一致（但强制暗化，F-18） |
| 长按菜单 | `bindContextMenu` / `bindMenu` | ✅ 标准用法 |
| 歌单拖拽排序 | `ForEach.onMove` 官方手势 | ✅ 用框架内建，避免自建手势 |
| 播放按钮 | `setInterval` 旋转封面（Layout.ets:70） | ⚠️ 44ms 高频轮询，建议 `requestAnimationFrame`/`animateTo` 持续动画 |

---

## 5. 断点 / 多端适配

- **断点体系**：`BreakpointConstants`（sm 320 / md 600 / lg 840）+ `BreakpointSystem`（mediaquery）+ `BreakpointType<T>` 取值 —— 体系完整 ✅。
- **折叠屏**：仅 `PlayerInfoComponent` 处理 `display.FoldDisplayMode.FULL`（`isFoldFull` 双栏）；`TopAreaComponent` 用 `per-song isDarkBackground` 控制投屏按钮对比色（F-18）。
- **平板（lg）**：仅播放页在 lg 用 `GridRow` 双栏（封面+控制 / 歌词）；**主列表（音乐库/歌单/收藏/历史/管理）仍为单列 `List`，未多列/未主从双栏**（F-05）。
- **车机/穿戴**：未在范围内，未预留。

---

## 6. 深色模式 Token 与无障碍

- **深色 Token**：`ThemeManager.DARK_TOKENS` 定义完整，页面经 `getThemeColors()` 取用，切换实时生效 ✅。
- **资源深色缺口**：`dark/color.json` 仅 `start_window_background`，其余 `$r('app.color.*')` 深色回退浅色（F-03）。
- **无障碍**：
  - 字号 `fp` ✅；但固定行高/高度在超大字体下可能挤压（P2）。
  - `reduceMotion` 已持久化（`SettingsCategory.ets:54,81,422`）但**全仓未被任何动画读取**（F-13）——「降低动态效果」开关形同虚设。
  - 图标按钮普遍缺 `.accessibilityText()/.accessibilityLevel()` 语义描述（F-13）。
  - 关键文本对比度：浅色 `secondaryText=#8E8E93` 在白底约 3.5:1（接近 AA 大文本阈值），建议加深深色或加粗；空态 `#636366` 更深但属硬编码（F-14）。
  - 多处空态/头像呼吸用 `setInterval`（Favorites/Mine/LocalLibrary/Playlists），需注意页面 `aboutToDisappear` 清理（代码已有守卫，但建议收敛到动画驱动）。

---

## 7. Findings 表（位置 / 问题 / 严重度 / 建议）

| # | 位置 | 问题 | 严重度 | 建议 |
|---|---|---|---|---|
| F-01 | `ControlAreaComponent.ets:101,112,145,299,317,334,396,397,413,440,449,488,502` | 播放队列半模态面板（musicListBuilder/sortBar/playListTitle/MusicListContainer）硬编码 `Color.White` 背景、`Color.Black/Red/Gray` 文字、 `#FA2759` 内联选中态与 `rgba(0,0,0,0.05)` 未选区；组件**未 import ThemeManager、无 `@StorageProp('isDark')`** | **P0** | 面板背景/文字改用 `getThemeColors().cardBg/primaryText/secondaryText`；当前播放项改 `accent`；选中排序标签用 `accent`+`accentSoft`；封装为受 `isDark` 控制的主题化 Sheet（与 SongDetailSheet 对齐） |
| F-02 | 约 50+ 处：`Layout.ets:26,142,147,167,182,195,200,204`；`LocalLibrary.ets:32,285,319,417,421,465,468,472,530,559`；`Favorites.ets:181,192,213,220,287,288`；`Playlists.ets:248,252,317,380,381,395,435,536`；`PlaylistDetail.ets:237,241,351,382,383,495,496,519`；`Mine.ets:170,178,183,218`；`AddToPlaylistSheet.ets:136,206,209` | 品牌色 `#FA2759` 大量内联；**重复定义 `const ACCENT`**（`Layout.ets:26` 与 `LocalLibrary.ets:32`）；`ThemeManager.accent` 令牌仅 SettingsCategory.ets:278、ManageSongs.ets:190 两处引用 | **P1** | 收敛为单一品牌源：在 ThemeManager 增 `accent`/`accentSoft`(alpha) 令牌，全量替换内联 + 删除重复 `ACCENT` 常量；`Checkbox/Toggle.selectedColor` 已用令牌，对齐即可 |
| F-03 | `resources/dark/element/color.json`（仅 `start_window_background`）；`base/element/color.json` 全量 | 深色资源令牌缺失：`slider_select/track`、`list_divider`、`play_text_color`、`singer_text`、`shadow_color`、`select_swiper` 深色下回退浅色值；Slider/divider 在深色依赖 base 回退 | **P1** | 在 `dark/color.json` 补全深色值（如 `list_divider→#2C2C2E`、`slider_track→#33FFFFFF` 保持、`shadow_color→#1A000000→#00000000` 等），或统一改用 ThemeManager 令牌，避免双源 |
| F-04 | `ThemeManager.ets:84`（`getColors()` 仅注释引用）；`resources/.../color.json` 并存 | 颜色系统双源：ThemeManager 语义令牌 与 color.json 资源令牌并存；`ThemeManager.getColors()` 定义后从未被页面调用（页面各自 `getThemeColors()`） | **P1** | 收敛单一来源：推荐以 resources light/dark 限定词 `$r('app.color.*')` 为唯一色源，或统一经 ThemeManager。清理 `getColors()` 死方法 |
| F-05 | `PlayerInfoComponent.ets:140-222`（lg/fold 双栏）；`LocalLibrary.ets`/`Favorites.ets`/`Playlists.ets`/`PlaylistDetail.ets`/`PlayHistory.ets`/`ManageSongs.ets` 列表 | 仅播放页适配平板/折叠屏；全部内容列表页为单列 `List`，未对 lg 做多列/主从双栏 | **P1** | lg 下主列表用 `List().lanes()` 或 `Grid/WaterFlow` 多列；或 `Navigation` 主从双栏（Master-Detail）；至少保证 lg 不浪费横向空间 |
| F-06 | `Layout.ets:268`；`Mine.ets:338`；`Favorites.ets:334`（TOP+BOTTOM）；`LocalLibrary.ets:608`（仅 TOP）；`SettingsCategory.ets`（无，靠 `topHeight` 手写 padding）；`PlayerPage.ets:71`（`ignoreLayoutSafeArea`） | 安全区/沉浸策略不统一，混合 `expandSafeArea` 与手动 `topHeight` padding 与 `ignoreLayoutSafeArea` | **P1** | 统一约定：内容页统一 `expandSafeArea([SYSTEM],[TOP,BOTTOM])` 或在 NavDestination 层统一注入安全区内边距，避免逐页手写 `topHeight` |
| F-07 | `Mine.ets:230,242,274,286,322`；`SettingsCategory.ets:386,390,406,422,435,439,446,458,470,486,490,494` | 分类图标底色与统计数字使用 Apple HIG 调色板（`#34C759/#FF9500/#007AFF/#5E5CE6/#FFCC00/#5856D6`），非 HarmonyOS Design 调色板，多色削弱品牌 `#FA2759` 识别度 | **P1** | 改用 HarmonyOS Design 语义/品牌色或统一中性底色；分类图标优先单色 Symbol 或统一灰度底 + 品牌强调 |
| F-08 | `WidgetCard.ets:98`（`#1E88E5`）、`:123`（`#1A1A2E`）、`:58,64` | 桌面播控卡片主按钮用 Material 蓝 `#1E88E5`（非品牌粉红），整卡硬编码深色 `#1A1A2E`，完全不跟随深浅主题 | **P1** | 主按钮改用品牌 `#FA2759`；卡片背景随系统深浅（读 `isDark` 选浅/深底），文本/图标对比度按主题取色；建议与 ThemeManager 共享令牌 |
| F-09 | `LocalLibrary.ets:260-337,339-434`；`Favorites.ets:175-253,96-173`；`PlaylistDetail.ets:398-460,159-254` | 歌曲列表项 `buildSongItem` + 长按菜单 `buildSongMenu` 三处近乎复制（各 ~80–175 行），菜单文案（播放/收藏/添加到歌单/详细/删除）硬编码于各页 | **P1** | 抽取公共 `@Component SongListItem`（cover+index+title+singer+playing+trailing）与 `@Builder songContextMenu(song, {onPlay,onFav,onAdd,onDetail,onRemove})`，参数/回调复用 |
| F-10 | 多处 `borderRadius(10/12/14/15/16/20/21/22/24/32)`：`Layout.ets:167,182,225`；`LocalLibrary.ets:320,432,473,512,560`；`Favorites.ets:171,221,289`；`Playlists.ets:263,327,394,436,548`；`PlaylistDetail.ets:252,373,384,440,519,546`；`Mine.ets:103,140`；`SettingsCategory.ets:257,287,303,329,345,373` | 圆角尺度发散，未收敛到统一半径令牌（`float.json` 仅 `cover_radius/cover_radius_label`） | **P2** | `float.json` 增 `radius_sm/md/lg/xl`（如 8/12/16/24）并统一引用 |
| F-11 | `Favorites.ets:235-252`；`LocalLibrary.ets:326-336`；`Playlists.ets:336-346`；`Mine.ets:146-156`；`PlaylistDetail.ets:449-458` | 按压反馈手写 `.onTouch`+`.animation({duration:120/150})`，重复度高、缩放系数（0.96/0.85/0.75）与时长不统一 | **P2** | 抽取 `@Styles`/`@Extend` 按压态（pressScale）统一交互反馈曲线/时长 |
| F-12 | `resources/base/media`（120+ png/svg）；`Layout.ets:64-65,186`（SymbolGlyph 混用） | 图标体系混杂：自定义 png/svg 与系统 Symbol 混用，png 不利着色/光学对齐 | **P2** | 统一优先 HarmonyOS Symbol（矢量符号）；自定义图标统一可着色 svg + 统一线宽；删除冗余 png |
| F-13 | `SettingsCategory.ets:54,81,422`（reducedMotion 已存未消费）；各图标按钮（`Image` 无 `accessibilityText`）；`Favorites/Mine/LocalLibrary/Playlists` 空态 `setInterval` 呼吸 | 无障碍：①`reduceMotion` 偏好已持久化但**全仓未被任何动画读取**，歌词流光等照常运行；②图标按钮缺语义描述；③脉冲用 setInterval | **P2** | `reduceMotion` 为真时降级/关闭非必要动画（歌词流光、入场错峰、呼吸）；图标按钮加 `.accessibilityText()`；脉冲改动画驱动 |
| F-14 | `Favorites.ets:312`；`PlaylistDetail.ets:577`；`Playlists.ets:429` | 次要文字色 `#636366` 硬编码，与 `secondaryText` 令牌（浅 #8E8E93 / 深 #98989F）不一致 | **P2** | 改用 `secondaryText` 令牌 |
| F-15 | `Favorites.ets:285-290`；`Playlists.ets:378-384`；`PlaylistDetail.ets:493-498` | 同类「计数徽章」（`#FA2759` 文字 + `rgba(250,39,89,0.1)` 底）在 3 页重复实现 | **P2** | 抽 `@Builder CountBadge(count,label)` 统一（依赖 F-02 令牌） |
| F-16 | 大量硬编码中文文案：`'我的收藏'/'我的歌单'/'播放历史'/'设置'/'关于'/'音乐库'/'导入'/'搜索歌曲、艺术家'/'共 X 首歌曲'/'收藏'/'取消收藏'/'添加到歌单'/'详细'/'删除'/'移出歌单'/'歌单还没有歌曲'` 等 | UI 文案未完全资源化（`string.json` 仅 35 项，多为系统/权限/排序/队列），不利多语言与一致 | **P2** | 用户可见文案迁移 `resources/base/element/string.json`（局部已用 `$r('app.string.*')`，补全即可） |
| F-17 | 每页 `@StorageProp('isDark') isDark`+`getThemeColors()` 样板（Layout/Mine/SettingsCategory/Favorites/LocalLibrary/Playlists/PlaylistDetail/About/SongDetailSheet/AddToPlaylistSheet/Mine… 共 13+）；`const ACCENT` 重复；`StyleConstants.FULL_WIDTH/FULL_HEIGHT` 与 `'100%'` 并存 | 主题消费样板大量重复；`ThemeManager.getColors()` 死代码；常量/写法不统一 | **P2** | 抽取共享主题混入（`@Styles` 或基类）统一 `getThemeColors()`；清理 `getColors()` 与重复 `ACCENT`；统一尺寸写法（`FULL_WIDTH` 或 `'100%'` 择一） |
| F-18 | `PlayerInfoComponent.ets:136,330`（暗化蒙层 + `lyricBgDark` 恒 true）；`TopAreaComponent.ets:43-48`（per-song `isDarkBackground` 直接算 White/Black） | 播放页强制暗化蒙层，浅色主题下播放页仍为暗色（沉浸设计但偏离「主题化表面」）；`TopAreaComponent` 直接据封面亮度算 White/Black，绕过令牌体系 | **P2（设计观察）** | 播放页暗化为有意为之，建议文档化；若希望浅色主题播放页更亮，可据 `isDark` 调蒙层强度。`TopAreaComponent` 的「媒体自适应对比」属合理模式，但应集中为对比度 helper，避免逐组件绕过令牌 |

---

## 8. 优先级与落地建议（给开发与架构）

1. **P0（立即）**：修 F-01 播放队列面板深色化（背景/文字改用 `getThemeColors().cardBg/primaryText`，当前项用 `accent`，选中排序标签用 `accent`+`accentSoft`）。这是唯一用户可见的明暗断裂，且修复成本低（纯着色改造）。
2. **P1（本迭代）**：
   - F-02 + F-03 + F-04：收敛颜色为单一来源，新增 `accent`/`accentSoft` 令牌并替换约 50 处内联 + 删除重复 `ACCENT`；补全 `dark/color.json`；清理 `getColors()` 死方法。
   - F-08：桌面卡片改品牌色 + 跟随主题（高频可见的离品问题）。
   - F-09：抽 `SongListItem` + `songContextMenu` 公共组件，消除三处复制。
   - F-05：lg 主列表多列 / 主从双栏。
   - F-06：统一安全区策略。
   - F-07：分类图标/统计去 iOS 调色板，回归 HarmonyOS 品牌。
3. **P2（后续优化）**：F-10~F-17 统一圆角/按压/图标/无障碍/文案/清理；F-13 落地 `reduceMotion` 全局消费；F-18 文档化播放页沉浸策略。

> **设计系统健康度**：颜色令牌「单一来源 + light/dark 限定词」是后续所有修复的基石。建议先定《Lumio 设计 Token 规范》（color / radius / spacing / font 资源 + 品牌色），再驱动代码替换；优先修 P0（F-01）与品牌离品项（F-08），即可在最小改动下消除最强用户感知缺陷。

---

*报告生成：蓝绘心（鸿蒙 UI/UX 设计专家）。本体检为独立复核，所有行号基于本次实读源码。*
