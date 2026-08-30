# Lumio Music · 设计系统（Apple 风格 / iOS 语义 + 弹簧动效 + 毛玻璃）

> 本文件定义 Lumio Music 的统一视觉与动效语言，所有页面/组件应引用语义令牌，禁止写死 hex。
> 实现入口：`entry/src/main/ets/common/utils/DesignSystem.ets`；主题联动：`ThemeManager.apple()`。

---

## 1. 设计原则
1. **语义化取色**：背景/填充/标签/分隔线/系统色分浅深两套，组件只认令牌。
2. **分层圆角**：sm 10 / md 14 / lg 20 / pill 999（iOS 规范）。
3. **弹簧动效为核心**：按钮、图标、卡片入场统一 `interpolatingSpring`，替代线性/缓动。
4. **毛玻璃造景深**：浮层、控制条、Sheet 用 `backdropBlur` + 半透明填充。

## 2. 颜色令牌（`AppleTokens`）
| 类别 | 浅色 | 深色 |
|------|------|------|
| systemBackground | `#FFFFFF` | `#000000` |
| secondarySystemBackground | `#F2F2F7` | `#1C1C1E` |
| systemGroupedBackground | `#F2F2F7` | `#000000` |
| systemFill / secondary/tertiary/quaternary | `rgba(120,120,128,0.20→0.08)` | `rgba(120,120,128,0.36→0.18)` |
| label | `#1C1C1E` | `#FFFFFF` |
| secondaryLabel | `rgba(60,60,67,0.60)` | `rgba(235,235,245,0.60)` |
| separator | `rgba(60,60,67,0.29)` | `rgba(84,84,88,0.60)` |
| systemBlue / Green / Orange / Red / Purple | `#007AFF / #34C759 / #FF9500 / #FF3B30 / #5856D6` | `#0A84FF / #30D158 / #FF9F0A / #FF453A / #BF5AF2` |
| **品牌强调色** `BRAND_ACCENT` | `#FA2759`（全局唯一，保持） | 同左 |

取色：`appleColors(isDark)` 或 `ThemeManager.apple()`（已含响应性）。

## 3. 动效（`Motion` + 弹簧预设）
| 令牌 | 值 | 用途 |
|------|----|------|
| `Motion.tap` | 120ms | 点按回弹 |
| `Motion.press` | 150ms | 按压 |
| `Motion.sheet` | 360ms | 半模态 |
| `Motion.fade` | 300ms | 淡入淡出 |
| `Motion.stagger` | 60ms | 列表错峰 |
| `springSnappy()` | stiffness 380 / damping 30 | 按钮/图标 |
| `springSoft()` | stiffness 280 / damping 24 | 卡片/入场 |
| `springGentle()` | stiffness 200 / damping 20 | 共享元素/转场 |

用法示例：
```ts
import { Motion, springSnappy } from '../common/utils/DesignSystem';
Image($r('app.media.ic_x'))
  .scale({ x: this.scale, y: this.scale })
  .animation({ duration: Motion.tap, curve: springSnappy() })
```

## 4. 毛玻璃（`Glass`）
- 模糊半径：`Glass.blur = 30`
- 填充：`Glass.bg(isDark)` → 浅 `rgba(255,255,255,0.62)` / 深 `rgba(28,28,30,0.62)`
```ts
Column() { /* 控制条内容 */ }
  .width('100%')
  .backgroundColor(Glass.bg(this.isDark))
  .backdropBlur(Glass.blur)
  .borderRadius(Radius.lg)
```

## 5. 圆角（`Radius`）与共享元素（`TransitionId`）
- `Radius.sm/md/lg/pill`
- 一镜到底 ID：`TransitionId.cover = 'player_cover'`（列表封面 / 播放页封面用同一 ID 触发共享元素转场）。

## 6. API 26 新特性使用清单
- `HdsNavigation`（`@kit.UIDesignKit`）作为根导航容器。
- `NavDestination.onWillShow / onWillHide` 生命周期驱动入场弹簧。
- `geometryTransition` 一镜到底（封面）。
- `@Reusable` + `reuseId` 组件复用池（队列面板）。
- **AppStartup**（`@kit.AbilityKit`）：`LumioCoverPreloadTask` + `LumioStartupConfig` + `startup_config.json`，AbilityStage 构造期并行预执行轻量初始化。
- **ContainerReader**（`@kit.ArkUI`，API 26 新增）：`MusicInfoComponent` 以 `ContainerReader({size})` 包裹 `GridRow`，`onAreaChange` 回填容器真实尺寸 + `breakpointConfig` 实现「基于容器尺寸」而非窗口尺寸的断点自适应。
- **AttributeString / StyledString**：`MusicInfoComponent` 歌曲标题+歌手合并为 `StyledString`（多 run 差异化样式），经 `TextController.setStyledString` 绑定到 `Text`，替代多 `Text` 拼接。
- **uiMaterial**（`@ohos.arkui.uiMaterial`）：`SongDetailSheet` 根容器 `.systemMaterial(ImmersiveMaterial.REGULAR)` 启用系统级沉浸毛玻璃，与 iOS 系统材质一致（材质优先级高于 backgroundColor，不再重复设背景色）。
- 沉浸光感系统材质在 Dialog/Toast 默认开启（无需显式调用）。

## 7. 组件接入检查表
- [ ] 颜色一律走 `ThemeManager.apple()` / `appleColors()`，不写死 hex（品牌色除外）。
- [ ] 点按反馈用 `springSnappy()`。
- [ ] 浮层/控制条/Sheet 用 `Glass` 毛玻璃。
- [ ] 卡片圆角用 `Radius` 令牌。
- [ ] 封面 `geometryTransition(TransitionId.cover)` 保持与播放页共享。

## 8. 悬浮导航胶囊 / 半蒙面 Sheet / 选项图标 / 歌词手势（2026-08-30 第二轮增补）

### 8.1 底部悬浮导航胶囊（居中浮动）
- 形态：**居中浮动胶囊**（`Stack({alignContent: Alignment.Bottom})` 内、`width('92%').constraintSize({ maxWidth: 520 })` 居中），非通栏。
- 外观：`backgroundColor(cardBg)` + `shadow(radius 22, rgba(0,0,0,0.18), offsetY 8)` + `borderRadius(30)` + `margin({ bottom: bottomHeight + 12 })`。
  - API 26：`import type uiMaterial`（编译期擦除）+ `aboutToAppear` 动态 `import('@ohos.arkui.uiMaterial')` 注入 `ImmersiveMaterial.REGULAR`，外层 `Row` 挂 `.systemMaterial(...)`。
  - API 24：降级 `.backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)`。
  - ⚠️ 材质/毛玻璃必须挂在**真实容器组件**（`Row`）上，不能链式挂在 `@Builder` 调用（返回 `void`）上。
- **点按回弹**：每个 tab 与播放按钮加 `.scale({x,y})` + `.animation({ duration: Motion.tap, curve: springSnappy() })`；`.onTouch` Down→`scale 0.9` / Up→`1.0`，苹果风跟手反馈。

### 8.2 半蒙面 Sheet（设置 / 关于）
- 设置、`SettingsCategoryDetail`、关于均为**普通组件**，**共用同一个 `bindSheet`**（由 `Mine.ets` 的 `sheetVisible`/`sheetKind` 状态切换渲染 `Settings` 或 `About`，避免同一节点挂两个 `bindSheet` 互相干扰导致串台/打不开）；`detents: ['90%']`（LARGE 大屏）、`dragBar: true`、`showClose: true`；默认蒙层即"半蒙面"效果，无需 `mask` 选项（本 SDK `SheetOptions` 无 `mask`/`preferType`/`SheetType`/`SheetSize`）。
- **Sheet 内页面跟随应用浅/深主题（已撤销强制灰底白字）**：设置/关于/二级分类详情与全应用其它页面一致，均按 `@StorageProp('isDark')` 取 `ThemeManager.lightColors`/`darkColors`（浅色=白底深字、深色=黑底白字）。第三轮曾为三组件加 `@Prop sheetStyle` 并在 `Mine` 渲染时传 `true`，`getThemeColors()` 在 `sheetStyle` 下返回 `ThemeManager.sheetColors`（灰底 `#2C2C2E` + 白字 `#FFFFFF`）——但会无视浅色主题、导致浅色模式下 sheet 变深色；第四轮已回退：删除 `sheetStyle` prop 与 `ThemeManager.sheetColors` getter，`Mine` 渲染不再传 `sheetStyle`，`getThemeColors()` 直接返回 `isDark` 分支。
- sheet 内二级导航：`Settings` 用 `@State selectedCategory` 在根列表与 `SettingsCategoryDetail` 间切换（二者 `TransitionEffect.OPACITY.combine(translate)` 转场，子页同样灰底白字），深层页（ManageSongs / PrivacyPolicy）经 `onNavigate` 关闭 sheet 并走主导航栈 `pathStack.pushPathByName`。
- 历史路由壳保留：`SettingsBuilder()` / `AboutBuilder()` / `SettingsCategoryBuilder()` 仍为 `NavDestination`（兼容旧路由名）。

### 8.3 选项图标去底色
列表/设置选项左侧图标只用图标本身，禁止 `Stack{Image.fillColor(White)}.backgroundColor(iconColor)` 底色块；统一 `Image(icon).width(24).height(24).fillColor(iconColor).margin({ right: 16 })`。点按反馈：`@State pressed` + `onTouch` 高亮 `rgba(120,120,128,0.12)`，松开复位。

### 8.4 歌词手势（PanGesture 跟手）
`LrcView` Canvas 改用 `PanGesture({ direction: Vertical, distance: 4 })`：
- `onActionStart`：复位 `lastPanY=0`、取消自动回位、`isUserScrolling=true`；
- `onActionUpdate`：`dy = event.offsetY - lastPanY`，累加到 `userOffsetY` 并重绘（`drawContent`）——增量派发，跟手顺滑；
- `onActionEnd`：触发自动回位定时器；
- 点击跳转走独立 `.onClick`（与 pan 天然分离，杜绝"滑动误触点击"）。

### 8.5 一镜到底进入/退出对称
`Layout.openPlayer()` 的 `pushPathByName` 与 `PlayerPage.back()` 的 `pop` 均包 `animateTo({ curve: curves.interpolatingSpring(0,1,342,38) })`，共享 id `player_cover`。
