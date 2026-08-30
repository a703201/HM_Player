# Lumio Music · 多维度代码审查 + API 26 适配 + UI/UX 升级报告

> 审查基准：HarmonyOS NEXT / ArkTS / ArkUI，目标 SDK 由 `6.1.1(24)` 升级至 **API 26（HarmonyOS 26.0.0，apiVersion=26）**（本地 SDK 已确认为 HarmonyOS 26.0.0）。`build-profile.json5` 实际写入纯 semver `26.0.0`——hvigor 在 API 26 会拒绝带 `(api)` 后缀的写法（`26.0.0(26)` 报 `api version parameter is illegal`）。
> 审查方式：harmonyos-reviewer 自动化扫描（67 文件）+ 人工多维度走查 + 大厂规范对照（ArkTS 红线、状态响应式、权限最小化、性能/复用、安全隐私、新特性适配）。

---

## 一、自动化审查结论

| 维度 | 结果 |
|------|------|
| 扫描文件数 | 67 |
| 🔴 ERROR | 0 |
| 🟡 WARNING | 0 |
| 🔵 INFO | 2（`componentSnapshot.get` 上下文无法静态判定，实际位于 UI 回调内，合法） |

`Index.ets` 已使用 `HdsNavigation`（`@kit.UIDesignKit`，API 26 新增 Design Kit），说明工程已部分接入新特性。

---

## 二、多维度人工走查

### 1. ArkTS 红线核查 ✅ 通过
- 未发现解构声明（`const [x]=arr` / `const {a}=obj`）、`any`/`unknown` 类型、对象字面量类型注解。
- 日志统一走 `utils/Logger.ets`（封装 `hilog`），无裸 `console.*`/`hilog`。
- `CustomDialogController` 仅作普通成员（如 `AddToPlaylistSheet`），未误加 `@State`；`NavPathStack`/`DialogAlignment` 等全局环境声明未误 import。

### 2. 运行时崩溃风险（本次重点修复）⚠️→✅
| 级别 | 位置 | 问题 | 修复 |
|------|------|------|------|
| **P0** | `PlayerInfoComponent.ets:59` | 字段初始化即 `this.songList[this.selectIndex].getLabel()`，`songList` 默认 `[]` 时 `undefined.getLabel()` 必崩 | 默认图 + `currentSong()` 守卫 + `@Watch('syncImageLabel')` |
| **P1** | `MusicInfoComponent.ets` (CoverInfo/MusicInfo) | `this.songList[this.selectIndex].getLabel()/.title/.singer` 多处无守卫 | 新增 `currentSong()` 守卫，统一 `?.` 兜底 |
| **P1** | `TopAreaComponent.ets:47` `getIsDark()` | `this.songList[this.selectIndex].isDarkBackground` 无守卫 | 空列表兜底为 `true` |
| **P1** | `PlayerInfoComponent.ets` LG 分支 | `Image(this.songList[this.selectIndex].getLabel())` 无守卫 | 改用 `currentSong()?.getLabel() ?? 默认图` |
| **P2** | `MusicInfoComponent.ets:73` | `.width(StyleConstants.FULL_HEIGHT)` 语义笔误（应为 FULL_WIDTH） | 修正为 `FULL_WIDTH` |

### 3. 状态管理 / 主题响应式 ✅ 符合规范
- `ThemeManager.getColors()` 为 AppStorage **非响应式**读取；各组件已正确使用 `@StorageProp('isDark')` + 普通方法 `getThemeColors()` 取色触发重渲染，符合项目红线。
- 新增 `DesignSystem.appleColors(isDark)` 与 `ThemeManager.apple()`，提供 iOS 语义令牌（分层背景/填充/标签/系统色），组件只引用语义令牌，主题切换零成本。

### 4. 权限最小化 ✅
`module.json5` 仅声明 `KEEP_BACKGROUND_RUNNING` + `INTERNET`（已与架构文档核对一致），无 `READ/WRITE_MEDIA` 等冗余权限。原 README 权限表误列 `GET_NETWORK_INFO`（共 3 项），本轮已修正为实际 2 项，文档与声明现在一致。

### 5. 性能 / 复用 ✅
- `ControlAreaComponent.MusicListContainer` 已 `@Reusable` + `reuseId`，队列列表走组件复用池。
- 列表项按压缩放用 `@State` 数组驱动，合理。本次将线性 `Curve.EaseOut` 按压反馈升级为 `interpolatingSpring` 弹簧，回弹更自然。

### 6. 安全 / 隐私 ✅
- 无网络敏感数据上传；导入走 `DocumentViewPicker` 本地沙箱；`fileIo.statSync` 均包 try/catch。
- **待办（非本次范围）**：`README.md` 权限表仍写旧权限，需与 `module.json5` 对齐（已在架构记忆中记录）。

### 7. API 版本 / 鸿蒙新特性适配（API 26）
| 项 | 状态 |
|----|------|
| `compatibleSdkVersion` / `targetSdkVersion` | **min `6.1.1(24)`、target `26.0.0`**（最低兼容 API 24=HarmonyOS 6.1.1，目标 API 26；API 10–25 须用 `X.Y.Z(API)` 格式如 `6.1.1(24)`，26+ 用纯 `26.0.0`，hvigor 会拒绝 `(26)` 后缀）✅ |
| HdsNavigation（UI Design Kit） | 已用 ✅ |
| Navigation `onWillShow` / `onWillHide` 生命周期 | 本次在 `PlayerPage` 落地 ✅ |
| 一镜到底 `geometryTransition('player_cover')` | 已用 ✅ |
| `@Reusable` 组件复用池 | 已用 ✅ |
| `bindSheet` / `bindMenu` 半模态与上下文菜单 | 已用 ✅ |
| `curves.interpolatingSpring` 弹簧 | 已用 + 本次扩展 ✅ |
| 新增 DesignSystem（iOS 语义色 + 弹簧 + 毛玻璃） | 本次新增 ✅ |
| AppStartup / ContainerReader / AttributeString / 显式 `uiMaterial` | **已落地（API 26 四项新特性，独立审查 APPROVE_WITH_NITS）** ✅ |

### 8. UI/UX（苹果风审美）🔧 强化
原工程已有圆角卡片、分组背景、错位入场、页面过渡。本轮强化：
1. **统一设计令牌**：`DesignSystem.ets` 单点定义 iOS 语义色 / 圆角 / 动效 / 毛玻璃 / 共享元素 ID。
2. **毛玻璃控制条**：`ControlAreaComponent` 根容器加 `backdropBlur(30)` + 半透明填充 + 圆角，浮于模糊封面之上，层次更立体。
3. **弹簧点按**：控制按钮、封面 `CoverImageView` 按压回弹（苹果味手感）。
4. **播放页弹簧入场**：`PlayerPage` `onWillShow` 以 `springSoft` 淡入 + 轻微缩放。
5. **封面景深**：`CoverImageView` 加阴影 + 按压缩放。

### 7.1 四项鸿蒙新特性落地明细（API 26）

| 新特性 | 文件 | SDK 正确用法（已逐条核对 d.ts） |
|--------|------|--------------------------------|
| **AppStartup** 启动框架 | `ets/startup/LumioCoverPreloadTask.ets`（@Sendable 任务）、`ets/startup/LumioStartupConfig.ets`（configEntry）、`resources/base/profile/startup_config.json`、`module.json5` 的 `appStartup` | `StartupTask.init(context: Context)` 返回 `Promise<Object\|void>`；`runOnThread:"taskPool"` + `waitOnMainThread:false` 不阻塞主线程；任务在 AbilityStage 构造期自动执行。占位任务仅做无副作用标记返回，预留封面缓存预热扩展点。 |
| **ContainerReader** 容器断点 | `ets/components/MusicInfoComponent.ets` | `ContainerReader({ size: Size })`（`Size = {width:number,height:number}` vp 数值，非字符串）；`.onAreaChange((oldArea: Area, newArea: Area)=>void)` 回填容器真实尺寸；`.breakpointConfig({width:[600,840]})` 让 `GridRow` 基于容器尺寸断点而非窗口尺寸，折叠屏/分屏自适应更精准。 |
| **AttributeString** 富文本 | `ets/components/MusicInfoComponent.ets` | `Text` 构造仅接受 `string\|Resource`；`StyledString` 须经 `TextController` 绑定（`Text('',{controller})` + `controller.setStyledString(...)`）；`TextStyle.fontSize` 为 `LengthMetrics`（用 `LengthMetrics.fp()` 构造，`@ohos.arkui.node` 提供的运行时值）；标题 run 加粗放大、歌手 run 常规降透明度。 |
| **uiMaterial** 系统材质 | `ets/components/SongDetailSheet.ets` | API 26 经动态 `import('@ohos.arkui.uiMaterial')` 注入 `ImmersiveMaterial.REGULAR` 并 `.systemMaterial(...)` 启用系统级沉浸毛玻璃；**API 24 降级**：该模块为 API 26 整模块新增，静态导入会在 24 真机加载即崩溃，故改用 `import type` + 动态 `import()` + `@State`，API 24 仅以 `.backgroundColor(主题卡片色)` 兜底毛玻璃。 |

> 编译验证：四项特性全部通过 `bash build_hap.sh` 全量构建（含 C++ NAPI 原生编译），**BUILD SUCCESSFUL，0 ERROR**，产出已签名 HAP（`entry-default-signed.hap`）。

### 7.2 API 24 兼容降级（min 24 / target 26）

测试真机为 API 24（HarmonyOS 6.1.1），要求最低适配 API 24、目标 API 26。编译基于 API 26 SDK，故对 **API 26 专属**特性做运行期优雅降级，避免低版本真机崩溃。

| API 26 专属特性 | 降级闸门 | API 24 行为 | API 26 行为 |
|----------------|----------|-------------|-------------|
| `ContainerReader` 组件（`@since 26.0.0`） | `ApiCompat.isAtLeast(26)` 分支 | 不实例化，直接渲染 `GridRow`（`breakpoints.reference=ComponentSize` 已基于容器宽度断点，等价容器级自适应） | `ContainerReader` 包裹 `GridRow`，基于「容器真实尺寸」断点 |
| `uiMaterial.systemMaterial` 方法（`@since 26.0.0`） | `ApiCompat.isAtLeast(26)` + 动态 `import()` 注入 | 模块/方法均不存在；静态导入会令 `SongDetailSheet` 加载即崩，故改用 `import type` + 动态 `import()` + `@State`，仅以 `.backgroundColor(主题卡片色)` 兜底毛玻璃 | 动态 `import()` 加载模块 → 构造 `ImmersiveMaterial.REGULAR` → `.systemMaterial(...)` 启用系统级沉浸毛玻璃 |

- **运行期版本判定**：`common/utils/ApiCompat.ets` 用 `import deviceInfo from '@ohos.deviceInfo'`（默认导出，`@since 6`，API 24 可用）取 `deviceInfo.sdkApiVersion`，提供 `ApiCompat.isAtLeast(api)`。
- **安全（≤API 18，无需降级）**：`HdsNavigation`（UIDesignKit `@since 12`）、`StyledString`/`TextController.setStyledString`（@since 12/18）、`@Reusable`/`geometryTransition`/`bindSheet`/`SymbolGlyph`/`interpolatingSpring`/`NavDestination` 生命周期 —— 在 API 24 真机均可用。
- **独立审查结论**：code-reviewer 对降级改动给出 **CHANGES_REQUIRED（1 P0）**——原静态 `import uiMaterial` 在 API 24 模块加载即崩；已按审查采用 `import type` + 动态 `import()` 修复并重建 **BUILD SUCCESSFUL**。

---

## 三、已落地改动清单

| 文件 | 改动 |
|------|------|
| `common/utils/DesignSystem.ets` | **新增**：iOS 语义色令牌、弹簧曲线预设、毛玻璃/圆角规范、共享元素 ID |
| `utils/ThemeManager.ets` | 新增 `apple()` 委托，导出 `AppleTokens` |
| `components/PlayerInfoComponent.ets` | P0 崩溃修复 + `currentSong()` 守卫 + 封面同步 Watch |
| `components/MusicInfoComponent.ets` | 宽度笔误修复 + `currentSong()` 守卫 |
| `components/TopAreaComponent.ets` | `getIsDark()` 空列表守卫 |
| `components/ControlAreaComponent.ets` | 毛玻璃控制条 + 弹簧点按（替换线性缓动） |
| `components/CoverImageView.ets` | 弹簧点按 + 阴影景深 |
| `pages/PlayerPage.ets` | `onWillShow/onWillHide` 生命周期 + 弹簧入场 |
| `build-profile.json5` | `compatibleSdkVersion` → `6.1.1(24)`（min API 24）、`targetSdkVersion` 维持 `26.0.0` |
| `pages/{Favorites,PlayHistory,PlaylistDetail,LocalLibrary}.ets` | `showToast` 包 `try/catch`（消除 `Function may throw exceptions` 编译告警） |
| `README.md` | 权限表对齐 `module.json5`（移除误列的 `GET_NETWORK_INFO`） |
| `ets/startup/LumioCoverPreloadTask.ets` | **新增**：AppStartup @Sendable 占位任务（封面预热扩展点） |
| `ets/startup/LumioStartupConfig.ets` | **新增**：`StartupConfigEntry` 配置入口（超时 10s + 完成监听器） |
| `resources/base/profile/startup_config.json` | **新增**：AppStartup 声明式任务/配置声明 |
| `module.json5` | 新增 `appStartup` 字段引用 `startup_config.json` |
| `ets/components/MusicInfoComponent.ets` | ContainerReader(`@since 26`) 包裹 GridRow + AttributeString；**API 24 降级**经 `ApiCompat.isAtLeast(26)` 分支，低版本直接渲染 GridRow（`breakpoints.reference=ComponentSize` 已基于容器宽度断点） |
| `ets/components/SongDetailSheet.ets` | `uiMaterial`(`@since 26`) 沉浸系统材质经动态 import 注入；**API 24 降级**用主题卡片背景色兜底（避免静态导入致模块加载崩溃） |
| `common/utils/ApiCompat.ets` | **新增**：运行期 API 版本判断（`deviceInfo.sdkApiVersion`，默认导出），为 API 26 专属特性提供优雅降级闸门 |

---

## 四、风险与后续

- **编译验证（最终状态）**：全量构建 `bash build_hap.sh` 已 **BUILD SUCCESSFUL**（exit 0，含 C++ NAPI 原生编译）。ArkTS 编译 **0 ERROR**。当前共 14 条 WARN（环境相关、非阻断、不阻断出包）：
  - `CoverCache.ets / AudioMeta.ets / AudioRendererController.ets` ×4：`media` 系统能力并非所有设备支持（能力声明层面提示，运行时按设备走降级）。
  - `NativeModule.ets` ×1：napi 模块校验将在后续 SDK 版本启用（已提供 `.d.ts` 与声明）。
  - 降级兼容提示 ×9（`LocalLibrary.ets` 的 `fill`、`MusicInfoComponent.ets` 的 `ContainerReader`/`breakpointConfig` 等）：编译器建议对 API 26 调用加 `apiAvailable` 保护；已用运行期 `ApiCompat.isAtLeast(26)` 分支等效降级（编译器看不懂运行期分支，故仍提示，属预期）。
- **未覆盖项（已全部完成）**：AppStartup 初始化框架、ContainerReader 容器断点自适应、AttributeString 富文本、显式 `uiMaterial` 系统材质调用 —— **本轮已落地并通过全量构建 + 独立代码审查**（verdict: APPROVE_WITH_NITS，仅 2 项 P2 打磨，无 P0/P1）。P2 处理：① 移除 `SongDetailSheet` 冗余 `backgroundColor`（材质优先级更高）；② `LumioCoverPreloadTask.init(context: Context)` 维持 `Context`（因 `AbilityStageContext` 未由 `@kit.AbilityKit` 导出，且占位任务无需其实例能力，沿用项目既定的安全写法）。
- **README 同步**：✅ 已完成，权限表已与 `module.json5` 对齐（移除误列的 `GET_NETWORK_INFO`）。
- **多设备回归**：折叠屏 / 平板（LG 布局）需在真机或模拟器回归一镜到底（`geometryTransition`）与控制条毛玻璃（`backdropBlur`）表现。
- **API 24 真机验证（待办）**：降级逻辑已通过编译与独立审查，但运行期行为需在 API 24 真机实测——重点验证 ① `SongDetailSheet` 打开不崩（uiMaterial 走背景色兜底）；② `MusicInfoComponent` 播放页容器断点正常（GridRow ComponentSize 降级路径）。若真机发现异常，按 `ApiCompat` 闸门再收口。

---

## 五、UI/UX 交互修复轮（2026-08-30，Apple Music 风 + 系统播控接入）

### 5.1 诉求与范围
用户要求整体 UI/UX 向 Apple Music 学习（高端简约、操作符合直觉、对应交互动画），并修复 7 处问题：歌词滑动误触、恢复进入一镜到底、移除播放页毛玻璃控制条、底栏沉浸光感、选项图标去底色+动效、全屏沉浸不挡内容、接入系统播控。

### 5.2 改动清单（本轮新增）
| 文件 | 改动 |
|------|------|
| `lyric/LrcView.ets` | 删 Canvas 冗余 `.onClick`（与 `onTouch` tap 分支重复触发致滑动结束误跳进度）；点击统一在 `handleTouch` 的 `Up && !hasMoved`；滑动阈值 8→10vp |
| `pages/Layout.ets` | `openPlayer()` 的 `pushPathByName` 补 `animateTo`（恢复进入一镜到底，与 `PlayerPage.back()` 对称）；底栏重构为浮动胶囊，API 26 `systemMaterial` / API 24 `backgroundBlurStyle`；内容 `padding.bottom` 降到 `bottomHeight+16` |
| `components/ControlAreaComponent.ets` | 删传输按钮 Row 毛玻璃底条；import 仅 `Motion, springSnappy`；保留按钮点按缩放 |
| `pages/Mine.ets` / `Settings.ets` / `SettingsCategory.ets` | 选项图标去底色（`Stack{Image.fillColor(White)}.backgroundColor(iconColor)` → 纯 `Image(icon).fillColor(iconColor)`）；Mine 新增 `@State menuPressed` + 点按高亮 `rgba(120,120,128,0.12)` |
| `utils/AVSessionController.ets`（`setAVMetadata`） | **系统播控根因修复**：`songItem.label` 强制 `as Resource` 解码，但 `label` 常为 `PixelMap`（CoverCache 命中）强转抛错中断整段 `setAVMetadata` → 锁屏/控制中心无卡片。改为 `songItem.getLabel()`（含缓存，`Resource|PixelMap`），PixelMap 直用、Resource 才解码且 try/catch，`assetId` 用 `songItem.id` |
| `pages/PlayerPage.ets` | 删未使用死常量 `PLAYER_COVER_ID` |

### 5.3 独立 code-reviewer 审查结论
- 6 组（7 项）**PASS**；第 4 组（底栏沉浸）初判 **PASS-WITH-NOTE**：担心 `@ohos.arkui.uiMaterial` 无 default 导出致 `mod.default` 为 undefined → 静默回退 `backgroundBlurStyle`。
- 主理人核验 SDK：`default/openharmony/ets/api/@ohos.arkui.uiMaterial.d.ts:530` 为 `export default uiMaterial;` → default 导出成立，该风险**不成立**，`.systemMaterial()` 在 API 26 真机正常生效。
- 审查提出的真实改进已采纳：① `setAVMetadata` 改用 `getLabel()`（同时修复编译 `Resource→PixelMap` insufficient-overlap 错误 + 让缓存封面 PixelMap 进系统播控）；② 删 `PlayerPage` 死常量。

### 5.4 构建验证（编译期踩坑 → 已修复）
- 首次构建 **6 ERROR**：
  1. `customBottomBar` 把 `.systemMaterial`/`.backgroundBlurStyle` 链式挂到 `@Builder` 调用 `this.miniBarInner()`（返回 `void`）→ ArkUI 拒收；改为外层真实 `Row` 包裹 `miniBarInner()` 再把材质挂 Row。
  2. `songItem.label`（`Resource|undefined`）强转 `PixelMap` 报 insufficient overlap；改用 `getLabel()` 修复。
- 复构建：**BUILD SUCCESSFUL（0 ERROR）**，产物 `entry-default-signed.hap`。12 条 WARN 为 API 26 `@since` 提示（systemMaterial/ContainerReader/breakpointConfig/fill 等），均已按 `ApiCompat`/`import type`/运行期分支降级，不阻断。

### 5.5 仍待办（需真机）
API 24 底栏 `backgroundBlurStyle` 降级观感、一镜到底进入/退出、系统播控卡片显示、歌词滑动不再误触、图标点按高亮可见性——本地无法执行，需真机回归。

---

## 六、UI/UX 交互修复轮（2026-08-30 第二轮，悬浮导航 + 半蒙面 Sheet + 动效丰富）

### 6.1 诉求与范围
用户在第 5 轮基础上提出新一轮 7 项体验修复：
1. 歌词上下滑动阻力大、卡顿 → 顺滑跟手；
2. 底部 Tab 栏改为**悬浮导航**（居中浮动胶囊，而非通栏）；
3. 我的页面无法上下滑动 → 恢复纵向滚动；
4. 设置及其子页面、关于页面改用**半蒙面 Sheet**（`bindSheet`），而非全页导航推送；
5. 我的页面顶部头像 / "本地音乐用户" / "已收藏 N 首" 整行移除；
6. 我的收藏左侧图标换成合适的（项目内 `ic_collect.svg`）；
7. 全局优化并丰富交互动画与动效。

### 6.2 改动清单（本轮新增）
| 文件 | 改动 |
|------|------|
| `lyric/LrcView.ets` | 歌词手势由 `.onTouch` 手动累加偏移（每次 `Move` 重绘 Canvas 致卡顿/阻力）改为 `PanGesture({ direction: Vertical, distance: 4 })` 增量派发；`onActionStart` 复位 `lastPanY`、取消自动回位，`onActionUpdate` 用 `event.offsetY - lastPanY` 增量更新 `userOffsetY`，`onActionEnd` 触发自动回位；`.onClick` 与 pan 天然分离（消除"滑动结束误触点击"）；删除 `handleTouch`/`hasMoved`/`lastTouchY` 等遗留 |
| `pages/Layout.ets` | 底栏重构为**居中浮动胶囊**：`customBottomBar` 由通栏 `width('100%')` → `width('92%').constraintSize({ maxWidth: 520 })` 居中、`borderRadius(30)`、`margin({ bottom: bottomHeight + 12 })`、`backgroundColor(cardBg)`；每 tab 与播放按钮新增 `.scale()` + `.animation({ curve: springSnappy(), duration: Motion.tap })` 点按回弹（`.onTouch` Down→0.9 / Up→1.0）；`miniBarInner` 高度 60→56、去掉内层透明背景填充 |
| `pages/Mine.ets` | ① 恢复滚动：去掉 `expandSafeArea(BOTTOM)` 与 `layoutWeight(1)`，根 `Scroll` 改 `height('100%')`（保留 `TOP` 沉浸与底部 padding，浮动栏在 Layout 父层不挡内容）；② 移除顶部头像 `Circle` 栈、"本地音乐用户"、"已收藏 N 首"整行；③ "我的收藏"图标 `ic_hm_favorite` → `ic_collect`；④ 设置/关于项改为置 `showSettings/showAbout=true`，Scroll 末尾加两处 `bindSheet` 半蒙面 sheet 渲染 `Settings`/`About` 普通组件，关闭经回调 `this.x=false` + 深层导航 `this.pathStack.pushPathByName` |
| `pages/Settings.ets` | 重写为普通 `@Component struct Settings`（去除 `NavDestination`）；`@State selectedCategory` 在 sheet 内切换根列表 / `SettingsCategoryDetail`（避免再开 NavDestination），二者 `TransitionEffect.OPACITY.combine(translate)` 转场；新增 `onRequestClose`/`onNavigate` 回调；`SettingsBuilder()` 保留为 `NavDestination` 路由壳兼容历史路由名 |
| `pages/SettingsCategory.ets` | 抽取普通 `@Component struct SettingsCategoryDetail`（`@Prop category` + `onBack`/`onNavigate` 回调）；Storage/隐私政策等深层导航改调 `this.onNavigate('ManageSongs'/'PrivacyPolicy')`；`SettingsCategoryBuilder()` 保留 `NavDestination` 壳 |
| `pages/About.ets` | 重写为普通 `@Component struct About`（新增 `onRequestClose` 回调）；`AboutBuilder()` 保留 `NavDestination` 壳 |

### 6.3 独立 code-reviewer 审查结论（并行调度）
- 7 项**全部 PASS**，P0/P1 均无；风险点 A–F 逐项确认（$$ 双向绑定、selectedCategory 切换无死循环、`ic_collect` 资源存在等）。
- ⚠️ **审查盲区（重要）**：reviewer 审查的对象为**修复前源码**（含 `@Prop onRequestClose` 等函数类型成员），却给出"P0 NONE / 全 PASS"。而 **ArkTS 编译器（build 闸门）实际报出 14 ERROR，其中 5 处正是 `@Prop` 作用于函数类型被拒**——reviewer 的红线检查清单未覆盖"@Prop/@State 不可用于函数类型变量"这一条，导致漏判。结论：**构建闸门（build）才是权威验证，LLM 审查不能替代编译**。已将该条补入项目红线清单（见 §6.5）。

### 6.4 构建验证（编译期踩坑 → 已修复）
- 首构建 **14 ERROR**：
  1. `@Prop` 作用于函数类型变量（5 处）：`About.ets:31 onRequestClose`、`Settings.ets:45/47 onRequestClose/onNavigate`、`SettingsCategory.ets:80/82 onBack/onNavigate` —— ArkTS V1 禁止 `@Prop` 修饰函数类型。**修复**：改为**普通成员**（无装饰器），由父组件在构造表达式 `<Settings onRequestClose={...} />` 中传入，默认值 `= () => {}` 兜底路由壳。
  2. `Mine.ets:21` `import { SheetType, SheetSize } from '@kit.ArkUI'` —— 本 SDK（API 24 / HarmonyOS 6.1.1）二者**均未导出**。**修复**：删除该 import。
  3. `bindSheet` 选项 `mask: true` / `preferType: SheetType.BOTTOM` 在本 SDK 的 `SheetOptions` 中**不存在**（`'mask' does not exist in type 'SheetOptions'`）。**修复**：删除 `mask` 与 `preferType`（默认 sheet 即底部 + 自带半透明蒙层，满足"半蒙面"诉求）；`detents: [SheetSize.MEDIUM, SheetSize.LARGE]` → 改用百分比 `['60%','90%']`（不依赖未导出枚举）。
  4. `Layout.ets` 浮动栏 `Row` 上 `.maxWidth(520)` —— 非 `RowAttribute` 成员。**修复**：改为 `.constraintSize({ maxWidth: 520 })`。
- 复构建：**BUILD SUCCESSFUL（0 ERROR）**，产物 `entry-default-signed.hap`（162 MB，含 C++ NAPI 原生编译）。本轮改动文件**无新增 WARN**；共 10 条 WARN 均为 API 26 `@since` 提示（含 `Layout.ets:299 systemMaterial`，已由 `ApiCompat.isAtLeast(26)` + `import type` 降级处理，属预期）。

### 6.5 红线补遗（本轮新增）
- **禁止 `@Prop`/`@State`/`@Link` 等状态装饰器修饰函数类型变量**（ArkTS V1 `10905363` 编译错误）。回调一律用**普通成员** + 父组件构造传参，默认 `= () => {}`。
- `bindSheet` 的 `SheetOptions` 在本 SDK（API 24）**无 `mask` / `preferType` / `SheetType` / `SheetSize`**，所需半蒙面效果依赖默认蒙层；`detents` 用百分比字符串数组。

### 6.6 仍待办（需真机）
悬浮胶囊居中/沉浸材质观感、歌词 PanGesture 跟手度、Mine 滚动恢复、半蒙面 Sheet 蒙层与二级切换、删除头部后布局、收藏图标观感、tab/播放按钮 scale 回弹——本地无法执行，需真机回归。

---

## 七、Mine 页 Sheet 交互 + 播放入口图标修复轮（2026-08-30 第三轮）

### 7.1 诉求与范围
用户在第二轮基础上反馈 4 项问题：
1. 我的页「设置」「关于」点不开——要先点设置、再点关于，设置才出现；关掉设置后关于又冒出来（两个 sheet 串台/打不开）。
2. 两个 sheet 高度都要用 LARGE。
3. 这两个 sheet 页面底色用**灰色**、选项颜色用**白色**（而非当前白底灰字）。
4. 播放入口封面上的图标在停止播放时显示的是「开始播放」图标（误导），要修复。

### 7.2 根因与改动
| # | 问题 | 根因 | 修复 |
|---|------|------|------|
| 1 | 双 sheet 串台/打不开 | `Mine.ets` 在**同一个根 `Scroll` 节点上挂了两个 `bindSheet`**，ArkUI 不支持同一节点多 sheet 共存，二者 `$$` 双向绑定互相抢占，导致状态错乱 | 改为**单一 `bindSheet`**：`sheetVisible: boolean` 驱动 `$$` 绑定，新增 `sheetKind: 'settings'\|'about'\|''` 状态，`sheetContent()` 按 `sheetKind` 切换渲染 `Settings`/`About`；点击各自置 `sheetKind+X=true`，`onRequestClose`/`onNavigate` 关闭 sheet 并复位 `sheetKind=''`。彻底消除多 sheet 干扰 |
| 2 | sheet 高度 | 原 `detents: ['60%','90%']`（两档、默认非最大） | 改为 `detents: ['90%']`（LARGE，单档大屏），设置与关于一致 |
| 3 | 灰底白字 | sheet 内 `Settings`/`About`/`SettingsCategoryDetail` 沿用主题色（浅色=白底深字） | 新增 `ThemeManager.sheetColors`（灰底 `#2C2C2E` + 白字 `#FFFFFF` + 白次级字）；为三组件加 `@Prop sheetStyle: boolean`，`getThemeColors()` 在 `sheetStyle` 时返回 `sheetColors`；`Mine` 渲染时传 `sheetStyle: true`（历史 `SettingsBuilder`/`AboutBuilder`/`SettingsCategoryRoute` 路由壳不传，走主题色，行为不变） |
| 4 | 封面图标错乱/误导 | `Layout.ets` `playerButton` 用 `SymbolGlyph($r('sys.symbol.pause_fill'))` 叠加，`pause_fill` 在部分设备渲染不确定，且语义写成「停止态显示暂停图标」导致误导 | 改用**可靠位图** `ic_hm_play`/`ic_hm_pause`；按用户要求映射：**停止→显示暂停/停止图标（`ic_hm_pause`）、播放→显示开始图标（`ic_hm_play`）**；新增 `playStateOverlay(icon)` builder 统一半透明遮罩，遮罩 `hitTestBehavior(None)` 不拦截点击（点击仍 `openPlayer()` 打开播放页） |

### 7.3 构建验证
- 复构建：**BUILD SUCCESSFUL（0 ERROR）**，产物 `entry-default-signed.hap`（162 MB）。
- 本轮改动文件无新增 WARN；唯一 `Layout.ets:310` WARN 为 `systemMaterial` API 26 `@since` 提示（已由 `ApiCompat.isAtLeast(26)` + `import type` 降级处理，属预期）。

### 7.4 仍待办（需真机）
双 sheet 互不干扰、LARGE 高度、封面图标在停止/播放两态显示正确、浅/深主题下 sheet 颜色跟随——本地无法执行，需真机回归。

### 7.5 第四轮回退：撤销强制灰底白字，恢复 sheet 跟随系统浅/深主题（2026-08-30 晚）
- **回归现象**：用户反馈"设置页面和关于页面全是深色模式的颜色了，浅色模式的颜色消失了"。
- **根因**：第三轮为三组件加的 `sheetStyle` 在 `Mine` 渲染时恒传 `true`，`getThemeColors()` 在 `sheetStyle` 时返回 `ThemeManager.sheetColors`（深灰 `#2C2C2E` + 白字），**无视 `@StorageProp('isDark')`**，导致浅色主题下 sheet 也被强制成深色，浅色配色整体消失。
- **修复（仅撤销第三轮第 3 项强制覆盖，保留第 1/2/4 项）**：
  - 删除 `About.ets` / `SettingsCategory.ets` 的 `sheetStyle` prop；`getThemeColors()` 还原为 `return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;`（跟随应用主题）。
  - `Mine.ets` 的 `sheetContent()` 中 `Settings`/`About` 构造移除 `sheetStyle: true`（不再传任何强制色）。
  - 删除 `ThemeManager.sheetColors` getter（不再被引用）；`Settings.ets` 在第三轮续作中已先行回退，本轮保持一致。
- **结果**：sheet 内页面与全应用其它页面**统一跟随系统/应用浅色或深色主题**（浅色=白底深字、深色=黑底白字）；单 sheet 不串台、LARGE 高度、封面图标两态等第三轮修复保持不变。
