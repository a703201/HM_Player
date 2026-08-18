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

/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

/**
 * 桌面音乐播控卡片（ArkTS 动态卡片）。
 * 数据由主应用经 formProvider.updateForm 推送（title / artist / isPlaying / isDark）；
 * 按钮通过 postCardAction 的 message 事件回传 'play' / 'pause' / 'next' / 'prev'，
 * 由 FormAbility.onFormEvent 转发给主 EntryAbility 实现回控。
 *
 * 主题跟随：卡片运行在独立渲染进程，无法共享主应用 AppStorage，亦不可 import 完整
 * ThemeManager（其依赖 window/Preferences）。故卡片内自建轻量 cardColors(isDark) 取色集，
 * 色值与《Lumio 设计 Token 规范》(docs/design_tokens.md §1) 的
 * ThemeManager.lightColors/darkColors 保持一致，作为权威来源的单点镜像。
 * isDark 由 FormAbility 经 createFormBindingData 写入（M2 G-4 闭环；当前默认 false=浅色）。
 */
interface CardColors {
  cardBg: string;
  titleText: string;
  artistText: string;
  iconColor: string;
  secondaryBtnBg: string;
  playBtnBg: string;
  playIconColor: string;
}

let storage = new LocalStorage();
@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('title') title: string = '';
  @LocalStorageProp('artist') artist: string = '';
  @LocalStorageProp('album') album: string = '';
  @LocalStorageProp('duration') duration: number = 0;
  @LocalStorageProp('isPlaying') isPlaying: boolean = false;
  @LocalStorageProp('isDark') isDark: boolean = false;

  /**
   * 毫秒 → mm:ss。build() 内禁止 const/let，故以纯方法内联调用。
   */
  private formatDuration(ms: number): string {
    if (ms <= 0) {
      return '00:00';
    }
    const totalSec: number = Math.floor(ms / 1000);
    const min: number = Math.floor(totalSec / 60);
    const sec: number = totalSec % 60;
    const mm: string = min < 10 ? '0' + min.toString() : min.toString();
    const ss: string = sec < 10 ? '0' + sec.toString() : sec.toString();
    return mm + ':' + ss;
  }

  /**
   * 卡片取色集：镜像 design_tokens.md §1 语义令牌（accent 恒为品牌粉红 #FA2759）。
   * 背景/文字/图标一律经此取色，禁止硬编码 Color.White / #1A1A2E 等字面量。
   */
  private getCardColors(): CardColors {
    if (this.isDark) {
      return {
        cardBg: '#1C1C1E',        // cardBg(dark)
        titleText: '#FFFFFF',     // primaryText(dark)
        artistText: '#98989F',    // secondaryText(dark)
        iconColor: '#FFFFFF',     // primaryText(dark)
        secondaryBtnBg: '#33FFFFFF',
        playBtnBg: '#FA2759',      // accent（恒值）
        playIconColor: '#FFFFFF'
      };
    }
    return {
      cardBg: '#F2F2F7',          // cardBg(light)
      titleText: '#1C1C1E',       // primaryText(light)
      artistText: '#8E8E93',      // secondaryText(light)
        iconColor: '#1C1C1E',       // primaryText(light)
        secondaryBtnBg: '#33000000',
        playBtnBg: '#FA2759',        // accent（恒值）
        playIconColor: '#FFFFFF'
      };
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_default_cover'))
          .width(44)
          .height(44)
          .borderRadius(8)
          .margin({ right: 12 })
        Column() {
          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getCardColors().titleText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text(this.artist)
            .fontSize(12)
            .fontColor(this.getCardColors().artistText)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .margin({ top: 2 })
          if (this.album.length > 0) {
            Text(this.album)
              .fontSize(11)
              .fontColor(this.getCardColors().artistText)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ top: 16, left: 16, right: 16 })

      Row() {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_prev'))
            .width(22)
            .height(22)
            .fillColor(this.getCardColors().iconColor)
        }
        .width(40)
        .height(40)
        .backgroundColor(this.getCardColors().secondaryBtnBg)
        .accessibilityText('上一首')
        .onClick(() => {
          postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: { control: 'prev' } });
        })

        Button({ type: ButtonType.Circle }) {
          Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(28)
            .height(28)
            .fillColor(this.getCardColors().playIconColor)
        }
        .width(56)
        .height(56)
        .backgroundColor(this.getCardColors().playBtnBg) // 品牌粉红 #FA2759（替代 Material 蓝 #1E88E5）
        .margin({ left: 16, right: 16 })
        .accessibilityText(this.isPlaying ? '暂停' : '播放')
        .onClick(() => {
          postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: { control: this.isPlaying ? 'pause' : 'play' } });
        })

        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_next'))
            .width(22)
            .height(22)
            .fillColor(this.getCardColors().iconColor)
        }
        .width(40)
        .height(40)
        .backgroundColor(this.getCardColors().secondaryBtnBg)
        .accessibilityText('下一首')
        .onClick(() => {
          postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: { control: 'next' } });
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 12 })

      // 时长信息（D4 第一步）：毫秒由主应用推送，卡片内格式化为 mm:ss
      Text(this.formatDuration(this.duration))
        .fontSize(11)
        .fontColor(this.getCardColors().artistText)
        .margin({ top: 8, bottom: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getCardColors().cardBg) // 随主题：dark=cardBg(dark) / light=cardBg(light)，替代硬编码 #1A1A2E
  }
}
