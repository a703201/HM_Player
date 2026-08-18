# Lumio Music 安全与隐私合规审计报告

- **审计对象**：Lumio Music（HarmonyOS NEXT 离线本地音乐播放器）
- **工程路径**：`D:\Codes\Project\Lumio_Music`
- **审计角色**：鸿蒙安全合规专家「安守规」
- **审计范围**：`entry/src/main/module.json5`、权限最小化、隐私与数据安全、网络安全、上架合规风险
- **审计基线**：华为应用市场《审核指南》常见驳回项（隐私声明一致性、权限合理使用、无违规收集/出网）
- **结论状态**：🔴 **待整改（不合规）** —— 存在 P0 级隐私政策一致性硬伤，需修复后方可提交上架

---

## 一、项目事实快速核对

| 维度 | 结论 |
| --- | --- |
| 应用类型 | 纯本地离线播放器；歌曲来自 `DocumentViewPicker` + 沙箱 `filesDir/download`，无媒体库访问 |
| 媒体读取方式 | `DocumentViewPicker.select()` 用户主动选择 → 拷贝至沙箱 → `AVPlayer.fdSrc` 播放（**无 `READ/WRITE_MEDIA` 权限**） |
| 网络出网面 | 仅两处：① 局域网投播（Cast+/DLNA，系统 AVSession 框架）② 用户主动点击「关于开发者」打开外链 `https://www.a703201sworld.top/resume/` |
| 第三方 SDK | **无**。仅鸿蒙官方 Kit + 自研 `libnative_module.so`（音频元数据解析），未集成任何统计/广告/推送 SDK |
| 应用内 HTTP 客户端 | **无**（`grep` 全仓无 `createHttp/rcp/fetch/websocket` 调用）。故不存在自定义明文传输/证书校验隐患 |
| 数据存储 | `preferences`（明文）存于沙箱：`music_store`(歌曲元数据/收藏/历史/歌单)、`app_settings`(设置)、`myStore`(桌面卡片 formId/权限引导标记) |

---

## 二、权限清单（module.json5 声明 vs 实际使用）

| 权限 | 声明场景 | 代码实际用途 | 是否必要 | 替代 / 整改 |
| --- | --- | --- | --- | --- |
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | EntryAbility, `when:inuse` | `BackgroundUtil.startContinuousTask()` → `AUDIO_PLAYBACK` 后台续播 | ✅ 必要 | **保留** |
| `ohos.permission.INTERNET` | EntryAbility, `when:always` | ① 局域网投播设备发现/媒体流（AVSession cast）② 打开外链网页 | ✅ 必要 | **保留**；建议 `internet_reason` 文案补充「外链跳转」 |
| `ohos.permission.GET_NETWORK_INFO` | EntryAbility, `when:always` | **全仓无任何 `NetConnection`/`getNetCapabilities` 调用**（仅 `avSession.ConnectionState` 命中，与该权限无关） | ❌ 未使用 | **移除**（声明未使用权限属典型驳回项） |

**结论**：权限整体已较精简（无媒体/存储权限，符合离线播放器最小化原则），但 `GET_NETWORK_INFO` 属于“声明了却未使用”，须删除。

---

## 三、Findings 清单

| 编号 | 位置 | 问题 | 严重度 | 整改建议 |
| --- | --- | --- | --- | --- |
| F-01 | `pages/PrivacyPolicy.ets`（概述/收集的信息/权限说明/与第三方共享 各段） | **隐私政策与真实权限、真实网络行为严重不一致（上架一票否决级）**：<br>① 声称「绝不会把任何数据传输出你的手机」「无第三方、不向任何第三方传输数据」——但投播会把本地音频文件经局域网发往用户选定设备，且应用会打开第三方网站；<br>②「权限说明」列出「读取本地音频文件」「应用存储（文件/媒体）」等**实际并未申请**的权限，却**完全未提及真实申请的 `INTERNET`/网络权限与投播**；<br>③ 与 `string.json` 的 `perm_guide_message`（已说明“网络连接：发现局域网投播设备”）自相矛盾 | **P0** | 重写隐私政策：如实列出**实际申请的 3 个权限及其用途**；明确说明「投播会将当前歌曲经局域网传输至你选定的投播设备」「应用会跳转至开发者主页等第三方网页，该网页由第三方提供」；删除不存在的存储/音频权限表述；保持与 `perm_guide_message` 口径一致 |
| F-02 | `entry/src/main/module.json5:31-38` | `GET_NETWORK_INFO` 声明 `when:always`，但代码中无任何对应 API 调用 → 声明未使用权限 | **P1** | 从 `requestPermissions` 删除该条目；如后续确需主动探测网络状态再补回并配理由 |
| F-03 | `songdatacontroller/SongItemBuilder.ets:61,63`<br>`utils/AudioRendererController.ets:222,224`<br>`utils/MediaTools.ets:58`<br>`utils/CoverCache.ets:97,141`<br>`utils/EmbeddedLyricReader.ets:183`<br>`utils/AVSessionController.ets:482` | **用户媒体文件路径经 `%{public}` Logger 明文写入系统日志**：`Logger.info/error(...)` 底层使用 `hilog %{public}s`，release 构建下仍明文可见。路径含用户歌曲文件名（个人媒体信息）。团队已在 `AudioMetaReader.sanitize()` 修复同类问题（注释明确“避免完整沙箱路径含用户歌曲名明文进 hilog”），但上述位置未统一应用 | **P1** | 路径一律经 `AudioMetaReader.sanitize(src)` 仅保留文件名，或改用 `Logger.*Private()`（`%{private}s`，release 自动脱敏）；建立日志规范：禁止 `%{public}` 打印任何用户文件/媒体信息 |
| F-04 | `resources/base/element/string.json:20-22` | `internet_reason` 仅写「局域网投播」，未涵盖「外链跳转」这一 INTERNET 的次要用途（虽为 normal 权限自动授予，但理由应如实） | **P2** | 将 reason 改为：「用于局域网投播（Cast+/DLNA）设备发现与媒体流传输，以及跳转开发者主页等外链」 |
| F-05 | `entryability/EntryAbility.ets` + `utils/PreferencesUtil.ets`(`permGuideShown`) | 首次启动仅有「知道了」式告知（`perm_guide_message`），**无明确的隐私政策同意动作**（勾选/点击同意）。对离线低采集应用风险可控，但非强合规形态 | **P2** | 建议在首次启动弹窗中加入「查看隐私政策」入口与明确的同意确认；隐私政策页已在 `Settings` 路径可达 |
| F-06 | `services/MusicStore.ets`、`utils/SettingsStore.ets`、`utils/PreferencesUtil.ets` | 本地数据（歌曲元数据/收藏/历史/歌单、设置、formId）以 **`preferences` 明文 JSON** 存储，未加密。当前数据为低敏感本地数据、沙箱隔离，风险低 | **P2** | 如后续引入账号/跨设备同步/更敏感信息，改用 `Asset Store`（加密）或 `@ohos.data.preferences` + 应用级加密；当前阶段作为加固建议，非阻断项 |
| F-07 | `utils/NativeModule.ets:55-57` | `getDeviceInfo()`（采集 brand/osType）**已定义但全仓未调用**（死代码）。当前不采集；若将来启用须如实披露并评估必要性 | **P2** | 删除死代码；如确需设备信息用于投播兼容，须在隐私政策补充并遵循最小必要 |
| F-08 | `pages/LocalLibrary.ets:151-161` | DocumentViewPicker 拷贝失败回退时 `srcPath = uri`（持久化受限 picker URI）。picker URI 授权有时效，长期持久化可能失效导致后续播放/元数据读取失败（功能/数据可用性，沾边健壮性） | **P2** | 拷贝失败不应把受限 URI 写库；改为标记为导入失败并提示用户重新选择，或先拷贝到沙箱再存沙箱路径 |
| F-09 | `utils/AVSessionController.ets:428,429`（`castController as ESObject`）；`utils/AudioMeta.ets:58`（`raw as ESObject`，位于顶层 `@Concurrent parseMetaOnWorker`，非 `AudioMetaReader` 类内） | 为绕过编译器重载/类型限制使用 `as ESObject` 类型逃逸，削弱类型安全、可能掩盖运行时契约错误。本身非安全漏洞，但属风险审计可标注项（与架构盘点 `docs/review_architecture.md` §5 P1-3/P2-3 同源） | **P2** | 优先用官方类型或扩展接口声明；如确需逃逸，集中封装并补注释与运行时校验，避免散落多处 |
| F-10 | `utils/AudioRendererController.ets:154-159`（`SILENT_ID='silentId'` 写入 `PreferencesUtil` 的 formIds 数组）；被 `utils/AVSessionController.ets:620` `pushFormUpdate` 遍历时当作真实卡片 ID 调用 `formProvider.updateForm` | 把语义为"静音开关"的 magic 字符串塞进"桌面卡片 ID"集合，关注点耦合；当前 `'silentId'` 被遍历时误调用 `updateForm` 仅被 catch 吞掉（良性），但属数据模型污染，影响健壮性与可维护性 | **P2** | 静音标记独立成 Preferences 键（如 `silent_mode`），与 formIds 数组解耦，避免非卡片 ID 混入卡片 ID 集合 |

> 交叉核对备注：F-09 / F-10 由系统架构盘点（`docs/review_architecture.md` §5）提出，与安全/隐私域重叠，已纳入本审计。另：架构侧关于「权限最小化（3 项、无媒体库读写）」的结论与本文 §二 完全一致，互为印证。F-03 已覆盖架构侧指出的播放引擎日志路径（实际位于 `AudioRendererController.loadAndPlay()` 的 :222/:224，非 `play()` 字面位置）。

---

## 四、隐私与数据安全要点

- **数据本地化（合规亮点）**：播放历史、收藏、歌单、设置、听歌统计开关全部存于应用沙箱 `preferences`，与应用隔离，无云端、无账号体系。✅
- **隐私政策一致性（硬伤）**：见 F-01。华为审核强校验「隐私政策声明 vs APK 实际权限与行为」一致；当前政策既**漏报** INTERNET/投播/外链，又**错报**了不存在的存储/音频权限，属高危驳回点。🔴
- **特殊场景**：无儿童/未成年专项收集，无位置/通讯录/相册等敏感权限，无人脸识别等。无针对性特殊合规负担。
- **告知时机**：权限引导弹窗（`perm_guide_message`）在首次启动展示，但非「同意即授权」形态（F-05）。

---

## 五、数据安全项

| 项 | 现状 | 评估 |
| --- | --- | --- |
| 本地存储加密 | `preferences` 明文 | 低敏感本地数据，可接受；建议后续敏感数据走加密（F-06） |
| 传输安全 | 无应用层网络请求；投播由系统框架经局域网传输，外链由系统浏览器处理 | **无自定义 TLS/明文风险**（无 HTTP 客户端）。投播为端到端系统能力，无需应用侧证书配置 ✅ |
| 密钥管理 | 无密钥/令牌使用场景 | 不适用 |
| 日志脱敏 | 部分脱敏（AudioMetaReader），多处未脱敏（F-03） | 须统一脱敏 |
| 文件访问合规 | DocumentViewPicker 用户主动授权 + 沙箱拷贝，无媒体库权限 | ✅ 合规且最小化 |

---

## 六、网络安全项

- **INTERNET 用途**：仅「局域网投播」+「外链跳转」，**无远程音频流、无数据上报、无埋点**。AVPlayer 仅使用 `fdSrc`（本地文件描述符），`AudioRendererController.ets:221` 证实。
- **明文传输**：不存在（无应用发起的 HTTP/Socket）。
- **证书校验**：不适用（无自建网络通道）。
- **用户数据出网**：投播会将**当前播放的音频文件**经局域网发往用户选定的投播设备——这是唯一一次用户数据离机，且为用户主动触发、限定局域网。须在隐私政策如实说明（F-01）。

---

## 七、上架合规风险与整改清单（按优先级）

**P0（提交前必须修复，否则大概率驳回）**
1. [ ] **F-01** 重写 `PrivacyPolicy.ets`：如实列出 3 个真实权限及用途；说明投播与外链；删除不存在的存储/音频权限描述；与 `perm_guide_message` 口径一致。
2. [ ] 在华为 AppGallery Connect 同步维护与 App 内一致的隐私政策链接文本（上架必填项）。

**P1（强烈建议修复，影响审核通过率）**
3. [ ] **F-02** 删除 `module.json5` 中 `GET_NETWORK_INFO` 权限声明。
4. [ ] **F-03** 统一日志脱敏：上述 8 处文件/媒体路径改走 `sanitize()` 或 `Logger.*Private()`。

**P2（加固与最佳实践）**
5. [ ] **F-04** 补充 `internet_reason` 文案涵盖外链。
6. [ ] **F-05** 首次启动增加明确的隐私政策同意动作。
7. [ ] **F-06** 敏感本地数据后续改用加密存储。
8. [ ] **F-07** 清理 `getDeviceInfo()` 死代码。
9. [ ] **F-08** DocumentViewPicker 拷贝失败不持久化受限 URI。
10. [ ] 发布前将 `AppScope/app.json5` 的 `vendor: "example"` 改为真实主体（发布配置项，非安全但影响上架资料）。
11. [ ] **F-09** 收敛 `as ESObject` 类型逃逸（AVSessionController:428-429、AudioMeta.ets:58），补强类型安全与运行时契约可见性。
12. [ ] **F-10** 将静音标记 `SILENT_ID` 从 formIds 数组解耦，独立为 Preferences 键，避免非卡片 ID 混入卡片 ID 集合。

---

## 八、合规结论

> **状态：待整改（不合规） —— 暂不具备直接上架的安全合规条件。**

- ✅ **已做对的部分**：权限整体最小化（无媒体/存储/位置等敏感权限）；数据 100% 本地化、无第三方 SDK、无应用层网络请求与明文传输；文件访问走 DocumentViewPicker + 沙箱合规模式；后台播放权限用途真实。
- 🔴 **阻断项**：隐私政策（F-01）与真实权限/真实网络行为不一致，是华为应用市场最典型的驳回点之一，必须先行修复。
- 🟠 **高优先修复**：`GET_NETWORK_INFO` 声明未使用（F-02）、用户媒体路径明文日志（F-03）。
- 完成 P0 + P1 项后，项目即可达到「**合规、可上架**」状态；P2 项为加固建议，不阻断上架。

---

*审计说明：以上结论基于静态代码与配置核查（module.json5、ets 源码、`string.json`、`app.json5`）。华为审核标准以官方最新发布为准，隐私政策最终表述建议由法务/产品复核；动态行为（如投播实际握手流程）建议追加真机回归验证。本报告不提供任何绕过审核的手段，所有建议均为合规达成路径。*
