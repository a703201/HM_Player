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
 * 令牌层 L1（Primitive 原始色板）+ L2（Semantic 语义色）+ 媒体覆盖层维度。
 *
 * 不变量：本文件「零 import」——不依赖 @kit.* / AppStorage / Preferences / Logger。
 * 因此主应用、Service 与 Form 卡片进程（WidgetCard）均可直接引用。
 * 任何依赖 @kit 的令牌（如 LumioMotion 的 curves）不得放进本文件。
 */

// ===================== L1：Primitive 原始色板（只存值，不表达用途） =====================
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
  pink400: string;
  pink500: string;
  pink600: string;
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
  pink400: '#FF4C74',
  pink500: '#FA2759',
  pink600: '#E01F4C',
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

// ===================== L2：Semantic 语义色（43 字段，浅/深两套） =====================
export interface LumioSemantic {
  background: string;
  backgroundSecondary: string;
  backgroundTertiary: string;
  surfaceRaised: string;
  surfaceGrouped: string;
  surfaceGroupedContent: string;
  surfaceOverlay: string;
  scrim: string;
  inverseSurface: string;
  fillPrimary: string;
  fillSecondary: string;
  fillTertiary: string;
  fillQuaternary: string;
  fillAccentSubtle: string;
  fillAccentSoft: string;
  fillAccentMuted: string;
  fillSuccessSoft: string;
  fillWarningSoft: string;
  fillDangerSoft: string;
  fillInfoSoft: string;
  label: string;
  labelSecondary: string;
  labelTertiary: string;
  labelQuaternary: string;
  labelOnAccent: string;
  labelInverse: string;
  separator: string;
  separatorOpaque: string;
  borderSubtle: string;
  borderAccent: string;
  accent: string;
  accentPressed: string;
  accentDisabled: string;
  onAccent: string;
  success: string;
  warning: string;
  danger: string;
  info: string;
  onMediaPrimary: string;
  onMediaSecondary: string;
  onMediaTertiary: string;
  onMediaEmphasis: string;
  onMediaControlBg: string;
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
  scrim: 'rgba(0,0,0,0.2)',
  inverseSurface: '#1C1C1E',
  fillPrimary: 'rgba(120,120,128,0.2)',
  fillSecondary: 'rgba(120,120,128,0.16)',
  fillTertiary: 'rgba(118,118,128,0.12)',
  fillQuaternary: 'rgba(116,116,128,0.08)',
  fillAccentSubtle: 'rgba(250,39,89,0.05)',
  fillAccentSoft: 'rgba(250,39,89,0.1)',
  fillAccentMuted: 'rgba(250,39,89,0.3)',
  fillSuccessSoft: 'rgba(52,199,89,0.12)',
  fillWarningSoft: 'rgba(255,149,0,0.12)',
  fillDangerSoft: 'rgba(255,59,48,0.12)',
  fillInfoSoft: 'rgba(0,122,255,0.12)',
  label: '#1C1C1E',
  labelSecondary: '#6E6E73',
  labelTertiary: '#8E8E93',
  labelQuaternary: 'rgba(60,60,67,0.18)',
  labelOnAccent: '#FFFFFF',
  labelInverse: '#FFFFFF',
  separator: 'rgba(60,60,67,0.29)',
  separatorOpaque: '#C6C6C8',
  borderSubtle: 'rgba(0,0,0,0.06)',
  borderAccent: 'rgba(250,39,89,0.2)',
  accent: '#FA2759',
  accentPressed: '#E01F4C',
  accentDisabled: 'rgba(250,39,89,0.35)',
  onAccent: '#FFFFFF',
  success: '#34C759',
  warning: '#FF9500',
  danger: '#FF3B30',
  info: '#007AFF',
  onMediaPrimary: 'rgba(0,0,0,0.85)',
  onMediaSecondary: 'rgba(0,0,0,0.3)',
  onMediaTertiary: 'rgba(0,0,0,0.2)',
  onMediaEmphasis: 'rgba(0,0,0,0.6)',
  onMediaControlBg: 'rgba(255,255,255,0.16)',
  onMediaScrim: 'rgba(255,255,255,0.35)'
};

export const DARK_SEMANTIC: LumioSemantic = {
  background: '#000000',
  backgroundSecondary: '#1C1C1E',
  backgroundTertiary: '#2C2C2E',
  surfaceRaised: '#1C1C1E',
  surfaceGrouped: '#000000',
  surfaceGroupedContent: '#1C1C1E',
  surfaceOverlay: '#1C1C1E',
  scrim: 'rgba(0,0,0,0.45)',
  inverseSurface: '#F2F2F7',
  fillPrimary: 'rgba(120,120,128,0.36)',
  fillSecondary: 'rgba(120,120,128,0.32)',
  fillTertiary: 'rgba(118,118,128,0.24)',
  fillQuaternary: 'rgba(118,118,128,0.18)',
  fillAccentSubtle: 'rgba(250,39,89,0.14)',
  fillAccentSoft: 'rgba(250,39,89,0.22)',
  fillAccentMuted: 'rgba(250,39,89,0.38)',
  fillSuccessSoft: 'rgba(48,209,88,0.22)',
  fillWarningSoft: 'rgba(255,159,10,0.22)',
  fillDangerSoft: 'rgba(255,69,58,0.22)',
  fillInfoSoft: 'rgba(10,132,255,0.22)',
  label: '#FFFFFF',
  labelSecondary: '#98989F',
  labelTertiary: '#636366',
  labelQuaternary: 'rgba(235,235,245,0.18)',
  labelOnAccent: '#FFFFFF',
  labelInverse: '#1C1C1E',
  separator: 'rgba(84,84,88,0.6)',
  separatorOpaque: '#38383A',
  borderSubtle: 'rgba(255,255,255,0.08)',
  borderAccent: 'rgba(250,39,89,0.32)',
  accent: '#FA2759',
  accentPressed: '#E01F4C',
  accentDisabled: 'rgba(250,39,89,0.35)',
  onAccent: '#FFFFFF',
  success: '#30D158',
  warning: '#FF9F0A',
  danger: '#FF453A',
  info: '#0A84FF',
  onMediaPrimary: '#FFFFFF',
  onMediaSecondary: 'rgba(255,255,255,0.5)',
  onMediaTertiary: 'rgba(255,255,255,0.3)',
  onMediaEmphasis: 'rgba(255,255,255,0.84)',
  onMediaControlBg: 'rgba(255,255,255,0.16)',
  onMediaScrim: 'rgba(0,0,0,0.35)'
};

/** 按「应用主题」选择语义令牌（返回常量引用，不新建对象）。 */
export function semanticOf(isDark: boolean): LumioSemantic {
  return isDark ? DARK_SEMANTIC : LIGHT_SEMANTIC;
}

// ===================== 媒体覆盖层维度（独立维度，不随应用主题） =====================
/**
 * onMedia* 系列叠加在封面/图片之上，其输入是「背景明暗」（封面取色结果），
 * 与「应用主题」（isDark）无关。深色主题用户播浅色封面时，歌词应取 onMedia*(light)，
 * 而非 semanticOf(true) 的 dark 分支——否则浅底白字不可读。
 */
export interface LumioOnMedia {
  primary: string;
  secondary: string;
  tertiary: string;
  emphasis: string;
  controlBg: string;
  scrim: string;
}

export const ON_MEDIA_LIGHT: LumioOnMedia = {
  primary: 'rgba(0,0,0,0.85)',
  secondary: 'rgba(0,0,0,0.3)',
  tertiary: 'rgba(0,0,0,0.2)',
  emphasis: 'rgba(0,0,0,0.6)',
  controlBg: 'rgba(255,255,255,0.16)',
  scrim: 'rgba(255,255,255,0.35)'
};

export const ON_MEDIA_DARK: LumioOnMedia = {
  primary: '#FFFFFF',
  secondary: 'rgba(255,255,255,0.5)',
  tertiary: 'rgba(255,255,255,0.3)',
  emphasis: 'rgba(255,255,255,0.84)',
  controlBg: 'rgba(255,255,255,0.16)',
  scrim: 'rgba(0,0,0,0.45)'
};

/** 按「背景明暗」选取媒体覆盖层令牌——与 semanticOf() 是两个不同维度，禁止混用。 */
export function onMediaOf(backgroundIsDark: boolean): LumioOnMedia {
  return backgroundIsDark ? ON_MEDIA_DARK : ON_MEDIA_LIGHT;
}

// ===================== 卡片控件底色（WidgetCard 专用，Form 进程安全） =====================
/** 次级按钮底（浅色卡：黑 20%）。等价于此前的硬编码 #33000000。 */
export const CARD_CONTROL_BG_LIGHT: string = 'rgba(0,0,0,0.2)';
/** 次级按钮底（深色卡：白 20%）。等价于此前的硬编码 #33FFFFFF。 */
export const CARD_CONTROL_BG_DARK: string = 'rgba(255,255,255,0.2)';
