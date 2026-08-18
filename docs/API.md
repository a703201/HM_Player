# Lumio Music — 开发者 API 参考文档

> 版本基线：HarmonyOS NEXT 6.1.1（API 24）/ Stage 模型 / ArkTS + C++ NAPI（libnative_module.so）
> 包名（bundleName）：`com.lumio.music`　许可证：Apache-2.0
> 本文档所有方法签名与调用约束均直接采信自 `docs/review_architecture.md` §3「公开 API 面盘点」，未做任何推断性扩展。
> 配套文档：`review_architecture.md`（架构与状态）、`review_security.md`、`review_compliance.md`。

---

## 1. 概述

### 1.1 目标读者

- **应用内开发者**：需要调用播放引擎、曲库、主题、封面、歌词、元数据、卡片等能力的页面/组件编写者。
- **扩展/集成方**：基于系统媒体会话、桌面卡片、投播做二次开发的协作者。
- **维护者/审查者**：需要核对公开契约、红线与跨进程边界的架构与合规角色。

> 本文件只描述「公开 API 契约」（`public` / `static` / 对外服务成员）。内部私有方法不纳入契约，其行为以源码为准。

### 1.2 文档约定

- **方法表列**：方法 / 签名 / 参数 / 返回 / 说明。
- **示例**：均为可独立运行的 ArkTS 片段（省略 import 与 UI 包裹），可直接粘贴到页面/工具方法中验证。
- **单例**：凡标注「单例」的模块，必须通过 `getInstance()` 获取，禁止 `new`。
- **AppStorage 语义**：`@StorageProp` 单向、`@StorageLink` 双向、`@Watch` 监听（详见 §4）。
- **类型别名**：`SongItem`（`models/music.ets`）、`RepeatMode`、`Playlist`、`MusicPlayMode`、`ThemeMode`、`AudioMeta`、`AudioMetadata`、`ColorTokens` 等以源码定义为准。
- **Kit 前缀**：文中 `@kit.*` 为导入模块来源，调用前需在 `oh-package.json5` / `module.json5` 已申请对应依赖与权限（见 §1.3、§1.4）。

### 1.3 SDK / Kit 依赖

| Kit | 用途 | 主要使用模块 |
|---|---|---|
| `@kit.ArkUI` | 组件/布局/Navigation/装饰器 | 全部 UI、BreakpointSystem、路由 |
| `@kit.MediaKit` | `AVPlayer` 播放、`AVMetadataExtractor` 元数据 | AudioRendererController、AudioMetaReader、CoverCache |
| `@kit.AVSessionKit` | 系统媒体会话/锁屏/投播/卡片 | AVSessionController |
| `@kit.ArkData` | `preferences` 持久化 | SettingsStore、PreferencesUtil |
| `@kit.ImageKit` | `image.PixelMap` 封面 | CoverCache |
| `@kit.CoreFileKit` | 沙箱文件/`fileIo`/`DocumentViewPicker` | SongItemBuilder、MusicStore |
| `@kit.AbilityKit` | `UIAbility`/`Want`/`formProvider` | EntryAbility、FormAbility |
| `@kit.FormKit` | 桌面卡片 Extension 与 `formProvider` | FormAbility、WidgetCard、AVSessionController |
| `@kit.LocalizationKit` | 语种/本地化 | LrcUtils（语种多数决，间接） |
| `@kit.PerformanceAnalysisKit` | 性能剖析（间接） | — |
| `@kit.BasicServicesKit` | 基础服务（hilog 等） | Logger |
| `@kit.ArkTS` | 运行时/TaskPool | AudioMetaReader（原生回退） |

> 项目原生层：`entry/src/main/cpp`（`audio_metadata.cpp/.h`、`napi_init.cpp`），编译产物 `libnative_module.so`，`nativeCompiler: BiSheng`，`CMakeLists.txt` 位于 `./src/main/cpp/CMakeLists.txt`。

### 1.4 调用前置条件（必读）

1. **应用上下文播种**：`EntryAbility.onCreate` 必须先向 AppStorage 播种 `context`/`uiContext`/`window`/`systemIsDark`/`currentBreakpoint`，再初始化各单例。
2. **MusicStore**：使用任何曲库/收藏/歌单 API 前，**必须**先 `await MusicStore.getInstance().init(context)`。
3. **SettingsStore**：所有 `set*` 在 `pref` 未初始化时静默 no-op，必须在 `EntryAbility` 完成 `init` 后再写。
4. **AudioRendererController**：`avPlayerReady` 异步就绪，**所有播放入口（`play/start/pause/stop/release/seek/playNext/playPrevious` 等）须 `await`**，防止冷启动竞态。
5. **ThemeManager / BreakpointSystem**：`init()` / `register()` 依赖 AppStorage 已播种；`BreakpointSystem` 构造期读取 `uiContext`，不可早于播种。
6. **原生解析**：`AudioMetaReader` 的 C++ NAPI 回退为同步耗时调用，已封装于 `taskpool` 工作线程，调用方无需自行包裹，但不得在主线程直接 `import 'libnative_module.so'`。
7. **桌面卡片**：卡片为独立进程，禁止直连播放 API；回控必须走 `want` 拉起主 Ability（见 §6）。

---

## 2. 模块 API 参考

> 建议与 `review_architecture.md` §3 编号一一对应。

### §3.1 `MusicStore` — 曲库/收藏/歌单权威持久层

- **职责**：曲库、收藏、歌单、最近播放的唯一持久权威（落盘 `music_store`）。
- **路径**：`services/MusicStore.ets`
- **类型**：单例（私有构造 + 懒加载）。

| 方法 | 签名 | 参数 / 返回 | 说明 |
|---|---|---|---|
| 单例 | `static getInstance(): MusicStore` | → 单例 | 全局唯一 |
| 初始化 | `init(context: Context): Promise<void>` | ctx → Promise | 读 `music_store`，失败置 `loadError` |
| 全量设置 | `setSongs(songs: SongItem[]): void` | songs → void | 同步 `songs`/`playList` 并持久化 |
| 索引/播放 | `setCurrentIndex(i: number): void` | i → void | 内存写 |
| 索引/播放 | `setIsPlaying(b: boolean): void` | b → void | 内存写 |
| 索引/播放 | `setRepeatMode(mode: RepeatMode): void` | mode → void | 内存+持久化 |
| 收藏 | `toggleFavorite(songId: number): void` | songId → void | 以 `song.id` 为主键 |
| 收藏 | `isFavorite(songId: number): boolean` | songId → boolean | 查询收藏态 |
| 歌单 | `addPlaylist(name: string, songIds: number[]): Playlist` | name, songIds → Playlist | id=`Date.now()_随机` 防重 |
| 歌单 | `deletePlaylist(id: string): void` | id → void | — |
| 歌单 | `getPlaylistById(id: string): Playlist \| undefined` | id → Playlist? | 页间只传 id，避免副本不同步 |
| 歌单 | `hasPlaylistName(name: string, excludeId?: string): boolean` | name, excludeId? → boolean | 去重校验 |
| 歌单 | `renamePlaylist(id: string, name: string): void` | id, name → void | trim 后写 |
| 歌单 | `addSongsToPlaylist(pid: string, songIds: number[]): number` | pid, songIds → number | 返回实际新增数 |
| 歌单 | `removeSongFromPlaylist(pid: string, songId: number): void` | pid, songId → void | — |
| 歌单 | `reorderPlaylistSongs(pid: string, from: number, to: number): void` | pid, from, to → void | 拖拽排序 |
| 最近播放 | `addToRecentlyPlayed(song: SongItem): void` | song → void | 上限 50 |
| 最近播放 | `getRecentlyPlayed(): SongItem[]` | → SongItem[] | — |
| 最近播放 | `clearRecentlyPlayed(): void` | → void | — |
| 收藏列表 | `getFavoriteSongs(): SongItem[]` | → SongItem[] | 由 `songs` 过滤 |
| 删除歌曲 | `removeSong(songId: number): void` | songId → void | evict 封面/歌词缓存、清理歌单悬挂引用 |
| 元数据补偿 | `refreshMetadataIfNeeded(): Promise<void>` | → Promise | 首次启动补扫文本元数据（幂等标记 `meta_scanned_v1`） |

**公开字段**：`songs`、`playList`、`currentIndex`、`isPlaying`、`repeatMode`、`favorites: Set<number>`、`playlists`、`recentlyPlayed`、`loadError`。

**调用约束**：
1. 单例，必须先 `init(context)`。
2. 所有落盘经私有 `save*`，异常仅 `Logger.error` 不抛出。
3. `favorites` 为 `Set<number>`，序列化时转数组。
4. `removeSong` 会同步清理封面/歌词缓存与歌单悬挂引用；删歌后调用方须执行 `AudioRendererController.reconcileWithLibrary(store.songs)` 对齐队列（见 §2 状态管理）。

**最小示例**：
```ts
import { MusicStore } from '../services/MusicStore';

// 启动后（EntryAbility 已 init）
const store = MusicStore.getInstance();
const fav = store.isFavorite(song.id);
store.toggleFavorite(song.id);                 // 切换收藏
const list = store.getFavoriteSongs();         // 收藏列表
const pl = store.addPlaylist('我的最爱', [song.id]);
store.addSongsToPlaylist(pl.id, [another.id]); // 返回实际新增数
```

---

### §3.2 `SettingsStore` — 设置项持久层

- **职责**：自动下一首、播放模式、主题模式、锁屏控制、听歌统计、降低动态等设置的持久权威（落盘 `app_settings`）。
- **路径**：`utils/SettingsStore.ets`
- **类型**：单例。类型：`ThemeMode='system'|'light'|'dark'`、`RepeatModeSetting='list'|'single'|'random'`。

| 方法 | 签名 | 参数 / 返回 | 联动 |
|---|---|---|---|
| 单例/初始化 | `getInstance()` | → 单例 | — |
| 初始化 | `ensureInitialized(ctx)` | ctx → void | 幂等 |
| 初始化 | `init(ctx): Promise<void>` | ctx → Promise | 幂等 |
| 自动下一首 | `getAutoNext(): boolean` | → boolean | — |
| 自动下一首 | `setAutoNext(v: boolean): Promise<void>` | v → Promise | — |
| 播放模式 | `getRepeatMode(): RepeatModeSetting` | → RepeatModeSetting | — |
| 播放模式 | `setRepeatMode(v): Promise<void>` | v → Promise | 联动 `MusicStore.setRepeatMode` |
| 主题模式 | `getThemeMode(): ThemeMode` | → ThemeMode | — |
| 主题模式 | `setThemeMode(v): Promise<void>` | v → Promise | — |
| 锁屏控制 | `getNotificationLockScreen(): boolean` | → boolean | — |
| 锁屏控制 | `setNotificationLockScreen(v): Promise<void>` | v → Promise | 联动 `AVSessionController.setLockScreenControl` |
| 听歌统计 | `getPrivacyStats()` | → any | — |
| 听歌统计 | `setPrivacyStats()` | → void | — |
| 降低动态 | `getReduceMotion()` | → any | 无障碍 |
| 降低动态 | `setReduceMotion()` | → void | 无障碍 |

**调用约束**：
1. 独立 PREF `app_settings`（与 `MusicStore`/`PreferencesUtil` 三套并存）。
2. **`pref` 未初始化时 `set*` 静默 no-op**（`putBoolean/putString` 检查 `!pref` 直接 return）；须在 `EntryAbility` 已 `init` 后写。
3. 跨类联动是隐式副作用，文档需明示：`setRepeatMode`→MusicStore、`setNotificationLockScreen`→AVSessionController。

**最小示例**：
```ts
import { SettingsStore } from '../utils/SettingsStore';

const s = SettingsStore.getInstance();
await s.ensureInitialized(this.context);      // 幂等
await s.setThemeMode('dark');                 // 持久化+刷新
const auto = s.getAutoNext();                 // 读取，无需 await
await s.setNotificationLockScreen(true);      // 联动 AVSession 锁屏控制
```

---

### §3.3 `ThemeManager` — 主题访问门面（纯静态）

- **职责**：深浅色/主题模式的统一访问门面，组件禁止自行算深浅色。
- **路径**：`utils/ThemeManager.ets`
- **类型**：纯静态（无实例）。`ColorTokens={bg,secondaryBg,cardBg,primaryText,secondaryText,separator,accent}`。

| 方法 | 签名 | 说明 |
|---|---|---|
| `static init(): void` | 读 `SettingsStore.themeMode`→写 AppStorage `themeMode`/`isDark` | — |
| `static isDark(): boolean` | system 模式读 AppStorage `systemIsDark` | — |
| `static getColors(): ColorTokens` | 按 `isDark` 返回浅/深令牌 | — |
| `static get lightColors: ColorTokens` | 静态 getter（浅色令牌） | — |
| `static get darkColors: ColorTokens` | 静态 getter（深色令牌） | — |
| `static setThemeMode(mode: ThemeMode): void` | 持久化+刷新+`applyToWindow()` | — |
| `static refreshSystemTheme(): void` | 系统变更时刷新（仅 system 模式有效） | — |
| `static applyToWindow(): void` | 同步状态栏/导航栏内容色 | — |

**调用约束**：
- 无实例；依赖 AppStorage `themeMode/isDark/systemIsDark/window`。
- `accent` 固定 `#FA2759`。
- `setThemeMode` 会触发窗口系统栏重绘。

**最小示例**：
```ts
import { ThemeManager } from '../utils/ThemeManager';

ThemeManager.init();
const dark = ThemeManager.isDark();
const tokens = ThemeManager.getColors();       // { bg, secondaryBg, ... accent }
// 组件内响应式取色：
// const c = dark ? ThemeManager.darkColors : ThemeManager.lightColors;
```

---

### §3.4 `CoverCache` — 内嵌封面抽取与缓存（单例）

- **职责**：内嵌封面抽取、内存缓存、负缓存与批量预载。
- **路径**：`utils/CoverCache.ets`
- **类型**：单例。`image.PixelMap` 来自 `@kit.ImageKit`。

| 方法 | 签名 | 说明 |
|---|---|---|
| `static getInstance(): CoverCache` | 取单例 | — |
| `get(src: string): image.PixelMap \| undefined` | 同步命中读取 | — |
| `isMissing(src: string): boolean` | 负缓存（确认无封面） | — |
| `load(src: string): Promise<image.PixelMap \| undefined>` | 抽取（pending 去重 + missing 短路） | — |
| `evict(src: string): void` | 删歌时清理 | — |
| `preload(songs: {src:string}[], concurrency?: number): Promise<void>` | 批量预载（默认并发 4） | — |

**调用约束**：
1. 仅对沙箱真实文件（`/`/`file://`/`internal://`）抽取，跳过 `.pcm`/rawfile。
2. 经 `AVMetadataExtractor.fetchAlbumCover()`。
3. 抽取失败/无封面**静默**返回 undefined，调用方须自行处理默认图。
4. 调用方在 `preload` 完成后应刷新 `songList`/`coverRefreshToken` 触发 UI 重绘（封面范式见 §4.2）。

**最小示例**：
```ts
import { CoverCache } from '../utils/CoverCache';

const cache = CoverCache.getInstance();
const pm = await cache.load(song.src);          // PixelMap | undefined
if (!pm) { /* 显示默认封面 */ }
// 启动预载
await cache.preload(store.songs);
AppStorage.setOrCreate('coverRefreshToken', Date.now());
```

---

### §3.5 `AVSessionController` — 系统媒体会话/锁屏/投播/卡片（单例，AppStorage 托管）

- **职责**：系统媒体会话、锁屏媒体卡片、投播、桌面卡片状态推送与回控的唯一收口。
- **路径**：`utils/AVSessionController.ets`（`@kit.AVSessionKit`）
- **类型**：单例，由 AppStorage `'AVSessionController'` 托管。

| 方法 | 签名 | 说明 |
|---|---|---|
| `static getInstance(): AVSessionController` | AppStorage 托管取单例 | — |
| `setSongList(list: SongItem[], index?: number): void` | 同步元数据源（队列变更后） | — |
| `bindAudioRendererController(c: AudioRendererController): void` | 双向装配 | 触发 `ensureListenersRegistered` |
| `setAVMetadata(): Promise<void>` | 推送标题/封面/歌词到锁屏 | 投播中切歌会重新投播 |
| `setPlayModeToAVSession(): void` | AVSession LoopMode 同步 | — |
| `setLoopModeState(m): Promise<void>` | AVSession LoopMode 同步 | — |
| `setProgressState(ms: number)` | 播放进度 | 同时 `pushFormUpdate()` |
| `setPlayState(isPlay: boolean)` | 播放状态 | 同时 `pushFormUpdate()` |
| `pushFormUpdate(): void` | 跨进程推送卡片状态 | formProvider |
| `remoteControl(cmd: string): void` | `'play'\|'pause'\|'next'\|'prev'` | 卡片回控入口 |
| `setLockScreenControl(enabled: boolean): void` | 激活/停用 AVSession | 联动设置项 |
| `updateFavoriteState(assetId: string): Promise<void>` | 收藏收口（按 id） | — |
| `getAndUpdateFavoriteState(assetId): Promise<void>` | 收藏收口（按 id） | — |
| `unregisterSessionListener(): Promise<void>` | 注销监听 + 退出释放投播 | — |

**内部（非公开，影响行为）**：`startCast/stopCast/castCurrentSong/onOutputDeviceChange`（投播经 `AVCastController`）；`onPlay/onPause/onPlayNext/onPlayPrevious/onSeek/onSetLoopMode/onToggleFavorite`（系统媒体键回调）。

**调用约束**：
1. 与 `AudioRendererController` 双向引用，`ensureListenersRegistered` 去重保活。
2. 投播 `castController.off('playNext'...)` 用 `as ESObject` 绕过重载不匹配（已知类型逃逸，见 §5）。
3. 收藏以 `song.id` 为稳定主键，绝不依赖会漂移的队列下标。
4. 投播与本地播放用**独立 fd**（`castFile` 与 `curFile` 解耦）。

**最小示例**：
```ts
import { AVSessionController } from '../utils/AVSessionController';

const av = AVSessionController.getInstance();
av.bindAudioRendererController(AudioRendererController.getInstance());
av.setSongList(queue, 0);                       // 队列变更后同步
av.setPlayState(true);                          // 同时推送卡片
av.remoteControl('next');                       // 卡片/系统键回控
await av.unregisterSessionListener();           // 退出释放
```

---

### §3.6 `AudioRendererController` — 播放引擎/队列权威（单例，AppStorage 托管）

- **职责**：播放队列与 `AVPlayer` 的唯一写者，播放/暂停/进度/模式/投播静音的权威。
- **路径**：`utils/AudioRendererController.ets`（`@kit.MediaKit` AVPlayer）
- **类型**：单例，由 AppStorage `'audioRendererController'` 托管。

| 方法 | 签名 | 说明 |
|---|---|---|
| `static getInstance(): AudioRendererController` | AppStorage 托管取单例 | — |
| `play(musicIndex?: number): Promise<void>` | 起播（先 `await avPlayerReady`） | 记最近播放+`syncQueue` |
| `start(): Promise<void>` | AVPlayer 起播 | 生命周期 |
| `pause(): Promise<void>` | 暂停 | 生命周期 |
| `stop(): Promise<void>` | 停止 | 生命周期 |
| `release(): Promise<void>` | 释放 fd+停长时任务 | 生命周期 |
| `seek(ms: number): void` | `SeekMode.SEEK_CLOSEST` | — |
| `playNext(): Promise<void>` | 按 `playMode` 切换 | — |
| `playPrevious(): Promise<void>` | 按 `playMode` 切换 | — |
| `getFirst(): boolean` | 是否队列首 | 查询 |
| `getCurrentSong(): SongItem \| undefined` | 当前曲 | 查询 |
| `getCurrentPosition(): number` | 当前位置(ms) | 查询 |
| `getDuration(): number` | 时长(ms) | 查询 |
| `getQueue(): SongItem[]` | 队列（返回副本） | 查询 |
| `getCurrentIndex(): number` | 当前下标 | 查询 |
| `setQueue(songs, startIndex, autoPlay?: boolean): void` | 覆盖队列+可选起播 | 排序场景 `autoPlay=false` |
| `playFromList(list: SongItem[], index: number): void` | 点歌即播 | = `setQueue(list,index,true)` |
| `removeFromQueue(index: number): void` | 移除并维持 current 正确 | — |
| `moveToPlayNext(index: number): void` | 下一首播放 | — |
| `reconcileWithLibrary(library: SongItem[]): void` | 队列与曲库差量对齐 | 见 §4.3 |
| `setPlayModel(m: MusicPlayMode): void` | 模式设置 | 联动 AVSession |
| `getPlayMode(): MusicPlayMode` | 当前模式 | 联动 AVSession |
| `setCastActive(active: boolean): void` | 投播期本地静音标记 | — |
| `setSilentModeAndMixWithOthers(isSupportSilent?: boolean): Promise<void>` | 静音/混音 | 写 `SILENT_ID` 到 formIds 集合 |

**公开字段**：`avPlayer?: media.AVPlayer`、`castActive: boolean`。

**调用约束**：
1. **播放队列唯一权威**，组件不得直连 `avPlayer`，须经控制器方法。
2. `avPlayerReady` 异步就绪，所有入口须 `await`。
3. `syncQueue()` 是 AppStorage 与 AVSession 的唯一回写点。
4. `reconcileWithLibrary` 仅在导入/删歌后调用，不在进播放页时调用（避免覆盖手动队列编辑）。
5. `BackgroundUtil.startContinuousTask` 维持后台播放（长时任务）。

**最小示例**：
```ts
import { AudioRendererController } from '../utils/AudioRendererController';

const player = AudioRendererController.getInstance();
await player.playFromList(library, tapIndex);    // 点歌即播
await player.pause();
await player.seek(30000);
await player.playNext();                          // 按 playMode 切换
// 删歌后对齐：
player.reconcileWithLibrary(MusicStore.getInstance().songs);
```

---

### §3.7 `AudioMetaReader` + `NativeUtils` — 文本元数据双路解析

- **职责**：文本元数据（title/artist/album/author/year）双路解析：MediaKit 优先，C++ NAPI 兜底。
- **路径**：`utils/AudioMeta.ets`、`utils/NativeModule.ets`
- **类型**：`AudioMetaReader` 静态类；`NativeUtils` 单例。
- 类型：`AudioMeta = { title?, artist?, album?, author?, year? }`；`AudioMetadata`(C++) = `{ title, artist, album, year, durationMs, sampleRate, channels }`。

| 类 | 方法 | 签名 |
|---|---|---|
| `AudioMetaReader` | `static read(src: string): Promise<AudioMeta \| null>` | MediaKit 优先 + NAPI 兜底（taskpool） |
| `NativeUtils` | `static getInstance()` | 取单例 |
| `NativeUtils` | `add(a,b): number` | 能力验证 |
| `NativeUtils` | `parseAudioMetadata(path): AudioMetadata` | C++ NAPI 封装（同步） |
| `NativeUtils` | `getDeviceInfo(): DeviceInfo` | 设备信息 |

**调用约束**：
1. `read`：**MediaKit `AVMetadataExtractor` 优先**；仅当失败或 `title` 缺失才回退 C++ NAPI。
2. 回退为**同步 NAPI**，必须在 `taskpool` 工作线程执行（`parseMetaOnWorker` 用 `@Concurrent` 顶层具名函数，闭包形式会抛 10200014）。
3. 返回纯数据（仅字符串字段），跨线程可序列化。
4. 日志**脱敏**（`sanitize` 只留文件名，避免沙箱路径进 hilog）。
5. MediaKit 不暴露内嵌歌词，故本类只取文本元数据，歌词走 `EmbeddedLyricReader`。

**最小示例**：
```ts
import { AudioMetaReader } from '../utils/AudioMeta';

const meta = await AudioMetaReader.read(song.src);   // AudioMeta | null
if (meta?.title) { /* 采用解析到的标题 */ }
```

---

### §3.8 `EmbeddedLyricReader` — 内嵌歌词定点解析（静态类）

- **职责**：内嵌/外挂歌词定点解析（FLAC/MP3/MP4 + 同名 `.lrc` 回落）。
- **路径**：`utils/EmbeddedLyricReader.ets`
- **类型**：静态类 + 静态 `Map` 缓存（含负结果）。

| 方法 | 签名 | 说明 |
|---|---|---|
| `static read(src: string): Promise<string \| undefined>` | 解析内嵌/外挂歌词（含负缓存） | — |
| `static evict(src: string): void` | 删歌清理 | — |

**内部能力（非公开）**：FLAC `VORBIS_COMMENT`（LYRICS/UNSYNCEDLYRICS/含 LYRIC 键）、MP3 ID3v2 `USLT/ULT`+`TXXX(LYRICS)`、MP4 `©lyr`+`----`(LYRICS)、魔数嗅探、回落同名 `.lrc`；编码探测（BOM/UTF-16 启发式→UTF-8）；`MAX_*` 上限（ID3 8MB / VORBIS 4MB / moov 16MB / 歌词 512KB）防 OOM。

**调用约束**：
1. 静态类 + 静态 `Map` 缓存（含负结果）。
2. **定点读取**不整文件载入。
3. 解析失败/无歌词返回 `undefined`（静默）。
4. 歌词中 `year` 字段无关（歌词文本）。

**最小示例**：
```ts
import { EmbeddedLyricReader } from '../utils/EmbeddedLyricReader';

const lrc = await EmbeddedLyricReader.read(song.src);   // string | undefined
if (lrc) { /* 交给 LrcUtils.parseLrcLyric 解析 */ }
```

---

### §3.9 `LrcUtils` + `LrcEntry` — 歌词文本解析（纯函数）

- **职责**：LRC/KRC 歌词文本解析，语种多数决区分原文/翻译，逐字高亮数据。
- **路径**：`lyric/LrcUtils.ets`、`lyric/LrcEntry.ets`
- **类型**：模块函数（非类）。`LrcEntry = { lineStartTime, lineDuration, lineWords, words: Word[], translation? }`。

| 方法 | 签名 | 说明 |
|---|---|---|
| `getRawStringData(ctx: Context, rawFilePath: string): Promise<string>` | 读 rawfile LRC | — |
| `parseLrcLyric(text: string): Array<LrcEntry>` | LRC 解析，语种多数决区分原文/翻译 | 注意大小写 |
| `parseKrcLyric(text: string): LrcEntry[]` | KRC 逐字（Word[]）解析 | — |
| `angleToRadian(angle: number): number` | 角度→弧度工具 | — |

**调用约束**：
1. 导出为**模块函数（非类）**，注意大小写 `parseLrcLyric`。
2. 语种多数决（`translationIsCjk`）区分原文/翻译，并剔除 `CREDIT_KEYWORDS`（作词/作曲…）制作信息行，避免翻译语种误判。
3. KRC 提供逐字高亮数据。

**最小示例**：
```ts
import { parseLrcLyric } from '../lyric/LrcUtils';

const entries = parseLrcLyric(lrcText);    // LrcEntry[]
for (const e of entries) {
  // e.lineStartTime, e.translation, e.words ...
}
```

---

### §3.10 `Logger` — 统一日志门面（纯静态）

- **职责**：全仓统一日志入口（封装 hilog，domain `0xFF00`，prefix `MusicPlay`）。
- **路径**：`utils/Logger.ets`（`@kit.BasicServicesKit` hilog）

| 方法 | 签名 | 说明 |
|---|---|---|
| `debug/info/warn/error(...args: string[])` | `%{public}s` | 公开日志 |
| `debugPrivate/infoPrivate/warnPrivate/errorPrivate(...args: string[])` | `%{private}s` | release 自动隐藏 |

**调用约束**：全仓统一经此入口，便于级别管控与隐私脱敏；敏感数据（路径/歌名）应走 `*Private` 或先 `sanitize`（见 §5）。

**最小示例**：
```ts
import { Logger } from '../utils/Logger';

Logger.info('queue synced, size=' + queue.length);
Logger.errorPrivate('file', sanitize(song.src));   // 脱敏路径
```

---

### §3.11 `BreakpointSystem` + `BreakpointType` — 响应式断点

- **职责**：一多响应式断点（sm/md/lg）基础。
- **路径**：`common/utils/BreakpointSystem.ets`

| 类 | 方法 | 签名 |
|---|---|---|
| `BreakpointType<T>` | `constructor(option: {sm?,md?,lg?})` | 泛型选项 |
| `BreakpointType<T>` | `getValue(currentPoint: string): T` | 取当前断点值 |
| `BreakpointSystem` | `register(): void` | 监听 sm/md/lg 写 AppStorage `currentBreakpoint` |
| `BreakpointSystem` | `unregister(): void` | 注销监听 |

**调用约束**：
1. 依赖 AppStorage `uiContext` 已播种（构造期读取）。
2. 是「一次开发多端部署（一多）」的响应式基础。
3. 配合 `common/constants/BreakpointConstants` 的 `RANGE_SM/MD/LG`。

**最小示例**：
```ts
import { BreakpointSystem, BreakpointType } from '../common/utils/BreakpointSystem';

const bp = new BreakpointSystem();
bp.register();                                    // 写 AppStorage.currentBreakpoint
const cols = new BreakpointType({ sm: 1, md: 2, lg: 3 }).getValue(
  AppStorage.get('currentBreakpoint') ?? 'sm'
);
```

---

### §3.12 `SongItemBuilder` — 媒体 fd 准备（默认类，非单例）

- **职责**：为沙箱文件/rawfile 准备 `RawFileDescriptor`（fd），防泄漏。
- **路径**：`songdatacontroller/SongItemBuilder.ets`
- **类型**：默认类（需 `new`，非单例）。

| 方法 | 签名 | 说明 |
|---|---|---|
| `build(songItem: SongItem): Promise<SongItem>` | 准备 `RawFileDescriptor` | — |
| `getRawFileDescriptor(): resourceManager.RawFileDescriptor \| undefined` | 取描述符 | — |
| `release(): Promise<void>` | 释放 fd | 必须配对调用 |

**调用约束**：实例需 `context`（构造期读 AppStorage `context`）；`releaseFileFd` 必须配对调用避免 fd 泄漏。

**最小示例**：
```ts
import { SongItemBuilder } from '../songdatacontroller/SongItemBuilder';

const builder = new SongItemBuilder();
const ready = await builder.build(song);
const fd = builder.getRawFileDescriptor();
// ... 播放使用 ...
await builder.release();                         // 释放 fd
```

---

### §3.13 `PreferencesUtil` — 底层偏好封装（PREF `myStore`）

- **职责**：桌面卡片 formIds、权限引导、静音标记的低层偏好封装（第三套 preferences）。
- **路径**：`utils/PreferencesUtil.ets`（`@kit.ArkData`）
- **类型**：单例。

| 方法 | 签名 | 备注 |
|---|---|---|
| `static getInstance()` | 取单例 | — |
| `getPreferences(ctx): Promise<preferences.Preferences>` | 读 `myStore` | — |
| `preferencesFlush(p)` | 落盘 | — |
| `preferencesPut(p, formIds)` | 写 formIds | — |
| `preferencesHas(p)` | 是否含键 | — |
| `getFormIds(ctx): Promise<Array<string>>` | ⚠ 见风险 | **异常分支返回永不应答 Promise** |
| `addFormId(ctx, formId)` | 登记卡片 ID | SILENT_ID 也混入此数组 |
| `removeFormId(ctx, formId)` | 注销卡片 ID | — |
| `isPermGuideShown(ctx): Promise<boolean>` | 权限引导标记 | — |
| `markPermGuideShown(ctx): Promise<void>` | 标记权限引导 | — |
| `removePreferencesFromCache(ctx)` | 清缓存 | — |

**调用约束**：
1. 与 `MusicStore`/`SettingsStore` 是**第三套** preferences（`myStore`），仅承载桌面卡片 formIds、权限引导、静音标记。
2. **静音标记 `SILENT_ID='silentId'` 作为 magic 字符串塞进 `formIds` 数组**（关注点耦合，见 P1-5）。

**最小示例**：
```ts
import { PreferencesUtil } from '../utils/PreferencesUtil';

const pu = PreferencesUtil.getInstance();
const ids = await pu.getFormIds(this.context);     // string[]
await pu.addFormId(this.context, formId);
const shown = await pu.isPermGuideShown(this.context);
```

---

### §3.14 路由/导航相关

- **职责**：系统命名路由与 `NavPathStack` 导航。
- 关键常量 `RouterConstants`（`common/constants/RouterConstants.ets`）：静态只读 `PLAYER_PAGE='PlayerPage'`、`NAV_PATH_STACK_CONSTANTS='NavPathStack'`、`PLAYER_INFO_COMPONENT`。
- `route_map.json`（`resources/base/profile/`）：12 个命名目的地（`Layout`/`PlayerPage`/`Settings`/`SettingsCategory`/`About`/`PrivacyPolicy`/`PlayHistory`/`Favorites`/`ManageSongs`/`Playlists`/`PlaylistDetail` + `Layout`）。
- 导航实现：`@Provide('navPathStack') pathStack: NavPathStack`（`HdsNavigation(this.pathStack)`）→ 子页 `@Consume('navPathStack')` → `pathStack.pushPathByName(name, param)`（或 `router.pushNamedRoute`）。

**调用约束**：新增页面须在 `route_map.json` 注册 `name`+`pageSourceFile`+`buildFunction`，且页面导出对应 `*Builder`；跨页参数经 `NavPathStack` 入参传递，歌单等仅传 `id` 再查 `MusicStore`。

**最小示例**：
```ts
// 根壳
@Provide('navPathStack') pathStack: NavPathStack = new NavPathStack();
// 子页
@Consume('navPathStack') pathStack: NavPathStack;
// 跳转（歌单仅传 id）
pathStack.pushPathByName('PlaylistDetail', { id: playlist.id });
```

---

### §3.15 桌面卡片（跨进程）

- **职责**：桌面播控卡片（状态推送 + 按钮回控），独立进程渲染。
- 关键组件：
  - `FormAbility`（`formability/FormAbility.ets`）：`onAddForm/onRemoveForm` 登记 formId；`onFormEvent` 仅记录（实际回控经 WidgetCard 的 `postCardAction` router 事件→`EntryAbility.handleControlWant`→`AVSessionController.remoteControl`）。
  - `WidgetCard`（`widget/pages/WidgetCard.ets`）：`@LocalStorageProp('title'|'artist'|'isPlaying')`；按钮 `postCardAction(this,{action:'router',abilityName:'EntryAbility',params:{control:'play'|'pause'|'next'|'prev'}})`。
  - 状态推送：主应用 `AVSessionController.pushFormUpdate()` 经 `formProvider.updateForm` 跨进程写 `title/artist/isPlaying`。

**调用约束**：卡片为独立进程，不可直接调系统播放 API；回控必须走 want 拉起主 Ability（见 §6）。

**最小示例**（卡片内）：
```ts
// WidgetCard.ets
Button('下一首').onClick(() => {
  postCardAction(this, {
    action: 'router',
    abilityName: 'EntryAbility',
    params: { control: 'next' }
  });
});
```

---

### §3.16 C++ NAPI 原生层

- **职责**：FLAC/MP3/MP4 真实音频元数据解析（C++）。
- **路径**：`entry/src/main/cpp/audio_metadata.h`、`.cpp`、`napi_init.cpp`（产物 `libnative_module.so`）
- 公开 C++ 函数：`AudioMetadata parseAudioMetadata(const std::string& filePath)`：返回 `{title, artist, album, year, durationMs, sampleRate, channels}`。
- 经 `napi_init.cpp` 注册导出；由 `NativeUtils.parseAudioMetadata` 在 `taskpool` 工作线程调用。

**调用约束**：
1. NAPI 同步、C++ 解析耗时，**必须置于工作线程**（已在 `AudioMetaReader` 用 `taskpool` 包裹）。
2. 内存安全已修（P0×6：size_t/uint64 边界校验）。
3. `durationMs/sampleRate/channels` 当前仅作能力储备，`AudioMetaReader` 未采用（时长仍由 MediaKit 取）。

**最小示例**（业务层不应直连，统一走 `AudioMetaReader`，此处仅示意封装边界）：
```ts
// 业务层：禁止 import 'libnative_module.so'
import { AudioMetaReader } from '../utils/AudioMeta';
const meta = await AudioMetaReader.read(src);     // 内部已 taskpool 包裹 NAPI 回退
```

---

## 4. 状态管理与全局入口

### 4.1 AppStorage 信号量清单

| 键 | 类型 | 生产者 | 主要消费者 | 用途 |
|---|---|---|---|---|
| `context` | `Context` | EntryAbility | 各工具/Builder | 全局上下文 |
| `uiContext` | `UIContext` | EntryAbility | BreakpointSystem | 媒体查询 |
| `window` | `window.Window` | EntryAbility | ThemeManager | 状态栏内容色 |
| `systemIsDark` | `boolean` | EntryAbility(onConfigurationUpdated) | ThemeManager(跟随系统) | 系统深色态 |
| `themeMode` | `'system'\|'light'\|'dark'` | ThemeManager | ThemeManager/样式 | 主题模式 |
| `isDark` | `boolean` | ThemeManager | 组件 `@StorageProp('isDark')` | 派生深浅色 |
| `songList` | `SongItem[]` | AudioRendererController.syncQueue | ControlArea/Lyrics/MusicInfo、AVSession | **播放队列镜像**（非曲库） |
| `selectIndex` | `number` | AudioRendererController.syncQueue | 组件、AVSession | 当前队列下标 |
| `isPlay` | `boolean` | AudioRendererController | ControlArea、AVSession、Widget | 播放态 |
| `progress` / `currentTime` / `totalTime` / `totalMsTime` / `progressMax` | `number`/`string` | AudioRendererController(时间回调) | 进度条/歌词联动 | — |
| `playMode` | `MusicPlayMode` | AVSessionController | ControlArea | 播放模式 |
| `isFavorite` | `boolean` | AVSessionController | ControlArea | 收藏态 |
| `isSilentMode` | `boolean` | AudioRendererController | ControlArea | 静音/混音 |
| `coverRefreshToken` | `number` | EntryAbility | CoverImageView(`@StorageProp`+`@Watch`) | 封面刷新信号量 |
| `currentBreakpoint` | `'sm'\|'md'\|'lg'` | BreakpointSystem | 各组件响应式布局 | 断点 |
| `topHeight` / `bottomHeight` | `number` | EntryAbility | 布局避让 | 安全区 |
| `imageColor` / `pageShowTime` / `lyricBgDark` / `isFoldFull` | 混合 | 播放页/折叠态 | 光感/歌词明暗/折叠 | 播放页局部态 |
| `AVSessionController` / `audioRendererController` | 单例实例 | 各自 `getInstance()` | 互引装配 | 控制器单例托管 |

> **三条「歌曲列表」概念**（务必区分）：
> 1. `MusicStore.songs` —— 曲库（持久权威），dataPreferences 落盘。
> 2. `AudioRendererController.songList` —— 当前播放队列（运行时权威），由导入/点歌/排序/移除驱动。
> 3. `AppStorage.songList` —— 队列的**镜像**，供 UI 绑定。
> 组件读取「曲库」走 `MusicStore.getInstance().songs`/数据源；读取「当前播放队列」才走 `AppStorage.songList`。

### 4.2 装饰器使用矩阵

| 装饰器 | 语义 | 典型用法 |
|---|---|---|
| `@StorageProp` | 单向（AppStorage→组件） | `isDark`、`currentBreakpoint`、`selectIndex`(只读)、`lyricBgDark`、`coverRefreshToken` |
| `@StorageLink` | 双向（组件↔AppStorage） | `isPlay`、`progress`、`totalTime`、`currentTime`、`progressMax`、`songList`、`playMode`、`isFavorite`、`isSilentMode`、`selectIndex`(可写) |
| `@Watch('xxx')` | 监听变化触发回调 | CoverImageView：`@StorageProp('coverRefreshToken') @Watch('refresh')`；LyricsComponent：`@StorageProp('selectIndex') @Watch('getLrcEntryList')` |
| `@Provide/@Consume` | 跨组件层级传递 | `@Provide('navPathStack')` ↔ 子页 `@Consume('navPathStack')` |
| `@LocalStorageProp` | 卡片独立存储 | WidgetCard：`title`/`artist`/`isPlaying` |

**封面正确范式**：`coverRefreshToken` 是「信号量」而非数据——CoverImageView 监听其变化后**重新读取** `CoverCache`（而非把 PixelMap 直接塞进 AppStorage），避免大图常驻 AppStorage。

### 4.3 对齐机制（MusicStore ↔ AppStorage ↔ 队列）

```
启动：EntryAbility.onCreate
  └─ MusicStore.getInstance().init(ctx)         // 曲库落盘→内存
  └─ CoverCache.preload(store.songs)
  └─ AppStorage.setOrCreate('songList', store.songs)   // 仅作初值
  └─ AppStorage.setOrCreate('coverRefreshToken', Date.now())

播放/点歌：AudioRendererController.setQueue()/playFromList()
  └─ 改内部 songList + musicIndex
  └─ syncQueue() → AppStorage('songList','selectIndex') + AVSession.setSongList()

导入/删歌：
  └─ MusicStore 改 songs 并持久化
  └─ AudioRendererController.reconcileWithLibrary(store.songs)   // 唯一对齐点
       ① 队列删去曲库中已不存在的歌  ② 新歌追加队尾
       ③ 当前曲被删→续播相邻曲 / 空队列→stop()
       ④ syncQueue() 回写 AppStorage
  └─ AVSessionController.pushFormUpdate() 同步卡片
```

### 4.4 单例获取方式

| 模块 | 获取方式 |
|---|---|
| `MusicStore` | `MusicStore.getInstance()` |
| `SettingsStore` | `SettingsStore.getInstance()` |
| `CoverCache` | `CoverCache.getInstance()` |
| `AVSessionController` | `AVSessionController.getInstance()`（AppStorage 托管） |
| `AudioRendererController` | `AudioRendererController.getInstance()`（AppStorage 托管） |
| `NativeUtils` | `NativeUtils.getInstance()` |
| `PreferencesUtil` | `PreferencesUtil.getInstance()` |

> 静态门面（`ThemeManager`/`Logger`/`AudioMetaReader`/`EmbeddedLyricReader`/`LrcUtils`）无需 `getInstance()`，直接 `ClassName.method(...)`。

---

## 5. 已知限制与红线提示

1. **组件内普通 `get` 访问器被 ArkUI 丢弃**：状态须用 `@StorageProp`/`@Watch` + 普通方法，不得用普通 `get` 访问器承载可观察状态（模型类 `SongItem.getMark()/getLabel()` 为普通方法，合规）。
2. **敏感数据脱敏**：路径/歌名等敏感数据须走 `Logger.*Private` 或先 `sanitize`（仅留文件名），禁止完整沙箱路径进 hilog（安全报告 F-03）。
3. **原生解析须置于 taskpool 工作线程**：`parseAudioMetadata` 为同步 NAPI + 耗时 C++ 解析，经 `AudioMetaReader` 的 `taskpool` 封装；`raw as ESObject` 仅作已知类型逃逸透传，禁止泛化 `any/unknown` 逃逸（红线，仅 NAPI 透传豁免并已标注）。
4. **跨进程卡片不可直连播放 API**：桌面卡片须走 `want` 回控（见 §6），不可直接调用 `AudioRendererController`/`AVSessionController` 播放方法。
5. **`reconcileWithLibrary` 是队列/曲库唯一对齐点**：任何删歌入口（含未来播放页/Favorites/详情删歌）必须调用，否则 `next/prev` 会跳到已删文件（P0 契约）。
6. **三层 preferences 不可混用**：曲库→`MusicStore`、设置→`SettingsStore`、卡片/权限/静音→`PreferencesUtil`，表现层/业务层禁止裸 `dataPreferences`/`preferences` 调用。
7. **`SettingsStore` 未初始化时 `set*` 静默丢失**：所有设置写入须在 `EntryAbility.init` 之后。
8. **`PreferencesUtil.getFormIds` 异常分支挂起风险**：`catch` 返回永不应答 Promise，会使 `await` 调用方（`pushFormUpdate`/`setSilentModeAndMixWithOthers`）静默挂起（P1-2），调用方需做好超时/兜底。
9. **`as ESObject` 类型逃逸**：`AVSessionController.castController` 与 `AudioMetaReader.raw` 已标注（F-09/P2-2），本身非漏洞，但应随 SDK 类型完善收敛并补运行时校验。
10. **播放模式三套表示不一致**：`RepeatMode` / `RepeatModeSetting` / `MusicPlayMode`（数值枚举）跨层转换需谨慎（P2-1）。

---

## 6. 桌面卡片与投播跨进程边界

> 桌面卡片与主应用是**独立进程**，二者通过 `want`（系统命名路由）与 `formProvider.updateForm` 通信，禁止直接共享内存或单例。

### 6.1 边界与数据流

```
[WidgetCard 独立进程]                      [主应用进程]
  @LocalStorageProp(title/artist/isPlaying)
        │ 按钮点击
        │ postCardAction({action:'router', abilityName:'EntryAbility',
        │                  params:{control:'play'|'pause'|'next'|'prev'}})
        ▼
  EntryAbility.handleControlWant(want)
        │ 解析 control 指令
        ▼
  AVSessionController.remoteControl(cmd)   ──► 本地播放控制
        │
        │ setPlayState / setProgressState
        ▼
  AVSessionController.pushFormUpdate()
        │ formProvider.updateForm(formId, {title, artist, isPlaying})
        ▼
  [WidgetCard 重新渲染]  (跨进程状态推送)
```

### 6.2 关键约定

1. **回控方向（卡片→主应用）**：卡片按钮只能 `postCardAction` 发 `router` 事件拉起 `EntryAbility`；由 `EntryAbility.handleControlWant` 解析 `want.parameters.control`，再调用 `AVSessionController.remoteControl('play'|'pause'|'next'|'prev')`。卡片**不可**直接调播放 API。
2. **状态推送方向（主应用→卡片）**：主应用经 `AVSessionController.pushFormUpdate()` → `formProvider.updateForm` 跨进程写 `title/artist/isPlaying`；`FormAbility.onFormEvent` 仅记录，不承载实际回控。
3. **formId 登记**：`FormAbility.onAddForm` 登记、`onRemoveForm` 注销；formId 由 `PreferencesUtil.addFormId/removeFormId` 持久化，`pushFormUpdate` 遍历已登记 formId 推送。
4. **投播（Cast）边界**：投播经 `AVSessionController.startCast/stopCast` + `AVCastController`，使用**独立 fd**（`castFile` 与本地 `curFile` 解耦）；远端连/断自动切换、断连续播对齐。`castController.off(...)` 用 `as ESObject` 绕过重载（已知逃逸）。

### 6.3 红线

- 卡片进程内**禁止** import 主应用的 `*Controller` 单例、`AppStorage` 信号量或 `libnative_module.so`。
- 所有跨进程回控必须走 `want` → `handleControlWant` → `remoteControl` 链路，不得另起直连通道。

---

## 附录 A：SDK 版本与权限要点

- **最低/目标 SDK**：`compileSdkVersion/targetSdkVersion/compatibleSdkVersion = 6.1.1(24)`（API 24）。
- **关键 Kit**：`@kit.ArkUI`、`@kit.MediaKit`、`@kit.AVSessionKit`、`@kit.ArkData`、`@kit.ImageKit`、`@kit.CoreFileKit`、`@kit.AbilityKit`、`@kit.FormKit`、`@kit.LocalizationKit`、`@kit.PerformanceAnalysisKit`、`@kit.BasicServicesKit`、`@kit.ArkTS`。
- **权限（3 项，运行时最小化）**：`ohos.permission.KEEP_BACKGROUND_RUNNING`（inuse）、`ohos.permission.INTERNET`（always）、`ohos.permission.GET_NETWORK_INFO`（always）。无媒体库读写权限（歌曲走沙箱）。
- **已知 SDK 限制**：6.1.1 无 `@kit.MultimodalAwarenessKit`；`setSpatializationEnabled`/多频段 EQ 无公开 API（设置页只读展示）；歌单云同步无账号体系（仅本地）。
- **原生编译**：`nativeCompiler: BiSheng`，`CMakeLists.txt` 路径 `./src/main/cpp/CMakeLists.txt`。

## 附录 B：ArkTS 红线核对

- 组件内**禁用普通 `get` 访问器**作状态（会被丢弃）→ 用 `@StorageProp`/`@Watch` + 普通方法。
- **禁 `any`/`unknown` 作类型逃逸**（除必要的 `as ESObject` NAPI 透传，已标注）。
- **禁解构声明**导致状态丢失 → 本仓未见违规。
- 构造成员首语句须有效（Logger/单例模式均合规）。

---

> 文档维护：本 API 参考与 `docs/review_architecture.md` §3 强绑定，若源码方法签名变更，请同步更新两处并标注版本。
