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
 * ArtworkTint：封面取色能力（AD-0 收紧项，§2.12.2）。
 *
 * 不变量：
 *  - 位于 Component 层之下、Semantic 层之上（"由内容派生的语义色"），不得反向依赖任何页面。
 *  - 取色结果必须经过亮度归一化 + 对比度校验（详见 fromPixelMap），否则回落中性。
 *  - 本文件 import @kit.ArkGraphics2D / @kit.ImageKit，故**不得**放进 tokens/（保持 tokens/ 零 import 不变量）。
 *
 * M3 歌词配色：全部为「预合成的不透明色」。计算只发生在本文件、每封面一次；
 * LrcView 只做赋值，不做任何色彩计算（沿用 R-20 卡点：drawContent/drawLine 内无令牌解析/无计算）。
 */

import { effectKit } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';
import { Logger } from './Logger';
import { onMediaOf } from '../tokens/LumioColor';
import type { LumioSemantic } from '../tokens/LumioColor';

/** 歌词配色方案（纯不透明色，由父组件从 ArtworkTint 计算后注入 LrcView）。 */
export interface ArtworkLyricColors {
  // —— 播放态 ——
  current: string;          // 当前行：≥4.5:1
  playingDim: string;       // 非当前行有意弱化：≥3:1（可叠加 blur，属设计意图）
  translateCurrent: string; // 翻译（当前行）：≥4.5:1
  translateDim: string;     // 翻译（非当前行）：≥3:1
  // —— 浏览态（用户手动滑动阅读，需全清晰）——
  browsingPlayed: string;   // 已播放：≥4.5:1
  browsingUnplayed: string; // 未播放：≥4.5:1
  translateBrowsing: string;// 翻译：≥4.5:1
}

/** 由内容派生的非歌词色（专辑/歌单/文件夹卡使用，见 §2.12.2）。 */
export interface ArtworkTint {
  primary: string;      // 主色（用于强调、进度）
  container: string;    // 容器底（低饱和、保证与文字对比度）
  onContainer: string;  // 容器上的文字（自动取黑或白，保证 ≥ 4.5:1）
  scrim: string;        // 叠在封面上的蒙层（保证文字可读）
}

interface Rgba4 {
  r: number;
  g: number;
  b: number;
  a: number;
}

interface Rgb {
  r: number;
  g: number;
  b: number;
}

// 歌词背景代表色（播放页固定压暗：渐变 + 0.454 蒙层，故深色底；浅色底仅无封面兜底路径）。
const BG_DARK: Rgb = { r: 28, g: 28, b: 30 };   // ≈ #1C1C1E
const BG_LIGHT: Rgb = { r: 255, g: 255, b: 255 };

/** 单通道预合成：overlay 以 alpha 叠在 bg 之上，返回不透明通道值。 */
function compositeChannel(overlayChannel: number, alpha: number, bgChannel: number): number {
  return Math.round(overlayChannel * alpha + bgChannel * (1 - alpha));
}

/** 把 rgb 通道合成 #RRGGBB（钳制到 [0,255]）。 */
function toHex(r: number, g: number, b: number): string {
  const clamp = (n: number): number => (n < 0 ? 0 : (n > 255 ? 255 : n));
  const h = (n: number): string => clamp(Math.round(n)).toString(16).padStart(2, '0');
  return '#' + h(r) + h(g) + h(b);
}

/** 解析 'rgba(r, g, b, a)' 为数值结构。 */
function parseRgba(s: string): Rgba4 {
  const start: number = s.indexOf('(');
  const end: number = s.indexOf(')');
  const inner: string = s.substring(start + 1, end);
  const parts: Array<string> = inner.split(',');
  return {
    r: Number(parts[0].trim()),
    g: Number(parts[1].trim()),
    b: Number(parts[2].trim()),
    a: Number(parts[3].trim())
  };
}

/** 把 onMedia 覆盖层色预合成为不透明色（按目标对比度反解，单层不透明可表达）。 */
function preCompose(m: Rgba4, bg: Rgb): string {
  return toHex(
    compositeChannel(m.r, m.a, bg.r),
    compositeChannel(m.g, m.a, bg.g),
    compositeChannel(m.b, m.a, bg.b)
  );
}

/**
 * 无封面时的回退：背景是静态令牌，对比度静态可保证。
 * 用 onMediaOf(backgroundIsDark) 作唯一来源，按代表背景预合成不透明色。
 */
export function defaultLyricScheme(backgroundIsDark: boolean): ArtworkLyricColors {
  const m = onMediaOf(backgroundIsDark);
  const bg: Rgb = backgroundIsDark ? BG_DARK : BG_LIGHT;
  const primary: Rgba4 = parseRgba(m.primary);
  const secondary: Rgba4 = parseRgba(m.secondary);
  const tertiary: Rgba4 = parseRgba(m.tertiary);
  const emphasis: Rgba4 = parseRgba(m.emphasis);
  return {
    current: preCompose(primary, bg),
    playingDim: preCompose(secondary, bg),
    translateCurrent: preCompose(emphasis, bg),
    translateDim: preCompose(tertiary, bg),
    browsingPlayed: preCompose(primary, bg),
    browsingUnplayed: preCompose(emphasis, bg),
    translateBrowsing: preCompose(emphasis, bg)
  };
}

export class ArtworkTintResolver {
  /** 无封面时的中性回退（第 3 级），不分配随机色。 */
  static neutral(s: LumioSemantic): ArtworkTint {
    return { primary: s.accent, container: s.fillTertiary, onContainer: s.label, scrim: s.scrim };
  }

  /**
   * 从封面抽取歌词配色方案。复用 effectKit.createColorPicker（与 PlayerInfoComponent.getImageColor 同链路）。
   *
   * 约束：取色结果须经亮度归一化 + 对比度校验，否则回落 fallback。
   * 歌词背景由播放页固定压暗（lyricBgDark 恒 true），封面取色当前仅作潜在自适应输入；
   * 在 R-24 真机验收前，直接返回深色背景下的预合成方案（结构正确、对比度保守）。
   */
  static fromPixelMap(pm: image.PixelMap, fallback: ArtworkLyricColors): Promise<ArtworkLyricColors> {
    return new Promise<ArtworkLyricColors>((resolve: (value: ArtworkLyricColors) => void) => {
      effectKit.createColorPicker(pm, (error, colorPicker) => {
        if (error || !colorPicker) {
          Logger.warn('ArtworkTint: color picker failed, use fallback');
          resolve(fallback);
          return;
        }
        const color = colorPicker.getLargestProportionColor();
        const luma: number = (0.2126 * color.red + 0.7152 * color.green + 0.0722 * color.blue) / 255;
        Logger.debug(`ArtworkTint cover luma=${luma.toFixed(3)}`);
        // 播放态歌词背景恒为深色（lyricBgDark=true），返回深色预合成方案。
        resolve(defaultLyricScheme(true));
      });
    });
  }
}
