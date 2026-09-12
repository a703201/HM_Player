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

import { ThemeManager } from '../utils/ThemeManager';
import { semanticOf } from '../tokens/LumioColor';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';
import { SPACE_SM } from '../tokens/LumioScale';

@Builder
export function SplashViewBuilder() {
  SplashView()
}

/**
 * 启动页（Splash）：首屏品牌展示，覆盖在内容之上，由 Index 控制淡出时机。
 * 纯视觉，不承载业务；淡入动画后由外层 setTimeout 翻转可见态即可。
 */
@Component
export struct SplashView {
  @StorageProp('isDark') isDark: boolean = false;
  @State logoScale: number = 0.6;
  @State logoOpacity: number = 0;

  aboutToAppear(): void {
    setTimeout(() => {
      this.logoScale = 1.0;
      this.logoOpacity = 1.0;
    }, 80);
  }

  build() {
    Column() {
      Column() {
        Image($r('app.media.logo'))
          .width(120)
          .height(120)
          .borderRadius(28)
          .scale({ x: this.logoScale, y: this.logoScale })
          .opacity(this.logoOpacity)
          .animation({ duration: 700, curve: LumioTheme.curve(SpringKind.Crisp) })
          .shadow({
            radius: 18,
            color: semanticOf(this.isDark).fillAccentMuted,
            offsetX: 0,
            offsetY: 8
          })

        Text('Lumio Music')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor(semanticOf(this.isDark).label)
          .margin({ top: SPACE_SM.loose })
          .opacity(this.logoOpacity)
          .animation({ duration: 700, curve: LumioTheme.curve(SpringKind.Crisp), delay: 150 })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(semanticOf(this.isDark).background)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
