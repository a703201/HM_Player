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
import { Settings } from './Settings';
import { About } from './About';

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

  @State menuScales: number[] = [1.0, 1.0, 1.0, 1.0, 1.0];
  @State menuPressed: boolean[] = [false, false, false, false, false];
  @State favCount: number = 0;
  @State songCount: number = 0;
  @State histCount: number = 0;
  @State playlistCount: number = 0;
  private countIntervalId: number = -1;
  @State appVersionDisplay: string = 'Lumio Music';
  /** 半蒙面 Sheet 调度：'' 无 / 'settings' / 'about'；sheetVisible 驱动 bindSheet 的 $$ 双向绑定。 */
  @State sheetKind: string = '';
  @State sheetVisible: boolean = false;

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
    this.songCount = this.store.songs.length;
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
        .margin({ right: 16 })

      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)

        if (subtitle) {
          Text(subtitle)
            .fontSize(12)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (showArrow) {
        Image($r('app.media.ic_hm_more'))
          .width(16)
          .height(16)
          .fillColor(this.getThemeColors().secondaryText)
      }
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.menuPressed[index] ? 'rgba(120, 120, 128, 0.12)' : this.getThemeColors().cardBg)
    .borderRadius(14)
    .margin({ bottom: 8 })
    .scale({ x: this.menuScales[index] ?? 1.0, y: this.menuScales[index] ?? 1.0 })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 20 })))
    .animation({ duration: 300, curve: Curve.EaseOut, delay: 200 + index * 60 })
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
        // 快速统计（头像 / 用户名 / 已收藏 行已按需求移除）
        Row() {
          Column() {
            Text(`${SettingsStore.getInstance().getPrivacyStats() ? this.songCount : '—'}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FA2759')
            Text('歌曲')
              .fontSize(11)
              .fontColor(this.getThemeColors().secondaryText)
              .margin({ top: 2 })
          }
          .layoutWeight(1)

          Column() {
            Text(`${SettingsStore.getInstance().getPrivacyStats() ? this.favCount : '—'}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#34C759')
            Text('收藏')
              .fontSize(11)
              .fontColor(this.getThemeColors().secondaryText)
              .margin({ top: 2 })
          }
          .layoutWeight(1)

          Column() {
            Text(`${SettingsStore.getInstance().getPrivacyStats() ? this.histCount : '—'}`)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9500')
            Text('历史')
              .fontSize(11)
              .fontColor(this.getThemeColors().secondaryText)
              .margin({ top: 2 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 32, right: 32, top: this.topHeight + 16, bottom: 20 })
        .backgroundColor(this.getThemeColors().secondaryBg)

        // 菜单区
        Column() {
          this.buildMenuItem(
            $r('app.media.ic_collect'),
            '我的收藏',
            `${this.favCount} 首歌曲`,
            true,
            0,
            '#FA2759',
            () => {
              this.pathStack.pushPathByName('Favorites', null);
            }
          )

          this.buildMenuItem(
            $r('app.media.ic_song_list'),
            '我的歌单',
            `${this.playlistCount} 个歌单`,
            true,
            1,
            '#5856D6',
            () => {
              this.pathStack.pushPathByName('Playlists', null);
            }
          )

          this.buildMenuItem(
            $r('app.media.ic_hm_list'),
            '播放历史',
            `${this.histCount} 首歌曲`,
            true,
            2,
            '#FF9500',
            () => {
              this.pathStack.pushPathByName('PlayHistory', null);
            }
          )
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8 })

        // 分区标题
        Text('更多')
          .fontSize(13)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: 16, bottom: 12, left: 16 })
          .textAlign(TextAlign.Start)
          .width('100%')

        Column() {
          this.buildMenuItem(
            $r('app.media.ic_hm_settings'),
            '设置',
            '',
            true,
            3,
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
            4,
            '#5856D6',
            () => {
              this.sheetKind = 'about';
              this.sheetVisible = true;
            }
          )
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(this.getThemeColors().bg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .bindSheet($$this.sheetVisible, this.sheetContent(), {
      detents: ['90%'],
      dragBar: true,
      showClose: true
    })
  }

  /** 单一半蒙面 Sheet：依 sheetKind 切换设置 / 关于内容，避免在同一节点挂两个 bindSheet 互相干扰。 */
  @Builder
  private sheetContent() {
    if (this.sheetKind === 'settings') {
      Settings({
        onRequestClose: () => {
          this.sheetVisible = false;
          this.sheetKind = '';
        },
        onNavigate: (name: string) => {
          this.sheetVisible = false;
          this.sheetKind = '';
          this.pathStack.pushPathByName(name, null);
        }
      })
    } else if (this.sheetKind === 'about') {
      About({
        onRequestClose: () => {
          this.sheetVisible = false;
          this.sheetKind = '';
        }
      })
    }
  }
}
