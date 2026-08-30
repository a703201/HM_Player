# Lumio Music — 产品需求文档（PRD）

| 项 | 值 |
|---|---|
| 产品名称 | Lumio Music（灯屿音乐） |
| 应用包名 | `com.Lumio.music`（`AppScope/app.json5` 实际值）⚠️ 与文档常用写法 `com.lumio.music` 大小写不一致，见 **OQ-01** |
| 当前版本 | `versionName 2.4.0` / `versionCode 2040000` |
| 许可证 | Apache-2.0（版权主体：何宇翔） |
| 目标平台 | HarmonyOS NEXT，API 24 / HarmonyOS 6.1.1（compile = compatible = target） |
| 技术栈 | ArkTS（Stage 模型）+ C++ NAPI（BiSheng）+ MediaKit / AVSessionKit |
| 设备范围 | 手机（`deviceTypes: ["phone"]`），含折叠屏形态；平板为规划预留 |
| 文档角色 | 鸿蒙软件项目经理「计谋远」 |
| 文档状态 | **v1.0 待评审** |
| 关联文档 | `docs/review_security.md`、`docs/review_compliance.md`、`docs/review_architecture.md`、`docs/review_design.md`、`README.md`、`CHANGELOG.md` |

> **文档定位**：本 PRD 基于已完成的**全链路体检**（安全 / 合规 / 架构 / 设计四份报告）编写，描述的是一个**功能已基本落地、正处于「上架前合规整改」阶段**的产品。因此本文档同时承担三个作用：① 沉淀产品定义与需求基线（对外可评审）；② 明确已交付能力的验收标准（对内可回归）；③ 汇总体检发现的风险与整改优先级（可排期）。
>
> **阅读约定**：功能需求中标注 `✅ 已交付` 的条目为现有实现，其验收标准（AC）用于**回归测试**；标注 `🟡 待补齐` / `⬜ 规划中` 的条目为后续里程碑范围。

---

## 目录

1. [产品概述](#1-产品概述)
2. [目标用户与典型使用场景](#2-目标用户与典型使用场景)
3. [目标设备与适配策略](#3-目标设备与适配策略)
4. [信息与功能架构](#4-信息与功能架构)
5. [功能需求（FR）](#5-功能需求fr)
6. [非功能需求（NFR）](#6-非功能需求nfr)
7. [视觉与设计规范方向](#7-视觉与设计规范方向)
8. [数据模型与持久化](#8-数据模型与持久化)
9. [里程碑与版本规划](#9-里程碑与版本规划)
10. [风险与开放问题](#10-风险与开放问题)
- [附录 A：术语表](#附录-a术语表)
- [附录 B：需求索引](#附录-b需求索引)
- [附录 C：文档修订记录](#附录-c文档修订记录)

---

## 1. 产品概述

### 1.1 一句话简介

**Lumio Music 是一款 HarmonyOS NEXT 原生的纯离线本地音乐播放器**：用户把自己拥有的音乐文件导入应用沙箱，即可获得无账号、无广告、无埋点、不上传的精致听歌体验，并完整接入鸿蒙系统级能力（锁屏媒体控制、桌面卡片、投播、后台播放）。

### 1.2 产品定位

在「在线流媒体全面主导」的市场里，Lumio Music 选择一条明确的差异化路线：**Local-first（本地优先）+ Privacy-first（隐私优先）+ 系统原生体验**。

它服务的不是"想听新歌"的用户，而是**"已经拥有一批音乐文件、且希望它们被认真对待"**的用户——无损收藏者、只想听自己歌单的人、以及对"播放器要联网、要登录、要推荐"感到疲惫的人。

产品由三根支柱支撑：

| 支柱 | 含义 | 具体体现 |
|---|---|---|
| **本地私有** | 数据不出机、不建账号、不做画像 | 无云端、无账号体系、无第三方 SDK、无应用层网络请求；曲库/收藏/歌单/历史/设置 100% 存于应用沙箱 |
| **体验精致** | 本地播放器也可以有旗舰级观感 | 「一镜到底」共享元素转场、封面取色光感背景、双语歌词（原文+翻译）与逐字高亮、明暗主题、错峰入场动效 |
| **系统原生** | 深度融入鸿蒙，而非移植一个通用 App | AVSession 锁屏/通知媒体控制、桌面播控卡片（含按钮回控）、Cast+ 投播、长时任务后台播放、数据备份、一多断点响应式 |

### 1.3 产品愿景

> 让每一个「本地音乐文件夹」都值得一个体面的播放器——不需要注册，不需要联网，不需要交出数据，就能获得鸿蒙生态最完整的听歌体验。

中期目标是成为 **HarmonyOS 生态内「离线本地播放器」品类的参考实现**：既是可日常使用的产品，也是一份可被学习的、符合 HarmonyOS Design 与 ArkTS 工程规范的开源样板（Apache-2.0）。

### 1.4 设计原则

产品与技术决策发生冲突时，按以下顺序裁决：

1. **隐私不可交易**：任何功能不得以"数据出机"为代价。若某能力必须联网，必须做到用户主动触发 + 如实披露 + 范围最小（当前唯一符合此条的是"局域网投播"）。
2. **权限最小必要**：不申请用不到的权限；能用 Picker 授权解决的，绝不申请媒体库全盘权限。
3. **系统能力优先于自研**：优先使用 HarmonyOS 官方 Kit 与 HarmonyOS Design 标准组件，仅在系统无对应能力时自研（如 C++ 元数据解析）。
4. **单一真源**：同一份数据只有一个权威写者（`SongItem` 实体、`MusicStore` 曲库、`AudioRendererController` 队列、`ThemeManager` 主题）。
5. **静默降级而非报错阻断**：缺封面、缺歌词、解析失败等非致命场景，一律降级到默认表现，不打断听歌主流程。

### 1.5 非目标（Non-goals）

明确**不做**，用于抵御范围蔓延；每条都附不做的理由：

| 非目标 | 理由 |
|---|---|
| 在线曲库 / 流媒体播放 / 音乐搜索下载 | 与"离线本地"定位冲突，且涉及版权与内容审核，超出产品边界 |
| 账号体系 / 云同步 / 跨设备歌单同步 | 需要服务端与用户身份，直接违背"隐私优先"支柱与"数据不出机"承诺 |
| 社交功能（分享、评论、听歌排行榜） | 需要出网与用户标识，且非目标用户的核心诉求 |
| 广告 / 埋点 / 第三方统计 SDK | 违背隐私承诺；当前全仓 0 个第三方 SDK，这是产品资产，须守住 |
| 均衡器（EQ）/ 空间音频调节 | HarmonyOS 6.1.1 未提供多频段 EQ 与 `setSpatializationEnabled` 公开 API（**SDK 能力限制**），无法实现，设置页不得虚构此类开关 |
| 智感握姿 / 隔空手势交互 | 6.1.1 无 `@kit.MultimodalAwarenessKit`，仅能做布局自适应 |
| 全盘媒体库自动扫描 | 需 `READ_MEDIA` 权限，与"权限最小化"冲突；改由 `DocumentViewPicker` 用户主动选曲 |
| 视频播放 / 播客 / 有声书专项 | 聚焦音乐播放，避免形态发散 |
| 车机 / 穿戴 / PC 端适配（当前阶段） | 资源有限，先做透手机 + 折叠屏；架构已预留断点扩展能力 |

### 1.6 成功度量（KPI）

| 维度 | 指标 | 目标值 | 度量方式 |
|---|---|---|---|
| **上架** | 华为应用市场审核通过 | 首次提交即通过（0 次隐私类驳回） | AppGallery Connect 审核结果 |
| 合规 | 体检 P0 项清零 | P0 = 0 | 复跑安全/合规体检脚本 |
| 质量 | 崩溃率（Crash-Free Session） | ≥ 99.5% | 真机回归 + 上架后 AGC 质量看板 |
| 性能 | 冷启动到曲库首帧可交互 | ≤ 1.0s（中端机，200 首曲库） | DevEco Profiler |
| 性能 | 点歌到出声延迟 | ≤ 400ms（本地沙箱文件） | 埋点计时（本地日志，不出网） |
| 体验 | 后台播放 30 分钟不被系统挂起 | 100% 成功 | 真机长时任务验证（依赖 **R-02** 修复） |
| 体验 | 明暗主题一致性缺陷 | 0 处用户可感知断裂 | 设计走查（依赖 **R-09** 修复） |
| 无障碍 | 关键交互控件具备语义标签 | ≥ 90% 图标按钮有 `accessibilityText` | 无障碍扫描 + 人工抽查 |

---

## 2. 目标用户与典型使用场景

### 2.1 用户画像

#### Persona A — 本地无损收藏者「老张」（核心用户，占比最高）

- **特征**：35 岁，工程师。硬盘里有 300+ 首 FLAC/无损，来自正版购买与自行转录，按专辑整理，非常在意元数据（标题/艺术家/专辑/年代）与内嵌封面。
- **痛点**：主流播放器要么不认本地文件的内嵌封面与歌词，要么把他的歌单混进在线推荐；导入一次要授权整个存储空间。
- **对 Lumio 的期待**：认得出 FLAC 的内嵌封面和内嵌歌词；导入不要索取过度权限；曲库和歌单不要莫名丢失。
- **对应需求**：`FR-A1`、`FR-F1`、`FR-F3`、`FR-C4`、`FR-D*`

#### Persona B — 隐私敏感用户「小林」（价值观用户）

- **特征**：28 岁，设计师。默认关闭一切个性化推荐，安装前会看权限清单和隐私政策。
- **痛点**：不理解一个"播放本地文件"的应用为什么要联网、要读取通讯录、要开机自启。
- **对 Lumio 的期待**：权限清单短、隐私政策说人话且**与实际行为完全一致**、能明确知道"什么情况下会用到网络"。
- **对应需求**：`FR-I7`、`FR-I9`、`NFR-SEC-*`；**这个用户群会第一时间发现 R-01（隐私政策不一致），也是 P0 定级的根本原因。**

#### Persona C — 鸿蒙生态尝鲜者「阿哲」（口碑放大者）

- **特征**：22 岁，学生，HarmonyOS NEXT 新机用户，热衷体验原生应用、桌面卡片、投播、折叠屏分屏。
- **痛点**：很多应用只是"能跑"，没有卡片、锁屏控制粗糙、折叠屏展开后布局拉伸难看。
- **对 Lumio 的期待**：有桌面卡片、锁屏能控制、能投到家里的音箱、展开折叠屏布局要变化。
- **对应需求**：`FR-G1`~`FR-G6`、`FR-K1`~`FR-K3`

### 2.2 需求与痛点映射

| 用户痛点 | 产品对策 | 承载需求 |
|---|---|---|
| 导入音乐要授权整个存储 | `DocumentViewPicker` 用户逐次选曲 + 拷入应用沙箱，**零媒体库权限** | `FR-A1`/`FR-A2` |
| 本地文件的封面/歌词识别不出来 | C++ NAPI 双路元数据解析 + 内嵌封面抽取 + 内嵌歌词定点解析（FLAC/MP3/MP4）+ 外挂 `.lrc` 回落 | `FR-F1`/`FR-F3`/`FR-C4` |
| 播放器偷偷联网、传数据 | 无应用层网络请求、无第三方 SDK；仅局域网投播与用户主动点击的外链会用到网络，且须如实披露 | `NFR-SEC-01`~`04`、`FR-I7` |
| 切歌/锁屏控制不好用 | AVSession 接入系统锁屏与通知媒体控制，收藏态与播放态双向同步 | `FR-G1`/`FR-G2`/`FR-E3` |
| 后台一锁屏就断 | `KEEP_BACKGROUND_RUNNING` + `audioPlayback` 长时任务持续播放 | `FR-B9`（**依赖 R-02 修复**） |
| 折叠屏展开后布局难看 | BreakpointSystem（sm/md/lg）+ 折叠态检测双栏布局 | `FR-K1`/`FR-K2` |
| 歌单只能靠系统顺序 | 自建歌单：建/删/改名/加歌/移出/**拖拽排序**/播放全部 | `FR-D1`~`FR-D8` |

### 2.3 典型使用场景（User Journey）

**场景 1 — 首次上手：把我的歌搬进来**
> 老张装好 Lumio，打开是一个空曲库和一句引导。他点「导入音乐」，系统文件选择器弹出，他从「我的手机 / Music」里多选了 20 首 FLAC。应用把文件拷进自己的沙箱，逐首解析出标题、艺术家、专辑和内嵌封面，列表随着解析进度陆续亮起封面。全过程没有弹出任何"允许访问所有文件"的授权框。
> **覆盖**：`FR-A1`/`FR-A2`/`FR-A6`/`FR-F1`/`FR-F3`/`FR-F4`

**场景 2 — 通勤：锁屏也要能控**
> 早高峰地铁，老张点开一首歌，滑动进入播放页看了眼封面就把手机锁进兜里。歌继续播，一首放完自动进入下一首。他想跳过一首，直接在锁屏媒体卡片上点了「下一首」，并顺手点了红心收藏。回到应用，收藏列表里已经有这首歌了。
> **覆盖**：`FR-B1`/`FR-B2`/`FR-B8`/`FR-B9`/`FR-G1`/`FR-E1`/`FR-E3`

**场景 3 — 睡前：看着歌词听歌**
> 小林把主题设成深色，播放页封面取出主色晕染成柔和背景，歌词一行行居中滚动，日文原文下方跟着中文翻译。她想回听某一句，手指把歌词往上拨，点中那一行，播放就跳了过去。
> **覆盖**：`FR-C1`/`FR-C2`/`FR-C4`/`FR-C6`/`FR-H1`

**场景 4 — 在家：投到客厅音箱**
> 周末阿哲想用客厅的智慧屏放歌。他在播放页点投播图标，系统弹出设备列表，选中智慧屏，声音从音箱出来了，手机变成遥控器。他拿着手机走出门，超出局域网范围连接断开，播放**自动切回手机本地**继续，没有停顿也没有报错。
> **覆盖**：`FR-G5`/`FR-G6`/`FR-B10`
> **隐私要点**：这是全产品**唯一一次用户数据离开手机**（当前歌曲经局域网发往用户选定设备），必须在隐私政策如实说明（**R-01**）。

**场景 5 — 桌面：一眼看到在放什么**
> 阿哲把 Lumio 的播控卡片放到桌面。卡片显示当前歌名与艺术家，播放/暂停/上下首按钮直接可点，不用打开应用。
> **覆盖**：`FR-G3`/`FR-G4`

**场景 6 — 整理：做一张跑步歌单**
> 老张新建歌单「跑步」，从曲库里多选 15 首加进去，然后长按拖拽把节奏最猛的排到最前，点「播放全部」。跑完他把两首不合适的移出歌单——曲库里的原曲还在。
> **覆盖**：`FR-D1`/`FR-D4`/`FR-D5`/`FR-D6`/`FR-D7`

**场景 7 — 换机：数据不重来**
> 老张换新机，通过系统备份恢复，曲库元数据、歌单、收藏、播放历史、设置一并回来（音频文件本体随沙箱备份策略处理）。
> **覆盖**：`FR-G7`

---

## 3. 目标设备与适配策略

### 3.1 设备支持矩阵

| 设备形态 | 当前状态 | `deviceTypes` 声明 | 说明 |
|---|---|---|---|
| **直板手机** | ✅ 主战场，完整支持 | `phone` ✅ | 所有功能的第一适配目标；sm/md 断点 |
| **折叠屏（外屏/折叠态）** | ✅ 支持 | 复用 `phone` | 折叠态等同普通手机布局（sm/md） |
| **折叠屏（内屏/展开态）** | 🟡 部分支持 | 复用 `phone` | `PlayerInfoComponent` 已按 `display.FoldDisplayMode.FULL` 做双栏；**其余页面未专门处理**（见 R-11） |
| **平板** | ⬜ 规划中（M3） | ❌ 未声明 | 需在 `module.json5` 增加 `"tablet"`，并补 lg 断点多列/主从双栏（见 R-12） |
| **PC / 2in1** | ⬜ 不在范围 | ❌ | 非目标 |
| **车机 / 穿戴 / 智慧屏** | ⬜ 不在范围 | ❌ | 非目标；智慧屏仅作为**投播接收端**间接支持 |

> **重要澄清**：折叠屏在 HarmonyOS 中仍属 `phone` 设备类型，因此**无需修改 `deviceTypes` 即可在折叠屏运行**；而平板是独立设备类型，**必须显式声明才能上架到平板**。这是 M3 的前置动作。

### 3.2 响应式断点策略（一多基础）

已落地的断点体系（`common/constants/BreakpointConstants` + `common/utils/BreakpointSystem`）：

| 断点 | 宽度范围（vp） | 典型设备形态 | 当前布局策略 |
|---|---|---|---|
| `sm` | < 320 ~ 600 | 直板手机竖屏、折叠屏折叠态 | 单列列表 + 底部 Tab + 迷你播放条 |
| `md` | 600 ~ 840 | 大屏手机横屏、折叠屏展开（部分） | 单列列表；播放页 GridRow 分栏 |
| `lg` | ≥ 840 | 折叠屏内屏、平板 | 播放队列已 `.lanes(2)`；**主列表仍单列**（缺口，R-12） |

**技术实现**：`BreakpointSystem` 基于 `mediaquery` 监听，写入 `AppStorage.currentBreakpoint`；组件通过 `@StorageProp('currentBreakpoint')` + `BreakpointType<T>.getValue()` 取值。

**适配原则**：
1. **断点驱动，不做设备型号判断**：一律通过断点与 `FoldDisplayMode` 决策，禁止硬编码机型。
2. **尺寸单位规范**：布局用 `vp`，字号统一用 `fp`（跟随系统字体大小，无障碍必需）。
3. **安全区策略需统一**：当前 `expandSafeArea` 与手写 `topHeight/bottomHeight` padding 混用（R-13），M2 收敛为统一约定。
4. **大屏不只是"拉宽"**：lg 断点应提升信息密度（多列/主从双栏），而非等比放大单列。

### 3.3 平板与折叠屏扩展预留（M3 范围）

| 动作 | 内容 |
|---|---|
| 声明 | `module.json5` → `deviceTypes: ["phone", "tablet"]` |
| 布局 | 主列表（曲库/收藏/歌单/历史）在 lg 下 `List().lanes()` 多列，或 `Navigation` 主从双栏（Master-Detail：左列表 + 右播放/详情） |
| 播放页 | 复用已有折叠屏双栏思路，扩展到 lg |
| 资源 | 补充大屏限定词资源目录（如需） |
| 验证 | 平板模拟器 + 折叠屏真机（折叠/展开态切换不丢播放状态） |

---

## 4. 信息与功能架构

### 4.1 导航模型

采用 **HarmonyOS 推荐的 `Navigation` + `NavPathStack` 系统命名路由**，而非旧式 `router` 页面栈：

- 根容器：`Index` 内 `HdsNavigation(this.pathStack)`（UIDesignKit），隐藏系统 NavBar/TitleBar，自建 `Layout` 壳。
- 路由栈：`@Provide('navPathStack') pathStack: NavPathStack` 由根提供，子页 `@Consume('navPathStack')` 消费。
- 路由注册：`resources/base/profile/route_map.json`（`module.json5` 的 `routerMap` 指向），每个目的地登记 `name` + `pageSourceFile` + `buildFunction`。
- 跳转：`pathStack.pushPathByName(name, param)`。
- **参数传递契约**：跨页**只传 ID**（如歌单只传 `playlistId`），落地页再回 `MusicStore` 查实体，避免副本不同步。路由参数一律 `context.pathInfo.param as Object` + `typeof` 收窄取值（ArkTS 规范）。

**新增页面的强制动作**：① 在 `route_map.json` 注册；② 页面导出对应 `*Builder` 函数；③ 若涉及删歌等数据变更，必须遵守 §8.4 的队列对齐契约。

### 4.2 页面地图

```
Index（Navigation 根 / HdsNavigation）
└─ Layout ——【路由 1】根导航壳：自定义胶囊 Tab + 底部迷你播放条
   ├─ Tab①  LocalLibrary   音乐库（导入 / 搜索 / 列表 / 空态引导）
   │            └─ 点歌 ──▶ PlayerPage（一镜到底转场）
   └─ Tab②  Mine           我的（资料 / 听歌统计 / 功能菜单）
                ├──▶ Favorites      ——【路由 8】 收藏
                ├──▶ Playlists      ——【路由 10】我的歌单
                │       └──▶ PlaylistDetail ——【路由 11】歌单详情（拖拽排序 / 加歌）
                ├──▶ PlayHistory    ——【路由 7】 最近播放（上限 50）
                ├──▶ ManageSongs    ——【路由 9】 本地歌曲管理（删除 / 批量）
                └──▶ Settings       ——【路由 3】 设置主页
                        ├──▶ SettingsCategory ——【路由 4】设置分类子页
                        ├──▶ About            ——【路由 5】关于（版本 / 开发者外链）
                        └──▶ PrivacyPolicy    ——【路由 6】隐私政策
   
   PlayerPage ——【路由 2】沉浸式播放页（NavDestination）
       ├─ 封面光感 + 取色渐变背景
       ├─ 歌词区（原文 + 翻译 / KRC 逐字 / 手动滑动定位）
       ├─ 控制区（播放控制 + 进度 + 模式 + 投播入口 + 队列面板）
       ├─ bindSheet ─ SongDetailSheet     歌曲详情半模态
       └─ bindSheet ─ AddToPlaylistSheet  加入歌单半模态

【应用外入口】
   桌面播控卡片（FormAbility + WidgetCard，独立进程）
       └─ 按钮 postCardAction(router) ──▶ EntryAbility.handleControlWant ──▶ AVSessionController.remoteControl
   锁屏 / 通知媒体控制（AVSession 系统 UI）
   系统备份恢复（EntryBackupAbility）
```

**路由注册表事实核对**：`route_map.json` 实际注册 **11 个命名目的地**（Layout / PlayerPage / Settings / SettingsCategory / About / PrivacyPolicy / PlayHistory / Favorites / ManageSongs / Playlists / PlaylistDetail）。此前文档中"12 个目的地"的说法源于 `review_architecture.md` §3.14 枚举时将 `Layout` 重复计入一次，属笔误。**`LocalLibrary` 与 `Mine` 不是独立路由**，而是 `Layout` 内的 Tab 视图，故"页面级视图"共 13 个。见 **OQ-04**。

### 4.3 关键用户流

**流 1 — 导入音乐（含队列对齐，最易出错的一条流）**

```
用户点「导入音乐」
  → DocumentViewPicker.select()（用户主动多选，无需媒体库权限）
  → 逐个 fileIo 拷贝到沙箱 context.filesDir/download
      ├─ 成功 → srcPath = 沙箱路径
      └─ 失败 → 【应标记导入失败并提示重选，不得持久化受限 picker URI】（R-16）
  → SongItem 建档（id / title / singer / album / src…）
  → MusicStore.setSongs() 持久化到 preferences `music_store`
  → AudioMetaReader 补扫文本元数据（MediaKit 优先 → C++ NAPI 兜底，taskpool 线程）
  → CoverCache.preload() 批量抽取内嵌封面（并发 4，pending 去重 + 负缓存）
  → AudioRendererController.reconcileWithLibrary(store.songs)  ★队列与曲库唯一对齐点
  → AppStorage 刷新 songList / coverRefreshToken → UI 重绘封面
  → AVSessionController.pushFormUpdate() 同步桌面卡片
```

**流 2 — 点歌播放（一镜到底）**

```
列表点击某首
  → animateTo(interpolatingSpring) + geometryTransition('player_cover', {follow:true})
  → pathStack.pushPathByName('PlayerPage', …)
  → AudioRendererController.playFromList(list, index)   = setQueue(list, index, autoPlay=true)
      → await avPlayerReady（防冷启动竞态）
      → SongItemBuilder.build() 准备 fd（AVPlayer.fdSrc，本地文件描述符）
      → BackgroundUtil.startContinuousTask(AUDIO_PLAYBACK)  ★依赖 backgroundModes 声明（R-02）
      → MusicStore.addToRecentlyPlayed(song)（上限 50）
      → syncQueue() → AppStorage(songList/selectIndex) + AVSession.setSongList()
  → AVSessionController.setAVMetadata() 推送锁屏元数据（标题/封面/歌词）
  → pushFormUpdate() 更新桌面卡片
```

**流 3 — 投播（唯一的数据离机路径）**

```
播放页点投播 → AVCastPicker 系统设备选择器
  → 用户选定局域网设备 → startCast()
  → castCurrentSong()：用独立 fd（castFile，与本地 curFile 解耦）
  → setCastActive(true) → 本地静音标记，手机变遥控器
  → 【当前歌曲音频经局域网传输至用户选定设备】← 须在隐私政策如实披露（R-01）
  → onOutputDeviceChange 监听
      ├─ 远端接入 → 切远端播放
      └─ 远端断开 → 自动回落本地续播（进度对齐，不中断）
  → 退出应用 → unregisterSessionListener() 释放投播资源
```

**流 4 — 桌面卡片回控（跨进程）**

```
桌面卡片按钮（独立进程，无法直接调播放 API）
  → postCardAction(this, {action:'router', abilityName:'EntryAbility',
                          params:{control:'play'|'pause'|'next'|'prev'}})
  → 拉起 / 唤醒 EntryAbility → onCreate/onNewWant 解析 want
  → EntryAbility.handleControlWant() → AVSessionController.remoteControl(cmd)
  → AudioRendererController 执行 → 状态回写 AppStorage
  → pushFormUpdate() → formProvider.updateForm 跨进程刷新卡片显示
```

### 4.4 分层架构映射（功能 → 代码边界）

| 层 | 目录 | 职责 | 架构不变式（红线） |
|---|---|---|---|
| 表现层 | `pages/`（14）、`components/`（8）、`widget/`、`lyric/LrcView` | 页面与可复用 UI | 不得裸调 `preferences`；不得直连 `avPlayer`；不得自行计算深浅色 |
| 数据服务层 | `services/MusicStore.ets` | **曲库/收藏/歌单/历史权威持久层** | 曲库与收藏的唯一权威写者 |
| 领域模型层 | `songdatacontroller/`、`models/` | `SongItem` 单一真源、`Playlist`、播放枚举、fd 构建 | 叶子层，不反向依赖上层 |
| 基础设施层 | `utils/`（16） | 播放引擎、AVSession、主题、封面、元数据、歌词、日志、偏好、断点 | `AudioRendererController` 是播放队列唯一写者；`ThemeManager` 是主题唯一门面 |
| 纯函数层 | `lyric/LrcUtils`、`common/utils` | LRC/KRC 解析、断点、取色、资源换算 | 无副作用 |
| 数据源适配 | `datasource/` | `IDataSource` 懒加载（`LazyForEach`） | 大列表必须走懒加载 |
| 原生层 | `cpp/`（`libnative_module.so`） | FLAC/MP3/MP4 元数据真实解析 | 业务层禁止直连 `.so`，须经 `NativeUtils`；同步解析必须在 `taskpool` 工作线程 |
| Ability 层 | `entryability/`、`formability/`、`entrybackupability/` | 生命周期、AppStorage 播种、卡片、备份 | AppStorage 播种必须早于任何消费者构造 |

---

## 5. 功能需求（FR）

### 5.1 优先级与状态标记约定

**MoSCoW**（相对"v2.3.x 可上架版本"范围）：

| 标记 | 含义 |
|---|---|
| **M**（Must） | 必须具备，缺失则产品不成立或无法上架 |
| **S**（Should） | 应当具备，显著影响体验但可延后一个版本 |
| **C**（Could） | 可以有，锦上添花 |
| **W**（Won't） | 本轮不做（记录以防重复讨论） |

**状态**：`✅ 已交付`（AC 用于回归）｜`🟡 待补齐`（已实现但有缺口）｜`⬜ 规划中`

---

### 5.2 领域 A — 音乐导入与曲库管理

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-A1** | 用户主动选曲导入 | M | ✅ | 通过 `DocumentViewPicker.select()` 让用户从系统文件选择器多选音频文件导入 | ① 支持一次多选；② **全程不申请 `READ_MEDIA`/`WRITE_MEDIA`**，不弹出全盘存储授权；③ 取消选择不产生任何数据变更；④ 支持 FLAC / MP3 / MP4(M4A) 及 MediaKit 可解码格式 |
| **FR-A2** | 拷入应用沙箱 | M | ✅ | 选中文件拷贝到 `context.filesDir/download`，以沙箱路径作为 `SongItem.src` | ① 导入后原文件删除或移动不影响播放；② 播放使用 `AVPlayer.fdSrc`（本地 fd），不使用远程 URL；③ 拷贝失败须提示用户并**不得**将受限 picker URI 持久化入库（当前为缺口，见 R-16） |
| **FR-A3** | 队列与曲库差量对齐 | M | ✅ | 导入/删除后调用 `reconcileWithLibrary(library)` 使播放队列与曲库一致 | ① 队列剔除曲库已删歌曲并修正当前索引；② 新导入歌曲追加至队尾；③ 当前播放曲被删则续播相邻曲，队列空则 `stop()`；④ 对齐后回写 AppStorage；⑤ `next/prev` 绝不跳到已删除文件 |
| **FR-A4** | 曲库列表浏览 | M | ✅ | 展示 `MusicStore.songs`，含封面、标题、艺术家 | ① 冷启动从 preferences 恢复完整曲库；② 大列表走 `LazyForEach` + `IDataSource` 懒加载；③ 封面异步就位不阻塞列表首帧；④ 当前播放曲在列表中有高亮标识 |
| **FR-A5** | 曲库搜索 | M | ✅ | 按标题/艺术家实时过滤 | ① 输入即时过滤无明显卡顿；② 清空恢复全量；③ 无匹配显示空结果提示；④ 搜索结果内点歌播放行为与全量列表一致 |
| **FR-A6** | 空态引导 | M | ✅ | 曲库为空时展示引导插画与导入入口 | ① 空曲库不显示空白页；② 提供醒目「导入音乐」主按钮；③ 加载中/加载失败（`MusicStore.loadError`）有区分于"空"的独立表现 |
| **FR-A7** | 单曲删除 | M | ✅ | `ManageSongs` / 长按菜单删除歌曲 | ① 删除有二次确认；② 同步 evict 封面缓存与歌词缓存；③ 清理该曲在所有歌单中的悬挂引用；④ 触发 `FR-A3` 队列对齐；⑤ 收藏态一并清除 |
| **FR-A8** | 批量删除 | S | ✅ | 多选批量移除 | ① 批量操作后仅触发一次队列对齐与一次持久化；② 结果与逐个删除一致 |
| **FR-A9** | 删除入口统一收口 | S | 🟡 | 队列对齐应在 `MusicStore.removeSong` 内统一触发，而非依赖各页面手动调用 | ① 任意页面新增删歌入口无需手写 `reconcileWithLibrary` 即保持一致；② 现有 4 处调用点行为不回退（见 R-14） |

---

### 5.3 领域 B — 播放控制与队列

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-B1** | 播放 / 暂停 | M | ✅ | 基础播放控制（`AVPlayer`） | ① 点歌到出声 ≤ 400ms；② 冷启动首次播放须 `await avPlayerReady`，不得因未就绪失败；③ 播放态经 AppStorage `isPlay` 同步到迷你条/播放页/锁屏/卡片，四处状态一致 |
| **FR-B2** | 上一首 / 下一首 | M | ✅ | 按当前播放模式切换 | ① 顺序模式在队列边界行为明确（末尾→首或停止，须一致）；② 单曲循环下手动切歌仍切换到相邻曲（不困在同一首）；③ 随机模式不连续重复同一首 |
| **FR-B3** | 进度显示与拖拽 | M | ✅ | 进度条 + 当前/总时长，可拖拽定位 | ① 进度每秒更新，与实际播放偏差 ≤ 1s；② 拖拽用 `SeekMode.SEEK_CLOSEST`，松手即跳转；③ 拖拽过程中歌词联动；④ 时长显示格式统一 `mm:ss` |
| **FR-B4** | 播放模式切换 | M | ✅ | 顺序 / 单曲循环 / 随机 | ① 三态循环切换且图标与文案对应；② 模式持久化，重启保留；③ 同步至 AVSession `LoopMode`，锁屏显示一致；④ **三套模式类型（`RepeatMode`/`RepeatModeSetting`/`MusicPlayMode`）转换不得出错**（见 R-19） |
| **FR-B5** | 播放队列面板 | M | ✅ | 半模态展示当前队列，可点击跳播 | ① 展示队列全量并高亮当前曲；② 打开时自动滚动定位到当前曲；③ lg 断点双列（`.lanes(2)`）；④ **面板须随明暗主题变化**（当前为缺口，见 R-09） |
| **FR-B6** | 队列编辑 | S | ✅ | 移出队列 / 下一首播放 | ① `removeFromQueue` 后当前播放曲不变、索引正确；② `moveToPlayNext` 使目标曲成为下一首；③ 编辑队列不影响曲库与歌单 |
| **FR-B7** | 全局迷你播放条 | M | ✅ | `Layout` 底部常驻，显示当前曲并可播控 | ① 除播放页外全局可见；② 点击进入播放页并复用一镜到底转场；③ 无播放内容时的表现明确（隐藏或占位提示） |
| **FR-B8** | 自动下一首 | M | ✅ | 一曲播完自动续播，可在设置关闭 | ① 开启时无缝进入下一首；② 关闭时播完即停并保持暂停态；③ 设置项持久化 |
| **FR-B9** | 后台持续播放 | M | 🟡 | 长时任务保障锁屏/切后台不中断 | ① 息屏 30 分钟连续播放不被系统挂起；② 停止播放时结束长时任务，不长期占用；③ **`module.json5` 的 EntryAbility 必须声明 `"backgroundModes": ["audioPlayback"]`**——当前缺失，`startBackgroundRunning` 返回 `BusinessError`，后台播放实际不生效（**R-02，M1 必修**） |
| **FR-B10** | 静音 / 混音模式 | C | 🟡 | 投播期本地静音、与其他音频混音 | ① 投播时本地不出声；② 静音标记持久化；③ **静音标记须独立存储，不得混入桌面卡片 formIds 数组**（当前为缺口，见 R-17） |

---

### 5.4 领域 C — 播放页与歌词

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-C1** | 沉浸式播放页 | M | ✅ | 全屏沉浸播放界面 | ① `ignoreLayoutSafeArea` 沉浸至状态栏；② sm/md/lg + 折叠展开态布局均不裁切、不拉伸；③ 返回不中断播放 |
| **FR-C2** | 封面光感背景 | S | ✅ | 从封面取主色生成渐变/模糊背景 | ① 取色在工作线程或不阻塞首帧；② 深浅背景自动决定歌词与文字对比色（`lyricBgDark`/`isDarkBackground`）；③ 无封面时降级为主题默认背景，不留白屏 |
| **FR-C3** | 一镜到底转场 | S | ✅ | 列表封面 → 播放页封面共享元素转场 | ① `geometryTransition('player_cover',{follow:true})` + `interpolatingSpring`；② 转场无跳帧/错位；③ 返回同样连续；④ 「降低动态效果」开启时应降级（见 R-18） |
| **FR-C4** | 双语歌词显示 | M | ✅ | 内嵌歌词 + 外挂 `.lrc`，原文 + 翻译双行 | ① 内嵌歌词支持 FLAC(VORBIS_COMMENT) / MP3(ID3v2 USLT·TXXX) / MP4(©lyr)；② 无内嵌时回落同名 `.lrc`；③ 语种多数决区分原文/翻译，并剔除"作词/作曲"等制作信息行；④ 编码探测支持 BOM/UTF-16→UTF-8；⑤ 无歌词时显示占位提示而非空白 |
| **FR-C5** | 逐字高亮（KRC） | C | ✅ | KRC 格式逐字滚动高亮 | ① `Word[]` 时间轴驱动逐字着色；② 与音频同步偏差 ≤ 200ms |
| **FR-C6** | 歌词手动滑动与定位 | S | ✅ | 手动拨动歌词，点击行跳播 | ① 手动滑动时暂停自动跟随；② 一段时间无操作恢复自动跟随；③ 点击行 seek 到该行起始时间 |
| **FR-C7** | 歌曲详情半模态 | S | ✅ | `bindSheet` 展示标题/艺术家/专辑/格式等 | ① 已主题化（明暗均正常）；② 关闭不影响播放；③ 提供"加入歌单"等后续动作入口 |
| **FR-C8** | 歌词缓存容量治理 | C | 🟡 | `EmbeddedLyricReader` 静态缓存需容量上限 | ① 超大曲库长期使用内存不无界增长；② 引入 LRU 或容量上限（当前仅删歌时 evict，见 R-20） |

---

### 5.5 领域 D — 歌单

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-D1** | 新建歌单 | M | ✅ | 弹窗输入名称创建 | ① 名称去空白后非空校验；② 重名校验（`hasPlaylistName`）；③ id 为 `时间戳_随机` 防重；④ 创建后立即出现在列表 |
| **FR-D2** | 删除歌单 | M | ✅ | 删除歌单本身 | ① 二次确认；② **仅删歌单，曲库原曲不受影响**；③ 删除后持久化生效 |
| **FR-D3** | 重命名歌单 | S | ✅ | 修改歌单名称 | ① trim 后写入；② 重名校验排除自身（`excludeId`）；③ 各引用处名称同步更新 |
| **FR-D4** | 添加歌曲到歌单 | M | ✅ | 半模态多选加歌（`AddToPlaylistSheet`） | ① 支持多选批量；② 已在歌单中的曲不重复添加；③ 返回实际新增数并给出反馈 |
| **FR-D5** | 从歌单移出 | M | ✅ | 移出单曲 | ① 仅移出引用，曲库原曲保留；② 列表即时更新并持久化 |
| **FR-D6** | 拖拽排序 | S | ✅ | 长按拖拽调整歌单内顺序 | ① `reorderPlaylistSongs(pid, from, to)` 落库；② 拖拽动画跟手；③ 排序结果重启后保留；④ 排序时若该歌单正在播放，队列覆盖须 `autoPlay=false`，**不得打断当前播放** |
| **FR-D7** | 播放全部 | M | ✅ | 以歌单为队列从首曲播放 | ① 队列被歌单覆盖且顺序与歌单一致；② 从第一首开始播放；③ 队列源须为最新数据，**不得读取可能 stale 的 `MusicStore.playList`**（见 R-21） |
| **FR-D8** | 歌单详情页 | M | ✅ | 展示歌单内歌曲、数量与操作入口 | ① 跨页仅传 `playlistId`，落地页回查 `MusicStore`；② 歌曲数量徽章准确；③ 空歌单有引导加歌入口 |

---

### 5.6 领域 E — 收藏与播放历史

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-E1** | 收藏 / 取消收藏 | M | ✅ | 红心切换，`song.id` 为主键 | ① **以 `song.id` 为稳定主键，绝不依赖会漂移的队列下标**；② 切换即时持久化；③ 曲库/收藏页/播放页/锁屏/卡片五处收藏态一致 |
| **FR-E2** | 收藏列表 | M | ✅ | 独立页面展示全部收藏 | ① 由 `songs` 过滤生成，不维护第二份副本；② 支持点歌播放、长按菜单；③ 空态有引导 |
| **FR-E3** | 锁屏 / 卡片收藏同步 | S | ✅ | 系统媒体控制中的收藏与应用内双向同步 | ① 锁屏点收藏，应用内即时反映；② 应用内收藏，锁屏图标同步；③ 同步经 `MusicStore` 收口（`updateFavoriteState(assetId)`），不旁路 |
| **FR-E4** | 最近播放记录 | M | ✅ | 自动记录播放历史，上限 50 条 | ① 起播即记录；② 重复播放同一首不产生重复条目（置顶更新）；③ 严格上限 50，超出淘汰最旧；④ 持久化 |
| **FR-E5** | 清空播放历史 | M | ✅ | 设置中一键清空 | ① 二次确认；② 清空后历史页显示空态；③ 不影响曲库/收藏/歌单 |

---

### 5.7 领域 F — 元数据与封面

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-F1** | 双路元数据解析 | M | ✅ | MediaKit 优先 + C++ NAPI 兜底 | ① `AVMetadataExtractor` 优先；仅失败或 `title` 缺失时回退 C++ NAPI；② **同步 NAPI 必须在 `taskpool` 工作线程**，`@Concurrent` 顶层具名函数（闭包形式会抛 10200014）；③ 跨线程仅传可序列化纯数据；④ 解析失败降级为文件名显示，不阻断导入 |
| **FR-F2** | 首启元数据补扫 | S | ✅ | `refreshMetadataIfNeeded()` 幂等补扫历史曲库 | ① 幂等标记 `meta_scanned_v1`，只跑一次；② 补扫在后台进行不阻塞 UI；③ 补扫失败不影响既有数据 |
| **FR-F3** | 内嵌封面抽取与缓存 | M | ✅ | `CoverCache` 抽取内嵌封面并缓存 | ① pending 去重（同一文件并发只抽一次）；② 负缓存（确认无封面后不重复尝试）；③ 仅对沙箱真实文件抽取，跳过 `.pcm`/rawfile；④ **PixelMap 不塞入 AppStorage**，改用 `coverRefreshToken` 信号量通知重读；⑤ 无封面静默降级默认封面图 |
| **FR-F4** | 封面批量预载 | S | ✅ | 启动时批量预载封面（并发 4） | ① 预载不阻塞曲库首帧；② 完成后刷新 `coverRefreshToken` 触发 UI 重绘；③ 删歌时 `evict` 释放 |
| **FR-F5** | 年代（year）全链路 | C | 🟡 | 解析出的 `year` 应可持久化与展示 | ① `SongItem` 增补 `year` 字段并持久化；② `refreshMetadataIfNeeded` 写入 `year`；③ 详情页展示年代。**当前 `AudioMetaReader` 能解析 `year` 但 `SongItem` 无该字段，解析结果被丢弃**（见 R-15）。若本轮不做，须从对外功能描述中移除"年代"承诺 |
| **FR-F6** | 原生解析能力复用 | C | ⬜ | C++ 已返回 `durationMs/sampleRate/channels`，可作 MediaKit 失败兜底 | ① MediaKit 取时长失败时以 C++ 结果兜底；② 详情页可展示采样率/声道（可选） |

---

### 5.8 领域 G — 系统能力集成

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-G1** | 锁屏 / 通知媒体控制 | M | ✅ | AVSession 接入系统媒体控制中心 | ① 锁屏与通知栏显示标题/艺术家/封面；② 播放/暂停/上下首/进度/收藏/循环模式可控且回传正确；③ 切歌时元数据即时刷新；④ 应用退出时 `unregisterSessionListener` 释放 |
| **FR-G2** | 锁屏控制开关 | S | ✅ | 用户可在设置关闭锁屏媒体控制 | ① 关闭后系统媒体控制不再显示本应用；② 开启即时恢复；③ 设置持久化 |
| **FR-G3** | 桌面播控卡片 | S | ✅ | 桌面卡片显示当前播放并提供播控按钮 | ① 显示 `title`/`artist`/`isPlaying`；② 主应用状态变化经 `pushFormUpdate` → `formProvider.updateForm` 跨进程刷新；③ 多张卡片同时存在均能刷新；④ 卡片进程不直接调用播放 API |
| **FR-G4** | 卡片按钮回控 | S | ✅ | 卡片按钮控制播放（play/pause/next/prev） | ① `postCardAction(router)` 拉起/唤醒 `EntryAbility`；② `handleControlWant` 正确解析并执行；③ 应用未运行时点击卡片按钮能拉起并执行；④ formId 登记/注销正确（`onAddForm`/`onRemoveForm`） |
| **FR-G5** | 投播（Cast） | S | ✅ | `AVCastPicker` 选设备，`AVCastController` 投播 | ① 系统设备选择器可发现局域网设备；② 投播成功后声音由远端输出、本地静音；③ 投播使用独立 fd（`castFile` 与 `curFile` 解耦）；④ **必须在隐私政策披露"音频经局域网传输至用户选定设备"**（R-01） |
| **FR-G6** | 投播连断自动切换 | S | ✅ | 远端连接/断开自动切换播放通路 | ① `onOutputDeviceChange` 监听生效；② 远端断开自动回落本地续播且进度对齐；③ 切换过程无崩溃、无双声道重叠 |
| **FR-G7** | 数据备份恢复 | S | ✅ | `EntryBackupAbility` 支持系统备份 | ① 备份覆盖曲库元数据/歌单/收藏/历史/设置；② 恢复后数据完整可用；③ 备份配置 `backup_config` 与实际存储路径一致 |

---

### 5.9 领域 H — 主题与外观

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-H1** | 三档主题模式 | M | ✅ | 跟随系统 / 浅色 / 深色 | ① 三档均生效且持久化；② "跟随系统"在系统切换时实时响应（`onConfigurationUpdated`）；③ 切换无需重启，页面即时重绘；④ `ThemeManager` 为唯一门面，组件不自行判深浅 |
| **FR-H2** | 状态栏内容色同步 | S | ✅ | 状态栏/导航栏内容色随主题 | ① 浅色主题深色图标、深色主题浅色图标；② 播放页沉浸态下内容色仍可读 |
| **FR-H3** | 明暗一致性（无断裂） | M | 🟡 | 所有界面在深色下无"纯白底"类断裂 | ① 全页面走查 0 处明暗断裂；② **播放队列半模态面板当前硬编码 `Color.White`/`Color.Black`，深色下为纯白底黑字，与全局深色主题割裂**（**R-09，设计侧 P0**）；③ 当前播放项高亮色须用品牌 `accent` 而非 `Color.Red` |
| **FR-H4** | 品牌色令牌化 | S | 🟡 | `#FA2759` 收敛为单一令牌来源 | ① 新增 `accent`/`accentSoft` 语义令牌；② 替换约 40 处内联 `#FA2759`/`rgba(250,39,89,…)`；③ 补齐 `dark/element/color.json` 深色变体；④ 颜色系统单一来源（见 R-10） |

---

### 5.10 领域 I — 设置、隐私与关于

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-I1** | 设置主页与分类子页 | M | ✅ | `Settings` + `SettingsCategory` 分类导航 | ① 分类清晰可达；② 子页经命名路由跳转，参数 `as Object` + `typeof` 收窄；③ 所有设置项即时生效并持久化 |
| **FR-I2** | 自动下一首开关 | M | ✅ | 见 `FR-B8` | 同 `FR-B8` |
| **FR-I3** | 听歌统计开关 | C | ✅ | 用户可关闭本地听歌统计 | ① 关闭后不再累计统计；② 统计数据仅存本地，**绝不出网**；③ 开关持久化 |
| **FR-I4** | 降低动态效果 | S | 🟡 | 无障碍：减少非必要动画 | ① 开启后转场/入场/呼吸等非必要动画降级或关闭；② **当前 `reduceMotion` 已持久化但未在动画处统一消费**（见 R-18） |
| **FR-I5** | 清空播放历史入口 | M | ✅ | 见 `FR-E5` | 同 `FR-E5` |
| **FR-I6** | 版本与关于 | M | ✅ | 展示版本号、许可证、开发者信息 | ① 版本号与 `app.json5` 一致（当前 2.3.0）；② 展示 Apache-2.0 许可与版权主体 |
| **FR-I7** | 隐私政策页 | **M** | **🔴 必须重写** | 应用内可查看的隐私政策 | ① **如实列出实际申请的权限及用途**；② **明确说明投播会将当前歌曲经局域网传输至用户选定设备**；③ **明确说明应用会跳转第三方网页（开发者主页），该网页由第三方提供**；④ **删除"读取本地音频文件""应用存储（文件/媒体）"等实际未申请的权限描述**；⑤ 与 `string.json` 的 `perm_guide_message` 口径一致；⑥ 与 AppGallery Connect 后台登记的隐私政策一致。**当前政策既漏报 INTERNET/投播/外链，又错报不存在的存储权限 → R-01（P0，上架一票否决级）** |
| **FR-I8** | 开发者信息外链 | C | ✅ | 「关于开发者」跳转外部网页 | ① 跳转由系统浏览器处理，应用内不内嵌 WebView 网络请求；② **跳转行为须在隐私政策披露**（并入 R-01）；③ 外链域名归属须确认（见 OQ-03） |
| **FR-I9** | 首次启动权限告知 | S | 🟡 | 首启说明权限用途 | ① 首启展示 `perm_guide_message` 并记录 `permGuideShown` 不重复弹；② **建议增加「查看隐私政策」入口与明确的同意确认动作**（当前仅"知道了"式告知，非强合规形态，见 R-08） |
| **FR-I10** | 文案资源化 | C | 🟡 | 用户可见文案迁移 `string.json` | ① 用户可见文案不硬编码在 `.ets` 中；② 为后续多语言留出扩展（见 R-22） |

---

### 5.11 领域 K — 响应式与无障碍

| ID | 需求 | 优先级 | 状态 | 描述 | 验收标准（AC） |
|---|---|---|---|---|---|
| **FR-K1** | 断点响应式布局 | M | ✅ | sm/md/lg 三断点体系 | ① `BreakpointSystem` 基于 `mediaquery` 写 `AppStorage.currentBreakpoint`；② 旋转/分屏/展开时断点即时更新且布局不错乱；③ 断点系统初始化不依赖隐式播种顺序（见 R-23） |
| **FR-K2** | 折叠屏展开适配 | S | 🟡 | 内屏展开双栏布局 | ① 播放页已按 `FoldDisplayMode.FULL` 双栏；② 折叠/展开切换不中断播放、不丢状态；③ **其余页面未专门处理展开态**（见 R-11） |
| **FR-K3** | 安全区与沉浸统一 | S | 🟡 | 统一安全区避让策略 | ① 内容不被状态栏/手势条遮挡；② **统一 `expandSafeArea` 或在 `NavDestination` 层统一注入内边距，避免逐页手写 `topHeight/bottomHeight`**（见 R-13） |
| **FR-K4** | 大屏多列 / 主从双栏 | S | ⬜ | lg 断点主列表多列或 Master-Detail | ① 曲库/收藏/歌单/历史在 lg 下多列或双栏；② 单列不被等比拉伸留大片空白（见 R-12，M3 范围） |
| **FR-K5** | 无障碍语义标签 | S | 🟡 | 图标按钮具备可读语义 | ① 图标按钮补 `accessibilityText()`/`accessibilityLevel()`；② 读屏可播报关键控件用途；③ 字号 `fp` 已达标，需确保超大字体下固定高度不挤压多行文本（见 R-18） |
| **FR-K6** | 文本对比度 | S | 🟡 | 关键文本达 WCAG AA | ① 浅色 `secondaryText=#8E8E93` 白底约 3.5:1，接近阈值，须评估加深或加粗；② 硬编码 `#636366` 次要文字统一回令牌（见 R-24） |

---

## 6. 非功能需求（NFR）

### 6.1 性能

| ID | 需求 | 指标 / 约束 |
|---|---|---|
| NFR-PERF-01 | 冷启动 | 曲库首帧可交互 ≤ 1.0s（中端机 / 200 首曲库）。启动链：AppStorage 播种 → `MusicStore.init` → 主题初始化 → 首帧；**封面预载与元数据补扫必须异步，不得阻塞首帧** |
| NFR-PERF-02 | 起播延迟 | 点歌到出声 ≤ 400ms（本地沙箱文件）；所有播放入口必须 `await avPlayerReady` 以规避冷启动竞态 |
| NFR-PERF-03 | 列表流畅度 | 曲库/歌单列表滑动 ≥ 60fps 无明显掉帧；大列表**必须** `LazyForEach` + `IDataSource`；列表项复用（`@Reusable`） |
| NFR-PERF-04 | 主线程零阻塞 | C++ NAPI 同步解析、封面抽取等耗时操作一律置于 `taskpool` 工作线程；主线程单次任务 < 16ms |
| NFR-PERF-05 | 内存 | 大图不常驻 AppStorage（用 `coverRefreshToken` 信号量 + `CoverCache` 重读）；歌词解析设上限（ID3 8MB / VORBIS 4MB / moov 16MB / 歌词 512KB）防 OOM；歌词缓存需容量上限（R-20） |
| NFR-PERF-06 | 状态更新粒度 | 避免 `@StorageLink('songList')` 整段大数组变更导致全列表重渲染；演进方向为 `@Observed`/`@ObjectLink` 细粒度（M4） |
| NFR-PERF-07 | 资源释放 | fd 必须配对释放（`SongItemBuilder.release`），无 fd 泄漏；退出释放投播与 AVSession 资源；停止播放结束长时任务 |

### 6.2 功耗

| ID | 需求 | 指标 / 约束 |
|---|---|---|
| NFR-PWR-01 | 后台功耗 | 后台播放仅保留必要长时任务（`AUDIO_PLAYBACK`），播放停止后立即结束，不常驻 |
| NFR-PWR-02 | 无后台轮询 | 禁止后台定时轮询与无谓唤醒；进度更新由播放器回调驱动，非 `setInterval` 空转 |
| NFR-PWR-03 | 息屏优化 | 息屏/切后台时停止 UI 动画与歌词渲染，仅保留音频链路 |

### 6.3 安全与隐私

| ID | 需求 | 约束（红线） |
|---|---|---|
| **NFR-SEC-01** | 数据本地化 | 曲库/收藏/歌单/历史/设置/统计 100% 存于应用沙箱；**无云端、无账号、无用户标识**。除用户主动触发的局域网投播外，**任何用户数据不得离机** |
| **NFR-SEC-02** | 权限最小化 | 仅保留真实使用的权限。目标终态：`KEEP_BACKGROUND_RUNNING`(inuse) + `INTERNET`(always)；**`GET_NETWORK_INFO` 声明未使用，须删除**（R-03）。严禁申请 `READ_MEDIA`/`WRITE_MEDIA`/位置/通讯录等敏感权限 |
| **NFR-SEC-03** | 无第三方 SDK | 全仓 0 个第三方 SDK（无统计/广告/推送）；无应用层 HTTP 客户端（`createHttp`/`rcp`/`fetch`/`websocket` 全仓 0 命中）。**新增依赖须经隐私评审** |
| **NFR-SEC-04** | 文件访问合规 | 音频经 `DocumentViewPicker` 用户主动授权 + 拷入沙箱；不经系统媒体库扫描；`AVPlayer` 仅用 `fdSrc` 本地描述符 |
| **NFR-SEC-05** | 日志脱敏 | **禁止以 `%{public}` 打印任何用户文件路径、歌名等个人媒体信息**。须经 `AudioMetaReader.sanitize()`（仅留文件名）或 `Logger.*Private()`（`%{private}s`，release 自动隐藏）。当前 8 处违规（R-04） |
| NFR-SEC-06 | 类型安全 | 禁 `any`/`unknown`；`as ESObject` 仅限 NAPI/JSON interop 且须集中封装 + 运行时校验，不得散落（R-05） |
| NFR-SEC-07 | 存储加密 | 当前 `preferences` 明文（低敏感本地数据 + 沙箱隔离，可接受）。**若未来引入账号/跨设备同步/更敏感信息，必须改用加密存储（Asset Store 或应用级加密）** |
| NFR-SEC-08 | 死代码清理 | 未使用的信息采集类接口（如 `NativeModule.getDeviceInfo`）必须删除，避免"能力存在即风险"（R-07） |
| NFR-SEC-09 | 原生内存安全 | C++ 层所有长度/偏移须做 `size_t`/`uint64` 边界校验；非法 UTF-8 与缺参安全回退（已修复，须回归守护） |

### 6.4 合规与上架

| ID | 需求 | 约束 |
|---|---|---|
| **NFR-CMP-01** | 隐私政策一致性 | 应用内隐私政策、AppGallery Connect 登记政策、`module.json5` 实际权限、代码实际行为**四者必须完全一致**。这是华为审核强校验项与最典型驳回点。当前不一致 → **R-01（P0）** |
| **NFR-CMP-02** | 长时任务声明完整 | 使用 `startBackgroundRunning(AUDIO_PLAYBACK)` 必须同时具备 `KEEP_BACKGROUND_RUNNING` 权限 **和** ability 的 `"backgroundModes": ["audioPlayback"]` 声明 → **R-02（P1）** |
| **NFR-CMP-03** | 发布资料真实 | `AppScope/app.json5` 的 `vendor` 不得为占位值（当前 `"example"`），须改为真实主体 → **R-06**；`bundleName` 一经上架不可更改，须先定案 → **OQ-01** |
| NFR-CMP-04 | 权限理由如实 | 每条权限 `reason` 须覆盖全部实际用途。`internet_reason` 当前仅写"局域网投播"，未涵盖"外链跳转" → R-25 |
| NFR-CMP-05 | ArkTS 红线合规 | 团队 11 条编译器红线 100% 合规（已达标，须纳入 CI 门禁）：`build()` 首语句、`CustomDialogController` 禁 `@State`、组件内禁 `get` 访问器、禁裸 `console`/`hilog`、禁解构声明、禁 `any`/`unknown`、路由参数收窄、`preferences` 异常捕获等 |
| NFR-CMP-06 | 许可与版权 | Apache-2.0，`LICENSE`/`NOTICE` 完备；源码文件头版权声明齐全（当前已具备） |
| NFR-CMP-07 | 内容合规 | 应用不提供任何音乐内容，全部由用户自行导入；须在描述与政策中明确"内容由用户提供，版权责任由用户承担" |

### 6.5 无障碍

| ID | 需求 | 约束 |
|---|---|---|
| NFR-A11Y-01 | 字号自适应 | 字号统一 `fp` 跟随系统（已达标）；超大字体下固定高度容器不得挤压多行文本 |
| NFR-A11Y-02 | 读屏语义 | 图标按钮须有 `accessibilityText()`；装饰性元素设 `accessibilityLevel('no')`（R-18） |
| NFR-A11Y-03 | 动效可关闭 | 「降低动态效果」开启时非必要动画统一降级（R-18） |
| NFR-A11Y-04 | 对比度 | 关键文本对比度达 WCAG AA（正文 4.5:1 / 大文本 3:1）（R-24） |
| NFR-A11Y-05 | 触达尺寸 | 可点击控件有效触达区 ≥ 40vp × 40vp |

### 6.6 兼容性与降级

| ID | 需求 | 约束 |
|---|---|---|
| NFR-CPT-01 | API 版本基线 | `compileSdkVersion` = `compatibleSdkVersion` = `targetSdkVersion` = **6.1.1(24)**。所用 API（`Navigation`/`NavPathStack`、`UIContext.*`、`mediaquery`、`display`、`taskpool`、`avSession`、`@kit.CoreFileKit`）均在 API 11+ 引入，无版本不足 |
| NFR-CPT-02 | 废弃 API 规避 | 已用 `getUIContext().getPromptAction()` 替代 API 12 起废弃的全局 `promptAction`；文件 API 须统一迁移至 `@kit.CoreFileKit`（当前 3 处仍用 `@ohos.file.fs`，R-26） |
| NFR-CPT-03 | SDK 能力缺口 | 6.1.1 无 `@kit.MultimodalAwarenessKit`（智感握姿）；无多频段 EQ 与 `setSpatializationEnabled` 公开 API。**产品不得承诺此类能力**（见 §1.5 非目标） |
| NFR-CPT-04 | 音频格式降级 | 元数据解析：MediaKit → C++ NAPI → 文件名，逐级降级；封面：内嵌 → 默认图；歌词：内嵌 → 外挂 `.lrc` → 占位提示。**任一环节失败均静默降级，不阻断播放** |
| NFR-CPT-05 | 异常健壮性 | `preferences` 读写全部 `try/catch`（已达标）；**异步接口的异常分支不得返回永不 resolve/reject 的 Promise**（`PreferencesUtil.getFormIds` 当前违规，会导致调用方静默挂起，R-14） |
| NFR-CPT-06 | 状态一致性 | 播放状态在「应用内 UI / 锁屏 / 通知 / 桌面卡片 / 投播端」五处保持最终一致；投播与本地播放使用独立 fd 互不干扰 |

### 6.7 可维护性与可观测性

| ID | 需求 | 约束 |
|---|---|---|
| NFR-MNT-01 | 分层边界 | 遵守 §4.4 架构不变式；表现层不裸调持久化、不直连 `avPlayer`、不直连 `.so` |
| NFR-MNT-02 | 单一真源 | 概念命名与读取路径须无歧义，尤其**三条"歌曲列表"**（见 §8.4，R-08） |
| NFR-MNT-03 | 统一日志门面 | 全仓仅 `utils/Logger.ets` 使用 `hilog`；domain `0xFF00`，prefix `MusicPlay` |
| NFR-MNT-04 | CI 门禁 | 体检脚本（ArkTS 红线 / 权限 / 隐私一致性）纳入 CI，`ERROR` 级退出码阻断合入 |
| NFR-MNT-05 | 可测试性 | 播放/会话控制器逐步抽象为接口，支持无设备单元测试（M4） |

---

## 7. 视觉与设计规范方向

> 基准：**HarmonyOS Design**（ArkUI 声明式规范）。设计体检当前成熟度评分 **7/10**，方向正确，主要问题是"令牌未收敛 + 一处明暗断裂"。

### 7.1 品牌与色彩

| 项 | 规范 |
|---|---|
| **品牌主色（accent）** | **`#FA2759`**（Lumio 玫红）—— 用于播放态高亮、当前播放项、开关选中态、计数徽章、主行动按钮 |
| accentSoft | `rgba(250,39,89,0.1)` 系列，用于徽章底、选中底 |
| 语义色令牌 | `bg` / `secondaryBg` / `cardBg` / `primaryText` / `secondaryText` / `separator` / `accent`，light + dark 两套 |
| **令牌单一来源（关键）** | 当前存在 `ThemeManager` 语义令牌与 `resources/*/element/color.json` 资源令牌**双源**，且品牌色被约 40 处内联硬编码、`ThemeManager.accent` 几乎未被引用。**必须收敛为单一来源**（推荐：资源 `color.json` + light/dark 限定词，或统一 ThemeManager），并补齐 `dark/element/color.json` 深色变体（当前仅覆盖 `start_window_background`）→ R-10 |
| **禁用调色板** | **禁止继续使用 Apple HIG 调色板**（`#34C759`/`#FF9500`/`#007AFF`/`#5E5CE6`/`#FFCC00`/`#5856D6`）。分类图标与统计数字应回归 HarmonyOS Design 语义色或统一中性底色，以强化品牌识别 → R-27 |
| 当前播放项高亮 | 必须用 `accent`（`#FA2759`），**禁止 `Color.Red`(#FF0000)** |

### 7.2 明暗主题

- **机制**：`SettingsStore.themeMode`（system/light/dark）为权威 → `ThemeManager` 计算 `isDark` 写 AppStorage → 组件 `@StorageProp('isDark')` + `getThemeColors()` 响应式取色。**组件不得自行判断深浅色**。
- **达标现状**：主题切换实时生效、状态栏内容色同步 ✅。
- **P0 缺口**：播放队列半模态面板硬编码 `Color.White` 背景 + `Color.Black` 文字，深色模式下为纯白底黑字，是**唯一用户可感知的明暗断裂** → **R-09（设计侧 P0，M1 修复）**。
- **原则**：任何新增面板/弹窗/半模态**必须**通过 `getThemeColors()` 取色，禁止字面量颜色。

### 7.3 版式、间距与形状

| 项 | 规范 |
|---|---|
| 字号 | 统一 `fp`（跟随系统字体，无障碍必需）。已达标 ✅ |
| 间距 | 走 `float.json`（`common_padding=16vp` 等），避免内联 `{left:16,right:16}` 与 `$r()` 混用 |
| **圆角** | 当前发散（12/14/16/20/22/32）。收敛为 `radius_sm/md/lg/xl`（建议 8/12/16/24）统一引用 → R-28 |
| 留白 | 极简留白风格：内容优先、弱化分隔线、以间距而非线框划分区块 |
| 布局单位 | 一律 `vp`；禁止 `px` 硬编码 |

### 7.4 组件选型（HarmonyOS 规范组件优先）

| 场景 | 组件 | 备注 |
|---|---|---|
| 应用级导航 | `Navigation` / `HdsNavigation` + `NavPathStack` + `NavDestination` | ✅ 已采用系统命名路由 |
| 底部 Tab | `Tabs(barHeight:0)` + 自建胶囊栏 + `SymbolGlyph` | 自定义玻璃态（`BlurStyle.COMPONENT_ULTRA_THICK`）；偏离标准 TabBar，属可接受的品牌化 |
| 列表 | `List` + `LazyForEach` + `ListItem`（`@Reusable`） | lg 下应 `.lanes()` 多列（R-12） |
| 半模态 | `bindSheet` + `@Builder` | 详情/加入歌单已主题化 ✅；队列面板待主题化（R-09） |
| 弹窗 | `CustomDialogController` | **禁 `@State` 修饰**，只能普通成员 new（红线，已合规） |
| 长按菜单 | `bindContextMenu` | ✅ 标准用法 |
| 表单控件 | `Toggle(Switch)` / `Select` / `Slider(OutSet)` | `selectedColor` 用 `accent` 令牌 |
| 栅格 | `GridRow` / `GridCol` | 播放页分栏 |
| 图标 | **优先 HarmonyOS `SymbolGlyph` 矢量符号** | 当前 121 个媒体资源 png/svg 混用；png 不利主题着色与光学对齐，应统一为可着色 svg 或系统 Symbol → R-29 |
| 空/加载/错误态 | `Column` + `Image` + `LoadingProgress` / `Button` | 三态须可区分（`FR-A6`） |
| **组件复用（关键）** | 歌曲列表项 `buildSongItem` + 长按菜单 `buildSongMenu` 在 3 个页面近乎复制（各 ~60–90 行） | **抽公共 `@Component SongListItem` + `@Builder songContextMenu`** → R-30 |

### 7.5 动效原则

| 原则 | 说明 |
|---|---|
| **一镜到底优先** | 列表 → 播放页使用 `geometryTransition('player_cover', {follow:true})` + `animateTo(interpolatingSpring)` 共享元素转场，符合 HarmonyOS 转场规范 ✅ |
| 错峰入场 | 列表项 `TransitionEffect.OPACITY.combine(translateY)` + `delay: index*50`，方向正确 ✅ |
| **按压反馈统一** | 当前手写 `.onTouch` 缩放且时长不一（120/150ms），须抽取 `@Extend`/`@Styles` 统一曲线与时长 → R-31 |
| 动画驱动方式 | 循环动效用 `animateTo` 递归而非 `setInterval` 驱动属性（已达标，避免属性动画与显式动画冲突）✅ |
| 时长基线 | 微交互 120–200ms；页面转场 300–400ms；避免超过 500ms |
| **可降级** | 「降低动态效果」开启时，转场降级为淡入淡出、关闭呼吸/流光等装饰动效 → R-18 |
| 克制 | 动效服务于空间关系与状态反馈，不做无意义装饰 |

### 7.6 设计债清单（来自 `review_design.md`）

| 优先级 | 内容 | 对应风险 |
|---|---|---|
| **P0** | 播放队列面板深色断裂 | R-09 |
| P1 | 品牌色令牌收敛 + 深色资源补齐 + 双源统一 | R-10 |
| P1 | 抽取 `SongListItem` 公共组件（消除 3 处复制） | R-30 |
| P1 | lg 主列表多列 / 主从双栏 | R-12 |
| P1 | 安全区策略统一 | R-13 |
| P1 | 去 iOS 调色板，回归 HarmonyOS 品牌 | R-27 |
| P2 | 圆角令牌收敛 / 按压态统一 / 图标体系统一 / 无障碍语义 / 文案资源化 / 死常量清理 | R-28、R-31、R-29、R-18、R-22 |

---

## 8. 数据模型与持久化

### 8.1 核心实体 `SongItem`（单一真源：`models/music.ets`）

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `number` | **稳定主键**。收藏、歌单引用、历史一律以此为键，**绝不使用会漂移的队列下标** |
| `title` | `string` | 标题（解析失败降级为文件名） |
| `singer` | `string` | 艺术家 |
| `album` | `string` | 专辑 |
| `author` | `string` | 作者 |
| `src` | `string` | **沙箱文件路径**（`filesDir/download/...`），播放 fd 来源 |
| `index` | `number` | 列表序号（展示用，非主键） |
| `lyric` | `string` | 歌词文本 / 来源标记 |
| `mark` / `label` | `Resource \| undefined` | 封面兜底资源（真实封面经 `CoverCache` 动态取，见下） |
| `isDarkBackground` | `boolean` | 封面取色得出的背景明暗，驱动歌词/文字对比色 |
| ~~`year`~~ | — | **⚠️ 缺失**：`AudioMetaReader` 能解析 `year`，但实体无此字段，解析结果被丢弃 → **R-15**（`FR-F5`） |

**行为方法**：`getMark()` / `getLabel()` 按 `CoverCache.get(src)` → `mark`/`label` → `$r('app.media.ic_default_cover')` 三级降级取封面。

> **设计要点**：`PixelMap` 封面**不进入实体也不进入 AppStorage**，由 `CoverCache` 持有；UI 通过 `coverRefreshToken` 信号量变化触发重读。这是本项目处理大图的正确范式，不可退化为"把 PixelMap 塞进状态"。

### 8.2 `Playlist`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `string` | `时间戳_随机` 防重 |
| `name` | `string` | 歌单名（trim 后写入，重名校验） |
| `songIds` | `number[]` | **仅存 `SongItem.id` 引用**，顺序即歌单顺序（拖拽排序改此数组） |
| `coverUri?` | `string` | 可选自定义封面 |

> **引用完整性**：删歌时必须清理所有歌单中的悬挂 `songId`（`MusicStore.removeSong` 已实现）。跨页只传 `playlistId`，落地页回查，避免副本不同步。

### 8.3 持久化布局（三套 preferences，均在应用沙箱）

| 存储 | PREF 名 | 封装 | 承载内容 | 加密 |
|---|---|---|---|---|
| 曲库域 | `music_store` | `services/MusicStore.ets` | `songs`、`playList`、`currentIndex`、`isPlaying`、`repeatMode`、`favorites`(Set→数组)、`playlists`、`recentlyPlayed`、幂等标记 `meta_scanned_v1` | 明文（低敏感，NFR-SEC-07） |
| 设置域 | `app_settings` | `utils/SettingsStore.ets` | `themeMode`、`autoNext`、`repeatMode`、`notificationLockScreen`、`privacyStats`、`reduceMotion` | 明文 |
| 系统集成域 | `myStore` | `utils/PreferencesUtil.ets` | 桌面卡片 `formIds`、权限引导标记 `permGuideShown`、静音标记（**当前混入 formIds，应独立**） | 明文 |

**持久化契约（红线）**：
1. 表现层/业务层**禁止**裸调 `dataPreferences`/`preferences`，必须经三套封装之一。
2. 所有 `.get()/.put()/.getPreferences()` 必须 `try/catch`；落盘异常仅 `Logger.error` 不向上抛（避免打断听歌主流程）。
3. `SettingsStore` 在 `pref` 未初始化时 `set*` **静默 no-op** → 任何设置写入必须在 `EntryAbility` 完成 `init` 之后（当前成立，须作为契约守护）。
4. `favorites` 内存为 `Set<number>`，序列化时转数组。

### 8.4 三条「歌曲列表」概念契约（**最易误读，务必遵守**）

| # | 名称 | 角色 | 读取方式 | 写者 |
|---|---|---|---|---|
| 1 | `MusicStore.songs` | **曲库（持久权威）** | `MusicStore.getInstance().songs` 或数据源 | 仅 `MusicStore` |
| 2 | `AudioRendererController.songList` | **当前播放队列（运行时权威）** | `getQueue()`（返回副本） | 仅 `AudioRendererController` |
| 3 | `AppStorage.songList` | **队列的 UI 镜像** | `@StorageLink('songList')`（ControlArea/Lyrics/MusicInfo） | 仅 `syncQueue()` |

**契约**：
- 想读"用户有哪些歌" → **走 ①**；想读"现在在播的队列" → **走 ③（或 ② 的 `getQueue()`）**。二者语义不同，不可互换。
- `syncQueue()` 是 AppStorage 与 AVSession 的**唯一回写点**。
- `reconcileWithLibrary()` 是①与②的**唯一对齐点**，仅在导入/删歌后调用；**不得**在进入播放页时调用（会覆盖用户手动编辑的队列）。
- `MusicStore.playList` 为历史冗余字段，`setSongs` 时复制但后续增删不同步，**存在 stale 风险**，"播放全部"等场景不得读它 → R-21。
- **命名与注释须显式标注**上述三者角色，降低认知负担 → R-08。

### 8.5 桌面卡片 `formId` 契约

| 项 | 约定 |
|---|---|
| 登记 / 注销 | `FormAbility.onAddForm` → `PreferencesUtil.addFormId`；`onRemoveForm` → `removeFormId` |
| 存储 | `myStore` 的 `formIds: string[]` |
| 状态推送 | 主应用 `AVSessionController.pushFormUpdate()` 遍历 `formIds` → `formProvider.updateForm` 写 `title`/`artist`/`isPlaying` |
| 卡片侧取值 | `WidgetCard` 用 `@LocalStorageProp('title'\|'artist'\|'isPlaying')` |
| 回控通路 | 卡片为**独立进程，不可直接调播放 API**；必须 `postCardAction(router)` 拉起 `EntryAbility` → `handleControlWant` → `AVSessionController.remoteControl(cmd)` |
| **数据纯净性（缺口）** | `formIds` 数组**必须只含真实卡片 ID**。当前静音标记 `SILENT_ID='silentId'` 被当作 magic 字符串混入，`pushFormUpdate` 遍历时误调 `updateForm`（异常被 catch 吞掉，良性但属数据模型污染）→ **R-17** |
| 异常健壮性（缺口） | `getFormIds` 异常分支返回**永不 resolve/reject 的 Promise**，会导致 `pushFormUpdate`/`setSilentModeAndMixWithOthers` 静默挂起，须改为 `return []` 或 `reject` → **R-14** |

### 8.6 设置项清单

| 设置项 | 键 | 默认 | 联动副作用 |
|---|---|---|---|
| 主题模式 | `themeMode` | `system` | `ThemeManager` 刷新 + `applyToWindow()` 状态栏重绘 |
| 自动下一首 | `autoNext` | 开 | 播放结束行为 |
| 播放模式 | `repeatMode` | `list` | **联动** `MusicStore.setRepeatMode` + AVSession `LoopMode` |
| 锁屏媒体控制 | `notificationLockScreen` | 开 | **联动** `AVSessionController.setLockScreenControl`（激活/停用 AVSession） |
| 听歌统计 | `privacyStats` | 开 | 本地统计累计开关（数据绝不出网） |
| 降低动态效果 | `reduceMotion` | 关 | 应统一降级动画（当前未消费，R-18） |

> **隐式副作用须显式化**：`repeatMode`→MusicStore、锁屏→AVSession 属跨类隐式联动，须在代码注释与文档双处标注，避免后续维护者只改一处。

### 8.7 数据生命周期

| 阶段 | 行为 |
|---|---|
| 启动 | AppStorage 播种（context/uiContext/window/systemIsDark/currentBreakpoint）→ `MusicStore.init` → `ThemeManager.init` → `CoverCache.preload` → `AppStorage.songList` 初值 → `coverRefreshToken` |
| 运行 | 曲库/歌单/收藏/历史变更即时落盘；播放态经 AppStorage 广播；卡片跨进程推送 |
| 删除 | 删歌 → 清收藏 + 清歌单悬挂引用 + evict 封面/歌词缓存 + 队列对齐 |
| 备份 | `EntryBackupAbility` + `backup_config`，覆盖三套 preferences |
| 卸载 | 沙箱数据随应用卸载清除（含用户导入的音频副本），须在隐私政策说明 |

---

## 9. 里程碑与版本规划

### 9.1 里程碑总览

| 里程碑 | 版本 | 主题 | 目标 | 退出准则（Exit Criteria） |
|---|---|---|---|---|
| **M1** | `v2.3.1` | **合规整改上架** | 清零上架阻断项，达成"合规可上架" | ① 体检 P0 = 0；② 安全/合规 P1 全部关闭；③ 真机验证后台播放 30 分钟不挂起；④ 隐私政策四方一致（应用内/AGC/权限声明/代码行为）；⑤ `vendor` 与 `bundleName` 定案；⑥ 提交华为审核通过 |
| **M2** | `v2.4.0` | **体验与设计债打磨** | 消除用户可感知的一致性缺陷，补齐无障碍 | ① 明暗断裂 0 处；② 颜色令牌单一来源、深色资源补齐；③ `SongListItem` 公共组件落地；④ `reduceMotion` 全局生效；⑤ 图标按钮无障碍语义 ≥ 90%；⑥ 安全区策略统一 |
| **M3** | `v2.5.0` | **多端扩展** | 从"手机 + 折叠屏"扩展到平板 | ① `deviceTypes` 含 `tablet`；② lg 主列表多列或主从双栏；③ 折叠屏全页面展开态适配；④ 平板 + 折叠屏真机/模拟器回归通过 |
| **M4** | `v3.0.0` | **架构演进（可选）** | 降低状态复杂度，提升可测试性 | ① 播放状态收敛为可测试状态机；② `SongItem` 补 `year` 等字段、播放模式类型统一；③ 控制器接口化 + 无设备单测；④ 细粒度状态更新替代大数组整段重渲染 |

### 9.2 M1 — 合规整改上架（最高优先，建议 1 个迭代内完成）

| 序 | 任务 | 风险 ID | 等级 | 维度 | 工作量 |
|---|---|---|---|---|---|
| 1 | **重写隐私政策**：如实列 3→2 项权限、披露投播局域网传输、披露第三方外链跳转、删除不存在的存储/音频权限描述、与 `perm_guide_message` 对齐 | R-01 | 🔴 **P0** | 安全/法务/产品 | M |
| 2 | AGC 后台隐私政策与应用内保持一致 | R-01 | 🔴 **P0** | 发布 | S |
| 3 | 补 `module.json5` → EntryAbility → `"backgroundModes": ["audioPlayback"]` | R-02 | 🟠 P1 | 合规/开发 | **XS（一行）** |
| 4 | 删除 `GET_NETWORK_INFO` 权限声明 | R-03 | 🟠 P1 | 安全 | XS |
| 5 | 统一日志脱敏（8 处路径改 `sanitize()` 或 `*Private()`）并立日志规范 | R-04 | 🟠 P1 | 安全 | S |
| 6 | `vendor: "example"` → 真实主体 | R-06 | 🟠 P1 | 发布 | XS |
| 7 | `bundleName` 大小写定案（上架后不可改） | OQ-01 | 🟠 P1 | 发布/决策 | XS |
| 8 | 修 `getFormIds` 永不应答 Promise（`return []`） | R-14 | P1/P2 | 架构 | XS |
| 9 | 修播放队列面板深色断裂 | R-09 | 🔴 设计 P0 | 设计/开发 | S |
| 10 | 补 `internet_reason` 涵盖外链 | R-25 | P2 | 安全 | XS |
| 11 | 回归：后台播放真机 30 分钟、投播连断、卡片回控、备份恢复 | — | — | 测试 | M |

> **M1 关键判断**：真正的重活只有第 1 项（隐私政策重写，涉及法务口径）；第 3、4、6、7、8、10 项合计代码改动不足 20 行，但直接决定上架成败与后台播放这一核心功能是否真正生效。**建议第 3 项立即修复并真机验证——它意味着"后台播放"这一 Must 需求当前实际处于失效状态。**

### 9.3 M2 — 体验与设计债打磨

| 任务 | 风险 ID | 维度 |
|---|---|---|
| 颜色令牌收敛为单一来源 + 补 `dark/color.json` + 替换约 40 处内联品牌色 | R-10 | 设计/开发 |
| 抽取 `SongListItem` + `songContextMenu` 公共组件（消除 3 处 60–90 行复制） | R-30 | 架构/设计 |
| 去 Apple HIG 调色板，分类图标/统计回归 HarmonyOS 品牌 | R-27 | 设计 |
| 安全区策略统一（`expandSafeArea` 或 NavDestination 层统一注入） | R-13 | 设计/开发 |
| `reduceMotion` 全局消费 + 图标按钮 `accessibilityText` + 对比度达 AA | R-18、R-24 | 无障碍 |
| 三条歌曲列表概念以命名/注释显式化；删歌入口收口至 `MusicStore.removeSong` | R-08、R-14 | 架构 |
| `SILENT_ID` 从 formIds 解耦为独立键 | R-17 | 架构/安全 |
| 圆角/按压态/图标体系统一；文案资源化；死常量清理 | R-28、R-31、R-29、R-22 | 设计 |
| 文件 API 统一至 `@kit.CoreFileKit`（3 处） | R-26 | 开发 |
| 歌词缓存 LRU / 容量上限 | R-20 | 性能 |
| 首启增加隐私政策入口与明确同意动作 | R-08(F-05) | 合规 |
| picker 拷贝失败不持久化受限 URI | R-16 | 健壮性 |
| 清理 `getDeviceInfo()` 死代码 | R-07 | 安全 |

### 9.4 M3 — 多端扩展

`deviceTypes` 增 `tablet` → lg 主列表多列 / 主从双栏 → 折叠屏全页面展开态 → 大屏资源限定词 → 平板与折叠屏回归。

### 9.5 M4 — 架构演进（可选）

播放状态机收敛 → `SongItem` 补 `year`（`FR-F5`）与播放模式类型统一（R-19）→ `as ESObject` 收敛（R-05）→ 控制器接口化 + 无设备 CI → 细粒度状态更新（NFR-PERF-06）→ 原生层能力前移（`FR-F6`）。

---

## 10. 风险与开放问题

### 10.1 风险登记册

> 来源：`review_security.md`（F-xx）、`review_compliance.md`（F-x）、`review_architecture.md`（§5）、`review_design.md`（F-x）。
> 等级：🔴 P0 = 上架阻断 / 核心功能失效；🟠 P1 = 强烈建议发布前修复；🟡 P2 = 加固与一致性。

#### 🔴 P0 — 上架阻断（M1 必修）

| ID | 来源 | 风险 | 影响 | 整改建议 | 负责维度 |
|---|---|---|---|---|---|
| **R-01** | 安全 F-01 | **隐私政策与真实权限/真实行为严重不一致**：① 声称"绝不把任何数据传输出手机""无第三方"，但**投播会把本地音频经局域网发往用户选定设备**，且应用会**打开第三方外链** `a703201sworld.top`；② 政策列出"读取本地音频文件""应用存储（文件/媒体）"等**实际并未申请**的权限；③ **完全未提及真实申请的 `INTERNET`/网络权限与投播**；④ 与 `string.json` 的 `perm_guide_message`（已说明"网络连接：发现局域网投播设备"）自相矛盾 | **上架一票否决级**。隐私声明与实际权限/行为一致性是华为审核强校验项与最典型驳回点 | 重写 `pages/PrivacyPolicy.ets`：如实列出实际申请权限及用途；明示"投播会将当前歌曲经局域网传输至你选定的设备"；明示"应用会跳转至开发者主页等第三方网页，由第三方提供"；删除不存在的存储/音频权限表述；与 `perm_guide_message` 口径一致；AGC 后台同步一致文本；**最终表述建议由法务/产品复核** | 安全 / 合规 / 法务 / 产品 |
| **R-09** | 设计 F-0 | **播放队列半模态面板深色模式断裂**：`ControlAreaComponent` 硬编码 `Color.White` 背景 + `Color.Black` 文字，深色主题下为纯白底黑字；当前播放项用 `Color.Red` 而非品牌 `accent` | 唯一用户可感知的明暗断裂，直接损害品质观感与主题一致性承诺（`FR-H3`） | 面板背景/文字改用 `getThemeColors().cardBg/primaryText/secondaryText`；当前播放项改 `accent`；封装为受 `isDark` 驱动的主题化 Sheet | 设计 / 开发 |

#### 🟠 P1 — 发布前强烈建议修复

| ID | 来源 | 风险 | 影响 | 整改建议 | 负责维度 |
|---|---|---|---|---|---|
| **R-02** | 合规 F-1 | **`module.json5` 的 EntryAbility 缺 `"backgroundModes": ["audioPlayback"]`**。官方要求长时任务除 `KEEP_BACKGROUND_RUNNING` 权限外还须声明 `backgroundModes`，否则 `startBackgroundRunning` 返回 `BusinessError` | **核心功能运行期失效**：后台音频播放会被系统挂起，`FR-B9`（Must）实际不成立 | 在 `abilities` → `EntryAbility` 增加 `"backgroundModes": ["audioPlayback"]`。权限已具备，**仅需补一行**；修复后必须真机验证息屏 30 分钟连播 | 合规 / 开发 |
| **R-03** | 安全 F-02 | **`GET_NETWORK_INFO` 声明未使用**：全仓无 `NetConnection`/`getNetCapabilities` 调用 | "声明了却未使用的权限"属典型驳回项，也违背权限最小化承诺 | 从 `requestPermissions` 删除该条；若后续确需探测网络状态再补回并配理由 | 安全 |
| **R-04** | 安全 F-03 | **用户媒体文件路径经 Logger 明文写入系统日志**（8 处，含歌名）：`Logger.info/error` 底层用 `hilog %{public}s`，**release 构建仍明文可见**。位置涵盖 `SongItemBuilder`、`AudioRendererController.loadAndPlay`、`MediaTools`、`CoverCache`、`EmbeddedLyricReader`、`AVSessionController` | 个人媒体信息（歌名/沙箱路径）泄漏至系统日志，隐私风险且与"数据不出机"承诺相悖 | 路径一律经 `AudioMetaReader.sanitize()` 仅留文件名，或改用 `Logger.*Private()`（`%{private}s`，release 自动脱敏）；**建立日志规范：禁止 `%{public}` 打印任何用户文件/媒体信息**，纳入 CI 检查 | 安全 |
| **R-06** | 安全 §七-10 | `AppScope/app.json5` 的 `vendor` 为占位值 `"example"` | 上架资料不真实，影响审核与品牌呈现 | 改为真实主体名称（版权主体为「何宇翔」，须与 AGC 开发者主体一致） | 发布 |

#### 🟡 P2 — 加固与一致性（M2 起排期）

| ID | 来源 | 风险 | 影响 | 整改建议 | 负责维度 |
|---|---|---|---|---|---|
| **R-08** | 架构 §5 P1-1 | **三条"歌曲列表"概念混淆**：`MusicStore.songs`（曲库）/ `AudioRendererController.songList`（队列权威）/ `AppStorage.songList`（队列镜像）易被页面误读 | 误读导致"曲库当队列用"或反之，引发队列漂移类缺陷 | 以命名/注释显式标注三者角色（见 §8.4 契约）；读曲库走 `MusicStore`，读队列走 `AppStorage.songList`/`getQueue()` | 架构 |
| **R-14** | 架构 §5 P1-2 | **`PreferencesUtil.getFormIds` 异常分支返回永不应答 Promise**（既未 resolve 也未 reject）；另：队列对齐依赖各页面手动调用 `reconcileWithLibrary`，新增删歌入口易遗漏 | 若 `getPreferences` 抛错，`pushFormUpdate`/`setSilentModeAndMixWithOthers` 的调用方将**静默挂起**（卡片不再更新且无报错）；对齐遗漏会导致 `next/prev` 跳到已删文件 | 改为 `return []` 或 `reject`；将 `reconcileWithLibrary` 收口到 `MusicStore.removeSong` 内统一触发。**架构报告定级 P1、修复成本极低（数行），建议提前并入 M1** | 架构 |
| **R-15** | 架构 §5 P1-3 | **`year` 解析后未持久化**：`AudioMetaReader` 能解析 `year`，但 `SongItem` 无 `year` 字段，`refreshMetadataIfNeeded` 仅写 `title/artist/album/author`，`year` 被丢弃 | 对外若宣称"年代全链路"则与实现不符（功能承诺风险） | 二选一：① 补 `SongItem.year` 字段 + 持久化 + 详情页展示（`FR-F5`，M4）；② **从对外功能描述中移除"年代"承诺**。须明确决策，见 OQ-05 | 架构 / 产品 |
| **R-17** | 安全 F-10 / 架构 §5 P1-5 | **`SILENT_ID='silentId'` 混入桌面卡片 `formIds` 数组**，`pushFormUpdate` 遍历时误当卡片 ID 调 `formProvider.updateForm`（当前异常被 catch 吞掉，良性） | 数据模型污染、关注点耦合，影响健壮性与可维护性 | 静音标记独立为 Preferences 键（如 `KEY_SILENT_MODE`），与 `formIds` 解耦；`pushFormUpdate` 即无需过滤 | 架构 / 安全 |
| **R-05** | 安全 F-09 / 架构 §5 P2-2 | **`as ESObject` 类型逃逸**：`AVSessionController:428-429`（`castController as ESObject` 绕过 `off` 重载不匹配）、`AudioMeta.ets:58`（native 返回值未结构化） | 削弱编译期类型安全，可能掩盖运行时契约错误（非安全漏洞） | 为 native `parseAudioMetadata` 返回值定义具名接口并结构化解析；`castController.off` 改为具体签名断言或封装方法；如必须逃逸则集中封装 + 运行时校验 + 注释 | 架构 / 安全 |
| **R-19** | 架构 §5 P2-1 | **播放模式三套类型不一致**：`models.RepeatMode`（`'single'\|'list'\|'random'`）、`SettingsStore.RepeatModeSetting`（`'list'\|'single'\|'random'`）、`PlayerData.MusicPlayMode`（数值枚举 0/1/2） | 跨层转换易出错，是"模式显示与实际行为不一致"类缺陷的温床 | 统一为单一类型（建议保留一个字符串联合类型 + 一处映射函数），消除散落转换 | 架构 |
| **R-20** | 架构 §5 P2-4 | `EmbeddedLyricReader` 静态缓存**无容量上限**，仅删歌时 `evict` | 超大曲库长期使用内存持续增长 | 引入 LRU 或容量上限（`FR-C8`） | 性能 / 架构 |
| **R-21** | 架构 §5 P2-6 | `MusicStore.playList` 在 `setSongs` 时复制自 `songs`，后续增删**不同步** | "播放全部"等若读 `playList` 会拿到旧数据 | 统一以 `songs` 为源，删除冗余 `playList`，或在变更时同步 | 架构 |
| **R-16** | 安全 F-08 | DocumentViewPicker 拷贝失败时回退 `srcPath = uri`，**持久化受限 picker URI**；该授权有时效 | 长期持久化后授权失效，导致播放/元数据读取失败 | 拷贝失败不写库，标记导入失败并提示重选（`FR-A2` AC③） | 健壮性 |
| **R-18** | 设计 F-10 | 无障碍三缺口：图标按钮缺 `accessibilityText`；`reduceMotion` 已持久化但**未在动画处统一消费**；固定高度在超大字体下可能挤压文本 | 读屏用户无法识别控件；动效敏感用户设置无效 | 补语义标签；`reduceMotion` 为真时降级/关闭非必要动画；固定高度改自适应 | 无障碍 / 设计 |
| **R-10** | 设计 F-1/F-2/F-4 | 品牌色 `#FA2759` 内联硬编码约 40 处、`ThemeManager.accent` 几乎未被引用；颜色**双源**（ThemeManager 令牌 + `color.json` 资源令牌）；`dark/color.json` 仅覆盖 `start_window_background`，其余 `$r('app.color.*')` 深色回退浅色 | 主题一致性脆弱、改色成本高、深色下细节偏色 | 收敛为单一颜色来源 + 新增 `accent`/`accentSoft` 令牌 + 补齐深色变体（`FR-H4`） | 设计 / 开发 |
| **R-30** | 设计 F-12 | 歌曲列表项 `buildSongItem` + 长按菜单 `buildSongMenu` 在 3 个页面近乎复制（各 60–90 行） | 改一处漏两处，是一致性缺陷的高发区 | 抽取公共 `@Component SongListItem` + `@Builder songContextMenu` | 架构 / 设计 |
| **R-12** | 设计 F-3 | 主列表（曲库/收藏/歌单/历史）在 lg 下仍单列，仅播放队列用 `.lanes()`；`deviceTypes` 未含 `tablet` | 平板/折叠屏展开态信息密度低、留白突兀；未声明 tablet 无法上架平板 | lg 下多列或 `Navigation` 主从双栏；`deviceTypes` 增 `tablet`（M3） | 设计 / 开发 |
| **R-13** | 设计 F-5 | 安全区策略不统一：`expandSafeArea` 与手写 `topHeight/bottomHeight` padding 混用 | 不同页面沉浸表现不一致，易出现遮挡或多余留白 | 统一约定：内容页统一 `expandSafeArea`，或在 `NavDestination` 层统一注入安全区内边距 | 设计 / 开发 |
| **R-27** | 设计 F-6 | 分类图标底色与统计数字使用 **Apple HIG 调色板**（`#34C759/#FF9500/#007AFF/#5E5CE6/#FFCC00/#5856D6`） | 非 HarmonyOS Design 调色板，多色削弱品牌 `#FA2759` 识别度 | 改用 HarmonyOS 语义/品牌色或统一中性底色；分类图标优先单色 Symbol | 设计 |
| **R-24** | 设计 F-11 + §6 | 次要文字 `#636366` 硬编码与 `secondaryText` 令牌不一致；浅色 `secondaryText=#8E8E93` 白底对比度约 3.5:1，接近 AA 阈值 | 视觉不统一 + 可读性风险 | 统一回令牌；评估加深或加粗以达 WCAG AA | 设计 / 无障碍 |
| **R-28** | 设计 F-7 | 圆角尺度发散（12/14/16/20/22/32），无统一半径令牌 | 形状语言不统一 | `float.json` 定义 `radius_sm/md/lg/xl`（8/12/16/24）统一引用 | 设计 |
| **R-31** | 设计 F-8 | 按压反馈手写 `.onTouch` 缩放，重复度高、时长不统一（120/150ms） | 交互手感不一致 | 抽取 `@Extend`/`@Styles` 统一按压态曲线与时长 | 设计 |
| **R-29** | 设计 F-9 | 图标体系混杂：121 个资源 png/svg 混用，并与系统 `SymbolGlyph` 混用；png 不利主题着色 | 深色模式着色困难、光学对齐不一致 | 优先 HarmonyOS Symbol；自定义图标统一为可着色 svg + 统一线宽 | 设计 |
| **R-22** | 设计 F-14 | 大量硬编码中文文案未资源化 | 不利多语言与文案统一维护 | 用户可见文案迁移 `string.json`（`FR-I10`） | 设计 / 开发 |
| **R-11** | 设计 §5 | 折叠屏展开态仅 `PlayerInfoComponent` 处理，其余页面未适配 | 内屏展开后列表页布局单薄 | 扩展折叠态双栏思路至主要列表页（M3） | 设计 |
| **R-23** | 架构 §5 P2-5 | `BreakpointSystem` 构造期读 AppStorage `uiContext`；`SongItemBuilder`/`AudioRendererController`/`PlayerInfoComponent` 在字段初始化器读 `AppStorage.get('context')`（合规 F-4） | **隐式时序依赖**：若任何消费者在 `EntryAbility` 播种前被构造，会静默拿到 `undefined` | 改显式注入（`init(context)`/构造参数）或惰性读取；`BreakpointSystem` 延迟到 `register()` 内取 | 架构 |
| **R-26** | 合规 F-3 | 3 处仍用旧版文件 API `@ohos.file.fs`（`LocalLibrary`/`SettingsCategory`/`SongDetailSheet`），其余已用 `@kit.CoreFileKit` | 一致性差 + 未来弃用风险 | 统一迁移至 `@kit.CoreFileKit` 的 `fileIo.*` | 开发 |
| **R-32** | 合规 F-2 | `lyric/LrcView.ets:112` 在**字段初始化器**中调用 `getUIContext().createAnimator()`，此时组件尚未挂载 | 上下文可能未就绪，导致创建异常（实际风险有限，`:241` 已在方法中重建） | 移至 `aboutToAppear()` 或首次使用时惰性创建 | 开发 |
| **R-07** | 安全 F-07 | `NativeModule.getDeviceInfo()`（采集 brand/osType）**已定义但全仓未调用**（死代码） | "能力存在即风险"；若将来误启用会构成未披露采集 | 删除死代码；如确需设备信息须先在隐私政策补充并评估最小必要 | 安全 |
| **R-25** | 安全 F-04 | `internet_reason` 仅写"局域网投播"，未涵盖"外链跳转" | 权限理由未如实覆盖全部用途 | 改为"用于局域网投播（Cast+/DLNA）设备发现与媒体流传输，以及跳转开发者主页等外链" | 安全 |
| **R-33** | 安全 F-05 | 首启仅"知道了"式告知，**无明确的隐私政策同意动作** | 对离线低采集应用风险可控，但非强合规形态 | 首启弹窗增加「查看隐私政策」入口与明确同意确认（`FR-I9`） | 合规 |
| **R-34** | 安全 F-06 | 本地数据以 `preferences` **明文 JSON** 存储 | 当前为低敏感本地数据 + 沙箱隔离，风险低；**但若未来引入账号/同步/敏感信息则风险升级** | 现阶段作为加固建议；引入敏感数据时改用 Asset Store 或应用级加密（NFR-SEC-07） | 安全 |
| **R-35** | 架构 §5 P2-7 | C++ 已解析 `durationMs/sampleRate/channels` 但未被采用，时长仍取自 MediaKit | 原生能力闲置，MediaKit 失败时无兜底 | MediaKit 失败时以 C++ 结果兜底（`FR-F6`） | 架构 |

### 10.2 开放问题（待确认，需决策人拍板）

| ID | 问题 | 背景与影响 | 建议 | 需谁决策 | 截止 |
|---|---|---|---|---|---|
| **OQ-01** | **`bundleName` 大小写以哪个为准？** | `AppScope/app.json5` 实际为 **`com.Lumio.music`**（大写 L），而文档与团队口径常写 `com.lumio.music`。**bundleName 一经上架不可更改**，且 HarmonyOS 惯例为全小写反域名 | 若尚未上架，**建议统一为全小写 `com.lumio.music`** 并同步 AGC 与全部文档；若 AGC 已注册 `com.Lumio.music`，则以 AGC 为准并修正所有文档 | 发布负责人 | **M1 提交前（阻断）** |
| **OQ-02** | `vendor` 填写主体名称？ | 当前占位 `"example"`；源码版权主体为「何宇翔」 | 与 AGC 开发者主体（个人/企业）保持一致 | 发布负责人 | M1 |
| **OQ-03** | 外链 `a703201sworld.top` 的归属与稳定性？ | 「关于开发者」跳转此站。隐私政策须声明"由第三方提供"；若该站为开发者本人所有，表述应改为"开发者主页"并说明其数据处理方式；域名若失效会造成死链 | 确认归属与可用性；在政策中如实定性；考虑外链前增加"即将离开应用"提示 | 产品 / 法务 | M1（并入 R-01） |
| **OQ-04** | 路由目的地数量以 11 还是 12 为准？ | `route_map.json` 实际注册 **11 个**；此前"12 个"源于 `review_architecture.md` §3.14 枚举时把 `Layout` 重复计入。`LocalLibrary`/`Mine` 是 `Layout` 内的 Tab 视图，非独立路由 | **统一采用 11 个命名路由 + 2 个 Tab 视图（共 13 个页面级视图）**；回填架构文档纠正笔误 | 架构 | M1（文档修正） |
| **OQ-05** | 对外是否承诺"年代（year）"能力？ | 解析层已支持但 `SongItem` 无字段、未持久化、未展示（R-15） | 二选一：M4 补齐字段与展示，或**立即从对外描述中移除该承诺**。倾向后者（避免功能承诺与实现不符） | 产品 | M1（文案）/ M4（实现） |
| **OQ-06** | 平板上架是否纳入正式路线？ | 需在 `deviceTypes` 增 `tablet` 并补 lg 多列/主从双栏（R-12），工作量中等 | 建议纳入 M3；若资源紧张可仅做折叠屏展开态优化，平板延后 | 产品 / 项目 | M2 末 |
| **OQ-07** | 是否需要多语言（i18n）？ | 当前大量中文文案硬编码（R-22）。若计划海外发布须先资源化 | 若无海外计划，M2 仅做"文案资源化"以统一维护，不做翻译 | 产品 | M2 |
| **OQ-08** | 「听歌统计」的统计口径与展示？ | 设置有开关、`Mine` 有统计数字，但统计维度与计算规则未在文档定义 | 明确统计项（累计时长/歌曲数/天数等）、口径与重置规则，补入 §8.6 | 产品 | M2 |
| **OQ-09** | 是否需要应用内"导入音频文件"的沙箱容量治理？ | 音频副本存于沙箱，长期导入会占用较大空间，当前无容量提示或清理入口 | 评估增加"存储占用"展示与"清理未使用文件"能力（候选 M2/M3 需求） | 产品 | M2 |
| **OQ-10** | 隐私政策最终表述是否需法务正式复核？ | R-01 为 P0，表述直接决定审核结果 | **强烈建议法务/产品双签**后再提交；不可仅由开发自拟 | 法务 / 产品 | M1（阻断） |

### 10.3 上架 Go / No-Go 检查清单（M1 提交前逐项签字）

| # | 检查项 | 关联 | 状态 |
|---|---|---|---|
| 1 | 隐私政策已重写，如实覆盖全部权限、投播局域网传输、第三方外链 | R-01 | ⬜ |
| 2 | 应用内政策 = AGC 登记政策 = `module.json5` 权限 = 代码实际行为（四方一致） | NFR-CMP-01 | ⬜ |
| 3 | 隐私政策经法务/产品复核签字 | OQ-10 | ⬜ |
| 4 | `GET_NETWORK_INFO` 已删除，权限清单仅剩 2 项 | R-03 | ⬜ |
| 5 | `"backgroundModes": ["audioPlayback"]` 已声明 | R-02 | ⬜ |
| 6 | **真机验证：息屏后台连续播放 30 分钟未被挂起** | FR-B9 | ⬜ |
| 7 | 8 处日志路径已脱敏；release 构建日志抽查无用户歌名/路径 | R-04 | ⬜ |
| 8 | `vendor` 已改为真实主体 | R-06 | ⬜ |
| 9 | `bundleName` 已定案并与 AGC 一致 | OQ-01 | ⬜ |
| 10 | `getFormIds` 异常分支不再返回悬挂 Promise | R-14 | ⬜ |
| 11 | 深色模式全页面走查，播放队列面板无断裂 | R-09 | ⬜ |
| 12 | `internet_reason` 已涵盖外链用途 | R-25 | ⬜ |
| 13 | 回归通过：投播连断切换 / 卡片回控 / 锁屏控制 / 备份恢复 / 导入删除队列对齐 | — | ⬜ |
| 14 | ArkTS 红线体检 P0 = 0，CI 门禁通过 | NFR-CMP-05 | ⬜ |
| 15 | 版本号、`CHANGELOG.md`、上架截图与文案齐备 | — | ⬜ |

---

## 附录 A：术语表

| 术语 | 含义 |
|---|---|
| 一多 | 「一次开发、多端部署」，HarmonyOS 响应式适配方法论（本项目体现为 sm/md/lg 断点体系） |
| AVSession | HarmonyOS 媒体会话框架，接入系统锁屏/通知媒体控制与投播 |
| AVCastPicker / AVCastController | 投播设备选择器与投播控制器（Cast+/DLNA） |
| 长时任务 | `backgroundTaskManager.startBackgroundRunning`，后台持续运行机制（音频场景为 `AUDIO_PLAYBACK`） |
| NAPI | Native API，ArkTS 调用 C/C++ 的桥接机制（本项目用于音频元数据解析） |
| Stage 模型 | HarmonyOS 应用模型（UIAbility + ExtensionAbility） |
| 命名路由 | `route_map.json` 注册 + `NavPathStack.pushPathByName` 的系统级路由方案 |
| 一镜到底 | 共享元素转场（`geometryTransition`），跨页面保持元素连续性 |
| formId | 桌面卡片实例的唯一标识 |
| MoSCoW | 需求优先级方法：Must / Should / Could / Won't |
| AC | Acceptance Criteria，验收标准 |
| 负缓存 | 缓存"确认不存在"的结果，避免重复无效尝试（本项目用于封面与歌词） |

## 附录 B：需求索引

| 领域 | 需求 ID 范围 | 数量 | 已交付 | 待补齐 | 规划中 |
|---|---|---|---|---|---|
| A 导入与曲库 | FR-A1 ~ A9 | 9 | 8 | 1 | 0 |
| B 播放与队列 | FR-B1 ~ B10 | 10 | 8 | 2 | 0 |
| C 播放页与歌词 | FR-C1 ~ C8 | 8 | 7 | 1 | 0 |
| D 歌单 | FR-D1 ~ D8 | 8 | 8 | 0 | 0 |
| E 收藏与历史 | FR-E1 ~ E5 | 5 | 5 | 0 | 0 |
| F 元数据与封面 | FR-F1 ~ F6 | 6 | 4 | 1 | 1 |
| G 系统能力集成 | FR-G1 ~ G7 | 7 | 7 | 0 | 0 |
| H 主题与外观 | FR-H1 ~ H4 | 4 | 2 | 2 | 0 |
| I 设置与隐私 | FR-I1 ~ I10 | 10 | 6 | 4 | 0 |
| K 响应式与无障碍 | FR-K1 ~ K6 | 6 | 1 | 4 | 1 |
| **合计** | — | **73** | **56** | **15** | **2** |

> 「待补齐」含 `FR-I7`（隐私政策，🔴 必须重写）——该条虽已有页面实现，但内容与实际行为不一致，按缺陷计入待补齐。

> 非功能需求：NFR-PERF(7)、NFR-PWR(3)、NFR-SEC(9)、NFR-CMP(7)、NFR-A11Y(5)、NFR-CPT(6)、NFR-MNT(5)，共 **42** 条。
> 风险登记册：**35** 条（P0×2、P1×4、P2×29）；开放问题：**10** 条。

## 附录 C：文档修订记录

| 版本 | 日期 | 作者 | 变更 |
|---|---|---|---|
| v1.0 | 2026-08-18 | 计谋远（鸿蒙软件项目经理） | 首版。基于安全/合规/架构/设计四份全链路体检报告与源码核对编写。新增：完整 FR/NFR 需求基线、数据模型契约（含三条歌曲列表澄清）、风险登记册（35 项）、开放问题（10 项）、上架 Go/No-Go 清单。**纠正两处事实**：① 路由目的地为 11 个而非 12 个（OQ-04）；② `bundleName` 实际为 `com.Lumio.music` 与文档口径不一致（OQ-01）。 |

---

> **文档维护约定**：本 PRD 为需求基线，任何范围变更须更新 §5/§6 对应条目与 §9 里程碑；风险状态变化须更新 §10.1；`review_*.md` 复检后须回填本文档风险状态。**§10.3 检查清单未全绿，不得提交上架。**
