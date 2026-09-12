# Lumio Music · UI 重设计 · 设计令牌层架构方案

> 版本：**v2.0**（Phase 1 架构基线 · 已并入 team-lead 裁决 + pm-planner 五轮复核 + 歌词对比度**按真实链路**定稿 + **分阶段落地参数** + R-24 强制口径 + **本轮 A/B 硬缺口与 `artworkScrim` 接口**）
> 作者：高见远（鸿蒙系统架构师）
> 适用范围：`entry/src/main/ets/**`（主应用 + Form 卡片）
> 运行环境：编译 SDK API 26 / 最低兼容 **API 24**（`ApiCompat.API_24`），单模块 `entry` + C++ NAPI
> 本阶段交付：**只产出文档与代码骨架，不改动任何现有 `.ets` 文件**

**v1.1 变更（并入 team-lead 裁决）**

| 裁决 | 变更 | 位置 |
|---|---|---|
| **AD-0（批准 + 收紧）** | 装饰性分类配色**全面取消**；新增三级色彩优先序「内容着色 > 语义着色 > 中性」与 `ArtworkTint` 封面取色能力 | §0.1 · **§2.12（新增）** · §4.4-C |
| **AD-1（批准）** | 圆角采用 4/8/12/16/24/999；补旧→新映射表；`DesignSystem.Radius` 以 re-export 指向同一常量 | §2.6 |
| **R-12（升级为强制约束）** | 新增「表面层级改造纪律」：整页提交、禁止跨页分批、逐页前后对照表、双截图验收 | **§4.6（新增）** |
| **AD-2（新增）** | 卡片**不能**访问主应用 `AppStorage`；确认卡片恒浅色是**活跃线上缺陷**；给出 `resolveIsDark()` + 三层兜底方案 | **§3.4（重写）** · §4.2-P5 · §6-R15/R19 |

**v1.2 变更（并入 pm-planner 复核意见）**

| 复核项 | 结论 | 位置 |
|---|---|---|
| 列表项复制处数 | pm-planner 说四处（补 `PlayHistory`）——**实测为 5 处**，`FolderBrowse.songRow()` @153 是双方都漏的第 5 处 | **§4.7（新增）** · §4.2-P3 · §4.5-18 |
| `SongRow` 差异化菜单 | 采纳"菜单项数组注入"，给出完整接口；`@Builder` 定义在组件内部以同时满足 `bindContextMenu` 与按行取参 | §4.7.1 |
| 对比度（pm-planner 实测 3.44/6.36） | **数据正确**；但不采纳 `secondaryLabelStrong`，改为**修令牌**——同时修正 v1.0 的**层级倒挂**（`labelTertiary` 5.99:1 比 `labelSecondary` 3.26:1 更醒目） | **§2.13（新增）** · §2.4 · §4.4-B · R-13 |
| P3 批次边界 | 确认一致；P3 由 3d 调整为 3.5d（第 5 处复制） | §4.2 · §4.6 |
| **§4.6 内部矛盾（自查发现）** | 原文"P3 一次性切换令牌值"与"整页提交"纪律冲突（改值=全局生效）。**修正为逐页「换指向」不改值**，R-12 由高降级为中 | §4.6 · R-12 |

**v1.3 变更（pm-planner 第二轮复核：`LrcView` 注入通道）**

| 项 | 结论 | 位置 |
|---|---|---|
| `onMedia*` 维度错误（**自查发现**） | `onMedia*` 挂在 `LumioSemantic` 上会被 `semanticOf(isDark)` 误选——深色主题用户播浅色封面时会出现白字不可读。**拆为独立维度**，新增 `onMediaOf(backgroundIsDark)` | **§2.4.1（新增）** · R-21 |
| `LrcView` Canvas 注入通道 | 现网 `@Prop @Watch` 骨架已正确；令牌解析只在 `applyColorScheme()`（冷路径），`drawContent()` 只读缓存字段 → **PanGesture 增量派发零影响** | **§3.5（新增）** · §4.4-E · R-20 |
| 动态封面对比度 | 实测固定蒙层不够：纯白封面 + 0.45 蒙层下白字仅 **3.36:1**。**改为自适应蒙层**（按封面亮度反解 alpha，clamp [0.35,0.65]），算法收敛到 `ArtworkTint` 一处 | §3.5.3 · R-18 |
| 新增阶段 | **P2c（歌词专项）**，0.5d | §4.2 |

**v1.4 变更（pm-planner 第三轮复核：半透明歌词的对比度计算错误）**

| 项 | 结论 | 位置 |
|---|---|---|
| **v1.3 §3.5.3 计算错误** | 我按"不透明白字"反解蒙层，但**非当前行是半透明（α=50.2%）**：加蒙层压暗背景同时也压暗文字，两者同向 → 对比度收益被吃掉。**"非当前行 4.5:1"在 clamp 内不可达**（蒙层 0.70 时也仅 3.50:1）。**本节已重写** | **§3.5.3（重写）** · R-18 |
| 结构性解法（新增） | 建议把半透明文字换成 **ArtworkTint 预合成的不透明色**（按目标对比度反解），对比度精确可控；蒙层已压平背景，视觉几乎无损。需 蓝绘心 拍板 A/B 方案 | §3.5.3 |
| 翻译行 14vp（v1.3 遗漏） | 明确小文本，**不适用 3:1 豁免**。蒙层 0.65 下：α=0.502→3.09:1（不达标）、α=0.65→4.04:1、α=0.84→5.51:1 | §3.5.3 |
| 分档验收口径 | 替换笼统的"歌词 ≥4.5:1"：当前行 4.5 / 非当前行 3.0 / 翻译当前行 4.5 / 翻译非当前行 3.0 | §3.5.3 · §7 |
| **对 pm-planner 的一处更正** | 「蒙层 ≥0.55 即可达 3:1」→ 实际需 **≥0.64**；且**起约束作用的是 clamp 上限 0.65 而非下限**（下限 0.35→0.50 对暗封面仅差 0.02:1） | §3.5.3 |

**v1.5 变更（team-lead 裁决 + 决定性发现：歌词是双层 alpha）**

| 项 | 结论 | 位置 |
|---|---|---|
| **A 案获批** | 采纳**预合成不透明色**。可达性已证明（单层不透明下 3:1→`#A9A9A9`、4.5:1→`#CFCFCF`，均可表达） | §3.5.3 |
| **🔴 决定性发现（v1.5）** | 现网歌词是 **`fillStyle` α × `globalAlpha` 双层叠加**（`LrcView.ets:637-695`）。我和 pm-planner **都只算了一层**。真实有效 α 仅 0.19~0.36 → 对比度 **1.2~2.5:1**，比 v1.4 结论再低一个档次 | §3.5.3 · **R-22** |
| 现网注释与实现背离 | `LrcView.ets:652` 注释「手动浏览模式：全部清晰」——实测浏览态未播放行仅 **1.94:1**（纯白）/ **2.45:1**（暗封面），**并不清晰** | §3.5.3 |
| v1.4 表一处数值更正 | 当前行在蒙层 0.35 下为 **2.44:1**（v1.4 误写 2.86:1）——即**现网连当前行都不达标** | §3.5.3 |
| 三态分档（team-lead 新增维度） | 增加**浏览态**（`isUserScrolling`，代码已有此能力但实现错了）：播放态 当前行 4.5 / 非当前行 3.0；**浏览态全部 4.5** | §3.5.3 |
| 不可协商参数 | 蒙层 clamp **上限 0.65 不得下调**；下限是否提 0.50 **只按视觉理由，不得挂对比度名义** | §3.5.3 |
| 新增风险 | **R-22** 歌词双层 alpha（高）；R-18 更新为已定方案 | §6 |

**v1.6 变更（team-lead 质疑：背景不是原始封面——质疑成立，我的模型错了）**

| 项 | 结论 | 位置 |
|---|---|---|
| **🔴 v1.5 模型错误** | 我把歌词背景当成**原始封面亮度**，忽略了 `PlayerInfoComponent` 的三段叠加：`Image@opacity .5 + blur` → `linearGradient(buildGradientColors 压暗 .28/.42/.62)@opacity .65` → `rgba(0,0,0,0.35)`。`LyricsComponent` 确在该 `Stack()` 内（L165/214/237）；`lyricBgDark` 恒 `true`（L351）**强制压暗** | §3.5.3 |
| **撤回错误结论** | ❌ **撤回"现网连当前行都只有 2.44:1"**。按真实链路当前行 **4.13~19.74:1**，基本达标（唯一缺口 4.13:1：纯白封面+白基底+lifted 位）。该结论不得作为后续决策依据 | §3.5.3 |
| **R-22 保留且仍是 A 案唯一理由** | 双层 alpha 在**真实链路上依然成立**：播放态未播放 1.39~1.79:1、浏览态 1.59~2.37:1。机理是半透明文字**永远向背景靠拢**，对比度被结构性压缩，**与背景明暗无关** | §3.5.3 · R-22 |
| **蒙层参数废止重定** | ❌ **废止"上限 0.65 不可协商"**（它是在错误模型上反解的，会把已压暗画面再压成一团黑）。✅ 改为 **clamp `[0.0, 0.25]`、默认 ≈0.10**；现网固定 0.35 建议改自适应 | §3.5.3 · R-23 |
| 新增风险 | **R-23**：在错误模型上反解参数会得出过压暗结论 | §6 |

**v1.7 变更（pm-planner 第四轮：按 85% 白字反解 + 播放态 alpha 复算）**

| 项 | 结论 | 位置 |
|---|---|---|
| **蒙层约束方更正** | 约束方不是"当前行（不透明）"而是**"浏览态 85% 白字"**：最坏底色需 scrim **0.159**（工程取 0.18），而非 v1.6 的 0.049。**采纳** | §3.5.3 |
| **播放态 alpha 修正（该数 pm-planner 有误）** | pm-planner 称 0.60→2.88:1 需提到 0.65。复算：scrim 0.18 下 0.55→2.95 ❌ / **0.60→3.20 ✅** / 0.65→3.46 ✅。**0.60 已达标，取 0.60**（alpha 越低聚焦层次越强，不必上调） | §3.5.3 |
| 新增验收硬要求 | 对比度**必须在渐变 `lifted` 位（最亮）取样**：深位 8.63:1 / base 4.63:1 / **lifted 3.47:1** ❌。在深位取样会误判为全部达标 | §3.5.3 · §3.5.4 |
| 确认 pm-planner 的 `globalAlpha` 论证 | `globalAlpha` 上限 1，基底 fill 仅 0.502，要达 0.85 需 1.69 > 1 → **必须改 `fillStyle` 本身**，`applyColorScheme()` 输出两套 fill 色。成立 | §3.5.3 |

**v1.8 变更（team-lead 冲突裁决：分阶段落地参数 + blur 判据 + 措辞修正）**

| 项 | 结论 | 位置 |
|---|---|---|
| **终态不变，本轮降级实现** | `ArtworkTint` 预合成 + `globalAlpha` 固定 1.0 是**终态**（M3）。`ArtworkTint` 当前不存在，**本轮缺陷修复用不上**，降级为「颜色 α=1.0 + 弱化只由 `globalAlpha` 表达（0.65 / 0.85 / 1.0）」。**二者都满足"alpha 单一来源"**，不产生二次衰减 | §3.5.5 |
| **grep 卡点措辞收窄** | 禁的是**颜色字面量里的 alpha**（`#80ffffff`），**`globalAlpha` 数值常量不在禁止之列**。改为「`fillStyle` 赋值中不得出现带 alpha 的颜色字面量」，避免误伤 | §3.5.4 |
| **alpha 分阶段取值** | **本轮（无蒙层）0.65**；**M3（自适应蒙层落地后）可下调至 0.60**。两值并存并标注生效阶段，代码注释须写明 | §3.5.3 · §3.5.5 |
| **blur 半径下调（裁决采纳，判据修正）** | 现网 `blur(5px)` 对 `mNormalTextSize≈15vp` 是字号的 **33%**，属"抹除"而非"柔化"。**下调至 2px / 1.5px**。但**比例判据的参照系需修正**：主流音乐 App 歌词**根本不用模糊**（参照是 0 而非 13%），取舍见 §3.5.6 | §3.5.6 |
| **新增风险 R-24** | 模糊会削平细笔画峰值亮度，**理论色值达标 ≠ 渲染后达标**。故验收必须**截图取样实测**，不得只按色值计算 | §3.5.6 · §6 |

**v1.9 变更（team-lead 三项回复：0.65 裁定 + R-24 升级 + 主观判读）**

| 项 | 结论 | 位置 |
|---|---|---|
| **0.65 裁定：维持不上调** | 最坏格 2.80:1 **接受降级**。理由：① 现网 1.39:1 → 2.80:1 已一个量级；② 为极端格加码正是「再提一点就能解决」陷阱，**病根在缺蒙层不在参数**；③ 0.70 逼近当前行 1.0，削弱聚焦层次。**严禁继续上调** | §3.5.3 |
| **代码注释扩为两条** | `0.65` 须写明：①「M3 落地蒙层后可下调至 0.60」；②「**禁止为使其达标继续上调 alpha，正解是 M3 自适应蒙层**」 | §3.5.3 |
| **R-24 升级高优 + 强制口径** | 复核**必须基于实际渲染截图取样**；本轮无条件实测时**须写明「未做实测、需 M3/QA 补做」，严禁编数字**。中 → **高** | §3.5.4 · §6 |
| **新增 M3 验收第 ⑦ 条** | **真机主观可读性确认**：3 张极端封面 × 2 态、正常室内光、**非作者本人**判读指定行、能正确读出即通过。**数值达标是必要非充分条件** | §3.5.4 |
| **§3.5.6 闸门条款锁定** | 「模糊若仍拖可读性 → 归零改用不透明度 + 字重差，而非在 1~2px 间微调」保留为闸门；并补记前提性疏漏：**我们连"要不要模糊"都没验证过就默认它该存在** | §3.5.6 |

**v2.0 变更（pm-planner 第五轮：字号基准更正 + 数值复算 + 本轮 A/B 硬缺口）**

| 项 | 结论 | 位置 |
|---|---|---|
| **🔴 字号基准更正** | `mNormalTextSize` 实测 **`LrcView.ets:153 = 18`**（当前行 22，L165）。此前 15vp 是**记忆值非实测**，已作废。blur 占比重算：5px = **27.8%**（原记 33%）、2px = 11.1%、1.5px = 8.3% | §3.5.6 |
| **🔴 两处数值更正（pm-planner 指出，脚本复算确认）** | 本轮（bg=125）下：0.65 → **2.71:1**（原记 2.80 ❌）；0.70 → **2.89:1**（原记 3.07 ❌）。**"0.70 即可达标"作废**，实测需 **0.7303** | §3.5.3 |
| **措辞更正：本轮不是"无蒙层"** | 本轮**沿用现网固定 `rgba(0,0,0,0.35)`**（bg=125 已含它），只是不做自适应。后续 0.16 / 0.18 均为**叠加其上的增量**，非总蒙层 | §3.5.3 |
| **本轮硬缺口 + A/B 方案** | 最坏底色：播放态 3:1 需 α=0.730；**浏览态 4.5:1 数学不可达**（不透明上限 4.116）。**架构侧推荐 A：加常量蒙层 0.16** → 0.65→3.367 ✅ / 0.85→4.501 ✅ | **§3.5.7（新增）** |
| **`artworkScrim` 接口定型** | 签名 `artworkScrim(liftedBgLuma: number): number` 本轮返回常量、M3 换反解函数体，**签名/入参语义/返回区间三者不变**，调用方零改动 | §3.5.7 |

---

## 0. 阅读指引与规范裁决

### 0.1 本文与既有文档的关系

仓库里已经存在两份**互相冲突**的设计文档，这是本次重设计最大的隐性风险，必须先裁决：

| 文档 | 主张 | 冲突点 |
|---|---|---|
| `docs/UI设计系统.md` | Apple 语义色（`AppleTokens`）为真源，`ThemeManager.apple()` 取色，`Glass`/`Radius`/`Motion` 均为令牌 | 与本文目标一致 ✅ |
| `docs/design_tokens.md` | **§0.1 主张 `ThemeManager.lightColors/darkColors`（7 字段）为唯一权威源**；**§3.3 把 `#34C759 #FF9500 #007AFF #5E5CE6 #FFCC00 #5856D6` 列为"全仓任何位置不得出现"的红线色** | ❌ 与 Apple 语义色体系正面冲突 |
| `entry/.../DesignSystem.ets` | 已实现 Apple 语义色，但只有 5 个文件引用 | 真源"建立了但没接通" |

**裁决（架构决策 AD-0，team-lead 已批准并收紧）**：

1. **两份文档都被新的三层令牌模型取代**。本文定义的 `tokens/` 层是**唯一真源（SSOT）**，`docs/design_tokens.md` §0.1 的"以 7 字段 ColorTokens 为权威源"作废。
2. **"HIG 调色板禁令"不删除，而是升级为一条可执行的架构约束**，而不是"色值黑名单"：
   - 组件**只能引用 Semantic / Component 层，永远不能引用 Primitive 层**（这是结构性约束，可用 code-linter 规则机械检查）。
   - `systemGreen/Orange/Blue…` 在 Primitive 层保留（它们是色板事实），但在 Semantic 层**只允许以 `success / warning / danger / info` 语义身份出现**。
   - 因此："成功/警告/危险/信息"的语义用法 → **允许**；装饰性用法 → **禁止**。
3. **收紧项：装饰性分类配色全面取消**（`Mine.ets` 给每个菜单项染不同色的做法，即收藏 `#FA2759` / 歌单 `#5856D6` / 历史 `#FF9500` / 文件夹 `#007AFF`）。这是全仓最不 Apple 的部分。Apple Music 的原则是**色彩来自内容本身**，取代方案为三级优先序，详见 **§2.12「色彩来源策略」**：
   > **内容着色（封面取色） > 语义着色（success/warning/danger/info/brand） > 中性（fill + 单色图标）**
4. `docs/design_tokens.md` 中仍然有效的部分（尺度命名 `space_*` / `radius_*`、卡片进程主题链路、F-03 资源镜像缺口）**被本文吸收并沿用**，避免产生第三套命名。

**据此，Semantic 层状态色保留四色，但使用范围被 §2.12 的优先序严格约束**；装饰性用途一律走中性或内容取色，不占用状态色。

### 0.2 关键术语

- **Primitive（原始层）**：只存值、不表达用途的色板。
- **Semantic（语义层）**：表达用途（"卡片底"、"次级文字"、"危险操作"），分浅/深两套。
- **Component（组件层）**：绑定到具体组件形态的令牌包与共享构建函数。
- **Scale / Effect / Motion**：非颜色的尺度、特效、动效令牌。

---

## 1. 现状问题诊断

### 1.1 实测数据（2026-09 全仓扫描）

| 指标 | 实测值 |
|---|---|
| `.ets` 文件总数 | 82 |
| 含硬编码色值（hex / rgba）的文件数 | 24 |
| 业务侧硬编码色值处数（剔除 `DesignSystem.ets` 56 处、`ThemeManager.ets` 18 处令牌定义） | **≈ 160 处** |
| 其中品牌色系（`#FA2759` + `rgba(250,39,89,*)`） | **≈ 67 处**，分布 17 个文件 |
| `DesignSystem` 被 import 的文件数 | **5**（`CoverImageView` / `ControlAreaComponent` / `Layout` / `PlayerPage` / `ThemeManager`） |
| `ThemeManager.getThemeColors()` / `lightColors` / `darkColors` 被引用文件数 | **22** |
| `resources/dark/element/color.json` 条目数 | **1**（`base` 未镜像，深色下组件资源回退浅色） |
| 重复定义的品牌色常量 | 2（`Layout.ets:32` 与 `LocalLibrary.ets:35` 各一个 `const ACCENT`） |

### 1.2 双轨分裂的具体代价

**代价一：Apple 语义色形同虚设。**
`AppleTokens` 有 26 个字段、`DesignSystem` 有完整的 `Radius`/`Motion`/`Glass`，但只有 5 个文件用。也就是说：**架构上已经付了令牌层的成本，却没收到任何收益**。每一次新页面开发，开发者面对 `ThemeManager`（7 字段，够用、有 22 处先例）和 `DesignSystem`（26 字段，只有 5 处先例），**默认会选前者**——这不是纪律问题，是**默认路径设计失败**。

**代价二：硬编码 hex 是"语义丢失"，不只是"重复"。**
以 `rgba(250, 39, 89, 0.05)`（选中行底）为例，它在 `LocalLibrary.ets:425`、`Favorites.ets:241` 出现，`rgba(250,39,89,0.08)` 在 `LocalLibrary.ets:581` 出现，`0.10` 在 6 个文件出现。这三个值**语义相同（品牌色弱化底）却取值不同**，且没有任何一处说明"为什么是 0.05 而不是 0.10"。当深色模式需要把它提到 0.14 时，**没有人知道该改哪几处**。

**代价三：状态色语义漂移。**
`PlayHistory.ets:188/200/231/291/292` 用橙色 `#FF9500` 表示"正在播放"，而其他所有页面用品牌粉 `#FA2759`。同一状态两种表达，用户认知分裂；而这条裂缝在代码里只是"某个文件里写了另一个 hex"，**没有任何机制能发现它**。

**代价四：跨进程无法复用。**
`WidgetCard.ets:90-106` 因为 Form 卡片进程不能 import `ThemeManager`（后者依赖 `window` / Preferences），只能**在卡片内自建一份取色集并手抄 8 个 hex**，注释里写着"镜像 design_tokens.md §1"。这是典型的**复制式真源**——主应用改色，卡片不会跟着改，且无编译期报错。

**代价五：动效降级无法统一。**
`SettingsStore.getReduceMotion()` 在 8 处被直接调用，每处各写各的降级（`? 0 : index*50`、`? 0 : index*40`、`if (!reduce) setInterval`）。`DesignSystem.Motion` 里没有一个字段知道"降低动态效果"的存在，**动效令牌与可达性开关完全脱钩**。

### 1.3 为什么"只改颜色不改结构"一定会失败

| 只改颜色的做法 | 失败原因 |
|---|---|
| 把 160 处 hex 逐个替换成 `AppleTokens` | 组件拿不到响应式令牌（见 §3），要么用 `get` 访问器崩溃，要么用 `getColors()` 主题切换不刷新；**改完立刻出现"切主题要重启才生效"的回归** |
| 给 `ColorTokens` 加 `accentSoft` 等字段 | 字段数从 7 涨到 20+，但仍然是**扁平命名**，`cardBg` 到底是"分组内卡片"还是"浮层卡片"没有层级表达，深色下"白卡片配灰底"的 Apple 表面层级无法落地 |
| 统一替换 `Radius.sm/md/lg` | `DesignSystem` 的 `10/14/20` 与 `design_tokens.md` 的 `8/12/16/24` 与 `float.json` 的 `cover_radius(16)` 三套并存，**换哪套都会与另外两套打架** |
| 把 HIG 调色板色值全局删掉 | 删除操作只能靠人肉 grep；今天删完，明天新代码再写回来，**没有结构性约束阻止** |

**结论**：问题不是"颜色值不对"，而是**令牌层没有成为唯一真源，且没有强制引用路径**。因此必须先建结构（三层 + 门面 + 零 import 不变量），再迁值。

---

## 2. 目标令牌层架构

### 2.1 分层模型

```
┌───────────────────────────────────────────────────────────────┐
│ L3  Component 组件层    LumioComponents.ets（导出 @Builder）    │
│     SongRow / PrimaryButton / Badge / SectionHeader / Card      │
│     └─ 只消费 L2，不允许出现任何 hex                             │
├───────────────────────────────────────────────────────────────┤
│ L2  Semantic 语义层     LumioColor.ets / LumioScale.ets         │
│     background / surfaceRaised / label / separator / accent …    │
│     └─ 浅/深两套常量，由 isDark 选择；表达"用途"不是"颜色"        │
├───────────────────────────────────────────────────────────────┤
│ L1  Primitive 原始层    LumioPalette（同文件内，仅 L2 可见）      │
│     gray50…gray950 / pink500 / blue / green / orange / red …     │
│     └─ 纯值，禁止 L3 直接引用（结构性禁令，可 lint 检查）         │
└───────────────────────────────────────────────────────────────┘
        ▲ 并列：LumioEffect（阴影/毛玻璃）· LumioMotion（弹簧/时长）
```

**命名规范**

| 层 | 命名 | 示例 | 禁止 |
|---|---|---|---|
| Primitive | `色相+明度` | `pink500`、`gray900`、`blueLight` | 不得表达用途 |
| Semantic | `类别+角色` 小驼峰 | `surfaceRaised`、`labelSecondary`、`fillAccentSoft` | 不得出现色相名（无 `pinkBg`） |
| Component | `组件+部位` | `songRowTitle`、`cardSurface` | 不得出现 hex |
| Scale | 语义尺寸名 | `space.base`、`radius.md`、`type.headline` | 不得用 `space_16` 这类带数字名 |

**依赖方向（不变量）**：`Component → Semantic → Primitive`，严格单向。反向依赖（Semantic 引用 Component）或跨层引用（Component 直接引用 Primitive）视为架构违规。

### 2.2 目录结构

```
entry/src/main/ets/
└── tokens/                          ← 新增，本阶段只产出骨架
    ├── LumioColor.ets               ← L1 Primitive + L2 Semantic（零 import）
    ├── LumioScale.ets               ← 间距 / 圆角 / 排版（零 import）
    ├── LumioEffect.ets              ← 海拔阴影 / 毛玻璃（零 import）
    ├── LumioMotionSpec.ets          ← 弹簧与时长纯数值（零 import）
    ├── LumioMotion.ets              ← 曲线工厂（import { curves } from '@kit.ArkUI'）
    ├── LumioTheme.ets               ← 门面：按 isDark/breakpoint/reduceMotion 解析（主应用专用）
    └── LumioComponents.ets          ← L3：导出 @Builder（后续阶段）

entry/src/main/ets/utils/            ← 新增两个「与令牌相关但依赖 @kit」的助手（不进 tokens/）
    ├── ThemeResolve.ets             ← resolveIsDark()：isDark 判定唯一实现（AD-2，§3.4.3）
    └── ArtworkTint.ets              ← 封面取色能力（AD-0 收紧项，§2.12.2）
```

> **为何这两个不放进 `tokens/`**：它们分别 import `@kit.AbilityKit` 与 `@kit.ArkGraphics2D`，会破坏"零 import"不变量、导致卡片进程不可用。**依赖 @kit 的一律不得进 `tokens/`**——这是 §2.2 不变量表的延伸。

**模块不变量（必须写进 code-linter / Code Review 检查表）**

| 模块 | 不变量 |
|---|---|
| `LumioColor.ets` | **零 import**。不得引用 `@kit.*`、`AppStorage`、`Preferences`、`Logger`。→ 因此 Form 卡片进程可安全 import |
| `LumioScale.ets` | **零 import** |
| `LumioEffect.ets` | **零 import** |
| `LumioMotionSpec.ets` | **零 import**（只存数字，卡片可读） |
| `LumioMotion.ets` | 唯一允许 `import { curves } from '@kit.ArkUI'` 的令牌文件；**不得** import `SettingsStore`（降级布尔由调用方传入） |
| `LumioTheme.ets` | 主应用专用，**禁止**被 `widget/**` 引用 |

### 2.3 模块依赖图

```
        AppStorage: 'isDark' / 'currentBreakpoint' / 'systemIsDark'
                              │
                              │ @StorageProp（唯一响应式入口）
                              ▼
   ┌────────────────────────────────────────────────────────┐
   │  业务页面 / 组件（pages/** components/** lyric/**）      │
   │   · 声明 @StorageProp('isDark')                         │
   │   · 用「普通方法」取令牌，绝不用 get 访问器               │
   └───────────────┬────────────────────────┬───────────────┘
                   │ private c() / t() / sp()│
                   ▼                         │ import（只读常量）
        ┌──────────────────────┐             │
        │  LumioTheme（门面）   │             │
        │  semantic/space/type │             │
        │  glass/elevation     │             │
        │  motion()（读设置）   │             │
        └──────┬───────────────┘             │
               │                             │
       ┌───────┼─────────┬──────────┐        │
       ▼       ▼         ▼          ▼        ▼
  LumioColor LumioScale LumioEffect LumioMotion  SettingsStore
   (零import) (零import)  (零import)  (curves)    (reduceMotion)
       ▲         ▲          ▲
       └─────────┴──────────┘
                 │
        WidgetCard（Form 进程）
        ★ 只允许引这三个「零 import」模块
```

### 2.4 Primitive + Semantic 代码骨架

> 已规避红线：**3**（全具名 interface，无 `any`/`unknown`、无解构、无行内对象字面量注解）；**7**（Apache-2.0 头）。

```arkts
/*
 * Copyright 2026 何宇翔
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * 令牌层 L1（Primitive 原始色板）+ L2（Semantic 语义色）。
 *
 * 不变量：本文件「零 import」——不依赖 @kit.* / AppStorage / Preferences。
 *        因此主应用、Service 与 Form 卡片进程（WidgetCard）均可直接引用。
 */

// ===================== L1：Primitive 原始色板 =====================
// 只存值、不表达用途。组件层（L3）禁止直接引用本接口。

export interface LumioPalette {
  white: string;
  black: string;
  gray50: string;
  gray100: string;
  gray200: string;
  gray300: string;
  gray400: string;
  gray500: string;
  gray600: string;
  gray700: string;
  gray800: string;
  gray900: string;
  gray950: string;
  pink500: string;      // 品牌 #FA2759
  pink600: string;      // 按压态
  pink400: string;      // 深色下的提亮变体（可选）
  blue: string;
  blueDark: string;
  green: string;
  greenDark: string;
  orange: string;
  orangeDark: string;
  red: string;
  redDark: string;
  purple: string;
  purpleDark: string;
  indigo: string;
  yellow: string;
}

export const LUMIO_PALETTE: LumioPalette = {
  white: '#FFFFFF',
  black: '#000000',
  gray50: '#F2F2F7',
  gray100: '#E5E5EA',
  gray200: '#D1D1D6',
  gray300: '#C7C7CC',
  gray400: '#AEAEB2',
  gray500: '#8E8E93',
  gray600: '#636366',
  gray700: '#48484A',
  gray800: '#3A3A3C',
  gray900: '#2C2C2E',
  gray950: '#1C1C1E',
  pink500: '#FA2759',
  pink600: '#E01F4C',
  pink400: '#FF4C74',
  blue: '#007AFF',
  blueDark: '#0A84FF',
  green: '#34C759',
  greenDark: '#30D158',
  orange: '#FF9500',
  orangeDark: '#FF9F0A',
  red: '#FF3B30',
  redDark: '#FF453A',
  purple: '#5856D6',
  purpleDark: '#BF5AF2',
  indigo: '#5E5CE6',
  yellow: '#FFCC00'
};

// ===================== L2：Semantic 语义色 =====================
// 表达「用途」，浅/深两套。组件只允许引用本接口。

export interface LumioSemantic {
  // —— 表面 / 背景 ——
  background: string;              // 页面底
  backgroundSecondary: string;     // 次级底（分组头、带状区）
  backgroundTertiary: string;      // 三级底（输入框、内嵌槽）
  surfaceRaised: string;           // 卡片 / 面板 / 列表项底（= 旧 cardBg）
  surfaceGrouped: string;          // 分组容器底
  surfaceGroupedContent: string;   // 分组内卡片底
  surfaceOverlay: string;          // Sheet / Dialog 不透明底
  scrim: string;                   // 半模态 / 遮罩蒙层
  inverseSurface: string;          // 反色底（Toast / Tooltip）

  // —— 填充（控件叠加，营造景深）——
  fillPrimary: string;
  fillSecondary: string;
  fillTertiary: string;            // 按压高亮（原 rgba(120,120,128,0.12)）
  fillQuaternary: string;
  fillAccentSubtle: string;        // 选中行底      （原 0.05 / 0.08）
  fillAccentSoft: string;          // 徽章 / 标签底  （原 0.10）
  fillAccentMuted: string;         // 强调块 / 进度  （原 0.30）
  fillSuccessSoft: string;
  fillWarningSoft: string;
  fillDangerSoft: string;
  fillInfoSoft: string;

  // —— 文本 ——
  label: string;
  labelSecondary: string;
  labelTertiary: string;
  labelQuaternary: string;         // 占位 / 禁用
  labelOnAccent: string;           // 品牌底上的文字
  labelInverse: string;

  // —— 描边 / 分隔 ——
  separator: string;
  separatorOpaque: string;
  borderSubtle: string;            // 深色下替代阴影的 hairline
  borderAccent: string;

  // —— 品牌 ——
  accent: string;
  accentPressed: string;
  accentDisabled: string;
  onAccent: string;

  // —— 状态（唯一允许使用系统色相的语义出口）——
  success: string;
  warning: string;
  danger: string;
  info: string;

  // —— 媒体（封面 / 歌词上层，语义为「叠在图片上」，非主题色）——
  onMediaPrimary: string;
  onMediaSecondary: string;
  onMediaTertiary: string;
  onMediaEmphasis: string;
  onMediaControlBg: string;        // 封面上的控件底（原 rgba(255,255,255,0.16)）
  onMediaScrim: string;
}

export const LIGHT_SEMANTIC: LumioSemantic = {
  background: '#FFFFFF',
  backgroundSecondary: '#F2F2F7',
  backgroundTertiary: '#FFFFFF',
  surfaceRaised: '#F2F2F7',
  surfaceGrouped: '#F2F2F7',
  surfaceGroupedContent: '#FFFFFF',
  surfaceOverlay: '#FFFFFF',
  scrim: 'rgba(0, 0, 0, 0.20)',
  inverseSurface: '#1C1C1E',

  fillPrimary: 'rgba(120, 120, 128, 0.20)',
  fillSecondary: 'rgba(120, 120, 128, 0.16)',
  fillTertiary: 'rgba(118, 118, 128, 0.12)',
  fillQuaternary: 'rgba(116, 116, 128, 0.08)',
  fillAccentSubtle: 'rgba(250, 39, 89, 0.05)',
  fillAccentSoft: 'rgba(250, 39, 89, 0.10)',
  fillAccentMuted: 'rgba(250, 39, 89, 0.30)',
  fillSuccessSoft: 'rgba(52, 199, 89, 0.12)',
  fillWarningSoft: 'rgba(255, 149, 0, 0.12)',
  fillDangerSoft: 'rgba(255, 59, 48, 0.12)',
  fillInfoSoft: 'rgba(0, 122, 255, 0.12)',

  label: '#1C1C1E',              // 16.9:1
  labelSecondary: '#6E6E73',     //  5.07:1  ← AA 达标（P4 起生效，见 §2.13）
  labelTertiary: '#8E8E93',      //  3.26:1  弱化信息，非正文
  labelQuaternary: 'rgba(60, 60, 67, 0.18)',  // 占位符
  labelOnAccent: '#FFFFFF',
  labelInverse: '#FFFFFF',

  separator: 'rgba(60, 60, 67, 0.29)',
  separatorOpaque: '#C6C6C8',
  borderSubtle: 'rgba(0, 0, 0, 0.06)',
  borderAccent: 'rgba(250, 39, 89, 0.20)',

  accent: '#FA2759',
  accentPressed: '#E01F4C',
  accentDisabled: 'rgba(250, 39, 89, 0.35)',
  onAccent: '#FFFFFF',

  success: '#34C759',
  warning: '#FF9500',
  danger: '#FF3B30',
  info: '#007AFF',

  onMediaPrimary: 'rgba(0, 0, 0, 0.85)',
  onMediaSecondary: 'rgba(0, 0, 0, 0.30)',
  onMediaTertiary: 'rgba(0, 0, 0, 0.20)',
  onMediaEmphasis: 'rgba(0, 0, 0, 0.60)',
  onMediaControlBg: 'rgba(255, 255, 255, 0.16)',
  onMediaScrim: 'rgba(255, 255, 255, 0.35)'
};

export const DARK_SEMANTIC: LumioSemantic = {
  background: '#000000',
  backgroundSecondary: '#1C1C1E',
  backgroundTertiary: '#2C2C2E',
  surfaceRaised: '#1C1C1E',
  surfaceGrouped: '#000000',
  surfaceGroupedContent: '#1C1C1E',
  surfaceOverlay: '#1C1C1E',
  scrim: 'rgba(0, 0, 0, 0.45)',
  inverseSurface: '#F2F2F7',

  fillPrimary: 'rgba(120, 120, 128, 0.36)',
  fillSecondary: 'rgba(120, 120, 128, 0.32)',
  fillTertiary: 'rgba(118, 118, 128, 0.24)',
  fillQuaternary: 'rgba(118, 118, 128, 0.18)',
  fillAccentSubtle: 'rgba(250, 39, 89, 0.14)',
  fillAccentSoft: 'rgba(250, 39, 89, 0.22)',
  fillAccentMuted: 'rgba(250, 39, 89, 0.38)',
  fillSuccessSoft: 'rgba(48, 209, 88, 0.22)',
  fillWarningSoft: 'rgba(255, 159, 10, 0.22)',
  fillDangerSoft: 'rgba(255, 69, 58, 0.22)',
  fillInfoSoft: 'rgba(10, 132, 255, 0.22)',

  label: '#FFFFFF',              // 21.0:1
  labelSecondary: '#98989F',     //  7.33:1  AA 达标（深色侧本就富余，无需调整）
  labelTertiary: '#636366',      //  3.51:1  与浅色侧 3.26:1 基本对称
  labelQuaternary: 'rgba(235, 235, 245, 0.18)',
  labelOnAccent: '#FFFFFF',
  labelInverse: '#1C1C1E',

  separator: 'rgba(84, 84, 88, 0.60)',
  separatorOpaque: '#38383A',
  borderSubtle: 'rgba(255, 255, 255, 0.08)',
  borderAccent: 'rgba(250, 39, 89, 0.32)',

  accent: '#FA2759',
  accentPressed: '#E01F4C',
  accentDisabled: 'rgba(250, 39, 89, 0.35)',
  onAccent: '#FFFFFF',

  success: '#30D158',
  warning: '#FF9F0A',
  danger: '#FF453A',
  info: '#0A84FF',

  onMediaPrimary: 'rgba(255, 255, 255, 1.00)',
  onMediaSecondary: 'rgba(255, 255, 255, 0.50)',
  onMediaTertiary: 'rgba(255, 255, 255, 0.30)',
  onMediaEmphasis: 'rgba(255, 255, 255, 0.84)',
  onMediaControlBg: 'rgba(255, 255, 255, 0.16)',
  onMediaScrim: 'rgba(0, 0, 0, 0.35)'
};

/** 按 isDark 选择语义令牌（返回常量引用，不新建对象）。 */
export function semanticOf(isDark: boolean): LumioSemantic {
  return isDark ? DARK_SEMANTIC : LIGHT_SEMANTIC;
}
```

**字段完备性自检**：上表 43 个字段覆盖了全仓 160 处硬编码的**全部用途**（逐一映射见 §4.3）。特别说明三处：

- `scrim`：`Layout.ets:318` 的 `rgba(0,0,0,0.35)` 与 `Layout.ets:361` 的 `0.45/0.18` 蒙层，此前无任何令牌。
- `onMedia*`：`LrcView.ets` 的 13 处 hex（`#80ffffff` / `#d6ffffff` / `#4d000000` / `#66000000` / `#99000000`）**不是主题色**，是"叠在封面图上"的覆盖层色，此前被误当主题色写死。单列 `onMedia*` 家族是本次架构的关键洞察。
- `fillAccentSubtle / Soft / Muted`：三档而非一档，对应现存 0.05 / 0.10 / 0.30 三种实际用法。

#### 2.4.1 ⚠️ `onMedia*` 是**第二个独立维度**，不得用 `semanticOf()` 选取

v1.2 修正：`onMedia*` 家族虽然定义在 `LumioSemantic` 内部（共用浅/深两套值），但它的**输入维度与其余字段不同**：

| 维度 | 输入 | 选择器 | 例 |
|---|---|---|---|
| 普通语义色 | **应用主题**（`isDark`） | `semanticOf(isDark)` | `label` / `surfaceRaised` |
| `onMedia*` | **背景明暗**（封面取色结果，与应用主题无关） | **`onMediaOf(backgroundIsDark)`** | `onMediaPrimary` |

一个深色主题用户可以正在播放一张**浅色封面**——此时歌词应取 `onMedia*(light)` 分支，而**不是** `semanticOf(true)` 的 dark 分支。若误用 `semanticOf(isDark)`，浅色封面上会出现白字，**直接不可读**。

```arkts
/** 媒体覆盖层令牌：叠在封面/图片上的前景色。输入是「背景明暗」，不是「应用主题」。 */
export interface LumioOnMedia {
  primary: string;      // 当前行
  secondary: string;    // 非当前行
  tertiary: string;     // 翻译（非当前行）
  emphasis: string;     // 翻译（当前行）
  controlBg: string;    // 封面上的控件底
  scrim: string;        // 蒙层（保证前景可读，见 §3.5.3）
}

export const ON_MEDIA_LIGHT: LumioOnMedia = {
  primary: 'rgba(0, 0, 0, 0.85)', secondary: 'rgba(0, 0, 0, 0.30)',
  tertiary: 'rgba(0, 0, 0, 0.20)', emphasis: 'rgba(0, 0, 0, 0.60)',
  controlBg: 'rgba(255, 255, 255, 0.16)', scrim: 'rgba(255, 255, 255, 0.35)'
};

export const ON_MEDIA_DARK: LumioOnMedia = {
  primary: 'rgba(255, 255, 255, 1.00)', secondary: 'rgba(255, 255, 255, 0.50)',
  tertiary: 'rgba(255, 255, 255, 0.30)', emphasis: 'rgba(255, 255, 255, 0.84)',
  controlBg: 'rgba(255, 255, 255, 0.16)', scrim: 'rgba(0, 0, 0, 0.45)'
};

/** 按「背景明暗」选取媒体覆盖层令牌 —— 与 semanticOf() 是两个不同维度，禁止混用。 */
export function onMediaOf(backgroundIsDark: boolean): LumioOnMedia {
  return backgroundIsDark ? ON_MEDIA_DARK : ON_MEDIA_LIGHT;
}
```

> 迁移动作：P2c 阶段把 `LumioSemantic` 中的 `onMedia*` 六个字段**迁出**到本接口（届时 `LumioSemantic` 减为 37 字段），所有调用点改用 `onMediaOf()`。**在此之前**，允许从 `LumioSemantic` 读取，但**严禁**用 `semanticOf(isDark)` 取 `onMedia*`。

### 2.5 间距栅格（`LumioScale.ets`）

**基准：4vp**。所有值均为 4 的倍数（仅 `hair=2` 例外，用于 1px 级描边补偿）。命名沿用 `docs/design_tokens.md` §2.2 的语义并向上扩展，避免第三套命名。

| 令牌 | vp | 等价 `space_*` | 使用场景 |
|---|---:|---|---|
| `space.none` | 0 | — | 归零 |
| `space.hair` | 2 | — | 徽章内距、1px 补偿 |
| `space.tight` | 4 | `space_xs` | 图标与文字、标题与副标题 |
| `space.compact` | 8 | `space_sm` | 列表项间距、卡片内元素 |
| `space.cozy` | 12 | `space_md` | 卡片内边距（紧凑）、按钮横内距 |
| `space.base` | 16 | `space_lg` | **页面/卡片主内距**（基准） |
| `space.roomy` | 20 | — | 分组间距、悬浮层内距 |
| `space.loose` | 24 | `space_xl` | 区块间距、分组头上下 |
| `space.section` | 32 | `space_xxl` | 大区块分隔 |
| `space.block` | 40 | — | 空态与首屏留白 |
| `space.page` | 48 | — | 大屏页面上下留白 |
| `space.hero` | 64 | — | 播放页/年度报告顶部留白 |

**触摸目标**：`touchTarget.min = 44`（Apple HIG 最小可点区域；鸿蒙建议 40，取二者较大值）。列表行高 `rowHeight = 72`（沿用现网，见 `LocalLibrary.ets:423`），`rowHeightCompact = 60`。

```arkts
export interface LumioSpace {
  none: number; hair: number; tight: number; compact: number; cozy: number;
  base: number; roomy: number; loose: number; section: number;
  block: number; page: number; hero: number;
  touchTargetMin: number; rowHeight: number; rowHeightCompact: number;
}

export const SPACE_SM: LumioSpace = {
  none: 0, hair: 2, tight: 4, compact: 8, cozy: 12, base: 16, roomy: 20,
  loose: 24, section: 32, block: 40, page: 48, hero: 64,
  touchTargetMin: 44, rowHeight: 72, rowHeightCompact: 60
};
// SPACE_MD / SPACE_LG 见 §5
```

### 2.6 圆角阶梯

**裁决（AD-1）**：采用 `docs/design_tokens.md` §2.1 的 4/8/12/16/24/999 阶梯（与 `float.json` 的 `cover_radius(16)` / `label_border(8)` 同值，且是 4 的倍数），**废弃** `DesignSystem.Radius` 的 10/14/20。

| 令牌 | vp | 与容器尺寸的对应 | 典型使用 |
|---|---:|---|---|
| `radius.none` | 0 | — | 通栏元素、分隔线 |
| `radius.xs` | 4 | 高度 ≤ 20vp | 小 chip、进度条 |
| `radius.sm` | 8 | 高度 20–32vp | 徽章（`QualityBadge`）、小按钮、卡片内缩略图 |
| `radius.md` | 12 | 高度 32–64vp | **列表项**、中等卡片、按钮 |
| `radius.lg` | 16 | 边长 ≥ 64vp | 封面、大卡片、面板 |
| `radius.xl` | 24 | 边长 ≥ 200vp | 浮层、Sheet 顶部、大容器 |
| `radius.pill` | 999 | 任意（结果=短边一半） | 胶囊按钮、圆形播放键（56vp）、悬浮导航胶囊 |

**连续曲率**：ArkUI `borderRadius` 无 Apple 的 continuous-corner 算法；视觉上用 `radius.lg=16` 近似 Apple 的 10–14pt 卡片圆角（鸿蒙 vp 与 iOS pt 视觉密度略有差异）。不追求像素级一致。

#### 旧值 → 新值映射表（AD-1 批准）

| `DesignSystem.Radius` 旧令牌 | 旧值 | → 新令牌 | 新值 | 说明 |
|---|---:|---|---:|---|
| `Radius.sm` | 10 | `radius.md` | **12** | 10 非 4 的倍数，提升到 12 |
| `Radius.md` | 14 | `radius.lg` | **16** | 14 → 16（与 `float.json:cover_radius` 同值） |
| `Radius.lg` | 20 | `radius.xl` | **24** | 20 → 24 |
| `Radius.pill` | 999 | `radius.pill` | **999** | 保持不变 |
| （无） | — | `radius.xs` | 4 | 新增 |
| （无） | — | `radius.sm` | 8 | 新增（与 `float.json:label_border` 同值） |
| （无） | — | `radius.none` | 0 | 新增 |

**为何必须换到 4 的倍数**：间距栅格以 4vp 为基（§2.5），嵌套容器若用非 4 倍数的圆角，会出现**内外圆角不同心**（外圆角 20 / 内圆角 12 且内边距 4 → 视觉上两条弧线的圆心不重合）。这是最容易被看穿的细节，也是 Apple 规范坚持"圆角与内边距同基"的原因。

**兼容处理**：`DesignSystem.Radius` 在 P4 前以 **re-export 垫片**方式保留，但其字段值**直接改为新值**（不再各写一套），确保过渡期内外圆角仍然同心：

```arkts
// DesignSystem.ets（P4 前的过渡形态）
// @deprecated 请改用 entry/src/main/ets/tokens/LumioScale 的 LUMIO_RADIUS
export class Radius {
  static readonly sm: number = LUMIO_RADIUS.md;  // 10 → 12
  static readonly md: number = LUMIO_RADIUS.lg;  // 14 → 16
  static readonly lg: number = LUMIO_RADIUS.xl;  // 20 → 24
  static readonly pill: number = LUMIO_RADIUS.pill;
}
```

> ⚠️ 注意这是**值变化、不是新增一层**：垫片指向同一常量，P4 删除垫片时不会有第二次值跳动。

### 2.7 字体排版阶梯

ArkUI 可表达：`fontSize(fp)`、`fontWeight(number 100–900)`、`lineHeight(vp)`、`letterSpacing(vp)`。**大字号负字距、小字号略正字距**（Apple 光学字距规律）。

> `size` 单位 **fp**（跟随系统字体缩放）；`lineHeight` / `tracking` 单位 **vp**（不随字体缩放，避免行高塌陷）。
> 「现网值」列 = 迁移时保持视觉等价的值；「目标值」列 = Apple 化后的值（P4 阶段可选启用）。

| 令牌 | 现网值 fp | 目标值 fp | 字重 | 行高 vp（目标） | 字距 vp | 用途 / 现网出处 |
|---|---:|---:|---:|---:|---:|---|
| `display` | 28 | **34** | 700 | 41 | **−0.40** | 年度报告大数字（`Wrapped`） |
| `largeTitle` | 28 | 28 | 700 | 34 | −0.26 | 页面大标题（`title_font_lg` 28） |
| `title1` | 20 | **22** | 700 | 28 | −0.20 | **播放页歌曲名**（`PlayerPage`） |
| `title2` | 20 | 20 | 600 | 25 | −0.16 | 页标题 / 卡片标题（`title_font_lg` 20） |
| `title3` | 18 | 18 | 600 | 24 | −0.12 | 分组标题（`title_font_md` 18） |
| `headline` | 16 | **17** | 600 | 22 | −0.10 | **列表主标题**（`item_font_md` 15–16） |
| `body` | 15 | 15 | 400 | 20 | −0.06 | 正文 / 列表副标题 |
| `bodyEmphasis` | 15 | 15 | 600 | 20 | −0.06 | 强调正文 |
| `subhead` | 14 | 14 | 400 | 19 | −0.04 | 次级说明（`font_fourteen`） |
| `footnote` | 13 | 13 | 400 | 18 | 0.00 | 歌手 / 副信息（`singer` 13） |
| `caption1` | 12 | 12 | 400 | 16 | **+0.02** | 角标 / 时间戳（`singer_font_sm` 12） |
| `caption2` | 11 | 11 | 500 | 14 | **+0.04** | 极小红点角标（`singer_title_sm` 11） |

```arkts
export interface LumioTextStyle {
  size: number;        // fp
  weight: number;      // 400/500/600/700
  lineHeight: number;  // vp
  tracking: number;    // vp（letterSpacing）；大字号负、小字号正
}

export interface LumioType {
  display: LumioTextStyle;
  largeTitle: LumioTextStyle;
  title1: LumioTextStyle;
  title2: LumioTextStyle;
  title3: LumioTextStyle;
  headline: LumioTextStyle;
  body: LumioTextStyle;
  bodyEmphasis: LumioTextStyle;
  subhead: LumioTextStyle;
  footnote: LumioTextStyle;
  caption1: LumioTextStyle;
  caption2: LumioTextStyle;
}
```

> ⚠️ **禁止固定 `height(64/60/76)` 行高**（沿用 `design_tokens.md` §2.3 的 P2 无障碍结论）：列表项改用 `minHeight` + `padding`，避免超大字体下多行挤压。

### 2.8 动效令牌

#### 2.8.1 弹簧曲线参数表

`curves.interpolatingSpring(velocity, mass, stiffness, damping)`，阻尼比 `ζ = damping / (2·√(stiffness·mass))`，过冲 `≈ e^(−πζ/√(1−ζ²))`。

| 令牌 | stiffness | damping | mass | velocity | ζ | 过冲 | 用途 |
|---|---:|---:|---:|---:|---:|---:|---|
| `crisp` | 380 | **39** | 1 | 0 | **1.00** | **0 %** | **默认（临界阻尼）**：控件显隐、状态切换、列表项出现。**绝不过冲** |
| `snappy` | 380 | 30 | 1 | 0 | 0.77 | 2.3 % | 点按 / 按压反馈（几乎无回弹的清脆感） |
| `soft` | 280 | 24 | 1 | 0 | 0.72 | 4.0 % | 卡片 / 面板入场 |
| `gentle` | 200 | 20 | 1 | 0 | 0.71 | 4.3 % | 页面转场、Sheet 展开 |
| `bouncy` | 500 | 26 | 1 | 0 | 0.58 | 10.7 % | **带惯性手势的轻微回弹**：拖拽释放、滑块吸附、下拉关闭 Sheet |
| `hero` | 342 | 38 | 1 | 0 | 1.03 | 0 % | 一镜到底共享元素（沿用现网 `Layout`/`PlayerPage` 的值，**保持不变**） |

**裁决（AD-2）**：新增 `crisp`（ζ=1.0）作为**默认曲线**，现有 `snappy/soft/gentle` 定位为"有回弹的变体"。理由：默认场景下过冲会让列表滚动后的元素出现轻微抖动；Apple 的"默认临界阻尼"与"手势惯性回弹"是两种明确分工，本表现在显式表达了这个分工。

#### 2.8.2 时长

| 令牌 | ms | 用途 | 现网出处 |
|---|---:|---|---|
| `micro` | 80 | 图标态切换 | — |
| `tap` | 120 | 点按回弹 | `Motion.tap` |
| `press` | 150 | 按压 | `Motion.press` |
| `quick` | 200 | 小规模属性变化 | `LocalLibrary` 200ms |
| `fade` | 300 | 淡入淡出 | `Motion.fade` |
| `sheet` | 360 | 半模态 | `Motion.sheet` |
| `page` | 400 | 页面转场 | — |
| `stagger` | 60 | 列表错峰步进 | `Motion.stagger`（现网实际用 40/50，统一为 60） |

#### 2.8.3 降级策略（reduceMotion）

`LumioMotion` 的所有出口都接收 `reduce: boolean`，由 `LumioTheme.motion()` 内部读 `SettingsStore.getInstance().getReduceMotion()`（沿用既有开关，不新增设置项）。

| 维度 | 正常 | 降级（reduce = true） |
|---|---|---|
| 曲线 | `interpolatingSpring(...)` | `curves.cubicBezier(0.2, 0.0, 0.2, 1.0)`（无过冲） |
| 时长 | base | `base > 200 ? 120 : base` |
| 错峰 | `index * stagger` | `0` |
| 位移动画（`translate`/`scale`） | 保留 | **替换为纯 `opacity`**（不做位移与缩放） |
| 循环动画（封面旋转 / 空态呼吸 / 歌词流光） | 保留 | **关闭**（沿用现网 `Layout:85`、`Favorites:62` 的既有实现） |
| 按压反馈 | `scale 0.96` + 弹簧 | **保留**（必要的即时反馈，只做 opacity） |

```arkts
// LumioMotionSpec.ets —— 零 import（纯数值，卡片可读）
export interface LumioSpringSpec {
  velocity: number; mass: number; stiffness: number; damping: number;
}

export class LumioSpringSpecs {
  static readonly crisp: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 380, damping: 39 };
  static readonly snappy: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 380, damping: 30 };
  static readonly soft: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 280, damping: 24 };
  static readonly gentle: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 200, damping: 20 };
  static readonly bouncy: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 500, damping: 26 };
  static readonly hero: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 342, damping: 38 };
}

export class LumioDurations {
  static readonly micro: number = 80;
  static readonly tap: number = 120;
  static readonly press: number = 150;
  static readonly quick: number = 200;
  static readonly fade: number = 300;
  static readonly sheet: number = 360;
  static readonly page: number = 400;
  static readonly stagger: number = 60;
}
```

```arkts
// LumioMotion.ets —— 唯一 import curves 的令牌文件
// 已规避红线 4：curves 从 @kit.ArkUI 具名导入；不 import SettingsStore（由调用方传 reduce）
import { curves } from '@kit.ArkUI';
import type { ICurve } from '@kit.ArkUI';
import { LumioDurations, LumioSpringSpec, LumioSpringSpecs } from './LumioMotionSpec';

export enum SpringKind { Crisp, Snappy, Soft, Gentle, Bouncy, Hero }

export class LumioMotion {
  static spring(kind: SpringKind, reduce: boolean): ICurve {
    if (reduce) {
      // 降级：无过冲的缓出，等价于「临界阻尼但更快」
      return curves.cubicBezier(0.2, 0.0, 0.2, 1.0);
    }
    const spec: LumioSpringSpec = LumioMotion.specOf(kind);
    return curves.interpolatingSpring(spec.velocity, spec.mass, spec.stiffness, spec.damping);
  }

  static duration(base: number, reduce: boolean): number {
    return reduce && base > 200 ? 120 : base;
  }

  static staggerDelay(index: number, reduce: boolean): number {
    return reduce ? 0 : index * LumioDurations.stagger;
  }

  private static specOf(kind: SpringKind): LumioSpringSpec {
    if (kind === SpringKind.Crisp) { return LumioSpringSpecs.crisp; }
    if (kind === SpringKind.Snappy) { return LumioSpringSpecs.snappy; }
    if (kind === SpringKind.Soft) { return LumioSpringSpecs.soft; }
    if (kind === SpringKind.Gentle) { return LumioSpringSpecs.gentle; }
    if (kind === SpringKind.Bouncy) { return LumioSpringSpecs.bouncy; }
    return LumioSpringSpecs.hero;
  }
}
```

> ⚠️ **风险 R-5**：若本 SDK 未具名导出 `ICurve`，去掉 `import type { ICurve }` 与返回类型标注，由推导得出（已登记于 §6）。

### 2.9 阴影 / 层级令牌

深色下投影几乎不可见，Apple 的做法是**用 hairline 描边替代**。因此每个海拔同时给出 `shadow` 与 `border`（深色取 border）。

| 令牌 | radius | light α | dark α | offsetY | 用途 / 现网出处 |
|---|---:|---:|---:|---:|---|
| `elevation.none` | 0 | 0 | 0 | 0 | 无投影 |
| `elevation.low` | 8 | 0.10 | 0.40 | 2 | 列表项卡片（`Favorites:186` / `Playlists:275` / `PlayHistory:179` / `PlaylistDetail:264` 的 r8 α0.1 y2） |
| `elevation.mid` | 12 | 0.10 | 0.60 | 4 | 上下文菜单 / 浮起卡片（`LocalLibrary:542` 的 r12 α0.1/0.6 y4） |
| `elevation.high` | 22 | 0.18 | 0.60 | 8 | 悬浮导航胶囊（`UI设计系统.md §8.1` 的 r22 α0.18 y8） |
| `elevation.modal` | 32 | 0.24 | 0.70 | 12 | Dialog / Sheet |
| `elevation.accent` | 12 | 0.35 | 0.45 | 4 | **品牌投影**（`Layout:287` 的 `rgba(250,39,89,0.35)`） |
| `elevation.cover` | 6 | 0.18 | 0.40 | 2 | 封面投影（`CoverImageView:89` 的 r6 α0.18 y2） |

深色配套：`border` = `borderSubtle`（light `rgba(0,0,0,0.06)` / dark `rgba(255,255,255,0.08)`，与 `Layout:386` 现网值一致）。

```arkts
export interface LumioShadow {
  radius: number; color: string; offsetX: number; offsetY: number;
}
export interface LumioElevation {
  none: LumioShadow; low: LumioShadow; mid: LumioShadow;
  high: LumioShadow; modal: LumioShadow; accent: LumioShadow; cover: LumioShadow;
}
```

### 2.10 毛玻璃令牌

| 令牌 | blur | fill（light） | fill（dark） | border（light / dark） |
|---|---:|---|---|---|
| `glass.thin` | 20 | `rgba(255,255,255,0.50)` | `rgba(28,28,30,0.50)` | `rgba(255,255,255,0.70)` / `rgba(255,255,255,0.08)` |
| `glass.regular` | 30 | `rgba(255,255,255,0.62)` | `rgba(28,28,30,0.62)` | 同上 |
| `glass.thick` | 40 | `rgba(255,255,255,0.75)` | `rgba(28,28,30,0.72)` | 同上 |

- `regular` 与现网 `Glass.bgLight/bgDark`（0.62）完全等价 → **P1 迁移零视觉变化**。
- `borderWidth = 0.5`vp（深色下更明显，营造顶部高光）。
- **API 26**：可由 `uiMaterial.ImmersiveMaterial` 取代（`systemMaterial` 优先级高于 `backgroundColor`，此时**不再设 fill**）；**API 24**：必须保留 `fill` 兜底——因此 `fill` 字段**不可省略**，这是降级路径的硬要求。

```arkts
export interface LumioGlass {
  blur: number; fill: string; border: string; borderWidth: number;
}
export interface LumioGlassSet { thin: LumioGlass; regular: LumioGlass; thick: LumioGlass; }
```

### 2.11 门面：`LumioTheme.ets`

```arkts
// 已规避红线 4/5：仅 import 本层模块与 SettingsStore；不引用 @kit.ArkUI 的 UI 组件
import { LumioSemantic, semanticOf } from './LumioColor';
import { LumioSpace, LumioRadius, LumioType, SPACE_SM, SPACE_MD, SPACE_LG, TYPE_SM, TYPE_LG } from './LumioScale';
import { LumioElevation, LumioGlass, LumioGlassSet, ELEVATION_LIGHT, ELEVATION_DARK, GLASS_LIGHT, GLASS_DARK } from './LumioEffect';
import { LumioMotion } from './LumioMotion';
import type { ICurve } from '@kit.ArkUI';
import { SettingsStore } from '../utils/SettingsStore';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';

export class LumioTheme {
  static semantic(isDark: boolean): LumioSemantic { return semanticOf(isDark); }
  static space(bp: string): LumioSpace { return bp === BreakpointConstants.BREAKPOINT_LG ? SPACE_LG : (bp === BreakpointConstants.BREAKPOINT_MD ? SPACE_MD : SPACE_SM); }
  static type(bp: string): LumioType { return bp === BreakpointConstants.BREAKPOINT_LG ? TYPE_LG : TYPE_SM; }
  static radius(): LumioRadius { return LUMIO_RADIUS; }
  static glass(isDark: boolean): LumioGlassSet { return isDark ? GLASS_DARK : GLASS_LIGHT; }
  static elevation(isDark: boolean): LumioElevation { return isDark ? ELEVATION_DARK : ELEVATION_LIGHT; }

  /** 动效：内部读可达性开关，调用方无需关心。 */
  static curve(kind: SpringKind, ...): ICurve { return LumioMotion.spring(kind, SettingsStore.getInstance().getReduceMotion()); }
  static duration(base: number): number { return LumioMotion.duration(base, SettingsStore.getInstance().getReduceMotion()); }
  static stagger(index: number): number { return LumioMotion.staggerDelay(index, SettingsStore.getInstance().getReduceMotion()); }
}
```

### 2.12 色彩来源策略：内容着色 > 语义着色 > 中性

> 本节落实 AD-0 第 3 条收紧项。**"某个元素该是什么颜色"这个问题，答案只有三个来源，按优先级取用。**

#### 2.12.1 三级优先序

| 优先级 | 来源 | 适用对象 | 令牌出口 | 典型位置 |
|---|---|---|---|---|
| **1（最高）** | **内容着色**：色彩来自内容自身（专辑/歌单/文件夹封面取色） | 歌单卡、专辑卡、文件夹卡、播放页背景与歌词底色 | `ArtworkTint`（见 2.12.2） | `Playlists` / `PlaylistDetail` / `FolderBrowse` / `PlayerPage` |
| **2** | **语义着色**：色彩携带确定含义 | 删除/清空（危险）、成功提示、提醒、品牌行动点 | `danger` / `success` / `warning` / `info` / `accent` | `Settings` / `SettingsCategory` / 主行动按钮 |
| **3（兜底）** | **中性**：不携带任何含义 | 功能入口图标、无封面的容器、次级控件底 | `labelSecondary` + `fillTertiary` | `Mine` 菜单项、无封面歌单 |

**硬性禁止**：

- ❌ **禁止为装饰目的给不同类别分配不同色相**（现状 `Mine.ets` 的四色菜单即典型违例）。类别区分应靠**图标形状 + 文案 + 封面**，不靠颜色。
- ❌ **禁止随机/哈希取色**（"给每个歌单随机一个颜色"）——不可预测、不可控、与品牌无关。
- ❌ **无封面时不得回退到随机色**，必须回退到第 3 级中性。

#### 2.12.2 `ArtworkTint`：封面取色能力（新增，P3 落地）

项目**已具备**取色能力：`PlayerInfoComponent.getImageColor()` 使用 `effectKit.createColorPicker`（`@kit.ArkGraphics2D`，`PlayerInfoComponent.ets:33/342`）。当前仅播放页在用，需抽为可复用能力供歌单卡、文件夹卡共用。

```arkts
// utils/ArtworkTint.ets —— 已规避红线 3（具名接口、无 any / 无解构）
import { effectKit } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';
import type { LumioSemantic } from '../tokens/LumioColor';   // 仅类型，编译期擦除

/** 从封面抽取的一套派生色。所有字段均为「内容色」，与主题无关。 */
export interface ArtworkTint {
  primary: string;      // 主色（用于强调、进度）
  container: string;    // 容器底（低饱和、保证与文字对比度）
  onContainer: string;  // 容器上的文字（自动取黑或白，保证 ≥ 4.5:1）
  scrim: string;        // 叠在封面上的蒙层（保证文字可读）
}

export class ArtworkTintResolver {
  /** 无封面时的中性回退（第 3 级），不分配随机色。 */
  static neutral(s: LumioSemantic): ArtworkTint {
    return { primary: s.accent, container: s.fillTertiary, onContainer: s.label, scrim: s.scrim };
  }

  static fromPixelMap(pm: image.PixelMap, fallback: ArtworkTint): Promise<ArtworkTint> {
    // 复用 effectKit.createColorPicker 现有实现（PlayerInfoComponent.getImageColor）
    // 约束：必须做饱和度/亮度归一化，避免高饱和封面导致 onContainer 对比度不足
    ...
  }
}
```

**不变量**：

1. `ArtworkTint` 位于 **Component 层之下、Semantic 层之上**（它是"由内容派生的语义色"），**不得**反向依赖任何页面。
2. 取色结果必须经过**亮度归一化 + 对比度校验**（`onContainer` 与 `container` 至少 4.5:1），否则回落中性。这是硬要求——高饱和封面直接取色会产生不可读文字。
3. 取色是异步的（PixelMap 解码），组件需提供 `fallback`（第 3 级中性），**不得在取色完成前显示空白或错误色**。
4. `ArtworkTint` **不进** `tokens/`（它 import `@kit.ArkGraphics2D`），放在 `utils/`，保持 `tokens/` 零 import 不变量不被破坏。

#### 2.12.3 `Mine.ets` 四色菜单的改造口径（P2b）

| 菜单项 | 现状 | 改造后 |
|---|---|---|
| 收藏 | `#FA2759` | 图标 `labelSecondary` + 单色描边；**计数徽章**用 `accent`（徽章承载信息，非装饰） |
| 歌单 | `#5856D6` | **封面取色**（有封面）/ `fillTertiary` + 单色图标（无封面） |
| 历史 | `#FF9500` | 图标 `labelSecondary`；若需表达"正在播放"则用 `accent`（语义，非装饰） |
| 文件夹 | `#007AFF` | **封面取色** / `fillTertiary` + 单色图标 |

> 与 §2.12.1 的一致性检查：`Settings.ets` / `SettingsCategory.ets` 的设置项图标同此口径——**设置项一律中性单色**，仅"清除缓存/清空历史/清除统计"这类**破坏性操作**用 `danger`，"启用听歌统计"等**状态类**用 `accent`。

### 2.13 文字对比度契约（对比度锚定，非"挑一个灰"）

> 来源：pm-planner 实测发现浅色 `secondaryLabel` 仅 3.44:1、深色 6.36:1 明暗不对称。经复核**该数据正确**，并由此暴露出 v1.0 令牌表的一个**层级倒挂缺陷**，一并修正。

#### 2.13.1 缺陷：v1.0 的 label 层级是倒挂的

v1.0 把 light `labelSecondary = #8E8E93`（**3.26:1**）、`labelTertiary = #636366`（**5.99:1**）。**"三级"比"二级"更醒目**，层级单调性被破坏。根因是直接沿用了现网两个孤立的 hex，没有按对比度排序。

修正后 `label` 层级**按对比度严格单调递减**，且明暗两侧基本对称：

| 令牌 | 角色 | light | 对比度 | dark | 对比度 | AA(4.5:1) |
|---|---|---|---:|---|---:|:---:|
| `label` | 主文本 / 标题 | `#1C1C1E` | **16.9:1** | `#FFFFFF` | **21.0:1** | ✅ |
| `labelSecondary` | 次要但需可读（歌手、副标题、空态说明） | `#6E6E73` | **5.07:1** | `#98989F` | **7.33:1** | ✅ |
| `labelTertiary` | 弱化信息（计数、时间戳），非正文 | `#8E8E93` | 3.26:1 | `#636366` | 3.51:1 | ⚠️ 豁免 |
| `labelQuaternary` | 占位符 / 禁用 | `rgba(60,60,67,0.18)` | ~1.5:1 | `rgba(235,235,245,0.18)` | ~1.6:1 | ❌ 豁免 |

**豁免依据**：WCAG 1.4.3 对"非必要信息"（占位符、纯装饰、禁用态）不要求 4.5:1。`labelTertiary` 只用于计数/时间戳等**补充信息**，主内容已在 `label`/`labelSecondary` 表达。

#### 2.13.2 裁决：修令牌，不新增 "Strong" 档

**不采纳**新增 `secondaryLabelStrong` 的方案，理由：

1. **"SecondaryStrong" 语义自相矛盾**，会形成 `label / labelSecondary / labelSecondaryStrong / labelTertiary / labelQuaternary` 五档，开发者只能"挑一个看着顺眼的"，尺度立刻失效。
2. 它是一**个逃生舱而非修复**：默认档 `labelSecondary` 仍不达标，只有记得用 Strong 的人才能达标——等于问题没解决。
3. 令牌层的价值正在于此：**修一处，全站生效**。

**采纳的做法**：

- 把 `labelSecondary` 的 light 值从 `#8E8E93` 加深到 **`#6E6E73`（5.07:1）**，使其**默认即达标**。
- 原 `#8E8E93`（3.26:1）下沉为 `labelTertiary`，dark 侧配套用 `#636366`（3.51:1）——两个值**现网已存在**（`DesignSystem` 的 `systemGray` / `systemGray2`），不引入新色。
- 原硬编码 `#636366`（空态说明文字，13fp 的"点击右上角「+」创建第一个歌单"这类**指导性文案**）改映射到 **`labelSecondary`**，不再映射到 `labelTertiary`。

> ⚠️ 这与 `docs/design_tokens.md` F-14 的结论**相反**——F-14 要求把 `#636366` 统一改成 `secondaryText`，但该操作会把 5.99:1 的指导性文字**降到** 3.26:1，反而降低可读性。请 pm-planner 在规划文档中覆盖 F-14。

#### 2.13.3 不变量（写进 Code Review）

1. **`label` 与 `labelSecondary` 在浅/深两侧都必须 ≥ 4.5:1**（对 `background`）。
2. **label 层级必须按对比度严格单调递减**：`label > labelSecondary > labelTertiary > labelQuaternary`。新增文字令牌时必须给出实测对比度。
3. **落到 P4 落地，不进 P1**：P1 需保持值等价以确保零视觉变化；对比度修正属视觉变更，且因全站已读令牌，**只需改 `LumioColor` 一行**（这正是令牌层的收益证明）。

---

## 3. 响应式安全方案（红线 1、2 的规避设计）

### 3.1 状态管理决策表

| 数据 | 载体 | 装饰器 / 读取方式 | 作用域 | 说明 |
|---|---|---|---|---|
| `isDark` | `AppStorage` | `@StorageProp('isDark')` | 每个用色组件 | **只读**跟随，用 Prop 不用 Link（本地无需回写） |
| `currentBreakpoint` | `AppStorage` | `@StorageProp('currentBreakpoint')` | 需要做多端适配的组件 | 沿用现有 `'sm'/'md'/'lg'` |
| `reduceMotion` | `SettingsStore` | 方法内直接 `getReduceMotion()` | `LumioTheme.motion()` 内部 | 非响应式；设置变更需重进页面，与现网一致 |
| 令牌对象 | 无 | **不落 `@State`，由普通方法返回** | `build()` 内 | 返回常量引用，不新建对象，无状态开销 |
| `themeMode` | `AppStorage` | `@StorageProp` / `ThemeManager.setThemeMode` | 设置页 | 写入口唯一 |

**最重要的一条不变量**：**任何用到颜色的 `@Component` 都必须声明 `@StorageProp('isDark') isDark: boolean = false;`**。漏声明不会报错，只会导致"切换主题后该组件不刷新"——这是本项目最隐蔽的缺陷类型，必须进 Code Review 检查表。

### 3.2 ✅ 推荐写法

```arkts
@Component
export struct SongRow {
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('currentBreakpoint') bp: string = 'sm';

  // ✅ 普通方法（不是 get 访问器）—— 已规避红线 1
  private c(): LumioSemantic { return LumioTheme.semantic(this.isDark); }
  private sp(): LumioSpace { return LumioTheme.space(this.bp); }
  private t(): LumioType { return LumioTheme.type(this.bp); }

  build() {
    // ✅ 首条语句即根组件 —— 已规避红线 2（build 体内不出现 const / let）
    Row() {
      Column() {
        Text(this.song.title)
          .fontColor(this.c().label)
          .fontSize(this.t().headline.size)
          .fontWeight(this.t().headline.weight)
          .lineHeight(this.t().headline.lineHeight)
          .letterSpacing(this.t().headline.tracking)
        Text(this.song.singer)
          .fontColor(this.c().labelSecondary)
          .fontSize(this.t().footnote.size)
      }
      .padding({ left: this.sp().cozy })
    }
    .height(this.sp().rowHeight)
    .padding({ left: this.sp().base, right: this.sp().base })
    .backgroundColor(this.c().surfaceRaised)
    .borderRadius(LumioTheme.radius().md)
  }
}
```

**减少重复调用的推荐写法：@Builder 传参（关键技巧）**

`build()` 体内不能 `const t = ...`，但可以把令牌作为 **`@Builder` 参数**传入——调用点在 `build()` 的响应式上下文中求值，主题切换时同样会重算，且 builder 内部不用重复写 `this.c()`：

```arkts
  @Builder
  private rowBody(s: LumioSemantic, t: LumioType, sp: LumioSpace) {
    // ✅ @Builder 首条语句同样是 UI 组件 —— 已规避红线 2
    Column() {
      Text(this.song.title).fontColor(s.label).fontSize(t.headline.size)
      Text(this.song.singer).fontColor(s.labelSecondary).fontSize(t.footnote.size)
    }
    .padding({ left: sp.cozy })
  }

  build() {
    // ✅ 行内求值并传入，LIGHT/DARK 是不同常量引用 → 主题切换时 builder 重执行
    Row() { this.rowBody(this.c(), this.t(), this.sp()) }
      .backgroundColor(this.c().surfaceRaised)
  }
```

**动效写法**

```arkts
  // ✅ 行内调用，首条语句仍是组件 —— 已规避红线 1/2
  Image($r('app.media.ic_play'))
    .scale({ x: this.pressed ? 0.96 : 1.0, y: this.pressed ? 0.96 : 1.0 })
    .animation({ duration: LumioTheme.duration(LumioDurations.tap), curve: LumioTheme.curve(SpringKind.Snappy) })
```

### 3.3 ❌ 反例与失效原因

```arkts
@Component
struct BadDemo {
  @StorageProp('isDark') isDark: boolean = false;

  // ❌ 反例 1：@Component 上的 get 访问器
  //    ArkUI 状态变换器会整段丢弃该访问器，运行时 this.c 为 undefined → 崩溃
  private get c(): LumioSemantic { return LumioTheme.semantic(this.isDark); }

  build() {
    // ❌ 反例 2：build 体首条语句是 const
    //    触发 "Only UI component syntax" / "one root node"，且错误级联误导
    const s = LumioTheme.semantic(this.isDark);
    Column() {}.backgroundColor(s.surfaceRaised)
  }

  // ❌ 反例 3：非响应式读取
  private legacy(): ColorTokens { return ThemeManager.getColors(); }
  //    getColors() 内部是 AppStorage.get()，不建立依赖关系。
  //    主题切换时本组件不会重渲染 → 必须杀进程重进才生效。
}
```

**为何静态 getter 也不够**：`ThemeManager.lightColors` / `darkColors` 本身没问题（它们是普通类的静态访问器，不受红线 1 约束），但**它们只解决"取到值"，不解决"何时重取"**。组件必须自己持有 `@StorageProp('isDark')` 才能感知变化——这正是现网 22 个文件统一写 `this.isDark ? darkColors : lightColors` 的原因。**新令牌层保留并强化了这个模式**，只是把 `ColorTokens` 换成字段完备的 `LumioSemantic`。

**为何不能用 `getColors()` 非响应式读**：`AppStorage.get()` 是一次性快照，`EntryAbility.onConfigurationUpdated → refreshSystemTheme()` 更新 AppStorage 后，没有任何依赖边指向本组件，ArkUI 不会调度重渲染。表现为"系统切深色，App 里部分页面变色、部分不变"，且**无法稳定复现**（取决于页面是否被重建过），是典型的顽固缺陷。

### 3.4 Form 卡片主题链路（AD-2 结论）

#### 3.4.1 直接回答：卡片**不能**访问主应用 `AppStorage('isDark')`

`AppStorage` 是**进程内单例**。桌面卡片运行在独立的 Form 渲染进程，与主应用不共享内存，因此：

| 能力 | 卡片侧是否可用 | 说明 |
|---|---|---|
| `AppStorage.get('isDark')` | ❌ **不可用** | 卡片的 `AppStorage` 是自己的空实例，读不到主应用的值 |
| `LocalStorage` / `@LocalStorageProp('isDark')` | ✅ **可用** | 由 `FormExtensionAbility` 经 `createFormBindingData` 初始化的卡片本地存储 |
| `formProvider.updateForm()` | ✅ 可用（主应用侧调用） | 主动向卡片推送新数据 |
| `LumioTheme`（门面） | ❌ **不可 import** | 依赖 `SettingsStore`（Preferences），卡片不应引入 |
| `LumioColor` / `LumioScale` / `LumioEffect` / `LumioMotionSpec` | ✅ **可 import** | 四个文件零 import，纯常量 |
| `LumioMotion` | ❌ 不可 import | 依赖 `@kit.ArkUI` 的 `curves` |

#### 3.4.2 ⚠️ 现存缺陷：卡片今天**恒为浅色**

实测确认（非推测）：

- `WidgetCard.ets:66` **已经**声明了 `@LocalStorageProp('isDark') isDark: boolean = false;` —— 卡片侧 plumbing 是齐的。
- 但 `FormAbility.onAddForm()`（`FormAbility.ets:52-58`）的 `createFormBindingData` **只写入了** `title/artist/album/duration/isPlaying`，**完全没有 `isDark`**。
- 主应用 `ThemeManager` 也没有任何 `formProvider.updateForm` 推送主题的逻辑。

**结论**：`isDark` 永远是默认值 `false`，**深色模式用户的桌面卡片至今一直是浅色**。这不仅是"G-4 待办缺口"，而是一个**活跃的线上缺陷**，P5 必须修。

#### 3.4.3 确定方案：不依赖主应用推送，FormAbility 自己算

关键发现：`FormAbility` **已经能读 Preferences** —— `onAddForm` 里就在执行 `PreferencesUtil.getInstance().addFormId(this.context, formId)`（`FormAbility.ets:50`）。同应用、同 uid、同数据目录，因此 `FormAbility` 可完整复算 `isDark`，无需依赖主应用推送。

**设计要点：抽一个零 AppStorage 依赖的纯函数，供主应用与 FormAbility 共用**，消除"两处各算一遍"的漂移：

```arkts
// utils/ThemeResolve.ets —— 纯函数，不读 AppStorage，不读 Preferences
// 已规避红线 3：复用 SettingsStore 已有的具名类型 ThemeMode，不重复定义、无 any、无解构
import { ConfigurationConstant } from '@kit.AbilityKit';
import type { ThemeMode } from './SettingsStore';   // import type：编译期擦除，无运行时依赖

/**
 * 唯一的 isDark 判定逻辑。主应用与 FormAbility 共用，杜绝双算漂移。
 * 逻辑与现网 ThemeManager.isDark() 完全等价，仅去除 AppStorage 依赖。
 * @param mode            持久化的主题模式
 * @param systemColorMode 系统当前 ColorMode（仅 system 模式下使用）
 */
export function resolveIsDark(mode: ThemeMode,
  systemColorMode: ConfigurationConstant.ColorMode): boolean {
  if (mode === 'light') {
    return false;
  }
  if (mode === 'dark') {
    return true;
  }
  return systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
}
```

**配套：给 FormAbility 一个同步读偏好的入口**

现网 `SettingsStore.getThemeMode()` 只能在 `await init()` 之后用（异步），而 `onAddForm` 必须**同步返回** `FormBindingData`。因此补一个同步读取方法（复用现网 `PREF_NAME='app_settings'` / `KEY_THEME_MODE='theme_mode'`，`SettingsStore.ets:35/38`）：

```arkts
// utils/SettingsStore.ets 新增
static getThemeModeSync(context: Context): ThemeMode {
  const pref: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_NAME });
  const raw: string = pref.getSync(KEY_THEME_MODE, 'system') as string;
  return (raw === 'light' || raw === 'dark' || raw === 'system') ? raw as ThemeMode : 'system';
}
```

> `getSync` 在本项目已有先例（`PreferencesUtil.isPermGuideShown` / `getSilentMode`），非新增风险。
> 主应用侧 `ThemeManager.isDark()` 改为调用 `resolveIsDark()`（判定规则收敛到一处，风险 **R-19**）。

**FormAbility 侧改造（P5）**

```arkts
onAddForm(want: Want): formBindingData.FormBindingData {
  // 同步读取，不依赖主应用推送
  const mode: ThemeMode = SettingsStore.getThemeModeSync(this.context);
  const isDark: boolean = resolveIsDark(mode, this.context.config.colorMode);
  return formBindingData.createFormBindingData({
    title: '', artist: '', album: '', duration: 0, isPlaying: false,
    isDark: isDark          // ← 补齐（现网缺失）
  });
}

// 自愈兜底：系统周期刷新时重算并回推，即使主应用推送失败也能纠正
onUpdateForm(formId: string): void {
  const binding = /* 同上重算 isDark 并组装 */;
  formProvider.updateForm(formId, binding).catch(() => { /* 静默，下个周期再试 */ });
}

// 跟随系统主题变化
onConfigurationUpdate(config: Configuration): void {
  // 遍历 Preferences 中的 formId，全量 updateForm 推送新 isDark
}
```

**主应用侧改造（P5）**：`ThemeManager.setThemeMode()` 与 `refreshSystemTheme()` 末尾，遍历 `PreferencesUtil` 中的 formId 列表，调 `formProvider.updateForm` 推送 `isDark`。

#### 3.4.4 三层兜底链

| 层级 | 机制 | 时效 | 覆盖场景 |
|---|---|---|---|
| **L1** | 主应用 `setThemeMode` / `refreshSystemTheme` 后主动 `updateForm` | 秒级 | 用户在 App 内切主题 |
| **L2** | `FormAbility.onUpdateForm` 周期刷新时自愈重推 | 分钟～小时级 | 主应用推送失败、进程被杀、系统主题变化 |
| **L3** | 卡片 `@LocalStorageProp('isDark')` 初值 `false` | 首次加载 | 从未收到推送的存量卡片 |

**L3 取值决策**：保持 `false`（浅色），**不采用"写死深色"**。理由：App 默认跟随系统，浅色是更常见的初始态；写死深色会让浅色主题用户的卡片与 App 观感割裂。为消除 L3 的暴露窗口，P5 上线时主应用**启动后主动全量 `updateForm` 一次**，把存量卡片刷新到正确主题。

#### 3.4.5 卡片取色（P5 收益）

卡片可安全 import 零 import 的令牌文件，`WidgetCard.ets:87-108` 的 `getCardColors()` **整段删除**：

```arkts
  @LocalStorageProp('isDark') isDark: boolean = false;

  // ✅ 零依赖，卡片进程可用（已规避红线 1：普通方法非 get 访问器）
  private c(): LumioSemantic { return semanticOf(this.isDark); }

  // 用法：.backgroundColor(this.c().surfaceRaised) / .fontColor(this.c().label)
```

> ⚠️ 卡片 import 本地 `.ets` 相对路径模块受支持，但需在真机验证（风险 **R-6**）。若验证失败，兜底为"卡片内保留一份 copy + CI 同值校验脚本"，**不可**因此放弃令牌化。

### 3.5 `LrcView` Canvas 的令牌注入通道（pm-planner R-04 最高风险项）

#### 3.5.1 问题本质

`LrcView` 用 `CanvasRenderingContext2D` **命令式绘制**歌词：颜色是 `fillStyle = string`，**不在 ArkUI 响应式体系内**，无法通过属性链式挂令牌。现网 13 处裸 hex 集中在 `applyColorScheme()`（`LrcView.ets:913-927`），按 `backgroundIsDark` 分支硬编码 8 个值。

三个必须同时满足的约束：

1. **不能破坏 `PanGesture` 增量派发跟手** —— `onActionUpdate` 里 `dy = event.offsetY - lastPanY` 累加后直接 `drawContent()`，**每帧一次重绘**。
2. **不能增加重绘开销** —— 令牌解析若进入 `drawContent()`，等于每帧多一次分支 + 属性访问。
3. **对比度必须由动态封面取色保证** —— 这是全应用唯一一处对比度**不由静态令牌保证**的地方。

#### 3.5.2 通道设计：注入发生在"配色变更时"，不在"每帧绘制时"

**关键观察：现网骨架已经是对的** —— `@Prop @Watch('onBgChanged') backgroundIsDark` → `applyColorScheme()` → `drawContent()`。令牌化只需**替换 `applyColorScheme()` 的取值来源**，`drawContent()` 一行不动。

```arkts
// lyric/LyricColors.ets —— 纯数据，零 import
// 已规避红线 3（具名接口、无 any / 无解构）
import type { LumioOnMedia } from '../tokens/LumioColor';
import { onMediaOf } from '../tokens/LumioColor';

/** 歌词配色方案（纯数据，由父组件从 ArtworkTint 计算后注入）。 */
export interface LyricColorScheme {
  normal: string;            // 非当前行
  current: string;           // 当前行
  translateNormal: string;   // 翻译（非当前行）
  translateCurrent: string;  // 翻译（当前行）
}

/** 无封面时的回退：背景是静态令牌，对比度静态可保证。 */
export function defaultLyricScheme(backgroundIsDark: boolean): LyricColorScheme {
  const m: LumioOnMedia = onMediaOf(backgroundIsDark);
  return {
    normal: m.secondary,
    current: m.primary,
    translateNormal: m.tertiary,
    translateCurrent: m.emphasis
  };
}
```

```arkts
// LrcView.ets 改动
  @Prop @Watch('onSchemeChanged') lyricScheme: LyricColorScheme = defaultLyricScheme(true);
  @Prop @Watch('onBgChanged') backgroundIsDark: boolean = true;   // 仅无封面时兜底

  // 缓存字段：drawContent() 只读这些字段
  private mNormalTextColor: string = '#80ffffff';

  /** 令牌解析只发生在这里 —— 背景/配色变更时，不是每帧。 */
  private applyColorScheme(): void {
    this.mNormalTextColor = this.lyricScheme.normal;
    this.mCurrentTextColor = this.lyricScheme.current;
    this.mTranslateColorNormal = this.lyricScheme.translateNormal;
    this.mTranslateColorCurrent = this.lyricScheme.translateCurrent;
  }

  onSchemeChanged(): void {
    this.applyColorScheme();
    this.drawContent(this.curCanvasOffsetY);
  }
```

**为什么这是零性能开销**：

| 函数 | 调用频率 | 是否做令牌解析 |
|---|---|---|
| `drawContent()` | **每帧**（PanGesture 增量派发） | ❌ 只读缓存的私有字符串字段 |
| `applyColorScheme()` | 3 次（`aboutToAppear` / `onBgChanged` / `onSchemeChanged`） | ✅ 只有这里 |

`drawContent()` 内部读取的仍是 `this.mNormalTextColor` 等普通字符串字段，**与现状逐字节相同**——PanGesture 的增量派发逻辑、重绘路径、帧率**完全不受影响**。

> ❌ **反例（禁止）**：把 `onMediaOf(this.backgroundIsDark).primary` 写进 `drawContent()` 或 `drawLine()`。虽然不会崩，但会在 120Hz 设备上产生每帧一次的无谓对象访问，且违反"热路径不做令牌解析"原则。**令牌必须在冷路径解析、缓存到字段、热路径只读字段。**

#### 3.5.3 歌词对比度：**双层 alpha** 与预合成不透明色（v1.5 定稿）

> ⚠️ **本节经历三次修正，v1.5 为定稿。** v1.3 按"不透明白字"计算（错）；v1.4 修正为单层半透明（仍不完整）；**v1.5 发现现网是 `fillStyle` α × `globalAlpha` 双层叠加**，实际对比度比 v1.4 的结论**还要低一个档次**。以下为脚本复算的完整结果。

##### 决定性发现：现网是**双层 alpha**，我和 pm-planner 都只算了一层

`drawLyricLine()`（`LrcView.ets:637-695`）对每一行同时设置了 `fillStyle`（含 alpha）**和** `context.globalAlpha`，两者**相乘**才是最终有效 alpha：

| 状态 | `fillStyle` | `globalAlpha` | **有效 α** | `filter` |
|---|---|---:|---:|---|
| 当前行 | `#FFFFFF` (1.0) | 1.00 | **1.000** | none |
| 播放态 已播放行 | `#80ffffff` (0.502) | 0.55 | **0.276** | `blur(3px)` |
| 播放态 未播放行 | `#80ffffff` (0.502) | 0.38 | **0.191** | `blur(5px)` |
| **浏览态** 已播放行 | `#80ffffff` (0.502) | 0.72 | 0.361 | none |
| **浏览态** 未播放行 | `#80ffffff` (0.502) | 0.55 | 0.276 | none |
| 翻译 当前行 | `#d6ffffff` (0.839) | 0.85 | 0.713 | none |
| 翻译 未播放 | `#80ffffff` (0.502) | 0.40 | 0.201 | `blur(5px)` |

##### 🔴 v1.6 更正：v1.5 把背景当成"原始封面亮度"，**结论错误**

team-lead 指出歌词背景**不是原始封面**，而是 `PlayerInfoComponent` 里的**三段叠加**。经核实**该质疑完全成立**——`LyricsComponent`（`PlayerInfoComponent.ets:165/214/237`）确实位于 `Stack()`（L106）内、三层背景之后：

```
① 封面图   Image(imageLabel).opacity(0.5).blur(...)                     L108-120
② 渐变层   linearGradient(buildGradientColors(...)).opacity(0.65)        L123-131
③ 蒙层     lyricBgDark ? rgba(0,0,0,0.35) : rgba(255,255,255,0.20)      L134-138
```

且 `buildGradientColors()`（L364-378）**先压暗再渐变**：`deep=0.28C` / `base=0.42C` / `lifted=0.62C`；`lyricBgDark` 恒为 `true`（L351 硬写），**现网强制走压暗路径**。

**按真实链路重算**（合成式 `C3 = 0.65·(0.65·G + 0.35·(0.5·封面 + 0.5·基底))`）：

| 封面 / 基底 | 渐变位 | 合成底色 | 当前行（不透明） | 播放态未播放 | 浏览态未播放 |
|---|---|---:|---:|---:|---:|
| 纯白 / 黑底 | lifted（最亮） | `#606060` | **6.31:1** ✅ | 1.56:1 | 1.87:1 |
| 纯白 / 黑底 | deep（最暗） | `#3B3B3B` | **11.17:1** ✅ | 1.79:1 | 2.30:1 |
| 纯白 / **白底（最坏）** | lifted | `#7D7D7D` | **4.13:1** ⚠️ | 1.39:1 | 1.59:1 |
| 中灰 `#BCBCBC` / 黑底 | lifted | `#474747` | **9.35:1** ✅ | 1.72:1 | 2.16:1 |
| 暗封面 `#1C1C1E` / 黑底 | lifted | `#0B0B0B` | **19.74:1** ✅ | 1.71:1 | 2.37:1 |

**三条更正后的结论**：

1. ❌ **撤回 v1.5 的"现网连当前行都只有 2.44:1"**。当前行实测 **4.13 ~ 19.74:1**，基本达标（唯一缺口：纯白封面 + 白基底 + lifted 位为 4.13:1）。**该结论建立在"背景=原始封面"的错误前提上，不得作为后续决策依据。**
2. ✅ **R-22（双层 alpha）依然成立，且这是 A 案现在的唯一理由**：播放态未播放行 1.39~1.79:1、浏览态未播放行 1.59~2.37:1，**在所有背景上都低**。
   - 机理解释：半透明文字**永远向背景靠拢**，因此**无论背景明暗，对比度都被压缩**——暗背景下白字被拖暗（2.37:1），亮背景下白字被拖亮。所以这不是"背景不够暗"的问题，**调蒙层无效，只能改结构**。

> 🔒 **本条机理为本文最重要的结论，任何后续修订不得删除或弱化**（team-lead 指定保留）。它解释了我们为何历经四轮才找对方向：**前三轮都在"调参数"的框架里打转，而病根在结构**。凡出现"把对比度再压一点/再提一点就能解决"的提议，先回到这条机理自检。
3. ✅ **`LrcView.ets:652` 注释「全部清晰」与实现背离**仍成立，但数值更正为 1.59~2.37:1。

> 更正 pm-planner §6.6⑤：「蒙层 ≥0.55 即可达 3:1」→ 实际需 **≥0.64**；且**起约束作用的是 clamp 上限 0.65 而非下限**（下限 0.35→0.50 在暗封面下仅差 0.02:1）。该结论在单层模型下成立，**在双层模型下则无论上下限都不可达**——这正是必须改结构而非调参数的理由。

##### 定稿方案（team-lead 裁决）：预合成不透明色

病根不是数值而是**结构**：同一个半透明色值在不同封面上渲染成不同颜色，且双层 alpha 让对比度彻底失控。**预合成把不确定性前移到 `ArtworkTint` 一处**，在取色时按目标对比度直接算出最终不透明色下发。

**为什么这是唯一可行解**——可达性证明（纯白封面 + 蒙层 0.65，背景 `#595959`）：

| 目标 | 所需不透明灰度 | 可表达？ |
|---|---|---|
| ≥3:1 | `#A9A9A9` | ✅ |
| ≥4.5:1 | `#CFCFCF` | ✅ |

**单层不透明色下两档目标均可达**；双层 alpha 下均不可达。这就是改结构的全部理由。

```arkts
// 已规避红线 3（具名接口、无 any / 无解构）
/**
 * 歌词配色：全部为「预合成的不透明色」。
 * 计算发生在 ArtworkTint 内、每封面一次；LrcView 只做赋值，不做任何计算。
 */
export interface ArtworkLyricColors {
  // —— 播放态 ——
  current: string;          // 当前行：≥4.5:1
  playingDim: string;       // 非当前行有意弱化：≥3:1（可叠加 blur，属设计意图）
  translateCurrent: string; // 翻译当前行：≥4.5:1
  translateDim: string;     // 翻译非当前行弱化：≥3:1
  // —— 浏览态（用户手动滑动阅读，需全清晰）——
  browsingPlayed: string;   // 已播放：≥4.5:1
  browsingUnplayed: string; // 未播放：≥4.5:1
  translateBrowsing: string;// 翻译：≥4.5:1
}
```

##### 三条落地约束（team-lead 指定）

1. **预合成计算只发生在 `ArtworkTint` 内、每封面一次**，不得进入 `drawContent()` / `drawLyricLine()`。沿用 **R-20** 卡点：grep 校验令牌解析与色彩计算不出现在绘制函数内。
   - 状态切换（播放态 ↔ 浏览态）走 `isUserScrolling` 变更 → 触发**一次** `applyColorScheme()`（冷路径），后续每帧仍只读缓存字段。
2. **保留降级路径**：若某张极端封面在 clamp `[·, 0.65]` 内仍算不出满足目标的色值，**回落 3:1 并 `Logger.warn` 记录**（含封面 hash 与目标档位），**不得**为达标把非当前行提亮到破坏聚焦层次。
3. **翻译行不再手写魔数 alpha**：原"alpha 提到 ≈0.70"的结论**保留意图、改由预合成统一计算**，`LrcView` 内不得出现任何 `0.70` 之类的字面量。

##### 🔒 蒙层 clamp：**v1.5 的"上限 0.65 不可协商"已废止**（v1.6）

v1.5 在"背景 = 原始封面"的错误前提下反解出 0.65。**按真实链路，渐变已把封面压暗到 0.28~0.62，合成底色本就足够暗，几乎不需要额外蒙层**：

> ⚠️ **v1.7 再修正：蒙层的约束方不是"当前行"，而是"浏览态 85% 白字"。** v1.6 按不透明字反解得 0.049，pm-planner 指出应按 85% 白字反解——**该修正成立**。

| 反解目标 | 底色 `#3B3B3B` | `#606060` | 中灰 `#474747` | 暗封面 | **`#7D7D7D`（最坏）** |
|---|---:|---:|---:|---:|---:|
| 不透明字（当前行）达 4.5:1 | 0.000 | 0.000 | 0.000 | 0.000 | 0.049 |
| **85% 白字（浏览态）达 4.5:1** | 0.000 | 0.000 | 0.000 | 0.000 | **0.159** |

**修正后的参数**：

- **clamp `[0.0, 0.25]`，自适应输出：典型封面 0.00，最坏 0.159（工程取 **0.18** 留余量）。** 0.65 会把已压暗的画面再压成一团黑，彻底破坏封面氛围感——team-lead 的判断正确，0.65 必须废止。
- **自适应按"浏览态 85% 白字"反解，不是按当前行**——前者才是真正的约束方。
- 现网固定的 0.35 建议**改为自适应**（0~0.18），它对暗封面是过量的（暗封面本就 19.7:1，再压 0.35 纯属牺牲氛围）。
- 下限是否保留 0（而非 0.35）**只按视觉理由**决定，与可达性无关——上表显示可达性在 0 即已满足。

##### 播放态非当前行 alpha：**分阶段取值**（v1.8 裁决，两值并存）

pm-planner 建议 0.60 → 0.65，理由是 0.60 只有 2.88:1。**经复算该数值有误**——在最坏底色（`#7D7D7D` + scrim 0.18 → bg≈102.5）上：

| alpha | 0.55 | **0.60** | 0.65 | 0.70 |
|---|---:|---:|---:|---:|
| 对比度 | 2.95 ❌ | **3.20 ✅** | 3.46 ✅ | 3.74 ✅ |

**0.60 已过 3:1（3.20:1），无需上调。** 且播放态的设计目标是**弱化**以形成聚焦层次，alpha 越低层次越强——在无必要时上调反而削弱效果。

**但该 3.20:1 依赖自适应蒙层已生效**（bg≈102.5）。**本轮只有现网固定的 0.35**（bg≈125）则：0.60 → **2.54:1** ❌ / 0.65 → **2.71:1** ❌ / 0.70 → **2.89:1** ❌ / **需 0.7303 才达 3:1**。

> ⚠️ **v2.0 数值更正**：本表 v1.8 写的 0.65→2.80、0.70→3.07 **均有误**（pm-planner 指出并由脚本复算确认）。正确值见上。0.70 仍**不达标**，此前"0.70 即可"的结论作废。
>
> ⚠️ **措辞更正**：本轮不是"无蒙层"，而是**沿用现网固定的 `rgba(0,0,0,0.35)`（已在合成链路内，bg=125 即含它）**，只是**不做自适应**。后续所有"scrim 0.16 / 0.18"都是**叠加在这 0.35 之上的增量**，不是总蒙层——务必写清，否则 M3 的人会误以为总蒙层只有 0.16。

**分阶段取值（team-lead 裁决，两值并存并标注阶段）**：

| 阶段 | 蒙层 | 取值 | 最坏底色实测 | 落地范围 |
|---|---|---:|---:|---|
| **本轮（缺陷修复）** | 现网固定 0.35，**自适应增量 0**（bg=125） | **0.65** | **2.71:1** ⚠️ | 仅修双层 alpha 结构，自适应蒙层属 M3 |
| **M3（终态）** | 固定 0.35 + 自适应增量 clamp `[0,0.25]`（最坏 0.18，bg=102.5） | **下调至 0.60** | 3.20:1 ✅ | `ArtworkTint` + 自适应蒙层 + 预合成色同批 |

**代码注释要求（强制）**：本轮写入的 `0.65` 必须带注释「**0.65 为无蒙层取值；M3 落地自适应蒙层后可下调至 0.60**」，否则后续无人知道该值是有条件的临时值。

**本轮对最坏底色的处理（team-lead 裁定：维持 0.65，不上调）**：本轮不做蒙层，故**纯白封面 + 白基底 + lifted 位**这一格（2.80:1）**接受降级**。三条理由：

1. 现网 1.39:1 → 2.71:1，**已是一个量级的改善**；
2. 为极端格上调 alpha，正是我们自己告诫过的「再提一点就能解决」陷阱——**病根在缺自适应蒙层，不在参数**；
3. 达标需 0.7303，已逼近当前行的 1.0，会明显削弱聚焦层次。

> ❌ **严禁**为让该格达标而把 0.65 继续上调。正解是 M3 的自适应蒙层。
> 📌 **代码注释要求（强制）**：本轮写入的 `0.65` 必须同时写明两件事——
> ①「0.65 为无蒙层取值；M3 落地自适应蒙层后可下调至 0.60」；
> ②「**禁止为使其达标继续上调 alpha，正确解法是 M3 落地自适应蒙层**」。

##### ⚠️ 验收必须测**渐变最亮位**，不能测平均位

不加自适应蒙层时，85% 白字沿渐变的对比度**跨度极大**：

| 渐变位 | 底色 | 85% 白字 |
|---|---:|---:|
| deep（最暗） | 59 | 8.63:1 ✅ |
| base | 103 | 4.63:1 ✅ |
| **lifted（最亮）** | 125 | **3.47:1** ❌ |

若只在深位或平均位取样，会得出"完全达标"的错误结论。**M3 验收必须在 `lifted` 位（渐变 0.45 处，最亮）取样。**

##### 分档验收口径（**三态**，替换 v1.4 的两态）

| 状态 | 行 | 字号/字重 | 目标 |
|---|---|---|---|
| 播放态 | 当前行 | 22vp bold | **≥4.5:1** |
| 播放态 | 非当前行（有意弱化） | 18vp bold | **≥3:1** |
| **浏览态** | 已播放 / 未播放 | 18vp bold | **≥4.5:1** |
| 任意 | 翻译 当前行 | 14vp bold | **≥4.5:1** |
| 任意 | 翻译 非当前行 | 14vp bold | **≥3:1** |

**关于播放态非当前行的 ≥3:1**：它是**有意弱化的聚焦机制**（Apple Music / Spotify 同样做法），配合 `blur(3~5px)`，属设计意图而非缺陷——但"有意弱化"不等于"可以不可读"，故仍设 3:1 下限。用户需要精读时，进入**浏览态即恢复 4.5:1**，这正是 `isUserScrolling` 已存在的能力，只是此前用错了实现方式（双层 alpha 而非预合成色）。

> ⚠️ **浏览态的设计连带影响**：已播放/未播放两档**都需 ≥4.5:1**，意味着**不能再靠大幅 alpha 差异区分**（那会把一档压到 4.5 以下）。改为**细微明度差**（如 5.2:1 vs 4.6:1）或改用非色彩标记。这点需 蓝绘心 确认视觉方案。

**兜底**：无封面时走 `defaultLyricScheme()`，背景是静态令牌——`ON_MEDIA_DARK.primary` 对 `#000000` 是 21:1，`ON_MEDIA_LIGHT.primary` 对 `#FFFFFF` 是 16.9:1，远超阈值，无需自适应。

#### 3.5.4 验收标准（M3）

- [ ] **`fillStyle` 赋值中不得出现带 alpha 的颜色字面量**（如 `#80ffffff` / `rgba(255,255,255,0.5)`）——这是**唯一**被禁的 alpha 来源（v1.8 措辞收窄）
  - ✅ **不禁止** `context.globalAlpha` 的数值常量（如 `0.65` / `0.85` / `1.0`）——本轮实现正是靠它承载弱化
  - ❌ 禁止的是**两层同时存在**：`fillStyle` 带 α **且** `globalAlpha < 1.0`，两者相乘即 v1.5 发现的根本缺陷
- [ ] `LrcView` 内无 hex 字面量，`applyColorScheme()` 改为读 `lyricScheme`
- [ ] `drawContent()` / `drawLyricLine()` 内**无令牌解析、无色彩计算**（grep `onMediaOf` / `semanticOf`，确认只出现在冷路径）
- [ ] **终态（M3）：预合成色下发时 `context.globalAlpha` 固定为 1.0** —— 颜色本身已含全部衰减，**不得再叠加第二层 alpha**
  - 本轮（无 `ArtworkTint`）降级为「颜色 α=1.0 + 弱化只由 `globalAlpha` 表达」，**同样满足单一来源**，不判失败
- [ ] PanGesture 跟手回归：快速滑动无卡顿、无双重偏移、点击跳转不错行（保留 `handleClick` 的坐标 1:1 映射注释）
- [ ] **三态对比度回归**：取 3 张极端封面（纯白 / 纯黑 / 高饱和彩色），分别在**播放态**与**浏览态**下逐档实测（当前行 4.5 / 非当前行播放态 3.0 / 浏览态 4.5 / 翻译当前行 4.5 / 翻译非当前行 3.0）
- [ ] **取样点必须是渐变 `lifted` 位（最亮，渐变 0.45 处）**——深位可达 8.63:1 而亮位只有 3.47:1，**在深位取样会得出错误结论**
- [ ] 降级路径回归：构造极端封面触发 3:1 回落，确认有 `Logger.warn` 且未破坏聚焦层次
- [ ] 无封面曲目走 `defaultLyricScheme()` 正常显示
- [ ] **🔴 对比度复核必须基于实际渲染的截图取样，不得基于公式计算**（**R-24**，team-lead 升级为**强制口径**）——模糊会削平细笔画峰值亮度，只看 `fillStyle` 色值会**高估**
  - **本轮若无条件做渲染实测，必须写明「未做实测、需 M3/QA 补做」，严禁编数字。** 这与本轮反复纠正的错误同源：宁可留白标注，不可填一个来源不明的数。
- [ ] **真实机主观可读性确认**（M3 验收第 ⑦ 条，已批准）：3 张极端封面 × 2 态（播放态 / 浏览态）；正常室内光；**由非作者本人**判读指定行；能正确读出即通过
  - 定位：**数值达标是必要条件，不是充分条件**。此项与上面的截图取样并列，任一不过即不通过。
- [ ] 本轮写入的 `0.65` 带注释「0.65 为无蒙层取值；M3 落地自适应蒙层后可下调至 0.60」（§3.5.5）

#### 3.5.5 分阶段实现：本轮降级写法 vs 终态（v1.8 新增）

`ArtworkTint`（封面取色 + 预合成）**当前不存在**，是 M1/M3 产物，本轮缺陷修复用不上。因此同一"alpha 单一来源"原则有**两种等价实现**，分阶段切换：

| | **本轮（缺陷修复）** | **终态（M3）** |
|---|---|---|
| `fillStyle` | **完全不透明**（α = 1.0） | 预合成不透明色（`ArtworkTint` 算好） |
| 弱化来源 | `context.globalAlpha`（0.65 / 0.85 / 1.0） | 颜色本身（`globalAlpha` 固定 **1.0**） |
| alpha 层数 | **1 层** ✅ | **1 层** ✅ |
| 每封面自适应 | ❌ 无（固定值） | ✅ 有 |
| 蒙层 | ❌ 无（M3 范围） | ✅ 自适应 clamp `[0, 0.25]` |
| 非当前行 alpha | **0.65** | **0.60** |

**为什么两种都合规**：二者最终落在画布上的都是「不透明色 × 唯一一个衰减系数」，只是系数挂在 `globalAlpha` 还是挂在颜色里。**被禁的从来不是某一层，而是两层并存。**

**切换触发条件（M3）**：`ArtworkTint` 落地时，把 `0.65` 改为 `0.60`、把 `globalAlpha` 固定为 1.0、颜色源切到预合成色。三处必须同批，不可分开。

> ⚠️ 终态下若仍保留 `globalAlpha` 承载衰减，后续给歌词加光晕/描边时 `globalAlpha` 会**二次作用于阴影**，导致阴影比字更淡。这是终态坚持预合成的实际工程理由。

#### 3.5.6 blur 半径：从"抹除"拉回"柔化"（v1.8 新增）

现网 `blur(5px)` / `blur(3px)` 作用在 `mNormalTextSize` 上。**字号基准已实测更正（v2.0）**：`LrcView.ets:153` `mNormalTextSize = 18`（当前行 `mCurrentTextSize = 22`，L165）。此前的 15vp 是记忆值，**不是实测**，已作废。

| 半径 | **占 18vp 的比例** | 观感 |
|---:|---:|---|
| 5px | **27.8%** | 笔画结构被瓦解，**"抹除"** |
| 3px | 16.7% | 偏重 |
| **2px** | **11.1%** | **"柔化"** ✅ |
| **1.5px** | 8.3% | 轻微柔化 ✅ |

**裁决：下调至 2px / 1.5px**（原 5px → 2px，原 3px → 1.5px）。保留模糊作为聚焦手段，只纠正强度。

**但比例判据的参照系需要修正**（架构侧补充，不影响裁决结论）：

team-lead 问「哪个主流音乐 App 用到了字号 1/3 的模糊半径」——答案是：**一个都没有，因为它们根本不用模糊**。Apple Music 与 Spotify 的歌词层次**完全由不透明度 + 字重 + 字号**表达，模糊半径为 **0**。所以真实参照系不是「27.8% vs 11.1%」，而是「27.8% vs **0%**」。

因此：
- **2px / 1.5px 是合理的折中**——它保留了本项目"柔化"的差异化设计意图，同时把强度拉回可用区间。**架构侧支持该取值。**
- 但若 M3 实测发现模糊仍在拖低可读性，正确的下一步是**归零并改用不透明度 + 字重差**表达层次，而不是继续在 1~2px 间微调。

> 🔒 **上一句为闸门条款，team-lead 已确认保留**：它防的是"后来者在 1~2px 之间做无意义微调"。本条同时暴露一个前提性疏漏——**我们连"要不要模糊"都没验证过就默认它该存在**。凡后续再动 blur 参数，先回到"是否该有模糊"这层，而非直接调半径。

> ⚠️ **新增风险 R-24**：模糊会削平细笔画的峰值亮度，**理论色值算出的对比度 ≠ 渲染后实测对比度**（小字号尤甚）。故 §3.5.4 要求**截图取样实测**；只按 `fillStyle` 色值计算会高估，得出"已达标"的错误结论。

#### 3.5.7 🔴 本轮硬缺口与 A/B 方案（v2.0 新增，脚本复算）

**已验证的对比度矩阵**（行 = `globalAlpha`，列 = 合成底色；脚本复算，非估算）：

| alpha | 典型 `#5F5F5F`(95) | 典型 +scrim.16(79.8) | **最坏 `#7D7D7D`(125)** | 最坏 +scrim.16(105) |
|---:|---:|---:|---:|---:|
| 0.52 | 3.018 | 3.518 | **2.277** ❌ | **2.737** ❌ |
| 0.60 | 3.472 | 4.119 | 2.537 ❌ | 3.115 ✅ |
| **0.65** | 3.777 | 4.526 | **2.709** ❌ | **3.367** ✅ |
| 0.73 | 4.299 | 5.228 | 2.999 ⚠️ | 3.796 ✅ |
| 0.76 | 4.506 | 5.508 | 3.112 ❌(需4.5) | 3.965 ❌(需4.5) |
| **0.85** | 5.164 | 6.404 | 3.469 ❌(需4.5) | **4.501** ✅ |
| 1.00 | 6.385 | 8.089 | **4.116**（数学上限） | 5.490 |

**各底色下所需最小 alpha（脚本求解）**：

| 底色 | 达 3:1 | 达 4.5:1 |
|---|---:|---:|
| 典型 `#5F5F5F`(95) | 0.517 | 0.759 |
| 最坏 `#7D7D7D`(125) | **0.730** | **不可达**（不透明字上限 4.116） |
| 最坏 + scrim 0.16(105) | **0.576** | **0.850** |

**硬缺口**：本轮（只有固定 0.35）下，最坏底色处 **播放态达 3:1 需 α=0.730**；**浏览态 4.5:1 任何 α 都不可达**（不透明字上限 4.116:1，是数学上限，只能加深底色）。

**两个选项**：

| | 做法 | 结果 |
|---|---|---|
| **A（架构侧推荐）** | 本轮加**固定常量蒙层 0.16**（叠加在现网 0.35 之上，等效总量 0.454） | α=0.65 → **3.367 ✅**；α=0.85 → **4.501 ✅**；典型底色 4.526 / 6.404 ✅ |
| **B** | 播放态提到 0.73、浏览态 4.5 登记为已知缺口留 M3 补 | 播放态勉强 2.999 ⚠️；**浏览态在最坏底色上仍不可读** |

**架构侧推荐 A**，三条理由：

1. **B 修不掉本缺陷的核心场景**。浏览态正是"用户主动停下来读歌词"的状态，是本次缺陷修复**最主要**要救的场景；在最坏底色上留着 4.5:1 不可达，等于这个场景没修。
2. **A 的成本是一行常量**，且对暗封面几乎无副作用：暗封面合成底色本就 ≈11/255，加 0.16 后 ≈9.2，**肉眼不可辨**；只有亮封面被压暗，而那正是需要的。
3. **A 严格落在 M3 的取值包络内**：本轮总量 0.454 < M3 最坏总量 0.467（0.35 + 0.18），**M3 落地时不会反弹变亮**，无视觉回归。

**最小改法**：不必新增图层，把现网 `PlayerInfoComponent` 的 `rgba(0,0,0,0.35)` 改为 `rgba(0,0,0,0.454)` 即可（1-(1-0.35)(1-0.16)=0.454）。⚠️ 前提：确认该 `Stack()` 内无其它兄弟节点依赖此层——改动前必须 grep 确认。

**`artworkScrim` 接口设计（pm-planner 要求：本轮常量、M3 自适应，接口不改第二次）**：

```arkts
// 已规避红线 3：具名常量、无 any / 无解构 / 无内联对象字面量类型
/** 自适应蒙层的取值区间。**注意：这是叠加在现网固定 0.35 之上的「增量」，不是总蒙层。** */
export const ARTWORK_SCRIM_MIN: number = 0.0;
export const ARTWORK_SCRIM_MAX: number = 0.25;
/** 本轮固定增量：使最坏底色（#7D7D7D → 105）下 α=0.85 恰好达 4.5:1。 */
export const ARTWORK_SCRIM_CONST: number = 0.16;

/**
 * 封面蒙层增量。
 * @param liftedBgLuma 渐变 **lifted 位（最亮，渐变 0.45 处）** 的合成底色亮度 0-255。
 *                     必须在最亮位取样——深位可达 8.63:1 而亮位只有 3.47:1（§3.5.3）。
 * @returns 蒙层增量，取值 [ARTWORK_SCRIM_MIN, ARTWORK_SCRIM_MAX]
 *
 * 本轮：直接返回常量。M3：按「浏览态 85% 白字达 4.5:1」反解，函数签名不变。
 */
export function artworkScrim(liftedBgLuma: number): number {
  return ARTWORK_SCRIM_CONST;
  // TODO(M3): 反解实现 —— 解 s 使 contrast(0.85*255+0.15*(L*(1-s)), L*(1-s)) >= 4.5，
  //          再 clamp 到 [MIN, MAX]。签名与本轮完全一致，调用方零改动。
}
```

> ✅ **接口稳定性论证**：本轮与 M3 的**唯一差异是函数体**，签名、入参语义（lifted 位亮度）、返回区间三者不变。M3 切换时调用方零改动——这正是"接口不改第二次"的要求。

---

## 4. 迁移路径

### 4.1 总原则

1. **每个阶段结束都必须可编译、可运行、主题切换正常**——不做"编译不过的中间态"。
2. **先接通真源，再迁值**：P1 让 22 个老文件"零改动"拿到新令牌，把风险集中在一个文件里。
3. **值等价优先，视觉重构押后**：P1/P2 追求零视觉变化，P3 才动表面层级。
4. **保留兼容垫片，反对一次性重写**。

### 4.2 阶段划分

| 阶段 | 目标 | 改动范围 | 预估 | 完成判据（DoD） |
|---|---|---|---|---|
| **P0 地基** | 新增 `tokens/` 6 个文件（`LumioComponents.ets` 可延后） | 纯新增，0 个业务文件 | 0.5d | 编译通过；无任何现有文件 import 变化；`LumioColor/LumioScale/LumioEffect/LumioMotionSpec` 四个文件 `import` 语句数为 0 |
| **P1 真源收敛** | `ColorTokens` 的 7 字段改为**由 `LumioSemantic` 派生**；`ThemeManager.apple()` 返回 `LumioSemantic`；`getColors()` 标 `@deprecated` | 仅 `ThemeManager.ets` | 1d | 22 个业务文件**零改动**；全站颜色值等价（唯一差异：light `secondaryBg` `#FAFAFA → #F2F2F7`，肉眼不可辨）；主题切换正常 |
| **P2 硬编码清零** | 按 §4.4 映射表替换 ≈160 处 hex/rgba，分 3 批 | 24 个业务文件 | 2–3d | `grep -E '#[0-9A-Fa-f]{6}\|rgba\('` 在 `pages/`、`components/`、`lyric/`、`widget/` 下**仅剩令牌定义文件**命中 |
| **P2c（歌词专项）** | `LrcView` Canvas 令牌注入（§3.5）+ `onMedia*` 迁出为独立接口（§2.4.1） | `lyric/` + `tokens/` | 0.5d | PanGesture 跟手无回归；3 张极端封面（纯白/纯黑/高饱和）歌词可读 |
| **P3 组件层 + 表面层级** | 新增 `LumioComponents.ets`（导出 `@Builder`）；抽 `SongRow` 消除 **5 处**复制（见 §4.7）；页面底改 grouped gray + 白卡片（`surfaceRaised` 换值） | 组件层新增 + 主要列表页 | 3.5d | **5 处**列表复制收敛为 1；`surfaceRaised` light 由 `#F2F2F7` → `#FFFFFF` 与页面底改造**同批上线** |
| **P4 尺度与动效统一** | 全量替换 radius/space/type；动效接入 `LumioMotion`；`DesignSystem.ets` 退化为 re-export 垫片 | 全仓 | 2d | `DesignSystem.ets` 只剩 re-export；`reduceMotion` 全量生效；无 `Curve.EaseOut` 直写 |
| **P5 资源与卡片** | ① `dark/element/color.json` 全量镜像；② `WidgetCard` 改 import 令牌层（删 `getCardColors()`）；③ **修复卡片恒浅色缺陷**：抽 `resolveIsDark()` + `FormAbility` 补 `isDark` + 主应用推送（§3.4） | resources + widget + ability + `ThemeManager` | 1.5d | 深色下无组件回退浅色；卡片主题跟随应用且深浅切换实时生效；三项主题回归通过 |

### 4.3 ThemeManager 与 DesignSystem 的合并策略

**裁决（AD-3）：保留 `ColorTokens` 作派生垫片，保留 `DesignSystem.ets` 作 re-export 垫片，两者都在 P4/P5 后再考虑删除。**

| 方案 | 取舍 | 结论 |
|---|---|---|
| A. 一次性重写全部页面 | 24 个文件同时改，回归面积不可控；中途编译不过 | ❌ 否决 |
| B. 保留 `ColorTokens` 但改为**派生** | ~40 行垫片成本；22 个文件零改动；可灰度、可回滚 | ✅ **推荐** |
| C. 立即删除 `DesignSystem.ets` | 5 个文件 import 断裂，与 P2 冲突 | ❌ 否决（P4 前保留 re-export） |

P1 的垫片写法（骨架）：

```arkts
// ThemeManager.ets（P1 后的形态）
import { LumioSemantic, semanticOf } from '../common/utils/DesignSystem'; // 或 tokens/LumioColor

/** @deprecated 兼容垫片：字段名保留，值改为由 LumioSemantic 派生。P4 后随业务迁移完成移除。 */
export interface ColorTokens {
  bg: string; secondaryBg: string; cardBg: string;
  primaryText: string; secondaryText: string; separator: string; accent: string;
}

// 由新令牌派生（值等价，唯一差异：light secondaryBg #FAFAFA → #F2F2F7）
const LIGHT_TOKENS: ColorTokens = {
  bg: LIGHT_SEMANTIC.background,
  secondaryBg: LIGHT_SEMANTIC.backgroundSecondary,
  cardBg: LIGHT_SEMANTIC.surfaceRaised,
  primaryText: LIGHT_SEMANTIC.label,
  secondaryText: LIGHT_SEMANTIC.labelSecondary,
  separator: LIGHT_SEMANTIC.separator,
  accent: LIGHT_SEMANTIC.accent
};
const DARK_TOKENS: ColorTokens = { /* 同法由 DARK_SEMANTIC 派生 */ };

export class ThemeManager {
  static get lightColors(): ColorTokens { return LIGHT_TOKENS; }   // 保留，供现有响应式方法用
  static get darkColors(): ColorTokens { return DARK_TOKENS; }
  static apple(): LumioSemantic { return semanticOf(ThemeManager.isDark()); }
  /** @deprecated 非响应式，禁止在新代码使用。仅保留给极少数非 UI 场景。 */
  static getColors(): ColorTokens { return ThemeManager.isDark() ? DARK_TOKENS : LIGHT_TOKENS; }
}
```

> 说明：`static get` 出现在**普通类**（非 `@Component`）上是安全的——红线 1 只约束 `@Component` / `@CustomDialog`。现网 22 个文件的 `this.isDark ? darkColors : lightColors` 写法可以原样保留到 P2。

### 4.4 硬编码 hex → 语义令牌映射表

> 图例：🟢 值等价（零视觉变化） · 🟡 微变（同一语义，取值收敛） · 🔴 语义修正（行为/配色改变，需设计确认）

#### A. 品牌色系（≈67 处，17 个文件）

| 现网值 | 处数 | 典型位置 | → 新令牌 | 变化 |
|---|---:|---|---|---|
| `#FA2759` | ≈40 | `AddToPlaylistSheet:136/206/209`、`ControlAreaComponent:432`、`OnboardingSheet:43/133`、`SettingsSubPageBodies:334/373/408/537/596/652`、`QualityBadge:32`、`FolderBrowse:108/135`、`Favorites:195/207/234/308`、`LocalLibrary:392/523/527`、`Mine:159/203`、`PlaylistDetail:248/252/362/394/514/537`、`Playlists:259/263/328/367/393/497/512/566/668`、`Settings:77`、`SettingsCategory:456/460/484/488` | `accent` | 🟢 |
| `const ACCENT = '#FA2759'` | 2 | `Layout.ets:32`、`LocalLibrary.ets:35` | **删除**，改用 `accent` 令牌 | 🟢 |
| `rgba(250,39,89,0.05)` | 2 | `LocalLibrary:425`、`Favorites:241` | `fillAccentSubtle` | 🟢 |
| `rgba(250,39,89,0.08)` | 1 | `LocalLibrary:581` | `fillAccentSubtle` | 🟡 收敛到 0.05 |
| `rgba(250,39,89,0.10)` | 6 | `SettingsSubPageBodies:219/335`、`Favorites:309`、`FolderBrowse:113`、`PlaylistDetail:515`、`Playlists:372/498` | `fillAccentSoft` | 🟢 |
| `rgba(250,39,89,0.20)` | 1 | `About:152` | `borderAccent` | 🟢 |
| `rgba(250,39,89,0.30)` | 1 | `LocalLibrary:377` | `fillAccentMuted` | 🟢 |
| `rgba(250,39,89,0.35)` | 1 | `Layout:287`（投影） | `elevation.accent` | 🟢 |
| `rgba(250,39,89,0.25)` | 1 | `Splash:53`（投影） | `elevation.accent` | 🟡 收敛到 0.35 |

#### B. 中性色 / 表面 / 文本

| 现网值 | 处数 | 典型位置 | → 新令牌 | 变化 |
|---|---:|---|---|---|
| `#FFFFFF` | ≈8 | `AddToPlaylistSheet:135`、`OnboardingSheet:69/132`、`PlaylistDetail:393/528/531`、`Playlists:301/507/565/667`、`Layout:278/312` | 品牌底上的文字 → `onAccent`；其余 → `labelOnAccent` | 🟢 |
| `#1C1C1E` | ≈4 | `Splash:61`、`ThemeManager:47/129` | `label`（light）/ `surfaceRaised`（dark） | 🟢 |
| `#000000` | 2 | `Splash:71`、`ThemeManager:54` | `background`（dark） | 🟢 |
| `#8E8E93` | 3 | `ThemeManager:48`、`LIGHT_APPLE` 系列 | **`labelTertiary`**（light，3.26:1） | 🟡 层级下沉，见 §2.13 |
| `#98989F` | 2 | `ThemeManager:58`、`WidgetCard:92` | `labelSecondary`（dark） | 🟢 |
| `#636366` | 3 | `Favorites:333`、`Playlists:560`、`PlaylistDetail:596`（空态说明等**指导性**文案，13fp） | **`labelSecondary`**（不是 `labelTertiary`） | 🔴 **覆盖 `design_tokens.md` F-14**：按 F-14 改 `secondaryText` 会把 5.99:1 降到 3.26:1，反而降低可读性。理由见 §2.13.2 |
| `#E5E5EA` | 1 | `ThemeManager:49` | `separatorOpaque`（light）/ `gray100` | 🟢 |
| `#2C2C2E` | 1 | `ThemeManager:59` | `separatorOpaque`（dark） | 🟢 |
| `#FAFAFA` | 1 | `ThemeManager:45` | `backgroundSecondary`（light） | 🟡 `#FAFAFA → #F2F2F7` |
| `#F2F2F7` | 3 | `WidgetCard:100`、`ThemeManager:46` | `surfaceRaised`（light） | 🟢 |
| `rgba(120,120,128,0.12)` | 2 | `Mine:112`、`UI设计系统.md §8.3` | `fillTertiary` | 🟢 |

#### C. 系统色 / 状态色（AD-0 收紧后的落点，严格按 §2.12 三级优先序）

> **口径**：先判是否**装饰性**。装饰性 → 取消染色，走内容取色或中性；非装饰（携带语义）→ 才允许用状态色。

| 现网值 | 处数 | 位置 | 装饰性? | → 新令牌 | 变化 |
|---|---:|---|---|---|---|
| `#34C759` | 3 | `Mine:171`（收藏）、`SettingsCategory:393`（自动下一首）、`OnboardingSheet:46` | ✅ 装饰 | 收藏计数徽章 → `accent`；设置项图标 → `labelSecondary`；引导页 → `success` 或中性 | 🔴 |
| `#FF9500` | 6 | `Mine:183/227`、`Settings:72/75`、`SettingsCategory:397/445/449/492`、`OnboardingSheet:44` | ✅ 装饰（除"清除缓存/清空历史"） | 破坏性操作 → `danger`；其余设置项图标 → `labelSecondary` | 🔴 |
| `#FF9500`（`PlayHistory:188/200/291`） | 3 | 表示"正在播放" | ❌ 语义 | **`accent`**（与其他页面的"正在播放"统一） | 🔴 一致性修复 |
| `#007AFF` | 3 | `Mine:239`、`Settings:74`、`SettingsCategory:405/433` | ✅ 装饰 | `labelSecondary`（设置项图标） | 🟡 |
| `#5856D6` | 3 | `Mine:215/276`（歌单/常听）、`OnboardingSheet:45` | ✅ 装饰 | **封面取色 `ArtworkTint`**；无封面 → `fillTertiary` + 单色图标 | 🔴 |
| `#5E5CE6` | 2 | `Settings:73`、`SettingsCategory:417` | ✅ 装饰 | `labelSecondary` | 🟡 |
| `#FFCC00` | 1 | `Settings:76`、`SettingsCategory:472` | ✅ 装饰 | `labelSecondary` | 🟡 |
| `#FF3B30` / `#FF453A` | 0（仅令牌定义） | `DesignSystem` | ❌ 语义 | `danger`（保留给破坏性操作） | 🟢 |

**判定原则（写进 Code Review 检查表）**：

1. **破坏性操作**（删除 / 清空 / 清除 / 移除）→ `danger`
2. **成功 / 已完成 / 已启用** → `success` 或 `accent`
3. **提醒 / 存储 / 通知** → `warning`
4. **功能入口 / 设置项 / 分类图标** → **中性 `labelSecondary` + 单色图标**，**不得逐项染色**
5. **歌单 / 专辑 / 文件夹 / 封面** → **内容取色 `ArtworkTint`**；无封面回落 `fillTertiary`
6. **引导页（Onboarding）** 允许使用状态色做概念区分（它是"介绍功能"的语义场景，非列表分类），但需设计确认

#### D. 特效类（阴影 / 蒙层 / 毛玻璃）

| 现网值 | 处数 | 位置 | → 新令牌 |
|---|---:|---|---|
| `rgba(0,0,0,0.10)` r8 y2 | 4 | `Favorites:186`、`Playlists:275`、`PlayHistory:179`、`PlaylistDetail:264` | `elevation.low`（light α0.10） |
| `rgba(0,0,0,0.10/0.60)` r12 y4 | 1 | `LocalLibrary:542` | `elevation.mid` |
| `rgba(0,0,0,0.18)` r6 y2 | 1 | `CoverImageView:89` | `elevation.cover` |
| `rgba(0,0,0,0.18/0.45)` | 1 | `Layout:361` | `elevation.high` / `scrim` |
| `rgba(0,0,0,0.20)` | 1 | `Layout:259` | `elevation.high`（light α0.18→0.20 收敛） |
| `rgba(0,0,0,0.35)` | 2 | `Layout:318`、`PlayerInfoComponent:137` | `scrim` / `onMediaScrim` |
| `rgba(255,255,255,0.08)` / `rgba(0,0,0,0.06)` | 3 | `Layout:367/386` | `borderSubtle`（dark / light） |
| `rgba(255,255,255,0.16)` | 1 | `ControlAreaComponent:179` | `onMediaControlBg` |
| `rgba(255,255,255,0.62)` / `rgba(28,28,30,0.62)` | 2 | `DesignSystem:175/180` | `glass.regular.fill` |

#### E. 歌词 / 媒体覆盖层（LrcView，13 处）—— **注入方案见 §3.5**

| 现网值 | 变量 | → `LumioOnMedia` 字段 |
|---|---|---|
| `#80ffffff` (dark) / `#4d000000` (light) | `mNormalTextColor` | `secondary` |
| `#FFFFFF` (dark) / `#000000` (light) | `mCurrentTextColor` | `primary` |
| `#80ffffff` / `#66000000` | `mTranslateColorNormal` | `tertiary` |
| `#d6ffffff` / `#99000000` | `mTranslateColorCurrent` | `emphasis` |
| `#18BBFC` | `starsColor` | ⚠️ 疑似废弃的星标色 → 建议删除；若保留则 `info` |

**注入纪律（三条，缺一不可）**：

1. 取值用 **`onMediaOf(backgroundIsDark)`**，**禁止**用 `semanticOf(isDark)` —— 见 §2.4.1（两个不同维度）。
2. 解析只发生在 `applyColorScheme()`（冷路径），**禁止**进 `drawContent()`（每帧热路径）；结果缓存到私有字段。
3. 有封面时由 `ArtworkTint` 注入 **`lyricScheme`**（含自适应蒙层）；**无封面**时才走 `defaultLyricScheme(backgroundIsDark)`。

> 架构收益：`LrcView` 的取色从"4 个私有字段 + 8 行 if/else 硬编码"变成"父组件注入一套已验证对比度的配色方案"，且**语义从"白字/黑字"变成"叠在封面上的主/次文本"**——这才是对的抽象。

#### F. 卡片（WidgetCard，18 处）

| 现网值 | → 新令牌 |
|---|---|
| `cardBg: '#1C1C1E'` / `'#F2F2F7'` | `semanticOf(isDark).surfaceRaised` |
| `titleText` / `artistText` / `iconColor` | `label` / `labelSecondary` |
| `secondaryBtnBg: '#33FFFFFF'` / `'#33000000'` | `fillSecondary` |
| `playBtnBg: '#FA2759'` | `accent` |
| `playIconColor: '#FFFFFF'` | `onAccent` |

→ P5 后 `WidgetCard.ets:90-106` 整段取色表**删除**。

### 4.5 逐文件影响面与迁移顺序

| 序 | 文件 | 硬编码处数 | 阶段 | 说明 / 风险 |
|---|---|---:|---|---|
| 1 | `utils/ThemeManager.ets` | 18（令牌定义） | **P1** | 真源切换点，**必须最先**，改动集中 |
| 2 | `common/utils/DesignSystem.ets` | 56（令牌定义） | P4 | 退化为 re-export；`Radius`/`Motion`/`Glass` 迁走 |
| 3 | `widget/pages/WidgetCard.ets` | 18 | P5 | 跨进程，需真机卡片验证（R-6）；**同时修复卡片恒浅色缺陷**（R-15 / §3.4） |
| 4 | `lyric/LrcView.ets` | 13 | P2 | 语义重构（`onMedia*`），建议独立 PR |
| 5 | `pages/Playlists.ets` | 17 | P2 | 品牌色 + 阴影 |
| 6 | `pages/LocalLibrary.ets` | 9 | P3 | `SongRow` 抽取（5 处之一，§4.7） |
| 7 | `pages/Mine.ets` | 9 | P2b | 含 4 处分类色（🔴），按 §2.12.3 逐项定口径 |
| 8 | `pages/SettingsCategory.ets` | 13 | P2b | 含 8 处分类色（🔴），按 §2.12.3 定口径 |
| 8b | `formability/FormAbility.ets` | 0 | **P5** | **新增**：`onAddForm` 补 `isDark`、`onUpdateForm` 自愈重推、`onConfigurationUpdate` 全量推送（§3.4.3） |
| 8c | `utils/ThemeManager.ets`（二次） | 0 | **P5** | **改为调用 `resolveIsDark()`** + 主题变更后主动 `updateForm`；单点改动，需三项回归（R-19） |
| 9 | `pages/PlaylistDetail.ets` | 12 | P3 | 列表行抽取 |
| 10 | `pages/Layout.ets` | 10 | P3 | 悬浮胶囊 + 蒙层 + `ACCENT` 常量删除 |
| 11 | `components/SettingsSubPageBodies.ets` | 8 | P2 | 品牌色为主 |
| 12 | `pages/Favorites.ets` | 8 | P3 | 列表行抽取 |
| 13 | `components/OnboardingSheet.ets` | 7 | P2 | 含分类色（🔴） |
| 14 | `pages/PlayHistory.ets` | 6 | P2 | **橙色高亮 → accent（🔴 一致性修复）** |
| 15 | `pages/Settings.ets` | 6 | P2 | 分类色（🔴） |
| 16 | `components/PlayerInfoComponent.ets` | 5 | P3 | 动态封面取色（`imageColor`），保留动态计算，仅基线色走令牌 |
| 17 | `components/ControlAreaComponent.ets` | 2 | P2 | 已引 `DesignSystem`，最易 |
| 18 | `pages/FolderBrowse.ets` | 3 | P2 + **P3** | **第 5 处 `SongRow` 复制**（`songRow()` @153），此前遗漏，必须纳入 P3 |
| 19 | `pages/Splash.ets` | 3 | P2 | — |
| 20 | `components/CoverImageView.ets` | 1 | P2 | 已引 `DesignSystem` |
| 21 | `components/QualityBadge.ets` | 2 | P4 | 归入组件层 `LumioBadge` |
| 22 | `components/AddToPlaylistSheet.ets` | 4 | P2 | — |
| 23 | `pages/About.ets` | 1 | P2 | — |
| 24 | `common/utils/ColorConversion.ets` | 2 | P5 | 系统栏内容色，随资源层对齐 |

**建议合并为 6 个 PR**：`P1-真源` / `P2a-品牌色` / `P2b-状态色(按 §2.12 口径)` / `P2c-特效与歌词` / `P3-组件层与表面层级` / `P4-尺度动效` / `P5-资源与卡片`。

### 4.6 表面层级改造纪律（R-12 强制约束）

> **操作纪律（强制，不可协商）**
>
> 1. **表面层级改造必须「整页提交」，禁止跨页分批。** 一个 PR 必须同时完成：该页所有容器的 `background` / `surfaceGrouped` / `surfaceRaised` 赋值 + 该页全部卡片底色 + 该页全部分隔线。
> 2. **禁止只改卡片底色不改页面底**（或反之）。二者的值必须成对切换，否则出现"白底白卡片 / 灰底灰卡片"，是最严重的视觉缺陷且测试容易漏。
> 3. **禁止一次 PR 混做多页**。P3 预计 6–8 个 PR，每页一个。
> 4. **每个 PR 必须附浅色 + 深色两张截图**，且截图中必须同时出现「页面底」「卡片」「分隔线」三种元素，供 review 确认层级可辨。

#### 表面层级：改造前 → 改造后对照

**改造前（现状）**：页面底与卡片底是**反的**——页面纯白、卡片浅灰，层级靠"卡片比页面深一档"表达。

| 页面 | 改造前：页面底 | 改造前：卡片/列表项底 | 改造后：页面底 | 改造后：卡片/列表项底 |
|---|---|---|---|---|
| `LocalLibrary` | `bg` `#FFFFFF` | `cardBg` `#F2F2F7` | `surfaceGrouped` `#F2F2F7` | `surfaceGroupedContent` `#FFFFFF` |
| `Favorites` | `bg` `#FFFFFF` | `cardBg` `#F2F2F7` | `surfaceGrouped` `#F2F2F7` | `surfaceGroupedContent` `#FFFFFF` |
| `Playlists` | `bg` `#FFFFFF` | `cardBg` `#F2F2F7` | `surfaceGrouped` `#F2F2F7` | `surfaceGroupedContent` `#FFFFFF` |
| `PlaylistDetail` | `bg` `#FFFFFF` | `cardBg` `#F2F2F7` | `surfaceGrouped` `#F2F2F7` | `surfaceGroupedContent` `#FFFFFF` |
| `PlayHistory` | `bg` `#FFFFFF` | `cardBg` `#F2F2F7` | `surfaceGrouped` `#F2F2F7` | `surfaceGroupedContent` `#FFFFFF` |
| `Mine` | `bg` `#FFFFFF` | `cardBg` `#F2F2F7` | `surfaceGrouped` `#F2F2F7` | `surfaceGroupedContent` `#FFFFFF` |
| `Settings` / `SettingsCategory` / `SettingsSubPageBodies` | `bg` `#FFFFFF` | `cardBg` `#F2F2F7` | `surfaceGrouped` `#F2F2F7` | `surfaceGroupedContent` `#FFFFFF` |
| `FolderBrowse` / `ManageSongs` / `DuplicateSongs` | `bg` `#FFFFFF` | `cardBg` `#F2F2F7` | `surfaceGrouped` `#F2F2F7` | `surfaceGroupedContent` `#FFFFFF` |

**深色下两者都是"页面 #000000 / 卡片 #1C1C1E"**，改造前后**值不变**——这正是深色模式当前观感正常、浅色模式显得"平"的原因。

#### 机制修正：逐页「换指向」，**不全局改令牌值**

> ⚠️ **v1.1 此处存在内部矛盾，v1.2 修正**：原文写"P3 一次性切换 `surfaceRaised` 的 light 值"，但**改令牌值是全局生效的**，一旦切换，尚未迁移的页面会立刻变成"灰底浅灰卡片"——这与"整页提交、禁止跨页分批"的纪律自相矛盾。

**正确机制：令牌值全程不变，逐页改变「引用哪个令牌」。**

| 元素 | 改造前引用 | 改造后引用 | light 值变化 | dark 值变化 |
|---|---|---|---|---|
| 页面底 | `background`（`#FFFFFF`） | **`surfaceGrouped`**（`#F2F2F7`） | 白 → 浅灰 | `#000000` → `#000000`（不变） |
| 卡片 / 列表项底 | `surfaceRaised`（`#F2F2F7`） | **`surfaceGroupedContent`**（`#FFFFFF`） | 浅灰 → 白 | `#1C1C1E` → `#1C1C1E`（不变） |
| 分隔线 | `separator` | `separator`（不变） | — | — |

- **两个令牌的值在 P3 全程保持不变**，因此未迁移的页面**不受影响**——R-12 的爆炸半径从"全仓"收缩到"单个 PR"。
- 每个页面 PR 内**同时**完成"页面底换指向" + "卡片底换指向"，二者配对即等于"页面与卡片交换配色"，原子生效。
- 全部页面迁移完成后，`surfaceRaised` 无引用方，作为**清理步骤**废弃（或令其等于 `surfaceGroupedContent`）——此时无任何视觉影响。

> **这是本次复核最有价值的一处修正**：把"改值"换成"换指向"，使 R-12 从**全局高风险**降级为**单 PR 可控风险**。

#### 施工自检（每页 PR 都要过）

- [ ] 页面根节点 `backgroundColor` 已改为 `surfaceGrouped`
- [ ] 该页**所有**卡片/列表项底色已改为 `surfaceGroupedContent`（无遗漏、无残留 `surfaceRaised`）
- [ ] 浅色下可清晰分辨：页面底浅灰、卡片纯白、分隔线可见
- [ ] 深色下可清晰分辨：页面底纯黑、卡片深灰、分隔线可见
- [ ] 无"卡片与页面同色"的元素

### 4.7 `SongRow` 抽取：5 处复制（实测修正）

> 修正：`design_tokens.md` F-09 记"三处复制"，pm-planner 补为四处，**实测实为 5 处**。判定依据不是 `getThemeColors()` 命中数，而是 **`buildSongMenu` / 歌曲行构建函数的存在**：

| # | 文件 | 证据 | 差异点 |
|---|---|---|---|
| 1 | `pages/LocalLibrary.ets` | `buildSongMenu(song)` @446 | 含"从设备删除" |
| 2 | `pages/Favorites.ets` | `buildSongMenu(song)` @111 | 含"取消收藏" |
| 3 | `pages/PlaylistDetail.ets` | `buildSongMenu(song, index)` @171 | **多一个 `index` 参数**，含"从歌单移除" |
| 4 | `pages/PlayHistory.ets` | `buildSongMenu(song)` @104 | 含"从历史移除"；且"正在播放"用橙色（§4.4-C 一致性修复） |
| 5 | `pages/FolderBrowse.ets` | `private songRow(song)` @153 | 文件夹场景的简化行 |

> ⚠️ 第 5 处 `FolderBrowse` 是**我和 pm-planner 都漏掉的**，请 pm-planner 在规划文档的 M2/M4 里补上，否则会剩一处漏网。

#### 4.7.1 接口设计：菜单项数组注入（避免布尔参数爆炸）

`PlaylistDetail` 需要 `index`（"从歌单移除"）、`Favorites` 需要"取消收藏"语义差异——若用 `showRemoveFromPlaylist?: boolean` 这类开关，5 个页面会迅速堆出 8+ 个布尔参数。**改用数据驱动的菜单项注入**：

```arkts
// components/SongRow.ets —— 已规避红线 3（具名接口 + 具名函数类型别名，无 any / 无解构）

/** 一条上下文菜单动作（纯数据，不含 UI）。 */
export interface SongMenuAction {
  id: string;              // 稳定标识，回调据此分发
  label: string;           // 文案
  destructive: boolean;    // true → 用 danger 色（删除/移除/取消收藏）
  enabled: boolean;        // 置灰态
}

/** 菜单回调类型（具名别名，避免行内函数类型注解）。 */
export type SongMenuHandler = (id: string, song: SongItem, index: number) => void;

/** 行配置：页面决定"有哪些菜单项"，组件只负责渲染。 */
export interface SongRowConfig {
  song: SongItem;
  index: number;                 // 透传给回调，PlaylistDetail 的「移除」需要
  selected: boolean;             // 是否正在播放
  menuActions: SongMenuAction[]; // ← 差异化在这里注入
  showQualityBadge: boolean;
  reduceMotion: boolean;         // 入场错峰降级
}

@Component
export struct SongRow {
  @Prop config: SongRowConfig;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('currentBreakpoint') bp: string = 'sm';
  onMenuAction: SongMenuHandler = (): void => {};   // 具名类型，默认值防空

  // ✅ 普通方法，非 get 访问器（已规避红线 1）
  private c(): LumioSemantic { return LumioTheme.semantic(this.isDark); }

  @Builder
  private menuBuilder() {
    // ✅ @Builder 首条语句是 UI 组件（已规避红线 2）
    Menu() {
      ForEach(this.config.menuActions, (action: SongMenuAction) => {
        MenuItem({ content: action.label })
          .fontColor(action.destructive ? this.c().danger : this.c().label)
          .enabled(action.enabled)
          .onClick(() => {
            this.onMenuAction(action.id, this.config.song, this.config.index);
          })
      }, (action: SongMenuAction) => action.id)
    }
  }

  build() {
    Row() { /* 封面 + 标题 + 歌手 + QualityBadge */ }
      .backgroundColor(this.config.selected ? this.c().fillAccentSubtle : this.c().surfaceGroupedContent)
      .bindContextMenu(this.menuBuilder(), ResponseType.LongPress)
  }
}
```

**关键设计点**：

1. **`@Builder` 定义在 `SongRow` 内部**——因此它能访问 `this.config.menuActions`，解决了"`bindContextMenu` 需要 `@Builder`、但菜单项又随页面变化"的矛盾。不必用 `@BuilderParam` 从父级传（那样无法按行取到 song/index）。
2. **`index` 一律透传**——`PlaylistDetail` 的"从歌单移除"需要它，其他页面忽略即可，比为单个页面加可选参数更干净。
3. **`destructive` 而非 `isDanger` 布尔**——它直接对应 §2.12 的语义着色规则（破坏性 → `danger`），是可审计的语义标记。
4. **菜单变更必须整体替换数组引用**（`this.menuActions = [...newList]`，不要原地 `push`/`splice`），否则 ArkUI 无法感知变化——这是 `@Prop` 数组的标准陷阱。
5. 各页面菜单项声明示例：

| 页面 | `menuActions` |
|---|---|
| `LocalLibrary` | 播放 / 下一首播放 / 添加到歌单 / 歌曲详情 / **从设备删除**(`destructive`) |
| `Favorites` | … / **取消收藏**(`destructive`) |
| `PlaylistDetail` | … / **从歌单移除**(`destructive`, 用 `index`) |
| `PlayHistory` | … / **从历史移除**(`destructive`) |
| `FolderBrowse` | 播放 / 下一首播放 / 添加到歌单 / 歌曲详情（无删除） |

---

## 5. 多端适配（sm / md / lg）

断点沿用 `AppStorage('currentBreakpoint')` 与 `BreakpointConstants`（`320vp / 600vp / 840vp`）。

| 维度 | sm（< 600vp）Phone | md（600–840vp）折叠展开 / 小平板 | lg（≥ 840vp）平板 / 2-in-1 |
|---|---|---|---|
| 栅格列数 | 4 | 8 | 12 |
| 页面主内距 `space.base` | 16 | 20 | 24 |
| 内容最大宽度 | 100% | **720vp 居中** | **1080vp 居中** |
| 列表形态 | 单列 | 单列（封面略大） | **双栏主从**（master 360vp 固定 + detail 自适应）或 `lanes: 2` |
| 卡片圆角主体 | `radius.md`(12) | `radius.lg`(16) | `radius.lg`(16) |
| 封面尺寸 | 全宽 − 32 | 全宽 − 64，上限 420 | 固定 420，与歌词左右分栏 |
| 播放页布局 | 纵向堆叠 | 纵向堆叠 | **左封面 / 右歌词**（`ControlAreaComponent:482` 已有 `lanes` 分支，沿用） |
| 悬浮导航胶囊 | `width('92%')` 上限 520 | 上限 560 | 上限 680，或改侧边栏 |
| 字号 | 基准 | 基准 | `display/largeTitle/title1/title2` **+2fp**，`body` 及以下**不变** |
| 悬浮层 `scrim` | 全屏蒙层 | 全屏蒙层 | 可与双栏并存（仅遮 detail 栏） |

```arkts
export const SPACE_MD: LumioSpace = {
  none: 0, hair: 2, tight: 4, compact: 8, cozy: 12, base: 20, roomy: 24,
  loose: 28, section: 36, block: 48, page: 56, hero: 72,
  touchTargetMin: 44, rowHeight: 76, rowHeightCompact: 64
};
export const SPACE_LG: LumioSpace = {
  none: 0, hair: 2, tight: 4, compact: 8, cozy: 16, base: 24, roomy: 28,
  loose: 32, section: 40, block: 56, page: 64, hero: 88,
  touchTargetMin: 48, rowHeight: 84, rowHeightCompact: 72
};
```

**资源限定词**：不新增 `screen.layout` 限定词——令牌层用 `currentBreakpoint` 在**运行期**解析（与现网 `BreakpointSystem` 一致），资源层只保留 `base` / `dark` 两套 color，避免资源与代码双处维护（这正是 `design_tokens.md` §0.1 警示的双源问题）。

---

## 6. 风险清单

| ID | 风险 | 等级 | 影响 | 缓解措施 |
|---|---|---|---|---|
| **R-1** | `@Component` 上的 `get` 访问器被丢弃 → 运行时 `undefined` 崩溃 | **高** | 崩溃 | 令牌层**只提供普通方法与静态类方法**；Code Review 检查表明令禁止 `private get`；P1 后新增一个"无 get 访问器"的 grep 卡点 |
| **R-2** | `build()` / `@Builder` 首条语句为 `const`/`let` → 编译错误且级联误导 | **高** | 编译失败 | 规定 build 体内**一律不声明局部变量**；改用行内调用或 `@Builder` 参数传递 |
| **R-3** | 组件漏声明 `@StorageProp('isDark')` → 主题切换不刷新，**不报错** | **高** | 静默缺陷 | 进 Code Review 检查表；P2 阶段用脚本比对"用了 `this.c()` 的文件数" vs "声明了 `@StorageProp('isDark')` 的文件数" |
| **R-4** | `backdropBlur` 在 API 24 的表现与性能 | 中 | 掉帧 / 视觉偏差 | API 24 上 blur ≤ 30、禁止多层叠加、禁止在滚动列表项上使用；`glass.regular.fill` 必须能在无模糊时独立可读（对比度自检） |
| **R-5** | `ICurve` 类型是否具名导出不确定 | 中 | 编译失败 | 若未导出：删除 `import type { ICurve }` 与返回类型标注，由推导得出；已在 §2.8.3 标注 |
| **R-6** | Form 卡片进程 import 主应用 `.ets` 模块可能受限 | 中 | 卡片编译/运行失败 | `LumioColor/LumioScale/LumioEffect/LumioMotionSpec` 保持**零 import**；P5 需在真机验证卡片（§3.4.5）；失败则退回"卡片内 copy + CI 同值校验脚本"，**不可**因此放弃令牌化 |
| **R-7** | `systemMaterial` / `uiMaterial` 整模块为 API 26 专属 | **高** | API 24 上**模块加载即崩** | 沿用现网 `Layout.ets:30/97-104` 的模式：`import type uiMaterial`（编译期擦除）+ `ApiCompat.isAtLeast(26)` 闸门 + 动态 `import()`；令牌层**不得**静态 import 该模块 |
| **R-8** | `ContainerReader`（API 26）同类风险 | 中 | 崩溃 | 同上，已由 `ApiCompat` 管控 |
| **R-9** | `SymbolGlyph` 渲染/着色在不同设备表现不一致 | 中 | 图标显示异常 | 关键路径（播放控制）保留 PNG 兜底；新增图标经真机验证后再推广 |
| **R-10** | `letterSpacing` 负值在 `Text` / `Span` / `StyledString` 上表现不一致 | 低 | 字距视觉偏差 | P4 启用目标字距时需逐页截图比对；必要时对 `StyledString` 关闭 tracking |
| **R-11** | 深色下阴影不可见 | 中 | 层级丧失 | 每个 elevation 配套 `border`（`borderSubtle`）；P3 落地 |
| **R-12** | P3 表面层级改造若不同步改页面底 → **白底白卡片 / 灰底灰卡片不可见** | 中（v1.2 降级） | 严重视觉缺陷 | **机制已修正**：不全局改令牌值，改为逐页「换指向」（`background→surfaceGrouped` 与 `surfaceRaised→surfaceGroupedContent` 配对），未迁移页面不受影响，爆炸半径收缩到单 PR。配套强制纪律见 **§4.6**：整页提交、禁止跨页分批、每 PR 附浅/深双截图 |
| **R-13** | 对比度：`labelSecondary` light `#8E8E93` 仅 3.26:1，低于 WCAG AA 4.5:1（pm-planner 实测 3.44:1／深色 6.36:1 不对称，已复核正确） | **高** | 无障碍 + **v1.0 令牌层级倒挂** | 见 **§2.13**：P4 将 light `labelSecondary` 加深为 `#6E6E73`（5.07:1），原 `#8E8E93` 下沉为 `labelTertiary`；**只需改 `LumioColor` 一行**。属视觉变更，需设计确认；同时**覆盖 `design_tokens.md` F-14**（按 F-14 改会让 5.99:1 的指导性文字降到 3.26:1） |
| **R-14** | `resources/dark/element/color.json` 仅 1 项，深色下组件资源回退浅色 | 中 | 深色显示错误 | P5 全量镜像 `base/color.json`；与令牌层**同值对齐**（用脚本校验，防止双源漂移） |
| **R-15** | `FormAbility` 未向卡片推 `isDark` —— **实测确认是活跃线上缺陷，卡片至今恒为浅色** | **高** | 深色用户桌面卡片配色错误 | 见 §3.4：抽零依赖纯函数 `resolveIsDark()` 供主应用与 FormAbility 共用；`onAddForm` 补齐 `isDark`、`onUpdateForm` 自愈重推、主应用切换后主动推送；三层兜底 L1/L2/L3 |
| **R-16** | `ColorTokens` 垫片长期存在导致"两套并存"回潮 | 中 | 架构退化 | P4 后标 `@deprecated` 并加注释；P5 验收时删除 `getColors()`；code-linter 增加"新文件禁止 import `ColorTokens`"规则 |
| **R-17** | 迁移期同时存在 `DesignSystem.Radius(10/14/20)` 与新 `radius(8/12/16/24)` | 中 | 圆角不统一 | AD-1 已裁决采用新阶梯；`DesignSystem.Radius` 改为 **re-export 指向同一常量**（不是新增一层），P4 删除时无第二次值跳动；映射见 §2.6 |
| **R-18** | `ArtworkTint` 封面取色：高饱和/极暗/纯白封面导致文字对比度不足 | **高** | 文字不可读 | 取色结果必须做**亮度归一化 + 对比度校验**（`onContainer` vs `container` ≥ 4.5:1），不达标回落中性（§2.12.2 不变量 2）；取色异步期间必须显示中性 fallback，禁止空白。**纯白封面是最坏情况**。解法已定为**预合成不透明色**（§3.5.3 定稿方案），可达性已证明：单层不透明下 3:1 需 `#A9A9A9`、4.5:1 需 `#CFCFCF`，均可表达 |
| **R-22** | **歌词双层 alpha**（`fillStyle` α × `globalAlpha`）——v1.5 发现、v1.6 确认在真实链路上仍成立 | **高** | 非当前行 1.39~1.79:1、浏览态 1.59~2.37:1，**在所有背景上都低**；代码注释"全部清晰"与实现背离 | 预合成色下发时 **`globalAlpha` 必须固定 1.0**，颜色本身含全部衰减；验收 grep 卡点见 §3.5.4。**机理：半透明文字永远向背景靠拢，对比度被结构性压缩——调蒙层无效，只能改结构** |
| **R-23** | 蒙层参数若在错误模型上反解，会得出"需要 0.65"这类**过压暗**结论 | 中 | 播放页封面氛围被破坏（一团黑），歌词虽清楚但设计意图丧失 | v1.5 的"上限 0.65 不可协商"**已废止**，改为 clamp `[0.0, 0.25]` 默认 0.10（§3.5.3）。教训：**量化前必须确认被量化对象的完整链路，而非只确认计算方法** |
| **R-20** | `LrcView` 令牌解析若误入 `drawContent()` 热路径 | 中 | PanGesture 跟手掉帧 | 令牌只在 `applyColorScheme()` 解析并缓存到字段；`drawContent()` 只读字段。Code Review 卡点：grep 确认 `onMediaOf` / `semanticOf` 不出现在 `drawContent`/`drawLine` 内（§3.5.2） |
| **R-21** | `onMedia*` 误用 `semanticOf(isDark)` 选取（应用主题 vs 背景明暗两个维度混淆） | **高** | 浅色封面上出现白字，直接不可读 | 见 §2.4.1：媒体覆盖层必须用 `onMediaOf(backgroundIsDark)`；P2c 阶段把 `onMedia*` 从 `LumioSemantic` 迁出为独立接口，从结构上杜绝混用 |
| **R-19** | AD-2 引入 `resolveIsDark()` 重构 `ThemeManager.isDark()`，是全站主题判定的**单点改动** | **高** | 主题判定回归（影响 22 个文件） | 纯函数无副作用、逻辑与现网 `isDark()` 完全等价；P5 单独立 PR + 三项回归验证：手动切主题 / 系统切主题 / `system` 模式跟随 |
| **R-24** | 模糊削平细笔画峰值亮度，**理论色值对比度 ≠ 渲染后实测对比度** | **高**（team-lead 升级） | 按色值算"已达标"但实际不可读（小字号尤甚）；**且会诱导编数字** | **强制口径**：复核必须基于实际渲染的**截图取样**，禁止只用公式/色值计算。本轮无条件实测时须写明「未做实测、需 M3/QA 补做」，**严禁编数字**。blur 已从 5px/3px 下调至 2px/1.5px（§3.5.6）；若 M3 实测仍不达标，下一步是归零模糊改用不透明度 + 字重差。补充 M3 第 ⑦ 条真机主观判读（3 封面 × 2 态、非作者本人判读）作为兜底 |
| **R-25** | `0.65` 是**无蒙层的条件取值**，若 M3 落地蒙层后忘记下调至 `0.60` | 低 | 聚焦层次被无谓削弱（覆盖率损失，非可读性） | 代码注释强制写明「0.65 为无蒙层取值；M3 落地自适应蒙层后可下调至 0.60」；M3 PR 的检查项含该常量的复核 |

---

## 7. 架构验收清单（Definition of Done）

- [ ] `tokens/` 下 `LumioColor` / `LumioScale` / `LumioEffect` / `LumioMotionSpec` 四个文件 **import 语句数为 0**
- [ ] `LumioTheme.ets` **未被** `widget/**` 任何文件引用
- [ ] 全仓 `@Component` / `@CustomDialog` 中**不存在** `private get xxx():` 形式的取色访问器
- [ ] 全仓 `build()` 与 `@Builder` 体内**不存在** `const` / `let` 声明
- [ ] 业务目录下 `grep -E '#[0-9A-Fa-f]{6}|rgba\('` 仅命中令牌定义文件
- [ ] 每个使用 `LumioTheme.semantic()` 的组件都声明了 `@StorageProp('isDark')`
- [ ] 主题切换（设置内手动切换 + 系统切换）后，全部页面**无需重建**即正确刷新
- [ ] 开启「降低动态效果」后：无过冲、无错峰、无循环动画，按压反馈仍保留
- [ ] API 24 真机：无 `uiMaterial` / `ContainerReader` 加载崩溃；毛玻璃有 fill 兜底
- [ ] `WidgetCard` 卡片进程可正常渲染且主题跟随应用
- [ ] **AD-0**：不存在"按类别分配色相"的装饰性配色；`Mine` 菜单项已按 §2.12.3 口径改造；无封面容器回落中性而非随机色
- [ ] **AD-1**：全仓无 `10/14/20` 圆角残留；`DesignSystem.Radius` 已 re-export 指向 `LUMIO_RADIUS` 同一常量
- [ ] **R-12 / §4.6**：每个页面 PR 均附浅色 + 深色双截图，截图中「页面底 / 卡片 / 分隔线」三层可辨；无"卡片与页面同色"
- [ ] **AD-2**：`isDark` 判定逻辑**仅存在于 `resolveIsDark()` 一处**；`FormAbility.onAddForm` 写入 `isDark`、`onUpdateForm` 自愈重推、主应用切换后主动推送均生效
- [ ] **AD-2**：卡片三层兜底验证——杀掉主应用后卡片仍显示正确主题（L3 → L2 自愈）
- [ ] **§2.13 对比度契约**：`label` / `labelSecondary` 浅深两侧实测均 ≥ 4.5:1；label 层级对比度**严格单调递减**（无倒挂）
- [ ] **§4.7 `SongRow`**：5 处复制（含 `FolderBrowse`）全部收敛；无 `showXxx?: boolean` 形式的菜单开关，菜单项走 `menuActions` 注入
- [ ] **§3.5 `LrcView`**：`drawContent()` / `drawLine()` 内**无令牌解析调用**；PanGesture 跟手无回归
- [ ] **§3.5.3 歌词对比度三态分档**：播放态（当前行 4.5 / 非当前行 3.0）+ **浏览态（全部 4.5）** + 翻译行（当前 4.5 / 非当前 3.0）；取 3 张极端封面分**播放态与浏览态**分别实测
- [ ] **§3.5.5 双层 alpha 已消除**（分阶段）：全仓歌词绘制路径**不存在** `fillStyle` α × `globalAlpha` 的叠加，alpha 恒为**单一来源**
  - **本轮**：`fillStyle` 完全不透明（α=1.0）+ 弱化只由 `globalAlpha` 表达
  - **M3 终态**：`globalAlpha` 固定 1.0，颜色为 `ArtworkTint` 预合成的不透明值
  - 两者均判通过；**两层并存即判失败**
- [ ] **R-24 强制口径**：歌词对比度复核**基于实际渲染截图取样**；未做实测的项已标注「未做实测、需 M3/QA 补做」，**全仓无来源不明的编造数值**
- [ ] **M3 第 ⑦ 条**：真机主观可读性确认通过（3 封面 × 2 态、正常室内光、非作者本人判读）
- [ ] **§2.4.1**：`onMedia*` 只能由 `onMediaOf(backgroundIsDark)` 选取，全仓无 `semanticOf(isDark).onMediaXxx` 形式的误用

---

## 8. 附：给实现与审查阶段的关键约定

1. **新增文件一律从 `tokens/LumioTheme` 取令牌**，不得新增任何 hex 字面量。
2. **新文件禁止 import `ColorTokens`**（P1 之后生效）。
3. **`DesignSystem.ets` 在 P4 前仍可被 import**，但只允许取 `Motion` / `spring*`，且新代码优先用 `LumioMotion`。
4. **任何新增颜色必须先加到 `LumioSemantic` 并同时给出浅/深两套值**，否则视为架构违规。
5. **`LumioColor/LumioScale/LumioEffect/LumioMotionSpec` 的"零 import"不变量**由 Code Review 强制；一旦被打破，Form 卡片复用能力立即失效。
6. **依赖 `@kit.*` 的助手一律不得放进 `tokens/`**（`ThemeResolve` / `ArtworkTint` 放 `utils/`）——这是第 5 条的延伸。
7. **给元素上色前先过 §2.12 三级优先序**：能用内容取色就不用状态色，能用中性就不用状态色；**装饰性逐项染色一律驳回**。
8. **`isDark` 的判定只允许调用 `resolveIsDark()`**，禁止在任何地方重写 `mode === 'dark'` 之类的分支（R-19）。
9. **表面层级改造按 §4.6 整页提交**，跨页分批的 PR 直接驳回。

---

*架构方案产出：高见远（鸿蒙系统架构师）· Phase 1 · 本阶段未改动任何 `.ets` 代码文件*
