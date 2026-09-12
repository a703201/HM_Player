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
import { QualityBadge } from '../components/QualityBadge';
import { SongDetailSheet } from '../components/SongDetailSheet';
import { AddToPlaylistSheet } from '../components/AddToPlaylistSheet';
import { SettingsStore } from '../utils/SettingsStore';
import { Logger } from '../utils/Logger';
import { semanticOf } from '../tokens/LumioColor';
import { SongRow, SongMenuEntry } from '../components/SongRow';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';
import { TYPE_SM, SPACE_SM } from '../tokens/LumioScale';

@Builder
export function FavoritesBuilder() {
  Favorites()
}

@Component
struct Favorites {
  pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('bottomHeight') bottomHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('onCoverRefreshed') coverRefreshToken: number = 0;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @State itemScales: number[] = [];
  @State favoriteSongs: SongItem[] = [];
  @State favScales: number[] = [];
  @State backScale: number = 1.0;
  @State emptyIconScale: number = 1.0;
  @State playingIndex: number = -1;
  @State selectedSong: SongItem | undefined = undefined;
  @State sheetOpen: boolean = false;
  @State sheetKind: 'detail' | 'add' = 'detail';

  aboutToAppear(): void {
    this.favoriteSongs = this.store.getFavoriteSongs();
    this.itemScales = this.favoriteSongs.map(() => 1.0);
    this.favScales = this.favoriteSongs.map(() => 1.0);
    setInterval(() => {
      // R-18/F-13：降低动态效果开启时不做空态图标呼吸
      if (this.store.getFavoriteSongs().length === 0 && !SettingsStore.getInstance().getReduceMotion()) {
        this.emptyIconScale = this.emptyIconScale === 1.0 ? 1.08 : 1.0;
      }
      this.playingIndex = this.store.isPlaying ? this.store.currentIndex : -1;
    }, 500);
  }

  onCoverRefreshed() {
    this.favoriteSongs = [...this.store.getFavoriteSongs()];
    this.itemScales = this.favoriteSongs.map(() => 1.0);
    this.favScales = this.favoriteSongs.map(() => 1.0);
  }

  /** 列表入场错峰延迟：降低动态效果开启时取消错峰（R-18/F-13）。 */
  private entryDelay(index: number): number {
    return SettingsStore.getInstance().getReduceMotion() ? 0 : index * 50;
  }

  playSong(song: SongItem): void {
    const globalIndex = this.store.songs.findIndex(s => s.id === song.id);
    if (globalIndex >= 0) {
      this.store.currentIndex = globalIndex;
      AudioRendererController.getInstance().playFromList(this.store.songs, globalIndex);
    }
    this.pathStack.pushPathByName('PlayerPage', null);
  }

  toggleFavoriteSong(song: SongItem): void {
    this.store.toggleFavorite(song.id);
    try {
      this.getUIContext().getPromptAction().showToast({ message: '已取消收藏' });
    } catch (e) {
      Logger.error('Favorites', 'showToast failed');
    }
  }

  openAddToPlaylist(song: SongItem): void {
    this.selectedSong = song;
    this.sheetKind = 'add';
    this.sheetOpen = true;
  }

  openSongDetail(song: SongItem): void {
    this.selectedSong = song;
    this.sheetKind = 'detail';
    this.sheetOpen = true;
  }

    private buildMenuItems(song: SongItem): SongMenuEntry[] {
    return [
      { text: '播放', icon: $r('app.media.ic_lib_play'), action: () => { this.playSong(song); } },
      { text: '取消收藏', icon: $r('app.media.ic_public_collect'), action: () => { this.toggleFavoriteSong(song); } },
      { text: '添加到歌单', icon: $r('app.media.ic_public_add'), action: () => { this.openAddToPlaylist(song); } },
      { text: '详细', icon: $r('app.media.ic_public_detail'), action: () => { this.openSongDetail(song); } }
    ];
  }


  

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Image($r('app.media.ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .scale({ x: this.backScale, y: this.backScale })
            .animation({ duration: 150, curve: LumioTheme.curve(SpringKind.Crisp) })
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

          Text('我的收藏')
            .fontSize(TYPE_SM.title2.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: SPACE_SM.cozy })
            .layoutWeight(1)

          // Count badge
          Text(`${this.favoriteSongs.length} 首`)
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.getThemeColors().accent)
            .backgroundColor(semanticOf(this.isDark).fillAccentSoft)
            .borderRadius(12)
            .padding({ left: SPACE_SM.cozy, right: SPACE_SM.cozy, top: SPACE_SM.tight, bottom: SPACE_SM.tight })
        }
        .width('100%')
        .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: this.topHeight + 12, bottom: SPACE_SM.base })

        if (this.favoriteSongs.length === 0) {
          Column() {
            Image($r('app.media.ic_public_favor_filled'))
              .width(72)
              .height(72)
              .fillColor(this.getThemeColors().secondaryText)
              .margin({ bottom: SPACE_SM.base })
              .scale({ x: this.emptyIconScale, y: this.emptyIconScale })
              .animation({ duration: 2000, curve: LumioTheme.curve(SpringKind.Crisp) })

            Text('暂无收藏歌曲')
              .fontSize(TYPE_SM.headline.size)
              .fontColor(this.getThemeColors().secondaryText)
              .fontWeight(FontWeight.Medium)

            Text('在播放页面点击收藏按钮添加')
              .fontSize(TYPE_SM.footnote.size)
              .fontColor(semanticOf(this.isDark).labelSecondary)
              .margin({ top: SPACE_SM.compact })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.favoriteSongs, (song: SongItem, index: number) => {
              ListItem() {
                SongRow({
              song: song,
              index: index,
              playing: this.playingIndex === song.id,
              playingColor: this.getThemeColors().accent,
              showIndex: true,
              showHeart: true,
              favorite: this.store.isFavorite(song.id),
              showQuality: true,
              circularCoverWhenPlaying: true,
              playingBg: semanticOf(this.isDark).fillAccentSubtle,
              coverSize: 48,
              titleFontSize: 15,
              rowHeight: 64,
              leftPadding: 8,
              animateEntry: true,
              entryDelayMs: this.entryDelay(index),
              menuItems: this.buildMenuItems(song),
              onPlay: () => {
        const globalIndex: number = this.store.songs.findIndex((s: SongItem): boolean => s.id === song.id);
        if (globalIndex >= 0) {
          this.store.currentIndex = globalIndex;
          AudioRendererController.getInstance().playFromList(this.store.songs, globalIndex);
        }
        this.pathStack.pushPathByName('PlayerPage', null);
      }
            })
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .padding({ bottom: this.bottomHeight + 16 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .bindSheet($$this.sheetOpen, this.sheetContent(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        dragBar: true,
        showClose: true,
        backgroundColor: this.getThemeColors().bg,
        preferType: SheetType.BOTTOM
      })
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .hideTitleBar(true)
  }

  @Builder
  sheetContent() {
    if (this.sheetKind === 'detail') {
      SongDetailSheet({ songId: this.selectedSong?.id ?? 0 })
    } else if (this.sheetKind === 'add') {
      AddToPlaylistSheet({
        songId: this.selectedSong?.id ?? 0,
        onClose: () => {
          this.sheetOpen = false;
        }
      })
    }
  }
}
