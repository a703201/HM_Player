# Lumio Music · 半模态面板（bindSheet）合规审查报告

> 审查范围：11 处 `bindSheet` 站点 + 3 个专用 sheet 组件（SongDetailSheet / AddToPlaylistSheet / OnboardingSheet）+ Mine 的 Settings/About 内容
> 审查方式：只读，未改动任何文件
> 规范真源：`docs/设计系统_Apple.md` §2.5.5 / §1.5.15 / §3.2.3 / §1.4-B / §1.5.11
> 审查日期：2026-09-12

## 关键令牌事实（已核实源码）
- `cardBg` = `surfaceGroupedContent` = `#FFFFFF` / `#1C1C1E`
- `surfaceOverlay` = `#FFFFFF` / `#1C1C1E` → **与 `cardBg` 值相同**（仅命名不同）
- `bg` = `surfaceGrouped` = `#F2F2F7` / `#000000` → **与 `surfaceOverlay` 值不同**（浅色差一档灰）
- 圆角令牌：md=12 / lg=16 / xl=24 / pill=999
- 间距：`SPACE_SM.compact`=8、`SPACE_SM.cozy`=12

---

## 一、不符合项清单

### 🔴 系统级 P0 · 背景材质（`systemMaterial` 缺失，最普遍）

`grep` 全量确认：`systemMaterial` 仅出现在 `SongDetailSheet.ets` 与 `Layout.ets`（miniBar 导航条，与 sheet 无关）。
**除 SongDetailSheet 外，所有 sheet 在 API 26 都是 flat `backgroundColor`，无系统毛玻璃材质。**

| Sheet | 位置（bindSheet → 内容根） | API 26 真实背景 | 规范 §2.5.5 | 严重度 |
|---|---|---|---|---|
| 播放队列 musicList | ControlAreaComponent.ets:136 → L502 | flat `cardBg` | 应 `systemMaterial` | P0 |
| 倍速 speed | :189 → L390 | flat `cardBg` | 应 `systemMaterial` | P0 |
| 睡眠 sleep | :204 → L451 | flat `cardBg` | 应 `systemMaterial` | P0 |
| AddToPlaylistSheet | AddToPlaylistSheet.ets:226 | flat `cardBg` | 应 `systemMaterial` | P0 |
| OnboardingSheet | OnboardingSheet.ets:152（Layout:424 未设 bg） | flat `bg`(surfaceGrouped) | 应 `systemMaterial` | P0 |
| Mine·Settings | Mine.ets:252 → Settings.ets:215/265 | flat `bg`/`cardBg` | 应 `systemMaterial` | P0 |
| Mine·About | Mine.ets:252 → About.ets | flat | 应 `systemMaterial` | P0 |
| 四列表页 add 路径 | Favorites:232 / LocalLibrary:615 / PlayHistory:224 / PlaylistDetail:488 → AddToPlaylistSheet | flat `cardBg` | 应 `systemMaterial` | P0 |
| 四列表页 picker 路径 | PlaylistDetail.ets:521 → songPickerBuilder(:323) | flat `bg` | 应 `systemMaterial` | P0 |
| ✅ SongDetailSheet | SongDetailSheet.ets:122 | `systemMaterial` | — | 仅此合规 |

> API 24 降级路径（flat 背景）在数值上可接受（`cardBg`≡`surfaceOverlay`），但 API 26 材质化是规范硬性要求，当前 8+ 个 sheet 全部缺失 → 视觉呈纯色块而非苹果风毛玻璃。

### 维度 1 · 尺寸（detents）
代码 detents 均落在冻结集合（`[MEDIUM]` / `[LARGE,MEDIUM]` / `[MEDIUM,LARGE]` / `['90%']`），无新增 → **代码层无 P0/P1**。唯一问题见文末「文档内部冲突」。

### 维度 2 · 位置（preferType）
musicList 用 `CENTER`（刻意设计，队列居中弹层），其余 `BOTTOM`/默认 → **合规**。

### 维度 3 · 圆角
| 文件:行 | 当前 | 规范 | 差异 | 严重度 |
|---|---|---|---|---|
| AddToPlaylistSheet.ets:150（内嵌 Dialog 容器） | `borderRadius(16)`=r.lg | Dialog 应 `r.xl`(24) §2.5.5/§1.5.15 | 16≠24 | P1 |
| AddToPlaylistSheet.ets:128（Dialog 次按钮「取消」） | `borderRadius(24)` | 次按钮应 `r.md`(12) §1.5.15 | 轻微 | P2 |
| OnboardingSheet.ets:143（主按钮） | `borderRadius(24)` | `r.pill` | — | ✅ 合规 |
| 各 sheet 顶部圆角 | 系统接管 | 系统接管 | — | ✅ 合规 |

### 维度 4 · 背景遮罩（mask）
全部站点均未设置 `mask` / 未关闭遮罩 → **沿用系统默认遮罩，合规**。无项。

### 维度 5 · 关闭交互（dragBar / showClose）
| 文件:行 | 当前 | 规范（#3「保留=true，除非刻意设计」） | 严重度 |
|---|---|---|---|
| ControlAreaComponent.ets:138-139（musicList） | `dragBar:false, showClose:false` | 偏离「保留」默认；但为 CENTER 居中弹层，likely 刻意 | P2 · 需确认 |
| 其余 11 个站点 | 均 `true` | — | ✅ 合规 |

### 维度 6 · 动效过渡
全部 `bindSheet` 均未自定义转场 → 系统接管 detents 定位、拖拽 1:1 跟手、释放 `SpringKind.Bouncy`、无淡出 → 符合 §3.2.3 ✅。
- 观察项（P2）：四个列表页 `bindSheet` 未挂 `onDisappear` 复位 `sheetKind`（Mine.ets:257 有；§3.2.3 不变量要求「onDisappear 才复位」），需确认关闭动画期间渲染是否受影响。

### 维度 7 · 内容布局
| 文件:行 | 当前 | 规范 | 差异 | 严重度 |
|---|---|---|---|---|
| SongDetailSheet.ets:118（InfoRow 行 padding） | `SPACE_SM.cozy`(12) | `sp.compact`(8) §1.5.15 | 12≠8 | P1 |
| SongDetailSheet.ets:143-168（信息区） | 裸 Row 堆叠，无 hairline、未套 Inset Grouped 整组容器 | §1.4-B/§1.5.15：InfoRow 行间 0.5vp hairline + 整组圆角容器 | 缺 hairline+组容器 | P1 |
| AddToPlaylistSheet.ets:169-202（歌单列表） | 裸 `List`，无 `.divider`、无 Inset Grouped 容器 | §1.4-B：整组圆角容器 + 0.5vp hairline | 缺 hairline+组容器 | P1 |
| AddToPlaylistSheet.ets:192（列表行高） | `.height(56)` | `minHeight(56)` | 固定高，长名不可撑开 | P2 |
| OnboardingSheet.ets:49-55（feature 图标底色） | 四色 accent/warning/purple/success，图标白 | 统一 `fillAccentSubtle` 底 + `accent` 图标（彩色归零 §1.5.15） | **彩色未归零** | P0 |
| ControlAreaComponent.ets:364-391（倍速 Sheet） | 裸 Row 堆叠，无 Inset Grouped 容器 + 无 hairline | §1.4-B：导航项/纯信息用整组圆角容器 + hairline | 裸行 | P1 |
| ControlAreaComponent.ets:394-452（睡眠 Sheet） | 同上裸行 | 同上 | 裸行 | P1 |

---

## 二、符合项确认（正向确认）

- SongDetailSheet API 26 `systemMaterial` 分支（L122）——全项目唯一合规材质实现，写法与 §2.5.5 改法表一致。
- 四个列表页 detents `[MEDIUM, LARGE]`（Favorites:233 / LocalLibrary:616 / PlayHistory:225 / PlaylistDetail:489）——与 §1.5.15 完全一致。
- 四个列表页 `dragBar:true, showClose:true, preferType:BOTTOM`——符合「保留」规则。
- OnboardingSheet detents `['90%']`（Layout.ets:425）+ dragBar/showClose true——符合 §1.5.15。
- speed / sleep detents `[MEDIUM]` + dragBar/showClose true + BOTTOM——合规。
- Mine detents `[LARGE, MEDIUM]`——符合 §2.5.5 冻结行顺序。
- SongDetailSheet 标题 `t.title3`、label 80vp、排版 `t.subhead`/secondaryText/primaryText——符合 §1.5.15。
- AddToPlaylistSheet「新建歌单」行用 `s.accent` 唯一主动作——符合 §1.5.15。
- 顶部圆角均由系统接管；背景遮罩全部系统默认；动效全部系统接管（无淡出）——符合 §3.2.3。
- SongDetailSheet / AddToPlaylistSheet / OnboardingSheet 在 API 24 降级背景值（cardBg≡surfaceOverlay）与规范数值一致。

---

## 三、系统级结论

**最普遍且最严重的问题 = 背景材质系统性缺失**：全项目仅 `SongDetailSheet.ets` 实现 API 26 `systemMaterial`，其余 8+ 个半模态在 API 26 全部退化为 flat 纯色背景，失去苹果风系统级毛玻璃；叠加 OnboardingSheet「feature 四色未归零」（P0），是当前距设计文档最大的两块视觉硬违反。

**修复主路径**：将 `SongDetailSheet.ets:86-140` 的 `ApiCompat.isAtLeast(API_26) + systemMaterial` 模式抽到共享 util，在其余 sheet 根容器按「API26 systemMaterial / API24 surfaceOverlay」二选一接入（遵守 §2.5.5「材质优先级高于 backgroundColor，不得重复设背景色」）。

---

## 四、文档内部冲突（单独指出）

**§2.5.5 与 §1.5.15 的 detents 顺序冲突**：
- §2.5.5（L1117 冻结行）写 `[SheetSize.LARGE, SheetSize.MEDIUM]`
- §1.5.15（L827-828）写 `[SheetSize.MEDIUM, SheetSize.LARGE]`

首元素相反（HarmonyOS 首元素=初始展开档，行为不同：LARGE 先全屏 / MEDIUM 先半屏）。代码现状是冲突的映射：Mine.ets:253 用 `[LARGE, MEDIUM]`（遵 §2.5.5），四列表页用 `[MEDIUM, LARGE]`（遵 §1.5.15）。
**建议**：以更具体的 §1.5.15（`[MEDIUM, LARGE]`）为权威，统一 Mine 顺序，或反之在文档明确「Settings 类 sheet 刻意以 LARGE 起手」。属文档侧 P2。

---

## 五、严重度汇总
- **P0**：API26 材质缺失（8+ sheet，系统性）、OnboardingSheet feature 四色未归零（L49-55）
- **P1**：SongDetailSheet 行 padding 12≠8（L118）、SongDetailSheet 缺 hairline/InsetGrouped（L143-168）、AddToPlaylistSheet Dialog 容器圆角 16≠24（L150）、AddToPlaylistSheet 列表缺 hairline/InsetGrouped（L169-202）、倍速 Sheet 裸行（L364-391）、睡眠 Sheet 裸行（L394-452）
- **P2**：musicList dragBar/showClose=false（需确认）、AddToPlaylistSheet 次按钮圆角（L128）、列表行高 height vs minHeight（L192）、SongDetailSheet API24 `cardBg` 令牌命名应改 `surfaceOverlay`（L138，值相同）、四列表页/Mine bindSheet 冗余 `backgroundColor:bg`、OnboardingSheet 用 `bg` 而非 `surfaceOverlay`、四列表页缺 `onDisappear` 复位 sheetKind、文档 detents 顺序冲突
