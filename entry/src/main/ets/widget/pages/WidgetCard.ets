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
 * 数据由主应用经 formProvider.updateForm 推送（title / artist / album / duration / position / lyric / isPlaying / isDark）；
 * position 与 lyric 由主应用在播放中每秒刷新，实现进度条走动与当前歌词行实时同步；
 * 按钮通过 postCardAction 的 message 事件回传 'play' / 'pause' / 'next' / 'prev'，
 * 由 FormAbility.onFormEvent 转发给主 EntryAbility 实现回控。
 *
 * 主题跟随：卡片运行在独立渲染进程，无法共享主应用 AppStorage，亦不可 import 完整
 * ThemeManager（其依赖 window/Preferences）。故卡片内自建轻量 getCardColors(isDark) 取色集，
 * 色值直接来自 tokens/LumioColor 的 semanticOf（与主应用 ThemeManager 同源，零 import，Form 进程安全）。
 * isDark 由 FormAbility.onAddForm 写入，并随主应用主题切换经 pushFormUpdate() 自愈重推（缺陷 1 已修复）。
 */
import { semanticOf, CARD_CONTROL_BG_LIGHT, CARD_CONTROL_BG_DARK } from '../../tokens/LumioColor';

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
  @LocalStorageProp('position') curPosition: number = 0;
  @LocalStorageProp('lyric') lyric: string = '';
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
   * 卡片取色集：直接引用 tokens/LumioColor 的 semanticOf（与主应用 ThemeManager 同源）。
   * 背景/文字/图标一律经此取色，禁止硬编码 Color.White / #1A1A2E 等字面量。
   * Form 卡片进程仅可 import 零 import 的 LumioColor。
   */
  private getCardColors(): CardColors {
    const s = semanticOf(this.isDark);
    return {
      cardBg: s.surfaceRaised,
      titleText: s.label,
      artistText: s.labelSecondary,
      iconColor: s.label,
      secondaryBtnBg: this.isDark ? CARD_CONTROL_BG_DARK : CARD_CONTROL_BG_LIGHT,
      playBtnBg: s.accent,
      playIconColor: s.labelOnAccent
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

      // 进度条 + 时间（D4 实时化）：position 由主应用每秒经 formProvider 推送
      Column() {
        Progress({
          value: this.curPosition > this.duration ? this.duration : this.curPosition,
          total: this.duration > 0 ? this.duration : 1,
          type: ProgressType.Linear
        })
          .width('100%')
          .height(4)
          .color(this.getCardColors().playBtnBg)
          .backgroundColor(this.getCardColors().secondaryBtnBg)
          .borderRadius(2)
        Row() {
          Text(this.formatDuration(this.curPosition > this.duration ? this.duration : this.curPosition))
            .fontSize(11)
            .fontColor(this.getCardColors().artistText)
          Text(this.formatDuration(this.duration))
            .fontSize(11)
            .fontColor(this.getCardColors().artistText)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 6 })
      }
      .width('100%')
      .margin({ top: 12, left: 16, right: 16 })

      // 当前歌词行（D4 实时化）：由主应用推送当前播放行，无歌词时隐藏
      if (this.lyric.length > 0) {
        Text(this.lyric)
          .fontSize(12)
          .fontColor(this.getCardColors().titleText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4, left: 16, right: 16 })
      }

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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getCardColors().cardBg) // 随主题：dark=cardBg(dark) / light=cardBg(light)，替代硬编码 #1A1A2E
  }
}
