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

import deviceInfo from '@ohos.deviceInfo';

/**
 * API 版本兼容工具。
 *
 * 项目编译基于 API 26 SDK，但最低兼容 API 24（HarmonyOS 6.1.1），目标 API 26。
 * 部分鸿蒙新特性为 API 26 专属（如 ContainerReader 组件、uiMaterial.systemMaterial 方法），
 * 在 API 24 真机上实例化/调用会直接崩溃。本工具在运行期读取设备 API 版本，
 * 供各组件对 API 26 专属能力做优雅降级（分支渲染 / 走兼容写法）。
 */
export class ApiCompat {
  /** 当前设备 SDK API 版本，例如 API 24 / API 26。 */
  static get sdkApiVersion(): number {
    return deviceInfo.sdkApiVersion;
  }

  /**
   * 是否达到指定 API 版本（含）。
   * @param api 目标 API 版本，例如 ApiCompat.API_26
   */
  static isAtLeast(api: number): boolean {
    return ApiCompat.sdkApiVersion >= api;
  }

  static readonly API_24: number = 24;
  static readonly API_26: number = 26;
}
