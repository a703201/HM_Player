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

import { curves } from '@kit.ArkUI';
import { AudioRendererController } from '../utils/AudioRendererController';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { BreakpointSystem } from '../common/utils/BreakpointSystem';
import { PlayerInfoComponent } from '../components/PlayerInfoComponent';
import { MusicStore } from '../services/MusicStore';
import { SongItem } from '../models/music';
import { Motion, springSoft } from '../common/utils/DesignSystem';

@Builder
export function PlayerPageBuilder() {
  PlayerPage();
}

@Component
struct PlayerPage {
  @Consume('navPathStack') pathStack: NavPathStack;
  @StorageLink('selectIndex') selectIndex: number = 0;
  @StorageLink('songList') songList: SongItem[] = [];
  @State isShowPlay: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @State entered: boolean = false;
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  aboutToAppear(): void {
    const store = MusicStore.getInstance();
    const savedIndex = AppStorage.get('selectIndex') as number ?? 0;
    if (savedIndex >= 0 && savedIndex < store.songs.length) {
      store.currentIndex = savedIndex;
    }
    AppStorage.setOrCreate('songList', store.songs);
    AppStorage.setOrCreate('selectIndex', store.currentIndex);
    AudioRendererController.getInstance();
    this.breakpointSystem.register();
  }

  aboutToDisappear(): void {
    this.breakpointSystem.unregister();
  }

  // 一镜到底：退出时把出栈包进 animateTo，触发共享元素反向收起
  private back(): void {
    this.getUIContext().animateTo(
      { curve: curves.interpolatingSpring(0, 1, 342, 38) },
      () => {
        this.pathStack.pop(false);
      }
    );
  }

  build() {
    NavDestination() {
      Column() {
        PlayerInfoComponent({ isShowPlay: this.isShowPlay })
      }
      .width('100%')
      .height('100%')
      .opacity(this.entered ? 1 : 0)
      .scale({ x: this.entered ? 1 : 0.98, y: this.entered ? 1 : 0.98 })
    }
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .hideTitleBar(true)
    .onWillShow(() => {
      // NavDestination 生命周期（onWillShow/onWillHide 为 API 10+ 通用能力）：入场时以弹簧曲线淡入内容
      this.getUIContext().animateTo({ duration: Motion.fade, curve: springSoft() }, () => {
        this.entered = true;
      });
    })
    .onWillHide(() => {
      this.entered = false;
    })
    .onBackPressed(() => {
      this.back();
      return true;
    })
  }
}
