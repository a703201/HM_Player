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
 * 令牌层 L2（弹簧与时长纯数值）。
 *
 * 不变量：本文件「零 import」——仅存数字，Form 卡片进程可读。
 * 真正的曲线对象由 LumioMotion.ets 用 curves 工厂生成（该文件才允许 import @kit.ArkUI）。
 *
 * 弹簧：curves.interpolatingSpring(velocity, mass, stiffness, damping)
 * 阻尼比 ζ = damping / (2·√(stiffness·mass))；过冲 ≈ e^(−πζ/√(1−ζ²))
 * - crisp（默认）：ζ=1.00，0% 过冲，临界阻尼，用于控件显隐/状态切换/列表项出现
 * - bouncy：ζ=0.58，10.7% 过冲，仅用于带惯性手势的拖拽释放/滑块吸附/下拉关闭
 */

export interface LumioSpringSpec {
  velocity: number;
  mass: number;
  stiffness: number;
  damping: number;
}

export class LumioSpringSpecs {
  static readonly crisp: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 380, damping: 39 };
  static readonly snappy: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 380, damping: 30 };
  static readonly soft: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 280, damping: 24 };
  static readonly gentle: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 200, damping: 20 };
  static readonly bouncy: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 500, damping: 26 };
  static readonly hero: LumioSpringSpec = { velocity: 0, mass: 1, stiffness: 342, damping: 38 };
}

export class LumioDurations {
  static readonly micro: number = 80;
  static readonly tap: number = 120;
  static readonly press: number = 150;
  static readonly quick: number = 200;
  static readonly fade: number = 300;
  static readonly sheet: number = 360;
  static readonly page: number = 400;
  static readonly stagger: number = 60;
}
