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

import { SongItem } from '../songdatacontroller/SongData';
import { BreakpointType } from '../common/utils/BreakpointSystem'
import { StyleConstants } from '../common/constants/StyleConstants';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { LrcEntry } from '../lyric/LrcEntry';
import { parseLrcLyric } from '../lyric/LrcUtils';
import { EmbeddedLyricReader } from '../utils/EmbeddedLyricReader';
import LrcView from '../lyric/LrcView';
import { LyricScrollEffect, LyricTopPosition } from '../lyric/LyricConst';
import { ControlAreaComponent } from './ControlAreaComponent';
import { PlayerConstants } from '../common/constants/PlayerConstants';
import { Logger } from '../utils/Logger';
import { AudioRendererController } from '../utils/AudioRendererController';
import { onMediaOf } from '../tokens/LumioColor';

const TAG: string = 'LyricsComponent';

@Component
export struct LyricsComponent {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @StorageLink('progress') @Watch('onProgressTick') time: number = 0;
  @StorageLink('isFoldFull') isFoldFull: boolean = false;
  @State progress: number = 0.01;
  @State progressText: string = '';
  @State lyricScrollEffect: LyricScrollEffect = LyricScrollEffect.Line;
  @State mLrcEntryList: Array<LrcEntry> = [];
  @State showTranslation: boolean = true;
  @StorageLink('songList') songList: SongItem[] = [];
  @StorageProp('selectIndex') @Watch('getLrcEntryList') selectIndex: number = 0;
  @StorageProp('lyricBgDark') lyricBgDark: boolean = true;
  @StorageLink('isPlay') isPlay: boolean = false;
  @Link isShowControl: boolean;
  @Link isTablet: boolean;
  @State intervalID: number = 0;
  @State pageShowTime: number = 0;
  private lastLyricLine: string = ''; // 已推送至桌面卡片的当前歌词行，避免重复写 AppStorage

  aboutToAppear() {
    this.getLrcEntryList();
  }

  /**
   * progress（当前播放位置 ms）变化时，重新定位并发布当前歌词行到桌面卡片。
   * 由 @Watch('onProgressTick') 在 timeUpdate 周期（约 4Hz）触发，仅当行文本变化时写 AppStorage。
   */
  private onProgressTick(): void {
    this.publishCurrentLyric();
  }

  /**
   * 依据当前播放位置在 mLrcEntryList 中定位活动歌词行（lineStartTime <= 位置 的最大者），
   * 经 AppStorage 'cardLyric' 暴露给 AVSessionController，供桌面卡片实时展示。
   * 无歌词或越界时发布空串（卡片据此隐藏歌词行）。
   */
  private publishCurrentLyric(): void {
    let line: string = '';
    const list: Array<LrcEntry> = this.mLrcEntryList;
    if (list.length > 0) {
      let idx: number = -1;
      for (let i: number = 0; i < list.length; i++) {
        if (list[i].lineStartTime <= this.time) {
          idx = i;
        } else {
          break;
        }
      }
      if (idx >= 0) {
        line = list[idx].lineWords;
      }
    }
    if (this.lastLyricLine !== line) {
      this.lastLyricLine = line;
      AppStorage.setOrCreate('cardLyric', line);
    }
  }

  /**
   * 歌词来源：**只从文件读，不在代码/资源包里内置歌词**。
   * EmbeddedLyricReader 内部依次尝试
   *   1) 音频内嵌标签（MP3 ID3 USLT/TXXX、FLAC VORBIS LYRICS、MP4 ©lyr / '----'）
   *   2) 同目录同名 .lrc 外挂文件
   * 两者都没有则显示"暂无歌词"。
   */
  getLrcEntryList() {
    this.mLrcEntryList = [];
    const song = this.songList[this.selectIndex];
    if (!song) {
      return;
    }
    const token = this.selectIndex;
    EmbeddedLyricReader.read(song.src)
      .then((lyricText: string | undefined) => {
        if (token !== this.selectIndex) {
          return; // 期间已切歌，丢弃过期结果
        }
        if (!lyricText || lyricText.trim().length === 0) {
          Logger.debugPrivate(TAG, 'no lyric found for ' + song.src);
          return;
        }
        this.mLrcEntryList = parseLrcLyric(lyricText);
        Logger.debugPrivate(TAG, 'src=' + song.src + ' lyricLen=' + lyricText.length +
          ' entries=' + this.mLrcEntryList.length);
        // 歌词刷新后立即同步当前行到桌面卡片（按当前播放位置定位）
        this.publishCurrentLyric();
      })
      .catch((err: Error) => {
        Logger.debug(TAG, 'read lyric failed: ' + err.message);
      });
  }

  /**
   * 点击歌词行跳转：命中行 → 取 lineStartTime → seek。
   */
  private onLyricLineClick(index: number): void {    if (index < 0 || index >= this.mLrcEntryList.length) {
      return;
    }
    const entry = this.mLrcEntryList[index];
    if (!entry) {
      return;
    }
    Logger.info(TAG, `lyric click seek: index=${index} time=${entry.lineStartTime}`);
    AudioRendererController.getInstance().seek(entry.lineStartTime);
  }

  build() {
    Column() {
      if (this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM) {
        Row() {
          if (!this.isTablet) {
            Image(this.songList[this.selectIndex].getLabel())
              .width(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ?
              $r('app.float.label_width_sm') : $r('app.float.label_width'))
              .borderRadius($r('app.float.label_border'))
              .margin({
                right: $r('app.float.label_margin_right')
              })
          }
          Column() {
            Text(this.songList[this.selectIndex].title)
              .fontSize(new BreakpointType({
                sm: $r('app.float.title_font_sm'),
                md: $r('app.float.title_font_md'),
                lg: $r('app.float.title_font_lg')
              }).getValue(this.currentBreakpoint))
              .fontColor(onMediaOf(this.lyricBgDark).primary)
              .fontWeight(PlayerConstants.FONT_WEIGHT_700)
              .fontFamily(PlayerConstants.FONT_FAMILY_BOLD)
            Text(this.songList[this.selectIndex].singer)
              .fontSize(new BreakpointType({
                sm: $r('app.float.singer_font_sm'),
                md: $r('app.float.singer_font_md'),
                lg: $r('app.float.singer_font_lg')
              }).getValue(this.currentBreakpoint))
              .fontColor(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
              $r('app.color.singer_text') : $r('sys.color.ohos_id_color_text_hint_contrary'))
              .fontWeight(PlayerConstants.FONT_WEIGHT_500)
              .fontFamily(PlayerConstants.FONT_FAMILY_MEDIUM)
              .margin({
                top: $r('app.float.singer_margin_top')
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width(StyleConstants.FULL_WIDTH)
        .justifyContent(FlexAlign.Start)
        .margin({
          top: new BreakpointType({
            sm: $r('app.float.info_margin_top_sm'),
            md: $r('app.float.zero_margin'),
            lg: $r('app.float.zero_margin')
          }).getValue(this.currentBreakpoint),
          bottom: $r('app.float.info_margin_bottom')
        })
      }

      if (this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG) {
        Row() {
          GridRow({
            columns: { lg: BreakpointConstants.COLUMN_LYRIC_LG }
          }) {
            GridCol({
              span: { lg: BreakpointConstants.SPAN_LYRIC_LG },
              offset: BreakpointConstants.OFFSET_MD
            }) {
              Column() {
                Row() {
                  Column() {
                    Text(this.songList[this.selectIndex].title)
                      .fontSize(new BreakpointType({
                        sm: $r('app.float.title_font_sm'),
                        md: $r('app.float.title_font_md'),
                        lg: $r('app.float.title_font_lg')
                      }).getValue(this.currentBreakpoint))
                      .fontColor(onMediaOf(this.lyricBgDark).primary)
                      .fontWeight(PlayerConstants.FONT_WEIGHT_700)
                      .fontFamily(PlayerConstants.FONT_FAMILY_BOLD)
                    Text(this.songList[this.selectIndex].singer)
                      .fontSize(new BreakpointType({
                        sm: $r('app.float.singer_font_sm'),
                        md: $r('app.float.singer_font_md'),
                        lg: $r('app.float.singer_font_lg')
                      }).getValue(this.currentBreakpoint))
                      .fontColor($r('sys.color.ohos_id_color_text_hint_contrary'))
                      .fontFamily(PlayerConstants.FONT_FAMILY_MEDIUM)
                      .margin({
                        top: $r('app.float.singer_margin_top')
                      })
                  }
                  .alignItems(HorizontalAlign.Start)
                }
                .width(StyleConstants.FULL_WIDTH)
                .justifyContent(FlexAlign.Start)
                .margin({
                  top: new BreakpointType({
                    sm: $r('app.float.info_margin_top_sm'),
                    md: $r('app.float.zero_margin'),
                    lg: $r('app.float.zero_margin')
                  }).getValue(this.currentBreakpoint),
                  bottom: $r('app.float.info_margin_bottom')
                })

                LrcView({
                  lyricMilliSecondsTime: this.time,
                  mLrcEntryList: this.mLrcEntryList,
                  lyricScrollEffect: this.lyricScrollEffect,
                  lyricTopPosition: LyricTopPosition.Middle,
                  showTranslation: this.showTranslation,
                  backgroundIsDark: this.lyricBgDark,
                  onLineClick: (index: number) => { this.onLyricLineClick(index); }
                })
                  .width('100%')
                  .height('100%')
                  .layoutWeight(1)
              }
            }
          }
        }
        .layoutWeight(1)
      } else {
        LrcView({
          lyricMilliSecondsTime: this.time,
          mLrcEntryList: this.mLrcEntryList,
          lyricScrollEffect: this.lyricScrollEffect,
          lyricTopPosition: LyricTopPosition.Middle,
          showTranslation: this.showTranslation,
          backgroundIsDark: this.lyricBgDark,
          onLineClick: (index: number) => { this.onLyricLineClick(index); }
        })
          .width('100%')
          .height('100%')
          .layoutWeight(1)
      }

      Row() {
        Image(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
        $r('app.media.ic_public_text') : $r('app.media.ic_public_text'))
          .fillColor(onMediaOf(this.lyricBgDark).primary)
          .width(new BreakpointType({
            sm: $r('app.float.lyrics_width_sm'),
            md: $r('app.float.lyrics_width_md'),
            lg: $r('app.float.lyrics_width_lg')
          }).getValue(this.currentBreakpoint))
          .aspectRatio(1)
          .opacity(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_LG ? 1 : 0.86)
      }
      .onClick(() => { this.showTranslation = !this.showTranslation; })
      .opacity(this.showTranslation ? 1 : 0.4)
      .width(StyleConstants.FULL_WIDTH)
      .height($r('app.float.control_icon_height'))
      .justifyContent(FlexAlign.End)
      .margin({
        top: $r('app.float.lyric_margin_top'),
        bottom: new BreakpointType({
          sm: $r('app.float.lyric_margin_bottom_sm'),
          md: $r('app.float.lyric_margin_bottom_md'),
          lg: $r('app.float.lyric_margin_bottom_lg')
        }).getValue(this.currentBreakpoint),
        right: new BreakpointType({
          sm: $r('app.float.lyric_margin_right_sm'),
          md: $r('app.float.lyric_margin_right_md'),
          lg: $r('app.float.lyric_margin_right_lg')
        }).getValue(this.currentBreakpoint)
      })

      if (this.isShowControl) {
        ControlAreaComponent()
          .margin({
            top: $r('app.float.control_lyric_margin'),
            bottom: $r('app.float.music_component_bottom')
          })
      }
    }
    .onClick(() => {
      this.pageShowTime = 0;
    })
  }
}
