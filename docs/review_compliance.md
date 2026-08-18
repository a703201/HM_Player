# Lumio Music — 鸿蒙静态编码合规审查报告

- **审查对象**：`D:\Codes\Project\Lumio_Music`（HarmonyOS NEXT 工程，bundle `com.lumio.music`）
- **审查人**：审查严（鸿蒙应用审查专家）
- **审查范围**：`entry/src/main/ets` 下 59 个 `.ets` 源码 + `entry/src/main/cpp`（napi 注册）+ `entry/src/main/module.json5` + `build-profile.json5`
- **目标 API 版本**：`compileSdkVersion / compatibleSdkVersion / targetSdkVersion = 6.1.1(24)`（API 24）
- **审查依据**：团队红线规范 + 华为官方 HarmonyOS 开发文档（API 24）

---

## 一、严重度统计

| 严重度 | 数量 | 说明 |
|---|---|---|
| 🔴 P0（构建阻断 / 启动崩溃） | **0** | 全部编译器红线均合规，无阻断项 |
| 🟠 P1（高：核心功能运行期失效） | **1** | 后台播放模式声明缺失 |
| 🟡 P2（中：最佳实践 / 潜在运行风险） | **5** | 见下方 findings（含 2 项来自安全审计合并，F-09/F-10） |
| 🔵 INFO（低：说明 / 已核实无风险） | 4 | 见下方说明 |

> 结论：工程在**全部编译器红线与团队规范上均为合规**，无 P0。存在 1 个 P1（建议在发布前修复）与 5 个 P2（含 2 项与安全审计交叉合并的类型安全/数据建模项）。整体**可放行**，P1 建议修复后发布。

> **交叉来源说明**：F-09、F-10 由安全审计（`docs/review_security.md`）提出，属类型安全 / 数据建模范畴，经本审查逐行核实代码后**合并入本代码评审**单列跟踪，便于 devops 发布前统一处理。原安全报告仍为该两项安全语义的权威出处。

---

## 二、团队红线合规结论（逐条核对）

| # | 红线 | 结果 | 证据 |
|---|---|---|---|
| 1 | `build()`/`@Builder` 体首条语句不能是 `const/let` | ✅ 合规 | 全量扫描 59 文件，0 处违规 |
| 2 | `CustomDialogController`/`DialogAlignment`/`NavPathStack`/`NavDestinationContext` 为全局声明，勿从 `@kit.ArkUI` import（裸用） | ✅ 合规 | 0 处从 `@kit.ArkUI` 导入这些符号；均裸用 |
| 3 | `CustomDialogController` 禁 `@State`，只能普通成员 new | ✅ 合规 | `AddToPlaylistSheet.ets:39`、`Playlists.ets:54` 均为普通成员；`@State ... CustomDialogController` 0 命中 |
| 4 | `@Component`/`@CustomDialog` 普通 `get` 访问器会被变换器丢弃，须用普通方法（如 `getThemeColors()`） | ✅ 合规 | 全量 0 处 `get` 访问器；普遍采用 `getThemeColors()` 等方法（如 `AddToPlaylistSheet.ets:45`） |
| 5 | 禁裸 `console.*`/`hilog`，统一 `utils/Logger.ets` | ✅ 合规 | 仅 `Logger.ets` 内使用 `hilog`（合规 sink）；其余文件均经 `Logger.debug/info/warn/error(...args: string[])` |
| 6 | 解构声明 `const [x]=arr` / `const {a}=obj`（`arkts-no-destruct-decls`） | ✅ 合规 | 0 命中 |
| 7 | `any`/`unknown` 类型（`arkts-no-any-unknown`） | ✅ 合规 | 0 命中（唯一相近处为 `EntryAbility.ets:66` 的 `ESObject`，属 ArkTS 官方 interop 类型，允许） |
| 8 | 行内对象字面量当类型（`arkts-no-obj-literals-as-types`） | ✅ 合规 | 所有 `: { … }` 命中均为 UI 属性**值字面量**（如 `columns: { lg: … }`），非类型注解 |
| 9 | 路由参数用 `context.pathInfo.param as Object` + `typeof` 收窄 | ✅ 合规 | `SettingsCategory.ets:558`、`PlaylistDetail.ets:611` 均为 `as Object` 后 `typeof` 收窄 |
| 10 | `preferences.get()` 等可能抛异常需 `try/catch` | ✅ 合规 | `MusicStore.ets`、`SettingsStore.ets`、`PreferencesUtil.ets` 所有 `.get()/.put()/.getPreferences()` 均在 `try/catch` 内 |
| 11 | `@kit.*` 聚合 Kit 只有具名导出无 default，默认导入报 `'default' is not exported` | ✅ 合规 | 0 处 `@kit.*` 默认导入 |

---

## 三、按严重度排序的 Findings 表

| 编号 | 位置 | 问题 | 严重度 | 修复建议 |
|---|---|---|---|---|
| F-1 | `entry/src/main/module.json5`（EntryAbility ability 配置） | `backgroundTaskManager.startBackgroundRunning(ctx, AUDIO_PLAYBACK, …)`（`BackgroundUtil.ets:65`）**缺少对应的 `backgroundModes` 声明**。官方文档明确要求：长时任务除声明 `ohos.permission.KEEP_BACKGROUND_RUNNING` 权限外，还须在 ability 上配置 `"backgroundModes": ["audioPlayback"]`，否则 `startBackgroundRunning` 返回 `BusinessError`（长时任务不生效），**后台音频播放将被系统挂起**。当前 module.json5 仅有权限、无 `backgroundModes`。 | 🟠 **P1** | 在 `module.json5` 的 `abilities` → `EntryAbility` 对象中增加：`"backgroundModes": ["audioPlayback"]`。权限已具备，仅需补声明。 |
| F-2 | `entry/src/main/ets/lyric/LrcView.ets:112` | 在**字段初始化器**中调用 `this.getUIContext().createAnimator({…})`。字段初始化器在组件构造期执行，此刻组件尚未挂载到 UI 树，`getUIContext()` 可能返回未就绪/空的上下文，导致 animator 创建异常或空指针。 | 🟡 **P2** | 将 animator 的创建移到 `aboutToAppear()`（或首次使用时惰性创建）。注：`LrcView.ets:241` 已在方法中重建 animator，故实际风险有限，但字段初始化路径属不必要风险，建议移除。 |
| F-3 | `entry/src/main/ets/pages/LocalLibrary.ets:29`、`pages/SettingsCategory.ets:23`、`components/SongDetailSheet.ets:27` | 使用旧版文件 API `import fs from '@ohos.file.fs'`。工程其余处（如 `AudioRendererController.ets`、`AVSessionController.ets`、`CoverCache.ets`、`EmbeddedLyricReader.ets`）均使用当前 API `import { fileIo } from '@kit.CoreFileKit'`，`@ohos.file.fs` 为待废弃/迁移路径，存在一致性与未来弃用风险。 | 🟡 **P2** | 统一迁移为 `import { fileIo } from '@kit.CoreFileKit'`，并将 `fs.accessSync/statSync/openSync/...` 改为 `fileIo.*`。（`MusicStore.ets:23` 的 `import dataPreferences from '@ohos.data.preferences'` 为当前规范路径，无需改动。） |
| F-4 | `entry/src/main/ets/songdatacontroller/SongItemBuilder.ets:40`、`utils/AudioRendererController.ets:52`、`components/PlayerInfoComponent.ets:68` | 在字段初始化器中通过 `AppStorage.get('context')` 取全局 context（如 `private context = AppStorage.get('context')`）。当前因 `EntryAbility.onCreate` 先行 set 而可用，但属**隐式时序依赖**：若任何组件/单例在 set 前被构造，会静默得到 `undefined`。 | 🟡 **P2** | 改为显式注入：通过 `init(context)` / 构造函数参数传入，或在真正使用处惰性读取 `AppStorage.get('context')`，消除对初始化顺序的隐式依赖。 |
| F-09（←安全审计 F-09） | `entry/src/main/ets/utils/AVSessionController.ets:428-429`、`utils/AudioMeta.ets:58` | `as ESObject` 类型逃逸：`(this.castController as ESObject)?.off('playNext'/'playPrevious', …)`（绕过 `AVCastController.off` 重载不匹配）；`parseMetaOnWorker` 内 `const raw: ESObject = NativeUtils.getInstance().parseAudioMetadata(src)`（native 返回值未经结构化）。非安全漏洞，但削弱编译期类型安全、可能掩盖运行时契约错误。 | 🟡 **P2** | 收敛封装：① 为 native `parseAudioMetadata` 返回值定义具名接口并结构化解析，替代 `ESObject`；② `castController.off` 的 playNext/playPrevious 注销改为对具体回调签名的类型断言或封装方法，避免 `ESObject` 逃逸。 |
| F-10（←安全审计 F-10） | `entry/src/main/ets/utils/AudioRendererController.ets:154-159`、`utils/AVSessionController.ets:620` | 静音标记 `SILENT_ID='silentId'` 混入 `formIds` 数组（`setSilentModeAndMixWithOthers` 经 `addFormId/removeFormId` 写入），`pushFormUpdate` 遍历时误当卡片 ID 调 `formProvider.updateForm`（当前被 catch 吞掉，良性但属数据模型污染）。 | 🟡 **P2** | 将静音标记独立为单独的 Preferences 键（如 `KEY_SILENT_MODE`），不再与 `formIds` 共用数组；`pushFormUpdate` 即无需过滤/误调。 |

---

## 四、INFO / 已核实无风险项

- **I-1（native 模块注册一致）**：`NativeModule.ets:17` `import nativeModule from 'libnative_module.so'` ↔ `napi_init.cpp` 中 `nm_modname="native_module"`，导出 `add` / `parseAudioMetadata` / `getDeviceInfo`，名称一致；cpp 已对缺参（`argc<1`）、非法 UTF-8 做安全回退，无 P0/P1 风险。
- **I-2（自动报告误报澄清）**：内置 starter 报告提及 `BreakpointSystem.ets:62`、`ColorConversion.ets:122` 的 `componentSnapshot.get` 上下文告警——经全量 grep 确认 `componentSnapshot` **在工程中无任何实际使用**，属 starter 矩阵的误报，无需处理。
- **I-3（ESObject 允许）**：`EntryAbility.ets:66` 用 `const params: ESObject = JSON.parse(...)` 做 JSON interop。`ESObject` 是 ArkTS 官方提供的 `any/unknown` 替代类型，**不违反 `arkts-no-any-unknown`**，属合规用法，仅作说明。另见 P2 项 **F-09**：`AVSessionController.ets:428-429` 与 `AudioMeta.ets:58` 的 `as ESObject` 逃逸已单列跟踪（非违规，但建议收敛）。
- **I-4（当前 API 用法均为 API 24 合规）**：`avSession`（`@kit.AVSessionKit`）、`taskpool` + `@Concurrent` 顶层函数（已规避 10200014）、`getUIContext().getPromptAction()`（已替代 API 12 起废弃的全局 `promptAction`，见 `ControlAreaComponent.ets:80` 注释）、`this.getUIContext().animateTo()` 等均为当前推荐模式，无废弃/受限问题。

---

## 五、权限声明审查（module.json5）

| 权限 | 状态 | 结论 |
|---|---|---|
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | 已声明（reason + usedScene） | ✅ 合理（后台长时任务所需） |
| `ohos.permission.INTERNET` | 已声明 | ✅ 合理 |
| `ohos.permission.GET_NETWORK_INFO` | 已声明 | ✅ 合理 |
| `ohos.permission.READ_MEDIA` / `WRITE_MEDIA` | **已删除** | ✅ 合理且正确：音频导入走 `picker.DocumentViewPicker()`（`LocalLibrary.ets:131`）→ 复制到应用沙箱 `context.filesDir/download`（`LocalLibrary.ets:136-158`），不经系统媒体库扫描，故无需媒体库权限。 |

> 权限集**合理**。唯一关联问题即 F-1：权限已备，但 `EntryAbility` 缺 `backgroundModes: ["audioPlayback"]` 声明，导致长时任务实际无法生效。

---

## 六、API 版本兼容性（API 24）

- 全部使用的 API（`Navigation`/`NavPathStack`、`NavDestinationContext.onReady`、`UIContext.getUIContext()/getPromptAction()/animateTo()/createAnimator()`、`mediaquery`、`display`、`taskpool`、`avSession`、`@kit.CoreFileKit`）均在 API 11+ 引入，目标 API 24 完全覆盖，**无版本不足问题**。
- `compileSdkVersion` 在 `build-profile.json5` 中确为 `6.1.1(24)`（自动扫描器因解析路径不同显示 None，特此纠正）。

---

## 七、下一步建议

1. **发布前必做（P1）**：补 `module.json5` → `EntryAbility` 的 `"backgroundModes": ["audioPlayback"]`，恢复后台播放能力。
2. **建议整改（P2）**：F-2 字段初始化器中的 `getUIContext()`；F-3 统一文件 API 至 `@kit.CoreFileKit`；F-4 消除 `AppStorage.get('context')` 的隐式时序依赖。
3. **保持现状**：当前编译器红线、日志规范、路由参数收窄、偏好异常捕获、权限集均达标，建议纳入 CI 门禁（本审查脚本 `review.py` 可挂 `ERROR` 退出码）。
4. 将本次核实结论（如 `ESObject` 合规、`componentSnapshot` 未使用、`backgroundModes` 要求）回填团队规范/知识库，扩充后续审查覆盖率。
