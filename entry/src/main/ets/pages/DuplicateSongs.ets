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

import { SongItem } from '../models/music';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { MusicStore } from '../services/MusicStore';
import { DuplicateDetector, DuplicateGroup } from '../utils/DuplicateDetector';
import { CoverImageView } from '../components/CoverImageView';
import { Logger } from '../utils/Logger';

@Builder
export function DuplicateSongsBuilder() {
  DuplicateSongs()
}

@Component
struct DuplicateSongs {
  pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('onCoverRefreshed') coverRefreshToken: number = 0;

  @State groups: DuplicateGroup[] = [];
  @State backScale: number = 1.0;
  @State itemScales: number[] = [];

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  aboutToAppear(): void {
    this.refresh();
  }

  onCoverRefreshed(): void {
    // 封面刷新仅触发重绘，无需重算分组
  }

  private refresh(): void {
    this.groups = DuplicateDetector.findDuplicates(this.store.songs);
    this.itemScales = this.groups.map((_: DuplicateGroup, i: number) => this.itemScales[i] ?? 1.0);
  }

  /** 仅统计「额外重复」曲目数（每组保留首条，其余为可清理项）。 */
  private duplicateCount(): number {
    let n: number = 0;
    this.groups.forEach((g: DuplicateGroup) => {
      n += Math.max(0, g.songs.length - 1);
    });
    return n;
  }

  private removeOne(song: SongItem): void {
    this.store.removeSong(song.id);
    this.refresh();
  }

  private removeAllDuplicates(): void {
    this.groups.forEach((g: DuplicateGroup) => {
      for (let i = 1; i < g.songs.length; i++) {
        this.store.removeSong(g.songs[i].id);
      }
    });
    this.refresh();
    try {
      this.getUIContext().getPromptAction().showToast({ message: '已清理重复歌曲' });
    } catch (e) {
      Logger.error('DuplicateSongs', 'toast failed');
    }
  }

  @Builder
  buildGroupCard(group: DuplicateGroup, index: number) {
    Column() {
      // 组头：归一化标题 + 重复数量
      Row() {
        Text(group.key)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColors().primaryText)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${group.songs.length} 个文件`)
          .fontSize(12)
          .fontColor('#FA2759')
          .backgroundColor('rgba(250, 39, 89, 0.1)')
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 8 })

      // 组内每首：保留首条标「保留」，其余可移除
      ForEach(group.songs, (song: SongItem, i: number) => {
        Row() {
          Stack() {
            CoverImageView({ src: song.src, coverSize: 40, coverRadius: 8 })
          }

          Column() {
            Text(song.title)
              .fontSize(14)
              .fontColor(this.getThemeColors().primaryText)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(song.singer)
              .fontSize(12)
              .fontColor(this.getThemeColors().secondaryText)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 10 })

          if (i === 0) {
            Text('保留')
              .fontSize(12)
              .fontColor(this.getThemeColors().secondaryText)
              .backgroundColor(this.getThemeColors().secondaryBg)
              .borderRadius(10)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          } else {
            Text('移除')
              .fontSize(13)
              .fontColor('#FA2759')
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                this.removeOne(song);
              })
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      }, (song: SongItem) => 'dup_' + song.id.toString())
    }
    .width('100%')
    .margin({ left: 8, right: 8, bottom: 12 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(14)
    .scale({ x: this.itemScales[index] ?? 1.0, y: this.itemScales[index] ?? 1.0 })
    .animation({ duration: 300, curve: Curve.EaseOut, delay: this.entryDelay(index) })
  }

  /** 列表入场错峰延迟：降低动态效果开启时取消错峰。 */
  private entryDelay(index: number): number {
    // 降低动态效果偏好直接读取 SettingsStore 成本略高，这里采用固定轻量错峰
    return index * 40;
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .scale({ x: this.backScale, y: this.backScale })
            .animation({ duration: 150, curve: Curve.EaseOut })
            .onClick(() => {
              this.pathStack.pop();
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.backScale = 0.8;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.backScale = 1.0;
              }
            })

          Text('重复歌曲')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: 12 })
            .layoutWeight(1)

          if (this.duplicateCount() > 0) {
            Text('清理全部')
              .fontSize(14)
              .fontColor('#FA2759')
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                this.removeAllDuplicates();
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 12 })

        if (this.groups.length === 0) {
          Column() {
            Image($r('app.media.ic_music_list'))
              .width(64)
              .height(64)
              .fillColor(this.getThemeColors().secondaryText)
              .margin({ bottom: 16 })
            Text('没有发现重复歌曲')
              .fontSize(16)
              .fontColor(this.getThemeColors().secondaryText)
              .fontWeight(FontWeight.Medium)
            Text('基于标题与歌手相似度比对，跨歌手同名不会被误判')
              .fontSize(13)
              .fontColor('#636366')
              .margin({ top: 8 })
              .width('70%')
              .textAlign(TextAlign.Center)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.groups, (group: DuplicateGroup, index: number) => {
              ListItem() {
                this.buildGroupCard(group, index)
              }
            }, (group: DuplicateGroup) => 'group_' + group.key)
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .hideTitleBar(true)
  }
}
