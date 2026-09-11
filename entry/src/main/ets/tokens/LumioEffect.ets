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
 * 令牌层 L2（阴影 / 海拔 / 毛玻璃）。
 *
 * 不变量：本文件「零 import」——不依赖 @kit.* / AppStorage / Preferences / Logger。
 * 主应用、Service 与 Form 卡片进程均可直接引用。
 *
 * 深色下投影几乎不可见，Apple 的做法是用 hairline 描边替代；因此每个海拔的
 * 深色分支仍以黑色 + 更高 alpha 表达（结构一致），实际可见性由边框补足。
 */

export interface LumioShadow {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export interface LumioElevation {
  none: LumioShadow;
  low: LumioShadow;
  mid: LumioShadow;
  high: LumioShadow;
  modal: LumioShadow;
  accent: LumioShadow;
  cover: LumioShadow;
}

export const ELEVATION_LIGHT: LumioElevation = {
  none: { radius: 0, color: 'rgba(0, 0, 0, 0)', offsetX: 0, offsetY: 0 },
  low: { radius: 8, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 2 },
  mid: { radius: 12, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 4 },
  high: { radius: 22, color: 'rgba(0, 0, 0, 0.18)', offsetX: 0, offsetY: 8 },
  modal: { radius: 32, color: 'rgba(0, 0, 0, 0.24)', offsetX: 0, offsetY: 12 },
  accent: { radius: 12, color: 'rgba(250, 39, 89, 0.35)', offsetX: 0, offsetY: 4 },
  cover: { radius: 6, color: 'rgba(0, 0, 0, 0.18)', offsetX: 0, offsetY: 2 }
};

export const ELEVATION_DARK: LumioElevation = {
  none: { radius: 0, color: 'rgba(0, 0, 0, 0)', offsetX: 0, offsetY: 0 },
  low: { radius: 8, color: 'rgba(0, 0, 0, 0.40)', offsetX: 0, offsetY: 2 },
  mid: { radius: 12, color: 'rgba(0, 0, 0, 0.60)', offsetX: 0, offsetY: 4 },
  high: { radius: 22, color: 'rgba(0, 0, 0, 0.60)', offsetX: 0, offsetY: 8 },
  modal: { radius: 32, color: 'rgba(0, 0, 0, 0.70)', offsetX: 0, offsetY: 12 },
  accent: { radius: 12, color: 'rgba(250, 39, 89, 0.45)', offsetX: 0, offsetY: 4 },
  cover: { radius: 6, color: 'rgba(0, 0, 0, 0.40)', offsetX: 0, offsetY: 2 }
};

export interface LumioGlass {
  blur: number;
  fill: string;
  border: string;
  borderWidth: number;
}

export interface LumioGlassSet {
  thin: LumioGlass;
  regular: LumioGlass;
  thick: LumioGlass;
}

// regular 与现网 Glass.bgLight/bgDark（0.62）完全等价 → P1 迁移零视觉变化
export const GLASS_LIGHT: LumioGlassSet = {
  thin: { blur: 20, fill: 'rgba(255, 255, 255, 0.50)', border: 'rgba(255, 255, 255, 0.70)', borderWidth: 0.5 },
  regular: { blur: 30, fill: 'rgba(255, 255, 255, 0.62)', border: 'rgba(255, 255, 255, 0.70)', borderWidth: 0.5 },
  thick: { blur: 40, fill: 'rgba(255, 255, 255, 0.75)', border: 'rgba(255, 255, 255, 0.70)', borderWidth: 0.5 }
};

export const GLASS_DARK: LumioGlassSet = {
  thin: { blur: 20, fill: 'rgba(28, 28, 30, 0.50)', border: 'rgba(255, 255, 255, 0.08)', borderWidth: 0.5 },
  regular: { blur: 30, fill: 'rgba(28, 28, 30, 0.62)', border: 'rgba(255, 255, 255, 0.08)', borderWidth: 0.5 },
  thick: { blur: 40, fill: 'rgba(28, 28, 30, 0.72)', border: 'rgba(255, 255, 255, 0.08)', borderWidth: 0.5 }
};
