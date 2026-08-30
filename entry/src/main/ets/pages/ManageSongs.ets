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

import { Logger } from '../utils/Logger';
import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';
import { AudioRendererController } from '../utils/AudioRendererController';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { CoverImageView } from '../components/CoverImageView';
import { QualityBadge } from '../components/QualityBadge';

@Builder
export function ManageSongsBuilder() {
  ManageSongs()
}

@Component
struct ManageSongs {
  pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('onCoverRefreshed') coverRefreshToken: number = 0;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @State songs: SongItem[] = [];
  @State itemScales: number[] = [];
  @State backScale: number = 1.0;
  @State emptyIconScale: number = 1.0;
  @State pendingDelete: SongItem | null = null;

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    this.songs = [...this.store.songs];
    this.itemScales = this.songs.map(() => 1.0);
  }

  onCoverRefreshed() {
    this.reload();
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (e) {
      Logger.error('toast failed');
    }
  }

  private confirmDelete(song: SongItem): void {
    this.pendingDelete = song;
    this.showDeleteDialog();
  }

  private showDeleteDialog(): void {
    if (!this.pendingDelete) {
      return;
    }
    const title: string = this.pendingDelete.title;
    this.getUIContext().showAlertDialog({
      title: '移除歌曲',
      message: `确定从本地库中移除「${title}」？`,
      primaryButton: { value: '取消', action: () => { this.pendingDelete = null; } },
      secondaryButton: { value: '移除', action: () => { this.doDelete(); } }
    });
  }

  private doDelete(): void {
    if (this.pendingDelete) {
      const id: number = this.pendingDelete.id;
      this.store.removeSong(id);
      AudioRendererController.getInstance().reconcileWithLibrary(this.store.songs);
      this.pendingDelete = null;
      this.reload();
      this.toast('已移除歌曲');
    }
  }

  @Builder
  buildSongItem(song: SongItem, index: number) {
    Row() {
      Stack() {
        CoverImageView({ src: song.src, coverSize: 48, coverRadius: 8 })
      }

      Column() {
        Row() {
          Text(song.title)
            .fontSize(15)
            .fontColor(this.getThemeColors().primaryText)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          QualityBadge({ quality: song.getQuality() })
            .margin({ left: 6 })
        }
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 4 })

        Text(song.singer)
          .fontSize(13)
          .fontColor(this.getThemeColors().secondaryText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })

      Image($r('app.media.ic_hm_more'))
        .width(20)
        .height(20)
        .fillColor(this.getThemeColors().secondaryText)
        .padding(8)
        .bindMenu([
          {
            value: '移除',
            action: () => {
              this.confirmDelete(song);
            }
          }
        ])
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 8 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(12)
    .margin({ left: 8, right: 8, bottom: 8 })
    .scale({ x: this.itemScales[index] ?? 1.0, y: this.itemScales[index] ?? 1.0 })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 30 })))
    .animation({ duration: 300, curve: Curve.EaseOut, delay: index * 50 })
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

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Image($r('app.media.ic_hm_back'))
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

          Text('本地歌曲管理')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: 12 })
            .layoutWeight(1)

          Text(`${this.songs.length} 首`)
            .fontSize(13)
            .fontColor(this.getThemeColors().accent)
            .backgroundColor('rgba(250, 39, 89, 0.1)')
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 16 })

        if (this.songs.length === 0) {
          Column() {
            Image($r('app.media.ic_hm_library'))
              .width(72)
              .height(72)
              .fillColor(this.getThemeColors().secondaryText)
              .margin({ bottom: 16 })
              .scale({ x: this.emptyIconScale, y: this.emptyIconScale })
              .animation({ duration: 2000, curve: Curve.EaseInOut })

            Text('暂无本地歌曲')
              .fontSize(16)
              .fontColor(this.getThemeColors().secondaryText)
              .fontWeight(FontWeight.Medium)

            Text('在「音乐库」导入本地音频后会显示在这里')
              .fontSize(13)
              .fontColor(this.getThemeColors().secondaryText)
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.songs, (song: SongItem, index: number) => {
              ListItem() {
                this.buildSongItem(song, index)
              }
            })
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .hideTitleBar(true)
  }
}
