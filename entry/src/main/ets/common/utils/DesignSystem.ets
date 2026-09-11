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
 * Lumio Music 设计系统 —— P4 退化垫片。
 *
 * 自 M1 起，颜色/尺度/特效/动效的权威来源已统一到 `tokens/` 层（LumioColor /
 * LumioScale / LumioEffect / LumioMotion / LumioTheme）。本文件不再持有任何定义，
 * 仅把旧组件仍通过 `from '../common/utils/DesignSystem'` 取用的符号 re-export 自令牌层，
 * 调用方零改动：
 *  - `BRAND_ACCENT`    → LumioSemantic.accent（品牌强调色，深浅同值 #FA2759）
 *  - `springSnappy` / `springSoft` / `springGentle` → LumioTheme.curve(...)
 *    （经 LumioTheme 出口，内部已读 reduceMotion 可达性开关，调用方无需关心降级）
 *  - `Motion`          → LumioDurations（tap/press/fade/sheet/stagger）
 *
 * 旧 AppleTokens / appleColors / Glass / TransitionId / Radius 定义已随 P4 收敛删除：
 * 现网无任何调用方（ThemeManager.apple() 为死代码，已移除）。
 */

import { LIGHT_SEMANTIC } from '../../tokens/LumioColor';
import { LumioTheme, SpringKind } from '../../tokens/LumioTheme';
import { LumioDurations } from '../../tokens/LumioMotionSpec';

/** 品牌强调色（全应用唯一强调色，保持 #FA2759，深浅同值）。 */
export const BRAND_ACCENT: string = LIGHT_SEMANTIC.accent;

/** 弹簧曲线预设（interpolatingSpring），经 LumioTheme 出口读取 reduceMotion。 */
export function springSnappy(): ICurve {
  return LumioTheme.curve(SpringKind.Snappy);
}

export function springSoft(): ICurve {
  return LumioTheme.curve(SpringKind.Soft);
}

export function springGentle(): ICurve {
  return LumioTheme.curve(SpringKind.Gentle);
}

/** 动效时长（毫秒），re-export 自令牌层。 */
export const Motion = LumioDurations;
