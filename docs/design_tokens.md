# Lumio Music · 设计 Token 规范（Lumio Design Tokens）

> 版本：v1.0（M1 奠基版） | 作者：蓝绘心（鸿蒙 UI/UX 设计专家）
> 依据：`docs/review_design.md` 体检结论（双源色 / 50+ 内联品牌色 / WidgetCard 离品 / HIG 调色板混入 / 列表复制）
> 适用范围：`entry/src/main/ets/**` 与 `resources/{base,dark}/element/**` 全部页面、组件、卡片
> 目标：**为 M2 设计债治理建立单一可信来源（Single Source of Truth）**，本文件为权威规范，代码替换以本文件为准。

---

## 0. 设计原则（治理基石）

1. **单一颜色来源（消除双源）**
   - **语义色唯一权威源 = `ThemeManager.lightColors` / `ThemeManager.darkColors`**（`ets/utils/ThemeManager.ets`）。业务代码只允许引用令牌，禁止出现 `Color.White` / `'#FA2759'` / `'#1A1A2E'` 等字面量（F-02 / F-08）。
   - `resources/{base,dark}/element/color.json` 仅承载**系统/组件资源色**（`start_window_background`、`slider_*`、`list_divider`、`shadow_color` 等 ArkUI 组件无法直接吃 TS 令牌的场景）。其值与语义令牌**必须同值对齐**，且 `dark/color.json` 须补全为 `base` 的全量镜像（当前仅 1 项，F-03 缺口）。
   - 删除 `Layout.ets` / `LocalLibrary.ets` 中重复定义的 `const ACCENT`，统一经 `ThemeManager.accent`。

2. **语义优先命名**：令牌表达「用途」而非「颜色」（`cardBg` 而非 `grayF2`）。新增色必须走令牌评审，不得业务内联。

3. **深色是一等公民**：所有表面、文字、描边、分隔线均经 `@StorageProp('isDark')` 取令牌；禁止任何硬编码明/暗字面量。卡片（Form 进程）经 `isDark` 表单数据驱动（见 §5）。

---

## 1. 颜色令牌（语义，light / dark 两套）

> `accent = #FA2759`（品牌粉红，恒值，不随深浅变化）。`accentSoft` 为品牌色低透明底，用于选中态/计数徽章背景（F-02 / F-15）。

| 令牌 | 用途 | light | dark |
|---|---|---|---|
| `bg` | 页面背景 | `#FFFFFF` | `#000000` |
| `secondaryBg` | 分组头 / 带状背景 | `#FAFAFA` | `#1C1C1E` |
| `cardBg` | 卡片 / 面板 / 列表项底 | `#F2F2F7` | `#1C1C1E` |
| `primaryText` | 主文字 / 标题 | `#1C1C1E` | `#FFFFFF` |
| `secondaryText` | 次文字 / 副标题 / 歌手 | `#8E8E93` | `#98989F` |
| `separator` | 分隔线 / 描边 | `#E5E5EA` | `#2C2C2E` |
| `accent` | 品牌强调（按钮 / 选中 / 链接） | `#FA2759` | `#FA2759` |
| `accentSoft` | 品牌色低透底（选中底 / 徽章底） | `rgba(250,39,89,0.10)` | `rgba(250,39,89,0.22)` |

**对比度**：light `secondaryText #8E8E93` 白底约 3.5:1（接近 AA 大文本阈值），禁止再加深；禁止另行硬编码 `#636366`（F-14，统一改用 `secondaryText`）。

---

## 2. 尺度令牌（圆角 / 间距 / 字号 / 阴影）

### 2.1 圆角（收敛发散，F-10）
| 令牌 | vp | 映射现有 `float.json` | 典型使用 |
|---|---|---|---|
| `radius_xs` | 4 | — |  chip 内小元素 |
| `radius_sm` | 8 | `label_border`(8) / 卡片内图标 | 小按钮 / 封面圆角（WidgetCard 封面 8→保持） |
| `radius_md` | 12 | `cover_radius_label`(12) / `play_all_border_radius`(12) | 列表项 / 中卡片 |
| `radius_lg` | 16 | `cover_radius`(16) | 封面 / 大卡片 / 面板 |
| `radius_xl` | 24 | — | 浮层 / 大圆角容器 |
| `radius_pill` | 999 | — | 胶囊 / 圆形按钮（播放键 56、上/下一首 40 沿用） |

> 全仓 `borderRadius(10/14/15/20/21/22/32...)` 收敛到上表，禁止其它随机半径。

### 2.2 间距（统一引用，F-17）
| 令牌 | vp | 映射现有 | 使用 |
|---|---|---|---|
| `space_xs` | 4 | `list_item_title_margin` | 紧凑内距 |
| `space_sm` | 8 | `margin_small` | 元素间 |
| `space_md` | 12 | `options_padding` | 次间距 |
| `space_lg` | 16 | `common_padding` / `common_margin` | 页面/卡片主间距 |
| `space_xl` | 24 | `twenty_four` | 区块间距 |
| `space_xxl` | 32 | — | 大留白 |

### 2.3 字号（统一 fp，无障碍友好）
| 令牌 | fp | 映射现有 | 使用 |
|---|---|---|---|
| `font_xs` | 11 | `singer_title_sm` | 角标 |
| `font_sm` | 12 | `singer_font_sm` | 副信息 / 歌手 |
| `font_md` | 14 | `font_fourteen` / `item_font_sm` | 正文 / 列表副 |
| `font_lg` | 15 | `item_font_md` | 列表主 |
| `font_title_sm` | 16 | `title_font_sm` | 卡片标题（WidgetCard 标题 16→保持） |
| `font_title_md` | 18 | `title_font_md` | 页标题 |
| `font_title_lg` | 20 | `title_font_lg` | 播放页标题 |
| `font_display` | 28 | — | 播放页大标题 |

> 全部用 `fp`；**禁止固定死 `height(64/60/76)` 行高**，列表项改用 `minHeight` + 自适应，避免超大字体挤压多行（P2 无障碍）。

### 2.4 阴影（按主题降级，禁止纯黑重影）
| 令牌 | 参数（light） | dark 处理 |
|---|---|---|
| `shadow_sm` | r8 / α0.06 / y2 | α 降至 0.0（深色以描边 `separator` 替代投影） |
| `shadow_md` | r16 / α0.10 / y4 | 同上，靠 `cardBg` 层次区分 |
| `shadow_lg` | r24 / α0.14 / y8 | 同上 |

---

## 3. 图标规范（优先 HarmonyOS Symbol，禁用 iOS HIG 调色板）

### 3.1 选用顺序
1. **优先 `SymbolGlyph` / `sys.symbol.*`**（矢量、可着色、光学对齐佳）。现状已混用（`music_square_stack_fill`/`person`/`pause_fill`），统一推广。
2. **自定义图标用可着色 SVG**，统一线宽 `1.5vp`、统一 `fillColor` 取令牌；**删除冗余 PNG**（png 不可着色、不利对齐，F-12）。
3. 封面/头像等照片类可用位图，不在此限。

### 3.2 着色规则
- 默认 `primaryText`；次级 `secondaryText`；激活/选中 `accent`。
- 分类图标底块用 **中性 `secondaryBg` + 单色 Symbol**，或统一 `accent` 强调；**禁止每类一色**。

### 3.3 🚫 红线：Apple HIG 调色板（绝对禁止）
以下色值**全仓任何位置不得出现**（用于分类图标底/统计数字等，F-07）：

```
#34C759  #FF9500  #007AFF  #5E5CE6  #FFCC00  #5856D6
```

> 出现在 `Mine.ets` / `SettingsCategory.ets` 等处的上述色，**替换为 `secondaryBg` 底 + `accent`/`primaryText` 单色图标**；索引见 `review_design.md` F-07。

---

## 4. 动效原则（支持 `reduceMotion` 降级，F-13）

1. **`reduceMotion` 全局消费**：`SettingsStore.reducedMotion` 已持久化但全仓未读。新增 `getReducedMotion()` 助手，**所有非必要动画在为真时降级/关闭**：
   - 关闭：歌词流光、列表错峰入场（`delay:index*50`）、空态呼吸 `setInterval`、封面 `setInterval` 旋转（改 `animateTo` 持续动画）。
   - 保留：必要状态切换（淡入 `<=120ms`）、按钮按压反馈（短 `opacity`，不做 `translate/spring`）。
2. **统一交互曲线**：按压反馈抽 `@Styles pressScale`（缩 0.96，`.animation({duration:120, curve: Curve.Friction})`），统一缩放与时长（F-11）。
3. **保留** `geometryTransition('player_cover')` + `interpolatingSpring` 一镜到底转场（规范合规，✅）。
4. 动画时长约定：微交互 120ms / 入场 300ms / 页面转场弹簧。

---

## 5. 深色主题强制要求（所有页面 / 组件 / 卡片）

1. 每个用到颜色的 `@Component` 必须声明：
   ```ts
   @StorageProp('isDark') isDark: boolean = false;
   getThemeColors(): ColorTokens {
     return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
   }
   ```
   表面/文字/描边一律取 `getThemeColors().cardBg / primaryText / separator / accent / accentSoft`。
2. **禁止** `Color.White` / `Color.Black` / `Color.Red` / `Color.Gray` 及 `'#FFFFFF'` / `'#1A1A2E'` 等字面量（F-01 播放队列面板、F-08 WidgetCard 为典型违例）。
3. **卡片（Form 进程）特殊处理**：ArkTS 卡片运行在独立渲染进程，无法共享主应用 `AppStorage`，亦不应 import 完整 `ThemeManager`（其依赖 `window`/Preferences，卡片不可用）。卡片侧：
   - 经 `@LocalStorageProp('isDark')` 读取主题（由 `FormAbility` 在 `createFormBindingData` 中写入 `isDark`，随系统/应用主题变更重推）。
   - 卡片内自建轻量 `cardColors(isDark)` 取色集，**值与 §1 令牌同值**（见 `WidgetCard.ets` 示范）；背景由 `#1A1A2E` 改为 `isDark ? cardBg(dark) : cardBg(light)`。
   - `FormAbility` 推送 `isDark` 为 M2 闭环项（见 §6）。

---

## 6. 与现有 `ThemeManager` 的映射 & 落地缺口

### 6.1 映射表（本规范以 `ThemeManager.lightColors/darkColors` 为权威源）
| 规范令牌 | ThemeManager 字段 | 现有？ | 备注 |
|---|---|---|---|
| `bg` | `bg` | ✅ | 同值 |
| `secondaryBg` | `secondaryBg` | ✅ | 同值 |
| `cardBg` | `cardBg` | ✅ | 同值 |
| `primaryText` | `primaryText` | ✅ | 同值 |
| `secondaryText` | `secondaryText` | ✅ | 同值 |
| `separator` | `separator` | ✅ | 同值 |
| `accent` | `accent` | ✅ | `#FA2759` 恒值 |
| `accentSoft` | **新增** `accentSoft` | ❌ | 须在 `ColorTokens` + `LIGHT_TOKENS`/`DARK_TOKENS` 补字段 |
| 圆角/间距/字号/阴影 | — | ⚠️ | 入 `float.json` 新增 `radius_*`/`space_*` 命名项（保留现有效项） |

### 6.2 需补齐的缺口（M2 排期，不在 M1 范围）
- **G-1**：`ThemeManager` 增 `accentSoft`（light/dark，见 §1）。
- **G-2**：`resources/dark/element/color.json` 补全为 `base` 全量镜像（`slider_*`/`list_divider`/`shadow_color`/`play_text_color`/`singer_text`/`select_swiper`），消除深色回退浅色（F-03）。
- **G-3**：清理 `ThemeManager.getColors()` 死方法（F-04）；业务统一经 `lightColors/darkColors`。
- **G-4**：`FormAbility` 在 `onAddForm`/`onUpdateForm` 与主题变更时向卡片 `createFormBindingData` 写入 `isDark`（闭合 §5.3 卡片主题链路）。
- **G-5**：`resources` 资源令牌（`$r('app.color.*')`）与 `ThemeManager` 同值对齐，形成双处一致（资源侧仅作组件约束兜底）。

---

## 7. M2 推荐执行顺序（设计债治理）

| 序 | 任务 | 对应 Finding | 优先级 | 说明 |
|---|---|---|---|---|
| 1 | 修播放队列面板深色化（`getThemeColors()` 替换 `Color.White`） | F-01 | **P0** | 唯一用户可见明暗断裂，纯着色，成本最低 |
| 2 | `ThemeManager` 增 `accentSoft` + 全仓替换 50+ 内联 `#FA2759`/删除重复 `ACCENT` | F-02 | P1 | 先补 `accentSoft` 令牌再批量替换 |
| 3 | `dark/color.json` 全量补全 + 资源令牌对齐 | F-03 | P1 | 与 G-2 同步 |
| 4 | WidgetCard 主题链路闭合（`FormAbility` 推 `isDark`） | F-08 / G-4 | P1 | M1 已示范卡片侧，此处补 Ability 侧 |
| 5 | 抽 `SongListItem` + `songContextMenu` 公共组件 | F-09 | P1 | 消三处复制 |
| 6 | lg 主列表多列 / 主从双栏 | F-05 | P1 | 平板/折叠屏利用 |
| 7 | 统一安全区策略 | F-06 | P1 | `expandSafeArea` 统一 |
| 8 | 分类/统计去 HIG 调色板，回归品牌 | F-07 | P1 | 替换 §3.3 红线色 |
| 9 | 圆角/间距/字号尺度收敛 | F-10 | P2 | 引用 §2 令牌 |
| 10 | 抽 `pressScale` @Styles 统一按压 | F-11 | P2 | 统一曲线 |
| 11 | 图标统一 Symbol / 可着色 SVG，删冗余 PNG | F-12 | P2 | |
| 12 | `reduceMotion` 全局消费 + 无障碍语义（`accessibilityText`） | F-13 | P2 | 落地 §4 |
| 13 | 次要文字色 `#636366` → `secondaryText` | F-14 | P2 | |
| 14 | 抽 `CountBadge` 公共构建 | F-15 | P2 | 依赖 `accent`/`accentSoft` |
| 15 | UI 文案资源化 `string.json` | F-16 | P2 | |
| 16 | 清理主题样板 / 死代码 / 写法统一 | F-17 | P2 | |
| 17 | 播放页沉浸策略文档化 + 对比度 helper | F-18 | P2 | 设计观察 |

---

*规范生成：蓝绘心（鸿蒙 UI/UX 设计专家）。本规范为 M2 设计债治理的权威依据，代码替换须以本文件令牌为准。*
