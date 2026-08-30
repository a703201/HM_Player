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

import { HdsNavigation } from '@kit.UIDesignKit';
import { SplashView } from './Splash';

@Entry
@Component
struct Index {
  @Provide('navPathStack') pathStack: NavPathStack = new NavPathStack()
  /** 启动页是否结束：结束后淡出 Splash 覆盖层，露出已就绪的主界面。 */
  @State splashDone: boolean = false

  aboutToAppear(): void {
    // 暴露导航栈到 AppStorage，供 Want「用 Lumio 打开」场景跨 Ability 打开播放页
    AppStorage.setOrCreate('navPathStack', this.pathStack);
  }

  build() {
    Stack() {
      HdsNavigation(this.pathStack) {
      }
      .onAppear(() => {
        this.pathStack.pushPathByName('Layout', null, false);
      })
      .hideNavBar(true)
      .hideTitleBar(true)
      .mode(NavigationMode.Stack)

      if (!this.splashDone) {
        SplashView()
      }
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      // 品牌展示约 1.2s 后淡出，露出主界面（此时 Layout 已挂载于导航栈背后）
      setTimeout(() => {
        this.splashDone = true;
      }, 1200);
    })
  }
}
