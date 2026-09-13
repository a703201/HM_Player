# 半模态面板（Sheet）Apple 风重设计 · 实施记录

- 日期：2026-09-12
- 范围：`SongDetailSheet` / `AddToPlaylistSheet` / `OnboardingSheet` / `ControlAreaComponent`（速度 / 睡眠 / 队列三个子 Sheet）
- 调用技能：`@skill:apple-design`（材质 / 字距 / 弹簧 / 减弱动效）
- 设计依据：`docs/设计系统_Apple.md` §2.5.5、§1.5.15/16/17、L924/L835/L1188；`docs/UI重设计_设计令牌架构.md` AD-1、§2.6

## 1. 结论速览

Phase A 已让 Sheet 接入 `SheetScaffold`（`systemMaterial(ImmersiveMaterial.REGULAR)` / `surfaceOverlay` 纯色兜底，两分支互斥，符合 §2.5.5）。本轮在**已稳定的合规骨架上做 apple-design 增强**，不破坏任何 Phase A 不变量：

| 维度 | 现状 | 本轮整改 | apple-design 依据 |
|------|------|----------|-------------------|
| 材质重量 | REGULAR（正确） | 不动 | §12 材质重量编码层级：REGULAR = 轻量交互层，符合 Sheet |
| 标题字距 | 仅 `size`+字重，**缺 letterSpacing / lineHeight** | 套用令牌全字段（size/lineHeight/tracking） | §15 光学字距：大字负字距 |
| 标题字重 | `Bold`(700) / `Medium`(500) | **保留原字重**（见 §3 平台约束） | — |
| 硬圆角 | 多处 `borderRadius(12)` 硬编码 | `LUMIO_RADIUS.md`（值不变，令牌化） | AD-1 同心圆角纪律 |
| detents / 拖拽 | 冻结 | 不动（系统接管） | §2.5.5 / §3.2.3 |
| 减弱动效 | Sheet 拖拽为系统行为 | 不动（无法自定义）；Onboarding 微交互已用 `LumioTheme.curve(SpringKind.Crisp)` | §14 |

## 2. 逐文件改动清单

### 2.1 SongDetailSheet.ets
- `Text('歌曲信息')`（SheetBody 标题，title3）：补 `.lineHeight(title3.lineHeight)` + `.letterSpacing(title3.tracking)`；字重保留原 `Bold`。
- `infoRow` 的 label / value（subhead）：补 `.lineHeight(subhead.lineHeight)` + `.letterSpacing(subhead.tracking)`（label 列宽 80vp 保留，符合 L835）。

### 2.2 AddToPlaylistSheet.ets
- 弹窗标题 `Text('新建歌单')` 与 Sheet 主标题 `Text('添加到歌单')`（title3）：均补 title3 全字段 `lineHeight`+`letterSpacing`；字重保留原 `Bold`。
- `nameDialogBuilder` 内 `TextInput` 的 `.borderRadius(12)` → `LUMIO_RADIUS.md`。

### 2.3 OnboardingSheet.ets
- `Text('欢迎使用 Lumio Music')`（title1）：补 `.lineHeight(title1.lineHeight)` + `.letterSpacing(title1.tracking)`；字重保留原 `Bold`（title1 令牌 weight=700）。
- `featureItem` 特性标题 `Text(f.title)`（headline）：补 headline 全字段 `lineHeight`+`letterSpacing`；字重保留原 `Medium`。

### 2.4 ControlAreaComponent.ets
- 导入补 `LUMIO_RADIUS`。
- 速度 Sheet 标题 `Text('播放速度')`、睡眠 Sheet 标题 `Text('睡眠定时')`（title3）：补 title3 全字段；字重保留原 `Bold`。
- 速度行 `Text(rateLabel)`、睡眠三行（`分钟` / `播完当前曲后停止` / `关闭定时`）（headline）：补 `.lineHeight` + `.letterSpacing`（**不改字重**，避免整列加粗破坏列表可读性）。
- 两处 `.borderRadius(12)`（倍速标签胶囊、倍速选中行背景）→ `LUMIO_RADIUS.md`。

## 3. 平台约束：字重无法精确对齐令牌 600

设计令牌 `TYPE_SM.title3/headline.weight = 600`（Semibold），但本 SDK 的 `FontWeight` 枚举**只有具名成员** `Lighter / Normal / Regular / Medium(500) / Bold(700) / Bolder(900)`，**不存在 `W600` 或 `SemiBold`**（编译报错 `Property 'W600' does not exist on type 'typeof FontWeight'`）。枚举在 500 与 700 之间无中间值，故无法在 ArkTS 层精确表达 600。

处置：字重**回退为改前原值**（标题 `Bold`、特性标题 `Medium`），仅落实可编译的光学字距部分（`letterSpacing` / `lineHeight`）。这是设计令牌与平台枚举的已知鸿沟，已在 `docs/UI重设计_设计令牌架构.md` 的 R-10 之外作为新的实现约束记录；后续若 SDK 提供 `FontWeight.W600` 可一次性补回。

## 4. 保留不动项（明确记录，避免回归）

1. `SheetScaffold` 的 `systemMaterial` / `backgroundColor` 二选一互斥结构 —— 符合 §2.5.5 硬规，绝不合并两者。
2. `acquireSheetMaterial()` 返回 `ImmersiveMaterial({ style: REGULAR })` —— 已是正确材质重量。
3. 所有 `detents`（MEDIUM / LARGE / ['90%']）与 `dragBar` / `showClose` —— 冻结。
4. `bindSheet` 拖拽释放 / 1:1 跟手 / 投影落点 —— 系统行为，不可自定义（§3.2.3）。

## 5. 验证

- 改动经原子脚本写入（每文件每处 old→new 精确匹配断言，避免并行 Edit 竞态）。
- `FontWeight.W600` 首次引入即触发编译错误（枚举无此成员），已回退字重、保留字距整改。
- 构建状态：见 `BUILD SUCCESSFUL` 闸门输出（assembleHap）。
