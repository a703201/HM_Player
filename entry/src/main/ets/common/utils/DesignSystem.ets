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
 * Lumio Music 设计系统（Apple 风格 / iOS 语义色 + 弹簧动效 + 毛玻璃）。
 *
 * 设计原则（对齐 iOS / HarmonyOS Design System）：
 *  1. 语义化颜色令牌：背景、分组背景、填充、标签、分隔线、系统色全部按「浅/深」双套，
 *     组件只引用语义令牌，不写死 hex，主题切换零成本。
 *  2. 圆角 / 间距 / 字号分层（iOS 规范）：卡片 14~20vp、列表行 12vp、分组间距 8/16vp。
 *  3. 动效以「弹簧曲线」为核心（interpolatingSpring），取代线性/缓动，带来果味回弹手感。
 *  4. 毛玻璃（backdropBlur + 半透明填充）用于浮层、控制条、Sheet，营造层次纵深。
 *
 * 本模块为纯常量 + 纯函数，不依赖 ThemeManager，避免循环引用；组件直接 import 使用。
 */

import { curves } from '@kit.ArkUI';

/** 品牌强调色（全应用唯一强调色，保持 #FA2759）。 */
export const BRAND_ACCENT: string = '#FA2759';

/** Apple 语义色令牌（iOS System Color 近似）。 */
export interface AppleTokens {
  // 背景层
  systemBackground: string;
  secondarySystemBackground: string;
  tertiarySystemBackground: string;
  systemGroupedBackground: string;
  secondarySystemGroupedBackground: string;
  // 填充（控件按层级叠加，营造景深）
  systemFill: string;
  secondarySystemFill: string;
  tertiarySystemFill: string;
  quaternarySystemFill: string;
  // 文本标签
  label: string;
  secondaryLabel: string;
  tertiaryLabel: string;
  quaternaryLabel: string;
  // 分隔线
  separator: string;
  opaqueSeparator: string;
  // 系统语义色
  systemBlue: string;
  systemGreen: string;
  systemOrange: string;
  systemRed: string;
  systemPurple: string;
  systemGray: string;
  systemGray2: string;
  systemGray3: string;
  systemGray4: string;
  systemGray5: string;
  systemGray6: string;
}

/** 浅色令牌。 */
export const LIGHT_APPLE: AppleTokens = {
  systemBackground: '#FFFFFF',
  secondarySystemBackground: '#F2F2F7',
  tertiarySystemBackground: '#FFFFFF',
  systemGroupedBackground: '#F2F2F7',
  secondarySystemGroupedBackground: '#FFFFFF',
  systemFill: 'rgba(120, 120, 128, 0.20)',
  secondarySystemFill: 'rgba(120, 120, 128, 0.16)',
  tertiarySystemFill: 'rgba(118, 118, 128, 0.12)',
  quaternarySystemFill: 'rgba(116, 116, 128, 0.08)',
  label: '#1C1C1E',
  secondaryLabel: 'rgba(60, 60, 67, 0.60)',
  tertiaryLabel: 'rgba(60, 60, 67, 0.30)',
  quaternaryLabel: 'rgba(60, 60, 67, 0.18)',
  separator: 'rgba(60, 60, 67, 0.29)',
  opaqueSeparator: '#C6C6C8',
  systemBlue: '#007AFF',
  systemGreen: '#34C759',
  systemOrange: '#FF9500',
  systemRed: '#FF3B30',
  systemPurple: '#5856D6',
  systemGray: '#8E8E93',
  systemGray2: '#AEAEB2',
  systemGray3: '#C7C7CC',
  systemGray4: '#D1D1D6',
  systemGray5: '#E5E5EA',
  systemGray6: '#F2F2F7'
};

/** 深色令牌。 */
export const DARK_APPLE: AppleTokens = {
  systemBackground: '#000000',
  secondarySystemBackground: '#1C1C1E',
  tertiarySystemBackground: '#2C2C2E',
  systemGroupedBackground: '#000000',
  secondarySystemGroupedBackground: '#1C1C1E',
  systemFill: 'rgba(120, 120, 128, 0.36)',
  secondarySystemFill: 'rgba(120, 120, 128, 0.32)',
  tertiarySystemFill: 'rgba(118, 118, 128, 0.24)',
  quaternarySystemFill: 'rgba(118, 118, 128, 0.18)',
  label: '#FFFFFF',
  secondaryLabel: 'rgba(235, 235, 245, 0.60)',
  tertiaryLabel: 'rgba(235, 235, 245, 0.30)',
  quaternaryLabel: 'rgba(235, 235, 245, 0.18)',
  separator: 'rgba(84, 84, 88, 0.60)',
  opaqueSeparator: '#38383A',
  systemBlue: '#0A84FF',
  systemGreen: '#30D158',
  systemOrange: '#FF9F0A',
  systemRed: '#FF453A',
  systemPurple: '#BF5AF2',
  systemGray: '#8E8E93',
  systemGray2: '#636366',
  systemGray3: '#48484A',
  systemGray4: '#3A3A3C',
  systemGray5: '#2C2C2E',
  systemGray6: '#1C1C1E'
};

/** 取当前主题对应的 Apple 语义令牌。 */
export function appleColors(isDark: boolean): AppleTokens {
  return isDark ? DARK_APPLE : LIGHT_APPLE;
}

/**
 * 弹簧曲线预设（interpolatingSpring）。
 * 参数顺序：velocity, mass, stiffness, damping。
 *  - snappy：清脆回弹，适合按钮/图标点按。
 *  - soft：柔和回弹，适合卡片/列表项入场。
 *  - gentle：绵长回弹，适合共享元素/页面转场。
 */
export function springSnappy() {
  return curves.interpolatingSpring(0, 1, 380, 30);
}

export function springSoft() {
  return curves.interpolatingSpring(0, 1, 280, 24);
}

export function springGentle() {
  return curves.interpolatingSpring(0, 1, 200, 20);
}

/** 动效时长（毫秒）。 */
export class Motion {
  static readonly tap: number = 120;
  static readonly press: number = 150;
  static readonly sheet: number = 360;
  static readonly fade: number = 300;
  static readonly stagger: number = 60;
}

/** 圆角规范（iOS 分层）。 */
export class Radius {
  static readonly sm: number = 10;
  static readonly md: number = 14;
  static readonly lg: number = 20;
  static readonly pill: number = 999;
}

/** 毛玻璃规范：模糊半径与半透明填充（按主题取）。 */
export class Glass {
  static readonly blur: number = 30;

  static bgLight(): string {
    return 'rgba(255, 255, 255, 0.62)';
  }

  static bgDark(): string {
    return 'rgba(28, 28, 30, 0.62)';
  }

  static bg(isDark: boolean): string {
    return isDark ? Glass.bgDark() : Glass.bgLight();
  }
}

/** 共享元素转场 ID（一镜到底）。 */
export class TransitionId {
  static readonly cover: string = 'player_cover';
  static readonly miniBar: string = 'mini_player_bar';
}
