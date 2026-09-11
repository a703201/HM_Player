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
 * 令牌层门面（主应用专用）。
 *
 * 仅 import 本层模块与 SettingsStore；不引用 @kit.ArkUI 的 UI 组件。
 * 「禁止」被 widget/** 引用——Form 卡片进程只能 import 零 import 的
 * LumioColor / LumioScale / LumioEffect / LumioMotionSpec。
 *
 * 动效出口内部读取 SettingsStore 的 reduceMotion 开关，调用方无需关心降级逻辑。
 */
import { LumioSemantic, semanticOf } from './LumioColor';
import { LumioSpace, LumioRadius, LumioType, SPACE_SM, SPACE_MD, SPACE_LG, TYPE_SM, TYPE_LG, LUMIO_RADIUS } from './LumioScale';
import { LumioElevation, LumioGlass, LumioGlassSet, ELEVATION_LIGHT, ELEVATION_DARK, GLASS_LIGHT, GLASS_DARK } from './LumioEffect';
import { LumioMotion, SpringKind } from './LumioMotion';
import { SettingsStore } from '../utils/SettingsStore';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
export { SpringKind };

export class LumioTheme {
  static semantic(isDark: boolean): LumioSemantic {
    return semanticOf(isDark);
  }

  static space(bp: string): LumioSpace {
    if (bp === BreakpointConstants.BREAKPOINT_LG) {
      return SPACE_LG;
    }
    if (bp === BreakpointConstants.BREAKPOINT_MD) {
      return SPACE_MD;
    }
    return SPACE_SM;
  }

  static type(bp: string): LumioType {
    if (bp === BreakpointConstants.BREAKPOINT_LG) {
      return TYPE_LG;
    }
    return TYPE_SM;
  }

  static radius(): LumioRadius {
    return LUMIO_RADIUS;
  }

  static glass(isDark: boolean): LumioGlassSet {
    return isDark ? GLASS_DARK : GLASS_LIGHT;
  }

  static elevation(isDark: boolean): LumioElevation {
    return isDark ? ELEVATION_DARK : ELEVATION_LIGHT;
  }

  /** 动效：内部读可达性开关，调用方无需关心。 */
  static curve(kind: SpringKind): ICurve {
    return LumioMotion.spring(kind, SettingsStore.getInstance().getReduceMotion());
  }

  static duration(base: number): number {
    return LumioMotion.duration(base, SettingsStore.getInstance().getReduceMotion());
  }

  static stagger(index: number): number {
    return LumioMotion.staggerDelay(index, SettingsStore.getInstance().getReduceMotion());
  }
}
