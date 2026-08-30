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
import { AudioRendererController } from '../utils/AudioRendererController';
import { AVSessionController } from '../utils/AVSessionController';
import { Logger } from '../utils/Logger';
import { MusicPlayMode, PlayModeSwitchList } from '../songdatacontroller/PlayerData';
import { SongItem } from '../songdatacontroller/SongData';
import { CoverImageView } from './CoverImageView';
import { StyleConstants } from '../common/constants/StyleConstants';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { PlayerConstants } from '../common/constants/PlayerConstants';
import { BreakpointType } from '../common/utils/BreakpointSystem'
import { ContentConstants } from '../common/constants/ContentConstants';
import { ResourceConversion } from '../common/utils/ResourceConversion';
import { MusicStore } from '../services/MusicStore';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { sortSongs } from '../common/utils/SortUtil';
import { Motion, springSnappy } from '../common/utils/DesignSystem';

const TAG = 'ControlAreaComponent'

@Component
export struct ControlAreaComponent {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @StorageLink('isPlay') isPlay: boolean = false;
  @StorageLink('currentTime') currentTime: string = '00:00';
  @StorageLink('totalTime') totalTime: string = '00:00';
  @StorageLink('progress') value: number = 0;
  @StorageLink('progressMax') max: number = 0;
  @State playModeIndex: number = 0;
  @StorageLink('imageColor') imageColor: string = '';
  @StorageLink('pageShowTime') pageShowTime: number = 0;
  @StorageLink('songList') songList: SongItem[] = [];
  @State isShowPlayList: boolean = false;
  @State currentIndex: number = 0;
  @State sortMode: number = 0;
  @StorageLink('playMode') playMode: MusicPlayMode = PlayModeSwitchList[this.playModeIndex];
  @State prevScale: number = 1.0;
  @State playBtnScale: number = 1.0;
  @State nextScale: number = 1.0;
  @StorageLink('selectIndex') selectIndex: number = 0;
  @StorageLink('isFavorite') isFavorite: boolean = false;
  @StorageLink('isSilentMode') isSilentMode: boolean = false;
  @StorageProp('isDark') isDark: boolean = false;
  private scroller: Scroller = new Scroller();
  private resourceConversion: ResourceConversion = new ResourceConversion();

  switchPlayMode() {
    if (this.playModeIndex === PlayModeSwitchList.length - 1) {
      this.playModeIndex = 0;
    } else {
      this.playModeIndex++;
    }
    this.playMode = PlayModeSwitchList[this.playModeIndex];
    Logger.info(TAG, 'playModeIndex is' + this.playModeIndex);
    // API 12 起 Prompt/promptAction 全局方法已废弃，统一走 UIContext.getPromptAction()
    const modeText: string = this.playMode === MusicPlayMode.ORDER ?
      this.resourceConversion.getStringValueFromResource($r('app.string.sequential_playback')) :
      this.playMode === MusicPlayMode.RANDOM ?
        this.resourceConversion.getStringValueFromResource($r('app.string.random_playback')) :
        this.resourceConversion.getStringValueFromResource($r('app.string.single_playback'));
    if (modeText.length > 0) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: modeText });
      } catch (e) {
        Logger.error(TAG, 'showToast failed');
      }
    }
    AudioRendererController.getInstance().setPlayModel(this.playMode);
  }

  build() {
    Column() {
      Row() {
        Image(this.playMode === MusicPlayMode.ORDER ? $r('app.media.order_play') :
          this.playMode === MusicPlayMode.RANDOM ? $r('app.media.shuffle') : $r('app.media.repeat_1'))
          .fillColor(Color.White)
          .controlImageBuilder()
          .width(new BreakpointType({
            sm: $r('app.float.twenty_four'),
            md: $r('app.float.twenty_four'),
            lg: $r('app.float.control_image_lg')
          }).getValue(this.currentBreakpoint))
          .onClick(() => {
            this.switchPlayMode()
          })
        Image($r('app.media.ic_music_list'))
          .fillColor(Color.White)
          .controlImageBuilder()
          .width(new BreakpointType({
            sm: $r('app.float.twenty_four'),
            md: $r('app.float.twenty_four'),
            lg: $r('app.float.control_image_lg')
          }).getValue(this.currentBreakpoint))
          .onClick(() => {
            this.isShowPlayList = true;
          })
          .bindSheet($$this.isShowPlayList, this.musicListBuilder(), {
            detents: [SheetSize.MEDIUM],
            dragBar: false,
            showClose: false,
            preferType: SheetType.CENTER,
            onWillAppear: () => {
              Logger.info(TAG, 'musicListBuilder');
              this.refreshQueue();
              this.scroller.scrollToIndex(this.currentIndex, false, ScrollAlign.CENTER);
            }
          })
        Image(this.isSilentMode ? $r('app.media.silence') : $r('app.media.ic_ring'))
          .controlImageBuilder()
          .width(new BreakpointType({
            sm: $r('app.float.twenty_four'),
            md: $r('app.float.twenty_four'),
            lg: $r('app.float.control_image_lg')
          }).getValue(this.currentBreakpoint))
          .onClick(() => {
            this.isSilentMode = !this.isSilentMode;
            AudioRendererController.getInstance().setSilentModeAndMixWithOthers(this.isSilentMode)
          })
        Image(this.isFavorite ? $r('app.media.heart_fill') : $r('app.media.heart'))
          .fillColor(this.isFavorite ? Color.Red : Color.White)
          .controlImageBuilder()
          .animation({
            duration: Motion.fade,
            curve: springSnappy()
          })
          .width(new BreakpointType({
            sm: $r('app.float.twenty_four'),
            md: $r('app.float.twenty_four'),
            lg: $r('app.float.control_image_lg')
          }).getValue(this.currentBreakpoint))
          .onClick(() => {
            // 收藏以 song.id 为稳定主键（队列索引会漂移）；移除原「点收藏即跳收藏页」的误跳转
            const song: SongItem | undefined = AudioRendererController.getInstance().getCurrentSong();
            if (song) {
              AVSessionController.getInstance().updateFavoriteState(song.id.toString());
            }
          })
      }
      .width(StyleConstants.FULL_WIDTH)
      .justifyContent(FlexAlign.SpaceBetween)

      Column() {
        Slider({
          min: 0,
          max: this.max,
          step: 1,
          style: SliderStyle.OutSet,
          value: this.value
        })
          .selectedColor($r('app.color.slider_select'))
          .trackColor($r('app.color.slider_track'))
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.End || mode === SliderChangeMode.Begin) {
              AudioRendererController.getInstance().seek(value);
            }
            this.pageShowTime = 0;
          })
          .height($r('app.float.slider_height'))
          .margin({
            left: new BreakpointType({
              sm: $r('app.float.slider_margin_sm'),
              md: $r('app.float.slider_margin_md'),
              lg: $r('app.float.slider_margin_lg')
            }).getValue(this.currentBreakpoint),
            right: new BreakpointType({
              sm: $r('app.float.slider_margin_sm'),
              md: $r('app.float.slider_margin_md'),
              lg: $r('app.float.slider_margin_lg')
            }).getValue(this.currentBreakpoint)
          })
          .hitTestBehavior(HitTestMode.Block)
        Row() {
          Text(this.currentTime)
            .fontColor($r('app.color.play_text_color'))
            .fontSize($r('app.float.singer_title_sm'))
            .fontFamily(PlayerConstants.FONT_FAMILY_BLACK)
            .lineHeight('14vp')
          Text(this.totalTime)
            .fontColor($r('app.color.play_text_color'))
            .fontSize($r('app.float.singer_title_sm'))
            .fontFamily(PlayerConstants.FONT_FAMILY_BLACK)
            .lineHeight('14vp')
        }
        .width(StyleConstants.FULL_WIDTH)
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .margin({
        top: $r('app.float.slider_margin_top'),
        bottom: this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
        $r('app.float.slider_margin_bottom_lg') : $r('app.float.slider_margin_bottom')
      })

      Row() {
        Image($r('app.media.ic_public_forward'))
          .controlImageBuilder()
          .width(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
          $r('app.float.control_width_lg') : $r('app.float.control_width'))
          .scale({ x: this.prevScale, y: this.prevScale })
          .animation({ duration: Motion.tap, curve: springSnappy() })
          .onClick(() => {
            AudioRendererController.getInstance().playPrevious();
            this.pageShowTime = 0;
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.prevScale = 0.75;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.prevScale = 1.0;
            }
          })
        Image(this.isPlay ? $r('app.media.ic_public_play') : $r('app.media.ic_public_pause'))
          .controlImageBuilder()
          .width(new BreakpointType({
            sm: $r('app.float.image_play_width'),
            md: $r('app.float.image_play_width'),
            lg: $r('app.float.image_play_width_lg')
          }).getValue(this.currentBreakpoint))
          .scale({ x: this.playBtnScale, y: this.playBtnScale })
          .animation({ duration: Motion.tap, curve: springSnappy() })
          .onClick(() => {
            if (this.isPlay) {
              AudioRendererController.getInstance().pause();
            } else {
              if (AudioRendererController.getInstance().getFirst()) {
                AudioRendererController.getInstance().play(0);
              } else {
                AudioRendererController.getInstance().start();
              }
            }
            this.pageShowTime = 0;
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.playBtnScale = 0.85;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.playBtnScale = 1.0;
            }
          })
        Image($r('app.media.ic_public_next'))
          .controlImageBuilder()
          .width(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
          $r('app.float.control_width_lg') : $r('app.float.control_width'))
          .scale({ x: this.nextScale, y: this.nextScale })
          .animation({ duration: Motion.tap, curve: springSnappy() })
          .onClick(() => {
            AudioRendererController.getInstance().playNext();
            this.pageShowTime = 0;
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.nextScale = 0.75;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.nextScale = 1.0;
            }
          })
      }
      .width(StyleConstants.FULL_WIDTH)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        left: $r('app.float.control_padding'),
        right: $r('app.float.control_padding')
      })
    }
  }

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @Builder
  musicListBuilder() {
    Column() {
      this.playListTitle();
      this.sortBar();
      if (this.songList.length === 0) {
        Text($r('app.string.queue_empty'))
          .width(StyleConstants.FULL_WIDTH)
          .textAlign(TextAlign.Center)
          .fontColor(this.getThemeColors().secondaryText)
          .fontSize(15)
          .layoutWeight(1)
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.songList, (item: SongItem, index: number) => {
            ListItem() {
              MusicListContainer({
                item: item,
                index: index,
                isCurrent: index === this.currentIndex,
                onQueueChanged: () => this.refreshQueue()
              }).reuseId(item.id + '_' + index);
            }
          }, (item: SongItem, index: number) => item.id + '_' + index)
        }
        .height(StyleConstants.FULL_HEIGHT)
        .width(StyleConstants.FULL_WIDTH)
        .backgroundColor(this.getThemeColors().cardBg)
        .margin({ top: $r('app.float.list_area_margin_top') })
        .lanes(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
        ContentConstants.COL_TWO : ContentConstants.COL_ONE)
        .layoutWeight(1)
        .divider({
          color: $r('app.color.list_divider'),
          strokeWidth: $r('app.float.stroke_width'),
          startMargin: $r('app.float.list_item_padding'),
          endMargin: $r('app.float.list_item_padding')
        })
      }
    }
    .padding({
      top: this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ? 0 : $r('app.float.list_area_padding_top'),
      bottom: $r('app.float.list_area_padding_bottom')
    })
    .backgroundColor(this.getThemeColors().cardBg)
  }

  private refreshQueue(): void {
    const ctrl = AudioRendererController.getInstance();
    this.currentIndex = ctrl.getCurrentIndex();
  }

  private applySort(mode: number): void {
    this.sortMode = mode;
    const ctrl = AudioRendererController.getInstance();
    const store = MusicStore.getInstance();
    // 排序逻辑抽到 common/utils/SortUtil.ets，与曲库页共用。
    // mode 0（默认）保持原语义：队列重置为曲库默认顺序。
    const base: SongItem[] = mode === 0 ? store.songs : this.songList;
    const sorted: SongItem[] = sortSongs(base, mode, store.recentlyPlayed);
    const cur: SongItem | undefined = ctrl.getCurrentSong();
    let newIndex: number = 0;
    if (cur) {
      const found: number = sorted.findIndex((s: SongItem) => s.id === cur.id);
      if (found >= 0) {
        newIndex = found;
      }
    }
    ctrl.setQueue(sorted, newIndex, false);
    this.refreshQueue();
  }

  @Builder
  sortBar() {
    Row() {
      ForEach([0, 1, 2, 3, 4], (mode: number) => {
        Text(this.sortLabel(mode))
          .fontSize(13)
          .fontColor(this.sortMode === mode ? Color.White : this.getThemeColors().secondaryText)
          .backgroundColor(this.sortMode === mode ? this.getThemeColors().accent : this.getThemeColors().secondaryBg)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .margin({ right: 8 })
          .onClick(() => {
            this.applySort(mode);
          })
      }, (mode: number) => 'sort_' + mode.toString())
    }
    .width(StyleConstants.FULL_WIDTH)
    .padding({
      left: $r('app.float.play_all_area_padding'),
      right: $r('app.float.play_all_area_padding'),
      top: 8,
      bottom: 8
    })
    .backgroundColor(this.getThemeColors().cardBg)
  }

  private sortLabel(mode: number): Resource {
    switch (mode) {
      case 1:
        return $r('app.string.sort_title');
      case 2:
        return $r('app.string.sort_artist');
      case 3:
        return $r('app.string.sort_recent');
      case 4:
        return $r('app.string.sort_random');
      default:
        return $r('app.string.sort_default');
    }
  }

  @Builder
  playListTitle() {
    Row() {
      Image($r('app.media.ic_sort_list'))
        .height($r('app.float.play_all_icon_size'))
        .width($r('app.float.play_all_icon_size'))
      Text($r('app.string.play_list', this.songList.length))
        .maxLines(ContentConstants.PLAY_ALL_MAX_LINES)
        .padding({ left: $r('app.float.play_all_text_padding') })
        .fontColor(this.getThemeColors().primaryText)
        .fontSize(new BreakpointType({
          sm: $r('app.float.play_font_sm'),
          md: $r('app.float.play_font_md'),
          lg: $r('app.float.play_font_lg')
        }).getValue(this.currentBreakpoint))
    }
    .height($r('app.float.play_all_area_height'))
    .width(StyleConstants.FULL_WIDTH)
    .backgroundColor(this.getThemeColors().cardBg)
    .padding({
      left: $r('app.float.play_all_area_padding'),
      right: $r('app.float.play_all_area_padding')
    })
    .borderRadius({
      topRight: $r('app.float.play_all_border_radius'),
      topLeft: $r('app.float.play_all_border_radius')
    })
    .position({
      x: 0,
      y: 0
    })
  }
}

@Extend(Image)
function controlImageBuilder() {
  .aspectRatio(1)
  .opacity(0.86)
  .objectFit(ImageFit.Contain)
}

@Reusable
@Component
struct MusicListContainer {
  @StorageLink('isPlay') isPlay: boolean = false;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @StorageLink('selectIndex') selectIndex: number = 0;
  @Prop isCurrent: boolean = false;
  @StorageProp('isDark') isDark: boolean = false;
  item: SongItem | undefined = undefined;
  index: number | undefined = undefined;
  onQueueChanged: () => void = () => {};

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.item!.title)
            .fontColor(this.isCurrent && this.isPlay ? this.getThemeColors().accent : this.getThemeColors().primaryText)
            .fontSize(new BreakpointType({
              sm: $r('app.float.item_font_sm'),
              md: $r('app.float.item_font_md'),
              lg: $r('app.float.item_font_lg')
            }).getValue(this.currentBreakpoint))
            .margin({ bottom: $r('app.float.list_item_title_margin') })
          Row() {
            Stack() {
              CoverImageView({ src: this.item!.src, coverSize: 16, coverRadius: 2 })
            }
            .margin({ right: $r('app.float.list_item_image_margin') })
            Text(this.item!.singer)
              .opacity($r('app.float.singer_opacity'))
              .fontColor(this.isCurrent && this.isPlay ? this.getThemeColors().accent : this.getThemeColors().primaryText)
              .fontSize(new BreakpointType({
                sm: $r('app.float.singer_title_sm'),
                md: $r('app.float.singer_title_md'),
                lg: $r('app.float.singer_title_lg')
              }).getValue(this.currentBreakpoint))
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .onClick(() => {
        if (this.index === undefined) {
          return;
        }
        if (this.index === this.selectIndex && this.isPlay) {
          return;
        }
        AudioRendererController.getInstance().play(this.index);
      })
      .height($r('app.float.list_item_height'))
      .width(StyleConstants.FULL_WIDTH)
      .bindMenu(this.buildRowMenu)
    }
    .padding({
      left: $r('app.float.list_item_padding'),
      right: $r('app.float.list_item_padding')
    })
  }

  @Builder
  buildRowMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.queue_play') })
        .onClick(() => {
          if (this.index !== undefined) {
            AudioRendererController.getInstance().play(this.index);
          }
          this.onQueueChanged();
        })
      MenuItem({ content: $r('app.string.queue_play_next') })
        .onClick(() => {
          if (this.index !== undefined) {
            AudioRendererController.getInstance().moveToPlayNext(this.index);
          }
          this.onQueueChanged();
        })
      MenuItem({ content: $r('app.string.queue_remove') })
        .onClick(() => {
          if (this.index !== undefined) {
            AudioRendererController.getInstance().removeFromQueue(this.index);
          }
          this.onQueueChanged();
        })
    }
  }
}