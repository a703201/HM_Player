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
import { semanticOf } from '../tokens/LumioColor';
import { CoverImageView } from '../components/CoverImageView';
import { QualityBadge } from '../components/QualityBadge';
import { SongRow } from '../components/SongRow';
import { DuplicateDetector, DuplicateGroup } from '../utils/DuplicateDetector';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';
import { TYPE_SM, SPACE_SM } from '../tokens/LumioScale';

interface YearStat {
  year: string;
  plays: number;
}

/**
 * Settings sheet 内嵌子页的统一样式头部：左侧返回箭头 + 大标题 + 右侧占位。
 * onBack 由外层传入（sheet 内关闭 subPage / 主导航栈 pop）。
 */
@Component
export struct SubPageHeader {
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  title: string = '';
  onBack: () => void = () => {};
  rightSlot?: () => void;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  build() {
    Row() {
      Image($r('app.media.ic_public_arrow_left'))
        .width(24)
        .height(24)
        .fillColor(this.getThemeColors().primaryText)
        .onClick(() => this.onBack())
      Text(this.title)
        .fontSize(TYPE_SM.title2.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .margin({ left: SPACE_SM.cozy })
        .layoutWeight(1)
      // 右侧占位（由调用方决定是否提供）
      Row() {
      }
      .width(24)
      .height(24)
    }
    .width('100%')
    .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: this.topHeight + 12, bottom: SPACE_SM.cozy })
  }
}

/**
 * 本地歌曲管理：列出库内全部歌曲，长按移除。从原 ManageSongs.ets 抽出，与 sheet 内
 * 嵌场景共享同一份渲染逻辑；onBack 由调用方控制（sheet 内切换 subPage 或主栈 pop）。
 */
@Component
export struct ManageSongsBody {
  store: MusicStore = MusicStore.getInstance();
  onBack: () => void = () => {};
  /** sheet 内嵌时由 Settings 传 false 跳过自身表头，避免与 Settings 标题栏重复。 */
  showHeader: boolean = true;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('onCoverRefreshed') coverRefreshToken: number = 0;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @State songs: SongItem[] = [];
  @State itemScales: number[] = [];
  @State emptyIconScale: number = 1.0;
  @State pendingDelete: SongItem | null = null;

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    this.songs = [...this.store.songs];
    this.itemScales = this.songs.map(() => 1.0);
  }

  onCoverRefreshed(): void {
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

  

  build() {
    Column() {
      if (this.showHeader) {
        SubPageHeader({ title: '本地歌曲管理', onBack: () => this.onBack() })
      }

      Text(`${this.songs.length} 首`)
        .fontSize(TYPE_SM.footnote.size)
        .fontColor(this.getThemeColors().accent)
        .backgroundColor(semanticOf(this.isDark).fillAccentSoft)
        .borderRadius(12)
        .padding({ left: SPACE_SM.cozy, right: SPACE_SM.cozy, top: SPACE_SM.tight, bottom: SPACE_SM.tight })
        .margin({ left: SPACE_SM.base, bottom: SPACE_SM.cozy })
        .visibility(this.songs.length > 0 ? Visibility.Visible : Visibility.Hidden)

      if (this.songs.length === 0) {
        Column() {
          Image($r('app.media.ic_public_albums'))
            .width(72)
            .height(72)
            .fillColor(this.getThemeColors().secondaryText)
            .margin({ bottom: SPACE_SM.base })
            .scale({ x: this.emptyIconScale, y: this.emptyIconScale })
            .animation({ duration: 2000, curve: LumioTheme.curve(SpringKind.Crisp) })
          Text('暂无本地歌曲')
            .fontSize(TYPE_SM.headline.size)
            .fontColor(this.getThemeColors().secondaryText)
            .fontWeight(FontWeight.Medium)
          Text('在「音乐库」导入本地音频后会显示在这里')
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ top: SPACE_SM.compact })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.songs, (song: SongItem, index: number) => {
            ListItem() {
              SongRow({
              song: song,
              playing: false,
              showQuality: true,
              coverSize: 48,
              titleFontSize: 15,
              rowHeight: 64,
              leftPadding: 16,
              showRemove: true,
              animateEntry: false,
              menuItems: [],
              onPlay: () => {},
              onRemove: () => {
                this.confirmDelete(song);
              }
            })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColors().bg)
  }
}

/**
 * 重复歌曲清理体：从 DuplicateSongs.ets 抽出供 sheet 复用。
 */
@Component
export struct DuplicateSongsBody {
  store: MusicStore = MusicStore.getInstance();
  onBack: () => void = () => {};
  /** sheet 内嵌时由 Settings 传 false 跳过自身表头，避免与 Settings 标题栏重复。 */
  showHeader: boolean = true;
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') coverRefreshToken: number = 0;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @State groups: DuplicateGroup[] = [];
  @State backScale: number = 1.0;
  @State itemScales: number[] = [];

  aboutToAppear(): void {
    this.refresh();
  }

  private refresh(): void {
    this.groups = DuplicateDetector.findDuplicates(this.store.songs);
    this.itemScales = this.groups.map((_: DuplicateGroup, i: number) => this.itemScales[i] ?? 1.0);
  }

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
      Row() {
        Text(group.key)
          .fontSize(TYPE_SM.headline.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColors().primaryText)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${group.songs.length} 个文件`)
          .fontSize(TYPE_SM.caption1.size)
          .fontColor(this.getThemeColors().accent)
          .backgroundColor(semanticOf(this.isDark).fillAccentSoft)
          .borderRadius(12)
          .padding({ left: SPACE_SM.compact, right: SPACE_SM.compact, top: SPACE_SM.tight, bottom: SPACE_SM.tight })
      }
      .width('100%')
      .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: SPACE_SM.cozy, bottom: SPACE_SM.compact })

      ForEach(group.songs, (song: SongItem, i: number) => {
        Row() {
          Stack() {
            CoverImageView({ src: song.src, coverSize: 40, coverRadius: 8 })
          }
          Column() {
            Text(song.title)
              .fontSize(TYPE_SM.subhead.size)
              .fontColor(this.getThemeColors().primaryText)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(song.singer)
              .fontSize(TYPE_SM.caption1.size)
              .fontColor(this.getThemeColors().secondaryText)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: SPACE_SM.cozy })
          if (i === 0) {
            Text('保留')
              .fontSize(TYPE_SM.caption1.size)
              .fontColor(this.getThemeColors().secondaryText)
              .backgroundColor(this.getThemeColors().secondaryBg)
              .borderRadius(12)
              .padding({ left: SPACE_SM.cozy, right: SPACE_SM.cozy, top: SPACE_SM.tight, bottom: SPACE_SM.tight })
          } else {
            Text('移除')
              .fontSize(TYPE_SM.footnote.size)
              .fontColor(this.getThemeColors().accent)
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                this.removeOne(song);
              })
          }
        }
        .width('100%')
        .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: SPACE_SM.compact, bottom: SPACE_SM.compact })
      }, (song: SongItem) => 'dup_' + song.id.toString())
    }
    .width('100%')
    .margin({ left: SPACE_SM.compact, right: SPACE_SM.compact, bottom: SPACE_SM.cozy })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(16)
  }

  build() {
    Column() {
      if (this.showHeader) {
        Row() {
          Image($r('app.media.ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .onClick(() => this.onBack())
          Text('重复歌曲')
            .fontSize(TYPE_SM.title2.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: SPACE_SM.cozy })
            .layoutWeight(1)
          if (this.duplicateCount() > 0) {
            Text('清理全部')
              .fontSize(TYPE_SM.subhead.size)
              .fontColor(this.getThemeColors().accent)
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                this.removeAllDuplicates();
              })
          }
        }
        .width('100%')
        .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: this.topHeight + 12, bottom: SPACE_SM.cozy })
      }

      if (this.groups.length === 0) {
        Column() {
          Image($r('app.media.ic_public_view_list'))
            .width(64)
            .height(64)
            .fillColor(this.getThemeColors().secondaryText)
            .margin({ bottom: SPACE_SM.base })
          Text('没有发现重复歌曲')
            .fontSize(TYPE_SM.headline.size)
            .fontColor(this.getThemeColors().secondaryText)
            .fontWeight(FontWeight.Medium)
          Text('基于标题与歌手相似度比对，跨歌手同名不会被误判')
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ top: SPACE_SM.compact })
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
  }
}

/**
 * 我的听歌报告体：从 Wrapped.ets 抽出供 sheet 复用。
 * 行为简化：sheet 内不再 push 玩家（保留点击 toast 提示），主导航栈独立保留完整 Wrapped 体验。
 */
@Component
export struct WrappedBody {
  store: MusicStore = MusicStore.getInstance();
  onBack: () => void = () => {};
  /** sheet 内嵌时由 Settings 传 false 跳过自身表头，避免与 Settings 标题栏重复。 */
  showHeader: boolean = true;
  @StorageProp('isDark') isDark: boolean = false;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @State totalPlays: number = 0;
  @State totalMs: number = 0;
  @State topSongs: SongItem[] = [];
  @State yearStats: YearStat[] = [];
  @State hasData: boolean = false;

  aboutToAppear(): void {
    const summary = this.store.getStatsSummary();
    this.totalPlays = summary.totalPlays;
    this.totalMs = summary.totalMs;
    this.topSongs = summary.topSongs;
    this.yearStats = this.computeYearStats();
    this.hasData = this.totalPlays > 0 && this.store.songs.length > 0;
  }

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
        .fontSize(TYPE_SM.footnote.size)
        .fontColor(this.getThemeColors().accent)
        .fontWeight(FontWeight.Medium)
        .letterSpacing(1)
        .margin({ bottom: SPACE_SM.cozy })
      Text(`${this.totalPlays}`)
        .fontSize(56)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
      Text('次播放')
        .fontSize(TYPE_SM.body.size)
        .fontColor(this.getThemeColors().secondaryText)
        .margin({ top: SPACE_SM.hair, bottom: SPACE_SM.roomy })
      Row() {
        Column() {
          Text('总收听时长')
            .fontSize(TYPE_SM.caption1.size)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ bottom: SPACE_SM.tight })
          Text(this.formatDuration(this.totalMs))
            .fontSize(TYPE_SM.title3.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
        }
        .layoutWeight(1)
        Column() {
          Text('歌曲总数')
            .fontSize(TYPE_SM.caption1.size)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ bottom: SPACE_SM.tight })
          Text(`${this.store.songs.length}`)
            .fontSize(TYPE_SM.title3.size)
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
    .borderRadius(24)
    .margin({ left: SPACE_SM.compact, right: SPACE_SM.compact, bottom: SPACE_SM.base })
  }

  @Builder
  buildTopSongs() {
    Column() {
      Text('最常播放')
        .fontSize(TYPE_SM.title3.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .width('100%')
        .padding({ left: SPACE_SM.cozy, bottom: SPACE_SM.cozy })
      ForEach(this.topSongs, (song: SongItem, index: number) => {
        Row() {
          Text(`${index + 1}`)
            .fontSize(TYPE_SM.body.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(index < 3 ? this.getThemeColors().accent : this.getThemeColors().secondaryText)
            .width(28)
            .textAlign(TextAlign.Center)
          Stack() {
            CoverImageView({ src: song.src, coverSize: 44, coverRadius: 8 })
          }
          Column() {
            Text(song.title)
              .fontSize(TYPE_SM.body.size)
              .fontColor(this.getThemeColors().primaryText)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(song.singer)
              .fontSize(TYPE_SM.caption1.size)
              .fontColor(this.getThemeColors().secondaryText)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: SPACE_SM.cozy })
          Text(`${this.store.getPlayCount(song.id)} 次`)
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.getThemeColors().secondaryText)
        }
        .width('100%')
        .height(58)
        .padding({ left: SPACE_SM.cozy, right: SPACE_SM.base })
        .backgroundColor(this.getThemeColors().cardBg)
        .borderRadius(12)
        .margin({ left: SPACE_SM.compact, right: SPACE_SM.compact, bottom: SPACE_SM.compact })
      }, (song: SongItem) => 'top_' + song.id.toString())
    }
    .margin({ bottom: SPACE_SM.base })
  }

  @Builder
  buildYearChart() {
    Column() {
      Text('按发行年份')
        .fontSize(TYPE_SM.title3.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .width('100%')
        .padding({ left: SPACE_SM.cozy, bottom: SPACE_SM.cozy })
      ForEach(this.yearStats, (y: YearStat) => {
        Row() {
          Text(y.year)
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.getThemeColors().secondaryText)
            .width(64)
          Stack() {
            Row()
              .width(`${Math.max(8, (y.plays / this.maxYearPlays()) * 100)}%`)
              .height(14)
              .backgroundColor(this.getThemeColors().accent)
              .borderRadius(7)
          }
          .width('100%')
          .height(14)
          .backgroundColor(this.getThemeColors().secondaryBg)
          .borderRadius(7)
          .margin({ left: SPACE_SM.compact })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: SPACE_SM.cozy })
      }, (y: YearStat) => 'year_' + y.year)
    }
    .width('100%')
    .padding({ top: SPACE_SM.base, left: SPACE_SM.base, right: SPACE_SM.base, bottom: SPACE_SM.base })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(24)
    .margin({ left: SPACE_SM.compact, right: SPACE_SM.compact, bottom: SPACE_SM.base })
  }

  build() {
    Column() {
      if (this.showHeader) {
        SubPageHeader({ title: '我的听歌报告', onBack: () => this.onBack() })
      }

      if (!this.hasData) {
        Column() {
          Image($r('app.media.ic_public_music_public_filled'))
            .width(64)
            .height(64)
            .fillColor(this.getThemeColors().secondaryText)
            .margin({ bottom: SPACE_SM.base })
          Text('还没有足够的数据')
            .fontSize(TYPE_SM.headline.size)
            .fontColor(this.getThemeColors().secondaryText)
            .fontWeight(FontWeight.Medium)
          Text('多听几首歌，这里会生成你的听歌报告')
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ top: SPACE_SM.compact })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            this.buildHero()
            this.buildTopSongs()
            if (this.yearStats.length > 0) {
              this.buildYearChart()
            }
            Text('数据仅在本地统计，不上传任何服务器')
              .fontSize(TYPE_SM.caption1.size)
              .fontColor(this.getThemeColors().secondaryText)
              .margin({ top: SPACE_SM.compact, bottom: SPACE_SM.loose })
          }
          .width('100%')
          .padding({ bottom: SPACE_SM.loose })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColors().bg)
  }
}

/**
 * 隐私政策体：从 PrivacyPolicy.ets 抽出供 sheet 复用。
 * 仅做静态排版——sheet 内的 stack-overflow 安全（不再注册 pathStack）。
 */
@Component
export struct PrivacyPolicyBody {
  onBack: () => void = () => {};
  /** sheet 内嵌时由 Settings/About 传 false 跳过自身表头，避免与外层标题栏重复。 */
  showHeader: boolean = true;
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @Builder
  buildSection(title: string, body: string) {
    Column() {
      Text(title)
        .fontSize(TYPE_SM.title3.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .width('100%')
        .margin({ bottom: SPACE_SM.compact })
      Text(body)
        .fontSize(TYPE_SM.subhead.size)
        .fontColor(this.getThemeColors().secondaryText)
        .width('100%')
        .lineHeight(22)
    }
    .width('100%')
    .margin({ bottom: SPACE_SM.loose })
  }

  build() {
    Column() {
      if (this.showHeader) {
        SubPageHeader({ title: '隐私政策', onBack: () => this.onBack() })
      }

      Scroll() {
        Column() {
          this.buildSection(
            '概述',
            'Lumio Music 是一款纯离线本地音乐播放器。你的歌曲、收藏、歌单与设置全部保存在设备本地，不提供云端服务、不要求注册账号、不集成任何第三方 SDK。除你主动触发的局域网投播与第三方网页跳转外，应用不会向任何外部服务器传输你的数据。'
          )
          this.buildSection(
            '我们收集的信息',
            '我们不收集任何个人身份信息。你看到的「曲库」仅由你主动导入的本地音频文件解析而来，应用仅读取并展示其元数据：曲名、歌手、专辑、时长。收藏、歌单、播放与主题设置等均由你的本地操作产生，仅保存在本机，我们不会采集你的位置、设备标识符、账号或浏览行为等任何个人信息。'
          )
          this.buildSection(
            '信息存储位置',
            '上述所有数据均存储在设备本地的应用沙箱目录（Preferences 与文件目录）中，与其他应用隔离，仅本应用可访问，不会上传到任何服务器，也不会离开你的设备。卸载应用后，本地沙箱数据会随之删除。'
          )
          this.buildSection(
            '权限说明',
            '本应用仅申请以下权限：\n' +
            '• 后台运行（KEEP_BACKGROUND_RUNNING）：用于锁屏或离开应用后继续播放音乐。\n' +
            '• 网络访问（INTERNET）：仅用于（1）将本地音频经局域网投送到你主动选择的设备；（2）点击「开发者主页」等入口时调用系统浏览器打开第三方网页 a703201sworld.top。我们不会用它上传你的音乐或个人数据。'
          )
          this.buildSection(
            '投播（局域网）传输',
            '投播通过系统 AVSessionKit 的 AVCastController，将你设备上正在播放的本地音频经局域网（Wi-Fi）传输到你主动选择的设备（如智能音箱 / 电视）。传输仅发生在你的局域网内，不经过云端，且仅在你主动点击投送并选定设备时才会发起。'
          )
          this.buildSection(
            '第三方外链',
            '在「设置 - 关于开发者」等入口，本应用提供跳转链接 https://www.a703201sworld.top/resume/（开发者主页）。点击时仅由系统浏览器打开该网页，应用不嵌入也不向其传输你的数据。该网页由第三方运营，其隐私实践由该网站自行负责。'
          )
          this.buildSection(
            '日志与脱敏',
            '我们已对日志进行整改：原先可能写入系统日志的媒体文件路径、歌名等敏感信息，已改用 Logger 的 *Private 接口脱敏，确保日志中不会出现可定位到你文件的路径或可识别的歌名，也不记录任何个人信息。'
          )
          this.buildSection(
            '我们的承诺',
            '我们不做以下事情：无云端同步 / 存储；不向任何第三方共享、出售或传输你的数据；不集成任何会收集信息的第三方 SDK；不展示广告；不进行埋点、数据统计或行为分析；不要求注册账号，不收集个人身份信息。'
          )
          this.buildSection(
            '你的权利与联系方式',
            '你完全掌控自己的本地数据：可在「设置」中清除缓存、清除听歌统计、关闭相关功能；卸载应用即可删除全部本地数据。\n' +
            '如有疑问或需行使相关权利，请联系：\n' +
            '主体 / 开发者名称：何宇翔\n' +
            '联系邮箱：Lumio_a7032@qq.com'
          )
        }
        .width('100%')
        .padding({ left: SPACE_SM.base, right: SPACE_SM.base, bottom: SPACE_SM.block })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColors().bg)
  }
}
