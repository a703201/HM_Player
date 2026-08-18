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

  @State avatarScale: number = 0.8;
  @State avatarOpacity: number = 0;
  @State avatarStrokeWidth: number = 2;
  @State avatarRotation: number = 0;
  @State menuScales: number[] = [1.0, 1.0, 1.0, 1.0, 1.0];
  @State favCount: number = 0;
  @State songCount: number = 0;
  @State histCount: number = 0;
  @State playlistCount: number = 0;
  private countIntervalId: number = -1;
  @State appVersionDisplay: string = 'Lumio Music';
  private breatheInterval: number = -1;
  private rotateInterval: number = -1;

  aboutToAppear(): void {
    this.appVersionDisplay = getAppVersionDisplay();
    setTimeout(() => {
      this.avatarScale = 1.0;
      this.avatarOpacity = 1.0;
    }, 100);
    // R-18/F-13：降低动态效果开启时不做头像呼吸动画
    if (!SettingsStore.getInstance().getReduceMotion()) {
      this.breatheInterval = setInterval(() => {
        if (this.avatarStrokeWidth === 2) {
          this.avatarStrokeWidth = 4;
        } else {
          this.avatarStrokeWidth = 2;
        }
      }, 2000);
    }
    // 实时计数：轮询 store 写入 @State，收藏/历史/歌单变化后即时刷新（无需退出重进）
    this.refreshCounts();
    this.countIntervalId = setInterval(() => { this.refreshCounts(); }, 600);
  }

  aboutToDisappear(): void {
    if (this.breatheInterval >= 0) {
      clearInterval(this.breatheInterval);
    }
    if (this.rotateInterval >= 0) {
      clearInterval(this.rotateInterval);
    }
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
      // Icon container
      Stack() {
        Image(icon)
          .width(20)
          .height(20)
          .fillColor(Color.White)
      }
      .width(36)
      .height(36)
      .borderRadius(10)
      .backgroundColor(iconColor)
      .margin({ right: 14 })
      .shadow({
        radius: 6,
        color: `${iconColor}33`,
        offsetX: 0,
        offsetY: 2
      })

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
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(14)
    .margin({ bottom: 8 })
    .scale({ x: this.menuScales[index] ?? 1.0, y: this.menuScales[index] ?? 1.0 })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 20 })))
    .animation({ duration: 300, curve: Curve.EaseOut, delay: 200 + index * 60 })
    .onClick(onClick)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        let scales = [...this.menuScales];
        scales[index] = 0.96;
        this.menuScales = scales;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        let scales = [...this.menuScales];
        scales[index] = 1.0;
        this.menuScales = scales;
      }
    })
  }

  build() {
    Scroll() {
      Column() {
        // Header section with gradient
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            // Outer ring
            Circle()
              .width(96)
              .height(96)
              .fill(Color.Transparent)
              .stroke('#FA2759')
              .strokeWidth(this.avatarStrokeWidth)
              .animation({ duration: 1000, curve: Curve.EaseInOut })

            // Inner circle
            Circle()
              .width(80)
              .height(80)
              .fill('#E5E5EA')

            Image($r('app.media.ic_mine'))
              .width(40)
              .height(40)
              .fillColor('#FA2759')
          }
          .margin({ bottom: 16 })
          .scale({ x: this.avatarScale, y: this.avatarScale })
          .opacity(this.avatarOpacity)
          .animation({
            duration: 500,
            curve: Curve.EaseOut,
          })

          Text('本地音乐用户')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ bottom: 6 })
            .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 10 })))
            .animation({ duration: 400, curve: Curve.EaseOut, delay: 150 })

          Text(SettingsStore.getInstance().getPrivacyStats() ? `已收藏 ${this.favCount} 首 · 共 ${this.songCount} 首歌曲` : '听歌统计已关闭')
            .fontSize(14)
            .fontColor(this.getThemeColors().secondaryText)
            .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 10 })))
            .animation({ duration: 400, curve: Curve.EaseOut, delay: 200 })
        }
        .width('100%')
        .padding({ top: this.topHeight + 32, bottom: 24 })
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.getThemeColors().secondaryBg)

        // Quick stats
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
        .padding({ left: 32, right: 32, top: 20, bottom: 20 })
        .backgroundColor(this.getThemeColors().secondaryBg)

        // Menu section
        Column() {
          this.buildMenuItem(
            $r('app.media.ic_hm_favorite'),
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

        // Section header
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
              this.pathStack.pushPathByName('Settings', null);
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
              this.pathStack.pushPathByName('About', null);
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
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor(this.getThemeColors().bg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .padding({ bottom: this.bottomHeight + 16 })
  }
}
