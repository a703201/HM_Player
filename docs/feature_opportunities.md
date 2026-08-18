# Lumio Music（灯屿音乐）功能机会分析报告

> 产出方：pm-planner（计谋远）｜主理人归档：齐活林｜日期：2026-08-18
> 审查范围：`docs/PRD.md`（73 FR + 42 NFR + M1–M4）、`docs/review_architecture.md` / `API.md` / `review_design.md` / `design_tokens.md`、`entry/src/main/ets` 全部 57 个源码文件、`module.json5` / `app.json5`、`CHANGELOG.md`、git 历史。
> 方法：以「代码事实为准」对照 PRD 规格，识别**已实现 / 已规格化未接线 / 文档超前或滞后于代码**三类状态，再按离线本地约束筛选可追加功能。

---

## 1. 现状：应用当前真正能做什么（基于代码，而非仅 PRD）

**重要结论：代码已明显超前于 `PRD.md` v1.0 与四份体检报告。** M1 合规整改项在代码里大多已经落地：

| 风险项（PRD 记录） | 代码现状 | 依据 |
|---|---|---|
| R-02 缺 `backgroundModes` | ✅ 已声明 `"backgroundModes": ["audioPlayback"]` | `entry/src/main/module.json5`（EntryAbility） |
| R-06 `vendor: "example"` | ✅ 已改为 `"何宇翔"` | `AppScope/app.json5` |
| R-01 隐私政策不一致 | ✅ 已重写：如实列 2 项权限（KEEP_BACKGROUND_RUNNING / INTERNET），披露局域网投播与第三方外链 `a703201sworld.top` | `pages/PrivacyPolicy.ets` |
| R-03 多声明 `GET_NETWORK_INFO` | ✅ 已删除，权限仅剩 2 项 | `module.json5` `requestPermissions` |
| R-14 `getFormIds` 悬挂 Promise | ✅ 已改异常兜底 `return []` | `utils/PreferencesUtil.ets:136-137` |
| R-17 `SILENT_ID` 混入 formIds | ✅ 已独立为 `SILENT_MODE` 键 | `utils/PreferencesUtil.ets:40,225-260` |
| R-09 队列面板深色断裂 | ✅ 已主题化（面板/列表/文字均走 `getThemeColors()`） | `components/ControlAreaComponent.ets:296-341` |
| 卡片不随主题 | ✅ `WidgetCard` 已按 `isDark` 双套取色 | `widget/pages/WidgetCard.ets:67-88` |

### ✅ 真正已实现（可运行）
1. **导入**：`DocumentViewPicker` 多选 → 拷贝进 `filesDir/download` 沙箱 → `AudioMetaReader` 双路元数据解析（MediaKit 优先 + C++ NAPI taskpool 兜底）→ `CoverCache` 后台抽封面 → `reconcileWithLibrary` 队列对齐（`pages/LocalLibrary.ets:129-204`）。
2. **播放**：AVPlayer（fd 本地播放）、上一首/下一首/进度拖拽/三态循环（顺序/随机/单曲）、空队列守卫、`playFromList`/`setQueue`/`moveToPlayNext`/`removeFromQueue`、后台长时任务（`utils/AudioRendererController.ets`）。
3. **系统集成**：AVSession 锁屏/通知媒体控制（含收藏同步、循环模式、进度回写）、Cast+ 投播（独立 fd、连断自动切换、断连进度对齐）、桌面播控卡片（状态推送 + `postCardAction` 回控 `play/pause/next/prev`）、数据备份（`EntryBackupAbility` + `backup_config`）。
4. **播放页**：封面取色光感背景（`ColorConversion` + `effectKit.createColorPicker`）、一镜到底 `geometryTransition('player_cover')`、lg/折叠屏双栏、歌词（内嵌 FLAC/MP3/MP4 定点解析 + 同名 `.lrc` 外挂回落 + LRC/KRC 解析 + 原文/翻译多数决 + 手动滑动/点击跳播）。
5. **曲库管理**：曲库列表/搜索（标题+歌手）/空态/错误态重试、单曲删除（联动清收藏/歌单悬挂引用/封面歌词缓存/队列对齐）、自建歌单（建/删/改名/加歌多选/移出/拖拽排序/播放全部）、收藏（`song.id` 主键，锁屏/卡片双向同步）、最近播放（上限 50）。
6. **设置与主题**：系统/浅/深三档、状态栏内容色同步、自动下一首开关（**未接线**）、锁屏控制开关、听歌统计开关（**未累计**）、降低动态开关（**未消费**）、缓存清理、隐私政策、开发者外链、版本。
7. **响应式**：sm/md/lg 断点 + 折叠屏双栏（`common/utils/BreakpointSystem.ets`）。

### ⚠️ 已规格化但代码里「没接上」的（第一类机会）
- 「自动下一首」开关**无效**：`AudioRendererController.ets:115-116` 在 `state==='completed'` 无条件 `playNext()`，全仓无人读 `SettingsStore.getAutoNext()`（FR-B8 空承诺）。
- 「降低动态效果」开关**无效**：`reduceMotion` 只被持久化与设置页读写，全仓动画无一处读取（R-18/F-13）。
- `year` 已解析未持久化：`AudioMetaReader` 返回 `year`，`SongDetailSheet` 打开时临时重读展示，但 `SongItem` 无字段、`MusicStore` 不落盘（OQ-05 / R-15 / FR-F5）。
- `LazyForEach` + `IDataSource` **全仓零使用**；`datasource/SongDataSource.ets`、`SongListData.ets` 已写好但无人 import（死代码/待接线）；曲库/收藏/历史/歌单全部用 `ForEach`（NFR-PERF-03）。
- 桌面卡片**不推封面/专辑/进度**：`pushFormUpdate` 只推 `title/artist/isPlaying`，卡片封面恒为 `ic_default_cover`。
- `Playlist.coverUri` 字段已声明但全仓无人使用（歌单封面「有字段无 UI」）。
- `NativeModule.getDeviceInfo()` 仍是死代码（R-07）。
- 「听歌统计」只有**计数**，没有任何累计时长/次数统计（OQ-08）。

### 📄 文档漂移提示
- PRD 标记 FR-A8 批量删除 ✅，但 `ManageSongs` 仅见单曲删除，未见多选批量（需回归确认或补齐）。
- `review_design.md` F-01 描述的队列面板硬编码白底已被修复。

---

## 2. 可追加功能优先级清单（按主题分组）

优先级：🔴 高价值优先做 ｜ 🟡 中价值可排期 ｜ ⚪ 低优先级/远期。可行性：高/中/低；工作量：XS/S/M/L。

### 主题 A — 播放体验增强

| ID | 功能 | 价值 | Kit / 依赖 | 可行性 | 工作量 | 衔接点 |
|---|---|---|---|---|---|---|
| A1 | 睡眠定时器 🔴 | 睡前听歌典型诉求，到点自动暂停/停止 | 现有 `BackgroundUtil` + 普通 Timer；无需新权限 | 高 | S | `AudioRendererController`（定时入口）、`ControlAreaComponent`/`PlayerPage`（入口）、`SettingsStore`（剩余时长持久化） |
| A2 | 断点续播（记忆上次位置）🔴 | 长音频刚需；切歌/重启续播 | 本地 `preferences`；起播时 `seek` | 中 | S/M | `AudioRendererController`（`timeUpdate` 节流记位置、loadAndPlay 前 seek）、`MusicStore`（持久化 Map，删歌清理） |
| A3 | 倍速播放（0.5×–2.0×）🟡 | 播客化/快速过歌 | `@kit.MediaKit` AVPlayer 速度接口（**需 API 24 核实公开性**） | 中 | S | `AudioRendererController`、`ControlAreaComponent`、`SettingsStore` |
| A4 | 应用内音量滑条/静音增强 ⚪ | 锁屏/系统音量不可达时调节 | `@kit.AudioKit` `AudioManager.getVolumeManager`（**需核实 MODIFY_AUDIO_SETTINGS**） | 中 | S/M | `ControlAreaComponent`（音量 Slider）、`AudioRendererController` |
| A5 | 长按上/下一首快进快退（±5s/±10s）🟡 | 低成本高感知；本地 seek 已具备 | 无新 Kit；`seek()` 已有 | 高 | XS/S | `ControlAreaComponent`（onTouch 长按计时）、`AudioRendererController:446-460` |
| A6 | 随机模式「整轮不重复」⚪ | 当前只避免与上一首连续重复 | 本地洗牌（Fisher-Yates） | 高 | S | `AudioRendererController:526-543`、`PlayerData.ets` |

### 主题 B — 曲库与组织

| ID | 功能 | 价值 | Kit / 依赖 | 可行性 | 工作量 | 衔接点 |
|---|---|---|---|---|---|---|
| B1 | 专辑视图 / 专辑详情页 🔴 | Persona A 核心诉求；`album` 字段已落盘 | 纯 ArkUI 分组；复用 `CoverCache`/`CoverImageView` | 高 | M | `LocalLibrary`（入口+分组）、`MusicStore`（只读聚合）、`route_map.json` |
| B2 | 艺术家视图 / 按歌手分组 🟡 | 同上；`singer` 字段已有 | 同 B1 | 高 | M（可与 B1 合并） | 同 B1 |
| B3 | 曲库排序（标题/歌手/专辑/添加时间）🔴 | 排序能力已存在（队列面板）只是曲库页没有 | 无新 Kit；复用 `applySort` | 高 | S | `LocalLibrary`（排序入口）、`ControlAreaComponent:348-394` |
| B4 | 本地歌单/曲库导出（m3u8 + CSV）🟡 | 数据自主权的「离线版云同步」 | `@kit.CoreFileKit` + `DocumentViewPicker.save()`（无需存储权限） | 高/中 | S/M | `Playlists`（导出菜单）、`MusicStore` |
| B5 | 批量操作（删除/收藏/加歌单）🟡 | PRD 标记已交付但代码未见（FR-A8 缺口） | ArkUI `Checkbox` 选择模式（`PlaylistDetail:349-357` 有先例） | 高 | M | `ManageSongs`（多选态）、`MusicStore.removeSong` 收口 |
| B6 | 沙箱存储管理（占用统计 + 清理未引用文件）🟡 | OQ-09 | `@kit.CoreFileKit`（已用） | 高 | S/M | `SettingsCategory`（升级 computeCacheSize/clearCache）、`MusicStore` |
| B7 | 重复歌曲检测（同文件指纹）⚪ | 导入重复文件痛点 | 本地 hash（可下沉 C++ NAPI） | 中 | M | `LocalLibrary`（导入后提示）、`NativeModule`/`napi_init.cpp` |
| B8 | 文件夹视图 / 最近添加 ⚪ | 导入平铺于 download/ | 本地字段扩展（`SongItem.addTime`） | 中 | M | `models/music.ets`、`MusicStore`、`LocalLibrary` |

### 主题 C — 个性化与主题

| ID | 功能 | 价值 | Kit / 依赖 | 可行性 | 工作量 | 衔接点 |
|---|---|---|---|---|---|---|
| C1 | 封面动态主题色（全局/播放页 accent 随封面）🟡 | 差异化观感；播放页已能取主色 | `effectKit`/`image`（已用） | 中 | M | `ThemeManager`（动态 accent）、`PlayerInfoComponent`、`ColorConversion` |
| C2 | 歌词显示设置持久化（原文/翻译 + 字号）🟡 | `showTranslation` 每次进页重置；字号硬编码 18 | `SettingsStore` 新键 | 高 | XS/S | `LyricsComponent.ets:57,258`、`LrcView.ets:105`、`SettingsCategory` |
| C3 | 歌单封面自定义（coverUri 落地）🟡 | 字段已存在无 UI | `DocumentViewPicker`（已用）+ `MusicStore` 落盘 | 高 | S | `Playlists`/`PlaylistDetail`（封面入口） |
| C4 | 自定义品牌色（可选 accent）⚪ | `ThemeManager.accent` 已令牌化 | 纯主题令牌 | 中 | S（前置 M2） | `ThemeManager`、`SettingsCategory` |

### 主题 D — 多端与系统能力

| ID | 功能 | 价值 | Kit / 依赖 | 可行性 | 工作量 | 衔接点 |
|---|---|---|---|---|---|---|
| D1 | 大屏多列 / 主从双栏（FR-K4 / M3 先导）🟡 | 折叠屏/平板信息密度 | `List().lanes()` / `Grid` / `Navigation` | 中 | M | `LocalLibrary`/`Favorites`/`Playlists` 等 lg 分支、`BreakpointSystem` |
| D2 | 文件「打开方式」导入（接受系统分享的音频）🔴 | 显著降低导入摩擦 | `@kit.AbilityKit`（EntryAbility `skills` 音频 mime + want 解析） | 中 | M | `EntryAbility`（复用 handleControlWant 模式）、`LocalLibrary`（抽出 `importUris()`） |
| D3 | 系统分享（歌曲信息文本卡片 / 歌单分享文本）🟡 | 离线定位下分享不传文件 | `@kit.ShareKit` `systemShare`（**需核实 API 24 公开性**） | 中 | S/M | `SongDetailSheet`（分享按钮）、`PlaylistDetail` |
| D4 | 桌面卡片增强（推专辑/进度 + 可选 2×2 小卡片）🟡 | 卡片信息量低 | `@kit.FormKit`（已有 updateForm 通路）；`form_config.json` 扩展 | 中 | S/M | `AVSessionController:606-634`（增字段）、`WidgetCard`、`FormAbility` |
| D5 | 应用锁（密码 / 生物识别保护）🟡 | 本地数据再加一道本地锁 | `@kit.UserAuthenticationKit`（**需核实**）或本地 PIN；`ACCESS_BIOMETRIC` normal 权限 | 中（生物识别）/高（PIN） | M | `EntryAbility`（启动鉴权门）、`SettingsCategory`、`SettingsStore` |
| D6 | 多语言（i18n）⚪ | 已有 en_US 目录 + 28 键，但用户文案大量硬编码（R-22/F-16，约 40+ 处） | `@kit.LocalizationKit` 资源限定词（已用） | 高（机械替换）/低（翻译） | M | 全页面硬编码 → `string.json` |

### 主题 E — 无障碍与效率

| ID | 功能 | 价值 | Kit / 依赖 | 可行性 | 工作量 | 衔接点 |
|---|---|---|---|---|---|---|
| E1 | `reduceMotion` 全局消费 🔴 | 开关已持久化却全仓无效（R-18/F-13），无障碍承诺空壳 | 无新 Kit | 高 | S | `LrcView`（歌词流光）、各列表（入场错峰）、`Layout:70-74`（封面旋转）、`Mine`（头像呼吸） |
| E2 | 图标按钮无障碍语义标签补全 🟡 | KPI 承诺「关键控件语义标签 ≥90%」 | ArkUI `accessibilityText` | 高 | S | `ControlAreaComponent`、`LocalLibrary`、`TopAreaComponent` |
| E3 | 本地听歌统计（时长/次数 + 可视化）🔴 | 统计开关是空壳（OQ-08）；补累计时长/次数/每日分布，纯本地 | 本地 `preferences`（`stats_*`） | 高 | M | `AudioRendererController`（timeUpdate/stateChange 累计）、`Mine`（统计卡）、`SettingsCategory` |
| E4 | 播放模式三态类型统一（R-19）🟡 | `RepeatMode`/`RepeatModeSetting`/`MusicPlayMode` 三套表示易错 | 纯类型重构 | 高 | S | `models/music.ets:46`、`SettingsStore.ets:32`、`PlayerData.ets:32-36` |

---

## 3. 被「离线本地」约束阻断 / 削弱的想法与离线替代

| 想法 | 阻断/削弱原因 | 离线友好替代 |
|---|---|---|
| 云同步 / 跨设备歌单同步 | 硬约束：无账号、数据不出机 | **本地导出 m3u8/CSV（B4）** + 现有 `EntryBackupAbility` 系统备份 |
| 在线歌词匹配 / 在线封面下载 | 需联网到歌词/封面服务 | 已实现内嵌 + 同名 `.lrc` 外挂；可增强为「批量导入同名歌词文件」与「歌词文件夹扫描」 |
| 在线歌词翻译 | 需云端翻译 | 已支持本地双语 lrc（`LrcUtils.parseLrcLyric` 多数决）；用户可自行导入带翻译 lrc |
| 社交 / 分享到社区 / 排行榜 | 需出网与用户标识 | **系统分享文本卡片（D3）**：标题+歌手+专辑经 `@kit.ShareKit` 分享，文件不出机 |
| 音乐指纹识别（类 Shazam） | 需云端指纹库 | 纯本地**重复歌曲检测（B7）**：文件大小 + 分块 hash |
| 在线曲库 / 流媒体 / 搜索下载 | 硬约束 + 版权 | 不做；定位即是「用户自有文件」 |
| 账号 / 会员 / 个性化推荐 | 硬约束 | 本地统计 + 本地「最近播放」驱动排序 |
| 均衡器 / 空间音频 | SDK 能力限制（6.1.1 无公开多频段 EQ，PRD Non-goal） | 放弃 UI 开关；只做**音量/倍速（A3/A4）**等 SDK 允许的调节 |
| 智感握姿 / 隔空手势 | SDK 限制（6.1.1 无 `MultimodalAwarenessKit`） | 已做布局级底栏自适应（`adaptToHandedness`） |

---

## 4. 建议的下一个里程碑切分

考虑到「代码已超前 PRD、M1 合规基本完成」，建议 **M1.5「接线与补齐批」+ M2.5「体验增值批」**，避免一上来做重架构。

### 第一批（M1.5，≈2 周）——「把已规格化的能力接上」（低垂果实批）
1. **修复「自动下一首」开关不生效**（`AudioRendererController` completed 分支读设置）— XS
2. **`year` 持久化到 `SongItem`**（FR-F5/OQ-05 落地：字段 + 落盘 + 详情直读）— S
3. **`reduceMotion` 全局消费**（E1，兑现无障碍承诺）— S
4. **曲库排序**（B3，复用队列面板 `applySort`）— S
5. **桌面卡片推送专辑/进度字段**（D4 第一步）— XS/S
6. 顺手清理：删除 `NativeModule.getDeviceInfo` 死代码、`datasource` 接线或标注 — XS

### 第二批（M2.5，1–2 个迭代）——「曲库组织 + 播放体验增值」
7. **专辑/艺术家聚合浏览**（B1+B2）— M（最高用户价值）
8. **睡眠定时器**（A1）— S
9. **断点续播**（A2）— S/M

### 第三批（M2.5–M3.0）——「效率 + 隐私增值」
10. **本地听歌统计可视化**（E3，兑现统计开关承诺）— M
11. **文件「打开方式」导入**（D2）— M
12. **本地歌单/曲库导出 m3u8**（B4）— S

**排序逻辑**：第一批全部是「已有规格/开关/解析，只差接线」，成本最低、最能消除「文档与实现不一致」的信任风险；第二批直击 Persona A 核心诉求与离线播放器典型场景；第三批是隐私承诺兑现与导入摩擦优化。**不建议**把 M3 大屏多列、M4 状态机重构排在前面（价值存在但成本高，当前无 tablet 上架诉求）。

---

## 5. 低垂果实（已被现有代码/utils 部分支持、可低成本补齐）

| # | 果实 | 现状证据 | 补齐动作 | 成本 |
|---|---|---|---|---|
| 1 | **`year` 全链路闭合（OQ-05/R-15/FR-F5）** | `AudioMeta` 接口含 `year`（`utils/AudioMeta.ets:42`）、MediaKit `extractYear` + C++ `rawYear` 都已解析、`SongDetailSheet` 已展示但每次重读；`SongItem` 无字段（`models/music.ets:24-44`） | `SongItem.year` + `MusicStore` 落盘 + 详情直读 + 按年代筛选 | S |
| 2 | **「自动下一首」开关接线（FR-B8 真实缺陷）** | 设置持久化在 `SettingsStore.ets:48,97-104`；播放完成回调无条件 `playNext()`（`AudioRendererController.ets:115-116`） | completed 分支读 `getAutoNext()`，关闭则 `pause/stop` | XS |
| 3 | **`reduceMotion` 消费（R-18/F-13）** | 开关持久化（`SettingsStore.ets:53,155-162`）；全仓动画未读 | 动画处读开关降级（流光/入场/呼吸/旋转） | S |
| 4 | **大列表性能（NFR-PERF-03）** | `datasource/SongDataSource.ets`（IDataSource）+ `SongListData.ets` 已实现但零引用；页面用 `ForEach`（`LocalLibrary.ets:593`） | 曲库列表切 `LazyForEach` + 现有 `@Reusable MusicListContainer` 模式（`ControlAreaComponent.ets:478-568`） | S/M |
| 5 | **队列排序能力复用（B3）** | `ControlAreaComponent.applySort`（`ControlAreaComponent.ets:348-394`）支持标题/歌手/最近/随机 | 曲库页加排序入口，逻辑抽出公共函数 | S |
| 6 | **桌面卡片信息增强（D4 第一步）** | `pushFormUpdate` 只推 3 字段（`AVSessionController.ets:606-634`）；卡片恒默认封面 | 增加 album/duration 字段 + 卡片布局消费 | XS/S |
| 7 | **歌单封面（coverUri 落地）** | 字段已声明未用（`models/music.ets:52`） | 歌单详情「设置封面」入口，落盘 coverUri | S |
| 8 | **歌词显示设置（C2）** | `showTranslation` 为临时 `@State`（`LyricsComponent.ets:57,258`）；`LrcView` 字号硬编码（`LrcView.ets:105`） | 持久化到 `SettingsStore` + 字号设置项 | XS/S |
| 9 | **存储管理升级（OQ-09）** | `SettingsCategory` 已有 `computeCacheSize`/`clearCache`/`dirSize`（`SettingsCategory.ets:156-233`） | 增加「曲库占用 + 未引用文件清理」 | S |
| 10 | **死代码清理（R-07/R-26）** | `NativeModule.getDeviceInfo` 未调用；3 处仍用 `@ohos.file.fs`（旧 API） | 删死代码；迁移 `@kit.CoreFileKit` | XS |

---

## 6. 附：风险提示与建议同步的文档漂移

1. **文档与代码漂移**：`PRD.md`/`review_design.md` 中 M1 多项（R-01/R-02/R-03/R-06/R-09/R-14/R-17、卡片主题化）在代码里已完成，建议把 PRD 相应条目从「待补齐」翻转为「✅ 已交付」并回填回归 AC。
2. **「自动下一首」开关无效**属于用户可感知的规格违约，建议在第一批最先修（XS）。
3. **FR-A8 批量删除** PRD 标记 ✅ 但 `ManageSongs` 无多选实现——若确认未实现，应移回「待补齐」并纳入 B5，或修正文档。
4. **新 Kit 引入需过隐私评审**（NFR-SEC-03）：A4（AudioKit）、D3（ShareKit）、D5（UserAuthenticationKit）均为新增依赖，须在隐私政策/权限清单同步更新，优先评估纯本地替代（如 PIN 锁优先于生物识别）。
5. **任何「导入/导出」功能**都必须维持「用户主动触发 + 范围最小」原则，导出用 `DocumentViewPicker.save()`、不申请存储权限。

---

**一句话总结**：Lumio Music 的核心能力面已相当完整且超出 PRD 记录，下一个里程碑的最大机会不在「新增重功能」，而在 **① 把 6 个已规格化但未接线的开关/字段/通路补齐（第 4 节第一批），② 用专辑/艺术家聚合 + 睡眠定时器 + 断点续播补足「本地收藏者」的体验纵深，③ 用本地统计/导出/打开方式导入兑现隐私与效率承诺**——全部与「纯离线 / 本地」定位严格一致，且多数可落在现有 `MusicStore` / `AudioRendererController` / `ThemeManager` 架构内，无需引入网络依赖。
