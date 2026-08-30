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

import { StartupTask, Context } from '@kit.AbilityKit';

/**
 * AppStartup 启动任务（示例）：在 AbilityStage 构造阶段并行预执行轻量初始化。
 *
 * 此处建立启动框架的占位任务，验证 AppStartup 自动执行链路；后续可安全扩展为
 * 封面缓存预热、高频资源预载、配置预解析等。约束：@Sendable 上下文内不可访问
 * 非可序列化对象，故仅做无副作用的标记返回，避免在启动关键路径引入阻塞。
 */
@Sendable
export default class LumioCoverPreloadTask extends StartupTask {
  override async init(context: Context): Promise<Object | void> {
    // TODO(后续迭代): 在此并行预热 CoverCache、预载高频歌单，禁止访问非 sendable 单例。
    return 'LumioCoverPreloadTask';
  }
}
