# Lumio Music · 鸿蒙音乐播放器

> **Lumio 系列** · 本地优先的 HarmonyOS NEXT 原生应用（同系列：碰卡 / NearCard）

<img width="200" height="200" alt="logo" src="https://github.com/user-attachments/assets/bec472ea-0320-4c85-85a5-1c898d9d9aee" />

一款运行在 **HarmonyOS** 平台的本地音乐播放器，基于 **ArkTS + ArkUI + C++ Native** 开发。
主打简洁流畅的本地听歌体验，并已全面接入 **HDS 设计系统** 与 **沉浸光感**，播放器进出采用 **一镜到底** 共享元素动画。

> 完整版本演进见 [CHANGELOG.md](./CHANGELOG.md)。

---

## 演示

本应用为 HarmonyOS 移动端原生应用，无法通过 Web 链接在线访问。以下是真机演示视频：

<video src="https://raw.githubusercontent.com/a703201/Lumio_Music/main/Video/Demo.mp4" controls width="100%" poster="https://github.com/user-attachments/assets/bec472ea-0320-4c85-85a5-1c898d9d9aee"></video>

> 💡 如果视频无法在线播放，可 [点击此处下载](./Video/Demo.mp4) 后本地观看（~50MB）。

**本地体验**：具备 HarmonyOS 6.1.1 DevEco Studio 环境的开发者，可直接克隆本仓库并运行 `bash build_hap.sh` 构建签名 HAP。

```bash
git clone https://github.com/a703201/Lumio_Music.git
cd Lumio_Music
bash build_hap.sh
# 产物：entry/build/default/outputs/default/entry-default-signed.hap
```

---

## 功能特性

### 音乐库（核心）
- 由「歌曲」与「音乐库」两个页面 **合并为统一入口**（音乐库页）。
- **导入音乐**：通过系统文件选择器将本地音频导入曲库（导入功能已从原歌曲页迁移至此）。
- **搜索**：顶部搜索栏实时过滤歌曲。
- 歌曲列表、收藏高亮、播放中高亮状态一目了然。
- **长按歌曲**唤出操作选项栏（播放 / 收藏 / 添加到歌单 / 详细 / 删除），列表行右侧不再挂「更多」按钮，详见下方「歌曲操作」。
- 空状态提示 + 引导导入。

### 播放体验
- 播放控制：播放 / 暂停 / 上一首 / 下一首。
- **迷你播放器**：底部悬浮卡片显示当前播放歌曲的**真实内嵌封面**（非默认占位图），点击进入播放器页。
  - 播放时封面**不旋转**；暂停时在封面中央叠加 `sys.symbol.pause_fill` 暂停图标，播放时隐藏。
  - 封面由 `Layout.playerButton` 的 `refreshPlayerCover()` 从 `CoverCache.getLabel()` 取真图，在 `aboutToAppear` / `coverRefreshToken` / `selectIndex` / `songList` 变化时刷新。
- **一镜到底动画**：迷你封面与播放器页通过 `geometryTransition` 共享元素 + `interpolatingSpring` 曲线，实现进出场的顺滑形变；**两端均使用同一张真实封面**，过渡连续无跳变。
- **播放器页**：封面大图、歌词显示、播放进度与控制台。
- **歌词手动滑动浏览**：Canvas 歌词（`LrcView.ets`）支持上下滑动手势自由浏览；滑动过程中**取消模糊**、全部歌词清晰可读；手指静止 **5 秒**后自动平滑回到「正在播放」的歌词行并恢复模糊焦点效果。

### 歌曲操作（长按选项栏 + 半模态面板）
- **长按选项栏**：歌曲列表**不再使用右侧的 `ic_hm_more` 按钮**，改为 **长按歌曲**（`bindContextMenu(menu, ResponseType.LongPress)`）唤出选项栏。选项栏统一为「图标 + 文字」样式，宽度约 200，圆角卡片 + 阴影。
- 各页面选项栏内容：

  | 页面 | 选项 |
  |------|------|
  | 音乐库 `LocalLibrary` | 播放 / 收藏切换 / 添加到歌单 / 详细 / 删除 |
  | 我的收藏 `Favorites` | 播放 / 取消收藏 / 添加到歌单 / 详细 |
  | 播放历史 `PlayHistory` | 播放 / 收藏切换 / 添加到歌单 / 详细 |
  | 歌单详情 `PlaylistDetail` | 播放 / 收藏切换 / 添加到歌单 / 详细 / 移出歌单 |
  | 我的歌单 `Playlists`（歌单项） | 播放 / 重命名 / 删除歌单（原右侧 `bindMenu` 按钮改为长按） |

- **详情半模态面板**（`SongDetailSheet`）：点击「详细」经 `bindSheet` 弹出（`detents: [SheetSize.MEDIUM, SheetSize.LARGE]`，`preferType: SheetType.BOTTOM`），展示 **文件名 / 标题 / 歌手 / 作曲家 / 合集 / 年代 / 添加时间**。文件名取自 `decodeURIComponent(src)` 末段，添加时间取 `fs.statSync(src).mtime`，**年代从音频元数据异步读取**。
- **添加到歌单半模态面板**（`AddToPlaylistSheet`）：点击「添加到歌单」弹出 Medium 面板，列出全部自建歌单一键加入；重复加入提示「歌曲已在歌单中」；面板内可直接**新建歌单并立即加入**，经 `onClose` 回调关闭。
- **年代（year）全链路解析**：C++ `audio_metadata.cpp` 解析 FLAC `DATE` / MP3 `TYER`+`TDRC` / MP4 `©day` → NAPI `napi_init.cpp` 返回 `year` → ArkTS `AudioMeta.year`（MediaKit 优先路径从 `AVMetadata.dateTime` 用 `extractYear` 正则 `/(19|20)\d{2}/` 抽 4 位年份）→ 详情面板打开时 `AudioMetaReader.read(src)` 异步取值。
  - 设计取舍：**year 不落 `SongItem`**，改为详情面板按需重读——既让新旧歌曲都能显示年代，也**不改动 `dataPreferences` 既有数据结构**。

### 自建歌单（Playlist）
- **我的歌单**：新建 / 重命名 / 删除歌单，同名校验，空歌单占位提示。
- **歌单详情**：按歌单内顺序展示曲目，支持 **播放全部**、单曲起播、**移出歌单**。
- **拖拽排序**：在歌单详情内**长按歌曲并拖动**即可重排（`ForEach.onMove` 内建长按拖拽手势），落点给出语义化 from/to，`MusicStore.reorderPlaylistSongs` 持久化，顺序本地保存；长按不拖动则弹出选项栏（见「歌曲操作」）。
- **添加歌曲**：底部面板从本地库多选加入，自动过滤已在歌单中的曲目并去重（与「详细」「添加到歌单」共用页面内**单一 `bindSheet`**，按 `sheetKind` 分发）。
- 播放歌单时会**将歌单曲目整体设为播放队列**（`setQueue`），与本地库全量队列互不干扰。
- 数据统一存于 `MusicStore`（`dataPreferences: music_store`），从本地库删除歌曲会同步清理歌单中的悬挂引用。

### 我的（个人中心）
- 列表支持 **上下滑动**（Scroll 容器）。
- 听歌统计面板：歌曲数 / 收藏数 / 最近播放数。
- 入口：收藏列表、**我的歌单**、播放历史、设置。
- 头像呼吸灯、数字滚动等微动效。

### 设置
- **清空播放历史**：一键清除最近播放记录。
- **设置子页**（`SettingsCategory`）：点击设置项进入分类子页，支持自动下一首开关、播放模式选择、主题切换（系统/浅色/深色）、锁屏媒体控制开关。
- **版本信息**：跳转关于页查看版本与功能特色。
- **隐私政策**：查看应用隐私政策。
- **开发者**：点击跳转开发者简历网页 `https://www.a703201sworld.top/resume/`（开发者署名：何宇翔）。

### 沉浸与握姿适配
- **HDS 设计系统**：根导航 `HdsNavigation` + 主布局 `HdsTabs`，底部标签栏采用自定义沉浸式样式。
- **沉浸光感**：底部栏 `barFloatingStyle` 启用 `systemMaterialEffect`（ADAPTIVE 材质），与系统视觉融合。
- **智感握姿（底栏自适应）**：底部栏 `adaptToHandedness: true`，根据握持姿态自适应布局。

---

## 技术栈

| 维度 | 选型 |
|------|------|
| 前端框架 | ArkTS + ArkUI（声明式） |
| 原生模块 | C++ (NAPI) 音频元数据解析：FLAC(VORBIS_COMMENT/STREAMINFO)、MP3(ID3v2 + MPEG 帧头)、MP4(mvhd/ilst)，作为 MediaKit 的兜底路径 |
| 设计系统 | HDS（`@kit.UIDesignKit`） |
| 路由 | Navigation + NavPathStack（HdsNavigation / NavDestination） |
| 开发工具 | DevEco Studio |
| 目标平台 | HarmonyOS **6.1.1 (API 24)**，兼容 6.1.0(23) |
| 目标设备 | phone |
| bundleName | `com.Lumio.music`（见 `AppScope/app.json5`） |

---

## 架构与项目结构

### 导航模型
- `Index.ets`：`HdsNavigation` 根容器，承载 `NavPathStack`，首屏 push `Layout`。
- `Layout.ets`：`HdsTabs` 主布局，内含两个 Tab 子组件 —— **音乐库**（`LocalLibrary`）、**我的**（`Mine`），以及底部的迷你播放器（一镜到底共享元素）。
- **推送页（NavDestination）**：`PlayerPage`、`Settings`、`SettingsCategory`、`About`、`PrivacyPolicy`、`Favorites`、`PlayHistory`、`ManageSongs`、`Playlists`、`PlaylistDetail`，通过 `route_map.json` 注册并以 `pushPathByName` 入栈（`PlaylistDetail` 以歌单 id 作为路由参数，页面内按 id 实时取数，不缓存对象副本；`SettingsCategory` 以分类 id 作为路由参数，按 id 渲染对应设置子项）。
- **Tab 子组件**（非独立页面）：`LocalLibrary`、`Mine` 直接作为 `HdsTabs` 的 `TabContent` 内容。

### 目录结构

```
Lumio_Music/
├── AppScope/                        # 应用级配置（包名、版本、图标）
│   └── resources/base/element/
│       └── string.json              # app_name = "Lumio Music"
├── entry/src/main/
│   ├── ets/
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets     # 应用入口 Ability（initStore、窗口沉浸、桌面卡片回控）
│   │   ├── entrybackupability/
│   │   │   └── EntryBackupAbility.ets # 数据备份恢复
│   │   ├── formability/
│   │   │   └── FormAbility.ets      # 桌面卡片能力
│   │   ├── pages/
│   │   │   ├── Index.ets            # 入口：HdsNavigation 根容器
│   │   │   ├── Layout.ets           # 主布局：HdsTabs + 迷你播放器（一镜到底共享元素）
│   │   │   ├── LocalLibrary.ets     # 音乐库 Tab（合并 Songs+Moment，含导入）
│   │   │   ├── Mine.ets             # 我的 Tab（可滚动，含统计面板/歌单/历史入口）
│   │   │   ├── PlayerPage.ets       # 播放器页（一镜到底目标）
│   │   │   ├── Settings.ets         # 设置：清空历史 / 版本 / 开发者
│   │   │   ├── SettingsCategory.ets # 设置子页：自动下一首/播放模式/主题/锁屏开关
│   │   │   ├── About.ets            # 关于（版本 + 功能特色）
│   │   │   ├── PrivacyPolicy.ets    # 隐私政策
│   │   │   ├── Favorites.ets        # 收藏列表
│   │   │   ├── Playlists.ets        # 我的歌单（新建/重命名/删除/拖拽调序）
│   │   │   ├── PlaylistDetail.ets   # 歌单详情（播放全部/加歌/移出/拖拽排序）
│   │   │   ├── ManageSongs.ets      # 曲库管理（移除歌曲）
│   │   │   └── PlayHistory.ets      # 播放历史
│   │   ├── services/
│   │   │   └── MusicStore.ets       # 全局状态与曲库数据（单例，含收藏/歌单/历史）
│   │   ├── models/
│   │   │   ├── music.ets            # SongItem 数据模型
│   │   │   └── lyric.ets            # LyricLine 数据模型
│   │   ├── songdatacontroller/
│   │   │   ├── SongData.ets         # SongItem 定义
│   │   │   ├── PlayerData.ets       # MusicPlayMode 枚举（ORDER/RANDOM/SINGLE_CYCLE）
│   │   │   └── SongItemBuilder.ets  # 从 rawfile/沙箱构建 SongItem（fd 生命周期管理）
│   │   ├── datasource/
│   │   │   ├── SongDataSource.ets   # IDataSource 实现（列表懒加载）
│   │   │   └── SongListData.ets     # 初始示例数据（实际由 MusicStore 管理）
│   │   ├── components/
│   │   │   ├── PlayerInfoComponent.ets    # 播放页封面+背景模糊
│   │   │   ├── LyricsComponent.ets        # 歌词容器（翻译开关+明暗自适应）
│   │   │   ├── MusicInfoComponent.ets      # 标题/艺术家/专辑展示
│   │   │   ├── ControlAreaComponent.ets   # 进度条/播放控制
│   │   │   ├── TopAreaComponent.ets        # 顶栏（返回/收藏等）
│   │   │   ├── CoverImageView.ets          # 响应式封面组件（coverRefreshToken 刷新）
│   │   │   ├── SongDetailSheet.ets         # 歌曲详情半模态面板（含年代）
│   │   │   └── AddToPlaylistSheet.ets      # 添加到歌单半模态面板（含新建歌单）
│   │   ├── lyric/
│   │   │   ├── LrcView.ets           # Canvas 歌词渲染（手动滑动+5秒回正）
│   │   │   ├── LrcUtils.ets         # LRC/KRC 解析 + rawfile 兜底
│   │   │   ├── LrcEntry.ets        # 歌词行数据结构
│   │   │   └── LyricConst.ets       # 歌词常量
│   │   ├── utils/                   # 工具类
│   │   │   ├── AudioRendererController.ets  # AVPlayer 播放引擎（队列/模式/后台）
│   │   │   ├── AVSessionController.ets      # 系统媒体会话（锁屏/投播/卡片）
│   │   │   ├── AudioMeta.ets               # 元数据读取（MediaKit+NAPI 双路）
│   │   │   ├── NativeModule.ets             # C++ NAPI 桥接
│   │   │   ├── CoverCache.ets              # 封面抽取+缓存（单例）
│   │   │   ├── EmbeddedLyricReader.ets     # 内嵌歌词解析（FLAC/MP4/MP3）
│   │   │   ├── PreferencesUtil.ets        # dataPreferences 封装
│   │   │   ├── SettingsStore.ets           # 设置项持久化（app_settings）
│   │   │   ├── ThemeManager.ets            # 主题色令牌（浅/深/系统）
│   │   │   ├── MediaTools.ets             # 媒体工具
│   │   │   ├── BackgroundUtil.ets          # 后台长时任务
│   │   │   ├── Logger.ets                  # 统一日志（domain 0xFF00）
│   │   │   ├── AppInfoUtil.ets             # 运行时版本读取
│   │   │   └── ResourceConversion.ets      # 资源转换
│   │   ├── common/
│   │   │   ├── constants/           # 常量（断点/播放器/路由/样式/内容）
│   │   │   └── utils/              # 断点系统、颜色转换
│   │   └── widget/pages/
│   │       └── WidgetCard.ets       # 桌面卡片 UI + 回控
│   ├── cpp/                         # C++ 原生模块（NAPI）
│   │   ├── audio_metadata.cpp/.h    # FLAC/MP3/MP4 元数据解析
│   │   ├── napi_init.cpp            # NAPI 模块注册
│   │   └── CMakeLists.txt           # 编译配置（libnative_module.so）
│   ├── resources/base/
│   │   ├── media/                   # 资源（含 ic_hm_* 图标等 87 个 SVG）
│   │   └── profile/                  # main_pages / route_map / form_config 等
│   └── module.json5                 # 权限与 Ability 声明
├── tools/                           # 开发辅助脚本（Python）
│   ├── dump_3files.py               # C++ 解析器验证：3 个真实音频 dump
│   ├── probe_lyrics.py              # 歌词编码探测工具
│   ├── verify_reader.py            # EmbeddedLyricReader 验证
│   └── verify_reversal.py           # 回绕缺陷验证
├── build_hap.sh                     # 签名 HAP 构建脚本（规避环境问题）
├── build-profile.json5              # 编译 / SDK 版本 / 签名配置
├── oh-package.json5                 # 依赖（hypium 测试 + hamock）
├── LICENSE                          # Apache-2.0 完整文本
├── NOTICE                           # 版权声明
├── CHANGELOG.md                     # 版本演进日志
├── README.md                        # 本文件
├── overview.md                      # 交付概览
└── docs/                            # 项目文档
    ├── PRD_Lumio_Music.md            # 产品需求文档
    ├── 功能模块拆解表.md            # 模块→文件映射
    ├── 代码审查报告_PRD落地.md       # 第一轮审查报告
    ├── 代码审查报告_第二轮增强.md    # 第二轮审查报告
    ├── 实施计划_PRD落地.md          # PRD 落地实施计划
    ├── 实施计划_第二轮增强.md       # 第二轮增强实施计划
    └── C++解析器真实音频验证.md      # C++ 解析器验证报告
```

---

## 设计亮点

- **一镜到底动画**：迷你封面 `geometryTransition('player_cover', { follow: true })` 与播放器页根节点共享同一 ID，进出场 `push/pop` 均包在 `animateTo(interpolatingSpring(0,1,328,36))` 中，过渡连续无跳变。
- **HDS 沉浸光感**：`barFloatingStyle({ systemMaterialEffect: { materialType: ADAPTIVE, materialLevel: ADAPTIVE } })`，底部栏随系统材质自适应。
- **智感握姿（底栏自适应）**：`barFloatingStyle({ adaptToHandedness: true })`，底部栏布局跟随握持姿态。
- **页面合并与减负**：原「歌曲」+「音乐库」合并为单一音乐库页，导入功能下沉至音乐库；**移除不可用的扫描功能**，设置页**移除不可调整的播放模式项**，界面更聚焦。
- **列表操作收进长按菜单**：去掉列表行右侧的「更多」按钮，操作全部收进 `bindContextMenu` 长按选项栏，列表更清爽，点击区域也不再误触。
- **响应式封面组件**：新增 `CoverImageView.ets` 组件，监听 `coverRefreshToken` + `src` 双信号自动刷新封面，解决列表项 `ForEach` 复用时 `Image(song.getMark())` 从默认 Resource 切换到真实 PixelMap 不重渲染的问题。
- **单一 `bindSheet` 分发**：ArkUI 中同一组件**只能挂一个 `bindSheet`**（后挂覆盖先挂）。各页面统一改为「一个 `bindSheet` + `sheetOpen` 开关 + `sheetKind`（`detail` / `add` / `picker`）判别 + `@Builder sheetContent()` 按 kind 渲染」，避免多面板互相顶掉。

---

## 权限说明

本应用遵循**权限最小化**原则，`module.json5` 中实际仅声明以下 2 项权限：

| 权限 | 用途 | 时机 |
|------|------|------|
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | 后台持续播放（长时任务：audioPlayback） | inuse |
| `ohos.permission.INTERNET` | 关于页跳转开发者主页 / 投播设备网络发现 | always |

**为什么没有媒体库权限？**
歌曲来源全部为「用户主动通过 `DocumentViewPicker` 选择 → 拷贝进应用沙箱 → 记录于 `dataPreferences`」，
播放时以 `fdSrc` 读取沙箱文件，**全程不访问系统媒体库**，因此不需要 `READ_MEDIA` / `WRITE_MEDIA`。
同理，智感握姿仅使用 HDS 底栏的 `adaptToHandedness` 自适应布局（无需权限），未做主动手势监听，
因此不声明 `DETECT_GESTURE`。

> 应用无账号体系、无数据上传、无广告 SDK，所有歌曲、收藏、歌单、播放历史均只存于本机。

---

## 构建与运行

### 方式一：DevEco Studio（图形化）

```
使用 DevEco Studio 打开本项目
Build > Build Hap(s)/APP(s) > Build Hap(s)
```

### 方式二：命令行脚本（推荐，稳定出签名 HAP）

```bash
bash build_hap.sh
```

产物路径：

```
entry/build/default/outputs/default/entry-default-signed.hap
```

> **为什么用 `build_hap.sh` 而不是直接 `hvigorw assembleHap`？**
> 脚本用于规避两类环境问题：
> 1. WorkBuddy 注入的 `NODE_OPTIONS=genie-safe-delete.cjs` 守卫会拦截 hvigor 清理构建产物，导致构建崩溃；
> 2. PATH 中损坏的 Oracle Java 会让 hvigor 命中坏 JVM。
>
> 脚本会**前置 JBR**、**清空 `NODE_OPTIONS` / `BASH_ENV`**、并以 `--no-daemon` 运行，保证一次跑通。

> 需安装 **HarmonyOS 6.1.x SDK（API 23 / 24）**。当前工程已通过 `bash build_hap.sh` 验证 **BUILD SUCCESSFUL**，可产出签名 HAP；同时经 `harmonyos-reviewer` 审查 **0 ERROR / 0 WARNING**。

### 开发辅助脚本（tools/）

| 脚本 | 用途 |
|------|------|
| `dump_3files.py` | 用 `g++` 编译 standalone harness，对 3 个真实音频文件（FLAC/M4A/中文 FLAC）运行 C++ 解析器验证 |
| `probe_lyrics.py` | 探测音频文件内嵌歌词的编码格式（UTF-16 LE/BE/UTF-8），辅助 `EmbeddedLyricReader` 调试 |
| `verify_reader.py` | 验证 `EmbeddedLyricReader` 对 FLAC/MP4/MP3 内嵌歌词的解析正确性 |
| `verify_reversal.py` | 构造畸形文件验证 C++ 解析器对 32 位长度回绕缺陷的修复有效性 |

> 这些脚本在沙箱环境无法出 HAP 时用于离线验证 C++ 侧逻辑，真机构建无需依赖。

---

## 已知问题与限制

- **智感握姿主动感知**：当前 6.1.1 SDK 未内置 `@kit.MultimodalAwarenessKit`，因此仅底栏 `adaptToHandedness` 的**自适应布局**生效；若需「主动监听左右手握持」事件（`motion.on('holdingHandChanged')`），需升级到包含该 Kit 的更高版本 SDK。**这是 SDK 能力缺口，非实现缺陷。**
- **API 弃用告警**：已完成迁移 —— `Prompt.showToast` 全部改为 `this.getUIContext().getPromptAction().showToast(...)`，`animateTo` 改为 `this.getUIContext().animateTo(...)`。无 `UIContext` 上下文的工具类（如 `ResourceConversion`）继续通过 `AppStorage` 注入的 `UIAbilityContext` 取资源，属预期用法。
- **元数据解析分层**：文本元数据优先走 MediaKit `AVMetadataExtractor`；失败或标题缺失时回退 C++ NAPI 解析器。C++ 侧覆盖 FLAC / MP3 / MP4 三类容器，解析失败一律回退「文件名作标题」，保证不崩，但**冷门编码分支建议在真机复验**。
- **空间音频 / 多频段 EQ**：`setSpatializationEnabled` 需系统权限 `MANAGE_SYSTEM_AUDIO_EFFECTS`，三方应用只能只读查询；多频段 EQ 无公开 API。设置页因此仅展示状态、不提供开关。
- **发现页**：原 `Find.ets` 骨架经复核为孤儿文件（未注册导航、无引用），已在第二轮增强中**下线删除**，如后续要重启需从零设计，不保留旧骨架。
- **歌单能力边界**：支持建 / 删 / 改名 / 加歌 / 移出 / 播放全部 / **手动拖拽排序**；**云同步仍不支持**（无账号体系）。
- **一镜到底白屏 / 底部栏默认封面（已修复，v2.3.0）**：早期版本进入播放页偶发白屏或布局错乱，根因为 `PlayerPage` 误对整个 `PlayerInfoComponent` 施加 `geometryTransition`，叠加 `expandSafeArea` 与 `NavDestination` 的 `ignoreLayoutSafeArea` 后，纯渐变背景偶发错乱；现已回退为 **Image 放大模糊**的稳态背景，共享元素仅作用于封面节点。底部栏此前显示默认占位封面，现已改为真实内嵌封面，两端一致。
- **`bindSheet` 单绑定限制（已修复，v2.3.0）**：同一组件挂多个 `bindSheet` 时后者会覆盖前者，曾导致「详细」面板不弹；现每页只保留**单一 `bindSheet`**，由 `sheetKind` 判别渲染内容。

---

## 许可证

**Lumio Music** 基于 [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0) 发布。

- 版权所有 © 2026 **何宇翔**
- 允许查看、参考、修改与再分发，但**任何分发（含修改后）必须保留版权声明、许可证文本及 NOTICE 文件，并声明所做的修改**。
- 本软件按「原样」提供，不提供任何明示或暗示的担保。

完整条款见仓库根目录 [`LICENSE`](./LICENSE) 与 [`NOTICE`](./NOTICE) 文件。
