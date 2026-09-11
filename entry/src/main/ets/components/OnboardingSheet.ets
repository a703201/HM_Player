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

import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { semanticOf, LUMIO_PALETTE } from '../tokens/LumioColor';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';

interface OnboardFeature {
  icon: ResourceStr;
  title: string;
  desc: string;
  color: string;
}

/**
 * 首次引导页内容（半蒙面 Sheet 内嵌）。展示核心功能亮点，
 * 底部「开始体验」按钮关闭引导。被 Layout 的 bindSheet 承载。
 */
@Component
export struct OnboardingSheet {
  onClose: () => void = () => {};
  @StorageProp('isDark') isDark: boolean = false;

  @State itemOpacities: number[] = [0, 0, 0, 0];
  @State itemScales: number[] = [0.9, 0.9, 0.9, 0.9];

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  private features: OnboardFeature[] = [
    { icon: $r('app.media.ic_hm_library'), title: '本地音乐库', desc: '导入本地音频，纯离线播放，隐私优先', color: semanticOf(this.isDark).accent },
    { icon: $r('app.media.ic_hm_favorite'), title: '无损 · Hi-Res', desc: '自动识别无损与高解析音质，徽标呈现', color: semanticOf(this.isDark).warning },
    { icon: $r('app.media.ic_hm_list'), title: '智能歌单', desc: '按收藏、常听、年代、艺术家自动聚合', color: LUMIO_PALETTE.purple },
    { icon: $r('app.media.ic_hm_play'), title: '系统深度融合', desc: '锁屏播控、实况窗、卡片与倍速睡眠', color: semanticOf(this.isDark).success }
  ];

  aboutToAppear(): void {
    for (let i = 0; i < this.features.length; i++) {
      setTimeout(() => {
        const op = [...this.itemOpacities];
        const sc = [...this.itemScales];
        op[i] = 1.0;
        sc[i] = 1.0;
        this.itemOpacities = op;
        this.itemScales = sc;
      }, 200 + i * 120);
    }
  }

  @Builder
  private featureItem(f: OnboardFeature, index: number) {
    Row() {
      Stack() {
        Image(f.icon)
          .width(24)
          .height(24)
          .fillColor(semanticOf(this.isDark).onAccent)
      }
      .width(46)
      .height(46)
      .borderRadius(16)
      .backgroundColor(f.color)
      .align(Alignment.Center)

      Column() {
        Text(f.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getThemeColors().primaryText)
        Text(f.desc)
          .fontSize(12)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: 3 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 14, right: 8 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .opacity(this.itemOpacities[index])
    .scale({ x: this.itemScales[index], y: this.itemScales[index] })
    .animation({ duration: 400, curve: LumioTheme.curve(SpringKind.Crisp) })
  }

  build() {
    Column() {
      Column() {
        Image($r('app.media.logo'))
          .width(72)
          .height(72)
          .borderRadius(18)
          .margin({ top: 8, bottom: 12 })
        Text('欢迎使用 Lumio Music')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColors().primaryText)
        Text('本地音乐，纯粹聆听')
          .fontSize(13)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: 6, bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Column() {
        ForEach(this.features, (f: OnboardFeature, index: number) => {
          this.featureItem(f, index)
        }, (f: OnboardFeature, index: number) => index.toString())
      }
      .width('100%')
      .margin({ top: 8, bottom: 16 })

      Button('开始体验')
        .width('86%')
        .height(48)
        .fontSize(16)
        .fontColor(semanticOf(this.isDark).onAccent)
        .backgroundColor(this.getThemeColors().accent)
        .borderRadius(24)
        .onClick(() => {
          this.onClose();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 24, bottom: 32 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.getThemeColors().bg)
  }
}
