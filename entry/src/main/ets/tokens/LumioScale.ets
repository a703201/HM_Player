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
 * 令牌层 L1（间距 / 圆角 / 排版）。
 *
 * 不变量：本文件「零 import」——不依赖 @kit.* / AppStorage / Preferences / Logger。
 * 主应用、Service 与 Form 卡片进程均可直接引用。
 */

// ===================== 间距栅格（4vp 基准） =====================
export interface LumioSpace {
  none: number;
  hair: number;
  tight: number;
  compact: number;
  cozy: number;
  base: number;
  roomy: number;
  loose: number;
  section: number;
  block: number;
  page: number;
  hero: number;
  touchTargetMin: number;
  rowHeight: number;
  rowHeightCompact: number;
}

export const SPACE_SM: LumioSpace = {
  none: 0, hair: 2, tight: 4, compact: 8, cozy: 12, base: 16, roomy: 20,
  loose: 24, section: 32, block: 40, page: 48, hero: 64,
  touchTargetMin: 44, rowHeight: 72, rowHeightCompact: 60
};

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

// ===================== 圆角阶梯（4 的倍数，废弃 10/14/20） =====================
export interface LumioRadius {
  none: number;
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  pill: number;
}

export const LUMIO_RADIUS: LumioRadius = {
  none: 0,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  pill: 999
};

// ===================== 排版阶梯 =====================
export interface LumioTextStyle {
  size: number;        // fp（跟随系统字体缩放）
  weight: number;      // 400 / 500 / 600 / 700
  lineHeight: number;  // vp（不随字体缩放，避免行高塌陷）
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

// sm（< 600vp）：采用现网等价值，M1 阶段零视觉变更
export const TYPE_SM: LumioType = {
  display: { size: 28, weight: 700, lineHeight: 41, tracking: -0.40 },
  largeTitle: { size: 28, weight: 700, lineHeight: 34, tracking: -0.26 },
  title1: { size: 20, weight: 700, lineHeight: 28, tracking: -0.20 },
  title2: { size: 20, weight: 600, lineHeight: 25, tracking: -0.16 },
  title3: { size: 18, weight: 600, lineHeight: 24, tracking: -0.12 },
  headline: { size: 16, weight: 600, lineHeight: 22, tracking: -0.10 },
  body: { size: 15, weight: 400, lineHeight: 20, tracking: -0.06 },
  bodyEmphasis: { size: 15, weight: 600, lineHeight: 20, tracking: -0.06 },
  subhead: { size: 14, weight: 400, lineHeight: 19, tracking: -0.04 },
  footnote: { size: 13, weight: 400, lineHeight: 18, tracking: 0.00 },
  caption1: { size: 12, weight: 400, lineHeight: 16, tracking: 0.02 },
  caption2: { size: 11, weight: 500, lineHeight: 14, tracking: 0.04 }
};

// lg（≥ 840vp）：仅 display / largeTitle / title1 / title2 +2fp，其余不变
export const TYPE_LG: LumioType = {
  display: { size: 30, weight: 700, lineHeight: 41, tracking: -0.40 },
  largeTitle: { size: 30, weight: 700, lineHeight: 34, tracking: -0.26 },
  title1: { size: 22, weight: 700, lineHeight: 28, tracking: -0.20 },
  title2: { size: 22, weight: 600, lineHeight: 25, tracking: -0.16 },
  title3: { size: 18, weight: 600, lineHeight: 24, tracking: -0.12 },
  headline: { size: 16, weight: 600, lineHeight: 22, tracking: -0.10 },
  body: { size: 15, weight: 400, lineHeight: 20, tracking: -0.06 },
  bodyEmphasis: { size: 15, weight: 600, lineHeight: 20, tracking: -0.06 },
  subhead: { size: 14, weight: 400, lineHeight: 19, tracking: -0.04 },
  footnote: { size: 13, weight: 400, lineHeight: 18, tracking: 0.00 },
  caption1: { size: 12, weight: 400, lineHeight: 16, tracking: 0.02 },
  caption2: { size: 11, weight: 500, lineHeight: 14, tracking: 0.04 }
};
