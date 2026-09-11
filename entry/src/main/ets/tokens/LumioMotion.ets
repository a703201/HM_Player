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
 * 令牌层 L2（弹簧曲线工厂）。
 *
 * 本文件是令牌层中「唯一」允许 import { curves } from '@kit.ArkUI' 的文件。
 * 不 import SettingsStore——可达性降级布尔由调用方（LumioTheme）传入，
 * 以便 Form 卡片进程也能安全复用 LumioMotionSpec 的数值。
 */
import { curves } from '@kit.ArkUI';
import type { ICurve } from '@kit.ArkUI';
import { LumioDurations, LumioSpringSpec, LumioSpringSpecs } from './LumioMotionSpec';

export enum SpringKind {
  Crisp,
  Snappy,
  Soft,
  Gentle,
  Bouncy,
  Hero
}

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
    if (kind === SpringKind.Crisp) {
      return LumioSpringSpecs.crisp;
    }
    if (kind === SpringKind.Snappy) {
      return LumioSpringSpecs.snappy;
    }
    if (kind === SpringKind.Soft) {
      return LumioSpringSpecs.soft;
    }
    if (kind === SpringKind.Gentle) {
      return LumioSpringSpecs.gentle;
    }
    if (kind === SpringKind.Bouncy) {
      return LumioSpringSpecs.bouncy;
    }
    return LumioSpringSpecs.hero;
  }
}
