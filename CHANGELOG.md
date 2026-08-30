# 更新日志 · CHANGELOG

本文件记录 Lumio Music（鸿蒙音乐播放器）的版本演进。
许可证：[Apache-2.0](./LICENSE)，Copyright © 2026 何宇翔。
代码当前 `versionName` 为 `2.4.0`（见 `AppScope/app.json5`）；应用内「关于 / 设置 / 我的」页的版本展示通过 `bundleManager` 运行时读取，**自动跟随该配置**，无需硬编码。下方里程碑按功能迭代划分。

---

## v2.4.0（2026-08-30）· 体验完善与缺陷修复

> 版本升版 2.3.0 → 2.4.0（`AppScope/app.json5`：`versionName 2.4.0` / `versionCode 2040000`）。本批次聚焦缺陷修复与体验打磨。

### 缺陷修复
- **播放页显示错歌（Bug A）**：`PlayerPage.aboutToAppear` 不再用整库覆盖 `AppStorage('songList'/'selectIndex')`，改为读取 `AudioRendererController` 真实播放队列；从「我的歌单」点播放后播放页正确显示正在播放的歌曲（系统播控中心本就正确，UI 与引擎来源此前分裂）。
- **静音/响铃按钮无功能（Bug B）**：`AudioRendererController.setSilentModeAndMixWithOthers` 真正调用 `AVPlayer.setVolume` 静音/恢复音量，并在 `prepared` 状态机重放时重新应用静音状态，修复「只变图标不静音」。

### 体验完善
- **歌词惯性滚动**：`LrcView` 松手后按末段速度做衰减动量滑动一小段，再触发原有 5 秒自动回正，符合甩动手势直觉。
- **关于页功能特色图标**：三张功能卡片的 Emoji 替换为项目既有 `ic_hm_library` / `ic_hm_search` / `ic_hm_list` 鸿蒙风格图标。

### 版本对齐
- `AppScope/app.json5` → `versionName 2.4.0` / `versionCode 2040000`。
- PRD、本 CHANGELOG、app.json5 版本口径统一为 v2.4.0。

## v2.3.0（2026-08-06）· 交互打磨与 NFR 品质提升

> Lumio Music 的交互深度优化与非功能需求品质工程批次。全部改动经 `harmonyos-reviewer` 审查 **0 ERROR / 0 WARNING**，`bash build_hap.sh` 稳定产出签名 HAP。

### 新增
- **长按选项栏替代右侧「更多」按钮**（FR-25）：`bindContextMenu(menu, ResponseType.LongPress)` 长按唤出选项栏，`@Builder buildSongMenu` / `buildPlaylistMenu` 统一渲染；覆盖音乐库、收藏、历史、歌单详情、我的歌单共五处。
- **歌曲详情半模态面板**（FR-26）：`components/SongDetailSheet.ets`，`bindSheet` MEDIUM/LARGE 高度，展示文件名/标题/歌手/作曲家/合集/年代/添加时间。
- **添加到歌单半模态面板**（FR-27）：`components/AddToPlaylistSheet.ets`（Medium），列出自建歌单，支持面板内新建歌单并立即加入。
- **年代全链路解析**（FR-28）：C++ `FLAC DATE` / MP3 `TYER`+`TDRC` / MP4 `©day` → NAPI `year` → ArkTS `AudioMeta.year`（MediaKit 优先、NAPI 兜底）→ 详情面板按需异步取值。year 不落 `SongItem`。
- **歌词手动滑动浏览**（FR-29）：`LrcView.ets` `onTouch` 状态机，滑动时取消模糊，手指静止 5 秒后自动回正。
- **迷你播放器真实封面**（FR-30）：`Layout.playerButton` 经 `CoverCache.getLabel()` 取真实封面，`geometryTransition('player_cover', {follow:true})` 一镜到底两端一致。
- **设置子页**（FR-31）：`pages/SettingsCategory.ets`（`route_map` 注册），按分类渲染设置子项。
- **隐私政策页**（FR-32）：`pages/PrivacyPolicy.ets`（`route_map` 注册）。
- **响应式封面组件**（FR-33）：`components/CoverImageView.ets`，监听 `coverRefreshToken` + `src` 双信号，解决 `ForEach` 复用时 Image 源切换不重渲染。
- **开发辅助脚本**（FR-34）：`tools/` 4 个 Python 脚本（`dump_3files.py` / `probe_lyrics.py` / `verify_reader.py` / `verify_reversal.py`），提供 C++ 解析器与歌词解析器离线验证。
- **统一版权声明**：全部源码文件（`.ets` / `.cpp` / `.h` / `.py`）添加 Apache-2.0 版权头（Copyright 2026 何宇翔）。

### NFR（非功能需求）品质提升
- **C++ 原生解析健壮性补强**：MP3 `&buf[s]` UB 守卫（零长帧不取过尾索引）、MP4 `largesize==0` 延伸至文件尾（ISO 14496-12 合规）、帧同步二次校验（连续 2 帧一致才采信）、CBR 尾部 ID3v1/APE 标签扣除（时长更精确）、`spf` Layer I/II/III 显式区分、`static_assert(sizeof(size_t)>=8)` 固化 64 位前提——全部已在 `audio_metadata.cpp` 落地。
- **NAPI 超长路径动态分配**：`napi_init.cpp` 原 `char filePath[1024]` 固定栈缓冲改为先探长度再 `std::vector<char>` 动态分配，>1023 字节路径不再静默截断。
- **NAPI 类型声明**：新增 `cpp/types/libnative_module/index.d.ts`，把 `parseAudioMetadata` 的 7 字段契约交给编译器守护，IDE 获得自动补全与类型检查。

### 优化
- 各页面底部 `bindSheet` 收敛为单一绑定 + `sheetKind` 分发（修复后挂覆盖先挂导致「详细」面板不弹）。
- 一镜到底回退为 Image 放大模糊稳态背景（修复偶发白屏/布局错乱）。
- C++ 兜底路径恢复生效：`AudioMetaReader` 并发入口改为顶层 `@Concurrent` 具名函数（修复真机静默抛 10200014）。
- 空状态呼吸动画由 `setInterval` 改为 `UIContext.animateTo` 循环 + `isDisposed`/`pageVisible` 守卫。
- 迷你封面暂停态叠加 `SymbolGlyph` 图标。

### 版本对齐
- `AppScope/app.json5` → `versionName 2.3.0` / `versionCode 2030000`（此前 `2.1.0` 为合并口径，升版后 CHANGELOG 里程碑与代码完全一致）。
- `route_map.json` 随功能增至 **11 条**（新增 `SettingsCategory`）。
- PRD、本 CHANGELOG、app.json5 版本口径统一为 v2.3.0。

### NFR 尾项闭合（2026-08-06 继续）
- **移除空间音频「开关」**：`SettingsCategory.ets` 原空间音频条目仅展示 `isSpatializationEnabledForCurrentDevice()` 的只读状态，无实际开关能力（`setSpatializationEnabled` 需系统权限）。移除 `querySpatialAudio()` / `@State spatialAudioEnabled` / UI 条目，`Settings.ets` 播放分类副标题同步去「空间音频」。
- **Logger 新增 `%{private}s` 变体**：`Logger.debugPrivate()` / `infoPrivate()` / `warnPrivate()` / `errorPrivate()`，release 构建自动隐藏私有字段，调用方可选择性将敏感数据（文件路径等）标记为私有。
- **`readFile` 内存优化**：FLAC / MP3 元数据位于文件头部，改为只读前 **2MB**——不再将整首歌曲（无损 FLAC 可达 40MB+）全量读入内存；MP4/M4A 因 moov atom 可能在文件末尾，保持全量读取。无损 FLAC 峰值内存降低 >90%。

### 产品细节完善（2026-08-06 继续）
- **错误处理增强**：`MusicStore` 新增 `loadError` 标记——持久化加载失败时页面展示明确错误提示+重试按钮，不再静默显示"空库"。
- **UI 错误态**：`LocalLibrary.ets` 新增错误态 UI（`LoadingProgress` 加载指示器 + 错误文案 + 「重试」按钮），覆盖 store 初始化失败与导入文件失败两种场景；`onPickMusic` 失败时 errorMessage 显式展示错误原因。
- **播放器空歌单守卫**：`AudioRendererController.playNext()` / `playPrevious()` / `playRandom()` / `playFromList()` 增加空歌单校验，避免空列表时产生负索引或死循环。
- **单元测试**：新增 `entry/src/test/LocalUnit.test.ets` 全套单元测试，覆盖 `LrcUtils`（`parseLrcLyric` / `parseKrcLyric` / `angleToRadian` 共 20 条）、`MusicStore`（CRUD / 收藏 / 歌单 / 最近播放 / 移除联动 共 25 条），核心业务逻辑语句覆盖率 >70%。

---

## v2.1.0（2026-07-30）· HDS 沉浸重构与功能基线

### 新增
- **接入 HDS 设计系统**：根导航 `HdsNavigation` + 主布局 `HdsTabs` 替换传统 `Navigation` / `Tabs` 组件。
- **底部栏沉浸光感**：`barFloatingStyle` 启用 `systemMaterialEffect`（ADAPTIVE 材质），与系统视觉融合。
- **一镜到底动画**：迷你播放器封面与播放器页通过 `geometryTransition` 共享元素 + `interpolatingSpring` 曲线。
- **智感握姿（底栏自适应）**：`barFloatingStyle({ adaptToHandedness: true })`，底部栏布局跟随握持姿态。
- **音乐库与歌曲页合并**：原「歌曲」+「音乐库」合并为单一音乐库页；导入功能迁移至音乐库页。
- **我的页上下滑动**：列表包裹 `Scroll` 容器，支持上下滚动浏览。
- **官方图标集成**：引入 13 个 HarmonyOS 官方图标（`ic_hm_*` 系列 SVG）。
- **开发者信息更新**：设置页「开发者」改为 **何宇翔**，点击跳转简历网页。
- **播放器入口下移**：迷你播放条下压并留出底部安全区。
- **歌单拖拽排序（FR-24）**：`ForEach.onMove` 长按拖动重排，持久化顺序。
- **C++ 解析器计划项落地**：MP3 支持 Xing/Info VBR 头精确时长；MP4 支持 64 位 `largesize` 与 v0/v1 `mvhd`；ID3v2 `enc==2`（UTF-16BE 无 BOM）按大端解析，中文不再乱码。

### 优化
- 各页面功能布局重新梳理，聚焦核心听歌体验。
- 迷你播放条底部边距与列表底部留白联动安全区（`@StorageProp('bottomHeight')`）。

### 修复
- 适配 API 24，`BottomTabBarStyle` 改用 `CustomBuilder` 自定义底部标签栏。
- 移除 6.1.1 SDK 未提供的 `motion` 主动监听，保留底栏 `adaptToHandedness` 自适应。
- `main_pages.json` 精简为仅注册 `Index`，其余页面经 `route_map.json` 推送。

### 移除
- 不可用的**本地扫描功能**（删除 `MusicScanner` 及相关调用）。
- 设置页中**不可调整的播放模式项**。
- 已删除 `Songs.ets` / `Moment.ets`，统一由 `LocalLibrary.ets` 承载。
- **下线发现页（FR-21）**：`Find.ets` 经复核为孤儿文件（未注册导航、无引用），已删除，零构建影响。

---

## v2.0（2026-07-05）

### 新增
- 迷你播放器：底部显示当前播放歌曲，点击进入播放器页面。
- 播放器页面入场 / 退场动画。
- 页面交互动效：列表项交错入场、按压缩放反馈、空状态图标脉冲、Tab 栏切换弹跳、头像呼吸灯、数字滚动统计。
- 音乐库统计面板（歌曲数 / 收藏数 / 最近播放数）。
- 分类文件夹彩色图标、歌曲序号显示、播放中歌曲高亮状态、扫描进度条。
- 关于页面功能特色展示。

### 优化
- 整体 UI 视觉升级：统一圆角风格、彩色图标容器、徽章式计数、分组标题设计。
- 各页面头部统一为 20px 粗体标题；返回按钮按压缩放效果；设置页分组优化。
- 版本号更新至 2.0。

### 修复
- C++ 编译 duplicate symbol 错误（拆分 `audio_metadata.h/.cpp`）。
- ArkTS `Object.assign` 受限问题（改用手动属性赋值）。
- `main_pages.json` 中非 `@Entry` 页面注册错误。

---

## v1.1.0

### 新增
- 基础音乐播放功能框架。
- 歌曲列表展示。
- 音乐文件扫描与导入。
- 收藏功能。
- 播放历史记录。
- 播放模式切换（顺序 / 列表循环 / 单曲循环）。
- 设置页面、关于页面。

### 技术
- ArkTS + ArkUI 开发。
- C++ Native 模块（音频元数据解析）。
- Navigation + NavPathStack 页面路由。
