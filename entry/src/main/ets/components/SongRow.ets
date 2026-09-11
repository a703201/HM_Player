/*
 * Copyright 2026 何宇翔
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
import { CoverImageView } from './CoverImageView';
import { QualityBadge } from './QualityBadge';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { semanticOf } from '../tokens/LumioColor';

/**
 * 长按菜单项（数据驱动，规避 @BuilderParam 无法捕获 per-row song 的限制）。
 * action 为闭包，由各自页面在构造数组时捕获 song，统一组件只负责渲染与触发。
 */
export interface SongMenuEntry {
  text: string;
  icon?: Resource;
  action: () => void;
}

/**
 * 统一歌曲行组件（P3 SongRow 去重）。
 * 收口 6 处复制的列表行（LocalLibrary / Favorites / PlayHistory / PlaylistDetail / FolderBrowse / SettingsSubPageBodies），
 * 把原本散落的「封面 + 标题 + 歌手 + 品质徽章 + 卡片底 + 按压缩放 + 长按菜单」统一到此组件，
 * 通过配置项保留各页差异（序号列 / 心形脉冲 / 播放态色 / 圆形封面 / 播放图标 / 关闭按钮 / 入场动画）。
 *
 * 设计红线（见项目 MEMORY）：FolderBrowse 是降级变体——无长按菜单、固定高度 64，
 * 接入统一组件时**不得**借 menuItems 默认空数组之外「补齐」菜单；本组件契约：menuItems 空即完全不绑定 bindContextMenu。
 */
@Component
export struct SongRow {
  @Prop song: SongItem = new SongItem();
  @Prop index: number = 0;
  /** 本行是否为当前播放行（由各自页面按自身逻辑计算后传入） */
  @Prop playing: boolean = false;
  /** 播放态文字/图标着色（Local/Fav = accent，History = warning） */
  @Prop playingColor: ResourceColor = '#FA2759';
  @Prop showIndex: boolean = false;
  @Prop showHeart: boolean = false;
  @Prop favorite: boolean = false;
  @Prop showQuality: boolean = false;
  /** 播放态封面变圆形（Local/Fav/History = true） */
  @Prop circularCoverWhenPlaying: boolean = false;
  /** 播放态右下角叠播放图标（仅 LocalLibrary） */
  @Prop showPlayingIcon: boolean = false;
  /** 播放态卡片底色（fillAccentSubtle / fillWarningSoft） */
  @Prop playingBg: ResourceColor = '#00000000';
  @Prop coverSize: number = 48;
  @Prop coverRadius: number = 8;
  @Prop titleFontSize: number = 15;
  @Prop rowHeight: number = 64;
  @Prop leftPadding: number = 8;
  @Prop showRemove: boolean = false;
  @Prop animateEntry: boolean = false;
  @Prop entryDelayMs: number = 0;

  /** 长按菜单项；为空数组时本组件不绑定 bindContextMenu（FolderBrowse 降级契约） */
  menuItems: SongMenuEntry[] = [];
  onPlay: () => void = () => {};
  onRemove: () => void = () => {};

  @StorageProp('isDark') isDark: boolean = false;
  @State private pressedScale: number = 1.0;
  @State private heartPulse: number = 1.0;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  build() {
    if (this.menuItems.length > 0) {
      this.rowWithMenu();
    } else {
      this.rowWithoutMenu();
    }
  }

  @Builder
  private rowInner() {
    if (this.showIndex) {
      Text(`${this.index + 1}`)
        .fontSize(13)
        .fontColor(this.playing ? this.playingColor : this.getThemeColors().secondaryText)
        .width(28)
        .textAlign(TextAlign.Center)
    }

    Stack() {
      CoverImageView({
        src: this.song.src,
        coverSize: this.coverSize,
        coverRadius: this.playing && this.circularCoverWhenPlaying ? this.coverSize / 2 : this.coverRadius
      })

      if (this.playing && this.showPlayingIcon) {
        Stack() {
          Circle()
            .width(24)
            .height(24)
            .fill(semanticOf(this.isDark).fillAccentMuted)
            .scale({ x: this.pressedScale, y: this.pressedScale })

          Image($r('app.media.ic_playing'))
            .width(16)
            .height(16)
        }
        .position({ x: this.coverSize - 18, y: this.coverSize - 18 })
      }
    }

    Column() {
      Row() {
        Text(this.song.title)
          .fontSize(this.titleFontSize)
          .fontColor(this.playing ? this.playingColor : this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .animation({ duration: 200, curve: Curve.EaseOut })

        if (this.showQuality) {
          QualityBadge({ quality: this.song.getQuality() })
            .margin({ left: 6 })
        }
      }
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 4 })

      Text(this.song.singer)
        .fontSize(13)
        .fontColor(this.getThemeColors().secondaryText)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 12 })

    if (this.showHeart && this.favorite) {
      Image($r('app.media.ic_favorite'))
        .width(22)
        .height(22)
        .fillColor(this.getThemeColors().accent)
        .scale({ x: this.heartPulse, y: this.heartPulse })
        .animation({ duration: 200, curve: Curve.EaseOut })
    } else if (this.showRemove) {
      Image($r('app.media.ic_close'))
        .width(18)
        .height(18)
        .fillColor(this.getThemeColors().secondaryText)
        .onClick(() => {
          this.onRemove();
        })
    }
  }

  @Builder
  private rowWithMenu() {
    Row() {
      this.rowInner();
    }
    .width('100%')
    .height(this.rowHeight)
    .padding({ left: this.leftPadding, right: 16 })
    .backgroundColor(this.playing ? this.playingBg : this.getThemeColors().cardBg)
    .borderRadius(12)
    .margin({ left: 8, right: 8, bottom: 8 })
    .scale({ x: this.pressedScale, y: this.pressedScale })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 30 })))
    .animation({ duration: this.animateEntry ? 300 : 0, curve: Curve.EaseOut, delay: this.animateEntry ? this.entryDelayMs : 0 })
    .onClick(() => {
      this.onPlay();
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedScale = 0.96;
        if (this.showHeart) {
          this.heartPulse = 1.3;
        }
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedScale = 1.0;
        this.heartPulse = 1.0;
      }
    })
    .bindContextMenu(this.menuContent, ResponseType.LongPress)
  }

  @Builder
  private rowWithoutMenu() {
    Row() {
      this.rowInner();
    }
    .width('100%')
    .height(this.rowHeight)
    .padding({ left: this.leftPadding, right: 16 })
    .backgroundColor(this.playing ? this.playingBg : this.getThemeColors().cardBg)
    .borderRadius(12)
    .margin({ left: 8, right: 8, bottom: 8 })
    .scale({ x: this.pressedScale, y: this.pressedScale })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 30 })))
    .animation({ duration: this.animateEntry ? 300 : 0, curve: Curve.EaseOut, delay: this.animateEntry ? this.entryDelayMs : 0 })
    .onClick(() => {
      this.onPlay();
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedScale = 0.96;
        if (this.showHeart) {
          this.heartPulse = 1.3;
        }
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedScale = 1.0;
        this.heartPulse = 1.0;
      }
    })
  }

  @Builder
  private menuContent() {
    Column() {
      ForEach(this.menuItems, (item: SongMenuEntry, i: number) => {
        Row() {
          if (item.icon !== undefined) {
            Image(item.icon)
              .width(18)
              .fillColor(this.getThemeColors().primaryText)
              .margin({ right: 12 })
          }
          Text(item.text)
            .fontSize(14)
            .fontColor(this.getThemeColors().primaryText)
        }
        .width('100%')
        .height(44)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          item.action();
        })

        if (i < this.menuItems.length - 1) {
          Divider()
            .color(this.getThemeColors().separator)
            .strokeWidth(0.5)
        }
      }, (item: SongMenuEntry, i: number): string => `${item.text}_${i}`)
    }
  }
}
