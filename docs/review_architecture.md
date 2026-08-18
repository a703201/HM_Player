# Lumio Music — 架构梳理与公开 API 面盘点

> 范围：为后续 PRD 与 API 文档提供事实基线。
> 基线事实（直接采信，已与团队对齐）：bundleName `com.lumio.music`（注：概述里写作 `com.Lumio.music`，以 `app.json5` 签名为准）、Apache-2.0、ArkTS + C++ NAPI + MediaKit、目标 **API 24 / HarmonyOS 6.1.1**。
> 盘点方式：直接阅读 `entry/src/main/ets`（18 个子目录/模块）、`entry/src/main/cpp`、`build-profile.json5`、`resources/base/profile/route_map.json`，未逐文件通读全仓。
> 配套文档：`review_security.md`、`review_compliance.md` 已先行产出，本报告聚焦架构分层、状态管理与公开 API 面。

---

## 0. 事实基线速览

| 项 | 值 |
|---|---|
| 应用模型 | Stage 模型，`EntryAbility` 单 UIAbility + `FormAbility`（桌面卡片）+ `EntryBackupAbility`（数据备份） |
| 语言 | ArkTS（严格模式 `strictMode.caseSensitiveCheck=true`，`useNormalizedOHMUrl=false`） |
| 原生层 | `entry/src/main/cpp`（audio_metadata.cpp/.h、napi_init.cpp），编译产物 `libnative_module.so`，`nativeCompiler: BiSheng` |
| 持久化三套并存 | ① `MusicStore` → dataPreferences `music_store`；② `SettingsStore` → `@kit.ArkData` preferences `app_settings`；③ `PreferencesUtil` → `@kit.ArkData` preferences `myStore`（桌面卡片 formIds / 权限引导标记 / 静音标记） |
| 运行时状态 | AppStorage 信号量 + AudioRendererController / AVSessionController 单例（存于 AppStorage） |
| 导航 | `Navigation` + `NavPathStack`（`@Provide('navPathStack')`）+ `route_map.json` 系统命名路由，12 个目的地 |
| 权限（最小化） | `KEEP_BACKGROUND_RUNNING`、`INTERNET`、`GET_NETWORK_INFO`；无 `READ_MEDIA`/`WRITE_MEDIA`（歌曲经 `DocumentViewPicker` 拷入沙箱） |

---

## 1. 分层与模块边界

### 1.1 `entry/src/main/ets` 子目录职责

| 目录 | 职责 | 关键文件 |
|---|---|---|
| `entryability/` | UIAbility 生命周期：AppStorage 播种（context/uiContext/window/systemIsDark/currentBreakpoint）、MusicStore 初始化+封面预载、主题初始化、want 控制指令（投播回控） | `EntryAbility.ets` |
| `entrybackupability/` | 数据备份恢复（BackupExtensionAbility） | `EntryBackupAbility.ets` |
| `formability/` | 桌面播控卡片 Extension：登记/注销 formId、事件记录 | `FormAbility.ets` |
| `pages/` | 业务页面（路由目的地）：Layout（根导航壳）、LocalLibrary、Mine、PlayerPage、Settings 体系、Favorites、Playlists/PlaylistDetail、ManageSongs、PlayHistory、About、PrivacyPolicy | 14 个页面 |
| `components/` | 可复用 UI 组件：CoverImageView、LyricsComponent、ControlAreaComponent、PlayerInfoComponent、TopAreaComponent、MusicInfoComponent、SongDetailSheet、AddToPlaylistSheet | 8 个组件 |
| `services/` | **业务数据服务层（权威持久层）**：曲库、收藏、歌单、最近播放、元数据补偿 | `MusicStore.ets` |
| `songdatacontroller/` | 播放领域模型与构建器：`SongItem`（单一真源实体）、`PlayerData`（枚举/常量）、`SongItemBuilder`（fd 准备） | `SongData.ets`、`PlayerData.ets`、`SongItemBuilder.ets` |
| `utils/` | 工具/基础设施层：播放引擎、AVSession、主题、封面缓存、元数据、歌词、日志、偏好、断点、媒体换算、NAPI 封装 | 16 个文件 |
| `lyric/` | 歌词解析纯函数与数据结构：`LrcUtils`、`LrcEntry`、`LrcView`、`LyricConst` | — |
| `models/` | 跨层共享实体/类型：`SongItem`、`RepeatMode`、`Playlist` | `music.ets` |
| `common/` | 公共常量（`constants/`：Router/Breakpoint/Style/Content/Player）+ 公共工具（`utils/`：BreakpointSystem、ColorConversion、ResourceConversion） | — |
| `widget/` | 桌面卡片 ArkTS UI（独立进程渲染） | `pages/WidgetCard.ets` |
| `datasource/` | `LazyForEach` 数据源适配：`SongDataSource`、`SongListData`（IDataSource 懒加载） | — |

### 1.2 分层依赖关系（自上而下，箭头=依赖方向）

```
┌─ pages (业务页面) ───────────────────────────────────────────────┐
│   依赖 components、services、utils、songdatacontroller、models、common │
├─ components (UI 组件) ───────────────────────────────────────────┤
│   依赖 utils(Logger/CoverCache/AudioMetaReader/EmbeddedLyricReader)、│
│   services(MusicStore)、songdatacontroller、common               │
├─ services (业务数据服务) ────────────────────────────────────────┤
│   MusicStore → utils(Logger/CoverCache/EmbeddedLyricReader/AudioMeta)、models │
├─ utils (基础设施/引擎) ──────────────────────────────────────────┤
│   AVSessionController ⇄ AudioRendererController(双向)            │
│   两者 → MusicStore / PreferencesUtil / MediaTools / Logger       │
│   AudioMetaReader →(taskpool)→ NativeModule(NativeUtils)         │
├─ songdatacontroller / models / common ───────────────────────────┤
│   叶子层（被依赖，不反向依赖上层）                                │
└───────────────────────────────────────────────────────────────────┘
        │ NAPI 同步调用（封装于工作线程）
┌─ cpp/ (libnative_module.so) ────────────────────────────────────┐
│   audio_metadata.cpp → parseAudioMetadata(FLAC/MP3/MP4)          │
└───────────────────────────────────────────────────────────────────┘
```

### 1.3 模块边界与不变式（架构约束）

- **持久化封装边界**：表现层/业务层不得直接 `dataPreferences`/`preferences` 裸调用；必须经由 `MusicStore` / `SettingsStore` / `PreferencesUtil` 三套封装。
- **播放状态单一权威**：`AudioRendererController` 是播放队列与 `AVPlayer` 的唯一写者；组件严禁直接操作 `avPlayer`，须经控制器方法。
- **曲库/收藏单一权威**：`MusicStore`。`AVSessionController` 仅镜像（用于锁屏/卡片），收藏以 `song.id` 为主键与 MusicStore 对齐。
- **主题权威**：`SettingsStore.themeMode` + AppStorage 派生（`isDark`）；`ThemeManager` 是统一访问门面，组件不得自行算深浅色。
- **原生能力边界**：业务层不得 `import 'libnative_module.so'` 直连；须经 `NativeModule/NativeUtils` 单例，且耗时解析由 `AudioMetaReader` 用 `taskpool` 包裹。

---

## 2. 状态管理方案

### 2.1 AppStorage 信号量清单（共 ~22 个键）

| 键 | 类型 | 生产者 | 主要消费者 | 用途 |
|---|---|---|---|---|
| `context` | `Context` | EntryAbility | 各工具/Builder | 全局上下文 |
| `uiContext` | `UIContext` | EntryAbility | BreakpointSystem | 媒体查询 |
| `window` | `window.Window` | EntryAbility | ThemeManager | 状态栏内容色 |
| `systemIsDark` | `boolean` | EntryAbility(onConfigurationUpdated) | ThemeManager(跟随系统) | 系统深色态 |
| `themeMode` | `'system'\|'light'\|'dark'` | ThemeManager | ThemeManager/样式 | 主题模式 |
| `isDark` | `boolean` | ThemeManager | 组件 `@StorageProp('isDark')` | 派生深浅色 |
| `songList` | `SongItem[]` | AudioRendererController.syncQueue(+EntryAbility 初播) | ControlArea/Lyrics/MusicInfo、AVSession | **播放队列镜像**（非曲库） |
| `selectIndex` | `number` | AudioRendererController.syncQueue | 组件、AVSession | 当前队列下标 |
| `isPlay` | `boolean` | AudioRendererController | ControlArea、AVSession、Widget | 播放态 |
| `progress` / `currentTime` / `totalTime` / `totalMsTime` / `progressMax` | `number`/`string` | AudioRendererController(时间回调) | 进度条/歌词联动 |
| `playMode` | `MusicPlayMode` | AVSessionController | ControlArea | 播放模式 |
| `isFavorite` | `boolean` | AVSessionController | ControlArea | 收藏态 |
| `isSilentMode` | `boolean` | AudioRendererController | ControlArea | 静音/混音 |
| `coverRefreshToken` | `number` | EntryAbility | CoverImageView(`@StorageProp`+`@Watch`) | 封面刷新信号量 |
| `currentBreakpoint` | `'sm'\|'md'\|'lg'` | BreakpointSystem | 各组件响应式布局 | 断点 |
| `topHeight` / `bottomHeight` | `number` | EntryAbility | 布局避让 | 安全区 |
| `imageColor` / `pageShowTime` / `lyricBgDark` / `isFoldFull` | 混合 | 播放页/折叠态 | 光感/歌词明暗/折叠 | 播放页局部态 |
| `AVSessionController` / `audioRendererController` | 单例实例 | 各自 `getInstance()` | 互引装配 | 控制器单例托管 |

### 2.2 装饰器使用矩阵

| 装饰器 | 语义 | 典型用法 |
|---|---|---|
| `@StorageProp` | 单向（AppStorage→组件，组件改不影响源） | `isDark`、`currentBreakpoint`、`selectIndex`(只读场景)、`lyricBgDark`、`coverRefreshToken` |
| `@StorageLink` | 双向（组件与 AppStorage 同步） | `isPlay`、`progress`、`totalTime`、`currentTime`、`progressMax`、`songList`、`playMode`、`isFavorite`、`isSilentMode`、`selectIndex`(可写场景) |
| `@Watch('xxx')` | 监听变化触发回调 | CoverImageView：`@StorageProp('coverRefreshToken') @Watch('refresh')`；LyricsComponent：`@StorageProp('selectIndex') @Watch('getLrcEntryList')` |
| `@Provide/@Consume` | 跨组件层级传递 | `@Provide('navPathStack') pathStack` ↔ 子页 `@Consume('navPathStack')` |
| `@LocalStorageProp` | 卡片独立存储 | WidgetCard：`title`/`artist`/`isPlaying` |

> **关键纠偏**：`coverRefreshToken` 是“信号量”而非数据——CoverImageView 监听其变化后**重新读取** `CoverCache`（而非把 PixelMap 直接塞进 AppStorage），避免大图常驻 AppStorage。这是本项目处理封面的正确范式。

### 2.3 MusicStore ↔ AppStorage 双写与 `reconcileWithLibrary` 对齐机制

存在 **三条“歌曲列表”概念**，必须区分：

1. `MusicStore.songs` —— **曲库（持久权威）**，dataPreferences 落盘。
2. `AudioRendererController.songList` —— **当前播放队列（运行时权威）**，由导入/点歌/排序/移除驱动。
3. `AppStorage.songList` —— 队列的 **镜像**，供 UI 绑定（ControlArea/Lyrics/MusicInfo）。

对齐时序：

```
启动：EntryAbility.onCreate
  └─ MusicStore.getInstance().init(ctx)         // 曲库落盘→内存
  └─ CoverCache.preload(store.songs)
  └─ AppStorage.setOrCreate('songList', store.songs)   // 仅作初值
  └─ AppStorage.setOrCreate('coverRefreshToken', Date.now())

播放/点歌：AudioRendererController.setQueue()/playFromList()
  └─ 改内部 songList + musicIndex
  └─ syncQueue() → AppStorage('songList','selectIndex') + AVSession.setSongList()

导入/删歌（LocalLibrary / ManageSongs）：
  └─ MusicStore 改 songs 并持久化
  └─ AudioRendererController.reconcileWithLibrary(store.songs)
       ① 队列删去曲库中已不存在的歌（修正索引，防 next/prev 跳到已删文件）
       ② 新导入歌曲追加到队尾（"下一首"逐步覆盖新歌）
       ③ 当前曲被删→续播相邻曲 / 空队列→stop()
       ④ syncQueue() 回写 AppStorage
  └─ AVSessionController.pushFormUpdate() 同步卡片
```

> 该机制**已落地**：`reconcileWithLibrary` 在 `LocalLibrary.ets`（3 处：导入完成、删除、批量）与 `ManageSongs.ets`（删除）调用。需注意：其他删除入口（如将来从播放页/Favorites 删歌）必须同样调用，否则队列与曲库会漂移。

---

## 3. 公开 API 面盘点（供 API 文档）

> 约定：**公开 API = 标记为 `public` 或 `static`（对外服务）的成员**。以下逐类给出职责、路径、方法签名与调用约束。内部私有方法（`private`）仅列代表性项，不纳入 API 契约。

### 3.1 `MusicStore` — 曲库/收藏/歌单权威持久层
路径：`services/MusicStore.ets`

| 方法 | 签名 | 说明 |
|---|---|---|
| 单例 | `static getInstance(): MusicStore` | 私有构造 + 懒加载 |
| 初始化 | `init(context: Context): Promise<void>` | 读 `music_store`，失败置 `loadError` |
| 全量设置 | `setSongs(songs: SongItem[]): void` | 同步 `songs`/`playList` 并持久化 |
| 索引/播放 | `setCurrentIndex(i: number)` / `setIsPlaying(b: boolean)` / `setRepeatMode(mode: RepeatMode)` | 内存+（repeat）持久化 |
| 收藏 | `toggleFavorite(songId: number): void` / `isFavorite(songId: number): boolean` | 以 `song.id` 为主键 |
| 歌单 | `addPlaylist(name: string, songIds: number[]): Playlist` | id=`Date.now()_随机` 防重 |
| 歌单 | `deletePlaylist(id: string)` / `getPlaylistById(id: string): Playlist \| undefined` | 页间只传 id，避免副本不同步 |
| 歌单 | `hasPlaylistName(name: string, excludeId?: string): boolean` | 去重校验 |
| 歌单 | `renamePlaylist(id: string, name: string): void` | trim 后写 |
| 歌单 | `addSongsToPlaylist(pid: string, songIds: number[]): number` | 返回实际新增数 |
| 歌单 | `removeSongFromPlaylist(pid: string, songId: number): void` | — |
| 歌单 | `reorderPlaylistSongs(pid: string, from: number, to: number): void` | 拖拽排序（FR-24） |
| 最近播放 | `addToRecentlyPlayed(song: SongItem)` / `getRecentlyPlayed(): SongItem[]` / `clearRecentlyPlayed()` | 上限 50 |
| 收藏列表 | `getFavoriteSongs(): SongItem[]` | 由 `songs` 过滤 |
| 删除歌曲 | `removeSong(songId: number): void` | 同时 evict 封面/歌词缓存、清理歌单悬挂引用 |
| 元数据补偿 | `refreshMetadataIfNeeded(): Promise<void>` | 首次启动补扫文本元数据（幂等标记 `meta_scanned_v1`） |

公开字段：`songs`、`playList`、`currentIndex`、`isPlaying`、`repeatMode`、`favorites: Set<number>`、`playlists`、`recentlyPlayed`、`loadError`。
**调用约束**：① 单例，必须先 `init(context)`；② 所有落盘经私有 `save*`，异常仅 `Logger.error` 不抛出；③ `favorites` 为 `Set<number>`，序列化时转数组。

### 3.2 `SettingsStore` — 设置项持久层
路径：`utils/SettingsStore.ets`。类型：`ThemeMode='system'|'light'|'dark'`、`RepeatModeSetting='list'|'single'|'random'`。

| 方法 | 签名 | 联动 |
|---|---|---|
| 单例/初始化 | `getInstance()` / `ensureInitialized(ctx)` / `init(ctx): Promise<void>` | 幂等 |
| 自动下一首 | `getAutoNext(): boolean` / `setAutoNext(v: boolean): Promise<void>` | — |
| 播放模式 | `getRepeatMode(): RepeatModeSetting` / `setRepeatMode(v): Promise<void>` | 联动 `MusicStore.setRepeatMode` |
| 主题模式 | `getThemeMode(): ThemeMode` / `setThemeMode(v): Promise<void>` | — |
| 锁屏控制 | `getNotificationLockScreen(): boolean` / `setNotificationLockScreen(v): Promise<void>` | 联动 `AVSessionController.setLockScreenControl` |
| 听歌统计 | `getPrivacyStats()` / `setPrivacyStats()` | — |
| 降低动态 | `getReduceMotion()` / `setReduceMotion()` | 无障碍 |

**调用约束**：① 独立 PREF `app_settings`；② **`pref` 未初始化时 `set*` 静默 no-op**（`putBoolean/putString` 检查 `!pref` 直接 return）——需在 `EntryAbility` 已 `init` 后再写；③ 跨类联动（repeat→MusicStore、锁屏→AVSession）是隐式副作用，文档需明示。

### 3.3 `ThemeManager` — 主题访问门面（纯静态）
路径：`utils/ThemeManager.ets`。`ColorTokens={bg,secondaryBg,cardBg,primaryText,secondaryText,separator,accent}`。

| 方法 | 签名 |
|---|---|
| `static init(): void` | 读 `SettingsStore.themeMode`→写 AppStorage `themeMode`/`isDark` |
| `static isDark(): boolean` | system 模式读 AppStorage `systemIsDark` |
| `static getColors(): ColorTokens` | 按 `isDark` 返回浅/深令牌 |
| `static get lightColors: ColorTokens` / `static get darkColors: ColorTokens` | 静态 getter（供组件响应式取用） |
| `static setThemeMode(mode: ThemeMode): void` | 持久化+刷新+`applyToWindow()` |
| `static refreshSystemTheme(): void` | 系统变更时刷新（仅 system 模式有效） |
| `static applyToWindow(): void` | 同步状态栏/导航栏内容色 |

**调用约束**：无实例；依赖 AppStorage `themeMode/isDark/systemIsDark/window`；`accent` 固定 `#FA2759`；`setThemeMode` 会触发窗口系统栏重绘。

### 3.4 `CoverCache` — 内嵌封面抽取与缓存（单例）
路径：`utils/CoverCache.ets`。

| 方法 | 签名 |
|---|---|
| `static getInstance(): CoverCache` | — |
| `get(src: string): image.PixelMap \| undefined` | 同步命中读取 |
| `isMissing(src: string): boolean` | 负缓存（确认无封面） |
| `load(src: string): Promise<image.PixelMap \| undefined>` | 抽取（pending 去重 + missing 短路） |
| `evict(src: string): void` | 删歌时清理 |
| `preload(songs: {src:string}[], concurrency?: number): Promise<void>` | 批量预载（默认并发 4） |

**调用约束**：① 仅对沙箱真实文件（`/`/`file://`/`internal://`）抽取，跳过 `.pcm`/rawfile；② 经 `AVMetadataExtractor.fetchAlbumCover()`；③ 抽取失败/无封面**静默**返回 undefined，调用方须自行处理默认图；④ 调用方在 `preload` 完成后应刷新 `songList`/`coverRefreshToken` 触发 UI 重绘。

### 3.5 `AVSessionController` — 系统媒体会话/锁屏/投播/卡片（单例，AppStorage 托管）
路径：`utils/AVSessionController.ets`（`@kit.AVSessionKit`）。

| 方法 | 签名 | 说明 |
|---|---|---|
| `static getInstance(): AVSessionController` | AppStorage `'AVSessionController'` 托管 | — |
| `setSongList(list: SongItem[], index?: number): void` | 同步元数据源（队列变更后） | — |
| `bindAudioRendererController(c: AudioRendererController): void` | 双向装配 | 触发 `ensureListenersRegistered` |
| `setAVMetadata(): Promise<void>` | 推送标题/封面/歌词到锁屏 | 投播中切歌会重新投播 |
| `setPlayModeToAVSession(): void` / `setLoopModeState(m): Promise<void>` | AVSession LoopMode 同步 | — |
| `setProgressState(ms: number)` / `setPlayState(isPlay: boolean)` | 播放进度/状态 | 同时 `pushFormUpdate()` |
| `pushFormUpdate(): void` | 跨进程推送卡片状态 | formProvider |
| `remoteControl(cmd: string): void` | `'play'\|'pause'\|'next'\|'prev'` | 卡片回控入口 |
| `setLockScreenControl(enabled: boolean): void` | 激活/停用 AVSession | 联动设置项 |
| `updateFavoriteState(assetId: string): Promise<void>` / `getAndUpdateFavoriteState(assetId): Promise<void>` | 收藏收口 MusicStore（按 id） | — |
| `unregisterSessionListener(): Promise<void>` | 注销监听 + 退出时释放投播 | — |

内部（非公开，但影响行为）：`startCast/stopCast/castCurrentSong/onOutputDeviceChange`（投播经 `AVCastController`）；`onPlay/onPause/onPlayNext/onPlayPrevious/onSeek/onSetLoopMode/onToggleFavorite`（系统媒体键回调）。
**调用约束**：① 与 `AudioRendererController` 双向引用，`ensureListenersRegistered` 去重保活；② 投播 `castController.off('playNext'...)` 用 `as ESObject` 绕过重载不匹配（已知类型逃逸）；③ 收藏以 `song.id` 为稳定主键，绝不依赖会漂移的队列下标；④ 投播与本地播放用**独立 fd**（`castFile` 与 `curFile` 解耦）。

### 3.6 `AudioRendererController` — 播放引擎/队列权威（单例，AppStorage 托管）
路径：`utils/AudioRendererController.ets`（`@kit.MediaKit` AVPlayer）。

| 方法 | 签名 | 说明 |
|---|---|---|
| `static getInstance(): AudioRendererController` | AppStorage `'audioRendererController'` | — |
| `play(musicIndex?: number): Promise<void>` | 起播（先 `await avPlayerReady` 防冷启动） | 记最近播放+`syncQueue` |
| `start()/pause()/stop()/release(): Promise<void>` | AVPlayer 生命周期 | `release` 释放 fd+停长时任务 |
| `seek(ms: number): void` | `SeekMode.SEEK_CLOSEST` | — |
| `playNext()/playPrevious(): Promise<void>` | 按 `playMode` 切换 | — |
| `getFirst(): boolean` / `getCurrentSong(): SongItem\|undefined` / `getCurrentPosition(): number` / `getDuration(): number` | 查询 | — |
| `getQueue(): SongItem[]` / `getCurrentIndex(): number` | 队列查询（返回副本） | — |
| `setQueue(songs, startIndex, autoPlay?: boolean): void` | 覆盖队列+可选起播 | 排序场景 `autoPlay=false` |
| `playFromList(list: SongItem[], index: number): void` | 点歌即播 | = `setQueue(list,index,true)` |
| `removeFromQueue(index: number): void` | 移除并维持 current 正确 | — |
| `moveToPlayNext(index: number): void` | 下一首播放 | — |
| `reconcileWithLibrary(library: SongItem[]): void` | 队列与曲库差量对齐 | 见 §2.3 |
| `setPlayModel(m: MusicPlayMode)` / `getPlayMode(): MusicPlayMode` | 模式 | 联动 AVSession |
| `setCastActive(active: boolean): void` | 投播期本地静音标记 | — |
| `setSilentModeAndMixWithOthers(isSupportSilent?: boolean): Promise<void>` | 静音/混音 | 写 `SILENT_ID` 到 formIds 集合 |

公开字段：`avPlayer?: media.AVPlayer`、`castActive: boolean`。
**调用约束**：① **播放队列唯一权威**，组件不得直连 `avPlayer`；② `avPlayerReady` 异步就绪，所有入口须 `await`；③ `syncQueue()` 是 AppStorage 与 AVSession 的唯一回写点；④ `reconcileWithLibrary` 仅在导入/删歌后调用，不在进播放页时调用（避免覆盖用户的手动队列编辑）；⑤ `BackgroundUtil.startContinuousTask` 维持后台播放。

### 3.7 `AudioMetaReader` + `NativeUtils` — 文本元数据双路解析
路径：`utils/AudioMeta.ets`、`utils/NativeModule.ets`。
`AudioMeta = { title?, artist?, album?, author?, year? }`；`AudioMetadata`(C++) = `{ title, artist, album, year, durationMs, sampleRate, channels }`。

| 类 | 方法 | 签名 |
|---|---|---|
| `AudioMetaReader` | `static read(src: string): Promise<AudioMeta \| null>` | MediaKit 优先 + NAPI 兜底（taskpool） |
| `NativeUtils` | `static getInstance()` / `add(a,b): number` / `parseAudioMetadata(path): AudioMetadata` / `getDeviceInfo(): DeviceInfo` | C++ NAPI 封装 |

**调用约束**：① `read`：**MediaKit `AVMetadataExtractor` 优先**；仅当失败或 `title` 缺失才回退 C++ NAPI；② 回退为**同步 NAPI**，必须在 `taskpool` 工作线程执行（`parseMetaOnWorker` 用 `@Concurrent` 顶层具名函数，闭包形式会抛 10200014）；③ 返回纯数据（仅字符串字段），跨线程可序列化；④ 日志**脱敏**（`sanitize` 只留文件名，避免沙箱路径进 hilog）；⑤ MediaKit 不暴露内嵌歌词，故本类只取文本元数据，歌词走 `EmbeddedLyricReader`。

### 3.8 `EmbeddedLyricReader` — 内嵌歌词定点解析（静态类）
路径：`utils/EmbeddedLyricReader.ets`。

| 方法 | 签名 |
|---|---|
| `static read(src: string): Promise<string \| undefined>` | 解析内嵌/外挂歌词（含负缓存） |
| `static evict(src: string): void` | 删歌清理 |

内部能力（非公开）：FLAC `VORBIS_COMMENT`（LYRICS/UNSYNCEDLYRICS/含 LYRIC 键）、MP3 ID3v2 `USLT/ULT`+`TXXX(LYRICS)`、MP4 `©lyr`+`----`(LYRICS)、魔数嗅探、回落同名 `.lrc`；编码探测（BOM/UTF-16 启发式→UTF-8）；`MAX_*` 上限（ID3 8MB / VORBIS 4MB / moov 16MB / 歌词 512KB）防 OOM。
**调用约束**：① 静态类 + 静态 `Map` 缓存（含负结果）；② **定点读取**不整文件载入；③ 解析失败/无歌词返回 `undefined`（静默）；④ 歌词中 `year` 字段无关（歌词文本）。

### 3.9 `LrcUtils` + `LrcEntry` — 歌词文本解析（纯函数）
路径：`lyric/LrcUtils.ets`、`lyric/LrcEntry.ets`。

| 方法 | 签名 |
|---|---|
| `getRawStringData(ctx: Context, rawFilePath: string): Promise<string>` | 读 rawfile LRC |
| `parseLrcLyric(text: string): Array<LrcEntry>` | LRC 解析，语种多数决区分原文/翻译 |
| `parseKrcLyric(text: string): LrcEntry[]` | KRC 逐字（Word[]）解析 |
| `angleToRadian(angle: number): number` | 工具 |

`LrcEntry = { lineStartTime, lineDuration, lineWords, words: Word[], translation? }`。
**调用约束**：① 导出为**模块函数（非类）**，注意大小写 `parseLrcLyric`；② 语种多数决（`translationIsCjk`）区分原文/翻译，并剔除 `CREDIT_KEYWORDS`（作词/作曲…）制作信息行，避免翻译语种误判；③ KRC 提供逐字高亮数据。

### 3.10 `Logger` — 统一日志门面（纯静态）
路径：`utils/Logger.ets`（封装 hilog，domain `0xFF00`，prefix `MusicPlay`）。

| 方法 | 签名 |
|---|---|
| `debug/info/warn/error(...args: string[])` | `%{public}s` |
| `debugPrivate/infoPrivate/warnPrivate/errorPrivate(...args: string[])` | `%{private}s`（release 自动隐藏） |

**调用约束**：全仓统一经此入口，便于级别管控与隐私脱敏；敏感数据（路径/歌名）应走 `*Private` 或先 `sanitize`。

### 3.11 `BreakpointSystem` + `BreakpointType` — 响应式断点
路径：`common/utils/BreakpointSystem.ets`。

| 类 | 方法 |
|---|---|
| `BreakpointType<T>` | `constructor(option: {sm?,md?,lg?})`、`getValue(currentPoint: string): T` |
| `BreakpointSystem` | `register(): void` / `unregister(): void`（监听 sm/md/lg 写 AppStorage `currentBreakpoint`） |

**调用约束**：① 依赖 AppStorage `uiContext` 已播种（构造期读取）；② 是“一次开发多端部署（一多）”的响应式基础；③ 配合 `common/constants/BreakpointConstants` 的 `RANGE_SM/MD/LG`。

### 3.12 `SongItemBuilder` — 媒体 fd 准备（默认类，非单例）
路径：`songdatacontroller/SongItemBuilder.ets`。

| 方法 | 签名 |
|---|---|
| `build(songItem: SongItem): Promise<SongItem>` | 为沙箱文件/rawfile 准备 `RawFileDescriptor` |
| `getRawFileDescriptor(): resourceManager.RawFileDescriptor \| undefined` | — |
| `release(): Promise<void>` | 释放 fd（防泄漏） |

**调用约束**：实例需 `context`（构造期读 AppStorage `context`）；`releaseFileFd` 必须配对调用避免 fd 泄漏。

### 3.13 `PreferencesUtil` — 底层偏好封装（PREF `myStore`）
路径：`utils/PreferencesUtil.ets`。

| 方法 | 签名 | 备注 |
|---|---|---|
| `static getInstance()` | — | — |
| `getPreferences(ctx): Promise<preferences.Preferences>` | 读 `myStore` | — |
| `preferencesFlush(p)` / `preferencesPut(p, formIds)` / `preferencesHas(p)` | — | — |
| `getFormIds(ctx): Promise<Array<string>>` | ⚠ 见风险 | **异常分支返回永不应答 Promise** |
| `addFormId(ctx, formId)` / `removeFormId(ctx, formId)` | 桌面卡片 ID 登记 | SILENT_ID 也混入此数组 |
| `isPermGuideShown(ctx): Promise<boolean>` / `markPermGuideShown(ctx): Promise<void>` | 权限引导标记 | — |
| `removePreferencesFromCache(ctx)` | — | — |

**调用约束**：① 与 `MusicStore`/`SettingsStore` 是**第三套** preferences（`myStore`），仅承载桌面卡片 formIds、权限引导、静音标记；② **静音标记 `SILENT_ID='silentId'` 作为 magic 字符串塞进 `formIds` 数组**（关注点耦合，见风险 P1）。

### 3.14 路由/导航相关
- `RouterConstants`（`common/constants/RouterConstants.ets`）：静态只读 `PLAYER_PAGE='PlayerPage'`、`NAV_PATH_STACK_CONSTANTS='NavPathStack'`、`PLAYER_INFO_COMPONENT`。
- `route_map.json`（`resources/base/profile/`）：12 个命名目的地（`Layout`/`PlayerPage`/`Settings`/`SettingsCategory`/`About`/`PrivacyPolicy`/`PlayHistory`/`Favorites`/`ManageSongs`/`Playlists`/`PlaylistDetail` + `Layout`）。
- 导航实现：`@Provide('navPathStack') pathStack: NavPathStack`（`HdsNavigation(this.pathStack)`）→ 子页 `@Consume('navPathStack')` → `pathStack.pushPathByName(name, param)`（或 `router.pushNamedRoute`）。
- **调用约束**：新增页面须在 `route_map.json` 注册 `name`+`pageSourceFile`+`buildFunction`，且页面导出对应 `*Builder`；跨页参数经 `NavPathStack` 入参传递，歌单等仅传 `id` 再查 `MusicStore`。

### 3.15 桌面卡片（跨进程）
- `FormAbility`（`formability/FormAbility.ets`）：`onAddForm/onRemoveForm` 登记 formId；`onFormEvent` 仅记录（实际回控经 WidgetCard 的 `postCardAction` router 事件→`EntryAbility.handleControlWant`→`AVSessionController.remoteControl`）。
- `WidgetCard`（`widget/pages/WidgetCard.ets`）：`@LocalStorageProp('title'|'artist'|'isPlaying')`；按钮 `postCardAction(this,{action:'router',abilityName:'EntryAbility',params:{control:'play'|'pause'|'next'|'prev'}})`。
- 状态推送：主应用 `AVSessionController.pushFormUpdate()` 经 `formProvider.updateForm` 跨进程写 `title/artist/isPlaying`。
**调用约束**：卡片为独立进程，不可直接调系统播放 API；回控必须走 want 拉起主 Ability。

### 3.16 C++ NAPI 原生层
路径：`entry/src/main/cpp/audio_metadata.h`、`.cpp`、`napi_init.cpp`（产物 `libnative_module.so`）。
- `AudioMetadata parseAudioMetadata(const std::string& filePath)`：FLAC/MP3/MP4 真实解析，返回 `{title, artist, album, year, durationMs, sampleRate, channels}`。
- 经 `napi_init.cpp` 注册导出；由 `NativeUtils.parseAudioMetadata` 在 `taskpool` 工作线程调用。
**调用约束**：① NAPI 同步、C++ 解析耗时，**必须置于工作线程**（已在 `AudioMetaReader` 用 `taskpool` 包裹）；② 内存安全已修（P0×6：size_t/uint64 边界校验）；③ `durationMs/sampleRate/channels` 当前仅作能力储备，`AudioMetaReader` 未采用（时长仍由 MediaKit 取）。

---

## 4. 功能清单雏形（已落地能力，供 PRD 参考）

| 领域 | 能力 | 关键实现 | 状态 |
|---|---|---|---|
| 导入 | DocumentViewPicker 选曲→拷入沙箱；导入后 `reconcileWithLibrary` | LocalLibrary + SongItemBuilder | ✅ |
| 曲库 | 列表/搜索/空状态引导；`MusicStore.songs` 持久 | MusicStore + SongDataSource(LazyForEach) | ✅ |
| 播放 | 播放/暂停/上一首/下一首/进度/模式（顺序/单曲/随机）；迷你播放器+一镜到底 | AudioRendererController + AVPlayer + AVSession | ✅ |
| 播放页 | 封面光感、歌词（原文+翻译、手动滑动、明暗自适应）、控制区、详情半模态 | PlayerPage / LyricsComponent / ControlArea / SongDetailSheet | ✅ |
| 播放列表 | 自建歌单（建/删/改名/加歌/移出/拖拽排序/播放全部） | MusicStore 歌单 API | ✅ |
| 收藏 | 收藏切换，锁屏/卡片同步；以 `song.id` 为主键 | MusicStore + AVSession.updateFavoriteState | ✅ |
| 最近播放 | 自动记录（上限 50）、可清空 | MusicStore + AudioRendererController.play | ✅ |
| 歌词 | 内嵌（FLAC/MP3/MP4）+ 外挂 `.lrc`；LRC/KRC；语种多数决 | EmbeddedLyricReader + LrcUtils | ✅ |
| 封面 | 内嵌封面抽取+缓存（pending 去重+负缓存+批量预载） | CoverCache + AVMetadataExtractor | ✅ |
| 主题 | 系统/浅/深；状态栏内容色同步；accent 固定 | ThemeManager + SettingsStore | ✅ |
| 投播 | AVCastPicker/AVCastController；远端连/断自动切换；断连续播对齐 | AVSessionController(startCast/stopCast) | ✅ |
| 锁屏/通知 | 媒体控制卡片（可关） | AVSession + setLockScreenControl | ✅ |
| 桌面卡片 | 播控卡片（状态推送+按钮回控） | FormAbility + WidgetCard + pushFormUpdate | ✅ |
| 后台 | 持续播放（长时任务） | BackgroundUtil | ✅ |
| 元数据 | C++ NAPI 双路（FLAC/MP3/MP4）+ MediaKit；年代解析 | AudioMetaReader + NativeUtils | ✅（year 持久化待核实，见 P1） |
| 设置 | 主页+子页、自动下一首、锁屏控制、听歌统计、降低动态、清空历史、版本/隐私/开发者 | Settings + SettingsCategory | ✅ |
| 备份 | 数据备份恢复 | EntryBackupAbility | ✅ |
| 响应式 | 一多断点（sm/md/lg） | BreakpointSystem | ✅ |

---

## 5. 架构风险与改进点（P0 / P1 / P2）

### P0（正确性/可用性致命，需立即处理）
> 本轮代码通读**未发现新的 P0 阻塞**（C++ 内存安全 P0×6、ArkTS 红线均已在概述中标记已修复）。以下为需持续守护的不变量，而非已存在问题：
- **队列/曲库对齐契约**：`reconcileWithLibrary` 是队列与曲库唯一对齐点，新增任何删歌入口（播放页/Favorites/详情）必须调用它，否则 `next/prev` 会跳到已删文件。→ 建议在 `MusicStore.removeSong` 内统一触发（而非依赖各页面手动调用），消除遗漏风险。

### P1（重要，应在下一迭代修复）
1. **三条“歌曲列表”概念混淆**：`MusicStore.songs`（曲库）、`AudioRendererController.songList`（队列，权威）、`AppStorage.songList`（队列镜像）易在页面中被误读。需以注释/命名明确契约：组件读取“曲库”走 `MusicStore.getInstance().songs`/数据源，读取“当前播放队列”才走 `AppStorage.songList`。
2. **`PreferencesUtil.getFormIds` 异常分支返回永不应答 Promise**：`catch` 后 `return new Promise((resolve,reject)=>{ Logger.info(...) })`，既未 resolve 也未 reject。若 `getPreferences` 抛错，所有 `await getFormIds(...)` 的调用方（`pushFormUpdate`、`setSilentModeAndMixWithOthers`）将**静默挂起**。建议改为 `return []` 或 `reject`。
3. **`year` 解析后丢失**：`AudioMetaReader` 能解析 `year`，但 `SongItem` 无 `year` 字段，`refreshMetadataIfNeeded` 仅写 `title/artist/album/author`，`year` 被丢弃。若 PRD 承诺“年代全链路”，需补 `SongItem.year` 持久化与展示（或确认 `SongDetailSheet` 运行时再读 `AudioMetaReader`——需核实）。
4. **设置项 init 前写入静默丢失**：`SettingsStore` 在 `pref` 未初始化时 `set*` 直接 return。确保任何设置写入都在 `EntryAbility.init` 之后（目前成立，但需作为契约守护）。
5. **SILENT_ID 混入 formIds 数组**：静音标记以 magic 字符串 `'silentId'` 存于桌面卡片 formIds 集合（`AudioRendererController.setSilentModeAndMixWithOthers`，:154-159），被 `AVSessionController.pushFormUpdate`（:620）遍历时误当卡片 ID 调 `updateForm`（当前被 catch 吞掉，良性但属数据模型污染）。安全报告 **F-10(P2)** 已收录，建议独立为 Preferences 键解耦。

### P2（优化/一致性，可排期）
1. **播放模式三套表示不一致**：`models/music.ts` 的 `RepeatMode='single'|'list'|'random'`、`SettingsStore.RepeatModeSetting='list'|'single'|'random'`、`songdatacontroller.PlayerData.MusicPlayMode`（数值枚举 0/1/2）。建议统一为单一类型，避免跨层转换出错。
2. **`as ESObject` 类型逃逸**：`AVSessionController`（`castController as ESObject`，:428-429）与 `AudioMetaReader`（`raw as ESObject`，:58）为绕过编译器过载/类型限制使用逃逸。安全报告 **F-09(P2)** 已标注——本身非安全漏洞，但应随 SDK 类型完善逐步收敛封装并补运行时校验，长期削弱类型安全。
3. **Logger 隐私脱敏不彻底**：安全报告 `F-03`（**安全侧定级 P1**）已系统性覆盖——共 8 处打印完整沙箱路径（含歌名），含 `AudioRendererController.loadAndPlay()`（:222 `Logger.info('Playing: ' + song.title + ' from ' + song.src)`）、`SongItemBuilder`/`MediaTools`/`CoverCache`/`EmbeddedLyricReader`/`AVSessionController` 等。应统一走 `sanitize`（仅留文件名）或 `*Private` 变体（与 `AudioMetaReader` 既有做法一致）。（注：本架构报告 P2 为该问题在"架构演进优先级"下的归类，与安全侧 P1 不冲突，详见附录 C。）
4. **`EmbeddedLyricReader` 静态缓存无上限**：仅 `removeSong` 时 `evict`，超大曲库长期驻留。建议加 LRU/容量上限。
5. **`BreakpointSystem` 构造期读 AppStorage `uiContext`**：与 `EntryAbility` 播种顺序强耦合；若注册早于播种会拿到 `undefined`。建议延迟到 `register()` 内取。
6. **`MusicStore.playList` 可能 stale**：`setSongs` 时 `playList=[...songs]`，但后续增删曲库不同步 `playList` → “播放全部”若读 `playList` 会拿到旧数据。建议统一以 `songs` 为源，删除冗余 `playList` 或在其变更时同步。
7. **原生 `durationMs/sampleRate/channels` 未充分利用**：AudioMetaReader 未采用 C++ 解析的时长/采样率，时长仍由 MediaKit 取。可考虑在 MediaKit 失败时以前者兜底，减少依赖面。
8. **`PreferencesUtil` 冗余 Promise 包装与日志残留**（如 `'WANG'` 拼写、`getFormIds` 冗余分支）属清理项。

---

## 6. 演进路线建议（架构视角）

1. **状态层收敛**：将 `AppStorage` 信号量与单例控制器统一为可测试的“播放会话状态机”（如引入 `@Observed`/`AppStorage` 聚合对象 `PlaybackState`），降低三源列表带来的认知负担（对应 P1-1）。
2. **领域模型单一化**：`SongItem` 增补 `year` 等字段并统一播放模式类型；用 `@Observed`/`@ObjectLink` 替代大数组 `@StorageLink('songList')` 的整段重渲染。
3. **原生能力前移**：把时长/采样率解析、冷门编码分支回退逻辑沉淀到 C++ 层，ArkTS 侧仅做编排，提升冷启动与异常鲁棒性。
4. **可测试/可Mock**：将 `AudioRendererController`/`AVSessionController` 的交互抽象为接口，便于单元化与无设备 CI（配合现有 `tools/` Python 验证脚本）。
5. **多端扩展**：`BreakpointSystem` + 资源限定词已具备“一多”基础，后续平板/车机等可仅补 `RANGE_*` 与布局分支。

---

## 附录 C：与安全报告的对应关系
本报告的隐私/健壮性交叉点已与 `review_security.md` 对齐，便于联合跟踪：
- **F-03（Logger 完整沙箱路径泄漏）** ↔ 本报告 §5 P2-3（8 处路径打印，脱敏方案一致）。
- **F-09（`as ESObject` 类型逃逸）** ↔ 本报告 §5 P2-2（AVSessionController:428-429 / AudioMetaReader:58）。
- **F-10（SILENT_ID 混入 formIds）** ↔ 本报告 §5 P1-5（数据模型污染，建议独立键）。
- 权限最小化（3 项、无媒体库读写）结论与 `review_security.md` §二 完全一致，互为印证。

## 附录 A：API 版本与权限要点（供 API 文档）
- **最低/目标 SDK**：`compileSdkVersion/targetSdkVersion/compatibleSdkVersion = 6.1.1(24)`（API 24）。
- **关键 Kit**：`@kit.ArkUI`、`@kit.MediaKit`、`@kit.AVSessionKit`、`@kit.ArkData`、`@kit.ImageKit`、`@kit.CoreFileKit`、`@kit.AbilityKit`、`@kit.FormKit`、`@kit.LocalizationKit`、`@kit.PerformanceAnalysisKit`、`@kit.BasicServicesKit`、`@kit.ArkTS`。
- **权限（3 项，运行时最小化）**：`ohos.permission.KEEP_BACKGROUND_RUNNING`（inuse）、`ohos.permission.INTERNET`（always）、`ohos.permission.GET_NETWORK_INFO`（always）。无媒体库读写权限（歌曲走沙箱）。
- **已知 SDK 限制**：6.1.1 无 `@kit.MultimodalAwarenessKit`（智感握姿仅布局自适应）；`setSpatializationEnabled`/多频段 EQ 无公开 API（设置页只读展示）；歌单云同步无账号体系（仅本地）。
- **原生编译**：`nativeCompiler: BiSheng`，`CMakeLists.txt` 路径 `./src/main/cpp/CMakeLists.txt`。

## 附录 B：ArkTS 红线核对（供 reviewer 交叉验证）
- 组件内**禁用普通 `get` 访问器**作状态（会被丢弃）→ 项目用 `@StorageProp`/`@Watch` + 普通方法（`SongItem.getMark()/getLabel()` 为模型类方法，合规）。
- **禁 `any`/`unknown` 作类型逃逸**（除必要的 `as ESObject` NAPI 透传，已标注）。
- **禁解构声明**导致状态丢失 → 本仓未见违规。
- 构造成员首语句须有效（当前 `Logger`/单例模式均合规）。
