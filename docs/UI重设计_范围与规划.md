# Lumio Music · 整体 UI 重设计（Apple 风格）范围与规划

> **文档版本**：**v1.8**（Phase 0 立项版 · 已并入 system-architect v1.2/v1.3/v1.6/v1.7 复核结论 **+ R-04b 意图感知双档裁决** · **歌词参数已冻结** · **M1/M2 已细化到文件级**）
> ⚠️ **v1.3 第 ④ 条（蒙层 clamp 0.50/0.65、背景压到 105/255、对比度 1.42~1.89:1）已作废** —— 底色模型错误，见 v1.4 变更记录与 §6.6⑤「量化修正之三」。
> **变更记录**：
> - v1.0 初版（范围界定 / Apple 原则落地 / M0–M5 里程碑）
> - **v1.1**：① 列表项复制 4 处 → **5 处**（补 `FolderBrowse:153` 降级变体，新增 §4.6.1 清单）② 撤回 `secondaryLabelStrong`，改采**修令牌**方案并记录 **label 层级倒挂**修正（§6.6）③ **覆盖废止 `design_tokens.md` F-14**（结论有害，会降低空态文案可读性）④ **批次单位由「hex 类别」改为「页」**，M2 重构为 PR-0 + 逐页 PR（§7.0 / §7.4）⑤ 取消 `SongContextMenu.ets` 独立组件 ⑥ `SongListItem` 统一改名 `SongRow` ⑦ S-4 验收点由 M1 移至 M5 ⑧ R-07 降级 + 新增 R-07b / R-01b
> - **v1.2（歌词专项）**：① 并入架构师 `LrcView` 注入方案（§6.6⑤），R-04 由 🔴 降 🟡 ② 并入 R-21 维度错误修正（`onMedia*` 独立维度），新增 R-04c ③ **🔴 新发现 R-04b**：非当前行歌词是**半透明**（50.2%/30.2% alpha）且**全行 bold**，架构师蒙层反解按不透明白字计算，实测非当前行低至 **1.96:1**、clamp 上限仅 **3.09:1**，**4.5:1 目标不可达** → 已给三选项 + 反解数值，验收口径改为**分档**（当前行 4.5 / 非当前行 3 / 翻译 3），蒙层 clamp 下限建议 0.35→**0.50** ④ M3 吸收 **P2c 歌词专项**并置于开头 ⑤ 新增验收闸门 3c
> - ~~**v1.3（R-04b 裁决 · 意图感知双档）**~~ —— **第 ④ 条作废**，其余仍有效：① **裁决落地（team-lead）**：「非当前行」不是一个状态而是**两种意图** → 分**播放态**（自动滚动，非当前行 ≥3:1）与**浏览态**（`PanGesture` 拖拽中 / 手动定位后 5s 内，非当前行 **+ 翻译行均 ≥4.5:1**）。② **代码里已有这个分档**：`LrcView.ets:203` `isUserScrolling` + `:982` `scheduleAutoReturn()`（5s）+ `drawContent` 已分支 —— 裁决是**把现有两档定量化**，非新造机制。③ **🔴 第二处量化修正**：`globalAlpha` × `fillStyle` 是**双乘**，有效 alpha 仅 0.191~0.361，实测对比度 **1.42~1.89:1**，比 v1.2 记的 1.96~3.09 **更差**。④ **🔴 新冲突**：纯白封面上 4.5:1 的最小蒙层是 **0.535**，蒙层 0.50 时**不透明字也只到 3.98:1** → clamp 下限 0.50 只在「同步把 fill 提到 0.85」时才安全；已给**统一反解目标（背景压到 ≈105/255）+ 两档 alpha（播放 0.60 / 浏览 0.85）**的可行解。⑤ 翻译行（14vp 小文本）**浏览态必须 4.5:1**，S-3 分档描述已改。⑥ 验收 3c 改为 **3 张极端封面 × 各 2 态（播放 + 浏览）**。⑦ **歌词功能红线写入 §5.1**：只提可读性，**不得新增逐句跳转/编辑/翻译源切换**。⑧ M3 验收增补「每封面两态截图 + 切档禁硬切」
> - **v1.4（歌词底色模型更正 · 架构师 v1.6）**：① **🔴🔴 我与架构师此前都把歌词底色当成「原始封面亮度」，这是错的** —— `LyricsComponent` 在 `PlayerInfoComponent` 的 `Stack()` 内，底色是「封面 `opacity(0.5)`+模糊 → `buildGradientColors()` 压暗(deep .28/base .42/lifted .62) + `opacity(0.65)` → 黑蒙层 0.35（`lyricBgDark` 恒 true）」的**三段合成结果**，实际落在 **`#3B3B3B` ~ `#7D7D7D`**。② **作废**：v1.3 ④ 的「最小蒙层 0.535 / clamp [0.50, 0.65] / 背景压到 ≈105/255 / 对比度 1.42~1.89:1」。③ **重算（当前行不透明字）**：`#606060`→6.31、`#3B3B3B`→11.17、中灰→9.35、暗封面→19.74，**唯一缺口是「纯白+白底+lifted」的 4.13:1**。④ **蒙层 clamp 改 [0.0, 0.25]，默认 ≈0.10**（0.65 上限废止 —— 会把已压暗的画面压成一团黑）；反解目标改为「让**浏览态 85% 白字**达 4.5」→ 多数底色 **0.00**、最坏 `#7D7D7D` **≈0.18**。⑤ ~~**两档 alpha 微调**：播放 **0.60→0.65**~~ —— **该修正被架构师 v1.7 驳回（我算错了），播放态维持 0.60**，详见 v1.5。浏览 **0.85** 不变。⑥ **R-22 双层 alpha 依然成立**：真实底色上播放态 1.39~1.79:1、浏览态 1.59~2.37:1，**在所有背景上都低**；`LrcView.ets:652` 注释「全部清晰」仍与实现背离。⑦ **新增 R-23**：凡涉及叠加层/合成底色的对比度量化，须先读完整条渲染链并**经第二人复算**。⑧ **R-04b 双档裁决不受影响**（它是产品意图判断，与底色模型无关）
> - **v1.5（歌词参数定稿 · 架构师 v1.7 核验）**：① **我 v1.4 的「播放态 0.60 只有 2.88:1、需提到 0.65」算错并已撤回** —— 2.88 是 **scrim 0.10（bg 112.5）** 下的值，我误标成 scrim 0.18（bg 102.5）；正确值 **0.60 → 3.20:1 ✅ 已达标**，**维持 0.60 不上调**（播放态设计目标是弱化以形成聚焦层次，alpha 越低层次越强）。② **scrim 反解**：最坏 `#7D7D7D` 反解 **0.159**，工程取 **0.18**（架构师采纳我「按 85% 白字反解而非不透明字」的修正，其 v1.6 的 0.049 作废）。③ **参数定稿**：当前行 1.00 / 播放态 **0.60**（保留 blur）/ 浏览态 **0.85**（去 blur）；深色方案 fill 建议 浏览 `#D9ffffff`、播放 `#99ffffff`。④ **🔴 新增验收硬要求**：对比度**必须在渐变 `lifted` 位（0.45 处，最亮位）取样** —— 同一底色 deep 8.63:1 / base 4.63:1 / **lifted 3.47:1 ❌**，在深位取样会误判为全部达标。⑤ **批次约束**：**自适应蒙层与 α=0.60 必须同批落地**，无蒙层时 0.60 仅 **2.54:1** ❌。⑥ 已写入 §6.6⑤、R-04b、M3 验收、闸门 3c
> - **v1.6（参数分阶段 · team-lead 裁决）**：① **⚠️ 参数拆为两阶段** —— 上表此前只描述 **M3 终态**，而**本轮修线上缺陷不含自适应蒙层**，参数不同。**本轮（无蒙层）播放态 α=0.65**（实测最坏 **2.71:1**）、**M3 起（含自适应蒙层）α=0.60**（实测 **3.20:1**）。拿 M3 参数修 bug 会做出不达标的中间态。② **🔴 本轮存在硬缺口待裁**：无蒙层时最坏底色 `#7D7D7D` 上，播放态达 3:1 需 α≈**0.73**；浏览态 4.5:1 **任何 α 都不可达**（不透明字也只 4.13:1）。已给二选一：**加固定常量蒙层 0.16**（→ 3.36/4.50 均达标）或**登记为已知缺口留 M3 补**。③ **blur 强度必须下调**：已播 `blur(3px)`→**1.5px**、未播 `blur(5px)`→**2px**；判据是现网 5px ≈ 18vp 字号的 **28%**，属**抹除**而非柔化，是现网低对比度的**第二大成因**，**只修 alpha 修不干净**（架构师「blur 是设计意图不该动」的异议已被比例判据驳回）。**「是否模糊」不变，「模糊强度」必须降。** ④ **新增 M3 验收⑦ + 闸门 3d：真机主观可读性确认** —— 数值验收是**必要非充分条件**（WCAG 不建模模糊）；**非作者本人**在**正常室内光**下朗读**随机指定的一句非当前行歌词**，**能正确读出即通过**，由**蓝绘心**判定。⑤ 修正 M3 验收编号重复（原有两个 ⑥）
> - **v1.7（本轮缺口裁定 · 参数冻结）**：① **A/B 裁定 = B + 播放态 α 提到 0.73**。否决 A（固定常量蒙层 0.16）的判据：**固定蒙层不区分封面亮度，为 1% 极端封面惩罚 99% 普通封面** —— 这是「调参数」不是「修结构」，M3 自适应蒙层才是正解（我们已在 clamp [0.50,0.65] 上栽过一次）。② **播放态 0.73**（3:1 可达，相对 0.65 只差 0.08，视觉代价可忽略）；**浏览态维持 0.85、4.5:1 缺口登记** —— 判据：**「如果一个改动达不到目标，就别为它付代价」**（α=1.0 也只 4.13:1，故不为它牺牲不透明度差）。③ **🔴 8-bit 取整陷阱**：0.73×255=186.15，四舍五入取 `0xBA`(186) → α=0.7294 → **2.998:1 ❌**；**必须取 `0xBB`(187) → 3.01:1 ✅**。实现直接写 `#BBffffff`，不要写 0.73 再转（余量 <0.5%）。④ **封面集统一为 4 张**（纯白 / 中灰 / 纯黑 / 高饱和），④ 与 ⑦ 两处同组，保证两轮取样可比。⑤ **歌词参数就此冻结**
> - **v1.8（M1/M2 文件级细化 · 供开发调度）**：① 新增 **§7.3.1 M1 落地细则**：实测校正「22 个业务文件」→ **16 文件 / 337 处调用点**；实测校正「只需改 `LumioColor` 一行」→ **`LumioColor` 与 `#6E6E73` 全仓 grep 零命中，二者都不存在**，M1 = 新建 `tokens/` + 改造 `ThemeManager`。② **M1 可收敛到一个点**：只把 `LIGHT_TOKENS`/`DARK_TOKENS` 两个模块级常量改为从 `appleColors()` 派生 → 三条取色路径（`getColors()`/`lightColors`/`darkColors`）自动跟随，**337 处调用点零改动**。③ **🔴 坑一（待蓝绘心裁定）**：表面层级配对 —— Apple 原生是「页面底灰→卡片白」，现网是「页面底白→卡片灰」，按原生映射会导致**浅色下卡片与页面底同为纯白、卡片消失**。已给甲/乙两案，**推荐乙**（保持现网骨架，符合 R-07「不可有明显突变」）。④ **🔴 坑二**：Apple 原生 `secondaryLabel`(`rgba(60,60,67,0.60)`) 合成后仅 **3.44:1**，**不达 AA** → M1 派生时 `secondaryText` 必须落到 **`#6E6E73`（5.07:1）**，不可直接取 `AppleTokens.secondaryLabel`。⑤ 新增 **§7.4.1 M2 PR 切分**：**PR-0 前置 5 处列表项截图存档**（采纳蓝绘心建议）+ PR-1~4 逐页文件级裸 hex 清单（`LocalLibrary` 4 处全为 `#FA2759`、`Mine` 9 处/5 色、`Layout` 3 项、`Splash` 2 处）+ 表面配对规则 ⑥ 联带：`WidgetCard.ets:42` 是 `ThemeManager` 取色的单点镜像，M1 改常量后须同批更新或明确留 M5
> **作者**：计谋远（鸿蒙软件项目经理）
> **日期**：2026-09
> **项目**：Lumio Music v2.4.0（versionCode 2040000） / bundleName `com.Lumio.music`
> **技术底座**：HarmonyOS NEXT，ArkTS / ArkUI，`compatibleSdkVersion 6.1.1(24)` + `targetSdkVersion 26.0.0`，单模块 `entry`，C++ NAPI 音频元数据解析
> **产品定位**：纯本地离线音乐播放器（无联网、无账号）
> **本次性质**：**视觉与交互层重设计（Re-skin + Re-motion），非功能重写**
> **下游读者**：蓝绘心（UI/UX 设计师）、高见远（系统架构师）、开发实施同学

---

## 0. 文档定位与阅读指引

本文件是 Apple 风格整体 UI 重设计的 **Phase 0 范围契约**。它回答四个问题：

| 问题 | 章节 |
|---|---|
| 做到什么算成功？ | §2 目标与成功标准 |
| 改哪些、改到什么程度？ | §4 重设计范围清单 |
| 哪些绝对不许动？ | §5 保持不变的部分 |
| Apple 原则怎么落到 ArkUI？ | §6 设计原则落地清单 |
| 分几批做、怎么验收？ | §7 里程碑拆分 |

**⚠️ 本文件不含任何代码改动。** 所有 `.ets` 文件在 Phase 0 保持原样。

**⚠️ 先读 §3。** §3 记录了一个必须由 team-lead / 用户裁决的**治理冲突**，它决定了 §6 的令牌基线。若 §3 未裁决，M1 不得开工。

---

## 1. 现状基线核查（已实测，非推测）

以下数据由本人对仓库实测得出，作为范围判定依据。

### 1.1 代码规模与文件清单

| 分类 | 数量 | 位置 |
|---|---|---|
| 页面（`pages/`） | 18 个 `.ets` | 其中 14 个在 `route_map.json` 注册 |
| 组件（`components/`） | 11 个 `.ets` | 含 3 个 Sheet、1 个共享子页体文件 |
| 歌词渲染 | 1 个（Canvas） | `lyric/LrcView.ets` |
| 桌面卡片 | 1 个 | `widget/pages/WidgetCard.ets`（独立 Form 渲染进程） |
| 启动页 | 1 个 | `pages/Splash.ets`（覆盖层，非路由页） |

**路由注册表实测**（`resources/base/profile/route_map.json`，14 条）：
`Layout` / `PlayerPage` / `Settings` / `SettingsCategory` / `About` / `PrivacyPolicy` / `PlayHistory` / `Favorites` / `ManageSongs` / `Playlists` / `PlaylistDetail` / `DuplicateSongs` / `Wrapped` / `FolderBrowse`

**未注册但存在的页面**：`Index.ets`（`@Entry` 根）、`Splash.ets`（Index 内覆盖层）、`LocalLibrary.ets` / `Mine.ets`（作为 `Layout` 的 TabContent 挂载，不单独路由）。

### 1.2 关键结构发现：4 个页面是「薄壳」

实测确认 `ManageSongs.ets` / `DuplicateSongs.ets` / `PrivacyPolicy.ets` / `Wrapped.ets` 四个文件**均为 ~1.1–1.7KB 的 NavDestination 薄壳**，真实 UI 全部委托给 `components/SettingsSubPageBodies.ets` 中的四个 Body：

```
SettingsSubPageBodies.ets  →  SubPageHeader（第 36 行，共享头部）
                              ManageSongsBody（第 76 行）
                              DuplicateSongsBody（第 268 行）
                              WrappedBody（第 463 行）
                              PrivacyPolicyBody（第 728 行）
```

**范围含义**：改这 4 个页面的视觉 = 改 `SettingsSubPageBodies.ets` 一个文件（约 900 行），4 个薄壳只需令牌替换或完全不动。这是本次重设计**最高杠杆的单点**——一处改动覆盖 4 个页面 + 共享头部。

### 1.3 核心工程问题：三套并行的颜色真源

这是本次重设计必须先解决的**结构性障碍**。实测结果：

| 令牌源 | 位置 | 字段数 | 实际被引用情况 |
|---|---|---|---|
| **A. `AppleTokens`**（Apple 语义色，完整 iOS 分层） | `common/utils/DesignSystem.ets` | 27 个语义字段 | **仅 5 个文件 import**，且 4 个只取 `Motion`/`spring*`，**没有任何业务页面消费其颜色** |
| **B. `ColorTokens`**（老 7 字段） | `utils/ThemeManager.ets` | 7 个字段 | **17 个文件、共 318 处**调用 `getThemeColors()` / `ThemeManager.*` |
| **C. 资源色** | `resources/base/element/color.json` | 8 个 | 组件兜底；**`dark/color.json` 只有 1 个**（缺 7 个深色覆盖） |

**A 的实际消费情况实测**（`import ... from '.../DesignSystem'` 全仓仅 5 处）：

```
CoverImageView.ets      → 只取 { Motion, springSnappy }
Layout.ets              → 只取 { Motion, springSnappy }
PlayerPage.ets          → 只取 { Motion, springSoft }
ControlAreaComponent.ets→ 只取 { Motion, springSnappy }
ThemeManager.ets        → 取 { AppleTokens, appleColors }（唯一颜色消费者，但转手包装成 apple() 后无人调用）
```

**结论：`AppleTokens` 这套完整的 Apple 语义色实质上是「死代码」——建好了却没人用。** 全应用真实在用的是 B 的 7 字段老令牌 + 散落硬编码。

**硬编码 hex 实测分布**（22 个文件命中；扣除 A/B 两个令牌定义文件后，**20 个业务文件仍有约 124 处裸 hex**）。

> ⚠️ **口径说明**：下表为**仅 hex 字面量**的统计。架构师同步实测含 `rgba(...)` 后为 **24 文件 / ≈160 处**（其中品牌色系 ≈67 处分布 17 文件）。**S-1 验收以架构口径（含 rgba）为准**，下表为其子集。

| 文件 | 裸 hex 处数 | 文件 | 裸 hex 处数 |
|---|---|---|---|
| `widget/pages/WidgetCard.ets` | 18 | `pages/Playlists.ets` | 14 |
| `lyric/LrcView.ets` | 13 | `pages/SettingsCategory.ets` | 13 |
| `pages/PlaylistDetail.ets` | 10 | `pages/Mine.ets` | 8 |
| `components/OnboardingSheet.ets` | 7 | `components/SettingsSubPageBodies.ets` | 6 |
| `pages/Settings.ets` | 6 | `pages/Favorites.ets` | 5 |
| `pages/LocalLibrary.ets` | 5 | `components/AddToPlaylistSheet.ets` | 4 |
| `pages/PlayHistory.ets` | 3 | `pages/Layout.ets` | 3 |
| `pages/FolderBrowse.ets` / `Splash.ets` / `ColorConversion.ets` | 各 2 | `ControlAreaComponent` / `QualityBadge` / `PlayerInfoComponent` | 各 1 |

**这就是「Apple 风格无法整体落地」的根因**：令牌层三分、真源不明、业务绕过令牌直写 hex。**不先统一令牌，任何视觉重设计都会退化成 20 个文件各自刷漆。**

### 1.4 现有交互骨架（资产，需保留并强化）

| 交互 | 实现 | 评价 |
|---|---|---|
| 底部悬浮胶囊导航 | `Layout.customBottomBar()`：`92%` 宽 / `maxWidth 520` / `borderRadius 30` / `margin bottom = bottomHeight+12` | ✅ 已是 Apple 浮动栏形态，**保留** |
| API 26 沉浸材质 | 动态 `import('@ohos.arkui.uiMaterial')` → `ImmersiveMaterial.REGULAR`，挂在真实 `Row` 上；API 24 走 `cardBg`+阴影 | ✅ 闸门正确，**保留** |
| 一镜到底 | `geometryTransition('player_cover')`；进出场**对称**包 `animateTo(interpolatingSpring(0,1,342,38))` | ✅ 已对称，**保留** |
| 点按回弹 | `onTouch` Down→`scale 0.9` / Up→`1.0` + `springSnappy()` | ✅ 保留，但**缩放比例需统一**（现 Layout 用 0.9、Mine 用 0.97） |
| 长按上下文菜单 | `bindContextMenu(..., ResponseType.LongPress)` | ✅ 保留 |
| 单一 Sheet 调度 | `Mine.ets` 用 `sheetKind`+`sheetVisible` 切换 Settings/About，**避免同节点挂两个 bindSheet 串台** | ✅ 这是踩坑后的正确解，**严禁回退** |
| 主题响应式 | `AppStorage('isDark')` + `@StorageProp` + **普通方法** `getThemeColors()` | ✅ 必须用普通方法（见 §5.4 红线） |
| 降低动态效果 | `SettingsStore.getReduceMotion()`，已用于封面停转/空态呼吸/列表错峰 | ✅ 保留并**扩展覆盖面** |

### 1.5 版本闸门实测

`build-profile.json5` 确认：`compatibleSdkVersion: "6.1.1(24)"`、`targetSdkVersion: "26.0.0"`。
→ **API 24 是运行时下限**，API 26 专属能力必须动态 import + `ApiCompat.isAtLeast(26)` 双闸门。

---

## 2. 重设计目标与成功标准

### 2.1 目标陈述

> 在**不改动任何功能、信息架构与数据流**的前提下，将 Lumio Music 的视觉与交互语言统一到 Apple 设计体系（iOS 语义色分层、留白节奏、圆角阶梯、字体排版阶梯、弹簧动效、明暗模式一等公民），并**消除令牌层三分与硬编码色**这一结构性设计债。

### 2.2 成功标准（可验证，逐条可测）

| # | 标准 | 验证方法 | 阈值 |
|---|---|---|---|
| **S-1** | **零裸 hex**：业务代码（`pages/**`、`components/**`、`lyric/**`）不出现颜色字面量 | `Grep '#[0-9A-Fa-f]{3,8}'` 排除令牌定义文件 | 命中数 = **0**（基线 124 → 0） |
| **S-2** | **单一颜色真源**：全部页面/组件经统一令牌取色，`ColorTokens` 老 7 字段与 `AppleTokens` 完成归一 | 全仓仅 1 个文件定义色值；`Grep` 令牌 import 覆盖率 | 用色文件 **100%** import 统一令牌 |
| **S-3** | **深浅色对比度达标**：正文文字 ≥ 4.5:1，大文本/次要文字 ≥ 3:1（WCAG AA）<br>**歌词按意图分两档**（R-04b 裁决）：**播放态** 当前行 ≥4.5 / 非当前行 ≥3 / 翻译行 ≥3；**浏览态**（拖拽中或手动定位后 5s 内）**当前行、非当前行、翻译行全部 ≥4.5**（翻译行 14vp 属小文本，**无大文本豁免**） | 对 §6.6 对照表逐令牌算对比度 + 真机深/浅双走查 + 歌词每档每态截图 | 主文字 **≥4.5:1**，次文字 **≥3:1**，歌词按两档口径分态达标 |
| **S-4** | **资源色深色补全**：`dark/element/color.json` 为 `base` 全量镜像 | 比对两文件 `name` 集合 | base 8 项 → dark **8 项**（基线 1 项） |
| **S-5** | **尺度收敛**：圆角/间距/字号只取 §6 阶梯值 | `Grep 'borderRadius\('` 白名单校验 | 非阶梯值命中 = **0** |
| **S-6** | **动效可降级**：`reduceMotion` 开启时所有装饰性动画关闭，功能性反馈保留 | 设置内开关 → 逐页走查 | 装饰动画 **100%** 停；点按反馈仍在 |
| **S-7** | **构建与兼容不回退** | 每个里程碑独立 `hvigor assembleHap` + API 24/26 双设备冒烟 | 编译 **0 error**，无新增运行时崩溃 |
| **S-8** | **功能零回归** | 对 §5.1 功能清单逐条回归 | 功能项 **100%** 可用 |

> **S-1 与 S-2 是本次重设计的「地基」**，若不达标，S-3/S-5 无法稳定收敛（改一处漏三处）。

---

## 3. 设计治理冲突 —— **已裁决（AD-0）**

> **状态更新（本节已闭环）**：高见远（system-architect）在 `docs/UI重设计_设计令牌架构.md` §0.1 独立发现同一冲突，并已由 **team-lead 批准裁决 AD-0**。
> **本节保留冲突事实作为背景记录；裁决结论以 AD-0 为准，见 §3.3。**
> 我原提的「方案 A」与架构师的 **AD-3 方案 B（派生垫片）** 已独立收敛为同一手段 —— 见 §7.3 说明。

### 3.1 冲突事实

仓库内**已存在两份互相矛盾的设计规范**，各自宣称自己是「唯一权威源」：

| | `docs/UI设计系统.md` | `docs/design_tokens.md`（v1.0，**作者：蓝绘心**） |
|---|---|---|
| 宣称真源 | `DesignSystem.ets` 的 `AppleTokens`；`ThemeManager.apple()` | `ThemeManager.lightColors` / `darkColors`（§0.1 明写「语义色唯一权威源」） |
| 令牌体系 | iOS 完整语义分层（27 字段） | 老 7 字段 + 新增 `accentSoft` |
| 对 iOS 系统色态度 | **推荐**，列为 `systemBlue/Green/Orange/Red/Purple` 令牌 | **🚫 红线明令禁止**（§3.3） |

`design_tokens.md` §3.3 原文（红线清单）：

```
以下色值全仓任何位置不得出现：
#34C759  #FF9500  #007AFF  #5E5CE6  #FFCC00  #5856D6
```

而 `DesignSystem.ets` 的 `LIGHT_APPLE` 令牌**恰好包含其中 4 个**：
`systemGreen: '#34C759'`、`systemOrange: '#FF9500'`、`systemBlue: '#007AFF'`、`systemPurple: '#5856D6'`。

同时 `Mine.ets` 实测**正在使用全部这批被禁色**（第 159/171/183/203/215/227/239/276 行：`#FA2759` `#34C759` `#FF9500` `#5856D6` `#007AFF`）——即**当前代码同时违反 design_tokens.md，又没走 AppleTokens**。

### 3.2 冲突性质判断

这不是简单的「文档过期」，而是**两轮设计治理留下的方向性分歧**：

- `design_tokens.md` 的红线**动机是正确的**——它反对的是「每个分类图标一个颜色」的**彩虹式滥用**（原文：「禁止每类一色」），主张回归品牌单色 `#FA2759` + 中性底，以收敛视觉噪音。
- 但它把手段写成了**禁止具体色值**，而这批色值正是 iOS 语义系统色。用户现在明确要求 **Apple 设计风格**，禁掉 iOS 系统色等于自断手脚。

### 3.3 裁决结论：AD-0（team-lead 已批准，**以此为准**）

> 出处：`docs/UI重设计_设计令牌架构.md` §0.1。以下为裁决要点，本规划的 §4/§6/§7 均已按此对齐。

1. **两份旧文档均被新的三层令牌模型取代**：`tokens/` 层（**Primitive / Semantic / Component**）为唯一真源（SSOT）。`design_tokens.md` §0.1「以 7 字段 `ColorTokens` 为权威源」**作废**。
2. **「HIG 调色板禁令」不删除，升级为结构性架构约束**（可被 code-linter 机械检查）：
   - 组件**只能引用 Semantic / Component 层，永远不得引用 Primitive 层**；
   - `systemGreen/Orange/Blue/Purple` 在 Primitive 层保留（色板事实），但在 Semantic 层**只允许以 `success / warning / danger / info` 语义身份出现**；
   - 因此：**语义用法允许，装饰性用法禁止**。
3. **收紧项（比我原提案更严）：装饰性分类配色全面取消。** `Mine.ets` 给每个菜单项染不同色（收藏 `#FA2759` / 歌单 `#5856D6` / 历史 `#FF9500` / 文件夹 `#007AFF`）为全仓最不 Apple 的部分，取代方案为**三级色彩来源优先序**：
   > **内容着色（封面取色） > 语义着色（success/warning/danger/info/brand） > 中性（fill + 单色图标）**
4. `design_tokens.md` 中仍有效的部分（`space_*`/`radius_*` 命名、卡片进程主题链路、F-03 资源镜像缺口）**被新架构吸收沿用**，不产生第三套命名。

> **对本规划的影响**：§6.1 的「用色密度约束」**升级为 AD-0 第 3 条的三级优先序**（更严格，取消装饰性配色而非仅限制数量）；§4 范围表中 `Mine` / `SettingsCategory` 的 L3 整治依据由「≤2 色」改为「装饰色归零 + 三级优先序」。

<details>
<summary>（历史记录）我在裁决前提出的方案 A / B —— 已被 AD-0 取代，保留备查</summary>

**方案 A：升级红线语义，而非废除红线**

1. **颜色真源统一到 `AppleTokens`**（`DesignSystem.ets`），因为它是完整的 iOS 语义分层，是 Apple 风格的必要基础设施；`ThemeManager.ColorTokens` 老 7 字段**降级为对 `AppleTokens` 的语义别名视图**（保持 318 处调用点不必一次性重写，见 §7 M1 的适配层策略）。
2. **`design_tokens.md` §3.3 红线改写**：
   - 旧规则：❌ 禁止出现 `#34C759` 等色值 →
   - 新规则：✅ **禁止任何裸色值字面量**（含品牌色 `#FA2759`），必须经 `AppleTokens` 语义字段引用；
   - **并保留原动机**为一条独立的**用色密度约束**：「同一屏内彩色语义色（非品牌色、非中性色）不得超过 **2** 种；列表/设置分类图标统一中性 `secondaryLabel` 或品牌 `accent` 单色，禁止一类一色」。
3. **`docs/UI设计系统.md` 与 `docs/design_tokens.md` 合并**为单一 `docs/设计系统_Apple.md`，由蓝绘心在 M1 产出，旧两份标注「已废弃，见新文件」。

**方案 B（保守）**：保留品牌单色体系，`AppleTokens` 只用其中的中性层（background/fill/label/separator），彩色语义色仅保留 `systemRed`（危险操作）。视觉更克制，但「Apple 风格」表达力受限。

**我当时的建议是方案 A**，理由：用户诉求明确点名 Apple 风格；`AppleTokens` 已建好且质量高，弃用是浪费；方案 A 通过「用色密度约束」保住了原红线真正想防的问题。

**AD-0 采纳了方案 A 的方向并进一步收紧**：把「约束」从「同屏彩色 ≤ 2 种」升级为「装饰性配色归零 + 三级色彩来源优先序」，并把手段从「文档纪律」升级为「可 linter 检查的分层约束」。**AD-0 更优，本规划全面对齐 AD-0。**

</details>

---

## 4. 重设计范围清单

### 4.1 重设计级别定义

| 级别 | 名称 | 含义 | 允许改动 | 禁止改动 |
|---|---|---|---|---|
| **L0** | **不动** | 完全不进入本次范围 | — | 一切 |
| **L1** | **仅令牌替换** | 取色/尺度来源换成统一令牌，**渲染结果视觉等价**（或仅极微差） | `backgroundColor` / `fontColor` / `borderRadius` 的**取值来源** | 布局结构、组件层级、任何逻辑 |
| **L2** | **样式刷新** | 套用 §6 的圆角/间距/字号/动效阶梯，**布局骨架不变** | 上述 + 间距值、字号字重、动效曲线、按压反馈、状态样式 | 组件层级树、数据绑定、事件语义 |
| **L3** | **深度重构** | 视觉层次重组、公共组件抽取、容器结构调整 | 上述 + 容器嵌套、抽取共享组件、分组重排 | **功能行为、路由名、数据流、状态键位** |

> **L3 的边界**：允许把**五处**重复的歌曲列表项抽成一个 `SongRow` 组件、允许把设置项重排成 iOS `InsetGrouped` 分组卡，但**不允许增删任何一个功能入口、不允许改路由名、不允许改 AppStorage 键位**。
>
> ⚠️ **`FolderBrowse` 例外说明**：其第 5 处列表项**功能本就更少**（无长按菜单、无按压反馈）。接入 `SongRow` 时**保持其现有功能集**（`menuActions: []`），**不得顺势为它新增长按菜单** —— 那属于功能变更，超出本次范围（见 §5 契约）。若认为该页应有菜单，需另立需求。

### 4.2 令牌与基础设施层（前置，非页面）

| 文件 | 级别 | 理由 |
|---|---|---|
| `common/utils/DesignSystem.ets` | **L3** | 升为**唯一颜色/尺度/动效真源**。需补 `accentSoft`、间距 `Spacing`、字体 `Typography` 阶梯、阴影 `Elevation`、`pressScale` 统一比例。§3 裁决的落点。 |
| `utils/ThemeManager.ets` | **L3** | 老 `ColorTokens` 7 字段**降级为 `AppleTokens` 的语义别名视图**（保 318 处调用点不炸）；删除死方法 `getColors()`；保留 `isDark()` / `applyToWindow()` / `setThemeMode()` 全部逻辑不动 |
| `resources/base/element/color.json` | **L1** | 8 项资源色与新令牌**同值对齐**（组件兜底用，如 `slider_*`） |
| `resources/dark/element/color.json` | **L2** | **补全为 base 全量镜像**（1 → 8 项），闭合 S-4。基线缺 7 项深色覆盖 = 深色下回退浅色 |
| `resources/base/element/float.json` | **L2** | 新增 `radius_*` / `space_*` / `font_*` 命名项（343 行，保留现有有效项，只增不删以免断引用） |
| `common/constants/StyleConstants.ets` | **L1** | 与新尺度阶梯对齐；若与 `DesignSystem` 重叠则标注收敛方向（**M4 再清理，M1 不动以降风险**） |
| `common/utils/BreakpointSystem.ets` / `BreakpointConstants.ets` | **L0** | 断点机制正确（sm/md/lg），本次不改机制，仅由页面消费 |
| `common/utils/ColorConversion.ets` | **L1** | 2 处裸 hex（工具默认值），换令牌 |

### 4.3 壳层与导航（高风险、高可见度）

| 文件 | 级别 | 理由 |
|---|---|---|
| `pages/Index.ets` | **L1** | 仅 `@Entry` + `HdsNavigation` + Splash 覆盖层调度，几无样式。**Splash 淡出时机（1200ms）可微调**，其余不动 |
| `pages/Layout.ets` | **L2** | 悬浮胶囊形态**已是 Apple 风，保留骨架**；刷新点：① 删本地 `const ACCENT` 走令牌 ② 3 处裸 hex ③ tab 按压 `0.9` 与 Mine 的 `0.97` **统一为 0.96** ④ 阴影走 `Elevation` 令牌 ⑤ API 26 材质闸门**原样保留**。**⚠️ 材质必须挂真实 `Row`，不能挂 `@Builder` 调用** |
| `pages/Splash.ets` | **L2** | 品牌首屏，Apple 风格重点（大圆角 logo + 品牌字体阶梯）；2 处裸 hex；需接 `reduceMotion`（当前 700ms 缩放动画未受控） |

### 4.4 主 Tab 页（用户停留最久，最高优先级）

| 文件 | 级别 | 理由 |
|---|---|---|
| `pages/LocalLibrary.ets`（27KB，**全仓最大**） | **L3** | 音乐库主页。34 处 `getThemeColors()` + 5 处裸 hex。**L3 理由**：① 歌曲列表项与 Favorites / PlaylistDetail / PlayHistory / FolderBrowse **五处重复** → 抽 `SongRow` 公共组件（见 §4.6.1）② 搜索/排序/导入区需按 iOS 视觉层次重组（大标题 + 搜索栏 + 分段控件节奏）③ `bindContextMenu` 菜单项样式统一 ④ 空态/加载态按 Apple 规范重做 |
| `pages/Mine.ets` | **L3** | 「我的」主页。15 处 `getThemeColors()` + **8 处裸 hex（含全部 5 个 §3 争议色）**。**L3 理由**：① 统计三栏（歌曲/收藏/历史）当前一色一栏，是 §3 用色密度约束的**首要整治对象** ② 菜单区应改为 iOS `InsetGrouped` 分组卡（当前是独立圆角卡堆叠 + `margin bottom 8`）③ 按压 `0.97` 需统一。**⚠️ `sheetKind`+`sheetVisible` 单 Sheet 调度机制严禁改动** |

### 4.5 播放体验（品牌核心，视觉最重）

| 文件 | 级别 | 理由 |
|---|---|---|
| `pages/PlayerPage.ets` | **L1** | 实测仅 100 行薄壳：`NavDestination` + `PlayerInfoComponent` + 入场弹簧。**一镜到底 `animateTo(interpolatingSpring(0,1,342,38))` 与 `back()` 对称性严禁破坏**。真实 UI 在下方组件 |
| `components/PlayerInfoComponent.ets` | **L3** | 播放页真实容器（封面/信息/控制/歌词编排）。**L3 理由**：Apple 风播放页的视觉层次（封面主导、信息次级、控制区浮起）需重排间距与层级 |
| `components/ControlAreaComponent.ets` | **L2** | 23 处 `getThemeColors()`，已 import `springSnappy`。刷新：按钮尺寸阶梯（主 56 / 次 40）、进度条 Slider 令牌化、1 处裸 hex |
| `components/MusicInfoComponent.ets` | **L2** | 含 API 26 `ContainerReader` + `StyledString` 标题渲染。**⚠️ API 26 闸门与 `TextController.setStyledString` 逻辑不动**，仅刷字体阶梯与间距 |
| `components/CoverImageView.ets` | **L2** | 封面容器，已 import `Motion`/`springSnappy`。刷新圆角阶梯 + 阴影令牌；**`geometryTransition('player_cover')` 共享 ID 严禁改名** |
| `components/LyricsComponent.ets` | **L2** | 歌词容器（18 处状态/绑定）。刷字体阶梯、行高、高亮色令牌化 |
| `lyric/LrcView.ets` | **L2** | **Canvas 手绘歌词，13 处裸 hex**。Canvas 内无法吃 ArkUI 令牌，需**显式注入令牌色参数**（构造/属性传入），这是本次令牌统一的**特殊通道**。**⚠️ `PanGesture` 跟手逻辑（`onActionStart/Update/End` 增量派发）严禁改动** |
| `components/QualityBadge.ets` | **L1** | 音质角标，1 处裸 hex，纯令牌替换 |
| `components/TopAreaComponent.ets` | **L2** | 顶部区域（4 处绑定），刷间距与字体阶梯 |

### 4.6 二级列表页（复用同一列表模式，批量收益）

| 文件 | 级别 | 理由 |
|---|---|---|
| `pages/Favorites.ets` | **L2** | 23 处 `getThemeColors()` + 5 处裸 hex。**待 M2 抽出 `SongRow` 后降级为接入 + 样式刷新**；空态按 Apple 规范重做 |
| `pages/PlayHistory.ets` | **L2** | 25 处 `getThemeColors()` + 3 处裸 hex。同上，接入公共列表项 |
| `pages/Playlists.ets` | **L3** | 31 处 `getThemeColors()` + **14 处裸 hex（全仓业务文件第二高）**。**L3 理由**：歌单网格/列表卡片需按 Apple 卡片规范重构（封面九宫格、圆角、阴影层次）；新建歌单入口样式重做 |
| `pages/PlaylistDetail.ets` | **L3** | 36 处 `getThemeColors()`（**全仓业务文件最高**）+ 10 处裸 hex。**L3 理由**：头部大封面 + 渐变 + 播放全部按钮是 Apple Music 式布局重点；列表项接入公共组件 |
| `pages/FolderBrowse.ets` | **L2** | 13 处 `getThemeColors()` + 2 处裸 hex。文件夹层级列表，刷新为 iOS 分组列表样式。**含第 5 处重复列表项（降级变体，见 §4.6.1）** |

#### 4.6.1 歌曲列表项重复清单（**实测 5 处，已核验行号**）

> 本表由 `buildSongMenu` / 行构建函数实测得出，与 system-architect 复核结果一致。

| # | 文件:行 | 构建函数 | 长按菜单 | 特殊差异 |
|---|---|---|---|---|
| 1 | `LocalLibrary.ets:446` | `buildSongMenu(song)` | ✅ | 基准实现；行渲染在 `:431` 绑定 |
| 2 | `Favorites.ets:111` | `buildSongMenu(song)` | ✅ | 「取消收藏」语义差异 |
| 3 | `PlaylistDetail.ets:171` | `buildSongMenu(song, **index**)` | ✅ | **唯一多 `index` 参数**；独有「从歌单移除」 |
| 4 | `PlayHistory.ets:104` | `buildSongMenu(song)` | ✅ | — |
| 5 | **`FolderBrowse.ets:153`** | `private songRow(song)` | ❌ **无** | **降级变体**：无长按菜单、无按压反馈、固定 `height(64)`、`coverRadius 8`/`borderRadius 12`（阶梯外）、无 `QualityBadge` |

**第 5 处为何两轮侦察都漏掉**：它没有 `bindContextMenu`，因此以「菜单」为线索的检索无法命中 —— 需以「行构建函数」为判据才能发现。这也说明 **`SongRow` 的 `menuActions` 必须支持空数组**（无菜单形态），而非假定每行都有菜单。

**接口含义**：架构师的 `menuActions: SongMenuAction[]` 数组注入设计**天然覆盖**这一形态（空数组 = 无菜单），无需额外开关参数。`index` 一律透传（仅 `PlaylistDetail` 消费）。

### 4.7 设置与信息页

| 文件 | 级别 | 理由 |
|---|---|---|
| `pages/Settings.ets` | **L2** | 9 处 `getThemeColors()` + 6 处裸 hex。改为 iOS `InsetGrouped` 分组样式。**⚠️ `onRequestClose` 回调契约与 sheet 内二级导航（`@State selectedCategory` 切换）机制不动** |
| `pages/SettingsCategory.ets` | **L3** | 18 处 `getThemeColors()` + **13 处裸 hex（含争议分类色）**。**L3 理由**：分类图标一类一色是 §3 用色密度整治的第二对象；分组卡结构需重排 |
| `pages/About.ets` | **L2** | 26 处 `getThemeColors()`，0 裸 hex（相对干净）。刷版本信息卡、许可证区、品牌头部字体阶梯。**⚠️ `onStartOnboarding` + `pendingOnboarding` 衔接机制严禁改动**（防两 Sheet 同帧叠加空白页） |
| `components/SettingsSubPageBodies.ets`（~900 行） | **L3** | **本次最高杠杆单点**：一处覆盖 4 个页面 + 共享头部。53 处 `getThemeColors()`（全仓最高）+ 6 处裸 hex。**L3 理由**：`SubPageHeader` 需统一为 Apple 二级页头部规范（返回键 + 大标题过渡）；`WrappedBody`（年度回顾）是数据可视化，视觉重做空间最大 |
| `pages/ManageSongs.ets` | **L0** | 实测薄壳，无样式代码，UI 全在 `ManageSongsBody` |
| `pages/DuplicateSongs.ets` | **L0** | 同上，UI 在 `DuplicateSongsBody` |
| `pages/PrivacyPolicy.ets` | **L0** | 同上，UI 在 `PrivacyPolicyBody` |
| `pages/Wrapped.ets` | **L0** | 同上，UI 在 `WrappedBody`（薄壳仅多一层 `Column` 包裹） |

### 4.8 半模态 Sheet

| 文件 | 级别 | 理由 |
|---|---|---|
| `components/SongDetailSheet.ets` | **L2** | 6 处 `getThemeColors()`，已用 API 26 `systemMaterial` 沉浸材质。刷信息行排版（label/value 两列节奏）。**⚠️ 材质优先级高于 `backgroundColor`，不要重复设背景色** |
| `components/AddToPlaylistSheet.ets` | **L2** | 12 处 `getThemeColors()` + 4 处裸 hex。刷歌单选择列表 + 新建入口 |
| `components/OnboardingSheet.ets` | **L2** | 6 处 `getThemeColors()` + **7 处裸 hex**。首启引导，Apple 风格首因印象重点（分页图示 + 大标题 + 主按钮） |

### 4.9 桌面卡片（独立渲染进程，特殊约束）

| 文件 | 级别 | 理由 |
|---|---|---|
| `widget/pages/WidgetCard.ets` | **L2** | **18 处裸 hex（全仓最高）**。⚠️ **特殊约束**：ArkTS 卡片运行在独立 Form 渲染进程，**无法共享 `AppStorage`、不能 import `ThemeManager`**（其依赖 `window`/Preferences）。方案：卡片内自建轻量 `cardColors(isDark)`，**值与主令牌同值**，`isDark` 经 `@LocalStorageProp` 由 `FormAbility.createFormBindingData` 注入 |
| `ets/formability/FormAbility.ets` | **L1** | 需在 `onAddForm`/`onUpdateForm` 与主题变更时向卡片推 `isDark`，闭合卡片主题链路（历史文档记为 G-4 未闭合项） |

### 4.10 明确不在本次范围（L0，无需任何改动）

以下为**纯逻辑/数据层**，与视觉无关，本次**完全不动**：

`services/MusicStore.ets`、`services/SmartPlaylistService.ets`、`utils/AudioRendererController.ets`、`utils/AVSessionController.ets`、`utils/SettingsStore.ets`、`utils/PreferencesUtil.ets`、`utils/CoverCache.ets`、`utils/AudioMeta.ets`、`utils/MediaTools.ets`、`utils/NativeModule.ets`、`utils/DuplicateDetector.ets`、`utils/SleepTimer.ets`、`utils/BackgroundUtil.ets`、`utils/EmbeddedLyricReader.ets`、`utils/AppInfoUtil.ets`、`utils/Logger.ets`、`models/**`、`datasource/**`、`songdatacontroller/**`、`lyric/LrcEntry.ets`、`lyric/LrcUtils.ets`、`lyric/LyricConst.ets`、`startup/**`、`entryability/**`、`entrybackupability/**`、`common/constants/{Content,Player,Router}Constants.ets`、`common/utils/{ApiCompat,ResourceConversion,SortUtil}.ets`、C++ NAPI 侧全部代码。

### 4.11 范围统计汇总

| 级别 | 文件数 | 占比 | 说明 |
|---|---|---|---|
| **L3 深度重构** | **9** | 26% | `DesignSystem` / `ThemeManager` / `LocalLibrary` / `Mine` / `PlayerInfoComponent` / `Playlists` / `PlaylistDetail` / `SettingsCategory` / `SettingsSubPageBodies` |
| **L2 样式刷新** | **17** | 50% | 壳层 2 + 播放组件 6 + 列表页 3 + 设置页 2 + Sheet 3 + 卡片 1 |
| **L1 仅令牌替换** | **8** | 24% | `Index` / `PlayerPage` / `QualityBadge` / `ColorConversion` / `StyleConstants` / `base/color.json` / `FormAbility` / `Favorites`（M2 后） |
| **L0 不动** | **4 薄壳 + 约 35 逻辑文件** | — | 薄壳 4 个 + 逻辑/数据层全部 |
| **合计进入范围** | **34 个文件** | | 其中真正需要设计稿的约 **14 个界面** |

> **关键洞察**：34 个文件里，**9 个 L3 承载 80% 的设计价值**；而 `SettingsSubPageBodies.ets`（1 文件覆盖 4 页）与 `SongRow` 抽取（1 组件覆盖 4 页列表）是**两个最高杠杆点**，应优先排期。

---

## 5. 明确保持不变的部分（**契约条款，违反即视为验收失败**）

> 本章是用户的**核心诉求之一**。本次是视觉与交互层重设计，以下四类内容构成**不可变契约**。
> 任何 PR 若触及本章内容，须先回到 team-lead 重新评审范围。

### 5.1 功能集（逐条，**100% 保持可用且行为一致**）

> **🚫 歌词专项边界（M3 冻结条款，team-lead 裁定）**
>
> 本次**允许**做的：歌词**浏览态可读性提升** —— 属于**视觉分级**（提高非当前行/翻译行的 `fillStyle` 不透明度、按意图分两档、去 blur、切档淡入）。
>
> 本次**明确禁止**做的（属**功能蔓延**，一律不做）：
> - ❌ **逐句跳转**（点击某行定位播放）—— 现网 `PanGesture` 与「点击跳转」是**分离**的两套逻辑，不得合并、不得新增行级热区
> - ❌ **歌词编辑 / 手动校正时间轴**
> - ❌ **翻译源切换 / 多语切换入口**
> - ❌ 任何改变 `.lrc` 解析结果、内嵌歌词读取时序、逐行高亮时序的改动
>
> 判定口径：**只动「字看起来多清楚」，不动「能对它做什么」。** 凡触及 F-15 保持要求的改动，须 team-lead 批准。

| # | 功能 | 入口 | 保持要求 |
|---|---|---|---|
| F-01 | **歌曲导入** | 音乐库「导入」→ `DocumentViewPicker` | 选择器调用、沙箱拷贝、去重、`preferences` 持久化链路**完全不变** |
| F-02 | **搜索** | 音乐库搜索框 | 匹配字段（标题/歌手/专辑）、大小写与模糊策略不变 |
| F-03 | **排序** | 音乐库排序入口（`SortUtil`） | 全部排序维度与升降序语义不变 |
| F-04 | **收藏** | 列表长按菜单 / 播放页心形 / `Favorites` 页 | `isFavorite` 状态键、收藏集合持久化不变 |
| F-05 | **歌单** | `Playlists` / `PlaylistDetail` / `AddToPlaylistSheet` | 建/删/改名/加歌/移除/排序、`SmartPlaylistService` 智能歌单逻辑不变 |
| F-06 | **播放历史** | `PlayHistory` 页 | `recentlyPlayed` 记录时机、容量上限、清空逻辑不变 |
| F-07 | **文件夹浏览** | `FolderBrowse` 页 | 按来源目录归组的层级与展开逻辑不变 |
| F-08 | **重复检测** | 设置 → `DuplicateSongs`（`DuplicateDetector`） | 判重算法（指纹/元数据比对）与批量删除流程不变 |
| F-09 | **年度回顾** | 设置 → `Wrapped`（`WrappedBody`） | 统计口径、TopSongs 计算、跳播放页行为不变 |
| F-10 | **歌曲管理** | 设置 → `ManageSongs` | 批量删除/移除、确认弹窗语义不变 |
| F-11 | **设置项（8 项，逐条不变）** | `Settings` / `SettingsCategory` | `getAutoNext` / `getRepeatMode` / `getThemeMode` / `getNotificationLockScreen` / `getPrivacyStats` / `getReduceMotion` / `getSleepTimer` / `getGapless` —— **键名、取值域、默认值、持久化行为全部不变** |
| F-12 | **睡眠定时** | 设置（`SleepTimer`） | 定时档位与到点淡出停止行为不变 |
| F-13 | **桌面卡片** | `WidgetCard` + `FormAbility` | 卡片尺寸规格、`formConfig` 、点击跳转 Want、刷新周期不变 |
| F-14 | **系统播控 / 投播** | `AVSessionController` | AVSession 元数据上报、锁屏/通知控制、播控中心指令响应不变 |
| F-15 | **歌词** | `LyricsComponent` + `LrcView` + `EmbeddedLyricReader` | 内嵌歌词读取、`.lrc` 解析、逐行高亮时序、**`PanGesture` 跟手 + 点击跳转分离**不变<br>⚠️ **M3 专项边界**：只允许**视觉分级**（浏览态提可读性），**禁逐句跳转 / 歌词编辑 / 翻译源切换** —— 见 §5.1 抬头冻结条款 |
| F-16 | **播放核心** | `AudioRendererController` | 播放/暂停/上下曲/进度/倍速/播放模式/Gapless、队列语义（**`getQueue()` 优先于整库**的 Bug A 修复）不变 |
| F-17 | **封面提取** | `CoverCache` + C++ NAPI `AudioMeta` | 抽取时机、缓存键、`coverRefreshToken` 通知机制不变 |
| F-18 | **首启引导 / 权限说明** | `OnboardingSheet` + 权限 AlertDialog | 仅弹一次的持久化标记（`isOnboardingShown` / `isPermGuideShown`）与时序不变 |
| F-19 | **主题模式** | 设置 → 浅色/深色/跟随系统 | 三档语义、`systemIsDark` 跟随链路、`applyToWindow()` 系统栏同步不变 |
| F-20 | **降低动态效果** | 设置开关 | 开关本身不变；**覆盖面只增不减**（见 §6.5） |
| F-21 | **隐私政策 / 关于** | `PrivacyPolicyBody` / `About` | 文本内容、版本号展示、许可证信息不变 |

### 5.2 信息架构（**导航栈 / Tab / 路由名 / Sheet 语义全部冻结**）

**① 路由名（`route_map.json` 14 条）—— 一个字符都不许改**

```
Layout · PlayerPage · Settings · SettingsCategory · About · PrivacyPolicy
PlayHistory · Favorites · ManageSongs · Playlists · PlaylistDetail
DuplicateSongs · Wrapped · FolderBrowse
```

> 理由：`pushPathByName('...')` 全仓引用 + Want「用 Lumio 打开」跨 Ability 依赖 + 薄壳 `buildFunction` 名绑定。改名 = 运行时找不到页面。

**② 层级结构**

```
Index (@Entry, HdsNavigation + NavPathStack)
├── Splash 覆盖层（1200ms 后淡出）
└── Layout（NavDestination，底部悬浮胶囊 + Tabs）
    ├── Tab 0：LocalLibrary（音乐库）
    └── Tab 1：Mine（我的）
         ├── Sheet：Settings ──（内部 @State selectedCategory）── SettingsCategoryDetail
         └── Sheet：About
    ├── push → PlayerPage（一镜到底）
    ├── push → Favorites / Playlists → PlaylistDetail / PlayHistory / FolderBrowse
    └── push → ManageSongs / DuplicateSongs / Wrapped / PrivacyPolicy（薄壳 → Body）
```

- **Tab 数量与顺序不变**（2 个：音乐库 / 我的）。
- **`Layout` 承载引导 Sheet、`Mine` 承载设置/关于 Sheet** 的分工不变。
- **二级页进入方式不变**：哪些走 `pathStack.push`、哪些走 sheet 内 `@State` 切换，保持现状。

**③ Sheet 语义（严禁改动的三条机制）**

| 机制 | 现状 | 为何冻结 |
|---|---|---|
| **单 Sheet 调度** | `Mine.ets` 用 `sheetKind`(''/'settings'/'about') + `sheetVisible` 切换内容 | 历史踩坑：同一节点挂两个 `bindSheet` 会**串台/打不开** |
| **`onDisappear` 才复位 `sheetKind`** | 关闭动画期间保持内容渲染 | 否则关闭动画期 `kind=''` 渲染**空白页** |
| **`pendingOnboarding` 衔接** | 关于页点引导 → 标记 → 关本 Sheet → `onDisappear` 再开引导 | 否则两 Sheet **同帧叠加出空白 large 页** |

- `detents` 档位（`[SheetSize.LARGE, SheetSize.MEDIUM]` / `['90%']`）、`dragBar: true`、`showClose: true` 保持。
- ⚠️ 本 SDK 的 `SheetOptions` **无** `mask` / `preferType` / `SheetType` / `SheetSize` 选项（历史已验证），不要引入。

### 5.3 数据流与状态管理（**AppStorage 键位全部冻结**）

**实测全量键位清单（26 个，一个都不许改名/改类型）**：

| 分类 | 键位 |
|---|---|
| 播放队列 | `songList` · `selectIndex` · `playMode` · `playSpeed` |
| 播放状态 | `isPlay` · `progress` · `progressMax` · `currentTime` · `totalTime` · `isFavorite` · `isSilentMode` |
| 播放页视觉 | `imageColor` · `lyricBgDark` · `isFoldFull` · `pageShowTime` |
| 布局安全区 | `topHeight` · `bottomHeight` · `currentBreakpoint` |
| 主题 | `isDark` · `themeMode` · `systemIsDark` |
| 通知/调度 | `coverRefreshToken` · `showOnboarding` |
| 全局引用 | `navPathStack` · `context` · `window` |

**单例与服务边界不变**：
`MusicStore.getInstance()` · `AudioRendererController.getInstance()` · `SettingsStore.getInstance()` · `PreferencesUtil.getInstance()` · `AVSessionController` · `SmartPlaylistService` · `CoverCache` —— **不得改签名、不得改单例语义、不得在 UI 层新增业务状态源**。

**响应式绑定方式不变**：页面统一 `@StorageProp('isDark')` + **普通方法** `getThemeColors()`（见 §5.4 红线）。

### 5.4 业务红线（**ArkTS 语法 / 兼容 / 安全，违反即编译失败或运行时崩溃**）

| # | 红线 | 后果 |
|---|---|---|
| **R-1** | `build()` / `@Builder` 体**首条语句不能是 `const`/`let`**，只能行内调用 | 编译失败 |
| **R-2** | `@Component` / `@CustomDialog` 上**普通 `get` 访问器会被整段丢弃** → 必须用**普通方法**（如 `getThemeColors()`） | **运行时 undefined 崩溃**（最易踩，重构取色时高危） |
| **R-3** | 禁裸 `console.*` / `hilog`，统一 `utils/Logger.ets` | 审查驳回 |
| **R-4** | 禁 `any` / `unknown`、禁解构声明、禁行内对象字面量当类型 | 编译/lint 失败 |
| **R-5** | `CustomDialogController` / `NavPathStack` 等为**全局环境声明**，勿从 `@kit.ArkUI` import | 编译失败 |
| **R-6** | API 26 专属（`ContainerReader`、`@ohos.arkui.uiMaterial` 整模块）必须**动态 import + `ApiCompat.isAtLeast(26)` 双闸门** | API 24 运行时**模块不存在崩溃** |
| **R-7** | 材质/毛玻璃必须挂**真实容器组件**（`Row`/`Column`），不能链式挂 `@Builder` 调用（返回 `void`） | 编译失败 |
| **R-8** | 所有文件保留 **Apache-2.0 头注释（Copyright 2026 何宇翔）**，新增文件照抄 | 合规失败 |
| **R-9** | **权限最小化**：不得为视觉需求新增任何权限；本应用无联网、无账号，**不得引入网络请求** | 隐私合规失败 |
| **R-10** | 卡片（Form 进程）**不能** import `ThemeManager` / 访问 `AppStorage` | 卡片渲染崩溃 |

---

## 6. Apple 设计原则落地清单（用户点名 6 项 → 本项目可执行指标）

> **落地口径**：每项都给出「Apple 原则 → 本项目具体要求 → 可量化指标 → ArkUI 表达方式」。
> 所有新增令牌落在 `common/utils/DesignSystem.ets`（§3 方案 A 裁决后）。

### 6.1 简洁的视觉层次（Visual Hierarchy）

**Apple 原则**：用「背景分层 + 填充分层 + 文字分层」三套语义层级表达纵深，而非靠边框和阴影堆叠。同屏只有一个视觉主角。

| 要求 | 量化指标 | ArkUI 表达 |
|---|---|---|
| **背景三层制** | 页面底 `systemBackground` → 分组底 `systemGroupedBackground` → 卡片面 `secondarySystemGroupedBackground`，**层级差不超过 3 层** | `.backgroundColor(tokens.xxx)` |
| **填充四层制** | 控件底按 `systemFill` → `secondary` → `tertiary` → `quaternary` 递减，用于按压态/选中底/占位块 | 已有 4 级令牌，直接取用 |
| **文字四层制** | `label`（主）/ `secondaryLabel`（次）/ `tertiaryLabel`（占位）/ `quaternaryLabel`（禁用），**同屏文字层级 ≤ 3 种** | `.fontColor(tokens.label)` |
| **色彩来源优先序**（AD-0 第 3 条，**取代原「≤2 色」提法**） | **内容着色（封面取色） > 语义着色（success/warning/danger/info/brand） > 中性（fill + 单色图标）**。装饰性分类配色**归零**；分类图标统一中性 fill + 单色 | 整治 `Mine.ets`（现 5 色 → 0 装饰色）、`SettingsCategory.ets` |
| **分层引用约束**（AD-0 第 2 条） | 组件**只能引用 Semantic / Component 层，禁止引用 Primitive 层**（可 linter 机械检查） | `import` 白名单校验 |
| **主角唯一** | 每屏一个 `accent` 主动作；`accent` 面积占比 **< 10%** | 品牌色仅用于主按钮/选中态/关键计数 |
| **阴影克制** | 浅色 3 档（见 §6.3）；**深色模式阴影 α → 0**，改用 `separator` 描边表达边界 | `.shadow()` 按 `isDark` 分支 |

**首要整治对象**：`Mine.ets` 统计三栏（`#FA2759`/`#34C759`/`#FF9500` 三色并列）→ 统一为 `label` 数字 + `labelSecondary` 标签，仅「歌曲」总数用 `accent` 强调（**3 色 → 1 色**）；菜单项四色图标（`#FA2759`/`#5856D6`/`#FF9500`/`#007AFF`）→ **全部改中性 fill + 单色图标（装饰色归零，AD-0 第 3 条）**。

### 6.2 留白（Spacing / Breathing Room）

**Apple 原则**：4pt 基础栅格；页面水平边距恒定；用间距而非分隔线划分区块。

| 令牌 | vp | 用途 |
|---|---|---|
| `space.xxs` | **2** | 图标与文字微调 |
| `space.xs` | **4** | 标题与副标题间（栅格基准） |
| `space.sm` | **8** | 元素间、卡片间 |
| `space.md` | **12** | 列表项内上下padding |
| `space.lg` | **16** | **页面水平边距（全局恒定）** / 卡片内边距 |
| `space.xl` | **20** | 卡片内大间距 |
| `space.xxl` | **24** | 区块间距 |
| `space.section` | **32** | 大区块分隔（替代分隔线） |
| `space.hero` | **40** | 播放页封面上下留白 |

**硬性指标**：

1. **页面水平边距统一 16vp**（现状已基本为 16，需全量核对；`Mine.ets` 统计栏用了 `left/right 32` 属于内容内缩，登记为例外）。
2. **列表项高度改自适应**：禁止固定 `height(60/64/76)`，改 `minHeight(60)` + 内部 `padding({top:12,bottom:12})` — **无障碍必需**（超大字体下固定高度会挤压多行文本）。当前 `Mine.buildMenuItem` 用 `.height(60)`，须改。
3. **分组间距 ≥ 24vp** 时可省略分隔线（Apple 做法：留白即分隔）。
4. **安全区**：顶部 `topHeight` / 底部 `bottomHeight` 统一经 `@StorageProp` + `expandSafeArea`，**不得硬编码状态栏高度**。
5. **底部内容避让**：列表底部 padding = `bottomHeight + 16 + 悬浮胶囊高度`，保证最后一项不被胶囊遮挡（现 `Layout` 用 `bottomHeight + 16`，需核对是否够）。

### 6.3 圆角（Corner Radius）

**Apple 原则**：圆角与元素尺寸成正比，形成阶梯；嵌套时外圆角 > 内圆角。

| 令牌 | vp | 用途 | 现状映射 |
|---|---|---|---|
| `radius.xs` | **4** | 徽章、chip 内小元素 | 新增 |
| `radius.sm` | **10** | 小按钮、封面小图、输入框 | ✅ 已有 `Radius.sm` |
| `radius.md` | **14** | **列表项、菜单项、迷你封面** | ✅ 已有 `Radius.md`（`Layout` 迷你封面 14 已符合） |
| `radius.lg` | **20** | 大卡片、Sheet 顶角、播放页封面 | ✅ 已有 `Radius.lg` |
| `radius.xl` | **28** | 品牌 logo、超大卡片 | 新增（`Splash` logo 现 28 ✅ 已符合） |
| `radius.floatingBar` | **30** | **悬浮胶囊导航（登记为具名例外，保留现值）** | `Layout` 现 30 |
| `radius.pill` | **999** | 胶囊按钮、圆形图标按钮 | ✅ 已有 |

**硬性指标**：

1. **禁止阶梯外的随机半径**。全仓 `borderRadius(15/16/21/22/32/...)` 一律收敛到上表（S-5 验证项）。
2. **嵌套规则**：内层圆角 = 外层圆角 − 内边距，且不小于 `radius.xs`。例：卡片 `radius.lg 20` + 内边距 `space.sm 8` → 内部封面 `radius.md 14`（20−8=12 → 就近取 14 或 10）。
3. **`radius.floatingBar 30` 保留现值**而非改 pill：避免零收益的视觉回归；但必须**登记为具名令牌**，不再是魔法数字。

**阴影阶梯（配合 §6.1）**：

| 令牌 | 浅色参数 | 深色处理 |
|---|---|---|
| `elevation.sm` | `radius 8 / rgba(0,0,0,0.06) / y 2` | α → 0，改 `separator` 0.5vp 描边 |
| `elevation.md` | `radius 16 / rgba(0,0,0,0.10) / y 4` | 同上 |
| `elevation.lg` | `radius 22 / rgba(0,0,0,0.18) / y 8` | α → `0.45`（浮动胶囊需保留纵深，现值即此） |

### 6.4 字体排版（Typography）

**Apple 原则**：SF Pro 文本样式阶梯（Large Title → Caption2），字号/字重/行高三者绑定，不单独调字号。

| 令牌 | 字号 fp | 字重 | 行高 vp | 用途 | 现状 |
|---|---|---|---|---|---|
| `type.largeTitle` | **34** | Bold | 41 | 品牌页（`Splash`） | ✅ Splash 现 34 |
| `type.title1` | **28** | Bold | 34 | 播放页大标题 | 新增 |
| `type.title2` | **24** | Bold | 30 | **页面大标题**（音乐库/我的） | ✅ 现 24 Bold |
| `type.title3` | **20** | Semibold | 25 | 区块标题、统计数字 | ✅ Mine 统计现 20 Bold → 改 Semibold |
| `type.headline` | **17** | Semibold | 22 | 列表主标题（强调） | 新增 |
| `type.body` | **17** | Regular | 22 | 正文 | 新增 |
| `type.callout` | **16** | Medium | 21 | **列表项标题** | ✅ Mine 菜单现 16 Medium |
| `type.subheadline` | **15** | Regular | 20 | 列表副标题（承载正文级信息时用） | 新增 |
| `type.footnote` | **13** | Regular | 18 | 分区头、辅助说明 | ✅ Mine「更多」现 13 |
| `type.caption1` | **12** | Regular | 16 | 副信息、歌手名 | ✅ 现 12 |
| `type.caption2` | **11** | Medium | 13 | Tab 标签、角标 | ✅ Tab 现 11 |

**硬性指标**：

1. **全部用 `fp`**（跟随系统字体缩放），禁用 `px`。
2. **字号必须成对带行高**：`.fontSize(x).lineHeight(y)`，不得只设字号（Apple 排版节奏依赖行高）。
3. **禁止阶梯外字号**（S-5 验证）。
4. **字重只用 4 档**：`Regular` / `Medium` / `Semibold` / `Bold`，禁用 `Lighter`/`Bolder`。
5. **单行截断统一**：`.maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })`；歌名/歌手区禁用跑马灯（除播放页主标题）。
6. **数字对齐**：统计数字、时长用等宽特性避免跳动（时长 `00:00` 已是固定格式）。

### 6.5 动效与交互反馈（Motion & Feedback）

**Apple 原则**：动效表达空间关系而非装饰；一切触摸有即时反馈；尊重「减弱动态效果」。

**① 弹簧曲线（保留现有 3 档 + 登记转场档）**

| 令牌 | 参数（velocity, mass, stiffness, damping） | 用途 | 现状 |
|---|---|---|---|
| `springSnappy()` | `(0, 1, 380, 30)` | 按钮/图标点按 | ✅ 已有 |
| `springSoft()` | `(0, 1, 280, 24)` | 卡片/列表入场 | ✅ 已有 |
| `springGentle()` | `(0, 1, 200, 20)` | 大面积转场 | ✅ 已有 |
| `springHero()` | `(0, 1, 342, 38)` | **一镜到底共享元素**（现为魔法数字，须登记为令牌） | `Layout`/`PlayerPage` 内联 |

**② 时长（保留现值）**：`tap 120` / `press 150` / `sheet 360` / `fade 300` / `stagger 60` ms。

**③ 按压缩放 —— 分两级（修正现状不一致）**

| 令牌 | 比例 | 适用 | 理由 |
|---|---|---|---|
| `pressScale.surface` | **0.97** | 列表项、菜单项、卡片（大面积） | 大面积同比缩放位移更大，0.9 观感过猛 |
| `pressScale.control` | **0.92** | 图标按钮、Tab、播放键（小面积 ≤ 56vp） | 小控件需更明显反馈 |

> **现状修正**：`Layout` tab/播放键用 `0.9` → 改 `0.92`（`pressScale.control`）；`Mine` 菜单项用 `0.97` → 保持（`pressScale.surface`）。**统一为具名令牌，消除魔法数字。**

**④ 反馈完整性**：所有可点区域必须同时具备 ①`scale` 回弹 ②按压底色 `quaternarySystemFill`。现 `Mine` 用 `rgba(120,120,128,0.12)` 即 `tertiarySystemFill` 近似值 → 换令牌。

**⑤ 转场语义**：
- 列表 → 详情：`geometryTransition` 共享元素（**封面 `player_cover` 已实现，严禁改 ID**）。
- 入场错峰：`delay: index * Motion.stagger`，**上限 8 项**（超出不再递增，避免长列表末项延迟过久）。
- Sheet：`Motion.sheet 360ms` + 系统默认弹簧。

**⑥ `reduceMotion` 降级表（S-6 验证项，覆盖面只增不减）**

| 动效 | 正常 | `reduceMotion = true` |
|---|---|---|
| 封面旋转（`Layout` 40ms 定时器） | 1.6°/帧 | **停止**（现已实现 ✅） |
| 列表错峰入场 | `delay: index*60` | **delay = 0**，仅 120ms 淡入 |
| 空态呼吸动画 | 循环缩放 | **停止**（现已实现 ✅） |
| 按压回弹 | `spring` + `scale` | **保留但降级**：仅 `opacity 0.7`，无 `scale`（反馈是功能性的，不可去除） |
| 一镜到底转场 | `springHero` 共享元素 | **降级为 120ms 淡入淡出**（避免大位移） |
| Sheet 弹出 | 360ms 弹簧 | 200ms 线性 |
| `Splash` logo 缩放 | 700ms `EaseOut` 缩放+淡入 | **仅淡入 300ms**（现未受控 ⚠️ 需补） |
| 页面转场（`PlayerPage.entered`） | `springSoft` 缩放淡入 | 仅淡入 |

> **原则**：**装饰性动效可去除，功能性反馈必须保留**（用户需知道点击已生效）。

### 6.6 明暗模式适配（Dark Mode as First-Class）

**Apple 原则**：深色不是浅色反转，而是独立设计；深色下降低对比刺激、用层次代替阴影。

**① 机制（保持现状，不改）**
```
SettingsStore.getThemeMode()  →  AppStorage('themeMode')  →  ThemeManager.isDark()
                                          ↓
        @StorageProp('isDark')  →  普通方法 getThemeColors()  →  令牌
                                          ↓
                        ThemeManager.applyToWindow() 同步系统栏内容色
```
⚠️ **R-2 红线**：取色只能用普通方法，不能用 `get` 访问器。

**② 对比度实测与整治（我已按 WCAG 公式实算）**

| 令牌组合 | 浅色对比度 | 深色对比度 | 判定 |
|---|---|---|---|
| `label` on `systemBackground` | **17.0 : 1** | **21.0 : 1** | ✅ AAA |
| `secondaryLabel` on `systemBackground` | **3.44 : 1** | **6.36 : 1** | ⚠️ **浅色不达 AA 正文（4.5:1）** |
| `tertiaryLabel` on `systemBackground` | ≈ 1.8 : 1 | ≈ 2.5 : 1 | ❌ 仅装饰/占位，**禁止承载信息** |

**🔴 关键发现**：`secondaryLabel` 在**浅色模式下仅 3.44:1**，只满足大文本 3:1 门槛，**不满足正文 4.5:1**；深色模式反而达标（6.36:1）——**明暗不对称**。

**整治方案：修令牌，而非加新档**（采纳 system-architect §2.13，**取代我原提的 `secondaryLabelStrong` 新增档**）

我原方案是新增一个 `secondaryLabelStrong` 加强档。架构师指出该方案的问题：会形成「label / Secondary / SecondaryStrong / Tertiary / Quaternary」五档，`SecondaryStrong` 语义自相矛盾，开发者只能凭观感挑一个；且它是**逃生舱而非修复**——默认档仍不达标。**此判断正确，本文采纳架构师方案。**

同时架构师顺此线索查出一个**更严重的缺陷**：令牌表的 label 层级**单调性倒挂**（我实测复核确认）——

| 令牌 | 原值 | 浅色对比度 | 问题 |
|---|---|---|---|
| `labelSecondary` | `#8E8E93` | **3.26 : 1** | ← 二级 |
| `labelTertiary` | `#636366` | **5.99 : 1** | ← **三级比二级更醒目，层级倒挂** |

**修正后（值均已存在于现网 `DesignSystem` 的 `systemGray`/`systemGray2`，不引入新色）**：

| 令牌 | 浅色 | 浅色对比度 | 深色 | 深色对比度 |
|---|---|---|---|---|
| `labelSecondary` | `#6E6E73` | **5.07 : 1** ✅ 默认即达 AA | `#AEAEB2` 档 | 达标 |
| `labelTertiary` | `#8E8E93`（原 Secondary 下沉） | **3.26 : 1** | `#636366` | **3.51 : 1**（与浅色 3.26 对称） |

> **我已独立用 WCAG 公式复算全部四个值，与架构师数据完全一致**（`#6E6E73`→5.07、`#636366` on black→3.51、`#8E8E93`→3.26、`#636366` on white→5.99）。
> **落地成本**：因全站已读令牌，**只需改 `LumioColor` 一行** —— 这正是令牌层价值的证明。

**使用规则（硬性）**：
- `labelSecondary` 为**默认次要文字档**，任意字号均达 AA（5.07:1），承载副标题/歌手名/设置说明。
- `labelTertiary` / `labelQuaternary` → **只用于占位符、禁用态、装饰**，禁止承载用户需读取的信息。
- **不再设「加强档」**；若某处次要文字对比度不足，说明它选错了档，而非需要新档。

**🔴 F-14 覆盖裁定（重要，防止旧文档结论被误用）**

`docs/design_tokens.md` **F-14 的结论是反的，本文予以覆盖废止**。

F-14 原要求：把 `#636366` 统一替换为 `secondaryText`（即旧 `#8E8E93`）。我实测 `#636366` 全仓**仅 3 处**，且**全部是空态的 13fp 指导性文案**：

| 位置 | 文案 |
|---|---|
| `Favorites.ets:333` | 「在播放页面点击收藏按钮添加」 |
| `PlaylistDetail.ets:596` | 「点击「添加歌曲」从本地库挑选」 |
| `Playlists.ets:560` | 「点击右上角「+」创建第一个歌单」 |

这三条是**空屏上最重要的文字**（告诉用户如何脱离空态）。按 F-14 执行会把它们从 **5.99:1 降到 3.26:1**，**恰好降低了最需要被读到的文案的可读性**。

→ **裁定**：这 3 处映射到修正后的 `labelSecondary`（**5.07:1**，仍达 AA），**不得映射到 `labelTertiary`**。F-14 原条款作废。

**③ 深色专属规则**
1. **阴影 α → 0**（除浮动胶囊 `elevation.lg` 保留 0.45），改用 `separator` 0.5vp 描边表达边界 —— `Layout` 现已按 `isDark` 分支处理描边 ✅ 保持。
2. **纯黑背景 + 分层面**：`systemBackground #000` → 卡片 `secondarySystemGroupedBackground #1C1C1E`，靠明度差而非阴影分层。
3. **品牌色 `#FA2759` 深浅一致**（不随主题变化，保持品牌识别）—— 需验证其在 `#000` 上对比度：约 **4.9:1** ✅ 达标。
4. **系统色用深色变体**：`systemBlue #007AFF → #0A84FF` 等（`DARK_APPLE` 已正确定义 ✅）。

**④ 资源色深色补全（S-4）**
`resources/dark/element/color.json` 现**仅 1 项**（`start_window_background`），须补齐 `base` 的其余 **7 项**：
`select_swiper` · `slider_track` · `slider_select` · `play_text_color` · `singer_text` · `shadow_color` · `list_divider`
> 否则深色模式下这些资源色**静默回退浅色值**（如 `list_divider #E5E5EA` 在纯黑背景上会成为刺眼亮线）。

**⑤ 特殊上下文：播放页与歌词（全应用唯一对比度不由静态令牌保证之处）**

**架构师已定注入方案**（`UI重设计_设计令牌架构.md` §3.5），要点我已核验：
- 现网骨架**已经是对的**：`@Prop @Watch('onBgChanged') backgroundIsDark`（`LrcView.ets:87`）→ `applyColorScheme()`（`:913`）→ 4 个私有字符串字段 → `drawContent()` 只读缓存字段。
- 令牌化**只需替换 `applyColorScheme()` 的取值来源**，`drawContent()` 一行不动 → **每帧零解析开销**，`PanGesture` 跟手与重绘路径不受影响。
- 硬卡点（R-20）：`grep` 确认 `onMediaOf`/`semanticOf` **不得出现在 `drawContent`/`drawLine` 内**。
- 维度分离（R-21，架构师自查）：歌词/媒体覆盖层色的输入是**封面明暗**而非应用主题，已拆为独立 `LumioOnMedia` + `onMediaOf(backgroundIsDark)`，与 `semanticOf(isDark)` 严格分离。**否则深色主题用户播浅色封面会得到白字白底。**

**🔴 量化修正之一（v1.2）：架构师的蒙层反解按「不透明白字」计算，但非当前行其实是半透明**

实测 `LrcView.applyColorScheme()`（`:913–927`）的真实色值：

| 行类型 | 字号/字重 | 深色方案 | alpha | 浅色方案 | alpha |
|---|---|---|---|---|---|
| **当前行** | 22vp **bold** | `#FFFFFF` | **100%** ✅ 不透明 | `#000000` | **100%** |
| **非当前行** | 18vp **bold**（非 regular） | `#80ffffff` | **50.2%** ⚠️ | `#4d000000` | **30.2%** ⚠️ |
| 翻译-当前 | 14vp bold | `#d6ffffff` | 84% | `#99000000` | 60% |
| 翻译-非当前 | 14vp bold | `#80ffffff` | 50.2% | `#66000000` | 40% |

> ⚠️ 另一处更正：`fontWeight` 是**单一字段**（`:150`），全部行共用 `'bold'` —— **非当前行也是 bold，不是 regular**。

**🔴 量化修正之二（v1.3 新增）：`globalAlpha` 与 `fillStyle` 是「双乘」，v1.2 的 alpha 仍偏乐观**

`drawContent` 在 `fillStyle`（`#80ffffff` = 50.2%）之上**再乘一层 `globalAlpha`**，有效 alpha = 两者之积：

| 行类型 | 状态 | `globalAlpha` | × fill 50.2% → | **有效 alpha** | filter |
|---|---|---|---|---|---|
| 非当前-已播 | **浏览** | 0.72 | | **0.361** | 无 |
| 非当前-未播 | **浏览** | 0.55 | | **0.276** | 无 |
| 非当前-已播 | **播放** | 0.55 | | **0.276** | blur 3px |
| 非当前-未播 | **播放** | 0.38 | | **0.191** | blur 5px |

→ **有效 alpha 只有 0.191~0.361**（v1.3 曾记 1.42~1.89:1，该数值基于错误底色模型，**已作废**，正确值见下方「量化修正之三」）。核心机理与底色无关：**半透明文字永远向背景靠拢，对比度被结构性压缩。**

**✅ R-04b 裁决（team-lead，2026-09）：按「用户意图」分流，非当前行分两档**

我原来把「非当前行」当成一个固定状态去选 A/B/C，那是伪命题 —— 它有两种完全不同的意图：

| | **播放态**（自动滚动跟随） | **浏览态**（`PanGesture` 拖拽中 / 手动定位后 5s 内） |
|---|---|---|
| 用户在做什么 | **在听**，非当前行是氛围层 | **在读**，每一行都是正文 |
| 当前行 22vp bold | **≥ 4.5:1** | **≥ 4.5:1** |
| 非当前行 18vp bold | **≥ 3:1** | **≥ 4.5:1** |
| 翻译行 14vp（**小文本，无大文本豁免**） | **≥ 3:1** | **≥ 4.5:1** |
| blur | 保留（聚焦手段） | 去掉（现状已去掉） |

---

**🔴🔴 量化修正之三（v1.4 · 架构师 v1.6 更正）：歌词底色模型错了 —— 我 v1.3 据此反解的数值全部作废**

我和架构师此前都把歌词背景当成**原始封面亮度**，这是错的。`LyricsComponent` 位于 `PlayerInfoComponent` 的 `Stack()` 内（L165/214/237），底色是**三段叠加后的合成结果**：

1. 封面图 `opacity(0.5)` + 模糊
2. `buildGradientColors()` 先压暗（deep `.28` / base `.42` / lifted `.62`）再以 `opacity(0.65)` 叠渐变
3. 黑蒙层 `rgba(0,0,0,0.35)`，且 `lyricBgDark` **恒 `true`**（`L351` 硬写）→ **现网强制压暗**

→ 纯白封面经渐变后最亮处也只有 `#9E9E9E`，再叠渐变 + 蒙层，**实际底色落在 `#3B3B3B` ~ `#7D7D7D`**，根本不是近白背景。

**❌ 作废清单（v1.3 我写的，勿采用）**

| 作废项 | 原因 |
|---|---|
| 「纯白封面达 4.5:1 的最小蒙层 **0.535**」 | 底色不是纯白封面，是已压暗的合成色 |
| 「蒙层 clamp **[0.50, 0.65]**」/「背景压到 **≈105/255**」 | 在已压暗的合成底色上再压 0.50+，**会把画面压成一团黑** |
| 「对比度 **1.42~1.89 : 1**」 | 基于错误底色，正确值见下 |

**重算（当前行 / 不透明白字 · 架构师 v1.6）**

| 场景 | 合成底色 | 对比度 |
|---|---|---:|
| 纯白/黑底 lifted | `#606060` | **6.31 : 1** ✅ |
| 纯白/黑底 deep | `#3B3B3B` | **11.17 : 1** ✅ |
| **纯白 / 白底 lifted（最坏）** | `#7D7D7D` | **4.13 : 1** ⚠️ **唯一缺口** |
| 中灰 `#BCBCBC` | `#474747` | **9.35 : 1** ✅ |
| 暗封面 `#1C1C1E` | `#0B0B0B` | **19.74 : 1** ✅ |

→ **当前行基本达标**，唯一不达 4.5 的是「纯白封面 + 白基底 + lifted 位」的 **4.13:1**（可由极小蒙层补齐，见下）。

**仍然成立的两条（架构师确认保留）**

1. **R-22 双层 alpha 依然成立**。真实合成底色上实测：**播放态未播放 1.39~1.79 : 1、浏览态 1.59~2.37 : 1**。关键结论：**它在所有背景上都低** —— 暗封面背景下浏览态也只有 2.37:1。因为半透明文字永远向背景靠拢，对比度被结构性压缩，**与背景明暗无关**。
2. **`LrcView.ets:652` 注释「全部清晰」仍与实现背离**，实际为 **1.59~2.37 : 1**。

> **R-04b 裁决（按意图分两档）不受本次更正影响** —— 它是产品意图判断，与底色模型无关，继续有效。

---

**✅ 参数分阶段定稿（v1.6 · team-lead 裁决）**

⚠️ **两张表必须分开看**：下表描述的是 **M3 终态（含自适应蒙层）**；**本轮修线上缺陷不含蒙层**，参数不同。拿 M3 的参数去修 bug 会做出不达标的中间态。

| 阶段 | 蒙层 | 播放态 α | 最坏 `#7D7D7D` | 典型 `#606060` | deep `#3B3B3B` |
|---|---|---|---|---|---|
| **本轮缺陷修复（M3 之前 / 任务 #4）** | **无**（沿用现网固定 0.35） | **0.73** | **3.01 : 1** ✅ | 4.27 : 1 ✅ | 6.89 : 1 ✅ |
| **M3 起（含自适应蒙层）** | clamp `[0.0, 0.25]` 默认 0.10 | **0.60** | **3.20 : 1** ✅ | 3.43 : 1 ✅ | 5.20 : 1 ✅ |

**浏览态 α = 0.85（两阶段相同）**：本轮最坏 **3.47 : 1** ⚠️ ← **已裁定接受的缺口** / M3 最坏 **4.66 : 1** ✅。当前行 α = 1.00：本轮最坏 **4.13 : 1** ⚠️ / M3 最坏 **5.70 : 1** ✅。

**✅ 本轮缺口已裁定（team-lead）：选 B —— 不加蒙层，播放态 α 提到 0.73**

| 裁决要点 | 内容 |
|---|---|
| **否决 A（固定蒙层 0.16）的理由** | 固定蒙层**不区分封面亮度**：暗封面本就 19.7:1，再压 0.16 纯属牺牲氛围；只有纯白封面真正需要它。**为 1% 的极端封面惩罚 99% 的普通封面** = 「调参数」而非「修结构」。M3 的自适应蒙层按封面亮度精确施加才是正解。我们已在 clamp [0.50,0.65] 上栽过一次（会压成一团黑），不再栽第二次。 |
| **播放态取 0.73** | 3:1 **可达** → 提到 0.73 刚好达标（相对 0.65 只差 0.08，视觉代价可忽略），**值得改**。 |
| **浏览态维持 0.85，缺口登记** | 4.5:1 本轮**数学上不可达**（α=1.0 也只 4.13:1）。**既然提到 1.0 也够不到目标，就不为它牺牲不透明度差 —— 如果一个改动达不到目标，就别为它付代价。** 缺口在 M3 由自适应蒙层补齐。 |

**🔴 实现陷阱：0.73 的 8-bit 取整必须向上，不能四舍五入**

`0.73 × 255 = 186.15`，常规四舍五入取 **`0xBA`(186) → α=0.7294 → 实测 2.998:1 ❌ 差 0.002 不达标**。

| fill | α | 最坏底色对比度 |
|---|---|---|
| `#BAffffff`（四舍五入，❌ 勿用） | 0.7294 | **2.998 : 1** ❌ |
| **`#BBffffff`（向上取整，✅ 用这个）** | 0.7333 | **3.01 : 1** ✅ |

> **0.73 是数学临界值，余量 < 0.5%。** 任何向下取整、色值转换误差或后续微调都会跌破 3:1。**实现时直接写 `#BBffffff`，不要写 `0.73` 再转。**
> 翻译行跟随同档（0.73）；浏览态 `#D9ffffff`（0.85，0.85×255=216.75 → 217 无歧义）。

- **蒙层 `artworkScrim` clamp 改为 `[0.0, 0.25]`，默认 ≈0.10**（架构师 v1.6/v1.7）。反解目标为「让**浏览态 85% 白字**达 4.5」：`#3B3B3B` / `#606060` / 中灰 / 暗封面 → **0.00**（已足够暗）；最坏 `#7D7D7D` → 反解 **0.159**，工程取 **0.18**。
- ⚠️ **「上限 0.65」废止** —— 那是错误模型反解出来的，会把画面压成一团黑。
- ⚠️ **「必须改 `fillStyle`，不能只调 `globalAlpha`」已由架构师核验成立**：`globalAlpha` 上限为 1，而基底 fill 仅 0.502，浏览态要 0.85 则需 `globalAlpha = 1.69 > 1`，**不可能**。
- **两档只切 fill alpha 与 blur**：播放态 α 见上表（本轮 **0.73** / M3 **0.60**）、浏览态 **0.85**（去 blur）。

**🔴 blur 强度必须下调（team-lead 裁决）**

| | 现网 | **改后** | 占字号比 |
|---|---|---|---|
| 已播非当前 | `blur(3px)` | **`blur(1.5px)`** | 17% → **8%** |
| 未播非当前 | `blur(5px)` | **`blur(2px)`** | 28% → **11%** |

> **判据（team-lead）**：非当前行字号 18vp（我实测 `LrcView.ets:126` `mNormalTextSize=18`；team-lead 记 15vp → 33%/13%，**量级一致、结论不变**），现网 5px ≈ 字号的 **28%** —— 这不是柔化，是**抹除**。它与双层 alpha 并列，是现网 1.5:1 的**第二大成因**，**只修 alpha 修不干净**。
> **「是否模糊」不变，「模糊强度」必须降。** 架构师曾以「blur 是设计意图、不该动」异议，team-lead 以比例判据驳回。

**🔴 验收取样位（架构师 v1.7 新增硬要求，最易漏测）**

对比度**必须在渐变 `lifted` 位取样**（渐变 **0.45** 处，最亮位）。同一底色在渐变三个位置的落差（架构师实测）：

| 取样位 | 对比度 |
|---|---|
| deep（最暗） | 8.63 : 1 ✅ |
| base | 4.63 : 1 |
| **lifted（最亮）** | **3.47 : 1** ❌ |

→ **在深位取样会误判为「全部达标」**。测试一律按 **lifted** 取。

> **好消息：代码里已经有这个分档了。** `LrcView.ets:203` `isUserScrolling` + `:982–990` `scheduleAutoReturn()`（5s `setTimeout` 复位）+ `drawContent` 已按 `isUserScrolling` 分支（浏览态去 `blur`、抬 `globalAlpha`；播放态加 `blur`、压 `globalAlpha`）。**裁决不是新造机制，而是把现有的两档「定量化」——把浏览态从「稍微清楚一点」提到真正达 4.5:1。**

**实现要点（P2c 必读）**

1. **`applyColorScheme()` 要输出两套 fill 色**，不能只调 `globalAlpha`（理由见上，架构师 v1.7 已核验）。深色方案：浏览态 `#D9ffffff`（0.85）；播放态 **本轮 `#BBffffff`（0.73，⚠️ 勿用 `#BA`，见上取整陷阱）**、**M3 起改 `#99ffffff`（0.60）**；浅色方案对称提黑字不透明度。
2. **切档不能硬切**：`PanGesture.onActionStart` → `isBrowsing = true`；`onActionEnd` → **复用现有 `scheduleAutoReturn()`（5s）**复位。档位过渡用 **200ms 交叉淡入**（或 crisp 弹簧），**禁止硬切**；现有 5s 定时器正好是天然窗口。
3. **R-20 不变**：`onMediaOf` / `semanticOf` 仍**不得出现在 `drawContent` / `drawLine` 内**；两套 fill 色必须在 `applyColorScheme()` 里**预计算成字符串/数值字段**，`drawContent` 只读字段 —— 保持每帧零解析。
4. **翻译行 14vp 属明确小文本**，两档均无「大文本 3:1」豁免，与 S-3 一致。
5. **blur 强度必须同步下调**：已播非当前 `blur(3px)` → **`blur(1.5px)`**、未播非当前 `blur(5px)` → **`blur(2px)`**（判据见上）。**只改 alpha 不改 blur 修不干净** —— 它与双层 alpha 并列为现网低对比度的两大成因。浏览态仍**去 blur**（现状即如此）。

**验收口径（定稿）**：S-3 中「歌词 ≥4.5:1」**不可笼统写**，须拆为「**播放态：当前行 ≥4.5 / 非当前行 ≥3 / 翻译行 ≥3；浏览态：全部 ≥4.5**」，且**每张封面截两态**。否则 M3 会出现「公式通过但实际读不清」或「目标在 clamp 内不可达」。

---

## 7. 里程碑拆分

### 7.0 ⚠️ 与架构师 P0–P5 阶段的对齐（**必读，避免两套批次冲突**）

`docs/UI重设计_设计令牌架构.md` §4.2 定义了 **P0–P5 六个令牌层迁移阶段**。本章的 **M0–M5 是页面/功能维度的批次**。两者是**不同轴，不是竞品**：

| 轴 | 归谁权威 | 关注 |
|---|---|---|
| **P0–P5**（令牌层迁移） | **高见远的架构文档权威** | `tokens/` 建设、垫片、hex 清零、尺度动效统一、资源镜像 |
| **M0–M5**（页面批次） | **本文权威** | 哪个页面在哪一批改、每批验收什么、功能不回归 |

**映射关系（开发按此对照排期）**：

| 本文 | 架构 P 阶段 | 说明 |
|---|---|---|
| **M0** 治理裁决与规范合一 | — | AD-0 已裁决 ✅；剩余为文档合一 |
| **M1** 令牌层地基 | **P0 + P1** | P0 新增 `tokens/` 6 文件；P1 `ColorTokens` 改派生垫片（= 我的适配层策略） |
| **M2** 公共组件 + 主 Tab | **P2（B 类·按页）+ P3（按页）** | ⚠️ **批次单位已改为「页」，见下方修正说明** |
| **M3** 播放体验 | **P2c（歌词专项 0.5d）+ P2（播放组件按页）** | **P2c 置于 M3 开头**：`onMedia*` 维度迁出 + `ArtworkTint` 自适应蒙层 + `LrcView` 注入 |
| **M4** 二级页 + 设置 + Sheet | **P2（批 3）** | 剩余业务文件 hex 清零 |
| **M5** 卡片 + 无障碍 + 收口 | **P4 + P5** | P4 尺度/动效全量统一 + `DesignSystem` 退化为 re-export；P5 资源镜像 + 卡片主题链路 |

**🔴 修正说明：批次单位从「hex 类别」改为「页」（架构师 v1.2 自查结论，本文采纳）**

架构师原 P3 写「一次性切换 `surfaceRaised` 的 light 值」，但自查发现**改令牌值是全局生效的** —— 一旦切换，尚未迁移的页面会立刻变成「灰底 + 浅灰卡片」，与其自定的「整页提交」纪律自相矛盾。

**修正后的机制**：**令牌值全程不变，逐页改变「引用哪个令牌」** ——

```
页面底：background      →  surfaceGrouped
卡片底：surfaceRaised   →  surfaceGroupedContent
（两者配对切换 = 该页「页面与卡片交换配色」，原子生效）
```

未迁移页面**完全不受影响**。风险从「全仓高风险」降为「单 PR 可控」。

**这对批次划分的直接影响**：既然 P3 是逐页的，且每页**必须先清掉该页的中性/表面 hex** 才能换指向，则「P2 的 B 类批」与「P3」**在同一页上有严格先后关系**。因此：

> **批次单位 = 页，而非 hex 类别。**
> 每页一个 PR，PR 内顺序：① 清该页 B 类（中性/表面/文本）hex → ② 换该页表面令牌指向。二者**同 PR 原子提交**。

这同时也更贴合架构 §4.6 的「整页提交」纪律。**我已据此重写 M2（§7.4）。**

**其余三处差异（已确认无冲突，排期需知）**：

1. **P4「尺度与动效全量统一」落在 M5** → M2–M4 期间圆角/间距/字号**允许逐页局部替换**，全量收敛与 `DesignSystem.ets` 退化为 re-export 垫片在 M5 完成。→ **S-5 最终验收点在 M5，不在 M2。**
2. **S-4（`dark/color.json` 全量镜像）在 P5 = M5**，M1 不做。→ 已从 M1 验收标准移出。
3. **硬编码口径**：架构 ≈160 处（含 `rgba`），我 ≈124 处（仅 hex）。→ **以架构 160 为准**；本文 §1.3 的 124 为其 hex-only 子集。S-1 验收统一用架构 §4.2 P2 的 DoD 正则。

### 7.1 排期总览

| 里程碑 | 主题 | 文件数 | 可独立构建 | 用户可见变化 |
|---|---|---|---|---|
| **M0** | 治理裁决与规范合一 | 0 代码 / 3 文档 | — | 无 |
| **M1** | 令牌层地基（适配层策略） | 5 | ✅ | 无（视觉等价） |
| **M2** | 公共组件抽取 + 主 Tab | 7 | ✅ | 中 |
| **M3** | 播放体验 | 8 | ✅ | 高 |
| **M4** | 二级页 + 设置 + Sheet | 11 | ✅ | 中 |
| **M5** | 桌面卡片 + 无障碍 + 收口 | 4 | ✅ | 低 |

> **排期原则**：M1 先建地基（不改观感，风险最低），M2 抽公共组件（后续里程碑都受益），M3 做品牌核心，M4 扫尾，M5 收口验收。**每个里程碑结束都必须能独立 `assembleHap` 并通过冒烟。**

### 7.2 M0 · 治理裁决与规范合一（前置，阻塞全部）

| 项目 | 内容 |
|---|---|
| **做什么** | ① ~~裁决 §3 冲突~~ **已完成：AD-0 由 team-lead 批准** ✅ ② 蓝绘心据 AD-0 产出 `docs/设计系统_Apple.md`（视觉规范侧），与架构的 `UI重设计_设计令牌架构.md`（工程侧）**分工不重叠**，旧两份 `UI设计系统.md`/`design_tokens.md` 标注废弃 ③ ~~确认适配层方案~~ **已完成：架构 AD-3 方案 B 与我方策略收敛** ✅ |
| **涉及文件** | `docs/设计系统_Apple.md`（新）、`docs/UI设计系统.md`（标废弃）、`docs/design_tokens.md`（标废弃）。**零 `.ets` 改动** |
| **验收标准** | ① ✅ §3 冲突已书面裁决（AD-0）② 视觉规范含 §6 全部令牌表且与架构 `tokens/` 命名**一致无二套** ③ AD-0 三级色彩优先序条款已写入 ④ ✅ 适配层方案已签署（AD-3 方案 B） |
| **风险** | 🟢 已大幅降低。**剩余风险**：蓝绘心的视觉规范若与架构 `tokens/` 命名不一致会产生第三套命名。**缓解**：蓝绘心出稿前先读架构 §2.4–2.10 令牌骨架，**直接复用其字段名** |

### 7.3 M1 · 令牌层地基（**最关键，决定后续成败**）

| 项目 | 内容 |
|---|---|
| **做什么** | ① 建 `tokens/` 三层（架构 P0）② **修 label 层级倒挂**：`labelSecondary → #6E6E73`（5.07:1）、原 `#8E8E93` 下沉 `labelTertiary`（§6.6）③ 补 `accentSoft`、`Spacing`、`Typography`、`Elevation`、`pressScale`、`springHero`、`radius.xs/xl/floatingBar` ④ **`ThemeManager.ColorTokens` 改为派生垫片**（架构 P1 = 我的适配层，见下）⑤ `float.json` 增 `radius_*`/`space_*`/`font_*`（只增不删）⑥ `ColorConversion.ets` 2 处裸 hex<br>⚠️ **`dark/color.json` 补 7 项与 `base` 对齐移至 M5**（架构 P5），M1 不做 |
| **涉及文件** | 新增 `tokens/` 三层文件；改 `common/utils/DesignSystem.ets`（L3）、`utils/ThemeManager.ets`（L3）、`resources/base/element/float.json`、`common/utils/ColorConversion.ets` |
| **验收标准** | ① `assembleHap` 0 error ② **全应用视觉与 M1 前逐屏等价**，唯二**有意**差异需逐屏确认：`secondaryBg #FAFAFA→#F2F2F7`（肉眼难辨）与**次要文字对比度提升** 3.26→5.07（**变清晰，属修复**）③ 深浅色切换无回退 ④ label 层级单调性成立（二级 > 三级 > 四级）⑤ 令牌自检脚本跑通<br>⚠️ **S-4（dark 8 项）验收点在 M5，不在 M1** |
| **风险** | 🔴 **最高**。318 处 `getThemeColors()` 调用点，若直接重写全部调用 = 巨型 PR + 高回归风险 |

**M1 关键策略 —— 适配层（Adapter）而非大爆炸重写**：

```
第一步：AppleTokens 成为唯一色值定义处（27 字段 + 新增 2 字段）
第二步：ColorTokens 的 7 个字段改为「从 AppleTokens 派生」的别名映射：
        bg            ← systemBackground
        secondaryBg   ← systemGroupedBackground
        cardBg        ← secondarySystemGroupedBackground
        primaryText   ← label
        secondaryText ← labelSecondary(#6E6E73) ← 顺带修复浅色对比度 3.26→5.07！
        separator     ← separator
        accent        ← BRAND_ACCENT
第三步：318 处调用点「零改动」即自动继承 Apple 语义色
第四步：后续 M2–M4 逐页把 getThemeColors() 换成更精细的 AppleTokens 直取
```

> **这样 M1 只改 2 个 `.ets` 文件就完成令牌归一，318 处调用点无需一次性重写，风险从「巨型重构」降为「两文件替换」。**
> 副作用（正向）：`secondaryText` 自动升级为达标对比度，**一次性修好全应用浅色次要文字可读性**。
> ⚠️ 注意：别名映射会带来**极小的视觉位移**（如 `secondaryBg` 由 `#FAFAFA` → `#F2F2F7`），需在验收时逐屏确认「等价或更优」，不可有明显突变。

### 7.3.1 M1 落地细则（文件级 · 我实测校正）

**🔴 先更正两处既有表述（此前是推演，现在是实测）**

| 既有表述 | 实测结果 |
|---|---|
| 「只改 `ThemeManager` 让 **22 个业务文件**零改动」 | 实际是 **16 个文件 / 337 处调用点**（`SettingsSubPageBodies` 53、`LocalLibrary` 34、`PlaylistDetail` 36 …） |
| 「值已存在于 `DesignSystem`，**只需改 `LumioColor` 一行**」 | ❌ **`LumioColor` 与 `#6E6E73` 全仓 grep 零命中** —— 二者**都不存在**。`LumioColor` 是架构师 P0 待建的 `tokens/` 层（当前目录不存在），`#6E6E73` 是**需要新增**的色值。M1 = **新建 tokens/ + 改造 ThemeManager，不是「改一行」** |

**① 取色真源（实测链路）**

```
entry/src/main/ets/utils/ThemeManager.ets
  :45  const LIGHT_TOKENS: ColorTokens  ← 模块级常量（7 字段）
  :55  const DARK_TOKENS:  ColorTokens
  :82  static getColors()          → 返回上面两个常量之一
  :88  static get lightColors()    → 同上   ← ⚠️ 业务实际走这条
  :93  static get darkColors()     → 同上
  :101 static apple(): AppleTokens → 已存在，Apple 令牌已接通 ✅
```

**⚠️ 关键**：业务侧**不是**直接调 `ThemeManager.getColors()`，而是每个组件各自定义 `getThemeColors()` 包一层，内部走 **`ThemeManager.darkColors` / `lightColors`（静态 `get` 访问器）** —— 实测 **23 处定义 / 16 个文件**，形如：

```ts
private getThemeColors(): ColorTokens {
  return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;  // LocalLibrary:55
}
```

**② 因此 M1 可收敛到一个点（这是好消息）**

> **只把 `LIGHT_TOKENS` / `DARK_TOKENS` 两个常量改为从 `appleColors(false/true)` 派生。**
> 三条取色路径（`getColors()` / `lightColors` / `darkColors`）**自动全部跟随**，无遗漏风险 —— **16 个业务文件、337 处调用点零改动**。

```
LIGHT_TOKENS = { bg: appleColors(false).systemBackground, ... }   // 只改这一个对象
DARK_TOKENS  = { bg: appleColors(true).systemBackground,  ... }
        ↓ 自动
   getColors() / lightColors / darkColors
        ↓ 自动
   23 处 getThemeColors() → 337 处调用点（零改动）
```

**③ M1 的 PR 切分（建议 2 个 PR，可再拆 commit）**

| PR | 文件 | 内容 | 验收 |
|---|---|---|---|
| **M1-PR-1**（P0 建层） | **新建** `common/tokens/` 6 文件（架构师 P0 已定义） | Apple 语义层 + **新增 `labelSecondary = #6E6E73`（5.07:1）**、`labelTertiary = #8E8E93`；`LumioSemantic` / `LumioOnMedia`（R-21 分离） | 新文件编译通过；`#6E6E73` 已入库；`onMedia*` 与 `semantic*` 无交叉引用 |
| **M1-PR-2**（P1 派生） | **只改** `utils/ThemeManager.ets` | `LIGHT_TOKENS` / `DARK_TOKENS` 改派生；字段映射见下 | 318+ 处调用点零改动；深/浅双主题全量截图比对（R-07） |

**④ 字段映射（⚠️ 有两个坑，见 ⑤⑥）**

| `ColorTokens` 字段 | 浅色（现 → 建议） | 深色（现 → 建议） | 映射来源 |
|---|---|---|---|
| `bg` | `#FFFFFF` → `#FFFFFF` | `#000000` → `#000000` | `systemBackground` |
| `secondaryBg` | `#FAFAFA` → **见 ⑤** | `#1C1C1E` → **见 ⑤** | `systemGroupedBackground` |
| `cardBg` | `#F2F2F7` → **见 ⑤** | `#1C1C1E` → `#1C1C1E` | `secondarySystemGroupedBackground` |
| `primaryText` | `#1C1C1E` → `#1C1C1E` | `#FFFFFF` → `#FFFFFF` | `label` |
| `secondaryText` | `#8E8E93` → **`#6E6E73`** ✅ | `#98989F` → `#AEAEB2` 档 | **不能直接用 Apple 原生值，见 ⑥** |
| `separator` | `#E5E5EA` → `#E5E5EA` | `#2C2C2E` → `#2C2C2E` | `separator` |
| `accent` | `#FA2759` → `#FA2759` | `#FA2759` → `#FA2759` | `BRAND_ACCENT`（品牌色不变） |

**⑤ 🔴 坑一：表面层级配对冲突（M1 开工前须蓝绘心裁定，我不单方面定）**

iOS 原生 grouped 层级的正确配对是「**页面底灰 → 卡片白**」：

| | `systemGroupedBackground` | `secondarySystemGroupedBackground` |
|---|---|---|
| 浅色 | `#F2F2F7`（灰） | `#FFFFFF`（白） |
| 深色 | `#000000`（黑） | `#1C1C1E`（深灰） |

但现网是「**页面底白 → 卡片灰**」（`bg #FFFFFF` / `cardBg #F2F2F7`）。若按原生映射 `bg←systemBackground(#FFFFFF)` + `cardBg←secondarySystemGroupedBackground(#FFFFFF)` → **浅色下卡片与页面底同为纯白，卡片直接消失**。

| 方案 | 做法 | 代价 |
|---|---|---|
| **甲（Apple 原生）** | `bg ← systemGroupedBackground`（浅色页面底变 `#F2F2F7`）、`cardBg ← secondarySystemGroupedBackground`（`#FFFFFF`） | **视觉位移最大**（页面底由纯白变浅灰），与 R-07「不可有明显突变」冲突，但最 Apple |
| **乙（推荐）** | 保持现网三级骨架：`bg #FFFFFF` / `secondaryBg #FAFAFA` / `cardBg #F2F2F7`（深色 `#000000` / `#1C1C1E` / `#1C1C1E`），**仅做命名归一 + `secondaryText` 对比度修复** | 视觉**几乎无位移**，符合 R-07；Apple 原生反差留到 M2 逐页试点时由蓝绘心定 |

> **我推荐乙**：R-07 已承诺「等价或更优，不可有明显突变」。M1 先做到「令牌归一 + 修好次要文字可读性」，**层级反差是设计决策不是技术决策**，不该在 M1 悄悄改掉。

**⑥ 🔴 坑二：Apple 原生 `secondaryLabel` 不达 AA（不可直接派生）**

`LIGHT_APPLE.secondaryLabel = 'rgba(60, 60, 67, 0.60)'` 合成后 ≈ `#8A8A8E`，对白底实测 **3.44:1** —— **不满足 AA 4.5:1**（与 §6.6② 表一致）。

→ **M1 派生时 `secondaryText` 不能直接取 `AppleTokens.secondaryLabel`，必须落到 `#6E6E73`（5.07:1）**。这是「Apple 原味 vs WCAG AA」的取舍，**本文已在 v1.1 裁定取 AA（5.07:1）**，M1 按此执行。

**⑦ 联带影响（别漏）**

- `widget/pages/WidgetCard.ets:42` 注释自述是 `ThemeManager.lightColors/darkColors` 的**单点镜像** → M1 改常量后卡片镜像会漂移，**须同批更新或明确留到 M5**。
- `static get lightColors/darkColors` 是 `get` 访问器，与 §5.4 **R-2 红线**表述存在张力（现网可用，但 M1 改动时**不得新增 `get` 取色**，新增一律用普通方法）。

---

### 7.4 M2 · 公共组件抽取 + 主 Tab

| 项目 | 内容 |
|---|---|
| **做什么** | **按页拆 PR，每 PR 内「清 B 类 hex + 换表面令牌指向」原子提交**（见 §7.0 修正）：<br>**PR-0（组件基建）** 抽 `components/SongRow.ets`（`menuActions` 数组注入，支持空数组）+ `CountBadge.ets`<br>**PR-1** `LocalLibrary` L3：接入 `SongRow`（基准页）+ 大标题/搜索/排序节奏 + 空态/加载态<br>**PR-2** `Mine` L3：**统计 3 色→1 色 + 菜单 4 色图标→中性单色（装饰色归零）** + InsetGrouped 分组 + `height(60)`→`minHeight`<br>**PR-3** `Layout` L2：删 `const ACCENT`、`pressScale.control 0.92`、3 处裸 hex<br>**PR-4** `Splash` L2：2 处裸 hex + 接 `reduceMotion`<br>⚠️ 其余 4 处 `SongRow` 接入（Favorites/PlayHistory/PlaylistDetail/FolderBrowse）**在 M4 按页进行**，M2 只做基准页 |
| **涉及文件** | 新增 `SongRow.ets` / `CountBadge.ets`；改 `LocalLibrary.ets`（L3）、`Mine.ets`（L3）、`Layout.ets`（L2）、`Splash.ets`（L2）<br>❌ **不再单独抽 `SongContextMenu.ets`** —— 架构师指出 `bindContextMenu` 需 `@Builder`，菜单 `@Builder` 必须**定义在 `SongRow` 内部**才能既满足签名又访问 `this.config.menuActions`；从父级用 `@BuilderParam` 传入无法按行取到 song/index |
| **验收标准** | ① `LocalLibrary` 接入 `SongRow` 后行为与 M2 前完全一致（播放/收藏/菜单/长按）② **`Mine` 装饰性配色归零**（菜单 4 色图标→中性单色；统计 3 色→1 色），符合 AD-0 三级优先序 ③ 列表项超大字体下不截断（`minHeight` 生效）④ 单 Sheet 调度机制未被破坏（设置/关于均能正常开关）⑤ 按压反馈统一为两级令牌 ⑥ **每个 PR 内页面底与卡片底令牌指向配对切换，无「白卡片贴白底」**；未迁移页面视觉不受影响 ⑦ `SongRow` 的 `menuActions: []` 空数组形态经 `FolderBrowse` 场景验证可用 ⑧ 构建通过 + 双 Tab 冒烟 |
| **风险** | 🟠 中高。`SongRow` 需覆盖 5 个页面差异化菜单项，**签名设计不当会导致某页功能退化**（如 `PlaylistDetail` 独有「从歌单移除」、`FolderBrowse` 本就无菜单）。**缓解**：① 架构师已给出 `SongMenuAction { id, label, destructive, enabled }` 数组注入设计 ② `index` 一律透传 ③ **M2 只迁基准页，其余 4 页在 M4 逐页迁逐页冒烟** ④ ⚠️ **菜单变更必须整体替换数组引用，禁止原地 `push`/`splice`** —— 否则 ArkUI 感知不到变更 |

### 7.4.1 M2 PR 切分（文件级 · 含裸 hex 实测清单）

**🔴 PR-0 前置（采纳蓝绘心建议，硬前置，未完成不许动 `SongRow`）**

> **先对 5 处现有列表项各自截图存档**，有基线才能判断迁移是否等价。

| # | 位置 | 存档内容（每处 4 张） |
|---|---|---|
| 1 | `pages/LocalLibrary.ets`（基准页） | ① 正常字号 ② **超大字体**（验 `minHeight` 不截断）③ 长按菜单展开态 ④ 深/浅各一 |
| 2 | `pages/Favorites.ets` | 同上 |
| 3 | `pages/PlayHistory.ets` | 同上 |
| 4 | `pages/PlaylistDetail.ets`（含独有「从歌单移除」） | 同上 |
| 5 | `pages/FolderBrowse.ets` **`songRow()` @153 降级变体（本就无菜单）** | 同上 + **确认无菜单** |

**每个 PR 内三步原子提交**（页内顺序纪律）：① 清该页 B 类 hex → ② 换该页表面令牌指向 → ③（列表页）接入 `SongRow`。**三步同 PR，跨页无顺序约束。**

---

**PR-0 · 组件基建（无页面改动，纯新增）**

| 文件 | 动作 |
|---|---|
| **新增** `components/SongRow.ets` | `menuActions: SongMenuAction[]` 数组注入（支持空数组）；菜单 `@Builder` **必须定义在 `SongRow` 内部**（`@BuilderParam` 传不进 `this.config.menuActions`）；`index` 一律透传 |
| **新增** `components/CountBadge.ets` | 计数徽章 |

**验收**：新文件编译通过；`menuActions: []` 空数组形态可用；**未接入任何页面，线上视觉零变化**。

---

**PR-1 · `LocalLibrary` L3（基准页，最先做）** 　`pages/LocalLibrary.ets`

| 裸 hex（实测 4 处，全是品牌色 `#FA2759`） | 处理 |
|---|---|
| `:35` `const ACCENT: string = '#FA2759'` | 收归 `BRAND_ACCENT` 令牌 |
| `:392` `.fontColor(... ? '#FA2759' : ...)` | 同上 |
| `:523` `.fillColor('#FA2759')` | 同上 |
| `:527` `.fontColor('#FA2759')` | 同上 |

**另做**：大标题 / 搜索 / 排序节奏；空态 / 加载态；**接入 `SongRow`（基准页）**。
**验收**：接入后播放/收藏/菜单/长按行为与迁移前完全一致；与 PR-0 基线截图逐项比对。

---

**PR-2 · `Mine` L3（装饰色归零，最高杠杆）** 　`pages/Mine.ets`

实测 **9 处裸 hex / 5 个色**：

| 分组 | 位置与色值 | 处理 |
|---|---|---|
| **统计 3 色 → 1 色** | `:159 #FA2759` · `:171 #34C759` · `:183 #FF9500` | 统一为 `BRAND_ACCENT` |
| **菜单图标 4 色 → 中性单色** | `:203 #FA2759` · `:215 #5856D6` · `:227 #FF9500` · `:239 #007AFF` | 统一为中性（`labelSecondary` 档） |
| 额外 1 处 | `:276 #5856D6` | 同上，一并归零 |

**另做**：InsetGrouped 分组；`height(60)` → **`minHeight`**（超大字体不截断）。
**验收**：**装饰性配色归零**（符合 AD-0 三级优先序：内容着色 > 语义着色 > 中性）；超大字体下不截断。

---

**PR-3 · `Layout` L2** 　`pages/Layout.ets`

| 项 | 位置 | 处理 |
|---|---|---|
| `const ACCENT` | `:32` | **删除**，改用 `BRAND_ACCENT` 令牌 |
| 裸 hex ×2 | `:278` `.fillColor('#FFFFFF')` · `:312` `.fillColor('#FFFFFF')` | → `label` 令牌（当前是硬写白，深色下需跟随） |
| `pressScale.control` | — | `0.92` 改为两级按压令牌 |

**验收**：主 Tab 切换、迷你播放器、系统栏同步正常；深浅双主题无硬写白残留。

---

**PR-4 · `Splash` L2** 　`pages/Splash.ets`

| 裸 hex（实测 2 处，均为三目硬写） | 处理 |
|---|---|
| `:61` `.fontColor(this.isDark ? '#FFFFFF' : '#1C1C1E')` | → `label` 令牌 |
| `:71` `.backgroundColor(this.isDark ? '#000000' : '#FFFFFF')` | → `systemBackground` 令牌 |

**另做**：接入 `reduceMotion`。
**验收**：首屏闪现无白闪/黑闪；`reduceMotion` 开启时动效降级。

---

**⚠️ 表面层级配对规则（每页换指向时必守）**

- **页面底与卡片底必须配对切换**，禁止只换一个（否则出现「白卡片贴白底」或卡片消失）。
- 具体取值**取决于 §7.3.1 ⑤ 的裁定结果**（甲=Apple 原生灰底白卡 / 乙=保持现网白底灰卡）。**PR-1 开工前必须拿到蓝绘心裁定**，否则四个 PR 的令牌指向会不一致。
- ⚠️ `secondaryBg`（分组头/带状底）与 `cardBg` **不得取同值**，否则分组头与卡片糊成一片 —— 这是最容易漏的配对错误。

**M2 整体风险**：🟠 中高。`SongRow` 需覆盖 5 个页面差异化菜单项。
**缓解**：① 架构师已给 `SongMenuAction { id, label, destructive, enabled }` 数组注入设计 ② `index` 一律透传 ③ **M2 只迁基准页，其余 4 页在 M4 逐页迁逐页冒烟** ④ **菜单变更必须整体替换数组引用，禁止原地 `push`/`splice`**（ArkUI 感知不到） ⑤ **PR-0 截图基线必须先有**。

---

### 7.5 M3 · 播放体验（品牌核心）

| 项目 | 内容 |
|---|---|
| **做什么** | **⓿ 首先做 P2c 歌词专项（架构师新增，0.5d，置于 M3 开头）**：① `onMedia*` 从 `LumioSemantic` **迁出**为独立 `LumioOnMedia` + `onMediaOf(backgroundIsDark)`（修 R-21 维度错误）② `ArtworkTint` 增 `onArtwork` + `artworkScrim`，**按「合成底色」反解蒙层 alpha**（⚠️ 不是原始封面亮度，见 §6.6⑤「量化修正之三」），目标「**浏览态 85% 白字达 4.5:1**」，clamp **[0.0, 0.25]，默认 ≈0.10** —— ⚠️ **原 0.65 上限作废**（会把已压暗的画面压成一团黑）③ `LrcView.applyColorScheme()` 换取值来源（13 处裸 hex），`drawContent()` 不动 ④ **按 R-04b 双档裁决输出两套 fill 色**：播放态非当前/翻译有效 alpha **0.60（M3 值；本轮缺陷修复为 0.73 → `#BBffffff`，见 §6.6⑤ 阶段表）**、浏览态 **0.85**（去 blur）—— ⚠️ **必须改 `fillStyle`，只调 `globalAlpha` 不可达（需 1.69 > 1）**；⚠️ **α=0.60 与自适应蒙层必须同批落地**（无蒙层时 0.60 仅 2.54:1）⑤ 复用现有 `isUserScrolling` + `scheduleAutoReturn()`(5s) 做切档，**200ms 交叉淡入，禁硬切** ⑥ **blur 强度同步下调**：已播 `blur(3px)`→**`blur(1.5px)`**、未播 `blur(5px)`→**`blur(2px)`**（现网 5px ≈ 18vp 字号的 28%，属抹除而非柔化）<br>随后：⑤ `PlayerInfoComponent` L3（封面主导层次、`space.hero`）⑥ `ControlAreaComponent` L2（按钮阶梯 56/40、Slider 令牌化）⑦ `MusicInfoComponent` L2（字体阶梯；**API 26 `ContainerReader`/`StyledString` 逻辑不动**）⑧ `CoverImageView` L2（圆角+阴影令牌）⑨ `LyricsComponent` L2 ⑩ `QualityBadge` / `TopAreaComponent` ⑪ `PlayerPage` L1 + `springHero` 令牌化 |
| **涉及文件** | `components/{PlayerInfoComponent,ControlAreaComponent,MusicInfoComponent,CoverImageView,LyricsComponent,QualityBadge,TopAreaComponent}.ets`、`lyric/LrcView.ets`、`pages/PlayerPage.ets` |
| **验收标准** | ① **一镜到底进出场仍完全对称、无闪跳**（共享 ID `player_cover` 未变）② 歌词 `PanGesture` 跟手手感无退化、点击跳转不误触 ③ **歌词对比度按「意图双档」验收（不可笼统写 4.5:1）**：**播放态** 当前行 ≥4.5:1 / 非当前行 ≥3:1 / 翻译行 ≥3:1；**浏览态**（拖拽中或手动定位后 5s 内）**当前行、非当前行、翻译行全部 ≥4.5:1** —— 按 §6.6⑤ 裁决执行 ④ **4 张基准封面（纯白 / 中灰 / 纯黑 / 高饱和）× 各 2 态（播放 + 浏览）= 8 张截图**逐张确认歌词可读（架构师 §3.5.4 最关键项）；**两档切换无硬切**（200ms 交叉淡入，录屏验证）⑤ **`grep` 确认 `onMediaOf`/`semanticOf` 未出现在 `drawContent`/`drawLine` 内**（R-20 硬卡点）⑥ **⚠️ 取样位必须是渐变 `lifted` 位（0.45 处，最亮位）** —— deep 位 8.63:1 会误判为全部达标，lifted 位才 3.47:1（架构师 v1.7 硬要求）⑦ **真机主观可读性确认（team-lead 批准）** —— 见下方独立条款 ⑧ **深色主题 + 浅色封面组合专项验证**（R-21 回归场景）⑨ API 24 设备上 `ContainerReader` 降级路径正常 ⑩ 倍速/播放模式/收藏/静音全部可用 ⑪ 构建通过 |

**⑦ 真机主观可读性确认（独立条款 · 数值验收的必要补充）**

> **为什么需要**：WCAG 公式**不建模模糊**，数值达标 ≠ 看得清。**数值验收（lifted 位取样）是必要条件，不是充分条件。**

| 项 | 要求 |
|---|---|
| **判定人** | **蓝绘心**（定稿 + 判定） |
| **执行人** | **非作者本人**（避免"我知道答案"的确认偏误） |
| **封面** | **4 张基准封面（与 ④ 同一组，保证两轮取样可比）：纯白 / 中灰 / 纯黑 / 高饱和** |
| **状态** | 每张 × 2 态：**播放态 / 浏览态** |
| **环境** | **正常室内光** |
| **方法** | 随机指定**一句非当前行歌词**，要求执行人**朗读** |
| **判定标准（写死）** | **能正确读出即通过**；读错或需凑近/遮挡反光才读出 = 不通过 |

**⚠️ 与 §6.6⑤ 一致**：本轮（无蒙层）与 M3（含自适应蒙层）参数不同 —— 本轮播放态 α=**0.73**（`#BBffffff`）、M3 α=**0.60**（`#99ffffff`），**不得交叉套用**；本轮浏览态 4.5:1 为**已裁定接受的缺口**（M3 补齐）

**M3 `LrcView` blur 验收**：已播非当前 `blur(1.5px)`、未播非当前 `blur(2px)`（现网 3px/5px **必须降**，见 §6.6⑤）；浏览态无 blur。
| **风险** | 🔴 高。① `LrcView` 是 Canvas 手绘 + 自定义手势 —— 但架构师已确认**骨架正确、`drawContent()` 零改动**，风险已从"改绘制入参"降为"仅换 `applyColorScheme()` 取值来源" ② **半透明文字的对比度不可能靠蒙层单独解决**（见 §6.6⑤）—— **必须改 `fillStyle` 本身**（`globalAlpha` 需 1.69 > 1）；且⚠️ **蒙层不得按「原始封面亮度」反解**（R-23），真实底色是三段叠加的合成色，按错模型反解会把画面压成一团黑 ③ 一镜到底对 `geometryTransition` 两端尺寸/圆角敏感。**缓解**：`LrcView` 单独成 PR 并录屏对比手感；对比度按分档口径验收；封面圆角两端（`Layout` 迷你 14 / 播放页）**同步**调整并录屏验证转场 |

### 7.6 M4 · 二级页 + 设置 + Sheet（量最大，风险最低）

| 项目 | 内容 |
|---|---|
| **做什么** | **同样按页拆 PR（清 B 类 hex + 换表面指向 + 接入 `SongRow`）**：<br>① **`SettingsSubPageBodies.ets` L3（最高杠杆：1 文件覆盖 4 页）**：`SubPageHeader` 统一二级页头部、`WrappedBody` 数据可视化重做、53 处取色 + 6 处裸 hex（**按 4 个 Body 拆 4 个 commit**）② `PlaylistDetail` L3（大封面头部 + 播放全部）+ **接入 `SongRow`（含独有「从歌单移除」+ `index` 消费）** ③ `Playlists` L3（14 处裸 hex、歌单卡片规范）④ `SettingsCategory` L3（**分类图标装饰色归零**、13 处裸 hex）⑤ `Settings` L2（InsetGrouped）⑥ `About` L2 ⑦ **`Favorites` / `PlayHistory` / `FolderBrowse` 接入 `SongRow`**（其中 `FolderBrowse` 用 `menuActions: []` **保持无菜单，不得新增功能**）⑧ 三个 Sheet L2 ⑨ `StyleConstants.ets` 收敛清理 |
| **涉及文件** | `components/SettingsSubPageBodies.ets`（L3）、`pages/{PlaylistDetail,Playlists,SettingsCategory}.ets`（L3）、`pages/{Settings,About,Favorites,PlayHistory,FolderBrowse}.ets`（L2）、`components/{SongDetailSheet,AddToPlaylistSheet,OnboardingSheet}.ets`（L2）、`common/constants/StyleConstants.ets` |
| **验收标准** | ① 4 个薄壳页（ManageSongs/DuplicateSongs/PrivacyPolicy/Wrapped）经 Body 改动后全部正常渲染 ② **`About` 的 `pendingOnboarding` 衔接仍无空白页**（关于→引导链路录屏验证）③ Sheet `detents` 档位与 dragBar/close 行为不变 ④ `SettingsCategory` 装饰色归零（符合 AD-0 三级优先序）⑤ 设置 8 项全部可读写且持久化正常 ⑥ **5 处列表项全部收敛为 `SongRow`，且每页功能集与迁移前逐项一致**（尤其 `PlaylistDetail` 的「从歌单移除」、`FolderBrowse` 的「无菜单」）⑦ **空态 3 处指导文案对比度 ≥ 4.5:1**（F-14 覆盖裁定生效，见 §6.6）⑧ 构建通过 |
| **风险** | 🟠 中。`SettingsSubPageBodies` 单文件 ~900 行改动面大，**一处编译错误阻塞 4 个页面**；Sheet 内二级导航（`@State selectedCategory`）转场易被样式改动干扰。**缓解**：`SettingsSubPageBodies` 按 4 个 Body **分 4 个 commit**，每个 commit 后单独冒烟对应页面 |

### 7.7 M5 · 桌面卡片 + 无障碍 + 全局收口

| 项目 | 内容 |
|---|---|
| **做什么** | ① `WidgetCard` L2（**18 处裸 hex → 卡片内 `cardColors(isDark)` 同值取色**）② `FormAbility` L1（`createFormBindingData` 推 `isDark`，闭合卡片主题链路）③ 无障碍补齐（`accessibilityText` / 触达区 ≥ 44×44vp）④ **`reduceMotion` 降级表全量落地**（§6.5 八项）⑤ S-1/S-5 全局扫描清零 ⑥ 多端断点走查（sm/md/lg：折叠屏/平板/2-in-1）⑦ 更新 `CHANGELOG.md` / `README.md` |
| **涉及文件** | `widget/pages/WidgetCard.ets`、`ets/formability/FormAbility.ets`、全局扫描收尾、`CHANGELOG.md`、`README.md` |
| **验收标准** | ① **S-1 零裸 hex 扫描通过**（业务文件命中 = 0）② S-5 尺度扫描通过 ③ 卡片深浅色跟随系统正确切换 ④ `reduceMotion` 开启后 8 项降级全部生效 ⑤ 三档断点无布局破裂 ⑥ **S-3 对比度全量复核通过** ⑦ §5.1 功能清单 21 项逐条回归通过 ⑧ API 24 + API 26 双设备冒烟 |
| **风险** | 🟡 中低。卡片跨进程主题链路（`FormAbility` → `@LocalStorageProp`）**历史未闭合（G-4）**，可能遇到刷新时机问题（卡片不实时跟随主题）。**缓解**：卡片主题若无法实时跟随，**降级为「下次刷新周期生效」并在文档标注已知限制**，不阻塞里程碑 |

### 7.8 里程碑依赖关系

```
M0（裁决）──▶ M1（令牌地基）──┬──▶ M2（公共组件 + 主 Tab）──┬──▶ M4（二级页/设置/Sheet）──▶ M5（卡片/无障碍/收口）
                              │                              │
                              └──▶ M3（播放体验）─────────────┘

强依赖：M0 → M1 → {M2, M3}；M4 依赖 M2 的 SongRow（PR-0 组件基建）
弱依赖：M3 与 M2 可并行（文件无交集，仅共用 M1 令牌）
```

> **并行建议**：M2（`pages/` 主 Tab + 列表组件）与 M3（`components/` 播放 + `lyric/`）**文件集无交集**，可由两人并行。M4 必须等 M2 的 `SongRow`（PR-0）落地。
>
> **页内顺序纪律（架构师 v1.2 修正）**：每页一个 PR，PR 内 ①清该页 B 类 hex → ②换该页表面令牌指向 → ③（列表页）接入 `SongRow`，**三步同 PR 原子提交**。跨页之间无顺序约束，可任意排列或并行。

---

## 8. 风险与依赖清单

### 8.1 风险登记（按严重度排序）

| ID | 风险 | 概率 | 影响 | 等级 | 缓解措施 | 责任 |
|---|---|---|---|---|---|---|
| **R-01** | ~~§3 治理冲突未裁决~~ → **已由 AD-0 关闭** ✅。**残余风险**：蓝绘心视觉规范与架构 `tokens/` 命名不一致 → 产生第三套命名 | 中 | 高 | 🟠 | 蓝绘心出稿前复用架构 §2.4–2.10 的字段名；M0 验收加「命名一致性」检查；旧两份文档立即标废弃 | 蓝绘心 |
| **R-01b** | **两套批次计划（M0–M5 vs P0–P5）被开发误读为两条并行任务线** | 中高 | 中 | 🟠 | §7.0 映射表为唯一对照口径；每批开工前明确「本批 = M? + P?」；S-5 验收点明确在 M5/P4 | team-lead |
| **R-02** | **R-2 红线踩坑**：重构取色时误用 `get` 访问器 → 运行时 undefined 崩溃 | 中高 | 致命 | 🔴 | 所有取色一律 `private getXxx(): Tokens {}` 普通方法；**加入 code review 检查清单第 1 条**；M1 适配层策略天然减少改动面 | 全员 |
| **R-03** | **一镜到底转场破裂**：`geometryTransition` 两端封面圆角/尺寸不同步 → 跳变 | 中 | 高 | 🔴 | 圆角改动必须 `Layout` 迷你封面与播放页封面**同 PR 同步改**；每次改动录屏对比；`player_cover` ID 禁改 | M3 负责人 |
| **R-04** | ~~`LrcView` 令牌注入破坏跟手/性能~~ → **已降级** 🟡：架构师确认现网骨架正确，`drawContent()` 零改动、每帧不解析令牌 | 低 | 中 | 🟡 | 仍单独成 PR + 录屏对比；**R-20 硬卡点**：grep 确认 `onMediaOf`/`semanticOf` 不入 `drawContent`/`drawLine` | M3 负责人 |
| **R-04b** | **半透明歌词文字对比度（v1.4 已裁决为「意图感知双档」）**：`globalAlpha` × `fillStyle` 双乘后有效 alpha 仅 **0.191~0.361**；在真实合成底色（`#3B3B3B`~`#7D7D7D`）上实测 **播放态 1.39~1.79:1、浏览态 1.59~2.37:1**，**在所有背景上都低**（暗封面下浏览态也只有 2.37:1，因半透明文字永远向背景靠拢） | **高** | 高 | 🟡 | **✅ 已裁决（team-lead）**：按意图分两档 —— 播放态 当前 4.5 / 非当前 3 / 翻译 3；**浏览态全部 4.5**（该裁决与底色模型无关，继续有效）。<br>**解法（v1.6 参数分阶段定稿 · 架构师 v1.7 已核验）**：⚠️ **两阶段参数不同** —— **本轮缺陷修复（无蒙层）播放态 α=0.73**（实测最坏 **3.01:1**，⚠️ **fill 必须写 `#BBffffff`，四舍五入的 `#BA` 只有 2.998:1 ❌**）、**M3 起（含自适应蒙层）α=0.60**（实测 **3.20:1**）；浏览态两阶段均 **0.85**（本轮最坏 3.47:1，**已裁定接受的缺口**）。蒙层 clamp **[0.0, 0.25]，默认 ≈0.10**（⚠️ 原 0.65 上限作废），反解目标「让**浏览态 85% 白字**达 4.5」→ 多数底色 **0.00**、最坏 `#7D7D7D` **0.18**。<br>**✅ 本轮缺口已裁定（选 B）**：不加蒙层，播放态 α 提到 **0.73**（最坏 **3.01:1** ✅，⚠️ fill 用 `#BBffffff`）；浏览态 4.5:1 本轮数学不可达 → **维持 0.85、缺口登记**，M3 由自适应蒙层补齐。判据：**「如果一个改动达不到目标，就别为它付代价」**；否决固定蒙层的理由是**不为 1% 极端封面惩罚 99% 普通封面**。<br>**实现硬约束**：**必须改 `fillStyle` 本身**（`globalAlpha` 需 1.69 > 1）；切档 **200ms 交叉淡入**禁硬切；复用 `isUserScrolling` + 5s `scheduleAutoReturn()`；**blur 强度必须降**（3px→1.5px、5px→2px，现网 5px ≈ 字号 28% 属抹除）。<br>⚠️ **验收取样位必须是渐变 `lifted`（0.45 处）** | 蓝绘心（观感确认 + ⑦ 主观判定）+ 架构师（参数核验 ✅ v1.7 已完成） |
| **R-04c** | **深色主题 + 浅色封面 → 白字白底**（架构师自查 R-21：`onMedia*` 误挂应用主题维度） | 中 | 致命 | 🟠 | 架构师已拆独立 `LumioOnMedia` + `onMediaOf(backgroundIsDark)`，P2c 迁出；**验收须专项测「深色主题 + 纯白封面」组合** | M3 负责人 |
| **R-23** | **量化结论基于不完整的渲染链路**：歌词底色被误当成「原始封面亮度」，实际是「封面 `opacity(0.5)`+模糊 → `buildGradientColors()` 压暗 + `opacity(0.65)` → 黑蒙层 0.35（`lyricBgDark` 恒 true）」的**三段合成结果**（`#3B3B3B`~`#7D7D7D`）→ 导致蒙层参数反解失真（需 0.65 实为需 ≤0.25） | 中 | **高（会导致画面被压成一团黑）** | 🟠 | 架构师已记入其文档。**规则**：凡涉及**叠加层/合成底色**的对比度量化，**必须先读完整条渲染链再算**，不得直接取原始封面亮度；产出数值须经**第二人独立复算**方可写入验收口径。P2c 落地前用真机截图反验合成底色 | 架构师 + 计谋远 |
| **R-05** | **`SongRow` 抽取导致某页功能退化**（PlaylistDetail 的「从歌单移除」丢失；或**误给 FolderBrowse 新增菜单**造成功能蔓延） | 中高 | 高 | 🟠 | 架构师已定 `SongMenuAction` 数组注入设计；`index` 一律透传；**M2 只迁基准页，M4 逐页迁逐页冒烟**；`FolderBrowse` 明确 `menuActions: []`；**菜单数组必须整体替换引用，禁止原地 push/splice** | M2/M4 负责人 |
| **R-06** | **单 Sheet 调度机制被破坏** → 设置/关于串台、打不开、或关闭时空白页 | 中 | 高 | 🟠 | §5.2 三条机制列为契约；`Mine.sheetKind`/`sheetVisible`/`onDisappear`/`pendingOnboarding` 改动需 team-lead 批准；关于→引导链路每次回归录屏 | M2/M4 负责人 |
| **R-07** | **M1 派生垫片产生非预期视觉突变** | 中 | 低 | 🟡 | 已**降级**：架构师修正机制后「令牌值全程不变，逐页换引用」，未迁移页面不受影响。M1 仅两处有意差异（`secondaryBg #FAFAFA→#F2F2F7` 肉眼难辨、次要文字对比度 3.26→5.07 属修复）。仍需改动前对 18 个界面**截图基线**逐屏比对 | M1 负责人 |
| **R-07b** | **表面层级切换出现「白卡片贴白底」** | 中 | 中 | 🟠 | 已由架构师机制修正化解：页面底与卡片底令牌指向**必须同 PR 配对切换**，原子生效；单页 PR 可独立回滚 | M2/M4 负责人 |
| **R-08** | **`SettingsSubPageBodies` 单文件 900 行改动，一处编译错误阻塞 4 页** | 中 | 中 | 🟠 | 按 4 个 Body 拆 4 个 commit，逐个冒烟；`SubPageHeader` 改动单独一个 commit | M4 负责人 |
| **R-09** | **API 24 兼容回退**：误将 API 26 专属 API 写成静态 import | 中 | 高 | 🟠 | R-6 双闸门（动态 import + `ApiCompat.isAtLeast(26)`）；**每里程碑必须 API 24 真机/模拟器冒烟**，不能只测 26 | 全员 |
| **R-10** | **卡片主题链路（G-4）历史未闭合**，卡片不实时跟随主题 | 中高 | 低 | 🟡 | M5 尝试闭合；若刷新时机受系统限制，**降级为「下次刷新周期生效」并文档标注已知限制**，不阻塞验收 | M5 负责人 |
| **R-11** | **超大字体 / 无障碍**：`minHeight` 改造不彻底，某些列表仍固定高度导致文字截断 | 中 | 中 | 🟡 | S-5 扫描 `height(` 白名单；M5 用系统最大字号逐页走查 | M5 负责人 |
| **R-12** | **多端断点回归**：折叠屏/平板 lg 断点下新布局破裂 | 中 | 中 | 🟡 | 现有 `currentBreakpoint` 机制不动；M5 三档断点走查；L3 页面改动时同步看 md/lg | M5 负责人 |
| **R-13** | **范围蔓延**：重设计过程中顺手改功能/加功能 | 中高 | 中 | 🟡 | §5 契约条款；PR 模板加「是否触及 §5？」勾选项；触及即打回 | team-lead |
| **R-14** | **品牌色 `#FA2759` 在深色纯黑上对比度** 4.9:1，若用于小字号需复核 | 低 | 低 | 🟢 | 已实算达标（≥4.5:1）；仅需避免用于 < 12fp 文字 | 蓝绘心 |

### 8.2 依赖清单

**① 决策依赖（阻塞型）**

| 依赖 | 需要谁 | 阻塞什么 | 时限 |
|---|---|---|---|
| §3 治理冲突裁决（方案 A / B） | team-lead → 用户确认 | **M0 及全部后续** | 立即 |
| `radius.floatingBar 30` 保留 vs 改 pill | 蓝绘心 | M2 的 `Layout` | M2 前 |
| `Wrapped` 年度回顾视觉方向（数据可视化重做幅度） | 蓝绘心 + 用户 | M4 | M4 前 |

**② 人员/角色依赖**

| 角色 | 交付物 | 被谁依赖 |
|---|---|---|
| **蓝绘心（UI/UX）** | `docs/设计系统_Apple.md`（M0）；14 个界面的视觉稿/标注 | 全部里程碑 |
| **高见远（架构）** | M1 适配层技术方案签署；`SongRow` 接口设计评审 | M1、M2 |
| **开发实施** | 按里程碑逐批落地 + 每批构建冒烟 | — |
| **team-lead** | §3 裁决、范围守门（R-13） | 全部 |

**③ 技术依赖**

| 依赖 | 说明 | 风险 |
|---|---|---|
| `compatibleSdkVersion 6.1.1(24)` | API 24 为运行时下限，不可提升（否则丢老设备） | 已实测确认 |
| `targetSdkVersion 26.0.0` | API 26 专属能力可用但须双闸门 | R-09 |
| `@kit.UIDesignKit` 的 `HdsNavigation` | 根导航容器，本次不动 | 低 |
| `@ohos.arkui.uiMaterial` | API 26 沉浸材质，动态 import；材质须挂真实容器（R-7） | R-09 |
| C++ NAPI（`AudioMeta` / BiSheng 编译） | 本次完全不动 | 无 |
| 双设备（API 24 + API 26） | 每里程碑冒烟必需 | 若无 API 24 设备 → 需模拟器 |

**④ 文档依赖（需同步更新，避免再次出现 §3 式冲突）**

| 文档 | 动作 |
|---|---|
| `docs/UI设计系统.md` | M0 标注「已废弃，见 `设计系统_Apple.md`」 |
| `docs/design_tokens.md` | M0 标注「已废弃」；§3.3 红线语义迁移至新规范 |
| `docs/设计系统_Apple.md` | M0 新建（蓝绘心），**唯一权威设计规范** |
| `docs/review_design.md` | M5 复核 Finding 关闭情况（F-01…F-18） |
| `CHANGELOG.md` / `README.md` | M5 更新 |

### 8.3 验收总闸（M5 结束时逐条签署）

| # | 闸门 | 判定 |
|---|---|---|
| 1 | S-1 零裸 hex（业务文件命中 = 0，基线 124） | ☐ |
| 2 | S-2 单一颜色真源（用色文件 100% 走令牌） | ☐ |
| 3 | S-3 对比度达标（主 ≥4.5:1；`labelSecondary` 修正为 5.07:1 默认达标；**label 层级单调性成立**；空态 3 处文案 ≥4.5:1） | ☐ |
| 3c | **歌词分档对比度（R-04b 双档裁决）**：**播放态** 当前行 ≥4.5:1 / 非当前行 ≥3:1 / 翻译行 ≥3:1；**浏览态**（拖拽中或手动定位后 5s 内）**当前行、非当前行、翻译行全部 ≥4.5:1**。<br>**3 张极端封面（纯白 / 纯黑 / 高饱和）各截 2 态（播放 + 浏览）= 6 张**，逐张确认；**⚠️ 取样位必须是渐变 `lifted` 位（0.45 处，最亮位）**，deep 位会误判为全部达标；深色主题 + 浅色封面组合无白字白底；**两档切换无硬切（200ms 交叉淡入，录屏验证）**；**blur 已降至 1.5px / 2px**（现网 3px/5px 属抹除）；**⚠️ 本轮缺陷修复与 M3 参数不同**（本轮无蒙层 → 播放态 α=0.65；M3 含自适应蒙层 → α=0.60），**不得交叉套用** | ☐ |
| 3d | **歌词真机主观可读性确认**（见 M3 验收⑦）：**非作者本人**在**正常室内光**下，朗读**随机指定的一句非当前行歌词**；3 张极端封面（纯白 / 中灰 / 纯暗）× 2 态（播放 + 浏览）；**能正确读出即通过**。由**蓝绘心**判定 | ☐ |
| 3b | 5 处列表项全部收敛为 `SongRow`，各页功能集零退化（含 `FolderBrowse` 保持无菜单） | ☐ |
| 4 | S-4 `dark/color.json` 补齐 8 项 | ☐ |
| 5 | S-5 圆角/间距/字号阶梯外命中 = 0 | ☐ |
| 6 | S-6 `reduceMotion` 八项降级生效 | ☐ |
| 7 | S-7 API 24 + API 26 双设备构建与冒烟通过 | ☐ |
| 8 | S-8 §5.1 功能 21 项零回归 | ☐ |
| 9 | §5.2 路由名 14 条 / §5.3 键位 26 个 未变更 | ☐ |
| 10 | §5.4 红线 R-1…R-10 全部未违反 | ☐ |

---

## 9. 附录：给下游的关键提示

### 9.1 给蓝绘心（UI/UX 设计师）

- **需要视觉稿的界面共 14 个**（非 34 个文件）：音乐库、我的、播放页、歌单列表、歌单详情、收藏、播放历史、文件夹浏览、设置、设置分类、关于、二级页头部+3 个 Body（管理歌曲/重复检测/年度回顾/隐私）、3 个 Sheet、启动页、桌面卡片。
- **最高杠杆点**：`SubPageHeader`（1 个头部覆盖 4 页）与 `SongRow`（1 个列表项覆盖 **5** 页）——**请优先出这两个的规范稿**。
- **`SongRow` 需出两个形态**：① 完整态（含长按菜单 + 按压反馈 + 音质角标）② **精简态**（`FolderBrowse` 用，无菜单）。不要假定每行都有菜单。
- **最需要你判断的**：`Mine` 统计栏与 `SettingsCategory` 分类图标的「一类一色 → 收敛」具体方案（§6.1 用色密度约束）。
- **对比度红线**：`labelSecondary` 已修正为 `#6E6E73`（**5.07:1，默认即达 AA**），可放心用于任意字号的次要文字。`labelTertiary`（3.26:1）/ `labelQuaternary` **仅限占位符、禁用态、装饰**，禁止承载需读取的信息。**不设「加强档」** —— 对比度不足说明选错了档。
- **空态文案属高优先级信息**：3 处空态指导文案（收藏/歌单/歌单详情）必须 ≥ 4.5:1，见 §6.6 的 F-14 覆盖裁定。
- **🔴 需你与架构师共同裁决一项（M3 开工前，见 §6.6⑤）**：歌词**非当前行**当前是半透明（深色方案 50.2% 白 / 浅色方案 30.2% 黑），实测对比度低至 **1.96:1**，且**蒙层加到上限也只有 3.09:1**。三个选项已列出并附反解数值 —— 核心取舍是：**要不要为可读性牺牲「当前行 vs 非当前行」的明暗层次**。我推荐选项 A（非当前行定 3:1，蒙层下限提到 0.50，alpha 不变），因为 18vp **bold** 已接近 WCAG 大文本阈值，且压暗非当前行是 Apple Music/Spotify 同样采用的**有意聚焦机制**。**翻译行 14vp 需单独定档**（建议 alpha 提到 ≈65%）。

### 9.2 给高见远（系统架构师）

**已确认对齐 ✅**：
- 你的 **AD-0** 裁决已被本文全面采纳（§3.3 / §6.1 已改写为三级色彩优先序）。
- 你的 **AD-3 方案 B（派生垫片）** 与我的 M1 适配层策略**独立收敛为同一手段** —— 两边都得出「改 `ThemeManager` 一个文件，让 20+ 业务文件零改动继承新令牌」。这一交叉验证大幅提升了 M1 的可信度。
- 你的 **P0–P5** 与我的 **M0–M5** 已在 §7.0 建立映射表，请复核该映射是否符合你的预期。

**v1.2 复核已全部采纳（2026-09 第二轮）**：
1. **列表项复制 = 5 处**（你补的 `FolderBrowse.ets:153` 我已独立核验，确认是**降级变体**：无菜单、无按压反馈、固定 `height(64)`、圆角阶梯外）→ 已建 §4.6.1 完整清单（含行号），并明确「接入时保持其无菜单形态，不得顺势加功能」。
2. **`SongRow` 菜单 `@Builder` 定义在组件内部** —— 你指出的 `bindContextMenu` 签名与 `menuActions` 访问的矛盾解法我已采纳；**据此取消了我原计划的 `SongContextMenu.ets` 独立组件**（从父级 `@BuilderParam` 传入拿不到按行 song/index）。`destructive` 标记 → danger 语义、`index` 一律透传、**数组整体替换禁止原地 push/splice** 均已写入 M2 风险缓解。
3. **对比度改为修令牌，不加 Strong 档** —— 你的判断更对，我已撤回 `secondaryLabelStrong`。你查出的 **label 层级倒挂**（Secondary 3.26 < Tertiary 5.99）我用 WCAG 公式独立复算了全部四个值（`#6E6E73`→5.07 / `#636366` on black→3.51 / `#8E8E93`→3.26 / `#636366` on white→5.99），**与你完全一致**。
4. **F-14 已在我文档覆盖废止**（§6.6 末）：我实测 `#636366` 全仓仅 3 处，**全部是空态 13fp 指导文案**（Favorites:333 / PlaylistDetail:596 / Playlists:560），按 F-14 执行会把空屏上最该被读到的文字从 5.99 降到 3.26。已裁定映射到 `labelSecondary`(5.07)，并列为 M4 验收第⑦条。
5. **P3 机制修正已采纳，并重构了 M2** —— 你自查出的「改令牌值全局生效 vs 整页提交纪律」矛盾很关键。我已按「令牌值不变、逐页换引用、页面底与卡片底同 PR 配对切换」重写 §7.0 与 §7.4：**批次单位从「hex 类别」改为「页」**，M2 拆成 PR-0（组件基建）+ PR-1…4（逐页），其余 4 处 `SongRow` 接入下移到 M4 逐页进行。R-07 已据此从 🟠 降为 🟡，新增 R-07b 专门盯「白卡片贴白底」。

**口径差异**：硬编码你 ≈160 处（含 `rgba`）/ 我 ≈124 处（仅 hex）→ **S-1 以你的口径为准**，已在 §1.3 与 §7.0 标注。

**v1.3 歌词方案已并入（第三轮）**：
- `LrcView` 注入方案我核验通过：`@Prop @Watch backgroundIsDark`(:87) → `applyColorScheme()`(:913) → 私有字段 → `drawContent()` 只读缓存，链路确实已就位，**`drawContent()` 零改动**成立。R-04 已由 🔴 降 🟡。R-20 硬卡点已写入 M3 验收第⑤条。
- **R-21 维度错误你抓得很关键** —— `onMedia*` 的输入是封面明暗而非应用主题，混用会导致「深色主题 + 浅色封面 = 白字白底」。已记为我的 R-04c，并把「深色主题+纯白封面」组合列为 M3 专项回归。
- P2c 已吸收进 M3 开头，M↔P 映射表同步更新。

**🔴 但你的蒙层反解有一处量化错误，会导致验收口径不可达（我的 R-04b）**

> ⚠️ **历史留档（v1.2）——本段数值已全部作废。** 你我都把歌词底色当成**原始封面亮度**，实际是三段叠加的**合成底色**（`#3B3B3B`~`#7D7D7D`），见 §6.6⑤「量化修正之三」。下方 4.28/3.35/2.27/1.96/3.09 与反解出的 0.535 均**不再采用**；以 v1.4 的 clamp **[0.0, 0.25]** 与两档 alpha **0.65/0.85** 为准。**保留的原因**是记录「半透明文字不能靠蒙层单独解决」这一结论的推导过程 —— 该**结论仍然成立**。

你按**不透明白字**算蒙层。我先复现了你的两个数（中灰+0.35 → 4.28:1、纯白+0.45 → 3.35:1，与你的 4.29/3.36 一致 ✓），但实测 `applyColorScheme()` 的真实色值是**半透明**：

| 行 | 字号/字重 | 深色方案 | alpha |
|---|---|---|---|
| 当前行 | 22vp bold | `#FFFFFF` | **100%** ✅ 你的算法适用 |
| 非当前行 | 18vp **bold** | `#80ffffff` | **50.2%** ⚠️ |
| 翻译行 | 14vp bold | `#80ffffff`/`#d6ffffff` | 50.2% / 84% |

（另：`fontWeight` 是单一字段 `:150`，**非当前行也是 bold，不是 regular**）

按真实 alpha 重算非当前行：

| 场景 | 你的口径 | **实际** |
|---|---|---|
| 中灰 `#BCBCBC` + 0.35 | 4.28:1 | **2.27:1** |
| 纯白 + 0.45 | 3.35:1 | **1.96:1** |
| 纯白 + **0.65（clamp 上限）** | — | **3.09:1 — 仍不足 4.5** |
| 浅色方案 30% 黑 on 亮底 | — | **≈2.0:1** |

反解：
- **当前行**（不透明）达 4.5:1 → 纯白封面需蒙层 **0.535**，**在你的 [0.35,0.65] clamp 内 ✅ 你的方案有效**
- **非当前行**达 4.5:1 → 需 alpha 从 50.2% **提到 ≈71.3%**
- 非当前行达 3.0:1 → 蒙层 ≥0.55 时**现有 50% alpha 即可**

**所以「蒙层 alpha 按非当前行 4.5:1 来定」这条在 clamp 内不可达** —— 半透明文字的对比度由 alpha 主导，不是蒙层能单独解决的。

建议：① **clamp 下限 0.35 → 0.50** ② 验收口径改**分档**（当前行 4.5 / 非当前行 3 / 翻译 3）③ 非当前行档位需蓝绘心确认（取舍是"可读性 vs 聚焦层次"），我推荐保 alpha、提蒙层下限。§6.6⑤ 已列三选项与全部反解数值，可直接引用。

---

*本规划文档由计谋远（鸿蒙软件项目经理）产出，作为 Lumio Music Apple 风格 UI 重设计的 Phase 0 范围契约。*
*所有现状数据均经仓库实测，未作推测。§3 治理冲突需 team-lead 裁决后方可开工 M1。*



