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

import { ThemeManager } from '../../utils/ThemeManager';
import { SPACE_SM, LUMIO_RADIUS } from '../../tokens/LumioScale';

/**
 * Inset Grouped 容器：整组圆角卡片（backgroundColor = cardBg），叠在玻璃之上形成「卡中卡」，
 * 对标 iOS 设置分组。统一内距：左右 base(16) / 上下 cozy(12)。
 *
 * 通过 ThemeManager.getColors() 取色（随 isDark 切换；宿主组件持有 @StorageProp('isDark') 会触发重渲染）。
 *
 * @param expand 为 true 时容器沿主轴撑满父级剩余空间（用于内部含 layoutWeight(1) 的 List 等场景）；
 *               默认 false（内容高度自适应，适合 SongDetailSheet 等定高内容块）。
 */
@Component
export struct GroupedSheetContainer {
  /** 内容槽：由宿主组件以尾随 builder 传入。 */
  @BuilderParam content: () => void;
  /** 是否沿主轴撑满父级剩余空间。 */
  @Prop expand: boolean = false;

  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .backgroundColor(ThemeManager.getColors().cardBg)
    .borderRadius(LUMIO_RADIUS.md)
    .padding({
      top: SPACE_SM.cozy,
      bottom: SPACE_SM.cozy,
      left: SPACE_SM.base,
      right: SPACE_SM.base
    })
    .layoutWeight(this.expand ? 1 : 0);
  }
}

/**
 * Inset Grouped 行间分隔线（0.5vp hairline）。
 *
 * @param color 分隔线颜色（通常传 getThemeColors().separator）
 * @param startMargin 左缩进（默认 80 + cozy，对齐 SongDetailSheet 的 InfoRow 值文本左缘）
 * @param endMargin 右缩进（默认 base，与卡片右侧内距对齐）
 */
@Builder
export function GroupedSheetHairline(
  color: ResourceColor,
  startMargin: number = 80 + SPACE_SM.cozy,
  endMargin: number = SPACE_SM.base
) {
  Divider()
    .strokeWidth(0.5)
    .color(color)
    .width('100%')
    .margin({ left: startMargin, right: endMargin });
}
