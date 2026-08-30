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
import { StyleConstants } from '../common/constants/StyleConstants';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { ControlAreaComponent } from './ControlAreaComponent';
import { ContainerReader } from '@kit.ArkUI';
import { LengthMetrics } from '@ohos.arkui.node';
import { ApiCompat } from '../common/utils/ApiCompat';

/**
 * 容器真实尺寸（vp）。作为 ContainerReader 断点分析的参考尺寸，
 * 由 onAreaChange 回填；显式具名接口以符合 ArkTS 禁用匿名对象字面量类型（arkts-no-obj-literals-as-types）约束。
 */
interface ContainerSize {
  width: number;
  height: number;
}

@Preview
@Component
export struct MusicInfoComponent {
  @State currentTabIndex: number = 0;
  @StorageProp('currentBreakpoint') @Watch('refreshSongStyledString') currentBreakpoint: string =
    BreakpointConstants.BREAKPOINT_SM;
  @StorageLink('isFoldFull') @Watch('refreshSongStyledString') isFoldFull: boolean = false;
  @StorageLink('songList') @Watch('refreshSongStyledString') songList: SongItem[] = [];
  @StorageProp('selectIndex') @Watch('refreshSongStyledString') selectIndex: number = 0;
  @State isShowControl: boolean = false;
  // 容器真实尺寸（vp），由 onAreaChange 回填，作为 ContainerReader 断点分析的参考尺寸
  @State containerSize: ContainerSize = { width: 360, height: 800 };
  // 富文本控制器：AttributeString（StyledString）经 TextController 绑定到 Text 组件
  private textController: TextController = new TextController();

  /**
   * 取当前播放歌曲（带边界保护，避免 songList 为空或索引越界导致崩溃）。
   */
  private currentSong(): SongItem | undefined {
    if (!this.songList || this.songList.length === 0) {
      return undefined;
    }
    return this.songList[this.selectIndex] ?? undefined;
  }

  aboutToAppear(): void {
    // 首次挂载即推送富文本，避免 Text 短暂空白
    this.refreshSongStyledString();
  }

  /**
   * 歌曲/断点/折叠态变化时重新推送「标题 + 歌手」富文本到 TextController。
   * @Watch 在属性变更后回调；aboutToAppear 负责首次渲染。
   */
  private refreshSongStyledString(): void {
    this.textController.setStyledString(this.buildSongStyledString());
  }

  build() {
    if (ApiCompat.isAtLeast(ApiCompat.API_26)) {
      // 鸿蒙新特性 ContainerReader（API 26）：包裹 GridRow，使其断点分析基于「容器真实尺寸」
      // 而非窗口尺寸。容器渲染尺寸经 onAreaChange 回填，折叠屏/平板分屏等容器宽度变化时布局自适应更精准。
      ContainerReader({ size: this.containerSize })
        .onAreaChange((_oldArea: Area, newArea: Area) => {
          const w: number = typeof newArea.width === 'number' ? newArea.width : 0;
          const h: number = typeof newArea.height === 'number' ? newArea.height : 0;
          if (w > 0 && h > 0 && (w !== this.containerSize.width || h !== this.containerSize.height)) {
            this.containerSize = { width: w, height: h };
          }
        })
        .breakpointConfig({ width: [600, 840] }) {
        this.GridRowContent()
      }
    } else {
      // API 24 降级：ContainerReader 为 API 26 引入的组件，低版本实例化会直接崩溃。
      // 直接渲染 GridRow——其 breakpoints reference=ComponentSize 已基于自身宽度断点，
      // 同样能获得容器级自适应，无需 ContainerReader。
      this.GridRowContent()
    }
  }

  @Builder
  private GridRowContent() {
    GridRow({
      columns: {
        xs: BreakpointConstants.COLUMN_SM,
        sm: BreakpointConstants.COLUMN_SM,
        md: BreakpointConstants.COLUMN_MD
      },
      gutter: BreakpointConstants.GUTTER_MUSIC_X,
      breakpoints: { reference: BreakpointsReference.ComponentSize }
    }) {
      GridCol({
        span: {
          xs: BreakpointConstants.SPAN_SM,
          sm: BreakpointConstants.SPAN_SM,
          md: BreakpointConstants.SPAN_MD
        },
        offset: { md: BreakpointConstants.OFFSET_MD }
      }) {
        Column() {
          this.CoverInfo()
          this.MusicInfo()
          Blank()
          ControlAreaComponent()
        }
        .height(StyleConstants.FULL_HEIGHT)
        .width(StyleConstants.FULL_WIDTH)
        .clip(false)
      }
    }
  }

  @Builder
  CoverInfo() {
    Row() {
      Image(this.currentSong()?.getLabel() ?? $r('app.media.ic_default_cover'))
        .width(StyleConstants.FULL_WIDTH)
        .aspectRatio(1)
        .borderRadius($r('app.float.cover_radius_label'))
        .shadow({
          radius: $r('app.float.shadow_radius'),
          color: $r('app.color.shadow_color'),
          offsetX: 0,
          offsetY: 8
        })
        .margin($r('app.float.lyric_margin_right_sm'))
        .geometryTransition('player_cover')
    }
  }

  @Builder
  MusicInfo() {
    // 鸿蒙新特性 AttributeString（StyledString）：标题与歌手合并为单个富文本，
    // 同一字符串内多 run 差异化样式（标题加粗放大、歌手常规缩小降透明度）。
    // StyledString 经 TextController 绑定到 Text（Text 构造本身仅接受 string | Resource）。
    Text('', { controller: this.textController })
      .width(StyleConstants.FULL_WIDTH)
      .margin({ top: $r('app.float.music_info_margin_top') })
  }

  /**
   * 构建「标题 + 歌手」富文本：标题 run 加粗并随断点放大，歌手 run 常规字号、降透明度，
   * 保留原有响应式字号逻辑，避免逐字符拼接多个 Text 组件。
   */
  private buildSongStyledString(): StyledString {
    const song: SongItem | undefined = this.currentSong();
    const title: string = song?.title ?? '';
    const singer: string = song?.singer ?? '';
    const titleSize: number = this.currentBreakpoint === BreakpointConstants.BREAKPOINT_MD && !this.isFoldFull ?
      22 : 19;
    const raw: string = title + '\n' + singer;
    const styles: Array<StyleOptions> = [
      {
        start: 0,
        length: title.length,
        styledKey: StyledStringKey.FONT,
        styledValue: new TextStyle({
          fontWeight: FontWeight.Bold,
          fontSize: LengthMetrics.fp(titleSize),
          fontColor: Color.White
        })
      },
      {
        start: title.length + 1,
        length: singer.length,
        styledKey: StyledStringKey.FONT,
        styledValue: new TextStyle({
          fontWeight: FontWeight.Regular,
          fontSize: LengthMetrics.fp(14),
          fontColor: $r('app.color.play_text_color')
        })
      }
    ];
    return new StyledString(raw, styles);
  }
}
