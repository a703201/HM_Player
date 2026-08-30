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

import { StartupConfigEntry, StartupConfig } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';

/**
 * AppStartup 启动参数配置入口（configEntry）。
 *
 * 由 module.json5 的 appStartup 引用，框架在 AbilityStage 构造期调用 onConfig()
 * 获取超时与监听器配置；具体任务在 resources/base/profile/startup_config.json 中声明。
 * 该回调运行于 AbilityStage 上下文（非 sendable），可直接使用 Logger 等工具。
 */
export default class LumioStartupConfig extends StartupConfigEntry {
  override onConfig(): StartupConfig {
    return {
      timeoutMs: 10000,
      startupListener: {
        onCompleted: (): void => {
          Logger.info('AppStartup', 'all startup tasks completed');
        }
      }
    };
  }
}
