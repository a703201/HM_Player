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

import { ApiCompat } from './ApiCompat';
import { SPACE_SM } from '../../tokens/LumioScale';
// 仅类型导入（编译期擦除）：API 24 真机不存在 @ohos.arkui.uiMaterial 模块，
// 此处仅用于注解 material 类型，运行期通过 acquireSheetMaterial() 内的动态 import() 加载，
// 绝不在此做值导入（否则 API 24 运行期会崩溃）。
import type uiMaterial from '@ohos.arkui.uiMaterial';

/**
 * 获取系统材质（API 26 沉浸毛玻璃）。
 *
 * - API 26：动态 import('@ohos.arkui.uiMaterial') → 构造 ImmersiveMaterial({ style: REGULAR })；
 * - API 24：直接 resolve(undefined)，不加载该模块；
 * - 任何 import / 构造异常：catch 兜底 resolve(undefined)。
 *
 * 调用方据此在 SheetScaffold 中二选一：有值走 systemMaterial，否则走纯色 surfaceOverlay 兜底。
 */
export function acquireSheetMaterial(): Promise<uiMaterial.Material | undefined> {
  return new Promise<uiMaterial.Material | undefined>(
    (resolve: (value: uiMaterial.Material | undefined) => void): void => {
      if (!ApiCompat.isAtLeast(ApiCompat.API_26)) {
        resolve(undefined);
        return;
      }
      import('@ohos.arkui.uiMaterial')
        .then((mod: ESObject): void => {
          const def: ESObject = mod.default;
          const materialObj: ESObject = new (def.ImmersiveMaterial as ESObject)({
            style: (def.ImmersiveStyle as ESObject).REGULAR
          });
          resolve(materialObj as uiMaterial.Material);
        })
        .catch((): void => {
          resolve(undefined);
        });
    }
  );
}

/**
 * 半模态根容器脚手架（@Component + @BuilderParam 内容槽，ArkTS 内容槽标准机制）。
 *
 * - API 26 且材质就绪：根 Column 启用 systemMaterial 系统级毛玻璃（自适应深浅色与算力档位）；
 * - 其余情况（API 24 / 材质未就绪 / 加载失败）：根 Column 用纯色 fallbackColor 兜底。
 *
 * ⚠️ 硬规则（设计文档 §2.5.5）：两分支互斥，绝不同时在同一 Column 上设 systemMaterial + backgroundColor。
 * 两个 if/else 分支各自只设置其一。
 *
 * 统一内距：左右 roomy(20) / 底 loose(24)（与 SongDetailSheet 既有写法一致，顶距由内容自行控制）。
 */
@Component
export struct SheetScaffold {
  /** 系统材质实例：API 26 经动态 import 注入；API 24 / 未就绪为 undefined（走纯色兜底）。 */
  @Prop material: uiMaterial.Material | undefined = undefined;
  /** API 24 降级纯色兜底（通常传 surfaceOverlay）。 */
  @Prop fallbackColor: ResourceColor = '#FFFFFF';
  /** 内容槽：由宿主组件以尾随 builder 传入，捕获宿主 this 上下文（方法/状态）。 */
  @BuilderParam content: () => void;

  build() {
    if (ApiCompat.isAtLeast(ApiCompat.API_26) && this.material !== undefined) {
      Column() {
        this.content();
      }
      .width('100%')
      .padding({ left: SPACE_SM.roomy, right: SPACE_SM.roomy, bottom: SPACE_SM.loose })
      .systemMaterial(this.material);
    } else {
      Column() {
        this.content();
      }
      .width('100%')
      .padding({ left: SPACE_SM.roomy, right: SPACE_SM.roomy, bottom: SPACE_SM.loose })
      .backgroundColor(this.fallbackColor);
    }
  }
}
