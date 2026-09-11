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

import { getAppVersionName } from '../utils/AppInfoUtil';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { curves } from '@kit.ArkUI';
import { PrivacyPolicyBody } from '../components/SettingsSubPageBodies';
import { semanticOf } from '../tokens/LumioColor';

@Builder
export function AboutBuilder() {
  NavDestination() {
    About({})
  }
  .hideTitleBar(true)
}

@Component
export struct About {
  /** 由外层（Mine 的 bindSheet）传入：关闭关于 sheet。 */
  onRequestClose: () => void = () => {};
  /** 由外层传入：关闭本 Sheet 后再弹出新手引导（避免两 Sheet 同帧叠加出空白页）。 */
  onStartOnboarding: () => void = () => {};
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;

  private getThemeColors(): ColorTokens {
    // 跟随应用浅色/深色主题（sheet 内页面与全局一致，不强制灰底白字）
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @State logoScale: number = 0.5;
  @State logoOpacity: number = 0;
  @State titleOpacity: number = 0;
  @State subtitleOpacity: number = 0;
  @State itemScales: number[] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
  @State featureScales: number[] = [0.9, 0.9, 0.9];
  @State featureOpacities: number[] = [0, 0, 0];
  @State appVersion: string = '';
  /** sheet 内嵌子页：'main' 关于主页 / 'privacy' 隐私政策。 */
  @State subPage: string = 'main';

  aboutToAppear(): void {
    this.appVersion = getAppVersionName();
    setTimeout(() => {
      this.logoScale = 1.0;
      this.logoOpacity = 1.0;
    }, 100);
    setTimeout(() => {
      this.titleOpacity = 1.0;
    }, 300);
    setTimeout(() => {
      this.subtitleOpacity = 1.0;
    }, 400);
    // Feature cards animation
    for (let i = 0; i < 3; i++) {
      setTimeout(() => {
        let newScales = [...this.featureScales];
        let newOpacities = [...this.featureOpacities];
        newScales[i] = 1.0;
        newOpacities[i] = 1.0;
        this.featureScales = newScales;
        this.featureOpacities = newOpacities;
      }, 600 + i * 100);
    }
  }

  private openSubPage(target: string): void {
    if (this.subPage === target) {
      return;
    }
    this.getUIContext().animateTo(
      { curve: curves.interpolatingSpring(0, 1, 360, 36), duration: 280 },
      () => {
        this.subPage = target;
      }
    );
  }

  private goBackFromSubPage(): void {
    if (this.subPage === 'main') {
      this.onRequestClose();
      return;
    }
    this.getUIContext().animateTo(
      { curve: curves.interpolatingSpring(0, 1, 360, 36), duration: 240 },
      () => {
        this.subPage = 'main';
      }
    );
  }

  build() {
    Column() {
      // 顶部头部：subPage=privacy 时显示返回；其它与旧逻辑一致（无头部，标题区在内部）
      if (this.subPage === 'privacy') {
        Row() {
          Image($r('app.media.ic_hm_back'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .onClick(() => this.goBackFromSubPage())
          Text('隐私政策')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: 12 })
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 12 })
      }

      if (this.subPage === 'main') {
        this.buildMain()
      } else if (this.subPage === 'privacy') {
        PrivacyPolicyBody({ onBack: () => this.goBackFromSubPage(), showHeader: false })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 32 })))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColors().bg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildMain() {
    Scroll() {
      Column() {
        // Header section
        Column() {
          Image($r('app.media.logo'))
            .width(108)
            .height(108)
            .borderRadius(24)
            .shadow({
              radius: 16,
              color: semanticOf(this.isDark).fillAccentMuted,
              offsetX: 0,
              offsetY: 8
            })
            .scale({ x: this.logoScale, y: this.logoScale })
            .opacity(this.logoOpacity)
            .animation({
              duration: 600,
              curve: Curve.EaseOut,
            })

          Text('Lumio Music')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ top: 20, bottom: 6 })
            .opacity(this.titleOpacity)
            .transition(TransitionEffect.translate({ y: 10 }))
            .animation({ duration: 400, curve: Curve.EaseOut })

          Text('本地音乐播放器')
            .fontSize(15)
            .fontColor(this.getThemeColors().secondaryText)
            .opacity(this.subtitleOpacity)
            .transition(TransitionEffect.translate({ y: 10 }))
            .animation({ duration: 400, curve: Curve.EaseOut })
        }
        .width('100%')
        .padding({ top: this.topHeight + 48, bottom: 36 })
        .backgroundColor(this.getThemeColors().secondaryBg)

        // Features section
        Text('功能特色')
          .fontSize(13)
          .fontColor(this.getThemeColors().secondaryText)
          .width('100%')
          .padding({ left: 20, bottom: 12 })

        Row() {
          Column() {
            Image($r('app.media.ic_hm_library'))
              .width(30)
              .height(30)
              .margin({ bottom: 8 })
              .fillColor(this.getThemeColors().primaryText)
            Text('本地播放')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getThemeColors().primaryText)
          }
          .layoutWeight(1)
          .scale({ x: this.featureScales[0], y: this.featureScales[0] })
          .opacity(this.featureOpacities[0])
          .animation({ duration: 400, curve: Curve.EaseOut })

          Column() {
            Image($r('app.media.ic_hm_search'))
              .width(30)
              .height(30)
              .margin({ bottom: 8 })
              .fillColor(this.getThemeColors().primaryText)
            Text('文件扫描')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getThemeColors().primaryText)
          }
          .layoutWeight(1)
          .scale({ x: this.featureScales[1], y: this.featureScales[1] })
          .opacity(this.featureOpacities[1])
          .animation({ duration: 400, curve: Curve.EaseOut })

          Column() {
            Image($r('app.media.ic_hm_list'))
              .width(30)
              .height(30)
              .margin({ bottom: 8 })
              .fillColor(this.getThemeColors().primaryText)
            Text('歌词显示')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getThemeColors().primaryText)
          }
          .layoutWeight(1)
          .scale({ x: this.featureScales[2], y: this.featureScales[2] })
          .opacity(this.featureOpacities[2])
          .animation({ duration: 400, curve: Curve.EaseOut })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 12, bottom: 24 })
        .justifyContent(FlexAlign.SpaceAround)

        // Info section
        Text('应用信息')
          .fontSize(13)
          .fontColor(this.getThemeColors().secondaryText)
          .width('100%')
          .padding({ left: 20, bottom: 12 })

        Column() {
          this.buildAboutItem('应用版本', this.appVersion, 0)
          this.buildAboutItem('开发者', '何宇翔', 1)
          this.buildAboutItem('技术支持', 'HarmonyOS SDK', 2)
          this.buildAboutItem('架构', 'ArkTS + C++ Native', 3)

          // 重新查看新手引导：关闭本 Sheet 并触发 Layout 的引导半蒙面展示
          Row() {
            Text('新手引导')
              .fontSize(15)
              .fontColor(this.getThemeColors().primaryText)
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
            Image($r('app.media.ic_hm_more'))
              .width(16)
              .height(16)
              .fillColor(this.getThemeColors().secondaryText)
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .backgroundColor(this.getThemeColors().cardBg)
          .borderRadius(16)
          .margin({ bottom: 2 })
          .scale({ x: this.itemScales[4] ?? 1.0, y: this.itemScales[4] ?? 1.0 })
          .animation({ duration: 300, curve: Curve.EaseOut, delay: 820 })
          .onClick(() => {
            // 关闭本 Sheet 并交由外层在 Sheet 关闭后再弹引导，避免同帧出现空白 large 页。
            this.onStartOnboarding();
          })

          // 隐私政策：以 sheet 内嵌子页形式呈现，不再走主导航栈
          Row() {
            Text('隐私政策')
              .fontSize(15)
              .fontColor(this.getThemeColors().primaryText)
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
            Image($r('app.media.ic_hm_more'))
              .width(16)
              .height(16)
              .fillColor(this.getThemeColors().secondaryText)
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .backgroundColor(this.getThemeColors().cardBg)
          .borderRadius(16)
          .margin({ bottom: 2 })
          .scale({ x: this.itemScales[5] ?? 1.0, y: this.itemScales[5] ?? 1.0 })
          .animation({ duration: 300, curve: Curve.EaseOut, delay: 900 })
          .onClick(() => {
            this.openSubPage('privacy');
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        Text('一款简洁的本地音乐播放器，支持导入本地音频、播放控制、歌词显示等功能。')
          .fontSize(14)
          .fontColor(this.getThemeColors().secondaryText)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 32, bottom: 40 })
          .padding({ left: 30, right: 30 })
          .transition(TransitionEffect.OPACITY)
          .animation({ duration: 500, curve: Curve.EaseOut, delay: 800 })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .backgroundColor(this.getThemeColors().bg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  buildAboutItem(label: string, value: string, index: number) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.getThemeColors().secondaryText)
        .layoutWeight(1)
        .textAlign(TextAlign.Start)

      Text(value)
        .fontSize(15)
        .fontColor(this.getThemeColors().primaryText)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(16)
    .margin({ bottom: 2 })
    .scale({ x: this.itemScales[index] ?? 1.0, y: this.itemScales[index] ?? 1.0 })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 20 })))
    .animation({ duration: 300, curve: Curve.EaseOut, delay: 500 + index * 80 })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        let scales = [...this.itemScales];
        scales[index] = 0.96;
        this.itemScales = scales;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        let scales = [...this.itemScales];
        scales[index] = 1.0;
        this.itemScales = scales;
      }
    })
  }
}
