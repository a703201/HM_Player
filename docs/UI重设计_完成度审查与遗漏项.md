# Lumio Music · UI 重设计完成度审查与遗漏项清单

> 审查日期：2026-09-12 ｜ 审查人：审查严（code-reviewer）｜ 汇编：齐活林（team-lead）
> 基线：`main` @ `fcab940`（本轮：长按菜单修复 + 字号/间距令牌化）

---

## 0. 总体结论

| 维度 | 状态 |
|---|---|
| 令牌层（颜色/间距/圆角/特效/动效） | ✅ 已建立并落地 |
| 颜色硬编码清零 | ✅ 业务层零 `#hex`/`rgba` |
| 表面层级（灰底白卡） | ✅ 中心映射级联 |
| 歌曲行组件化（6 处去重） | ✅ |
| 长按菜单（尺寸/溢出） | ✅ 本轮已修 |
| 字号/间距令牌化 | 🟡 **约 85%**：等值项已全量映射；栅格外/阶梯外值待收尾 |
| 播放页媒体层接入令牌 | 🔴 **未做**（实质缺口） |

**判断：UI 重写尚未"完全实现"，完成度约 85%。** 剩余两项实质缺口见 §1；其余为零星收尾（§2）。

---

## 1. 实质缺口（P0/P1）

### P1① 播放页媒体层未接入令牌 🔴
播放页叠在封面之上的媒体层仍用硬编码与旧资源，未走 `onMediaOf(backgroundIsDark)`：

| 文件 | 行 | 现状 | 应改为 |
|---|---|---|---|
| `components/LyricsComponent.ets` | 175、224 | `Color.White` 硬编码 | `onMediaOf(backgroundIsDark).*` |
| `components/TopAreaComponent.ets` | 44、49 | `Color.White` / `Color.Black` 硬编码 | `onMediaOf(...)` |
| `components/PlayerInfoComponent.ets` | 多处 | `$r('app.float.*')` 间距/字号 | `SPACE_SM`/`TYPE_SM` |
| `components/MusicInfoComponent.ets` | 多处 | `$r('app.float.*')` | `SPACE_SM`/`TYPE_SM` |

> 影响：这三处是播放页唯一未纳入令牌体系的层，且属对比度最敏感区（叠封面），需连同真机取样一起做（R-24 口径）。

### P1② 间距/字号收尾
- `components/SettingsSubPageBodies.ets`：L71/160/291/294/316/323/335/370 等仍有裸间距 `10/14/3/6/18`；L496 `fontSize(56)`、L697 `fontSize(17)`。
- `pages/SettingsCategory.ets`：L263 等仍有裸间距。
- 全站 ~40 处"安全区"模式 `top: this.topHeight + 12` / `bottom: this.bottomHeight + 16`（本轮未动，`+ N` 未被规则匹配）。

---

## 2. 零星收尾（P2）

### ④ 阶梯外字号（13 处，共 9 个值）
`10, 17, 22, 24, 30, 34, 56` —— 不在 `TYPE_SM` 12 档内，未映射：

| 值 | 出处 |
|---|---|
| 56 | `SettingsSubPageBodies.ets:496` |
| 34 | `Splash.ets:61` |
| 30 | `About.ets:166` |
| 24 | `LocalLibrary.ets:399`、`Mine.ets:145` |
| 22 | `OnboardingSheet.ets:111`、`Layout.ets:217`、`Playlists.ets:507` |
| 17 | `SettingsSubPageBodies.ets:697`、`ControlAreaComponent.ets:363/393` |
| 10 | `QualityBadge.ets:32` |

> 多为展示/装饰用途（标题、空态图标、徽标），snap 到阶梯会改变视觉，需设计裁决。

### ⑤ 栅格外间距（~40 处，共 9 个值）
`1, 3, 5, 6, 10, 14, 18, 30, 36` —— 非 4vp 栅格倍数（其中 `10×24`、`14×16`、`6×15` 出现最多）。snap 会改变视觉。

### ⑥ 裸颜色（定义源，属正常）
`utils/ThemeManager.ets`（垫片定义）、`common/utils/ColorConversion.ets`（颜色数学）、`SongRow.ets` 的 `@Prop` 默认值 —— 属定义源/入参默认，不计入违规。

### ⑦ 旧 ThemeManager 依赖（19 文件）
各页仍 `import { ThemeManager, ColorTokens }` 取 7 字段色 —— 这是 P4 约定的**过渡垫片**（值由 `LumioSemantic` 派生），非缺陷；待全量迁 `semanticOf` 后删除。

### ⑧ DesignSystem 垫片（4 文件）
`ControlAreaComponent` / `CoverImageView` / `Layout` / `PlayerPage` 仍 `import from '.../DesignSystem'` —— 本轮已退化为 re-export 垫片，调用方零改动，属预期过渡态。

---

## 3. Sheet 与二级页面盘点

### 3.1 Sheet（`bindSheet`，共 9 处；颜色全令牌化 ✅）
| 宿主 | 行 | sheet 标识 | 内容构建器 |
|---|---|---|---|
| `ControlAreaComponent` | 132 | `isShowPlayList` | `musicListBuilder()` |
| `ControlAreaComponent` | 185 | `isShowSpeed` | `speedSheet()` |
| `ControlAreaComponent` | 200 | `isShowSleep` | `sleepSheet()` |
| `Mine` | 251 | `sheetVisible` | `sheetContent()`（Settings/About 复用） |
| `Favorites` | 231 | `sheetOpen` | `sheetContent()` |
| `PlayHistory` | 223 | `sheetOpen` | `sheetContent()` |
| `PlaylistDetail` | 487 | `sheetOpen` | `sheetContent()` |
| `LocalLibrary` | 614 | `sheetOpen` | `sheetContent()` |
| `Layout` | 423 | `onboardingVisible` | `onboardingContent()` |

> `components/AddToPlaylistSheet.ets`、`SongDetailSheet.ets`、`OnboardingSheet.ets` 为承接上述 sheet 的独立组件。

### 3.2 二级页面（`NavDestination`）
`About`、`PlayerPage`、`LocalLibrary`、`Favorites`、`PlayHistory`、`PlaylistDetail`、`Playlists`、`Settings` → `SettingsCategory` → `SettingsSubPageBodies`、`FolderBrowse`、`DuplicateSongs`、`ManageSongs`。

- 已完成令牌化：`About`、`Layout`、`Favorites`、`PlayHistory`、`PlaylistDetail`、`Playlists`、`LocalLibrary`、`FolderBrowse`。
- 壳体页委托 `SettingsSubPageBodies` 渲染正文，后者为 §1② 的收尾对象。
- `DuplicateSongs` / `ManageSongs`：经 `Settings` 的 `bindSheet` 复用 `SettingsSubPageBodies`，**无独立页面实现**，不属遗漏。

**无"未覆盖的 sheet / 二级页面"**——盘点的每个 sheet 与二级页面均已接入令牌（颜色），仅 §1② 的间距/字号收尾与 §1① 的媒体层未完成。

---

## 4. 建议的收尾顺序

1. **P1① 播放页媒体层**：`LyricsComponent`/`TopAreaComponent`/`PlayerInfoComponent`/`MusicInfoComponent` 接入 `onMediaOf` + `SPACE_SM`/`TYPE_SM`；**必须真机取样验收对比度（R-24）**。
2. **P1② SettingsSubPageBodies/SettingsCategory 间距字号收尾**：snap 到 4vp 栅格 + 阶梯，逐页截图比对。
3. **P2④⑤ 全站阶梯外/栅格外值**：一次性设计裁决（snap 映射表）后批量执行，逐页截图验证。
4. 过渡垫片（⑦⑧）待业务迁移完成后删除。

> ⚠️ 以上 1–3 均属"值变化"（非等值映射），改前需真机截图基线，改后需逐页比对，不可盲改。


---

## 5. 收尾更新（2026-09-12，提交 dbfc957）

下列缺口已闭环（构建 BUILD SUCCESSFUL）：

| 原缺口 | 状态 |
|---|---|
| P1① 播放页媒体层未接入令牌 | ✅ 已修：`ControlAreaComponent`/`LyricsComponent`/`TopAreaComponent`/`MusicInfoComponent` 叠封面元素统一走 `onMediaOf(封面明暗)`；accent 按钮白字走 `semanticOf.onAccent` |
| P1② SettingsSubPageBodies/SettingsCategory 栅格外值 | ✅ 已 snap |
| P2④ 阶梯外字号 10/17/22 | ✅ 已 snap 到 caption2/title3/title1 |
| P2⑤ 栅格外间距（1/3/5/6/10/14/18/30/36） | ✅ 已 snap 到 hair/tight/compact/cozy/base/roomy/section |
| 死代码 `LrcView.drawMiddle()`（含 `Color.Red` 调试中线，从未调用） | ✅ 已删 |

**仍未处理（需设计裁决，非执行缺口）**：
- 展示级字号 `24`（页大标题）/`30`（About 应用名）/`34`（Splash 品牌字）/`56`（超大统计）——超出文本阶梯上限 28，强 snap 会让展示层级塌陷，建议由设计扩充 `display` 档位后再统一。
- `$r('app.float.*')` 资源间距体系（媒体组件仍用华为样例的 breakpoint 资源），与令牌并存；彻底迁移需按其数值逐项替换并真机验证。

**本轮 snap 属"值变化"**（非等值映射），已在提交 `dbfc957` 中逐项记录；**建议真机截图逐页比对**后再视为最终态。
