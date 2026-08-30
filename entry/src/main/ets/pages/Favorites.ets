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

  @Builder
  buildSongMenu(song: SongItem) {
    Column() {
      Row() {
        Image($r('app.media.ic_hos_play'))
          .width(18)
          .fillColor(this.getThemeColors().primaryText)
          .margin({ right: 12 })
        Text('播放')
          .fontSize(14)
          .fontColor(this.getThemeColors().primaryText)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.playSong(song);
      })

      Divider().color(this.getThemeColors().separator).strokeWidth(0.5)

      Row() {
        Image($r('app.media.ic_hos_collect'))
          .width(18)
          .fillColor(this.getThemeColors().primaryText)
          .margin({ right: 12 })
        Text('取消收藏')
          .fontSize(14)
          .fontColor(this.getThemeColors().primaryText)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.toggleFavoriteSong(song);
      })

      Divider().color(this.getThemeColors().separator).strokeWidth(0.5)

      Row() {
        Image($r('app.media.ic_hos_add'))
          .width(18)
          .fillColor(this.getThemeColors().primaryText)
          .margin({ right: 12 })
        Text('添加到歌单')
          .fontSize(14)
          .fontColor(this.getThemeColors().primaryText)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.openAddToPlaylist(song);
      })

      Divider().color(this.getThemeColors().separator).strokeWidth(0.5)

      Row() {
        Image($r('app.media.ic_hos_detail'))
          .width(18)
          .fillColor(this.getThemeColors().primaryText)
          .margin({ right: 12 })
        Text('详细')
          .fontSize(14)
          .fontColor(this.getThemeColors().primaryText)
      }
      .width('100%')
      .height(44)
      .padding({ left: 16, right: 16 })
      .onClick(() => {
        this.openSongDetail(song);
      })
    }
    .width(176)
    .backgroundColor(this.getThemeColors().bg)
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
  }

  @Builder
  buildSongItem(song: SongItem, index: number) {
    Row() {
      // Index number
      Text(`${index + 1}`)
        .fontSize(13)
        .fontColor(this.playingIndex === song.id ? '#FA2759' : this.getThemeColors().secondaryText)
        .width(28)
        .textAlign(TextAlign.Center)

      Stack() {
        CoverImageView({ src: song.src, coverSize: 48, coverRadius: this.playingIndex === song.id ? 24 : 8 })
      }

      Column() {
        Row() {
          Text(song.title)
            .fontSize(15)
            .fontColor(this.playingIndex === song.id ? '#FA2759' : this.getThemeColors().primaryText)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .animation({ duration: 200, curve: Curve.EaseOut })

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

      // Favorite icon with pulse
      Image($r('app.media.ic_favorite'))
        .width(22)
        .height(22)
        .fillColor('#FA2759')
        .scale({ x: this.favScales[index] ?? 1.0, y: this.favScales[index] ?? 1.0 })
        .animation({ duration: 200, curve: Curve.EaseOut })
    }
    .width('100%')
    .height(64)
    .padding({ left: 8, right: 16 })
    .backgroundColor(this.playingIndex === song.id ? 'rgba(250, 39, 89, 0.05)' : this.getThemeColors().cardBg)
    .borderRadius(12)
    .margin({ left: 8, right: 8, bottom: 8 })
    .scale({ x: this.itemScales[index] ?? 1.0, y: this.itemScales[index] ?? 1.0 })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 30 })))
    .animation({ duration: 300, curve: Curve.EaseOut, delay: this.entryDelay(index) })
    .onClick(() => {
      const globalIndex = this.store.songs.findIndex(s => s.id === song.id);
      if (globalIndex >= 0) {
        this.store.currentIndex = globalIndex;
        AudioRendererController.getInstance().playFromList(this.store.songs, globalIndex);
      }
      this.pathStack.pushPathByName('PlayerPage', null);
    })
    .bindContextMenu(this.buildSongMenu(song), ResponseType.LongPress)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        let scales = [...this.itemScales];
        scales[index] = 0.96;
        this.itemScales = scales;
        // Pulse the heart icon
        let fScales = [...this.favScales];
        fScales[index] = 1.3;
        this.favScales = fScales;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        let scales = [...this.itemScales];
        scales[index] = 1.0;
        this.itemScales = scales;
        let fScales = [...this.favScales];
        fScales[index] = 1.0;
        this.favScales = fScales;
      }
    })
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

          Text('我的收藏')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: 12 })
            .layoutWeight(1)

          // Count badge
          Text(`${this.favoriteSongs.length} 首`)
            .fontSize(13)
            .fontColor('#FA2759')
            .backgroundColor('rgba(250, 39, 89, 0.1)')
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 16 })

        if (this.favoriteSongs.length === 0) {
          Column() {
            Image($r('app.media.ic_favorite'))
              .width(72)
              .height(72)
              .fillColor(this.getThemeColors().secondaryText)
              .margin({ bottom: 16 })
              .scale({ x: this.emptyIconScale, y: this.emptyIconScale })
              .animation({ duration: 2000, curve: Curve.EaseInOut })

            Text('暂无收藏歌曲')
              .fontSize(16)
              .fontColor(this.getThemeColors().secondaryText)
              .fontWeight(FontWeight.Medium)

            Text('在播放页面点击收藏按钮添加')
              .fontSize(13)
              .fontColor('#636366')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.favoriteSongs, (song: SongItem, index: number) => {
              ListItem() {
                this.buildSongItem(song, index)
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
