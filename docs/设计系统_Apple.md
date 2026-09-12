# Lumio Music · Apple 风格设计系统
### ——界面结构 / 组件样式规范 / 关键交互说明

> **文档版本**：v1.0（Phase 0 · M0 交付）
> **作者**：蓝绘心（鸿蒙 UI/UX 设计师）
> **项目**：Lumio Music v2.4.0 · HarmonyOS NEXT · ArkTS / ArkUI
> **编译 SDK**：API 26 ｜ **最低兼容**：API 24（`ApiCompat.API_24`）｜ 单模块 `entry` + C++ NAPI
> **本阶段**：**仅产出文档，不改动任何 `.ets` 文件**

---

## 0. 文档定位与命名铁律

### 0.1 与相邻文档的分工（不重叠）

| 文档 | 归属 | 权威性 |
|---|---|---|
| `docs/UI重设计_设计令牌架构.md`（高见远，v1.1） | **工程侧**：三层令牌模型、`tokens/` 文件与字段定义、迁移阶段 P0–P5 | **令牌字段名与取值的唯一真源** |
| `docs/UI重设计_范围与规划.md`（计谋远，v1.0） | **范围侧**：重设计级别 L1/L2/L3、34 文件清单、冻结契约、里程碑 M0–M5 | 范围与契约的唯一真源 |
| **`docs/设计系统_Apple.md`（本文）** | **视觉与交互侧**：界面结构、组件规格数值、交互与动效 | **视觉规范的唯一权威** |
| `docs/UI设计系统.md` / `docs/design_tokens.md` | 已废弃 | ❌ 不得作为依据 |

### 0.2 令牌命名铁律（**强制**）

> 本次改版的根因是历史上出现过三套并行的色彩命名。**本文所有令牌名直接取自架构文档 `tokens/` 的既有字段，一个字都不另起。**

1. 语义色一律写 `LumioSemantic` 的接口字段名，如 `surfaceGrouped` / `labelSecondary` / `fillAccentSubtle`。
2. 尺度一律写 `LumioSpace` / `LumioRadius` / `LumioType` 的接口字段名，如 `space.base` / `radius.md` / `type.headline`。
3. 动效写 `LumioSpringSpecs` / `LumioDurations` 字段名，如 `SpringKind.Crisp` / `LumioDurations.tap`。
4. 海拔 / 毛玻璃写 `LumioElevation` / `LumioGlassSet` 字段名，如 `elevation.high` / `glass.regular`。
5. **架构文档没有的令牌，本文不得发明**——一律登记到 §0.3「待补令牌」，标注用途、建议值、影响面，交 team-lead 裁决。
6. 文中记号：`s.xxx` = `LumioTheme.semantic(isDark).xxx`；`sp.xxx` = `LumioTheme.space(bp).xxx`；`t.xxx` = `LumioTheme.type(bp).xxx`；`r.xxx` = `LumioTheme.radius().xxx`。
7. **决策顺序铁律（team-lead 指令）**：遇到取舍先看**原生怎么做**，再谈权衡。**对齐原生是风险最低的路径，不需要我们发明。**
   > 实例（浏览态歌词，§2.6.8）：三个备选权衡良久，最后决定性判据是「Apple Music 原生歌词只区分『当前行 vs 其他行』，从不区分已播/未播——这个区分在原生里根本不存在」。本案因此收敛为**直接放弃该区分**，而不是在三个自制方案里比选。
   > 后续凡遇「要不要做某个区分 / 加某个标记 / 引入某个新的视觉手段」，第一步是查 Apple/HarmonyOS 原生同类场景做了没有；原生没有且不阻塞可用性 → 默认不做。

### 0.3 令牌裁决记录（**team-lead 已全部裁决**）

| ID | 缺口 | 裁决结论 | 落地位置 / 时机 |
|---|---|---|---|
| **T-01** | AA 达标的次级文字色 | ✅ **不新增令牌，一律用 `labelSecondary`** —— 架构 v1.2 已修正原令牌表的**层级倒挂**（旧表 `labelTertiary` 5.99:1 反而比 `labelSecondary` 3.26:1 醒目），改为对比度锚定的四级单调阶梯。本文初稿引用的 **3.44:1 是修正前的值**；新增第五档会破坏刚修好的单调性，且「SecondaryStrong」语义自相矛盾 | `labelSecondary` 的取值提升已由 team-lead 要求架构师**从 P4 提前到 P1**（否则 M2/M3 全应用次要文字持续不达 AA，最后还需一次性复验所有页面）。**本文规范照常写 `labelSecondary`**，见下方注记 |
| **T-02** | 按压缩放比例常量 | ✅ 批准两级：`pressScale.surface = 0.97` / `pressScale.control = 0.92` | 归属 **`LumioMotionSpec`**（非 `LumioScale`）；主播放键因面积最大另取 `0.90` |
| **T-03** | 悬浮胶囊圆角 30 | ✅ 批准改 **`r.pill`** | 几何论证见下方保留块，**请勿「修正」回 30** |
| **T-04** | 图标尺度 `icon.*` | ✅ 批准**不补令牌**，Component 层用具体 vp 数值 | 若后续 ≥6 处复用同一尺寸，再统一补 `icon.sm/md/lg` |

> **📌 T-01 实施注记（全篇适用）**：本文所有标注为次要文字的位置（歌手名、列表副标题、设置项说明、统计标签、歌单元信息、输入框 Placeholder 等）**统一写 `s.labelSecondary`**。该令牌的**取值将在 P1 被提升至 AA 达标**，届时本文这些位置的对比度自动达标，**无需改任何组件代码**。在此之前若实测不达标，属于 P1 尚未落地，不是选择器写错——**禁止为此在组件里写任何私有色值**。

> **📌 T-03 几何论证（保留，防止被「修正」回 30）**：胶囊容器高 **56vp**，`borderRadius 30` > 56/2 = 28，按 CSS/SVG 圆角缩放算法会被收敛到 **28vp**，与 `radius.pill` 的渲染结果**完全一致**。因此改 `r.pill` 是**零视觉变化**，同时消灭阶梯外魔法数字（闭合 S-5）。若有人主张「30 是设计原意需保留」，请先看这一条——30 从来没有真正渲染成过 30。

> **命名冲突登记（已由 team-lead 裁决，本文据此执行）**：规划文档 §6.4 的自有 type 阶梯（ `largeTitle 34` / `title1 28` / `title2 24` …）与架构 §2.7（ `display 34` / `largeTitle 28` / `title1 22` / `title2 20` …）**不一致**。按「复用架构字段名」铁律，**本文一律采用架构 §2.7 的 12 阶**，规划稿的 type 表作废。

### 0.4 本文不触碰的冻结契约

| 契约 | 内容 | 本文的处理 |
|---|---|---|
| 功能集 | 21 项（导入/搜索/排序/收藏/歌单/历史/文件夹/重复检测/年度回顾/设置 8 项/卡片/投播/歌词…） | 只改呈现，**不改任何入口的存在与否与行为** |
| 信息架构 | `Index` → `Layout`（悬浮胶囊 + Tabs）→ 二级页；路由名 14 条 | 导航树原样保留（§1.1） |
| 数据流 | AppStorage 键位 26 个、四个单例 | 不新增/改名任何键位；组件只读 `@StorageProp` |
| 三条 Sheet 机制 | 单 Sheet 调度（`sheetKind`+`sheetVisible`）、`onDisappear` 复位 kind、`pendingOnboarding` 衔接 | 不改；§3.2.3 的 Sheet 转场与 §3.4-K05 严格遵守 |
| 一镜到底 | `geometryTransition('player_cover')` | **ID 不变**；两端圆角必须同 PR 改（见 §2.3 封面圆角规则、§3.2.2） |

### 0.5 单位与写法约定

| 项 | 约定 |
|---|---|
| 字号 | 一律 `fp`（跟随系统字体缩放），**禁用 `px`** |
| 行高 / 字距 / 尺寸 / 间距 / 圆角 | 一律 `vp`（不随字体缩放，避免行高塌陷） |
| 取色 | 一律 **普通方法** `private s(): LumioSemantic`，**禁止 `private get`**（ArkUI 状态变换器会整段丢弃 → 运行时 undefined 崩溃） |
| `build()` / `@Builder` 体 | **首条语句必须是 UI 组件**；体内禁止 `const` / `let`。令牌经 **`@Builder` 形参**传递复用 |
| 类型 | 禁 `any` / `unknown`、禁解构声明、禁行内对象字面量当类型 |
| 文件头 | 所有 `.ets` 保留 Apache-2.0 头（Copyright 2026 何宇翔） |
| API 26 专属 | `ContainerReader` / `@ohos.arkui.uiMaterial` 必须 `import type` + 动态 `import()` + `ApiCompat.isAtLeast(26)` 双闸门 |

---
---

# 第一部分：重新设计后的界面结构

## 1.1 信息架构总览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Index  @Entry  （HdsNavigation + NavPathStack + Splash 覆盖层 1200ms 淡出）   │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  Layout  （NavDestination · 路由名保留）                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ 内容层  Tabs（barHeight 0 / scrollable false）                        │    │
│  │   ├── Tab 0  LocalLibrary   音乐库                                    │    │
│  │   └── Tab 1  Mine           我的                                      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │ 悬浮层  SkinBar（悬浮胶囊底栏，位于内容之上）                           │    │
│  │   [ Tab 音乐库 ] [ Tab 我的 ]  ...  [ ▶ 播放键 = 一镜到底起点 ]        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│  bindSheet: OnboardingSheet（detents ['90%']）                              │
└──────┬─────────────────────────────┬─────────────────────────┬─────────────┘
       │ pushPathByName              │ pushPathByName          │ Mine 的 bindSheet
       ▼                             ▼                         ▼
  ┌──────────┐   ┌────────────┬──────────────┬───────────┐  ┌──────────────┐
  │PlayerPage│   │ Favorites  │ Playlists    │PlayHistory│  │ Settings     │
  │ 一镜到底  │   │ 收藏       │ →PlaylistDetail 播放历史 │  │（Sheet 内）  │
  │Swiper 2页 │   │            │ FolderBrowse │           │  │ →SettingsCategory
  │ 封面/歌词 │   └────────────┴──────────────┴───────────┘  │ →4 个子页 Body│
  └──────────┘                                               │ About（Sheet）│
                                                             └──────────────┘
  ┌──────────────────────────────────────────────────────────────────────┐
  │ 4 个薄壳 NavDestination（UI 全在 SettingsSubPageBodies.ets）           │
  │   ManageSongs → ManageSongsBody                                       │
  │   DuplicateSongs → DuplicateSongsBody                                 │
  │   Wrapped → WrappedBody                                               │
  │   PrivacyPolicy → PrivacyPolicyBody                                   │
  └──────────────────────────────────────────────────────────────────────┘
  ┌──────────────────────────────┐   ┌──────────────────────────────────┐
  │ Form 独立进程                │   │ 覆盖层                            │
  │   WidgetCard（桌面播控卡片） │   │   Splash（1200ms 后淡出）         │
  └──────────────────────────────┘   └──────────────────────────────────┘
```

**结构不变，变的只有「每一层用什么底、多大留白、什么圆角」。**

## 1.2 需设计界面清单与改造级别

| # | 界面 | 载体文件 | 级别 | 本文对应小节 |
|---|---|---|---|---|
| 1 | Splash 启动页 | `pages/Splash.ets` | L2 | §1.5.1 |
| 2 | Layout 壳 + 悬浮胶囊底栏 | `pages/Layout.ets` | L2 | §1.5.2 |
| 3 | LocalLibrary 音乐库 | `pages/LocalLibrary.ets` | **L3** | §1.5.3 |
| 4 | Mine 我的 | `pages/Mine.ets` | **L3** | §1.5.4 |
| 5 | PlayerPage 播放页（含 Swiper 封面/歌词） | `pages/PlayerPage.ets` + 4 个组件 | **L3** | §1.5.5 |
| 6 | Playlists 歌单列表 | `pages/Playlists.ets` | **L3** | §1.5.6 |
| 7 | PlaylistDetail 歌单详情 | `pages/PlaylistDetail.ets` | **L3** | §1.5.7 |
| 8 | Favorites 收藏 | `pages/Favorites.ets` | L2 | §1.5.8 |
| 9 | PlayHistory 播放历史 | `pages/PlayHistory.ets` | L2 | §1.5.9 |
| 10 | FolderBrowse 文件夹浏览 | `pages/FolderBrowse.ets` | L2 | §1.5.10 |
| 11 | Settings 设置（Sheet 根） | `pages/Settings.ets` | L2 | §1.5.11 |
| 12 | SettingsCategory 设置分类 | `pages/SettingsCategory.ets` | **L3** | §1.5.12 |
| 13 | 4 个薄壳页 + SubPageHeader | `SettingsSubPageBodies.ets`（~900 行） | **L3** | §1.5.13 |
| 14 | About 关于 | `pages/About.ets` | L2 | §1.5.14 |
| 15 | SongDetailSheet 歌曲详情 | `components/SongDetailSheet.ets` | L2 | §1.5.15 |
| 16 | AddToPlaylistSheet 添加到歌单 | `components/AddToPlaylistSheet.ets` | L2 | §1.5.16 |
| 17 | OnboardingSheet 新手引导 | `components/OnboardingSheet.ets` | L2 | §1.5.17 |
| 18 | WidgetCard 桌面卡片（独立进程） | `widget/pages/WidgetCard.ets` | L2 | §1.5.18 |

> **两个最高杠杆点：`SongListItem`（1 组件覆盖 4 个列表页）与 `SubPageHeader` + 4 个 Body（1 文件覆盖 4 个页面）**。它们的规范在 §2.6.1 与 §2.7.3 / §1.5.13 优先给出。

## 1.3 通用页面骨架（三区模型）

所有全屏页面统一遵循此骨架，**不再各自发明 Header**。

```
┌────────────────────────────────────────────┐ ← 屏顶（expandSafeArea TOP）
│  ① 安全区  topHeight（@StorageProp，禁硬编码）│
├────────────────────────────────────────────┤
│  ② 标题区  LargeTitleBlock                  │  高度 = sp.loose(24) + 文字行高
│     · 左侧大标题  type.title1                │  padding top = topHeight + sp.tight(4)
│     · 右侧操作入口（Pill / Icon，≤2 个）      │  padding bottom = sp.cozy(12)
│     · 背景：跟随页面底，**不加分割线**         │
├────────────────────────────────────────────┤
│  ③ 工具区  ToolBar（可选，吸顶）              │
│     · 搜索框 / 排序 Chip / 分段控件           │  margin bottom = sp.compact(8)
├────────────────────────────────────────────┤
│  ④ 内容区  Content（Scroll / List / Grid）    │  layoutWeight(1)
│     · 页面水平内距 = sp.base（见 §1.6）        │
│     · 底部避让 = bottomHeight + 胶囊底距 12   │
│       + 胶囊 56 + sp.compact(8)              │
│       = bottomHeight + 76（全局唯一常量）     │
├────────────────────────────────────────────┤
│  ⑤ 悬浮层  SkinBar（悬浮胶囊 / Fab / Toast）  │  ← 覆盖在内容之上
└────────────────────────────────────────────┘ ← 屏底（expandSafeArea BOTTOM）
```

**表面层级（P3 后，四种底，最多三层，不得超三层）**

| 层级 | 令牌 | light | dark | 用于 |
|---|---|---|---|---|
| L1 页面底 | `s.surfaceGrouped` | `#F2F2F7` | `#000000` | 所有页面根容器 |
| L2 卡片面 | `s.surfaceGroupedContent` | `#FFFFFF` | `#1C1C1E` | 列表项、卡片、菜单行、分组容器面 |
| L3 卡内槽 | `s.backgroundTertiary` | `#FFFFFF` | `#2C2C2E` | 搜索框、嵌套容器、输入框、Segmented 底槽 |
| 浮层 | `s.surfaceOverlay` | `#FFFFFF` | `#1C1C1E` | Sheet / Dialog / 悬浮胶囊（API 24 兜底） |

> ⚠️ **施工纪律（沿用架构 R-12 / §4.6）**：`surfaceGrouped`（页面底）与 `surfaceGroupedContent`（卡片面）必须**同一页面同一 PR 成对切换**，禁止跨页分批、禁止单边改色。每个页面 PR 必须附浅色 + 深色两张截图，且截图中同时出现「页面底 / 卡片 / 分隔线」三种元素。

## 1.4 两种列表容器范式（**全局只用这两套，不再第三种**）

Apple 的 Inset Grouped 有两种合法形态，本文按「内容性质」分配，**不允许混用**：

| 范式 | 结构 | 何时用 | 用的界面 |
|---|---|---|---|
| **A · 卡片型列表（Card List）** | 每行一个独立圆角容器，行间 **留白（无分隔线）** | 每行一个独立圆角容器，相邻行之间存在 8vp 空隙 | 内容是**媒体对象**（有封面、可播放、可长按操作） | LocalLibrary / Favorites / PlayHistory / PlaylistDetail 歌曲区 / FolderBrowse / ManageSongs / 队列 Sheet / Playlists |
| **B · 分组型列表（Inset Grouped）** | 整组共用一个圆角容器，行间用 **0.5vp hairline `s.separator`**，行本身无底色 | 内容是**导航项 / 开关 / 纯信息** | Mine / Settings / SettingsCategory / SongDetailSheet 信息行 / AddToPlaylistSheet / 倍速 Sheet / 睡眠 Sheet / About |

```
  范式 A · 卡片型                       范式 B · 分组型
  ┌──────────────────────┐            ┌──────────────────────┐
  │ ▢ 曲名        [无损] │  ← SurfaceRow│ ▢ 我的收藏      12 首 ›│  ← GroupRow
  └──────────────────────┘            ├──────────────────────┤ ← 0.5vp hairline
    ↕ 8vp gap（无分隔线）              │ ▢ 我的歌单       3 个 ›│
  ┌──────────────────────┐            ├──────────────────────┤
  │ ▢ 曲名                │            │ ▢ 播放历史      86 首 ›│
  └──────────────────────┘            └──────────────────────┘
```

### 1.5 逐个界面结构说明

---

### 1.5.1 Splash 启动页

**布局骨架**

```
┌──────────────────────────┐
│                          │
│      ┌──────────┐        │   logo 96×96  radius.xl(24)
│      │  Lumio   │        │   （现状 28 → 收敛到 AIC）
│      └──────────┘        │
│                          │
│      Lumio Music         │   type.largeTitle 28/700/34
│      本地音乐，纯粹聆听   │   type.footnote 13 · s.labelSecondary
│                          │
└──────────────────────────┘
   背景 s.background（light #FFFFFF / dark #000000）
```

| 分区 | 承载内容 | 令牌 |
|---|---|---|
| Logo | 品牌标识 | 96×96 / `r.xl`(24) / `elevation.cover` |
| 品牌名 | 产品名 | `t.largeTitle` / `s.label` |
| Slogan | 定位语 | `t.footnote` / `s.labelSecondary` |

**改了什么 / 为什么**

| 现状问题 | 改法 |
|---|---|
| 2 处裸 hex（`#1C1C1E` / `#000000`）； logo 圆角 28 不在阶梯 | 底用 `s.background`；logo `r.xl`(24) |
| 700ms `EaseOut` 缩放 + 淡入 **未受 `reduceMotion` 管控** | 接入降级：`reduce` 时仅 300ms 淡入，无缩放（§3.6） |

---

### 1.5.2 Layout 壳层 + 悬浮胶囊底栏

**布局骨架**

```
Stack(alignContent: Bottom)
├── Tabs（barHeight 0 · scrollable false · animationDuration 200）
│     └── TabContent ×2        背景 s.surfaceGrouped
│           padding bottom = bottomHeight + 76   ← 全局唯一避让点
└── customBottomBar()          ← 悬浮胶囊（品牌核心悬浮容器）

customBottomBar:
┌──────────────────────────────────────────────────┐
│  [ 🎵      ]   [ 👤      ]        ┌────────┐     │  高 56
│   音乐库         我的              │ 封面48 │     │  内层左右 padding 8
│  caption2       caption2           └────────┘     │
└──────────────────────────────────────────────────┘
   width 92% · maxWidth 520/560/680 · margin bottom = bottomHeight + 12
```

| 分区 | 承载内容 | 规格 |
|---|---|---|
| 胶囊容器 | Tab 区 + 播放入口 | 高 56 / `r.pill`（T-03）/ `elevation.high` / 深色加 0.5vp `s.borderSubtle` |
| Tab 项 ×2 | 图标 22 + 文案 `t.caption2` | 选中 `s.accent`，未选中 `s.labelSecondary`；按下 `pressScale.control`（T-02） |
| 播放键 | 48×48 封面 + 播放态遮罩 | 56×56 / `r.pill` / `s.accent` / `elevation.accent`；封面 48×48 `r.lg`(16) |
| 封面遮罩 | 播放/暂停指示 | 48×48 / `r.lg`(16) / 底 `s.onMediaScrim` / 图标 22 `s.onMediaPrimary` |

**响应式**

| 断点 | maxWidth | 备注 |
|---|---|---|
| sm | 520 | 现状保留 |
| md | 560 | 现状保留 |
| lg | 680 | 或改侧边栏（本阶段不改结构，仅加宽） |

**改了什么 / 为什么**

| # | 现状问题 | 改法 |
|---|---|---|
| 1 | `const ACCENT = '#FA2759'` 本地常量（本文件定义，与 `LocalLibrary.ets:35` 构成第二份重复定义） | **删除**，改 `s.accent` |
| 2 | 3 处裸 hex：`rgba(0,0,0,0.20/0.45)`、`rgba(255,255,255,0.08)`、`rgba(250,39,89,0.35)` | → `elevation.high` / `elevation.high`(dark) / `s.borderSubtle` / `elevation.accent` |
| 3 | Tab 按压 `0.9`、播放键 `0.9` 与 Mine 的 `0.97` 不一致 | 统一 `pressScale.control`(0.92)（T-02） |
| 4 | 圆角 `30` 是阶梯外魔法数字 | 换 `r.pill`（几何等价，T-03） |
| 5 | **`SymbolGlyph($r('sys.symbol.*'))` 仍有渲染不确定性**（R-9；播放键已因该问题改位图） | **Tab 图标一并改位图资源**，与播放态图标同策略先行改造，避免 SymbolGlyph 与位图两条路线并存 |
| 6 | 封面 48 用 `borderRadius 14`（阶梯外） | → `r.lg`(16)，**与播放页大封面同步改**（R-03） |
| 7 | API 24 分支背景用 `cardBg` | → `s.surfaceOverlay`（语义正确「浮层」） |
| 8 | API 26 `systemMaterial` 挂真实 `Row` 的写法 | ✅ **正确，保留**；材质优先级高于 `backgroundColor`，不得重复设背景色 |
| 9 | 🔴 **底部避让被算了两遍**：`Layout` 的 Tabs 加了 `padding bottom = bottomHeight + 16`，`LocalLibrary` / `Mine` 根节点**又各自加了一次**（实际累计 `bottomHeight + 32`），而悬浮胶囊本身还额外占 56+12 —— 三者互不统属 | **收敛为单点**：由 `Layout` 统一提供 `bottomHeight + 76`；`LocalLibrary` / `Mine` **移除各自的底部 padding**。所有二级页（`push` 进来的）无悬浮胶囊，仍自行提供 `bottomHeight + sp.compact(8)` |

> ⚠️ **保留不动**：一镜到底 `geometryTransition('player_cover')` 的共享 ID、`openPlayer()` 与 `PlayerPage.back()` 的对称 `animateTo`（均为 `SpringKind.Hero`）、单 Sheet 调度、`maybeShowPermissionGuide` 时序。

---

### 1.5.3 LocalLibrary 音乐库（**L3 深度重构**）

**布局骨架**

```
┌────────────────────────────────────────────┐
│ 音乐库                        [↓ 导入]     │ ← LargeTitleBlock
│ t.title1                     Pill 32 高    │   padding top = topHeight + 4
├────────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐  │
│ │ 🔍  搜索歌曲、艺术家                  │  │ ← 搜索框 h44 r.pill
│ └──────────────────────────────────────┘  │   底 s.backgroundTertiary
├────────────────────────────────────────────┤
│ 共 128 首歌曲                              │ ← 元信息条 t.footnote
├────────────────────────────────────────────┤
│ [默认] [标题] [歌手] [专辑] [最近] [随机] →│ ← 排序 Chip 横滑 h32
├────────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐  │
│ │ ▢ 曲名                    [无损]      │  │ ← SongListItem 范式 A
│ │   歌手 · 03:42                        │  │   minHeight rowHeight
│ └──────────────────────────────────────┘  │
│   ↕ 8vp                                    │
│ ┌──────────────────────────────────────┐  │
│ │ ▢ 曲名                                │  │
│ └──────────────────────────────────────┘  │
│                    ⋮                        │
│ （空态 / 加载态 / 错误态 三选一，见 §2.5.7–9）│
└────────────────────────────────────────────┘
 页面底 s.surfaceGrouped · 底部避让由 Layout 统一负责（本页移除自身底部 padding）
```

| 分区 | 承载内容 | 规格 |
|---|---|---|
| ① 标题区 | 「音乐库」+ 导入 Pill | 见 §2.4.1 「Pill 按钮」 |
| ② 搜索区 | 搜索输入框 | 见 §2.4.5 |
| ③ 元信息条 | 「共 N 首歌曲」 | `t.footnote` / `s.labelSecondary`/ `sp.base` 左右 |
| ④ 排序区 | 6 个 Chip，横滑 | 见 §2.4.7 Chip / 未来可按需升级为 §2.4.6 分段控件 |
| ⑤ 列表区 | `SongListItem`（范式 A） | 见 §2.6.1 |
| ⑥ 三态 | 空 / 加载 / 错误 | 见 §2.5.7 / §2.5.8 / §2.5.9 |

**响应式**

| 断点 | 列表形态 | 页面内距 | 备注 |
|---|---|---|---|
| sm | `List` 单列 | `sp.base`(16) | 现状 |
| md | `Grid` 两列（`columnsTemplate '1fr 1fr'`） | `sp.base`(20) | 现状机制保留，列间距 `sp.compact` |
| lg | `Grid` 两列 | `sp.base`(24) | 内容最大宽度 1080 居中 |

**改了什么 / 为什么**

| # | 现状问题 | 改法 |
|---|---|---|
| 1 | **歌曲列表项在 LocalLibrary / Favorites / PlayHistory / PlaylistDetail 四处复制**（各写各的圆角、按压、色值），改一处漏三处 | 抽 **`SongListItem`** 统一组件（§2.6.1）。签名用「数据 + 可选回调 + 菜单项数组注入」，禁布尔参数爆炸 |
| 2 | `const ACCENT = '#FA2759'`（与 Layout 重复定义第二份） | 删除，走 `s.accent` |
| 3 | 行高死宽 `height(72)`，**超大字体下多行挤出容器**（无障碍 R-11） | `minHeight(sp.rowHeight)` + 上下 `sp.cozy` padding |
| 4 | 选中行底 `rgba(250,39,89,0.05)` 与 581 行 `0.08` 两种值同语义 | 全部 → `s.fillAccentSubtle` |
| 5 | 排序 Chip 圆角 14、padding left/right 14 top/bottom 6，行高无 token | 见 §2.4.7 |
| 6 | 搜索框高 44 / 半径 22（22 阶梯外） | 44 / `r.pill` |
| 7 | 长按菜单（§2.6.3）项高 44 ✅ 达标，但图标 18/文案 14 无行高、删除项用裸 `#FA2759` | 菜单项改统一规格，删除走 `s.danger`（**破坏性操作 = 语义着色，非装饰**） |
| 8 | 「正在播放」由 `this.store.currentIndex === index` 轮询判定（500ms `setInterval`） | **不改判定机制**（数据流冻结），仅把结果接通到统一的 `isPlayingCurrent` 入参 |
| 9 | 页面底是 `bg`(#FFFFFF) + 卡片 `#F2F2F7`（**层级是反的**） | P3 成对切换：`s.surfaceGrouped` + `s.surfaceGroupedContent` |
| 10 | 空态图标 2s 呼吸用 `setInterval` 且 `startEmptyPulse` 未清理 interval | 改用生命周期守卫的递归（参考 `Playlists.startBreathing` 已验证写法）；`reduceMotion` 时不启动 |
| 11 | 本页根节点自带 `padding bottom = bottomHeight + 16`，与 `Layout` 的 Tabs padding **重复叠加** | 移除，底部避让交回 `Layout` 单点负责（见 §1.5.2 改动 9） |
| 12 | md/lg 的 `Grid` 两列分支只设了 `rowsGap 8`，未设列间距 | 补 `columnsGap = sp.compact`(8)，与行间距一致 |

---

### 1.5.4 Mine 我的（**L3 深度重构 · AD-0 首要整治对象**）

**布局骨架**

```
┌────────────────────────────────────────────┐
│ 我的                                        │ ← t.title1
├────────────────────────────────────────────┤
│      128        12         86              │ ← 统计三栏
│      歌曲       收藏       历史             │   数字 t.title3 / 标签 t.footnote
├────────────────────────────────────────────┤
│  ┌────────────────────────────────────┐   │
│  │ ▢ 我的收藏        12 首歌曲      ›  │   │ ← Inset Grouped 组 1
│  ├────────────────────────────────────┤   │   0.5vp hairline
│  │ ▢ 我的歌单         3 个歌单      ›  │   │
│  ├────────────────────────────────────┤   │
│  │ ▢ 播放历史        86 首歌曲      ›  │   │
│  ├────────────────────────────────────┤   │
│  │ ▢ 文件夹浏览      按来源目录整理 ›  │   │
│  └────────────────────────────────────┘   │
│  更多                                      │ ← 分组标题 t.footnote
│  ┌────────────────────────────────────┐   │
│  │ ▢ 设置                          ›  │   │ ← 组 2
│  ├────────────────────────────────────┤   │
│  │ ▢ 关于              v2.4.0       ›  │   │
│  └────────────────────────────────────┘   │
└────────────────────────────────────────────┘
 页面底 s.surfaceGrouped
```

| 分区 | 承载内容 | 规格 |
|---|---|---|
| ① 标题区 | 「我的」 | `t.title1` / `sp.base` 左右 |
| ② 统计三栏 | 歌曲 / 收藏 / 历史 三个计数 | 见 §2.6.9 StatTriple |
| ③ 组 1（4 项） | 收藏 / 歌单 / 历史 / 文件夹 | Inset Grouped，`s.surfaceGroupedContent` |
| ④ 分组标题 | 「更多」 | `t.footnote` / `s.labelSecondary`，上 `sp.base` 下 `sp.compact` |
| ⑤ 组 2（2 项） | 设置 / 关于 | Inset Grouped |

**改了什么 / 为什么**

| # | 现状问题 | 改法 | 依据 |
|---|---|---|---|
| 1 | **统计三栏三色并列**（`#FA2759` / `#34C759` / `#FF9500`） | **数字统一 `s.label`，标签统一 `s.labelSecondary`，彩色归零**。理由：三个数并列给色，会重新引入「按类别分配色相」的观感，与 AD-0 第 3 条直接冲突 | AD-0 三级优先序第 3 级（中性） |
| 2 | **菜单四色图标**（收藏 `#FA2759` / 歌单 `#5856D6` / 历史 `#FF9500` / 文件夹 `#007AFF` / 关于 `#5856D6`）——全仓最不 Apple 的部分 | **全部改 `s.labelSecondary`+ 单色描边图标**；类别区分靠**图标形状 + 文案 + 封面**，不靠颜色 | §2.12.1 三级优先序；§2.12.3 逐项口径 |
| 3 | 「歌单」入口：有封面时也应内容着色 | 保留 `CoverImageView` 取封面；封面色只用于**缩略图本身**，不作为图标/文字染色 | AD-0 第 1 级（内容着色） |
| 4 | 菜单项 `.height(60)` 固定，**多行挤出**（歌手副标题 + 大字体） | `minHeight(sp.rowHeightCompact)` + `sp.cozy` 上下 padding | R-11 |
| 5 | 菜单项是「每张独立圆角卡 + `margin bottom 8`」堆叠 | 改为 **Inset Grouped**（整组一个 `r.md` 容器 + 行间 0.5vp hairline） | Apple Settings 范式 §1.4-B |
| 6 | 按压 `0.97` 与 Layout 的 `0.9` 不一致；按压底用裸 `rgba(120,120,128,0.12)` | 按压 `pressScale.surface`(0.97)（T-02）；按压底 `s.fillTertiary` | 状态统一 |
| 7 | 入场 `delay: 200 + index*60` 且 `index*60` 无上限 | 错峰用 `LumioTheme.stagger(index)`，**上限 8 项**（超出按 8 计） | 见 §3.1 |
| 8 | 统计区背景 `secondaryBg`，与页面 `#FFFFFF` 形成「第二条灰带」 | 统计区**不再单独铺底**，与页面同为 `s.surfaceGrouped`，靠**留白**分隔 | Apple 留白即分隔 |

> ⚠️ **绝对不动**：`sheetKind` + `sheetVisible` 单 Sheet 调度、`onDisappear` 才复位 kind、`pendingOnboarding` 衔接。这三条是踩坑后的正确解。

---

### 1.5.5 PlayerPage 播放页（**品牌核心 · M3**）

**布局骨架（sm / md）**

```
Stack
├─ ① 封面裁切背景层   Image blur + linearGradient（改：改由 ArtworkTint 供给）
├─ ② 动态蒙层         s.onMediaScrim（据 lyricBgDark 选择）
└─ ③ Stack(TopStart)
     ├─ Swiper（loop false · indicator DotIndicator.top(12)）
     │    ├─ Page 0：MusicInfoComponent（封面 + 标题/歌手 + QualityBadge + ControlArea）
     │    └─ Page 1：LyricsComponent（歌词 + ControlArea）
     └─ TopAreaComponent（返回 / 更多，浮于 Swiper 之上）
```

**布局骨架（lg / 折叠展开）**

```
Column
├─ TopAreaComponent
└─ GridRow（columns md/lg）
     ├─ GridCol：封面节能 → 大封面 420 固定 / 或 Column（Cover + ControlArea）
     └─ GridCol：LyricsComponent（歌词）
```
> ✅ **保留** `PlayerInfoComponent` 的 `isFoldFull` / `lg` / `else` 三分支结构，只改内部尺度与取色。

| 分区 | 承载内容 | 规格 |
|---|---|---|
| ① 背景层 | 封面放大 + `blur(32)` + 渐变 | 不透明度压到 **0.5 → 0.35**（现状 0.5 时个别亮封面会吞掉控件） |
| ② 动态阅读蒙层 | 保证文字/控件可读 | `lyricBgDark ? s.onMediaScrim : s.onMediaScrim`（统一由 `ArtworkTint` 决定是否叠加，见 §2.6.5） |
| ③ 封面 | 播放页大封面 | `aspectRatio 1` / **`r.lg`(16)**（与迷你封面共用，R-03）/ `elevation.cover` |
| ④ 标题/歌手 | `StyledString` 富文本 | `t.title1`(22→lg 24) Bold `Color.White`；歌手 `t.body`(15) `s.onMediaSecondary` **（不再用资源色 `play_text_color`）** |
| ⑤ QualityBadge | 无损 / Hi-Res | 见 §2.4.8（媒体主场 ... 改 `onMedia` 变体） |
| ⑥ ControlArea | 播放模式的 6 个控制件 + Slider + 三大键 | 见 §2.6.6 / §2.6.7 |
| ⑦ Swiper 指示器 | DotIndicator | `top(sp.cozy)`，`selectedColor s.onAccent`，`color s.fillSecondary` |

**响应式**

| 断点 | 布局 | 封面 |
|---|---|---|
| sm | Swiper 两页（封面页 / 歌词页） | 全宽 − 2×`sp.base` |
| md | Swiper 两页 | 全宽 − 2×`sp.base`，上限 420 |
| lg / 折叠展开 | 左封面 / 右歌词分栏 | 固定 420 |

**改了什么 / 为什么**

| # | 现状问题 | 改法 |
|---|---|---|
| 1 | 封面圆角三套并存：迷你 14（`Layout`）、播放页小 12（`cover_radius_label`）、lg 分支 16（`cover_radius`） | **统一 `r.lg`(16)**，两端**同 PR 改**并录屏验证转场（R-03） |
| 2 | 13 处歌词 Canvas 裸 hex（`#80ffffff` / `#4d000000` …）被误当主题色写死 | 语义化为 **`s.onMedia*`** 六件套，经**显式注入**（Canvas 吃不到 ArkUI 令牌，这是特殊通道） |
| 3 | 标题/歌手用资源色 `play_text_color`（`dark/color.json` 缺 -> 回退浅色） | 改 `s.onMediaPrimary` / `s.onMediaSecondary` |
| 4 | 封面背景 `blur` + `opacity 0.5`，亮封面时控件发灰不可读 | 压到 0.35，并强制叠 `s.onMediaScrim`（按 `lyricBgDark`） |
| 5 | 控制区图标统一 `.opacity(0.86)`，色 `Color.White` | → `s.onMediaSecondary`（浅/深封面背景均由此自动适配）；按下 `opacity 0.6` |
| 6 | 进度条用资源色 `slider_select` / `slider_track`（缺深色镜像） | → `s.accent` / `s.fillTertiary` |
| 7 | 播放/暂停三档按压：`0.75` / `0.85` / `0.75` 无规律 | → 统一 `pressScale.control`(0.92)（T-02），主播放键保持更明显的 `0.90`（因为它 60+vp，需更大反馈） |
| 8 | `imageColor` 取色只有播放页在用 | 抽 **`ArtworkTint`** 可复用能力（架构 §2.12.2），供歌单卡 / 文件夹卡共用 |
| 9 | 6 秒后控制区自动隐藏（`pageShowTime > 5`） | ✅ 保留；补充：Swiper 切回封面页时**立即复位**（现状已做） |

> ⚠️ **绝对不动**：`ContainerReader` / `StyledString` 的 API 26 闸门与降级分支、`TextController.setStyledString` 时机、`LrcView` 的 `PanGesture` 增量派发跟手逻辑、`geometryTransition('player_cover')` ID、`back()` 与 `openPlayer()` 的**对称** `SpringKind.Hero`。

---

### 1.5.6 Playlists 歌单列表（**L3**）

**布局骨架**

```
┌────────────────────────────────────────────┐
│ ‹ 我的歌单                            [＋]  │ ← SubPageHeader（返回 + 新建）
├────────────────────────────────────────────┤
│ 智能歌单                          ⌄ 收起   │ ← 可折叠分组头
│ ┌──────────────────────────────────────┐  │
│ │ ▢ 我最常听            32 首         › │  │ ← PlaylistCard（范式 A）
│ └──────────────────────────────────────┘  │
├────────────────────────────────────────────┤
│ 自建歌单 3 个                               │
│ ┌──────────────────────────────────────┐  │
│ │ ▢ 深夜通勤            12 首         ›  │  │
│ └──────────────────────────────────────┘  │
│   ↕ 8vp                                    │
│ ┌──────────────────────────────────────┐  │
│ │ ▢ 跑步 playlist        8 首          ›  │  │
│ └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

| 分区 | 承载内容 | 规格 |
|---|---|---|
| ① SubPageHeader | 返回 + 标题 + 右侧「新建」 | 见 §2.7.3 |
| ② 智能歌单分组 | `SmartPlaylistService` 产出，可折叠 | 强调色**由首曲封面经 `ArtworkTint` 取色**（AD-0 第 1 级） |
| ③ 自建歌单分组 | 用户歌单列表 | `PlaylistCard` 范式 A |
| ④ 空态 | 无歌单 | 见 §2.5.7 |

**改了什么 / 为什么**

| # | 现状问题 | 改法 |
|---|---|---|
| 1 | 14 处裸 hex（全仓业务第二高），歌单卡的强调色一律写死品牌色 | 全量令牌化 |
| 2 | 封面 `coverRadius 10`（阶梯外），空歌单叠 `ic_song_list` `#FFFFFF` | 封面 `r.md`(12)（56 档）；空态封面底 `s.fillTertiary` + 图标 `s.labelSecondary` |
| 3 | 长按菜单背景用 `bg`（深色 = `#000000` 纯黑，墨底亮字难辨） | → `s.surfaceOverlay` + `s.borderSubtle` hairline |
| 4 | 智能歌单与自建歌单混在一个平铺列表，无分组 | 加两个可折叠分组头（**不改数据源、不加功能**） |
| 5 | 命名弹窗（`PlaylistNameDialog`）未接入 — 由 AddToPlaylistSheet 的样式迁移 | 见 §2.5.5 Dialog |
| 6 | 「智能歌单折叠」已有 `smartCollapsed` @State | ✅ 保留；仅为其补 §2.5.3 Group 容器的分组头视觉（收起时隐藏内容、箭头旋转 180°） |

---

### 1.5.7 PlaylistDetail 歌单详情（**L3**）

**布局骨架**

```
┌────────────────────────────────────────────┐
│ ‹                                    ⋯     │ ← 透明导航栏（浮于封面之上）
│      ┌──────────────────┐                  │
│      │                  │                  │ ← 大封面 200×200 r.xl(24)
│      │   封面/九宫格     │                  │   elevation.high
│      └──────────────────┘                  │
│   深夜通勤                                  │ ← t.title2
│   12 首歌曲 · 1 小时 4 分钟                  │ ← t.footnote labelSecondary
│  ┌────────────┐  ┌────────────┐           │
│  │ ▶  播放全部 │  │ ⤨ 随机播放 │           │ ← 双主行动
│  └────────────┘  └────────────┘           │
├────────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐  │
│ │ ▢ 曲名                    [无损]  ⋯  │  │ ← SongListItem（范式 A）
│ └──────────────────────────────────────┘  │
│                    ⋮                        │
└────────────────────────────────────────────┘
```

| 分区 | 承载内容 | 规格 |
|---|---|---|
| ① 透明导航栏 | 返回 + 更多 | 图标 24 / `s.onMediaPrimary` / 44 触摸目标 / 滚动后叠 `s.surfaceOverlay` 渐变 |
| ② 头部大封面 | 歌单封面（首曲封面九宫格） | 200×200 / `r.xl`(24) / `elevation.high`；无封面 → `s.fillTertiary` + 单色图标（**禁止随机色**） |
| ③ 标题元信息 | 名称 / 歌曲数 / 总时长 | `t.title2` / `t.footnote` |
| ④ 主行动 | 播放全部（Primary）+ 随机（Secondary） | 见 §2.4.1 / §2.4.2 |
| ⑤ 歌曲列表 | `SongListItem`（范式 A） | 菜单项含 **`PlaylistDetail` 特有「从歌单移除」**（注入式，见 §2.6.1） |

**改了什么 / 为什么**

| # | 现状问题 | 改法 |
|---|---|---|
| 1 | 36 处 `getThemeColors()`（全仓业务最高）+ 10 处裸 hex | 全量令牌化 |
| 2 | 头部封面与「播放全部」的视觉层次不足（Apple Music 式的主次关系未建立） | 封面 `r.xl`(24) + `elevation.high` 做主角；「播放全部」`accent` 填充唯一主动作；「随机」为次级按钮（`accent` 面积占屏 < 10%） |
| 3 | 列表项自家一份（第 4 处复制） | 接入 `SongListItem`，「从歌单移除」通过菜单项数组注入 |
| 4 | 头部的歌单取色缺失（现多为品牌色硬编码） | 走 **`ArtworkTint`** 封面取色做标题渐变/强调色；无封面回落中性 |

---

### 1.5.8 Favorites 收藏 / 1.5.9 PlayHistory 播放历史 / 1.5.10 FolderBrowse 文件夹浏览

三者共享同一个「列表页 + SubPageHeader」骨架，差异只在**列表项数据源与菜单项集合**。

```
┌────────────────────────────────────────────┐
│ ‹  我的收藏 / 播放历史 / 文件夹浏览          │ ← SubPageHeader
├────────────────────────────────────────────┤
│ 共 32 首                      [清空]        │ ← 元信息 + 危险操作（仅历史有）
├────────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐  │
│ │ ▢ 曲名                    [无损]      │  │ ← SongListItem（范式 A）
│ └──────────────────────────────────────┘  │
│                    ⋮                        │
└────────────────────────────────────────────┘
```

| 界面 | 列表项形态 | 特殊性 |
|---|---|---|
| Favorites | `SongListItem` 范式 A | 空态文案「还没有收藏的歌曲」；长按菜单含「取消收藏」 |
| PlayHistory | `SongListItem` 范式 A | **清空**为破坏性操作 → `s.danger` + 二次确认 AlertDialog |
| FolderBrowse | `FolderCard`（**范式 A**，见 §2.6.10）→ 二级 `SongListItem` | 层级展开逻辑不变；文件夹封面**由内层首曲封面取色**（AD-0 第 1 级），无封面 → `s.fillTertiary` + 单色图标 |

**改了什么 / 为什么**

| # | 现状问题 | 改法 |
|---|---|---|
| 1 | 三处的歌曲行是第 2/3/4 份复制 | 统一接 `SongListItem` |
| 2 | **`PlayHistory` 用橙色 `#FF9500` 表示「正在播放」**（`188/200/231/291/292` 行），而其他所有页面用品牌 `#FA2759` —— 同一状态两种表达 | **改为 `s.accent`**，与其他页面完全一致（🔴 一致性修复） |
| 3 | 三处各自实现空态（`ic_hm_library` / `ic_music_list` / 各不相同文案） | 统一 `EmptyState`（§2.5.7），仅图文不同 |
| 4 | 行高 `height(64)` / `height(72)` 不一 | `minHeight(sp.rowHeight)` 统一 |

---

### 1.5.11 Settings 设置（Sheet 根，L2）

**布局骨架**

```
┌────────────────────────────────────────────┐
│ [‹] 设置                                    │ ← 内部 Header（SubPage 时显示返回）
├────────────────────────────────────────────┤
│  ┌────────────────────────────────────┐   │
│  │ ▢ 播放        自动下一首 · 播放模式 › │   │ ← Inset Grouped
│  ├────────────────────────────────────┤   │
│  │ ▢ 用户界面    深色模式 · 主题      › │   │
│  ├────────────────────────────────────┤   │
│  │ ▢ 无障碍      降低动态效果         › │   │
│  ├────────────────────────────────────┤   │
│  │ ▢ 存储        缓存 · 历史 · 本地管理› │   │
│  ├────────────────────────────────────┤   │
│  │ ▢ 通知        锁屏/状态栏控制      › │   │
│  ├────────────────────────────────────┤   │
│  │ ▢ 隐私        听歌统计             › │   │
│  └────────────────────────────────────┘   │
│                                            │
│           Made with HarmonyOS SDK          │ ← 页脚 t.caption1
└────────────────────────────────────────────┘
```

| 分区 | 承载内容 | 规格 |
|---|---|---|
| ① Header | 标题 / 二级页时带返回 | `t.title2`；见 §2.7.3 |
| ② 分类列表（6 项） | Inset Grouped | 行 `minHeight(sp.rowHeight)`；图标 24；副标题 `t.footnote` / `s.labelSecondary` |
| ③ 页脚 | 品牌文案 | `t.caption1` / `s.labelQuaternary` |

**改了什么 / 为什么**

| # | 现状问题 | 改法 |
|---|---|---|
| 1 | **6 个分类 6 种彩色**（`#FF9500`×2 / `#5E5CE6` / `#007AFF` / `#FFCC00` / `#FA2759`）——典型的装饰性逐项染色 | **全部改 `s.labelSecondary`单色图标**（AD-0 第 3 级）；「隐私」不再是 `#FA2759` |
| 2 | 分类行 `height(64)` + `borderRadius 14` + `margin bottom 2` 的**离散卡片堆叠** | 改 Inset Grouped 单容器 + hairline |
| 3 | 底部 `ic_hm_more` 箭头用 `separator` 色（过淡，几乎不可见） | → `s.labelQuaternary`（Apple chevron 用 tertiary label） |
| 4 | 行无按压态，“点击是否生效”缺少即时反馈 | 补通用按压态（`pressScale.surface` + `s.fillTertiary`，见 §2.1 状态定义） |

> ⚠️ **绝对不动**：`onRequestClose` 回调契约、`selectedCategory` / `subPage` 的 Sheet 内二级导航机制、`goBackInSheet()` 的三级回退优先级。

---

### 1.5.12 SettingsCategory 设置分类（**L3 · 整治第二对象**）

**布局骨架**

```
┌────────────────────────────────────────────┐
│ ‹  播放                                     │
├────────────────────────────────────────────┤
│ 播放                                        │ ← 分组标题（t.footnote）
│ ┌──────────────────────────────────────┐  │
│ │ ▢ 自动下一首                    [ ○] │  │ ← ToggleRow
│ ├──────────────────────────────────────┤  │
│ │ ▢ 播放模式          顺序播放  ⌄     │  │ ← SelectRow
│ ├──────────────────────────────────────┤  │
│ │ ▢ 无缝播放 (Gapless)           [ ○] │  │
│ │   减少曲间停顿                        │  │ ← 副说明
│ └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

**六种行的规格**（见 §2.4.4 Toggle / §2.4.10 Select）

| 行类型 | 用于 | 图标染色（新） |
|---|---|---|
| `ToggleRow` | 开关项 | `s.labelSecondary`· 仅「启用类」开关打开时右侧 Toggle 用 `s.accent` |
| `SelectRow` | 枚举选择项 | `s.labelSecondary` |
| `NavRow` | 二级跳转项 | `s.labelSecondary` |
| `NavRow(danger)` | **清除缓存 / 清空历史 / 清除统计** | **`s.danger`**（语义着色第 2 级：破坏性操作） |
| `ActionRow` | 立即执行 | `s.labelSecondary` |

**改了什么 / 为什么**

| # | 现状问题 | 改法 |
|---|---|---|
| 1 | **13 处裸 hex，8 处是分类装饰色**（`#34C759` `#FF9500`×3 `#007AFF`×2 `#5E5CE6` `#FFCC00` `#FA2759`×3） | 按上表的三类口径重分配：**入口项中性 / 破坏性 `s.danger` / 已启用 `s.accent`** |
| 2 | 「自动下一首」用 `#34C759` 绿勾表示"已启用" | 开关状态**只由 Switch 组件的 track/thumb 表达**，图标回归中性 |
| 3 | 分组标题（"播放"/"用户界面"/…）的层次弱 | `t.footnote` + `s.labelSecondary`，上 `sp.section`(32) 下 `sp.compact`(8) |

---

### 1.5.13 四个薄壳页 + SubPageHeader（`SettingsSubPageBodies.ets` · **最高杠杆**）

> `ManageSongs` / `DuplicateSongs` / `Wrapped` / `PrivacyPolicy` 四个 NavDestination 是 ~1.1–1.7KB 薄壳，真实 UI 全在本文件。**改这一个文件 = 改四个页面 + 共享头部。**

#### ① `SubPageHeader`（**优先出稿**）

```
┌────────────────────────────────────────────┐
│ ‹   本地歌曲管理                     (占位) │
└────────────────────────────────────────────┘
  返回 24vp · 标题 t.title2 · 右侧 24vp 占位槽
  padding: left/right sp.base, top topHeight+sp.cozy(12), bottom sp.cozy(12)
```

| 项 | 规格 |
|---|---|
| 返回箭头 | 24×24 / `s.label` / 触摸目标 ≥ 44×44（padding 补足）/ 按下 `pressScale.control` |
| 标题 | `t.title2` / `s.label` / `maxLines 1` / Ellipsis |
| 右侧插槽 | 24×24，`rightSlot?: () => void` 可选 Builder（现状是空 Row，保留兼容） |
| 背景 | `Color.Transparent`（跟随页面），**不铺底**（现状无底 ✅ 保留） |

#### ② `ManageSongsBody`

```
SubPageHeader
┌──────┐
│ 32 首 │ ← CountBadge（t.footnote / s.accent / s.fillAccentSoft / r.sm）
└──────┘
┌──────────────────────────────────────┐
│ ▢ 曲名                    [无损]  ⋯  │ ← SongListItem compact 变体
└──────────────────────────────────────┘
 ⋮ / 空态（§2.5.7）
```

#### ③ `DuplicateSongsBody`

```
Row: ‹ 重复歌曲            清理全部（s.accent / t.subhead / Medium）
┌──────────────────────────────────────────┐
│ 相似组名                        [3 个文件]│ ← GroupHeader + CountBadge
├──────────────────────────────────────────┤
│ ▢ 曲名 · 歌手                   [保留]   │ ← Chip（s.backgroundSecondary）
│ ▢ 曲名 · 歌手                   [移除]   │ ← danger Text Button
└──────────────────────────────────────────┘
 / 空态（「没有发现重复歌曲」+ 算法说明）
```

#### ④ `WrappedBody`（**数据可视化重做，视觉空间最大**）

```
Hero Card（Card 容器 r.xl(24)，padding 24）
┌──────────────────────────────────────┐
│ 听 歌 报 告                          │ ← t.footnote / s.accent / letterSpacing 1
│                                       │
│            1,284                      │ ← t.display 34/700/41  ← 改：56→34，入档
│            次播放                     │ ← t.body / labelSecondary
│ ┌─────────────┬─────────────┐       │
│ │ 总收听时长   │ 歌曲总数     │       │ ← 双指标 t.caption1 + t.title3
│ │ 3 天 4 小时  │ 128         │       │
│ └─────────────┴─────────────┘       │
└──────────────────────────────────────┘

最常播放（Card）
┌──────────────────────────────────────┐
│ # │ ▢ 曲名 · 歌手            │ 32 次 │
└──────────────────────────────────────┘

按发行年份（Card · 条形图）
┌──────────────────────────────────────┐
│ 2019  ████████████░░░░░░░░           │ ← Bar 高 14 r.pill / s.accent
│ 2004  ████████░░░░░░░░░░░░           │   槽 s.backgroundSecondary
└──────────────────────────────────────┘
```

| 改什么 | 现状问题 | 改法 |
|---|---|---|
| 主数字 | 56fp 不在任何阶梯 | `t.display`(34) |
| Top3 排名色 | 前 3 名 `#FA2759`、其余 secondary（**排名染色 = 装饰性**） | **序号统一 `s.labelSecondary`**，Top1 额外用 `s.label`（字重 Semibold）；配色零装饰 |
| 年份条形图 | `#FA2759` 实色条 + `#F2F2F7` 槽 | 条 `s.accent` / 槽 `s.backgroundSecondary` / `r.pill` |
| Card 圆角 | Hero 20、TopSongs 12、YearChart 20 —— 三值共存 | 大容器统一 `r.xl`(24)；行卡 `r.md`(12) |
| 卡片内距零散 | Hero `padding 24`、`margin left/right 8`，与列表行不一致 | 统一 `sp.base` 页面内距（Hero 容器内部仍用 `sp.loose`(24)）；列表行左右由 8 → `sp.base` |

#### ⑤ `PrivacyPolicyBody`

纯文本滚动页 → 统一 `t.body` / `lineHeight 20` / `sp.base` 左右 / 段落间距 `sp.loose`(24)；正文除此之外不改。

---

### 1.5.14 About 关于

```
┌────────────────────────────────────────────┐
│                 ┌────┐                     │ ← logo 72×72 r.lg(16)
│                 └────┘                     │
│              Lumio Music                   │ ← t.title2
│              v2.4.0 (2040000)              │ ← t.footnote
├────────────────────────────────────────────┤
│  ┌────────────────────────────────────┐   │
│  │ 新手引导                          ›  │   │ ← Inset Grouped
│  ├────────────────────────────────────┤   │
│  │ 隐私政策                          ›  │   │
│  ├────────────────────────────────────┤   │
│  │ 许可证  Apache-2.0                  │   │
│  └────────────────────────────────────┘   │
│  © 2026 何宇翔                             │ ← t.caption1
└────────────────────────────────────────────┘
```

| 改什么 | 为什么 |
|---|---|
| 0 裸 hex ✅，但 26 处 `getThemeColors()` 需升到新令牌 | 统一真源 |
| 品牌头部 → Inset Grouped 卡片分组 | 与 Settings 保持同构，保证全站设置类页面观感一致 |
| `onStartOnboarding` + `pendingOnboarding` 衔接 | ⚠️ **绝对不动**（防两 Sheet 同帧叠加空白页） |

---

### 1.5.15 SongDetailSheet 歌曲详情 ▸ 1.5.16 AddToPlaylistSheet ▸ 1.5.17 OnboardingSheet

**统一 Sheet 骨架**

```
╭──────────────────────────────────────╮  ← 顶部拖拽指示条 dragBar
│            ──────                    │
│  歌曲信息                     (标题区) │  t.title3 / 居中或左对齐
├──────────────────────────────────────┤
│  文件名        xxx.mp3                │ ← InfoRow（label 80vp 固定）
│  标题          七里香                  │    label: t.subhead / labelSecondary
│  歌手          周杰伦                  │    value: t.subhead / label
│  作曲家        …                       │    行 padding 上下 sp.compact(8)
│  合集          …                       │    行间 0.5vp hairline
│  年代          2004                    │
│  添加时间      2026-08-11 14:32        │
├──────────────────────────────────────┤
│  ╔════════════════════════════════╗  │
│  ║        主行动按钮                ║  │ ← 有的话
│  ╚════════════════════════════════╝  │
╰──────────────────────────────────────╯
  bottom padding = bottomHeight + sp.loose(24)
```

| Sheet | detents（冻结，不改） | 内容差异 |
|---|---|---|
| SongDetailSheet | `[SheetSize.MEDIUM, SheetSize.LARGE]` + dragBar + showClose | 7 行 InfoRow；无主行动 |
| AddToPlaylistSheet | `[SheetSize.MEDIUM, SheetSize.LARGE]` + dragBar + showClose | 歌单列表（`List` 行 56）+ 底部「新建歌单」Action Row |
| OnboardingSheet | `['90%']` + dragBar + showClose | 4 个 FeatureRow + 主按钮「开始体验」 |

**逐个改了什么 / 为什么**

| 组件 | 现状问题 | 改法 |
|---|---|---|
| SongDetailSheet | 标题 18、label 14 / value 14 **无行高**；InfoRow `padding 10`（非 4 倍数） | `t.title3` / `t.subhead`；行 padding `sp.compact`(8)；label 列宽 80vp 保留（对齐需要） |
| AddToPlaylistSheet | 弹窗按钮圆角 20/10；列表行 56 无 minHeight；12 处 getThemeColors + 4 处裸 hex | 按钮 `r.pill`（主）/ `r.md`（次）；行 `minHeight(56)`；令牌化；**新建行用 `s.accent`**（这是唯一主动作，合规） |
| OnboardingSheet | **4 个 feature 四色**（`#FA2759` `#FF9500` `#5856D6` `#34C759`）+ 白字彩底（46×46 `r14`）；主按钮圆角 24 | 依 AD-0 第 6 条「引导页（介绍功能的语义场景）允许用色区分概念，但需设计确认」，本文给出**建议方案**：**图标底色统一 `s.fillAccentSubtle` + 图标 `s.accent`（单一强调色）**，靠留白与图标形状区分，引导页彩色归零。此为设计侧建议，最终仍需 team-lead 确认。主按钮圆角 → `r.pill` |

---

### 1.5.18 WidgetCard 桌面卡片（**独立 Form 进程**）

```
┌────────────────────────────────────┐
│ ┌────┐  歌名                        │  封面 44×44 r.sm(8)
│ │  ▢  │  歌手                        │  标题 t.bodyEmphasis / s.label
│ └────┘  专辑                        │  歌手/专辑 t.caption1 / labelSecondary
├────────────────────────────────────┤
│ ▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░ │  Progress h4 r.xs(2)
│ 01:23                        04:56 │  t.caption1
│ 当前歌词行…                          │  t.caption1（有则显示）
├────────────────────────────────────┤
│      (⏮)      (▶)      (⏭)         │  40 / 56 / 40 · r.pill
└────────────────────────────────────┘
   卡片内距 16vp 四周（现状 16/12 混用 → 统一 16）
```

| 改什么 | 现状问题 | 改法 |
|---|---|---|
| 18 处裸 hex（全仓最高）+ 自建 `getCardColors()` 复制式真源 | 主应用改色卡片不跟 | **P5 改为 `import { semanticOf } from '../../tokens/LumioColor'`**（零 import 模块，卡片可安全引入），`getCardColors()` **整段删除** |
| 各签发所受 margin 混用：top/left/right 16、album 行 top 2、lyric 行 left/right 16 | Apple 卡片内距应恒定 | 统一 16vp 四周；内部元素间距 `sp.tight`(4) / `sp.compact`(8) |
| 次按钮底 `#33FFFFFF` / `#33000000` | 非语义 | `s.fillSecondary` |
| `disabled:` 无 `.accessibilityText` 在封面/专辑上 | 无障碍不足 | 补 `accessibilityText`（曲名/歌手/进度） |
| 🔴 **卡片恒为浅色（活跃线上缺陷，AD-2 / R-15）** | `FormAbility.onAddForm` 未写 `isDark` | 属 P5 修复；本文只负责卡片侧的**取色口径**（用 `semanticOf(this.isDark)`） |

---

## 1.6 响应式断点矩阵

断点沿用 `AppStorage('currentBreakpoint')` + `BreakpointConstants`（`320/600/840` vp）。

| 维度 | sm（<600）Phone | md（600–840）折叠展开 / 小平板 | lg（≥840）平板 / 2-in-1 |
|---|---|---|---|
| 栅格列数 | 4 | 8 | 12 |
| 页面主内距 `sp.base` | 16 | 20 | 24 |
| 内容最大宽度 | 100% | 720 居中 | 1080 居中 |
| `sp.rowHeight` | 72 | 76 | 84 |
| `sp.rowHeightCompact` | 60 | 64 | 72 |
| 触摸目标最小 | 44 | 44 | 48 |
| 列表形态（业务列表） | 单列 Card List | 双列 Grid | 双列 Grid |
| 列表形态（设置/Sheet） | 单列 Grouped | 单列 Grouped | 单列 Grouped（540 居中） |
| 悬浮胶囊 maxWidth | 520 | 560 | 680 |
| 播放页 | Swiper 两页 | Swiper 两页 | 左封面 / 右歌词 |
| 封面尺寸（歌单头/播放页） | 全宽 − 2×base | 全宽 − 2×base，上限 420 | 420 固定 |
| 字号变化 | 基准 | 基准 | `display/largeTitle/title1/title2` **+2fp**（`TYPE_LG`），`body` 及以下不变 |

---
---

# 第二部分：组件样式规范

## 2.1 规范读法

每张规格表的列：

| 列 | 含义 |
|---|---|
| 尺寸 | 宽 × 高（vp）；`min` 前缀表示最小高度（不允许固定 height） |
| 内距 | `padding`，用 `sp.*` 令牌 |
| 圆角 | `r.*` 令牌值 |
| 背景 | `s.*` 语义令牌；**状态变化只换 fill\*** |
| 文字 | `t.*` 排版令牌（字号/字重/行高/字距四元组）+ `s.*` 颜色 |
| 图标 | 边长（vp）+ 颜色令牌 |
| 状态 | 默认 / 按下 / 禁用 / 选中 / 悬停（2-in-1） |

**状态定义（全局统一）**

| 状态 | 表现 |
|---|---|
| 默认 | 规格表给定的基态 |
| 按下 | `opacity` 不降；用 `scale(pressScale)` + 底色 `s.fillTertiary`（**Down 即触发**，非 Up） |
| 禁用 | 文字/图标 `s.labelQuaternary`；填充 `s.accentDisabled`；**不响应触摸** |
| 选中 | 文字/图标 `s.accent`；容器底 `s.fillAccentSubtle` |
| 悬停（2-in-1 指针） | 叠加 `s.fillQuaternary`（**借用现有令牌，不新增**） |

## 2.2 排版投射表（**HIG → 架构 `LumioType` 12 阶**）

| 文本角色 | 令牌 | 字号 fp | 字重 | 行高 vp | 字距 vp | 颜色 |
|---|---|---:|---:|---:|---:|---|
| 年度回顾主数字 | `t.display` | 34 | 700 | 41 | −0.40 | `s.label` |
| Splash 品牌名 | `t.largeTitle` | 28 | 700 | 34 | −0.26 | `s.label` |
| **页面大标题**（音乐库/我的/SubPage） | `t.title1` | 22 | 700 | 28 | −0.20 | `s.label` |
| **二级页标题 / Sheet 标题** | `t.title2` | 20 | 600 | 25 | −0.16 | `s.label` |
| 分组标题 / StatTriple 数字 | `t.title3` | 18 | 600 | 24 | −0.12 | `s.label` |
| **列表主标题 / 菜单标题** | `t.headline` | 17 | 600 | 22 | −0.10 | `s.label`（播放中 `s.accent`） |
| 正文 | `t.body` | 15 | 400 | 20 | −0.06 | `s.label` |
| 强调正文 / InfoRow value | `t.bodyEmphasis` | 15 | 600 | 20 | −0.06 | `s.label` |
| 次级说明 / InfoRow label | `t.subhead` | 14 | 400 | 19 | −0.04 | `s.labelSecondary` |
| **歌手名 / 副信息 / 元信息** | `t.footnote` | 13 | 400 | 18 | 0.00 | `s.labelSecondary` |
| **计数 / 时间戳 / 角标** | `t.caption1` | 12 | 400 | 16 | +0.02 | `s.labelSecondary` |
| Tab 标签 / 极小徽标 | `t.caption2` | 11 | 500 | 14 | +0.04 | `s.labelSecondary` |

> **🔴 铁律（依 T-01 裁决）**：**正文级次要文字一律用 `labelSecondary`** —— 该令牌的取值将在 **P1** 提升至 AA 达标（浅色 ≥4.5:1），届时本文全部次要文字自动达标。
> 只有**真正降级的辅助信息**才允许用 `labelTertiary`；`labelQuaternary` **禁止承载任何用户需读取的信息**，只用于占位符、禁用态、分隔装饰。
> ⚠️ **禁止**为绕过 P1 排期而在组件里写任何私有色值（那会重演三套命名）；P1 落地前实测不达标属预期，不是选择器写错。

## 2.3 封面 / 图片圆角规则（**消灭随机值**）

| 封面边长 (vp) | 圆角 | 典型场景 |
|---|---|---|
| 16 | `r.xs`(4) | 队列 Sheet 内缩略图 |
| 28–40 | `r.sm`(8) | 迷你封面 / 歌词页小图 / 桌面卡片封面（44 → `r.sm`） |
| **44–56** | **`r.md`(12)** | 列表封面 / 歌单卡封面 / AddToPlaylist 封面 |
| **48（一镜到底起点）** | **`r.lg`(16)** | 悬浮胶囊封面（与播放页大封面**必须同 PR 同步**，R-03） |
| ≥200 | `r.xl`(24) | 播放页大封面 / 歌单详情页头图 |
| 圆形 | `r.pill`(999) | 圆形按钮 / 播放指示徽标 / 悬浮胶囊 |

> **同一构件跨场景必须取同一值**：一镜到底的两端（迷你 48 / 大封面）统一 `r.lg`(16)。

## 2.4 基础组件

### 2.4.1 按钮 —— Primary（品牌填充）

| 项 | 规格 |
|---|---|
| 尺寸 | 宽自适应，`minWidth 96`；**高 48**（sm/md）/ 52（lg） |
| 内距 | 左右 `sp.roomy`(20)，上下 `sp.cozy`(12) |
| 圆角 | **`r.pill`(999)**（Apple 主按钮是胶囊） |
| 背景 | 默认 `s.accent` ｜ 按下 `s.accentPressed` ｜ 禁用 `s.accentDisabled` ｜ 悬停 `s.accentPressed` |
| 文字 | `t.bodyEmphasis`（15/600/20）· `s.labelOnAccent` · 居中 |
| 图标 | 20×20（可选），右侧 `sp.tight`(4) |
| 按下 | `scale(pressScale.control = 0.92)` · `SpringKind.Snappy` · `LumioDurations.tap`(120) |
| 无障碍 | 触摸目标 ≥ 44×44（`minHeight` 48 已满足）；`accessibilityText` 必填 |

### 2.4.2 按钮 —— Secondary（描边 / 浅填充）

| 项 | 规格 |
|---|---|
| 背景 | `s.fillSecondary` ｜ 按下 `s.fillTertiary` ｜ 禁用 `Color.Transparent` |
| 文字 | `t.bodyEmphasis` · **`s.accent`** ｜ 禁用 `s.labelQuaternary` |
| 描边 | 无（Apple 的次级按钮不用描边，改用 fill 表达） |
| 其余 | 同 Primary |

### 2.4.3 按钮 —— Tertiary（纯文字 / 危险）

| 变体 | 尺寸 | 文字色 | 背景 |
|---|---|---|---|
| Tertiary 普通 | 高 44，`minWidth 64`，左右 `sp.cozy`(12)，`r.md`(12) | `s.accent` | `Color.Transparent`，按下 `s.fillTertiary` |
| **Destructive** | 同上 | **`s.danger`** | `Color.Transparent`，按下 `s.fillDangerSoft` |

> **何时用 Destructive**：删除、清空、清除、移除、清理。**语义着色第 2 级**，不是装饰。

### 2.4.4 Toggle（开关）

| 项 | 规格 |
|---|---|
| 容器 | 51×31（HarmonyOS 原生 Switch 默认），**不自定义改写 DP、只用令牌换色** |
| track | 开 `s.accent` ｜ 关 `s.fillSecondary`（浅）/ `s.fillPrimary`（深） |
| thumb | `s.surfaceOverlay` + `elevation.low` |
| 禁用 | 整体 `opacity 0.4`，交互关闭 |
| 动效 | 系统自带；`reduceMotion` 时由系统处理 |

### 2.4.5 输入框 / 搜索框

| 项 | 规格 |
|---|---|
| 容器 | 宽 100%（页面内距内）；**高 44**；`r.pill`(999) |
| 背景 | `s.backgroundTertiary`（light #FFFFFF 白框落 gray 页面，正是 Apple 观感）｜ 聚焦加深描边 `s.borderAccent` 1vp |
| 内距 | 左右 `sp.cozy`(12)，内部元素间距 `sp.compact`(8) |
| 搜索图标 | 18×18 · `s.labelSecondary` |
| 输入文字 | `t.body`（15/400/20）· `s.label` |
| Placeholder | `t.body` · `s.labelSecondary`（Placeholder 是**要被读的**，**不得用 `labelTertiary` / `labelQuaternary`**） |
| 清除按钮 | 18×18 · `s.labelSecondary`；出现/消失 `SpringKind.Crisp` + `LumioDurations.micro`(80) |
| 无障碍 | 高度 44 已满足触摸目标 ≥44 |

### 2.4.6 分段控件 Segmented（**≤4 个固定选项**）

| 项 | 规格 |
|---|---|
| 槽 | 高 32；`r.sm`(8)；底 `s.fillSecondary` |
| 分段宽 | 等分（`layoutWeight 1`） |
| 活动指示 | 高 28（槽内 2vp）；`r.xs`(4)；`s.surfaceOverlay` + `elevation.low` |
| 文字 | 选中 `t.subhead`(14/600) · `s.label` ｜ 未选中 `t.subhead`(14/400) · `s.labelSecondary` |
| 切换 | 指示块位移 `SpringKind.Crisp` + `LumioDurations.quick`(200)；不缩放整个控件 |

> 用于：播放模式、主题模式（system/light/dark）、歌词/封面切换（如后续需要）。
> **现有 SortChip 栏（6 个、可横滑）不符合分段控件的使用条件** → 走 §2.4.7 Chip。

### 2.4.7 Chip（可横滑的筛选/排序标签）

| 项 | 规格 |
|---|---|
| 容器 | 高 **32**；`r.pill`(999)｜左右 `sp.cozy`(12)｜上下 `sp.tight`(4) |
| 背景 | 默认 `Color.Transparent` + 0.5vp `s.borderSubtle` ｜ **选中 `s.accent`** ｜ 按下 `s.fillTertiary` |
| 文字 | 默认 `t.subhead`(14/400) · `s.labelSecondary`｜ 选中 `t.subhead`(14/600) · `s.labelOnAccent` |
| 间距 | chip 之间 `sp.compact`(8)；栏左右 `sp.base` |
| 按下 | `scale(pressScale.control)` |

> 现状：LocalLibrary 排序 Chip 为 `13fp / 圆角 14 / padding 14` → 改为 `t.subhead`(14) / `r.pill` / `sp.cozy`(12)。

### 2.4.8 徽章 Badge（**QualityBadge** / **CountBadge**）

| 变体 | 尺寸 | 圆角 | 背景 | 文字 | 边框 |
|---|---|---|---|---|---|
| **QualityBadge · 列表态**（浅底列表上） | `minHeight 18`，左右 `sp.hair`(2)+2 | `r.xs`(4) | `s.fillAccentSoft` | `t.caption2`(11/500) · `s.accent` | 无（改用 fill 而非描边，避免两层边界） |
| **QualityBadge · 媒体态**（播放页/封面上） | 同上 | `r.xs`(4) | `s.onMediaControlBg` | `t.caption2` · `s.onMediaPrimary` | 无 |
| **CountBadge**（计数） | `minHeight 20`，左右 `sp.compact`(8) | `r.sm`(8) | `s.fillAccentSoft` | `t.caption1`(12) · `s.accent` | 无 |
| **Dot**（极小红点） | 8×8 | `r.pill` | `s.accent` | — | 无 |

> 现状 QualityBadge：`10fp / border 1 / rgba(250,39,89,0.5) / 圆角 4 / padding 5,1` → 10fp 不在阶梯 → 改 `t.caption2`(11)；描边改 fill（更 Apple，且深色下描边会更刺眼）。

### 2.4.9 Slider（进度条 / 音量条）

| 项 | 规格 |
|---|---|
| 容器高 | **44**（可点区域；滑块视觉轨道 4vp） |
| 轨道 | 高 4；`r.xs`(2)；未播 `s.fillTertiary` ｜ 已播 `s.accent` |
| 滑块（thumb） | 拖拽时放大到 **16×16**（静止时 12×12，`r.pill`），底 `s.surfaceOverlay` + `elevation.low`；`reduceMotion` 时**不放大** |
| 命中区 | `hitTestBehavior(HitTestMode.Block)`（保留现状，避免与 Swiper/LrcView 抢手势） |
| 时间标签 | `t.caption1`(12) · `s.labelSecondary`（纯辅助数字，允许 3:1） |
| 拖拽反馈 | 拖拽中 thumb 放大 `SpringKind.Snappy` + `LumioDurations.micro`(80)；**拖动不触发 seek，抬起/End 才 seek**（保留现状 `SliderChangeMode.End/Begin`） |

### 2.4.10 选择行 SelectRow（枚举选择）

| 项 | 规格 |
|---|---|
| 结构 | 图标 24 + 标题 `t.headline` + 右侧当前值 `t.footnote` · `s.labelSecondary` + chevron 16 |
| 交互 | 点击弹出 `bindMenu`（`Menu` + `MenuItem`），**保留现有绑定方式** |
| 选中标记 | 菜单内当前项右侧 `check 16` · `s.accent`；标题 `t.bodyEmphasis` |
| 容器 | 同 GroupRow（§2.5.2） |

---

## 2.5 容器组件

### 2.5.1 Card（通用卡片）

| 项 | 规格 |
|---|---|
| 内距 | `sp.base`(16)（紧凑变体 `sp.cozy`(12)） |
| 圆角 | `r.lg`(16)（尺寸 ≥ 200vp 的大カード用 `r.xl`(24)） |
| 背景 | `s.surfaceGroupedContent` |
| 描边 | **浅色不描边**（靠留白+淡影）；深色加 0.5vp `s.borderSubtle` |
| 阴影 | `elevation.low`（浅）/ 深色下 shadow 不可见 → 由 `borderSubtle` 承接 |
| 按压 | 可点时 `pressScale.surface`(0.97) |

### 2.5.2 GroupRow（Inset Grouped 行）★ 范式 B

| 项 | 规格 |
|---|---|
| 高度 | **`minHeight(sp.rowHeight)`**（72/76/84），**禁用固定 `height`** |
| 内距 | 左右 `sp.base`；上下 `sp.cozy`(12) |
| 背景 | 行本身 **无底色**（整组共承 `s.surfaceGroupedContent`）；按下 `s.fillTertiary` |
| 分隔 | 行间 0.5vp `s.separator`，`startMargin = sp.base + 图标宽 + sp.cozy`（文字左缘对齐） |
| 图标 | 24×24 · `s.labelSecondary`· 右侧 `sp.base`
| 标题 | `t.headline`(17/600/22) · `s.label` · `maxLines 1` · Ellipsis |
| 副标题 | `t.footnote`(13/400/18) · `s.labelSecondary` · `margin top 2` |
| 尾部 | 值 `t.footnote` · `s.labelSecondary` + chevron 16 · `s.labelQuaternary` |
| 按下 | `pressScale.surface`(0.97) · `SpringKind.Snappy` · `LumioDurations.tap` |

### 2.5.3 Group 容器（分组卡）

| 项 | 规格 |
|---|---|
| 背景 | `s.surfaceGroupedContent` |
| 圆角 | `r.md`(12)（sm/md）／ `r.lg`(16)（lg） |
| 组间距 | 相邻组 `sp.loose`(24) |
| 组标题 | `t.footnote` · `s.labelSecondary` · `padding left sp.base` · `bottom sp.compact`(8) |
| 组尾注 | `t.caption1` · `s.labelSecondary` · `padding left sp.base` · `top sp.compact`(8) |

### 2.5.4 SurfaceRow（卡片型行）★ 范式 A

| 项 | 规格 |
|---|---|
| 高度 | `minHeight(sp.rowHeight)` |
| 内距 | 左右 `sp.base`；上下 `sp.cozy`(12) |
| 圆角 | `r.md`(12) |
| 背景 | `s.surfaceGroupedContent` ｜ 按下 `s.fillTertiary` ｜ 选中/播放中 `s.fillAccentSubtle` ｜ 悬停 `s.fillQuaternary` |
| 行间距 | `sp.compact`(8)（**不用分隔线**） |
| 描边 | 深色下 0.5vp `s.borderSubtle` |
| 按下 | `pressScale.surface`(0.97) |

### 2.5.5 Sheet / Dialog

| 类型 | 圆角 | 背景 | 尺寸 | 说明 |
|---|---|---|---|---|
| **Sheet（半模态）** | 系统接管顶部圆角（不改）；内容容器内部元素用 `r.md`/`r.xl` | **API 26**：`systemMaterial(ImmersiveMaterial.REGULAR)`（优先级高于 backgroundColor，**不得重复设背景色**）<br>**API 24**：`s.surfaceOverlay` | detents 按现状冻结（`[SheetSize.LARGE, SheetSize.MEDIUM]` / `['90%']` / `[SheetSize.MEDIUM]`） | dragBar / showClose 保留 |
| **Dialog（AlertDialog）** | `r.xl`(24) | `s.surfaceOverlay` + `elevation.modal` | 宽 320（lg 400）；内距 `sp.loose`(24) | 标题 `t.bodyEmphasis`；正文 `t.subhead`；按钮 `t.bodyEmphasis` |
| **Dialog · 危险确认** | 同上 | 同上 | 同上 | secondaryButton（确认）文字 **`s.danger`**；primaryButton（取消）`s.accent` 或 `s.labelSecondary` |

**Dialog 内距节奏**

```
╭──────────────────────────────╮
│                              │  ← top 24
│   移除歌曲                    │  ← t.bodyEmphasis 15/600
│   确定从本地库中移除「xxx」？  │  ← t.subhead 14 / labelSecondary，margin top 8
│                              │
│         [取消]   [移除]       │  ← margin top 24；按钮间距 12
│                              │  ← bottom 20
╰──────────────────────────────╯
```

### 2.5.6 Toast

| 项 | 规格 |
|---|---|
| 位置 | 距底 `bottomHeight + sp.cozy(12) + 56 + sp.compact(8)` = **`bottomHeight + 76`**（Toast 必须浮在悬浮胶囊之上，不被遮挡） |
| 样式 | 胶囊 `r.pill`；底 `s.inverseSurface`；高 36；左右 `sp.cozy`(12) |
| 文字 | `t.subhead`(14) · `s.labelInverse` |
| 动效 | 入场 `SpringKind.Crisp` + `LumioDurations.fade`(300)；停留 1800ms；出场 `crisp` + `fade` |
| 降级 | `reduceMotion`：仅 opacity 淡入/淡出，无位移 |
| 调用 | 沿用 `getUIContext().getPromptAction().showToast`（API 12+ 唯一正确入口） |

### 2.5.7 EmptyState 空态

```
              ┌────────┐
              │  ▢ 72  │   ← fill s.labelQuaternary · opacity 0.6
              └────────┘
           音乐库还是空的          ← t.bodyEmphasis 15/600 · s.labelSecondary
      点击右上角"导入"添加本地音频   ← t.footnote 13 · s.labelSecondary · width 70%·居中
          [  导入本地音乐  ]       ← Primary Button（可选，非必现）
```

| 项 | 规格 |
|---|---|
| 布局 | 垂直居中（`justifyContent(Center)` + `layoutWeight(1)`） |
| 图标 | 72×72 · `s.labelQuaternary` · 下方 `sp.base`(16) |
| 主文案 | `t.bodyEmphasis` · `s.labelSecondary` |
| 副文案 | `t.footnote` · `s.labelSecondary` · `maxWidth 70%` · 居中 · `margin top sp.compact` |
| 行动按钮 | 距上 `sp.loose`(24)，采用 §2.4.1 |
| **呼吸动画** | `scale 1.0 ↔ 1.08`，周期 2000ms，`Curve.EaseInOut`；**`reduceMotion` 时完全不启动**；必须带生命周期守卫（`isDisposed` / `pageVisible`，沿用 `Playlists.startBreathing` 已验证写法） |

### 2.5.8 LoadingState 加载态

| 项 | 规格 |
|---|---|
| 布局 | 垂直居中 |
| 指示器 | `LoadingProgress` 36×36 · **`s.accent`** · 下方 `sp.base`(16) |
| 文案 | `t.subhead` · `s.labelSecondary` |
| 占位加载（列表骨架） | 3–5 个 `SurfaceRow`，标题/副标题用 `s.fillSecondary` 圆角块（`r.xs`），`opacity 0.6`；**`reduceMotion` 时静态不闪烁** |

### 2.5.9 ErrorState 错误态

| 项 | 规格 |
|---|---|
| 图标 | 72×72 · `s.labelQuaternary` · `opacity 0.6` |
| 主文案 | `t.bodyEmphasis` · `s.labelSecondary` · 居中 · `maxLines 3` · 左右 `sp.loose`(24) |
| 副文案（可选） | `t.footnote` · `s.labelSecondary` |
| 行动按钮 | **Primary：「重试」** · 距上 `sp.roomy`(20) |
| 补充 | 错误态**不额外使用 `s.danger`**（错误提示不是破坏性操作；只在「无法恢复」时才降级到 `fillDangerSoft` 容器底） |

### 2.5.10 Divider 使用规则

| 场景 | 形态 |
|---|---|
| Inset Grouped 行间 | 0.5vp `s.separator`，`startMargin = sp.base + 图标 24 + sp.cozy` |
| Sheet/Dialog 内区块 | **不用分隔线**，用 `sp.loose`(24) 留白 |
| 页面级区块 | **不用分隔线**，用 `sp.section`(32) 留白 |
| 分组头与上一组之间 | 不用分隔线，用 `sp.loose`(24) |

> **Apple 核心原则：留白即分隔。分割线只在「同一容器内的连续行」出现（Inset Grouped），永不用于区块分隔。**

---

## 2.6 音乐专属组件

### 2.6.1 ★ `SongListItem`（**最高杠杆：统一组件，消灭 4 处复制**）

**外观（范式 A · SurfaceRow）**

```
┌──────────────────────────────────────────────────┐
│ ┌─────┐  曲名标题                    [无损]       │  封面 56×56 r.md(12)
│ │  ▢  │                                           │  右侧间距 12
│ │  ⓟ  │  歌手 · 专辑                              │  标题 t.headline
│ └─────┘                                           │  副行 t.footnote
└──────────────────────────────────────────────────┘
```

| 元素 | 规格 |
|---|---|
| 容器 | `minHeight(sp.rowHeight)`（sm 72 / md 76 / lg 84）；左右 `sp.base`；上下 `sp.cozy`(12)；`r.md`(12) |
| 封面 | 56×56 · `r.md`(12) · `elevation.cover` · `objectFit Cover` · `clip(true)` |
| 封面右侧间距 | `sp.cozy`(12) |
| 标题 | `t.headline`(17/600/22) · 播放中 `s.accent`，否则 `s.label` · `maxLines 1` · Ellipsis |
| QualityBadge | 标题右侧 `margin left sp.tight`(4)，仅 lossless/hires 显示（**现状判断逻辑保留**） |
| 副行 | `t.footnote`(13) · **`s.labelSecondary`(T-01)** · `maxLines 1` · Ellipsis · 距标题 `sp.tight`(4) |
| 尾部（可注入） | 队列 Sheet 的「⋮」/ 歌单详情的「移除」等；24×24 `s.labelSecondary`，触摸目标 44 |
| 播放指示 | 封面右下叠加 24×24 `r.pill` 圆片，底 `s.fillAccentMuted`，内含播放图标 16 `s.accent`；**进入/退出 `SpringKind.Crisp` + `LumioDurations.quick`(200)** |
| 播放态容器底 | `s.fillAccentSubtle` |
| 按下容器底 | `s.fillTertiary` |
| 按下缩放 | `pressScale.surface`(0.97) · `SpringKind.Snappy` · `LumioDurations.tap`(120) |
| 长按菜单 | `bindContextMenu(menuItems, ResponseType.LongPress)` —— **菜单项数组注入**，见下 |

**接口设计（给架构评审）**

| 参数 | 类型 | 说明 |
|---|---|---|
| `song` | `SongItem` | 数据源 |
| `index` | `number` | 用于错峰与 hitTest 追踪 |
| `isPlayingCurrent` | `boolean` | 是否「当前正在播放」（由外部传入，**不在组件内轮询**） |
| `onTap` | `() => void` | 点击播放 |
| `menuItems` | `SongMenuItem[]` | **菜单项数组注入**（`{ icon, label, danger?, action }`），避免布尔参数爆炸 |
| `trailingBuilder?` | `() => void` | 尾部可选 Builder |
| `variant` | `'default' \| 'compact'` | compact 用于队列 Sheet（封面 40 / `r.sm` / `rowHeightCompact`） |
| `entryIndex?` | `number` | 入场错峰序号（超出 8 按 8 计） |

> **🔴 给架构评审的前置阻塞**：仓库里存在**两个不同的 `SongItem`** —— `models/music.SongItem`（LocalLibrary / Favorites / PlaylistDetail / PlayHistory 用）与 `songdatacontroller/SongData.SongItem`（ControlAreaComponent / LyricsComponent / PlayerInfoComponent / MusicListContainer 用）。统一 `SongListItem` 只能先绑定 **`models/music.SongItem`**，并明确**不覆盖队列 Sheet 的 `MusicListContainer`**（后者走 `SongData` 且带自己的 `bindMenu` 三项语义，见 §1.5.5-⑥）。二者不得强行合并，否则会牵动 §0.4 的数据流契约。
> **`menuItems` 默认值**（保持现状五项语义不变）：播放 / 收藏(或取消收藏) / 添加到歌单 / 详细 / **删除（`danger: true`）**。
> **`PlaylistDetail` 的差异**：注入「从歌单移除」替代或追加到菜单数组；**不靠布尔开关**。
> **迁移纪律**：四个页面**逐页迁移、逐页冒烟**，禁止一次性替换（规划 R-05）。

### 2.6.2 `CoverImageView`（封面）

| 项 | 规格 |
|---|---|
| 圆角 | 按 §2.3 边长规则由外部传入 `coverRadius`（**保留现有 `@Prop` 接口**） |
| objectFit | `Cover` + `clip(true)` |
| 阴影 | `elevation.cover`（r6 / light α0.18 / dark α0.40 / y2） |
| 占位 | `$r('app.media.ic_default_cover')`，**中性灰占位，禁止随机色** |
| 按下缩放 | 现状 `0.95` 保留（封面是可点/可长按整体的一部分时不需要此套娃缩放 → **建议移除 cover 自身的 onTouch**，改由外层 `SongListItem` 统一按下，避免双层缩放） |
| 刷新机制 | 保留 `coverRefreshToken` + `src` 双观察（已验证可行）✅ |

### 2.6.3 长按上下文菜单 `SongContextMenu`

| 项 | 规格 |
|---|---|
| 容器 | 宽 **176**（菜单项数 ×44 决定高度，现状 5 项 = 220）· `r.md`(12) · `s.surfaceOverlay` + `elevation.mid` + 0.5vp `s.borderSubtle` |
| 菜单项 | 高 **44** · 左右 `sp.base` · 图标 18 · `s.label` · 图标右侧 `sp.cozy`(12) · 文字 `t.subhead`(14) · `s.label` |
| 分隔线 | 0.5vp `s.separator` |
| **危险项** | 图标与文字 **`s.danger`**；按下底 `s.fillDangerSoft` |
| 出现/消失 | `SpringKind.Crisp` + `LumioDurations.quick`(200) + `scale` 由 `0.95 → 1.0` |

### 2.6.4 迷你播放条（嵌于悬浮胶囊）

见 §1.5.2。补充：封面旋转（播放中 1.6°/帧 / 40ms）**保留**，`reduceMotion` 时停止（现状已实现 ✅）。

### 2.6.5 `ArtworkTint` 封面着色（AD-0 第 1 级）

| 字段 | 语义 | 派生规则 |
|---|---|---|
| `primary` | 主色（用于强调、进度条） | 由 `effectKit.createColorPicker` 取 `getLargestProportionColor()`（复用 `PlayerInfoComponent.getImageColor` 现有实现） |
| `container` | 容器底 | 主色做**饱和度 ↓45% + 明度归一到 [0.25, 0.55]** |
| `onContainer` | 容器上的文字 | 自动取黑或白，保证 **`container` 对比度 ≥ 4.5:1** |
| `scrim` | 叠在封面上的蒙层 | 保证歌词/文字 ≥ 4.5:1 |

| 硬约束 | 说明 |
|---|---|
| 对比度校验 | 不达标 → **回落第 3 级中性**（`ArtworkTintResolver.neutral()`），**不得回退随机色** |
| 异步 | PixelMap 解码是异步的，组件必须提供中性 fallback，**禁止取色完成前显示空白** |
| 归属 | `utils/ArtworkTint.ets`（**不进 `tokens/`**，因它 import `@kit.ArkGraphics2D`） |
| 适用 | 歌单卡、文件夹卡、播放页背景与歌词底色 |

### 2.6.6 播放控制条 `ControlAreaComponent`

```
     ① 功能行（6 件）                   ← h 44 · SpaceBetween
   [播放模式] [队列] [静音] [收藏] [1x] [睡眠]
────────────────────────────────────────
   02:13  ▓▓▓▓▓▓▓▓░░░░░░░░░░░░░  04:56     ← Slider + 时间
────────────────────────────────────────
     ② 三大键                            ← SpaceBetween
   [ ⏮ 40 ]        [ ▶ 64 ]      [ ⏭ 40 ]
```

| 元素 | 规格 |
|---|---|
| 功能行高度 | 44（含触摸目标）；图标 **24**（lg 32） |
| 功能图标色 | `s.onMediaSecondary`（默认）｜ 启用态（如收藏已选）`s.accent`｜ 按下 `opacity 0.6` |
| 「1x」胶囊 | 高 28 · `r.sm`(8) · 底 `s.onMediaControlBg` · 文字 `t.caption1` · `s.onMediaPrimary` |
| Slider | 见 §2.4.9；已播 `s.accent` / 未播 `s.onMediaTertiary` |
| 时间 | `t.caption1`(12) · `s.onMediaSecondary` · 等宽数字（`fontFamily` 保留现有 Black 系列） |
| **上/下一曲** | 40×40 · `r.pill` · 图标 24 · `s.onMediaPrimary` · 按下 `pressScale.control`(0.92) |
| **主播放键** | 64×64（lg 72）· `r.pill` · 底 `s.accent` · 图标 32 · `s.onAccent` · `elevation.accent` · 按下 `0.90`（比其它更明显，因为面积最大） |
| 整体 | 播放页内所有控件必须叠 `s.onMediaScrim` 之上，保证对比度 |

### 2.6.7 进度条（见 §2.4.9）+ 音量条

| 项 | 音量条 |
|---|---|
| 出现位置 | 播放页当前未独立提供 → **本阶段不新增**（避免范围蔓延，R-13）；如后续需要，复用 Slider 规格，未播段用 `s.fillTertiary` |

> **范围纪律**：本次不新增任何功能入口。音量控制仍由系统音量键承担。

### 2.6.8 歌词视图 `LrcView`（Canvas 手绘 · 特殊通道）

**三态配色（对应 `LrcView.drawLyricLine()` 的 `isCurrentLine` / `isUserScrolling` / `isPlayedLine` 三重分支）**

| 状态 | 当前播放行 | 已播放行 | 未播放行 |
|---|---|---|---|
| **浏览态**（用户手动滑动，在「读」） | `onMediaPrimary` 预合成 α1.0 / 无模糊 / `t.title3`(18) / 逐字歌词另有 `progressGrad` 卡拉 OK 渐变填充 | **`onMediaPrimary` 预合成 ≥4.5:1** / 无模糊 / `t.bodyEmphasis`(15) | **与「已播放行」完全相同**（颜色、透明度、字号、模糊一律一致） |
| **播放态**（自动滚动，在「听」） | 同浏览态 | `onMediaSecondary` **≥3:1** / `blur(3px)` | `onMediaTertiary` **≥3:1** / `blur(5px)` |

| 项 | 规格 |
|---|---|
| 注入方式 | **Canvas 吃不到 ArkUI 令牌**，必须**显式注入色值参数**（构造/属性传入）。这是令牌统一的特殊通道 |
| **预合成要求** | 采用**预合成不透明色**（把 α 烘进 RGB），**不再同时设 `fillStyle` alpha 与 `globalAlpha`**。现网两者相乘导致浏览态实际有效 α 仅 0.276 → 实测对比度 **1.94:1**（代码注释写的是「全部清晰」，实现把意图吃掉了） |
| **合成参照底色** | 因 `PlayerInfoComponent` 始终把 `lyricBgDark` 置为 `true`、背景渐变恒定压暗（见 `PlayerInfoComponent:351`），**参照底色确定为深色**，这是「预合成不透明色」方案成立的前提 |
| **对比度达标顺序（三步，不可颠倒）** | ① **先提文字 alpha** —— 采用预合成不透明色后，文字是不透明的，**对比度完全由颜色选择决定**，不需要靠压暗背景去凑；② **只有在文字已是不透明、仍够不到目标对比度时**，才动蒙层；③ **蒙层的本职是「统一不同封面的底色差异」，不是提供对比度** —— 这两件事不得混为一谈。<br>⚠️ 有了预合成，第 ② 步几乎不会被触发；**请勿把「压暗蒙层达标」当作首选手段**（那会把播放页压成一团黑） |
| 当前行前景 | **`s.onMediaPrimary`** |
| 非当前行前景（播放态） | **已播 `s.onMediaSecondary` / 未播 `s.onMediaTertiary`**，两者均须 ≥3:1 |
| 浏览态全部非当前行 | **`s.onMediaPrimary`**，与已播放与否**无关** |
| 译文·当前 | **`s.onMediaEmphasis`** |
| 译文·非当前 | 浏览态同 `onMediaEmphasis`；播放态 `s.onMediaTertiary` |
| **当前行字号（保留差异）** | `t.title3`(18/600/24) |
| **非当前行字号** | `t.bodyEmphasis`(15/600/20) |
| 行距 | `sp.loose`(24)（当前行上下额外 `sp.compact`(8)） |
| **★ 行槽高度固定（解决切行位移）** | **每行的槽位高度恒定为「按最大字号（`t.title3` 18）预留的高度」，与当前行是否放大无关**。当前行在槽内放大字号但不改变槽高 → **字号层级保留、位移归零**。Canvas 坐标由我们自己算，无技术障碍。<br>⚠️ 若固定槽高后单屏行数变少、观感稀疏，那是**排版密度问题，调行距解决，不得砍掉字号差异**——字号差异是唯一不消耗对比度预算的层级手段，砍掉代价太大 |
| **高亮锚定（不依赖明度）** | 当前行已天然具备四重非亮度区分：①更大字号 ②无模糊 ③独立色 ④逐字歌词的 `progressGrad` 行内渐变。**不需要额外新增左侧竖条/圆点标记**——`textAlign` 随内容类型在 `'center'`（普通歌词）与 `'start'`（逐字歌词）间切换（见 `LrcView:502` vs `522`），左侧标记在居中歌词上位置会漂移 |
| **模式切换过渡** | 浏览态 ⇄ 播放态整体明度变化必须做 **300ms 交叉淡入**（`SpringKind.Crisp` + `LumioDurations.fade`），**不得瞬间跳变**（避免「整屏歌词突然变亮/变暗」的闪烁观感） |
| 高亮切换 | `SpringKind.Crisp` + `LumioDurations.fade`(300)；**`reduceMotion` 时关闭「流光」渐变效果，仅做颜色切换** |
| 跟手 | ⚠️ **`PanGesture` 的 `onActionStart/Update/End` 增量派发逻辑一行不动**；只改绘制入参 |
| 点击跳转 | 保留 `onLineClick(index) → seek(entry.lineStartTime)`；点击与拖动必须分离（现状已做 ✅） |
| 背景判定 | 保留 `lyricBgDark`，据此选择上面的 `onMedia*` 组合；**动态背景下的对比度 ≥ 4.5:1 是硬指标** |
| ⚠️ 待实测风险 | 已改为**固定行槽高度**解决（见上），仍需在 M3 录屏复验切行时位移是否为零 |

> **设计裁决依据（为什么浏览态不再区分已播放/未播放）**：Apple Music 原生歌词同样**只区分「当前行 vs 其他行」，从不区分已播/未播**——这是对齐原生行为的选择。浏览态用户的真实需求是「我在歌词的哪一段」（一个锚点），而不是逐行的时间状态；而**当前行本身的四重标记已经提供了这个锚点**。逐行区分既不增加有效信息，又要吃掉几乎全部对比度预算（方案 1 的 5.2:1 vs 4.6:1 在快速滑动时用户根本感知不到）。

### 2.6.9 StatTriple（Mine 统计三栏）

| 项 | 规格 |
|---|---|
| 布局 | 三等分 `Row`，每格 `layoutWeight(1)` + `Column` 居中；横向 padding `sp.loose`(24) |
| 数字 | `t.title3`(18/600/24) · **`s.label`**（三格统一，**零装饰色**） |
| 标签 | `t.footnote`(13) · `s.labelSecondary`(T-01) · `margin top sp.tight`(4) |
| 隐私关闭态 | 显示 `—`（**保留现状逻辑**），色同数字 |
| 背景 | **不单独铺底**（跟随 `s.surfaceGrouped`），区块上下 `sp.loose`(24) 留白 |
| 数量变动 | 数字变化用 `SpringKind.Crisp` + opacity 交叉淡入（120ms），**不做位移动画** |

### 2.6.10 FolderCard / PlaylistCard（范式 A 的媒体变体）

| 元素 | 规格 |
|---|---|
| 封面 | 56×56 · `r.md`(12) |
| 空封面 | 容器的 `s.fillTertiary` + 单色图标 22 · `s.labelSecondary`；**禁止随机色** |
| 标题 | `t.headline` · `s.label` |
| 副标题 | 「12 首歌曲」/「3 个文件夹」· `t.footnote` · `s.labelSecondary`(T-01) |
| 着色 | 若引入 `ArtworkTint`，**只作用于封面所在的 56×56 区域与卡片左侧 3vp 强调条**，不染文字与图标 |

---

## 2.7 导航组件

### 2.7.1 悬浮胶囊底栏 `customBottomBar`

见 §1.5.2。尺寸汇总：

| 项 | 值 |
|---|---|
| 高 | 56 |
| 宽 | `92%`，`maxWidth` 520 / 560 / 680（sm/md/lg） |
| 圆角 | `r.pill`（T-03，与现状 30 几何等价） |
| 背景 | API 26：`systemMaterial(ImmersiveMaterial.REGULAR)`；API 24：`s.surfaceOverlay` |
| 描边 | 0.5vp `s.borderSubtle`（深浅都加，深色更明显） |
| 阴影 | `elevation.high`（r22 / light α0.18 / dark α0.45 / y8） |
| 内距 | 左右 `sp.compact`(8) |
| 底距 | `bottomHeight + sp.cozy`(12) |
| 内容区底部避让 | `bottomHeight + sp.cozy(12) + 56 + sp.compact(8)` = **`bottomHeight + 76`**（现状 `bottomHeight + 16` 不足以保证最后一项完全露出，此处补到 76） |

> ⚠️ 现状 `Layout` 的内容 padding 是 `bottomHeight + 16`，若列表最后一项正好在胶囊上方会被压住。本次修正为 **`bottomHeight + 76`**。

### 2.7.2 Tab 项

| 项 | 规格 |
|---|---|
| 结构 | `Column(space: 4)`：图标 22 + 文案 `t.caption2`(11) |
| 容器 | `layoutWeight(1)` · 高 100% · `justifyContent(Center)` · ≥44 宽 |
| 图标色 | 选中 `s.accent` ｜ 未选中 `s.labelSecondary`(T-01) |
| 文案 | 选中 `t.caption2`(11/**500**) ｜ 未选中 `t.caption2`(11/**400**) |
| 切换动效 | 颜色/字重 `SpringKind.Crisp` + `LumioDurations.quick`(200) |
| 按下 | `scale(pressScale.control = 0.92)` · `SpringKind.Snappy` · `LumioDurations.tap` |
| 图标实现 | **改用位图资源**（替换 `SymbolGlyph`，规避 R-9） |

### 2.7.3 `SubPageHeader`（二级页标准头）

见 §1.5.13-①。汇总：

| 项 | 值 |
|---|---|
| 高 | 内容 44 + `topHeight` + `sp.cozy`(12) 上 + `sp.cozy`(12) 下 |
| 内距 | 左右 `sp.base` |
| 返回箭头 | 24×24 · `s.label` · 触摸目标 44×44 · `pressScale.control` |
| 标题 | `t.title2`(20/600/25) · `s.label` · `layoutWeight(1)` · 左侧 `sp.cozy`(12) |
| 右侧槽 | 24×24 预留（保持两侧对称，标题居中感） |

### 2.7.4 播放页透明导航栏 `TopAreaComponent`

| 项 | 规格 |
|---|---|
| 高度 | 44 + `topHeight` |
| 内距 | 左右 `sp.base` |
| 图标 | 24×24 · `s.onMediaPrimary` · 触摸目标 44 |
| 背景 | 滚动/显式需要时叠由 `s.onMediaScrim` 向透明渐变的 scrim 层 |

---

## 2.8 深浅色差异总表

| 组件部位 | 浅色令牌 | 深色令牌 | 差异要点 |
|---|---|---|---|
| 页面底 | `surfaceGrouped` `#F2F2F7` | `surfaceGrouped` `#000000` | 深色**用纯黑做底**，卡片比页面**亮一档** |
| 卡片/行 | `surfaceGroupedContent` `#FFFFFF` | `surfaceGroupedContent` `#1C1C1E` | 层级关系在深色下反转（页暗卡亮） |
| 卡内槽/搜索框 | `backgroundTertiary` `#FFFFFF` | `backgroundTertiary` `#2C2C2E` | 深色下槽比卡更亮，形成第三层 |
| 浮层/Sheet | `surfaceOverlay` `#FFFFFF` | `surfaceOverlay` `#1C1C1E` | — |
| 主文字 | `label` `#1C1C1E`（17.0:1） | `label` `#FFFFFF`（21.0:1） | AAA |
| 次要文字（正文级） | `labelSecondary` **P1 起 ≥4.5:1** | `labelSecondary` **≥4.5:1** | 承载信息；取值提升由架构师在 **P1** 落地（T-01 裁决），**本文不改选择器** |
| 辅助文字 | `labelTertiary` | `labelTertiary` | 仅时间戳/计数/占位；**不得承载需读取的信息** |
| 分隔线 | `separatorOpaque` `#C6C6C8` | `separatorOpaque` `#38383A` | 深色下不能用浅色分割线（会成刺眼亮线） |
| 描边（替阴影） | `borderSubtle` `rgba(0,0,0,0.06)` | `borderSubtle` `rgba(255,255,255,0.08)` | **深色用 hairline 描边替代阴影** |
| 品牌色 | `accent` `#FA2759` | `accent` `#FA2759` | **不随主题变化**（保持品牌识别；在 #000 上 4.9:1 ✅） |
| 阴影 | `elevation.*` light α | `elevation.*` dark α（提高） | 浅色阴影柔和、深色几乎不可见 → 靠 `borderSubtle` |
| 毛玻璃 | `glass.*.fill` 白系 | `glass.*.fill` `#1C1C1E` 系 | 双套；API 24 必须有 fill 兜底 |
| 媒体层 | `onMedia*` 黑系 | `onMedia*` 白系 | **语义是「叠在封面上」而非主题色** |
| Toast | `inverseSurface` `#1C1C1E` + `labelInverse` 白 | `inverseSurface` `#F2F2F7` + `labelInverse` 黑 | 反色 |

**三条铁律**

1. **避免纯白（#FFFFFF）作为大面积背景出现在深色模式**；反之亦然。唯一例外是 `surfaceGroupedContent` 在浅色下的 `#FFFFFF`（这是 Apple 的规范语义，不是"随手写的白"）。
2. **深色下不用 #FFFFFF 做文字**（极端对比造成光晕）→ 用 `label`(#FFFFFF) 之外的次级字。
3. 任何新颜色必须**同时给出浅/深两套值**并加进 `LumioSemantic`，否则视为架构违规。

---

## 2.9 无障碍规格

| # | 要求 | 数值 / 做法 |
|---|---|---|
| A-1 | 触摸目标 | **≥ 44×44 vp**（lg ≥ 48）；不足时用 `padding` 或 `hitTestBehavior` 补足，**不得靠放大图标** |
| A-2 | 列表行高 | **禁用固定 `height`**，一律 `minHeight` + padding（R-11） |
| A-3 | 对比度 | 正文 ≥ 4.5:1；≥ 20fp 或纯装饰 ≥ 3:1；`labelTertiary`/`labelQuaternary` **禁止承载信息** |
| A-4 | 大字体 | 系统最大字号下逐页走查；所有多行文本允许换行，`maxLines 1` 仅用于单行列表标题 |
| A-5 | `accessibilityText` | 所有**纯图标按钮**必填（播放/暂停/上一首/下一首/收藏/返回/更多/桌面卡片三键） |
| A-6 | 状态播报 | 播放/暂停、收藏、播放模式切换需有无障碍标签更新 |
| A-7 | 降低动态效果 | 全覆盖，见 §3.6；**功能性反馈不可去除** |
| A-8 | 单位 | 字号一律 `fp`（跟随系统缩放）；行高/间距一律 `vp`（不塌陷） |
| A-9 | 桌面卡片 | 封面、进度、曲名补 `accessibilityText` |
| A-10 | 颜色不是唯一线索 | 「正在播放」必须同时有：容器底 `fillAccentSubtle` + 播放指示徽标 + （可选）标题 `accent`；**不能只靠标题变红** |

---
---

# 第三部分：关键交互说明

## 3.1 动效令牌选用规则

**裁决（AD-2）：默认 `crisp`（ζ=1.0，临界阻尼，绝不过冲）；只有带惯性的手势才允许 `bouncy`（10.7% 过冲）。**

| 场景 | 弹簧 | 时长 | 位移/缩放 | 备注 |
|---|---|---|---|---|
| 控件显隐、图标态切换 | `SpringKind.Crisp` | `LumioDurations.micro`(80) / `quick`(200) | 允许 | 默认档 |
| **点按/按压反馈** | `SpringKind.Snappy` | `LumioDurations.tap`(120) | `pressScale` | 几乎无回弹的清脆感 |
| 列表项 / 卡片入场 | `SpringKind.Soft` | `LumioDurations.fade`(300) | 允许（y +20～30） | 可带错峰 |
| 页面转场 / Sheet 展开 | `SpringKind.Gentle` | `LumioDurations.sheet`(360) / `page`(400) | 允许 | 大面积、慢 |
| **拖拽释放 / 滑块吸附 / 下拉关闭 Sheet** | `SpringKind.Bouncy` | — | 允许 | **唯一允许明显过冲的场合**（有惯性输入） |
| **一镜到底共享元素** | `SpringKind.Hero` | — | `geometryTransition` | **沿用现网值 (0,1,342,38)，保持不变** |
| 错峰延时 | — | `LumioTheme.stagger(index)` | — | **上限 8 项**，超出按 8 计 |

**三条禁止**

1. ❌ 列表项出现后用 `bouncy` —— 滚动后会出现轻微抖动。
2. ❌ `SheetMode`／转场用 `snappy` —— 大面积位移下会显得急躁。
3. ❌ 任何地方直写 `Curve.EaseOut` / `springInline` 字面量 —— 一律走 `LumioTheme.curve()`。

## 3.2 转场

### 3.2.1 页面进出

| 类型 | 进入 | 退出 | 对称要求 |
|---|---|---|---|
| `pushPathByName` 二级页 | 系统默认 nav transition（Hds 接管）｜内容区 `opacity 0→1` + `translate x +32→0`，`SpringKind.Gentle` + `page`(400) | 反向，**完全对称** | ✅ 从哪进从哪出 |
| Sheet 内二级（Settings → Category → SubPage） | `translate x +32→0` + `opacity`，当前实现用 `(0,1,360,36)`→ 改 `SpringKind.Gentle` | `translate x 0→+32`，同曲线 | ✅ 保留现有 `animateTo` 包裹结构 |
| PlayerPage 入场 | `opacity 0→1` + `scale 0.98→1`，`SpringKind.Soft` + `fade`(300) | `onWillHide` 置 `entered=false`，与入场**完全反向对称** | ✅ 保留 `onWillShow`/`onWillHide` 配对 |

### 3.2.2 一镜到底（**最高优先级，不得破坏**）

| 阶段 | 说明 |
|---|---|
| 触发 | 点击悬浮胶囊播放键（`Layout.openPlayer`）/ 列表项播放（`LocalLibrary.playSong`） |
| 中间态 | `animateTo({ curve: LumioTheme.curve(SpringKind.Hero) }, () => pushPathByName('PlayerPage'))`；`geometryTransition('player_cover')` 接管封面从 48×48 到全宽封面**与/或从列表封面到播放页封面**的连续变形 |
| 结束态 | 播放页封面就位，`entered=true` 触发内容淡入 |
| 对称性 | **进入与退出必须包同一个弹簧**。`Layout.openPlayer()` 与 `PlayerPage.back()` 现状均为 `(0,1,342,38)` ✅ **禁止单边修改** |
| **降级态** | `reduceMotion = true`：**降级为 120ms 纯淡入淡出，不做共享元素位移**（避免大位移引发不适） |
| **风险** | 🔴 R-03：两端封面圆角/尺寸不同步 → 跳变。**纪律：改任意一端圆角必须同 PR 改另一端，并录屏对比。** 本文已把两端统一为 `r.lg`(16) |

### 3.2.3 Sheet 展开 / 收起

| 阶段 | 表现 |
|---|---|
| 触发 | `bindSheet` 的 `$$` 双向绑定置 true |
| 中间态 | 系统接管 detents 定位（`dragBar: true` 的 Sheet 支持拖拽） |
| **拖拽跟手** | 手指位移 **1:1** 映射到 Sheet 位置（系统行为）；跟手期间**不做任何插值追赶**，位移即时生效 |
| **释放判定** | 由**位移**与**释放速度**共同决定落点：超过阈值 → 吸附到下一 detent；不足 → 回弹到当前 detent。回弹用 `SpringKind.Bouncy`（唯一合适的场合） |
| **投影落点** | Sheet 抬起时投影实时加深（`elevation.modal` 按展开比例插值），收起时回落 |
| 降级态 | `reduceMotion`：**时长压到 200ms**、回弹曲线换 `SpringKind.Crisp`（无过冲），拖拽跟手保留（那是直接操纵，不是装饰动效） |
| ⚠️ 不变量 | `onDisappear` 才复位 `sheetKind`（否则关闭动画期间渲染空白页）；`pendingOnboarding` 衔接顺序不变 |

### 3.2.4 从哪进从哪出（**对称原则**）

| 元素 | 进 | 出 |
|---|---|---|
| 共享元素封面 | 小 → 大 | 大 → 小，**同一条 `Hero` 曲线** |
| 列表 → 详情 | 右进 | 右出，不得左出 |
| Sheet | 下上 | 下下（同 detents 路径），**不得淡出** |
| 上下文菜单 | 由按压点 `scale 0.95→1.0` 展开 | 收回同源，`pressScale` 反向 |

## 3.3 手势

### 3.3.1 按下反馈（**Down 即时**）

```
onTouch(Down)   → 立即 scale(pressScale) + 底色 fillTertiary   ← 不等 Up
onTouch(Up/Cancel) → scale 回 1.0 + 底色回 tokens
```

| 规则 | 说明 |
|---|---|
| **必须在 `TouchType.Down` 触发** | 现状所有 `onTouch` 已是 Down/Up 配对 ✅ 保留；**禁止改成只监听 Up** |
| 缩放比 | `pressScale.surface` 0.97（列表/菜单/卡片/歌单卡）<br>`pressScale.control` 0.92（图标按钮/Tab/Chip/播放键）<br>主播放键 0.90（面积最大，需更强反馈）— **T-02 已批准，归属 `LumioMotionSpec`** |
| 曲线 | `SpringKind.Snappy` + `LumioDurations.tap`(120) |
| `Cancel` | **`TouchType.Cancel` 必须与 Up 同等处理**（现网部分组件遗漏 → 列表滚动时按下态卡住） |
| 降级 | `reduceMotion`：保留反馈，但**只做 opacity 0.7，不做 scale** |

### 3.3.2 拖拽 1:1 跟随

| 元素 | 规则 |
|---|---|
| Slider thumb | 位移 → value **即时映射**（不插值）；抬起/End 才 `seek`（**保留现状**） |
| Sheet dragBar | 手指位移 1:1 映射位置；释放按位移+速度选 detent |
| 歌词 `PanGesture` | ⚠️ **增量派发逻辑一行不动**；只保证拖拽期间不触发 seek（`onActionUpdate` 内只位移不 seek），避免抖动 |
| 列表项滑动删除（Swipe to delete） | ❌ 本项目无此功能，**本次不引入**（范围纪律 R-13，不得顺手加功能） |

### 3.3.3 边界橡皮筋

| 场景 | 规则 |
|---|---|
| 列表滚动到边界 | 用系统 `Scroll`/`List` 默认 `edgeEffect(EdgeEffect.Spring)`（ArkUI 默认即为弹性），**不自定义** |
| Sheet 拖过头 | 由系统 detents 机制处理，**不自定义回弹** |
| 禁止 | 不要自实现 `animateTo` 模拟橡皮筋（会与系统手势冲突、且 `.animation()` 与显式动画同时接管同一属性会导致跳变） |

> ⚠️ **ArkUI 陷阱**：同一属性**不得同时**被显式 `animateTo` 与属性动画 `.animation()` 接管。现网 `Playlists.startBreathing` 的注释已明确此坑 ✅ 沿用。

## 3.4 关键交互卡片

> 每个交互给出：**触发条件 → 中间态 → 结束态 → 降级态（reduceMotion）**

### K-01 播放一首歌（列表点击）
- **触发**：点击 `SongListItem`
- **中间态**：Down 即 `scale 0.97` + `fillTertiary`；抬起回弹（`Snappy`/120ms）并执行 `playFromList`
- **结束态**：该行容器底 → `fillAccentSubtle`，标题 → `s.accent`，封面右下出现播放指示徽标；悬浮胶囊封面更新并开始旋转
- **降级**：保留按压反馈（降为 opacity 0.7）；封面旋转**停止**

### K-02 一镜到底进入/退出播放页
- 见 §3.2.2
- **降级**：120ms 淡入淡出，无共享元素位移

### K-03 收藏 Toggle
- **触发**：播放页心形 / 长按菜单「收藏」/ `AVSession` 指令
- **中间态**：图标 `heart → heart_fill`，`SpringKind.Snappy` + `fade`(300)；同时图标色 `onMediaSecondary → accent`
- **结束态**：Toast「已收藏 / 已取消收藏」（1800ms）
- **降级**：保留颜色切换，去掉缩放；Toast 淡入无位移
- **反馈层级**：这是**功能性状态变更**，必须保留即时视觉反馈 + Toast

### K-04 长按上下文菜单
- **触发**：长按 ≥ 500ms（`ResponseType.LongPress`）
- **中间态**：菜单由按压点以 `scale 0.95→1.0` + `opacity 0→1` 展开（`Crisp`/200ms）；背景自动降暗 `s.scrim`
- **结束态**：选中某项 → 菜单 200ms 收回后才执行动作（**先收后做**，避免视觉叠加）
- **降级**：无错峰、无缩放，直接 120ms 淡入

### K-05 Sheet 展开/收起（含拖拽）
- 见 §3.2.3
- **降级**：360ms → 200ms；回弹 `Bouncy` → `Crisp`；**拖拽跟手保留**

### K-06 歌曲导入（Picker）
- **触发**：点击「导入」Pill
- **中间态**：Pill `scale 0.92` 回弹 → 系统 `DocumentViewPicker` 接管 → 返回后页面进入 `LoadingState`（`LoadingProgress` 36 `s.accent` +「正在导入...」）
- **结束态**：成功 → Toast「已导入 N 首音乐」；列表以 `Soft` + 错峰入场（≤8 项）；失败 → `ErrorState` +「重试」
- **降级**：列表入场无错峰、无位移，仅 120ms 淡入

### K-07 播放模式 / 倍速 / 睡眠
- **触发**：点击对应图标
- **中间态**：图标 `pressScale.control` + `Snappy`/120ms；Toast 显示当前模式/倍速文本
- **结束态**：倍速胶囊文字更新（`1x` → `1.5x`），`Crisp`/80ms crossfade
- **降级**：仅 opacity 切换

### K-08 Slider 拖动（进度/歌词）
- **触发**：`Slider` 按下并开始拖动
- **中间态**：thumb 12 → 16（`Snappy`/80ms）；轨道已播段实时跟随手指；**拖拽过程中不 seek**
- **结束态**：`SliderChangeMode.End` → `seek(value)`；thumb 缩回 12
- **降级**：**thumb 不放大**，其它一致

### K-09 列表项入场错峰
- **触发**：页面出现 / 数据刷新
- **中间态**：`translate y 30→0` + `opacity 0→1`，延时 `min(index, 8) × 60ms`，`SpringKind.Soft` + `fade`(300)
- **结束态**：全部就位
- **降级**：延时 = 0，且**位移禁用**，仅 120ms 淡入

### K-10 Tab 切换
- **触发**：点击胶囊 Tab
- **中间态**：`scale 0.92`（Down 即时）→ 抬起回弹并执行 `changeIndex`
- **结束态**：图标/文字色 — 选中 `accent`，未选中 `labelSecondary`；字重 500/400 切换，`Crisp`/200ms
- **降级**：保留颜色与字重切换，**去掉 scale**

### K-11 删除（危险操作）
- **触发**：长按菜单「删除」/ Management body「移除」/ 歌单「删除」
- **中间态**：菜单项按下底 `fillDangerSoft` → 菜单收回 → 弹 `AlertDialog`（secondaryButton 文字 `s.danger`）
- **结束态**：确认 → 列表项以 `Crisp` 移除（高度坍塌 200ms）+ Toast；取消 → 仅收回
- **降级**：无坍塌动画，直接重绘列表 + Toast

### K-12 桌面卡片播控
- **触发**：卡片上播放/上一首/下一首按钮（`postCardAction`）
- **中间态**：按钮 `scale 0.92` → 回弹（卡片进程渲染能力有限，仅做轻反馈）
- **结束态**：图标 `play ↔ pause` 切换 + `accessibilityText` 更新；进度由主应用每秒推送
- **降级**：仅图标替换，无动效

## 3.5 多模态反馈（触感 / 声音）

Apple 的三条因果性原则：**因果性（Causality）· 和谐性（Harmony）· 效用性（Utility）**。

| 时刻 | 反馈 | 原则 | 必要性 |
|---|---|---|---|
| 按下任意可点元素 | 视觉：即时 `scale` + `fillTertiary`（Down 触发） | 因果性 | **必需** |
| 状态成功变更（收藏/删除/清空/导入完成） | Toast 文本 | 效用性 | **必需** |
| 切换到下一个离散状态（播放模式、倍速档位） | 建议：**轻触感**（`vibrator` 的 `presetWave`） | 和谐性 | **可选**（需权限，可能触发 R-9 权限最小化约束 → **本阶段不引入**） |
| 拖动 Slider 越过整数刻度 | 视觉（数值跳变） | — | 不需要触感 |
| 错误（导入失败/加载失败） | ErrorState + 文案 | 效用性 | **必需** |
| 长时间操作 | LoadingState | 效用性 | **必需** |

> ⚠️ **范围纪律（R-9）**：为本次视觉重设计**不得新增任何权限**。因此**不引入振动反馈**（`ohos.permission.VIBRATE`）。本应用无声效资产，也**不新增音效**。
> 反馈策略收敛为：**视觉即时反馈（Down）+ Toast/状态 + 三态（空/加载/错误）**。这已经覆盖了 Apple 三原则中的因果性与效用性。

## 3.6 `reduceMotion` 全量降级表（S-6 验收依据）

| # | 动效 | 正常 | **reduceMotion = true** |
|---|---|---|---|
| 1 | 封面旋转（40ms 定时器，1.6°/帧） | 旋转 | **完全停止**（现网已实现 ✅） |
| 2 | 列表错峰入场 | `delay index×60`（上限 8） | **delay = 0**，且**位移禁用**，仅 120ms 淡入 |
| 3 | 空态呼吸动画 | 循环 `scale 1.0↔1.08` / 2000ms | **完全不启动**（带生命周期守卫） |
| 4 | 按压回弹 | `scale` + 弹簧 | **保留**（改为仅 `opacity 0.7`，无 scale） |
| 5 | 一镜到底转场 | `Hero` 共享元素 | **120ms 纯淡入淡出**，无共享元素位移 |
| 6 | Sheet 弹出/回弹 | 360ms 弹簧 + `Bouncy` 回弹 | **200ms**，`Bouncy` → `Crisp`（无过冲）；**拖拽跟手保留** |
| 7 | Splash logo 缩放 | 700ms `EaseOut` 缩放+淡入 | **仅 300ms 淡入**（现状未受控 ⚠️ 需补） |
| 8 | PlayerPage 页面转场（`entered`） | `Soft` 缩放淡入 | **仅淡入**，无 scale |
| 9 | 歌词高亮切换 | 颜色 + 「流光」渐变过渡 | **关闭流光**，仅颜色切换（≥4.5:1 仍保证） |
| 10 | Slider thumb 拖拽放大 | 12 → 16 | **不放大** |
| 11 | 列表项删除坍塌 | 高度坍塌 200ms | **无坍塌**，直接重绘 |
| 12 | 统计数字变化 | 交叉淡入 | 直接替换 |

> **原则：装饰性动效可去除，功能性反馈必须保留。** 用户必须始终知道「点击已生效」。

---

## 附录 A · 令牌引用速查

```arkts
// 每个用到颜色的 @Component 都必须声明（漏声明 = 主题切换不刷新，静默缺陷 R-3）
@StorageProp('isDark') isDark: boolean = false;
@StorageProp('currentBreakpoint') bp: string = 'sm';

// ✅ 普通方法（不是 get 访问器！get 会被状态变换器整段丢弃 → 运行时崩溃）
private s(): LumioSemantic  { return LumioTheme.semantic(this.isDark); }
private sp(): LumioSpace    { return LumioTheme.space(this.bp); }
private t(): LumioType      { return LumioTheme.type(this.bp); }

// ✅ build() / @Builder 首条语句必须是 UI 组件；令牌经 @Builder 形参传递
@Builder
private body(s: LumioSemantic, t: LumioType, sp: LumioSpace) {
  Column() {
    Text(this.song.title).fontColor(s.label).fontSize(t.headline.size)
  }.padding({ left: sp.base })
}

build() {
  Row() { this.body(this.s(), this.t(), this.sp()) }
    .backgroundColor(this.s().surfaceGroupedContent)
    .borderRadius(LumioTheme.radius().md)
}

// ✅ 动效（reduce 由 LumioTheme 内部读 SettingsStore，调用方无需关心）
.animation({ duration: LumioTheme.duration(LumioDurations.tap),
             curve:     LumioTheme.curve(SpringKind.Snappy) })
```

## 附录 B · 每个页面 PR 的自检清单

- [ ] 页面根节点背景已改为 `s.surfaceGrouped`
- [ ] 该页**所有**卡片/列表项底色已改为 `s.surfaceGroupedContent`（无遗漏、无残留 `surfaceRaised`）
- [ ] 搜索框/输入框底已改为 `s.backgroundTertiary`
- [ ] 浅色下可分辨：页面底浅灰、卡片纯白、分隔线可见
- [ ] 深色下可分辨：页面底纯黑、卡片深灰、0.5vp `s.borderSubtle` 描边可见
- [ ] 无「卡片与页面同色」的元素
- [ ] 所有列表/菜单行为 `minHeight` + padding，**无魔法数字 `height(60/64/72/76)`**
- [ ] 所有圆角 ∈ {0,4,8,12,16,24,999}
- [ ] 所有间距 ∈ {0,2,4,8,12,16,20,24,32,40,48,64}
- [ ] 所有字号 ∈ 排版 12 阶，且**成对带行高**
- [ ] 所有可点元素触摸目标 ≥ 44×44；纯图标按钮有 `accessibilityText`
- [ ] `onTouch` 在 `TouchType.Down` 触发按压，且 **`Cancel` 与 `Up` 同等处理**
- [ ] 无意外的装饰性配色（按 §2.12 三级优先序逐项自查）
- [ ] `reduceMotion = true` 时逐屏走查通过（§3.6 十二项）
- [ ] 浅色 + 深色两张截图，且同时含「页面底 / 卡片 / 分隔线」
- [ ] 未触及 §0.4 的冻结契约

## 附录 C · 令牌裁决汇总（**已全部裁决，无未决项**）

| ID | 议题 | 裁决 | 落地 | 状态 |
|---|---|---|---|---|
| **T-01** | AA 达标的次级文字色 | **不新增令牌，一律用 `labelSecondary`**（架构 v1.2 已修正层级倒挂；新增第五档会破坏单调性） | 取值提升由架构师**从 P4 提前到 P1** | ✅ 已裁决 |
| **T-02** | 按压缩放比例常量 | `pressScale.surface = 0.97` / `pressScale.control = 0.92`（主播放键 `0.90`） | **`LumioMotionSpec`** | ✅ 已批准 |
| **T-03** | 悬浮胶囊圆角 30 | 改 **`r.pill`**（几何等价，零视觉变化） | `Layout.customBottomBar`；几何论证见 §0.3 保留块 | ✅ 已批准 |
| **T-04** | 图标尺度 `icon.*` | **不补令牌**，Component 层用具体 vp 数值 | — | ✅ 已批准 |

## 附录 D · 设计决策记录（ADR 摘要）

| # | 决策 | 判据 | 章节 |
|---|---|---|---|
| ADR-1 | 卡片型 / 分组型**两种**列表范式并存，按「内容性质」分配 | Apple 两种 Inset Grouped 形态均有原生出处；禁止出现第三种 | §1.4 |
| ADR-2 | 一镜到底两端封面统一 `r.lg`(16) | 现网 14/12/16 三值并存是转场跳变根因（R-03）；两端必须同 PR 改 | §2.3 / §3.2.2 |
| ADR-3 | **浏览态歌词不再区分已播/未播** | **Apple Music 原生只区分「当前行 vs 其他行」，该区分在原生里不存在** —— 对齐原生优先于自制权衡 | §2.6.8 |
| ADR-4 | 否掉「细微明度差」区分已播/未播 | 吃掉几乎全部对比度预算换 5.2:1 vs 4.6:1，快速滑动时用户感知不到，性价比最差 | §2.6.8 |
| ADR-5 | 当前行**不新增**左侧竖条/圆点标记 | `textAlign` 随内容类型在 `'center'`/`'start'` 切换，左侧标记会漂移；且当前行已有四重非亮度区分 | §2.6.8 |
| ADR-6 | 歌词切行位移用**固定行槽高度**解决，不砍字号差异 | 字号差异是唯一不消耗对比度预算的层级手段；预留槽高后零位移；稀疏则调行距 | §2.6.8 |
| ADR-7 | 装饰性分类配色**归零**，三级优先序 | AD-0 第 3 条；`Mine` 与 `SettingsCategory` 为首要整治对象 | §1.5.4 / §1.5.12 |
| ADR-8 | 多模态反馈**不引入振动/音效** | R-9 权限最小化；靠「即时视觉反馈 + Toast + 三态」覆盖因果性与效用性 | §3.5 |
| ADR-9 | 遇到取舍**先查原生怎么做**，再谈权衡 | team-lead 指令：对齐原生是风险最低路径，不需要我们发明 | §0.2-7 |

---

*本文档由蓝绘心（鸿蒙 UI/UX 设计师）产出，作为 Lumio Music Apple 风格重设计的视觉与交互唯一权威规范。*
*令牌字段名取自 `docs/UI重设计_设计令牌架构.md` v1.1（高见远）；范围与契约取自 `docs/UI重设计_范围与规划.md` v1.0（计谋远）。*
*本阶段未改动任何 `.ets` 代码文件。*
