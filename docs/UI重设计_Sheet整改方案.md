# Lumio Music · bindSheet 合规整改实现方案

> 依据：`docs/UI重设计_Sheet合规审查.md`（已审计）+ `docs/设计系统_Apple.md` §2.5.5 / §1.5.15 / §3.2.3 / §1.4-B + 全量源码核实
> 状态：仅规划，未改动任何文件；待 team-lead（用户）确认选型后转交 code-developer 实施

---

## 一、三个关键决策（含推荐项）

### 决策 1 · 材质共享方式（消除 P0 材质缺失）
**【推荐】A：抽共享 util `common/utils/SheetMaterial.ets`**
- 导出 `acquireSheetMaterial(): Promise<uiMaterial.Material | undefined>`（`ApiCompat.isAtLeast(API_26)` 时动态 `import('@ohos.arkui.uiMaterial')` → `new ImmersiveMaterial({style:REGULAR})`；API24 或 catch 一律 `resolve(undefined)`）。
- 导出全局 `@Builder function SheetScaffold(material, fallbackColor, content: () => void)`，内部 `if (isAtLeast(API_26) && material !== undefined)` → 根 `Column().systemMaterial(material)`，否则 `Column().backgroundColor(fallbackColor)`；统一内距 `左右 roomy / 底 loose`。**绝不同时对同一 Column 设 systemMaterial + backgroundColor**（§2.5.5 禁止重复背景色）。
- 各 sheet 仍自持 `@State material`，`aboutToAppear` 里 `acquireSheetMaterial().then(m => this.material = m)`，根内容包一层 `SheetScaffold(this.material, surfaceOverlay, () => {...})`。

**理由**：与现存唯一合规写法（SongDetailSheet.ets:86-140）语义完全一致，把"动态 import + catch 兜底 + API26/24 二选一"收敛到一处，杜绝 8+ 复制缺失的根因（DRY）。
**备选 B**（`@Extend(Column) sheetSurface()`）：@Extend 包不住内容 + 跨组件 @State，弃用。**备选 C**（逐文件复制现模式）：正是当前 bug 成因，弃用。

**影响文件**：新建 `SheetMaterial.ets`；`ThemeManager.ets` 加 `surfaceOverlay` 字段（加法零破坏，同时消解 P2 "cardBg≡surfaceOverlay 仅命名"）；`ControlAreaComponent.ets` / `AddToPlaylistSheet.ets` / `OnboardingSheet.ets` / `Settings.ets` / `About.ets` / `PlaylistDetail.ets`(songPickerBuilder)。

### 决策 2 · Inset Grouped 容器 + hairline（消除 P1 布局）
**【推荐】A：抽共享 `common/components/GroupedSheet.ets`**
- `@Builder GroupedSheetContainer(content)`：整组 `r.md`(12) 圆角容器，`backgroundColor(cardBg)`（叠玻璃之上形成"卡中卡"），统一内距。
- `@Builder GroupedSheetHairline(color)`：`Divider().strokeWidth(0.5).color(separator)`，`startMargin = 80(sp.base) + cozy`（对齐 InfoRow label 左缘，遵循 §2.5.5）。
- 列表型（AddToPlaylistSheet 的 List）用 `List().divider({strokeWidth:0.5, color:separator, startMargin:base, endMargin:base})` 置于容器内；行型（speed/sleep 的 ForEach、SongDetailSheet 的 InfoRow）用 `GroupedSheetContainer` + 行间插 `GroupedSheetHairline`。

**理由**：手动包（B）会在 4 个 sheet 各写一遍圆角/底色/hairline，正是要消灭的复制漂移；共享模块强制单一真源（§1.4-B）。
**备选 B**：各 sheet 手动 `Column(.borderRadius(r.md)) + 行间 Divider`——可落地但不推荐。

**影响文件**：新建 `GroupedSheet.ets`；`SongDetailSheet.ets`、`AddToPlaylistSheet.ets`、`ControlAreaComponent.ets`(speed/sleep)。

### 决策 3 · OnboardingSheet 彩色归零
**【推荐】落地 §1.5.15 建议**：feature 图标底 `semanticOf(this.isDark).fillAccentSubtle` + 图标 `semanticOf(this.isDark).accent`（单一强调色，彩色归零）。
- `features()` 现为**方法**（L49-55），切主题会重算，无"非响应式"问题；仅把 4 处 `color` 改为 `fillAccentSubtle`，并删除 `OnboardFeature` 接口的 `color` 字段（L26）+ 4 处返回的 `color`。
- `featureItem`（L78 图标 `onAccent`→`accent`；L83 底 `f.color`→`fillAccentSubtle`）。

**理由**：§1.5.15 明文建议方案；引导页彩色归零、靠留白与图标形状区分，与全站"单一 accent"语言统一。
**需确认（设计决策）**：§1.5.15 标注"最终仍需 team-lead 确认"。若保留四色区分概念（AD-0 第 6 条允许引导页用色），则维持现状——但四色里 `LUMIO_PALETTE.purple` 深色偏暗、`warning/success` 深浅值不同，仍建议归零。

**影响文件**：`OnboardingSheet.ets`（L26 接口、L49-55、L78、L83）。

---

## 二、分阶段文件级改动清单（P0 → P1 → P2）

### P0 · 材质系统性缺失（决策 1A）+ 彩色归零（决策 3）
| 文件 | 行号 | 改什么 | 不变量 |
|---|---|---|---|
| `common/utils/SheetMaterial.ets`(新) | — | `acquireSheetMaterial` + `SheetScaffold` | 无 |
| `utils/ThemeManager.ets` | 35-66 | `ColorTokens` 加 `surfaceOverlay`（=LIGHT/DARK_SEMANTIC.surfaceOverlay，加法） | 无 |
| `components/ControlAreaComponent.ets` | 460 / 365-391 / 395-452 | 三处根 Column 包 SheetScaffold；加 import uiMaterial、@State material、aboutToAppear 调 acquire | 不动 :142 onWillAppear 刷新 |
| 同上 | 140 | bindSheet `backgroundColor:cardBg`→`surfaceOverlay` | 不动 :138-139 dragBar/showClose=false |
| `components/AddToPlaylistSheet.ets` | 154-227 | 根 Column 包 SheetScaffold；aboutToAppear(L51) 加 acquire | 不动 onClose/nameDialogController |
| `components/OnboardingSheet.ets` | 110-153 | 根 Column 包 SheetScaffold，fallback=surfaceOverlay | 不动 aboutToAppear 入场动画/:144 onClose |
| 同上 | 26/49-55/78/83 | 决策 3 彩色归零 + 删 color 字段 | 无 |
| `pages/Layout.ets` | 424 | bindSheet 补 `backgroundColor: surfaceOverlay`（保 API24 窗口） | 不动 :428 onDisappear→closeOnboarding |
| `pages/Settings.ets` | 213-216 | 根容器包 SheetScaffold；内层 `.backgroundColor(bg)` 去 bg 让玻璃透出，分组卡 secondaryBg 保留 | 不动 onRequestClose/selectedCategory/goBackInSheet |
| `pages/About.ets` | 137-140 / 325 | 根 Column 包 SheetScaffold；内层 Scroll bg→去 bg（secondaryBg 卡保留） | 不动 subPage 动画/onStartOnboarding/goBackFromSubPage |
| `pages/PlaylistDetail.ets` | 322-323 | songPickerBuilder 根包 SheetScaffold + import/@State/aboutToAppear | 不动 :521 sheetContent 分发/:517 onClose |

### P1 · Inset Grouped 容器 + hairline（决策 2A）+ 半径/间距
| 文件 | 行号 | 改什么 | 不变量 |
|---|---|---|---|
| `common/components/GroupedSheet.ets`(新) | — | `GroupedSheetContainer` / `GroupedSheetHairline` | 无 |
| `components/SongDetailSheet.ets` | 118 | infoRow padding `cozy`(12)→`compact`(8) | 无 |
| 同上 | 143-168 | 7 行 InfoRow 包 `GroupedSheetContainer` + 行间插 `GroupedSheetHairline`(startMargin=80+cozy) | 不动 :122 根 systemMaterial |
| `components/AddToPlaylistSheet.ets` | 169-202 | 歌单 List 包 `GroupedSheetContainer` + `.divider(0.5, separator, base, base)` | 无 |
| 同上 | 150 | nameDialog 容器 `borderRadius(16)`→`r.xl`(24) | 不动 nameDialogController |
| `components/ControlAreaComponent.ets` | 364-391 | speedSheet ForEach 行包 GroupedSheetContainer + 行间 hairline | 不动 :384 setSpeed |
| 同上 | 394-452 | sleepSheet 同上 | 不动定时器逻辑 |

### P2 · 收尾/合规细节（低风险批量）
| 文件 | 行号 | 改什么 | 不变量 |
|---|---|---|---|
| `components/AddToPlaylistSheet.ets` | 128 | 次按钮「取消」`borderRadius(24)`→`r.md`(12) | 无 |
| 同上 | 139 | 主按钮「确定」`borderRadius(24)`→`r.pill`(999) | 无 |
| 同上 | 192 | 列表行 `.height(56)`→`.minHeight(56)` | 无 |
| `components/SongDetailSheet.ets` | 138 | API24 降级 `cardBg`→`surfaceOverlay`（SheetScaffold fallback 解决） | 无 |
| `pages/Favorites.ets` | 236 | bindSheet `backgroundColor:bg`→`surfaceOverlay` | 不动 :249 sheetContent |
| `pages/LocalLibrary.ets` | 619 | 同上 | 不动 :615 其余 |
| `pages/PlayHistory.ets` | 228 | 同上 | 不动 :224 其余 |
| `pages/PlaylistDetail.ets` | 492 | 同上 | 不动 :488 其余 |
| `pages/Mine.ets` | 256 | 同上 | **保留 :257 onDisappear 复位 sheetKind + pendingOnboarding** |
| 四列表页 + Mine | — | 各 bindSheet 补 `onDisappear(()=>{ this.sheetKind='' })` 对齐 §3.2.3（仅 Mine 现有；四列表页缺），需回归关闭动画不闪烁 | §3.2.3 |
| `components/ControlAreaComponent.ets` | 138-139 | musicList `dragBar:false, showClose:false`：**保持原样**（CENTER 居中队列刻意设计），仅标注 | 无 |

> 注：父级 bindSheet `backgroundColor` 由 `bg`(灰) 改 `surfaceOverlay`(白) 属视觉微调——API26 下被玻璃覆盖不可见；API24 下窗口档由灰变白，与"Sheet 是 overlay 表面"语义一致。若保留灰档 gutter 的 iOS 观感，可保留 `bg`；二选一，建议 `surfaceOverlay`。

---

## 三、风险与回归点
1. **systemMaterial 仅 API26 动态 import，必须 catch 兜底**：`acquireSheetMaterial` 在 API24 / import 失败均 `resolve(undefined)`；`SheetScaffold` 守卫保证未成功时绝不调用 `.systemMaterial`，API24 恒走 `surfaceOverlay`，不崩溃。
2. **API24 仍 surfaceOverlay**：新增令牌值与 cardBg 相同（#FFFFFF/#1C1C1E），零视觉回归；同时消解 P2 命名歧义。
3. **不得破坏 Mine/Settings/About 不变量**：仅改根容器背景，subPage/onDisappear/pendingOnboarding/goBackInSheet 全部不动；About 去内层 Scroll bg 时确认次级卡 secondaryBg 保留、滚动可读。
4. **不得对同一 Column 同时 systemMaterial + backgroundColor**（§2.5.5 硬规）；SheetScaffold 两分支互斥保证。
5. **Layout.ets 新增 backgroundColor 选项**不影响 :428 onDisappear→closeOnboarding。
6. **@Builder 传参**：全球 @Builder 收 `content: () => void`，调用用箭头式安全。
7. **reduceMotion**：系统接管，本次零改动（审计确认已合规）。
8. **ThemeManager 加法字段**零破坏；其余均为局部替换。

---

## 四、建议执行顺序与每阶段独立验证判据
- **Phase 0（基建）**：新建 `SheetMaterial.ets` + `GroupedSheet.ets`，`ThemeManager` 加 `surfaceOverlay`。**判据**：`hvigor assembleHap` 编译通过。
- **Phase 1（P0 材质）**：ControlArea×3 / AddToPlaylist / Onboarding / Settings / About / PlaylistDetail(picker) 接 SheetScaffold + Layout 补 backgroundColor。**判据**：API26 各 sheet 呈系统毛玻璃；API24 降级纯色 surfaceOverlay 且不崩（catch 生效）；Mine 关闭→onDisappear 复位 sheetKind+pendingOnboarding 正常；ControlArea 队列 onWillAppear 刷新正常。
- **Phase 2（P0 彩色）**：OnboardingSheet 彩色归零。**判据**：4 feature 图标底统一 fillAccentSubtle + 图标 accent；浅/深切换正确。
- **Phase 3（P1 布局）**：SongDetailSheet 信息区 / AddToPlaylist 歌单列表 / speed/sleep 包 GroupedSheetContainer+hairline；SongDetailSheet 行 padding→8；AddToPlaylist nameDialog→r.xl。**判据**：整组 r.md 容器 + 0.5vp hairline；Dialog 容器 r.xl(24)。
- **Phase 4（P2 收尾）**：按钮圆角/行高/父 bindSheet bg/onDisappear/detents 文档。**判据**：编译通过 + 浅深双截图；onDisappear 复位不引发关闭闪烁。
> 每阶段独立可编译、可真机验证，便于分批合入与回滚。

---

## 五、detents 文档顺序冲突处理建议
- **运行时不改**：代码层无 P0/P1，detents 已冻结；Mine `[LARGE,MEDIUM]`、四列表页 `[MEDIUM,LARGE]` 各符合一处文档，不改任何 .ets 行为避免 Mine 起始档意外回退。
- **文档侧修正**：以更具体的 §1.5.15 为权威，将 §2.5.5 冻结行改为 `[SheetSize.MEDIUM, SheetSize.LARGE]`，并加注"Mine/Settings 因内容长可保留 `[LARGE, MEDIUM]` 起始档"。属文档 P2，不碰代码。
- **待 team-lead 拍板**：是否把 Mine 也统一到 `[MEDIUM, LARGE]`（会改 Mine 首屏展开档，建议不做）。

---

## 六、需用户确认的两点
1. 决策 3 OnboardingSheet 是否确认"彩色归零"（fillAccentSubtle+accent）；还是保留四色引导语义。
2. 父级 bindSheet `backgroundColor` 改 `surfaceOverlay`（白档）还是保留 `bg`（灰档 gutter）；以及 Mine detents 是否维持 `[LARGE,MEDIUM]` 不动。
