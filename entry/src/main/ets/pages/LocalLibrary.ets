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
import { curves } from '@kit.ArkUI';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';
import { AudioRendererController } from '../utils/AudioRendererController';
import { CoverCache } from '../utils/CoverCache';
import { AudioMetaReader } from '../utils/AudioMeta';
import { CoverImageView } from '../components/CoverImageView';
import { QualityBadge } from '../components/QualityBadge';
import { SongRow, SongMenuEntry } from '../components/SongRow';
import { SongDetailSheet } from '../components/SongDetailSheet';
import { AddToPlaylistSheet } from '../components/AddToPlaylistSheet';
import { picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { SettingsStore } from '../utils/SettingsStore';
import { sortSongs } from '../common/utils/SortUtil';
import { semanticOf } from '../tokens/LumioColor';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';
import { TYPE_SM, SPACE_SM } from '../tokens/LumioScale';

const PLAYER_COVER_ID: string = 'player_cover';

@Builder
export function LocalLibraryBuilder() {
  LocalLibrary()
}

@Component
export struct LocalLibrary {
  @Consume('navPathStack') pathStack: NavPathStack;
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('bottomHeight') bottomHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('onCoverRefreshed') coverRefreshToken: number = 0;
  // 响应式断点：sm 单列列表，md/lg（折叠屏/平板/2-in-1）两列网格
  @StorageProp('currentBreakpoint') breakpoint: string = 'sm';

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  @State searchText: string = '';
  @State filteredSongs: SongItem[] = [];
  @State sortMode: number = 0;
  @State isLoading: boolean = false;
  @State itemScales: number[] = [];
  @State importScale: number = 1.0;
  @State emptyIconScale: number = 1.0;
  @State playingIndex: number = -1;
  @State selectedSong: SongItem | undefined = undefined;
  @State sheetOpen: boolean = false;
  @State sheetKind: 'detail' | 'add' = 'detail';
  /** 错误消息（非空时页面展示错误态+重试按钮；覆盖导入失败/store加载失败） */
  @State errorMessage: string = '';
  private playingPulse: number = -1;

  aboutToAppear(): void {
    this.filteredSongs = sortSongs([...this.store.songs], this.sortMode, this.store.recentlyPlayed);
    this.itemScales = this.filteredSongs.map(() => 1.0);
    if (this.store.loadError) {
      this.errorMessage = '数据加载失败，请重试';
    }
    this.startEmptyPulse();
    this.startPlayingPulse();
  }

  aboutToDisappear(): void {
    if (this.playingPulse >= 0) {
      clearInterval(this.playingPulse);
    }
  }

  /** 重试加载数据（store 初始化失败或导入失败后点击重试） */
  async retryLoad(): Promise<void> {
    this.errorMessage = '';
    this.isLoading = true;
    try {
      const context: common.UIAbilityContext = AppStorage.get<common.UIAbilityContext>('context') as common.UIAbilityContext;
      await this.store.init(context);
      this.store.loadError = false;
      this.filteredSongs = sortSongs([...this.store.songs], this.sortMode, this.store.recentlyPlayed);
      this.itemScales = this.filteredSongs.map(() => 1.0);
      AudioRendererController.getInstance().reconcileWithLibrary(this.store.songs);
    } catch (e) {
      this.errorMessage = '重试失败，请检查存储权限';
    } finally {
      this.isLoading = false;
    }
  }

  startEmptyPulse(): void {
    // R-18/F-13：降低动态效果开启时不做空态呼吸动画
    if (SettingsStore.getInstance().getReduceMotion()) {
      return;
    }
    setInterval(() => {
      if (this.filteredSongs.length === 0 && !this.isLoading) {
        this.emptyIconScale = this.emptyIconScale === 1.0 ? 1.08 : 1.0;
      }
    }, 2000);
  }

  startPlayingPulse(): void {
    this.playingPulse = setInterval(() => {
      this.playingIndex = this.store.isPlaying ? this.store.currentIndex : -1;
    }, 500);
  }

  onSearchChange(text: string): void {
    this.searchText = text;
    if (text.trim() === '') {
      this.filteredSongs = [...this.store.songs];
    } else {
      this.filteredSongs = this.store.songs.filter(song =>
        song.title.includes(text) ||
        song.singer.includes(text)
      );
    }
    this.applyLibrarySort(this.sortMode);
  }

  // 原歌曲页的导入功能，已迁移至音乐库页
  async onPickMusic(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const documentOptions = new picker.DocumentSelectOptions();
      // 限定为常见音频后缀：仍可浏览目录，仅在目录中显示/可选中音频文件（flac/mp3/m4a/wav/ogg/ape/wma/aac 等）
      documentOptions.fileSuffixFilters = ['.flac', '.mp3', '.m4a', '.wav', '.ogg', '.ape', '.wma', '.aac', '.m4b', '.mp2', '.aiff', '.alac', '.opus'];
      const result: string[] = await documentPicker.select(documentOptions);
      if (result && result.length > 0) {
        this.isLoading = true;
        const context = AppStorage.get<common.UIAbilityContext>('context') as common.UIAbilityContext;
        const downloadDir = context.filesDir + '/download';
        try {
          if (!fs.accessSync(downloadDir)) {
            fs.mkdirSync(downloadDir);
          }
        } catch (e) {
          try { fs.mkdirSync(downloadDir); } catch (err) {}
        }
        const newSongs: SongItem[] = [];
        for (const uri of result) {
          const existingIndex = this.store.songs.findIndex(s => s.src === uri);
          if (existingIndex < 0) {
            const fileName = decodeURIComponent(uri.substring(uri.lastIndexOf('/') + 1));
            const fallbackTitle = fileName.includes('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
            const destPath = downloadDir + '/' + fileName;
            let srcPath: string = uri;
            try {
              const srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY);
              const destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
              fs.copyFileSync(srcFile.fd, destFile.fd);
              fs.closeSync(srcFile.fd);
              fs.closeSync(destFile.fd);
              srcPath = destPath;
            } catch (copyErr) {
              srcPath = uri;
            }
            const song = new SongItem();
            song.id = Math.abs(hashCode(srcPath));
            song.src = srcPath;
            song.folder = this.extractFolderName(uri);
            song.index = this.store.songs.length + newSongs.length;
            // 读取音频内嵌文本元数据：标题 / 艺术家 / 专辑 / 作者
            const meta = await AudioMetaReader.read(srcPath);
            if (meta) {
              song.title = (meta.title && meta.title.trim().length > 0) ? meta.title : fallbackTitle;
              song.singer = (meta.artist && meta.artist.trim().length > 0) ? meta.artist : '未知艺术家';
              song.album = meta.album ?? '';
              song.author = meta.author ?? '';
              song.year = meta.year ?? '';
              song.sampleRate = meta.sampleRate ?? 0;
              song.bitDepth = meta.bitDepth ?? 0;
              song.codec = meta.codec ?? '';
            } else {
              song.title = fallbackTitle;
              song.singer = '未知艺术家';
            }
            newSongs.push(song);
          }
        }
        if (newSongs.length > 0) {
          this.store.setSongs([...this.store.songs, ...newSongs]);
          AudioRendererController.getInstance().reconcileWithLibrary(this.store.songs);
          this.filteredSongs = sortSongs([...this.store.songs], this.sortMode, this.store.recentlyPlayed);
          this.itemScales = this.filteredSongs.map(() => 1.0);
          // 后台抽取新导入歌曲的内嵌封面，完成后刷新列表与全局 songList
          CoverCache.getInstance().preload(newSongs).then(() => {
            this.filteredSongs = [...this.store.songs];
            AppStorage.setOrCreate('songList', [...this.store.songs]);
            AppStorage.setOrCreate('coverRefreshToken', Date.now());
          }).catch((err: Error) => {
            Logger.error('LocalLibrary cover preload failed', err.message);
          });
          this.getUIContext().getPromptAction().showToast({ message: `已导入 ${newSongs.length} 首音乐` });
        } else {
          this.getUIContext().getPromptAction().showToast({ message: '没有新的音乐文件' });
        }
        this.isLoading = false;
      }
    } catch (err) {
      this.errorMessage = '导入失败：' + ((err as Error).message ?? '未知错误');
      Logger.error('Pick music failed');
      this.isLoading = false;
    }
  }

  /**
   * 从 picker URI 解析父目录名作为「来源文件夹」，用于按文件夹浏览本地音乐。
   * 例：file:///.../Music/周杰伦/七里香.mp3 → '周杰伦'。解析失败返回空串（归入「导入音乐」）。
   */
  private extractFolderName(uri: string): string {
    try {
      let path: string = uri;
      if (path.startsWith('file://')) {
        path = path.substring('file://'.length);
      }
      const q: number = path.indexOf('?');
      if (q >= 0) {
        path = path.substring(0, q);
      }
      const lastSlash: number = path.lastIndexOf('/');
      if (lastSlash <= 0) {
        return '';
      }
      const parentSlash: number = path.lastIndexOf('/', lastSlash - 1);
      if (parentSlash < 0) {
        return '';
      }
      return decodeURIComponent(path.substring(parentSlash + 1, lastSlash));
    } catch (e) {
      return '';
    }
  }

  // 一镜到底：进入播放页时与迷你播放条封面共享元素过渡
  playSong(song: SongItem): void {
    const index = this.store.songs.findIndex(s => s.id === song.id);
    if (index >= 0) {
      this.store.currentIndex = index;
      AudioRendererController.getInstance().playFromList(this.store.songs, index);
      this.getUIContext().animateTo(
        { curve: curves.interpolatingSpring(0, 1, 328, 36) },
        () => {
          this.pathStack.pushPathByName('PlayerPage', null);
        }
      );
    }
  }

  deleteSong(song: SongItem): void {
    this.store.removeSong(song.id);
    AudioRendererController.getInstance().reconcileWithLibrary(this.store.songs);
    this.filteredSongs = sortSongs([...this.store.songs], this.sortMode, this.store.recentlyPlayed);
    this.itemScales = this.filteredSongs.map(() => 1.0);
  }

  toggleFavoriteSong(song: SongItem): void {
    const isFav: boolean = this.store.isFavorite(song.id);
    this.store.toggleFavorite(song.id);
    try {
      this.getUIContext().getPromptAction().showToast({
        message: isFav ? '已取消收藏' : '已收藏'
      });
    } catch (e) {
      Logger.error('LocalLibrary', 'showToast failed');
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

  onCoverRefreshed() {
    const kw = this.searchText.trim();
    if (kw === '') {
      this.filteredSongs = [...this.store.songs];
    } else {
      this.filteredSongs = this.store.songs.filter(song =>
        song.title.includes(kw) || song.singer.includes(kw));
    }
    this.applyLibrarySort(this.sortMode);
  }

  /**
   * 曲库排序入口（B3）：与播放队列面板共用 common/utils/SortUtil.ets。
   * 排序作用于当前过滤结果（搜索后的列表），模式：0默认/1标题/2歌手/3最近/4随机/5专辑。
   */
  applyLibrarySort(mode: number): void {
    this.sortMode = mode;
    this.filteredSongs = sortSongs(this.filteredSongs, mode, this.store.recentlyPlayed);
    this.itemScales = this.filteredSongs.map(() => 1.0);
  }

  private librarySortLabel(mode: number): Resource {
    switch (mode) {
      case 1:
        return $r('app.string.sort_title');
      case 2:
        return $r('app.string.sort_artist');
      case 3:
        return $r('app.string.sort_recent');
      case 4:
        return $r('app.string.sort_random');
      case 5:
        return $r('app.string.sort_album');
      default:
        return $r('app.string.sort_default');
    }
  }

  /** 列表入场错峰延迟：降低动态效果开启时取消错峰（R-18/F-13）。 */
  private entryDelay(index: number): number {
    return SettingsStore.getInstance().getReduceMotion() ? 0 : index * 50;
  }

  @Builder
  librarySortBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach([0, 1, 2, 5, 3, 4], (mode: number) => {
          Text(this.librarySortLabel(mode))
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.sortMode === mode ? semanticOf(this.isDark).onAccent : this.getThemeColors().secondaryText)
            .backgroundColor(this.sortMode === mode ? this.getThemeColors().accent : this.getThemeColors().secondaryBg)
            .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: SPACE_SM.compact, bottom: SPACE_SM.compact })
            .borderRadius(16)
            .onClick(() => {
              this.applyLibrarySort(mode);
            })
        }, (mode: number) => 'lib_sort_' + mode.toString())
      }
      .padding({ left: SPACE_SM.base, right: SPACE_SM.base })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ bottom: SPACE_SM.cozy })
  }

  

    private buildMenuItems(song: SongItem): SongMenuEntry[] {
    return [
      { text: '播放', icon: $r('app.media.ic_hos_play'), action: () => { this.playSong(song); } },
      { text: this.store.isFavorite(song.id) ? '取消收藏' : '收藏', icon: $r('app.media.ic_hos_collect'), action: () => { this.toggleFavoriteSong(song); } },
      { text: '添加到歌单', icon: $r('app.media.ic_hos_add'), action: () => { this.openAddToPlaylist(song); } },
      { text: '详细', icon: $r('app.media.ic_hos_detail'), action: () => { this.openSongDetail(song); } },
      { text: '删除', icon: $r('app.media.ic_hos_delete'), action: () => { this.deleteSong(song); } }
    ];
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

  build() {
    Column() {
      // Header + 导入入口（原歌曲页导入功能已迁移至此）
      Row() {
        Text('音乐库')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColors().primaryText)
          .layoutWeight(1)
          .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: this.topHeight + 8, bottom: SPACE_SM.cozy })

        Row({ space: 4 }) {
          Image($r('app.media.ic_hm_download'))
            .width(16)
            .height(16)
            .fillColor(this.getThemeColors().accent)
          Text('导入')
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.getThemeColors().accent)
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: SPACE_SM.cozy, right: SPACE_SM.cozy, top: SPACE_SM.compact, bottom: SPACE_SM.compact })
        .backgroundColor(semanticOf(this.isDark).fillAccentSoft)
        .borderRadius(16)
        .margin({ right: SPACE_SM.base, top: this.topHeight + 8 })
        .scale({ x: this.importScale, y: this.importScale })
        .animation({ duration: 150, curve: LumioTheme.curve(SpringKind.Crisp) })
        .onClick(() => {
          this.onPickMusic();
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.importScale = 0.92;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.importScale = 1.0;
          }
        })
      }
      .width('100%')

      // Search bar
      Row() {
        Image($r('app.media.ic_hm_search'))
          .width(18)
          .height(18)
          .fillColor(this.getThemeColors().secondaryText)

        TextInput({ placeholder: '搜索歌曲、艺术家' })
          .placeholderColor(this.getThemeColors().secondaryText)
          .backgroundColor(Color.Transparent)
          .fontColor(this.getThemeColors().primaryText)
          .fontSize(TYPE_SM.body.size)
          .layoutWeight(1)
          .margin({ left: SPACE_SM.compact })
          .onChange((value: string) => {
            this.onSearchChange(value);
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: SPACE_SM.base, right: SPACE_SM.base })
      .backgroundColor(this.getThemeColors().cardBg)
      .borderRadius(22)
      .margin({ left: SPACE_SM.base, right: SPACE_SM.base, bottom: SPACE_SM.cozy })

      // Stats row
      Row() {
        Text(`共 ${this.filteredSongs.length} 首歌曲`)
          .fontSize(TYPE_SM.footnote.size)
          .fontColor(this.getThemeColors().secondaryText)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: SPACE_SM.base, right: SPACE_SM.base, bottom: SPACE_SM.cozy })

      // 曲库排序入口（B3）：仅在有歌曲时展示
      if (this.filteredSongs.length > 0 && this.errorMessage === '' && !this.isLoading) {
        this.librarySortBar()
      }

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color(this.getThemeColors().accent)
            .margin({ bottom: SPACE_SM.base })
          Text('正在导入...')
            .fontSize(TYPE_SM.subhead.size)
            .fontColor(this.getThemeColors().secondaryText)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage !== '') {
        Column() {
          Image($r('app.media.ic_hm_library'))
            .width(72)
            .height(72)
            .fillColor(this.getThemeColors().secondaryText)
            .margin({ bottom: SPACE_SM.base })
            .opacity(0.5)

          Text(this.errorMessage)
            .fontSize(TYPE_SM.body.size)
            .fontColor(this.getThemeColors().secondaryText)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .maxLines(3)
            .padding({ left: SPACE_SM.section, right: SPACE_SM.section })
            .margin({ bottom: SPACE_SM.roomy })

          Button('重试')
            .fontSize(TYPE_SM.subhead.size)
            .fontColor(semanticOf(this.isDark).onAccent)
            .backgroundColor(this.getThemeColors().accent)
            .borderRadius(24)
            .padding({ left: SPACE_SM.loose, right: SPACE_SM.loose, top: SPACE_SM.compact, bottom: SPACE_SM.compact })
            .onClick(() => {
              this.retryLoad();
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.filteredSongs.length === 0) {
        Column() {
          Image($r('app.media.ic_hm_library'))
            .width(72)
            .height(72)
            .fillColor(this.getThemeColors().secondaryText)
            .margin({ bottom: SPACE_SM.base })
            .scale({ x: this.emptyIconScale, y: this.emptyIconScale })
            .animation({ duration: 2000, curve: LumioTheme.curve(SpringKind.Crisp) })

          Text('音乐库还是空的')
            .fontSize(TYPE_SM.headline.size)
            .fontColor(this.getThemeColors().secondaryText)
            .fontWeight(FontWeight.Medium)

          Text('点击右上角"导入"添加本地音频')
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(this.getThemeColors().secondaryText)
            .margin({ top: SPACE_SM.compact })
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        if (this.breakpoint === 'sm') {
          List() {
            ForEach(this.filteredSongs, (song: SongItem, index: number) => {
              ListItem() {
                SongRow({
              song: song,
              index: index,
              playing: this.store.currentIndex === index && this.store.isPlaying,
              playingColor: this.getThemeColors().accent,
              showQuality: true,
              circularCoverWhenPlaying: true,
              showPlayingIcon: true,
              playingBg: semanticOf(this.isDark).fillAccentSubtle,
              coverSize: 56,
              titleFontSize: 16,
              rowHeight: 72,
              leftPadding: 16,
              animateEntry: true,
              entryDelayMs: this.entryDelay(index),
              menuItems: this.buildMenuItems(song),
              onPlay: () => {
                this.playSong(song);
              }
            })
              }
            })
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else {
          // 折叠屏 / 平板 / 2-in-1：两列网格，更高效地利用横向空间
          Grid() {
            ForEach(this.filteredSongs, (song: SongItem, index: number) => {
              GridItem() {
                SongRow({
              song: song,
              index: index,
              playing: this.store.currentIndex === index && this.store.isPlaying,
              playingColor: this.getThemeColors().accent,
              showQuality: true,
              circularCoverWhenPlaying: true,
              showPlayingIcon: true,
              playingBg: semanticOf(this.isDark).fillAccentSubtle,
              coverSize: 56,
              titleFontSize: 16,
              rowHeight: 72,
              leftPadding: 16,
              animateEntry: true,
              entryDelayMs: this.entryDelay(index),
              menuItems: this.buildMenuItems(song),
              onPlay: () => {
                this.playSong(song);
              }
            })
              }
            }, (song: SongItem): string => song.id.toString())
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(8)
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .padding({ left: SPACE_SM.compact, right: SPACE_SM.compact })
        }
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: this.bottomHeight + 16 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .backgroundColor(this.getThemeColors().bg)
    .bindSheet($$this.sheetOpen, this.sheetContent(), {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      dragBar: true,
      showClose: true,
      backgroundColor: this.getThemeColors().bg,
      preferType: SheetType.BOTTOM
    })
  }
}

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return hash;
}
