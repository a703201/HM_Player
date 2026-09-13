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

import { MusicStore } from '../services/MusicStore';
import { getAppVersionDisplay } from '../utils/AppInfoUtil';
import { SettingsStore } from '../utils/SettingsStore';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { semanticOf } from '../tokens/LumioColor';
import { Settings } from './Settings';
import { About } from './About';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';
import { TYPE_SM, SPACE_SM } from '../tokens/LumioScale';

@Builder
export function MineBuilder() {
  Mine()
}

@Component
export struct Mine {
  @Consume('navPathStack') pathStack: NavPathStack;
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('bottomHeight') bottomHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @State menuScales: number[] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
  @State menuPressed: boolean[] = [false, false, false, false, false, false];
  @State favCount: number = 0;
  @State histCount: number = 0;
  @State playlistCount: number = 0;
  private countIntervalId: number = -1;
  @State appVersionDisplay: string = 'Lumio Music';
  /** 半蒙面 Sheet 调度：'' 无 / 'settings' / 'about'；sheetVisible 驱动 bindSheet 的 $$ 双向绑定。 */
  @State sheetKind: string = '';
  @State sheetVisible: boolean = false;
  /** 关于页点「新手引导」后，先关本 Sheet 再开引导 Sheet；用此标志在 onDisappear 衔接，避免两 sheet 同帧叠加出现空白 large 页。 */
  @State pendingOnboarding: boolean = false;

  aboutToAppear(): void {
    this.appVersionDisplay = getAppVersionDisplay();
    // 实时计数：轮询 store 写入 @State，收藏/历史/歌单变化后即时刷新（无需退出重进）
    this.refreshCounts();
    this.countIntervalId = setInterval(() => { this.refreshCounts(); }, 600);
  }

  aboutToDisappear(): void {
    if (this.countIntervalId >= 0) {
      clearInterval(this.countIntervalId);
      this.countIntervalId = -1;
    }
  }

  private refreshCounts(): void {
    this.favCount = this.store.getFavoriteSongs().length;
    this.histCount = this.store.recentlyPlayed.length;
    this.playlistCount = this.store.playlists.length;
  }

  @Builder
  buildMenuItem(icon: ResourceStr, title: string, subtitle: string = '', showArrow: boolean = true, index: number = 0, iconColor: string = this.getThemeColors().primaryText, onClick: () => void = () => {}) {
    Row() {
      // 仅图标本身，不要底色背景（苹果风：彩色图标直接呈现，无圆角色块）
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(iconColor)
        .margin({ right: SPACE_SM.base })

      Column() {
        Text(title)
          .fontSize(TYPE_SM.headline.size)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)

        if (subtitle) {
          Text(subtitle)
            .fontSize(TYPE_SM.caption1.size)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ top: SPACE_SM.hair })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (showArrow) {
        Image($r('app.media.ic_public_arrow_right'))
          .width(16)
          .height(16)
          .fillColor(this.getThemeColors().secondaryText)
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: SPACE_SM.base, right: SPACE_SM.base })
    .backgroundColor(this.menuPressed[index] ? semanticOf(this.isDark).fillTertiary : this.getThemeColors().cardBg)
    .borderRadius(16)
    .margin({ bottom: SPACE_SM.compact })
    .scale({ x: this.menuScales[index] ?? 1.0, y: this.menuScales[index] ?? 1.0 })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 20 })))
    .animation({ duration: 300, curve: LumioTheme.curve(SpringKind.Crisp), delay: 200 + index * 60 })
    .onClick(onClick)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        let scales = [...this.menuScales];
        scales[index] = 0.97;
        this.menuScales = scales;
        let pressed = [...this.menuPressed];
        pressed[index] = true;
        this.menuPressed = pressed;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        let scales = [...this.menuScales];
        scales[index] = 1.0;
        this.menuScales = scales;
        let pressed = [...this.menuPressed];
        pressed[index] = false;
        this.menuPressed = pressed;
      }
    })
  }

  build() {
    Scroll() {
      Column() {
        // 标题栏（与音乐库页一致：左侧 24/Bold 大标题 + 右侧圆角操作入口）。
        // 右侧放「我的收藏」收藏星快捷入口，跳到收藏页；保留与音乐库「导入」pill 同等的视觉权重。
        Row() {
          Text('我的')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .layoutWeight(1)
            .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: this.topHeight + 8, bottom: SPACE_SM.cozy })
        }
        .width('100%')

        // 菜单区
        Column() {
          this.buildMenuItem(
            $r('app.media.ic_public_collect'),
            '我的收藏',
            `${this.favCount} 首歌曲`,
            true,
            0,
            this.getThemeColors().secondaryText,
            () => {
              this.pathStack.pushPathByName('Favorites', null);
            }
          )

          this.buildMenuItem(
            $r('app.media.ic_public_view_list'),
            '我的歌单',
            `${this.playlistCount} 个歌单`,
            true,
            1,
            this.getThemeColors().secondaryText,
            () => {
              this.pathStack.pushPathByName('Playlists', null);
            }
          )

          this.buildMenuItem(
            $r('app.media.ic_public_view_list'),
            '播放历史',
            `${this.histCount} 首歌曲`,
            true,
            2,
            this.getThemeColors().secondaryText,
            () => {
              this.pathStack.pushPathByName('PlayHistory', null);
            }
          )

          this.buildMenuItem(
            $r('app.media.ic_public_folder'),
            '文件夹浏览',
            '按来源目录整理',
            true,
            3,
            this.getThemeColors().secondaryText,
            () => {
              this.pathStack.pushPathByName('FolderBrowse', null);
            }
          )
        }
        .width('100%')
        .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: SPACE_SM.compact })

        // 分区标题
        Text('更多')
          .fontSize(TYPE_SM.footnote.size)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: SPACE_SM.base, bottom: SPACE_SM.cozy, left: SPACE_SM.base })
          .textAlign(TextAlign.Start)
          .width('100%')

        Column() {
          this.buildMenuItem(
            $r('app.media.ic_public_settings'),
            '设置',
            '',
            true,
            4,
            this.getThemeColors().secondaryText,
            () => {
              this.sheetKind = 'settings';
              this.sheetVisible = true;
            }
          )

          this.buildMenuItem(
            $r('app.media.ic_logo'),
            '关于',
            this.appVersionDisplay,
            true,
            5,
            this.getThemeColors().secondaryText,
            () => {
              this.sheetKind = 'about';
              this.sheetVisible = true;
            }
          )
        }
        .width('100%')
        .padding({ left: SPACE_SM.base, right: SPACE_SM.base })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(this.getThemeColors().bg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .bindSheet($$this.sheetVisible, this.sheetContent(), {
      detents: [SheetSize.LARGE, SheetSize.MEDIUM],
      dragBar: true,
      showClose: true,
      backgroundColor: this.getThemeColors().surfaceOverlay,
      onDisappear: () => {
        // Sheet 真正消失后才复位 kind，防止关闭动画期间 sheetContent 因 kind='' 渲染空白。
        this.sheetKind = '';
        // 关于页「新手引导」：本 Sheet 关闭完成后，再弹出引导 Sheet（Layout 承载）。
        if (this.pendingOnboarding) {
          this.pendingOnboarding = false;
          AppStorage.setOrCreate('showOnboarding', true);
        }
      }
    })
  }

  /** 单一半蒙面 Sheet：依 sheetKind 切换设置 / 关于内容，避免在同一节点挂两个 bindSheet 互相干扰。
   *  - 子页跳转（ManageSongs/DuplicateSongs/Wrapped/PrivacyPolicy）由 Settings/About 内部 state 处理，
   *    不再关闭 sheet 走主导航栈，符合「半模态 sheet 内页面切换」语义。 */
  @Builder
  private sheetContent() {
    if (this.sheetKind === 'settings') {
      Settings({
        onRequestClose: () => {
          this.sheetVisible = false;
        }
      })
    } else if (this.sheetKind === 'about') {
      About({
        onRequestClose: () => {
          this.sheetVisible = false;
        },
        onStartOnboarding: () => {
          // 先标记待开引导，再关本 Sheet；由 bindSheet 的 onDisappear 真正关闭后再弹引导，
          // 避免「关于 Sheet 未关 + 引导 Sheet 已开」同帧叠加出空白 large 页。
          this.pendingOnboarding = true;
          this.sheetVisible = false;
        }
      })
    }
  }
}
