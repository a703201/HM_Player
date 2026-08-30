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
import { AudioRendererController } from '../utils/AudioRendererController';
import { CoverImageView } from '../components/CoverImageView';
import { Logger } from '../utils/Logger';

interface YearStat {
  year: string;
  plays: number;
}

@Builder
export function WrappedBuilder() {
  Wrapped()
}

@Component
struct Wrapped {
  pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;

  @State backScale: number = 1.0;
  @State totalPlays: number = 0;
  @State totalMs: number = 0;
  @State topSongs: SongItem[] = [];
  @State yearStats: YearStat[] = [];
  @State hasData: boolean = false;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  aboutToAppear(): void {
    const summary = this.store.getStatsSummary();
    this.totalPlays = summary.totalPlays;
    this.totalMs = summary.totalMs;
    this.topSongs = summary.topSongs;
    this.yearStats = this.computeYearStats();
    this.hasData = this.totalPlays > 0 && this.store.songs.length > 0;
  }

  /** 按歌曲年份聚合播放次数，取前 6 年用于分布图。 */
  private computeYearStats(): YearStat[] {
    const map: Map<string, number> = new Map<string, number>();
    this.store.playCounts.forEach((plays: number, songId: number) => {
      const song: SongItem | undefined = this.store.songs.find((s: SongItem) => s.id === songId);
      const year: string = (song && song.year) ? song.year : '未知年份';
      map.set(year, (map.get(year) ?? 0) + plays);
    });
    const arr: YearStat[] = [];
    map.forEach((plays: number, year: string) => {
      arr.push({ year, plays });
    });
    arr.sort((a: YearStat, b: YearStat) => b.plays - a.plays);
    return arr.slice(0, 6);
  }

  private formatDuration(ms: number): string {
    const minutes: number = Math.floor(ms / 60000);
    const hours: number = Math.floor(minutes / 60);
    const days: number = Math.floor(hours / 24);
    if (days > 0) {
      const remHours: number = hours - days * 24;
      return `${days} 天 ${remHours} 小时`;
    }
    if (hours > 0) {
      const remMin: number = minutes - hours * 60;
      return `${hours} 小时 ${remMin} 分钟`;
    }
    if (minutes > 0) {
      return `${minutes} 分钟`;
    }
    return '不到 1 分钟';
  }

  private playSong(song: SongItem): void {
    const globalIndex = this.store.songs.findIndex(s => s.id === song.id);
    if (globalIndex >= 0) {
      this.store.currentIndex = globalIndex;
      AudioRendererController.getInstance().playFromList(this.store.songs, globalIndex);
    }
    this.pathStack.pushPathByName('PlayerPage', null);
  }

  private maxYearPlays(): number {
    let m: number = 1;
    this.yearStats.forEach((y: YearStat) => {
      if (y.plays > m) {
        m = y.plays;
      }
    });
    return m;
  }

  @Builder
  buildHero() {
    Column() {
      Text('听歌报告')
        .fontSize(13)
        .fontColor('#FA2759')
        .fontWeight(FontWeight.Medium)
        .letterSpacing(1)
        .margin({ bottom: 10 })

      Text(`${this.totalPlays}`)
        .fontSize(56)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)

      Text('次播放')
        .fontSize(15)
        .fontColor(this.getThemeColors().secondaryText)
        .margin({ top: 2, bottom: 18 })

      Row() {
        Column() {
          Text('总收听时长')
            .fontSize(12)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ bottom: 4 })
          Text(this.formatDuration(this.totalMs))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
        }
        .layoutWeight(1)

        Column() {
          Text('歌曲总数')
            .fontSize(12)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ bottom: 4 })
          Text(`${this.store.songs.length}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(24)
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(20)
    .margin({ left: 8, right: 8, bottom: 16 })
  }

  @Builder
  buildTopSongs() {
    this.buildSectionLabel('最常播放');
    Column() {
      ForEach(this.topSongs, (song: SongItem, index: number) => {
        Row() {
          Text(`${index + 1}`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(index < 3 ? '#FA2759' : this.getThemeColors().secondaryText)
            .width(28)
            .textAlign(TextAlign.Center)

          Stack() {
            CoverImageView({ src: song.src, coverSize: 44, coverRadius: 8 })
          }

          Column() {
            Text(song.title)
              .fontSize(15)
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

          Text(`${this.store.getPlayCount(song.id)} 次`)
            .fontSize(13)
            .fontColor(this.getThemeColors().secondaryText)
        }
        .width('100%')
        .height(58)
        .padding({ left: 12, right: 14 })
        .backgroundColor(this.getThemeColors().cardBg)
        .borderRadius(12)
        .margin({ bottom: 6 })
        .onClick(() => {
          this.playSong(song);
        })
      }, (song: SongItem) => 'top_' + song.id.toString())
    }
    .margin({ left: 8, right: 8, bottom: 16 })
  }

  @Builder
  buildYearChart() {
    this.buildSectionLabel('按发行年份');
    Column() {
      ForEach(this.yearStats, (y: YearStat) => {
        Row() {
          Text(y.year)
            .fontSize(13)
            .fontColor(this.getThemeColors().secondaryText)
            .width(64)
          Stack() {
            Row()
              .width(`${Math.max(8, (y.plays / this.maxYearPlays()) * 100)}%`)
              .height(14)
              .backgroundColor('#FA2759')
              .borderRadius(7)
          }
          .width('100%')
          .height(14)
          .backgroundColor(this.getThemeColors().secondaryBg)
          .borderRadius(7)
          .margin({ left: 8 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 10 })
      }, (y: YearStat) => 'year_' + y.year)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(20)
    .margin({ left: 8, right: 8, bottom: 16 })
  }

  @Builder
  buildSectionLabel(text: string) {
    Text(text)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.getThemeColors().primaryText)
      .width('100%')
      .padding({ left: 12, bottom: 10 })
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

          Text('我的听歌报告')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: 12 })
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 12 })

        if (!this.hasData) {
          Column() {
            Image($r('app.media.ic_music'))
              .width(64)
              .height(64)
              .fillColor(this.getThemeColors().secondaryText)
              .margin({ bottom: 16 })
            Text('还没有足够的数据')
              .fontSize(16)
              .fontColor(this.getThemeColors().secondaryText)
              .fontWeight(FontWeight.Medium)
            Text('多听几首歌，这里会生成你的听歌报告')
              .fontSize(13)
              .fontColor('#636366')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              this.buildHero();
              this.buildTopSongs();
              if (this.yearStats.length > 0) {
                this.buildYearChart();
              }
              Text('数据仅在本地统计，不上传任何服务器')
                .fontSize(12)
                .fontColor(this.getThemeColors().secondaryText)
                .margin({ top: 8, bottom: 24 })
            }
            .width('100%')
            .padding({ left: 8, right: 8, bottom: 24 })
          }
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
