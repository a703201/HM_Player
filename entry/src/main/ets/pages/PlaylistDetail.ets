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

import { SongItem, Playlist } from '../models/music';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { MusicStore } from '../services/MusicStore';
import { AudioRendererController } from '../utils/AudioRendererController';
import { Logger } from '../utils/Logger';
import { CoverImageView } from '../components/CoverImageView';
import { QualityBadge } from '../components/QualityBadge';
import { SongDetailSheet } from '../components/SongDetailSheet';
import { AddToPlaylistSheet } from '../components/AddToPlaylistSheet';
import { SettingsStore } from '../utils/SettingsStore';
import { semanticOf } from '../tokens/LumioColor';
import { SongRow, SongMenuEntry } from '../components/SongRow';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';

const TAG: string = 'PlaylistDetail';

@Builder
export function PlaylistDetailBuilder() {
  PlaylistDetail()
}

/**
 * 歌单详情页。
 * 入参：路由参数（context.pathInfo.param）传入歌单 id（string），页面内按 id 从 MusicStore 实时取，
 * 不缓存 Playlist 对象副本，避免与数据层状态漂移。
 */
@Component
struct PlaylistDetail {
  pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('bottomHeight') bottomHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('onCoverRefreshed') coverRefreshToken: number = 0;

  @State playlistId: string = '';
  @State playlistName: string = '';
  @State songs: SongItem[] = [];
  @State itemScales: number[] = [];
  @State backScale: number = 1.0;
  @State playAllScale: number = 1.0;
  @State selectedSong: SongItem | undefined = undefined;
  @State sheetOpen: boolean = false;
  @State sheetKind: 'detail' | 'add' | 'picker' = 'detail';

  // 添加歌曲面板
  @State candidates: SongItem[] = [];
  @State selectedIds: number[] = [];

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  onCoverRefreshed(): void {
    this.reload();
  }

  private reload(): void {
    const playlist: Playlist | undefined = this.store.getPlaylistById(this.playlistId);
    if (!playlist) {
      this.playlistName = '';
      this.songs = [];
      this.itemScales = [];
      return;
    }
    this.playlistName = playlist.name;
    // 按歌单内 songIds 的顺序展示，而不是本地库顺序
    const byId: Map<number, SongItem> = new Map<number, SongItem>();
    this.store.songs.forEach((s: SongItem) => byId.set(s.id, s));
    const ordered: SongItem[] = [];
    playlist.songIds.forEach((id: number) => {
      const hit: SongItem | undefined = byId.get(id);
      if (hit) {
        ordered.push(hit);
      }
    });
    this.songs = ordered;
    this.itemScales = ordered.map(() => 1.0);
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (e) {
      Logger.error(TAG, 'toast failed');
    }
  }

  private getCoverSrc(song: SongItem): string {
    return song.src;
  }

  /** 列表入场错峰延迟：降低动态效果开启时取消错峰（R-18/F-13）。 */
  private entryDelay(index: number): number {
    return SettingsStore.getInstance().getReduceMotion() ? 0 : index * 40;
  }

  private playAll(): void {
    if (this.songs.length === 0) {
      this.toast('歌单还没有歌曲');
      return;
    }
    AudioRendererController.getInstance().setQueue(this.songs, 0, true);
    this.pathStack.pushPathByName('PlayerPage', null);
  }

  private playAt(index: number): void {
    if (index < 0 || index >= this.songs.length) {
      return;
    }
    AudioRendererController.getInstance().setQueue(this.songs, index, true);
    this.pathStack.pushPathByName('PlayerPage', null);
  }

  private confirmRemove(song: SongItem): void {
    const songId: number = song.id;
    const title: string = song.title;
    this.getUIContext().showAlertDialog({
      title: '移出歌单',
      message: `将「${title}」移出本歌单？歌曲仍保留在本地库。`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '移出',
        action: () => {
          this.store.removeSongFromPlaylist(this.playlistId, songId);
          this.reload();
          this.toast('已移出歌单');
        }
      }
    });
  }

  private toggleFavoriteSong(song: SongItem): void {
    const isFav: boolean = this.store.isFavorite(song.id);
    this.store.toggleFavorite(song.id);
    try {
      this.getUIContext().getPromptAction().showToast({
        message: isFav ? '已取消收藏' : '已收藏'
      });
    } catch (e) {
      Logger.error('PlaylistDetail', 'showToast failed');
    }
  }

  private openAddToPlaylist(song: SongItem): void {
    this.selectedSong = song;
    this.sheetKind = 'add';
    this.sheetOpen = true;
  }

  private openSongDetail(song: SongItem): void {
    this.selectedSong = song;
    this.sheetKind = 'detail';
    this.sheetOpen = true;
  }

    private buildMenuItems(song: SongItem, index: number): SongMenuEntry[] {
    return [
      { text: '播放', icon: $r('app.media.ic_hos_play'), action: () => { this.playAt(index); } },
      { text: this.store.isFavorite(song.id) ? '取消收藏' : '收藏', icon: $r('app.media.ic_hos_collect'), action: () => { this.toggleFavoriteSong(song); } },
      { text: '添加到歌单', icon: $r('app.media.ic_hos_add'), action: () => { this.openAddToPlaylist(song); } },
      { text: '详细', icon: $r('app.media.ic_hos_detail'), action: () => { this.openSongDetail(song); } }
    ];
  }


  /**
   * 打开「添加歌曲」面板：候选集为本地库中尚未加入本歌单的歌曲。
   */
  private openPicker(): void {
    const playlist: Playlist | undefined = this.store.getPlaylistById(this.playlistId);
    if (!playlist) {
      return;
    }
    const existing: Set<number> = new Set<number>(playlist.songIds);
    this.candidates = this.store.songs.filter((s: SongItem) => !existing.has(s.id));
    this.selectedIds = [];
    if (this.candidates.length === 0) {
      this.toast('本地库的歌曲都已在歌单中');
      return;
    }
    this.sheetKind = 'picker';
    this.sheetOpen = true;
  }

  /**
   * 拖拽重排落点处理（FR-24）。
   * 采用 ArkUI 官方 ForEach.onMove（API 12+）：框架内建长按拖拽手势、占位动画与落点计算，
   * 回调直接给出 from / to 语义索引，无需手工处理 onDragStart / onDrop / extraParams。
   * 这里只做数据层持久化重排，UI 由 reload() 依据 MusicStore 的新顺序重建，保证单一数据源。
   */
  private handleMove(from: number, to: number): void {
    if (from === to) {
      return;
    }
    this.store.reorderPlaylistSongs(this.playlistId, from, to);
    this.reload();
  }

  private toggleSelect(songId: number): void {
    if (this.selectedIds.includes(songId)) {
      this.selectedIds = this.selectedIds.filter((id: number) => id !== songId);
    } else {
      this.selectedIds = [...this.selectedIds, songId];
    }
  }

  private commitAdd(): void {
    if (this.selectedIds.length === 0) {
      this.toast('请先选择歌曲');
      return;
    }
    const added: number = this.store.addSongsToPlaylist(this.playlistId, this.selectedIds);
    this.sheetOpen = false;
    this.reload();
    this.toast(`已添加 ${added} 首`);
  }

  @Builder
  songPickerBuilder() {
    Column() {
      Row() {
        Text('添加歌曲')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColors().primaryText)
          .layoutWeight(1)

        Text(`已选 ${this.selectedIds.length}`)
          .fontSize(13)
          .fontColor(this.getThemeColors().secondaryText)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      List() {
        ForEach(this.candidates, (song: SongItem) => {
          ListItem() {
            Row() {
              CoverImageView({ src: this.getCoverSrc(song), coverSize: 40, coverRadius: 8 })

              Column() {
                Text(song.title)
                  .fontSize(15)
                  .fontColor(this.getThemeColors().primaryText)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(song.singer)
                  .fontSize(12)
                  .fontColor(this.getThemeColors().secondaryText)
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 12, right: 8 })

              Checkbox()
                .select(this.selectedIds.includes(song.id))
                .selectedColor(this.getThemeColors().accent)
                .hitTestBehavior(HitTestMode.None) // P1-8：勾选框只做视觉呈现，统一由父 Row 点击驱动，避免事件冒泡双触发
            }
            .width('100%')
            .height(60)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.toggleSelect(song.id);
            })
          }
        }, (song: SongItem): string => `${song.id}`)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(42)
          .fontSize(15)
          .fontColor(this.getThemeColors().secondaryText)
          .backgroundColor(this.getThemeColors().secondaryBg)
          .borderRadius(21)
        .onClick(() => {
          this.sheetOpen = false;
        })

        Button('添加')
          .layoutWeight(1)
          .height(42)
          .fontSize(15)
          .fontColor(semanticOf(this.isDark).onAccent)
          .backgroundColor(this.getThemeColors().accent)
          .borderRadius(21)
          .margin({ left: 12 })
          .onClick(() => {
            this.commitAdd();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColors().bg)
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

          Text(this.playlistName.length > 0 ? this.playlistName : '歌单')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: 12 })
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`${this.songs.length} 首`)
            .fontSize(13)
            .fontColor(this.getThemeColors().accent)
            .backgroundColor(semanticOf(this.isDark).fillAccentSoft)
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 12 })

        // 操作区：播放全部 / 添加歌曲
        Row() {
          Row() {
            Image($r('app.media.ic_play_all'))
              .width(18)
              .height(18)
              .fillColor(semanticOf(this.isDark).onAccent)
            Text('播放全部')
              .fontSize(14)
              .fontColor(semanticOf(this.isDark).onAccent)
              .margin({ left: 6 })
          }
          .layoutWeight(1)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.getThemeColors().accent)
          .borderRadius(24)
          .scale({ x: this.playAllScale, y: this.playAllScale })
          .animation({ duration: 150, curve: LumioTheme.curve(SpringKind.Crisp) })
          .onClick(() => {
            this.playAll();
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.playAllScale = 0.97;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.playAllScale = 1.0;
            }
          })

          Row() {
            Text('+')
              .fontSize(18)
              .fontColor(this.getThemeColors().primaryText)
            Text('添加歌曲')
              .fontSize(14)
              .fontColor(this.getThemeColors().primaryText)
              .margin({ left: 6 })
          }
          .layoutWeight(1)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.getThemeColors().cardBg)
          .borderRadius(24)
          .margin({ left: 12 })
          .onClick(() => {
            this.openPicker();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })

        if (this.songs.length > 0) {
          Text('长按歌曲可拖动排序')
            .fontSize(12)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ left: 16, bottom: 4 })
        }

        if (this.songs.length === 0) {
          Column() {
            Image($r('app.media.ic_song_list'))
              .width(64)
              .height(64)
              .fillColor(this.getThemeColors().secondaryText)
              .margin({ bottom: 16 })

            Text('歌单还没有歌曲')
              .fontSize(16)
              .fontColor(this.getThemeColors().secondaryText)
              .fontWeight(FontWeight.Medium)

            Text('点击「添加歌曲」从本地库挑选')
              .fontSize(13)
              .fontColor(semanticOf(this.isDark).labelSecondary)
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.songs, (song: SongItem, index: number) => {
              ListItem() {
                SongRow({
              song: song,
              index: index,
              playing: false,
              showIndex: true,
              showQuality: true,
              showRemove: true,
              coverSize: 48,
              titleFontSize: 15,
              rowHeight: 64,
              leftPadding: 8,
              animateEntry: true,
              entryDelayMs: this.entryDelay(index),
              menuItems: this.buildMenuItems(song, index),
              onPlay: () => {
                this.playAt(index);
              },
              onRemove: () => {
                this.confirmRemove(song);
              }
            })
              }
            }, (song: SongItem): string => `${song.id}`)
              .onMove((from: number, to: number): void => {
                this.handleMove(from, to);
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
      const param: Object = context.pathInfo.param as Object;
      if (typeof param === 'string') {
        this.playlistId = param as string;
      } else {
        Logger.warn(TAG, 'PlaylistDetail: invalid route param, expected playlist id string');
      }
      this.reload();
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
    } else if (this.sheetKind === 'picker') {
      this.songPickerBuilder()
    }
  }
}
