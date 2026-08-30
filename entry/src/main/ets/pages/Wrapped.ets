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

import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';
import { AudioRendererController } from '../utils/AudioRendererController';
import { curves } from '@kit.ArkUI';
import { WrappedBody } from '../components/SettingsSubPageBodies';

@Builder
export function WrappedBuilder() {
  NavDestination() {
    Wrapped()
  }
  .hideTitleBar(true)
}

@Component
struct Wrapped {
  pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();

  /** 主导航栈版本：点击 TopSongs 进入播放页（一镜到底）。Body 内简化。 */
  build() {
    NavDestination() {
      Column() {
        WrappedBody({ onBack: () => this.pathStack.pop() })
      }
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .hideTitleBar(true)
  }
}
