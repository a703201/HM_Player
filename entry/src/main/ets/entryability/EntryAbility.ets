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

import { Logger } from '../utils/Logger';
import {
  UIAbility,
  Configuration,
  ConfigurationConstant,
  Want,
  AbilityConstant
} from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { MusicStore } from '../services/MusicStore';
import { SettingsStore } from '../utils/SettingsStore';
import { ThemeManager } from '../utils/ThemeManager';
import { AVSessionController } from '../utils/AVSessionController';
import { CoverCache } from '../utils/CoverCache';
import { SongItem } from '../models/music';
import { AudioMetaReader } from '../utils/AudioMeta';
import { AudioRendererController } from '../utils/AudioRendererController';

// 与 CoverCache.CoverSource 对齐的具名入参类型（CoverSource 在 CoverCache.ets 内未导出，这里独立声明）
interface CoverSrcItem {
  src: string;
}

// 跨设备流转待恢复状态（由 onContinue 注入，maybeRestoreContinuation 消费）
interface ContinueRestore {
  songId: number;
  position: number;
  isPlaying: boolean;
}

export default class EntryAbility extends UIAbility {
  private windowObj?: window.Window;
  // 冷启动携带的 want（可能含文件打开 uri），待 store 初始化后处理
  private pendingStartWant?: Want;

  onCreate(want: Want) {
    AppStorage.setOrCreate('context', this.context);
    Logger.info('Ability onCreate');
    this.pendingStartWant = want;
    // 处理来自桌面卡片（FormAbility.onFormEvent）的播放控制指令
    this.handleControlWant(want);
  }

  onNewWant(want: Want) {
    Logger.info('Ability onNewWant');
    this.handleControlWant(want);
    // 应用已运行时，从文件管理器/浏览器「用 Lumio 打开」拉起播放
    this.handleFileWant(want);
  }

  /**
   * 解析 want 中的 control 指令（play/pause/next/prev），转发给 AVSessionController 回控播放。
   */
  private handleControlWant(want: Want): void {
    let control: string = (want.parameters?.['control'] as string) ?? '';
    // 桌面卡片 router 事件：参数经 postCardAction 的 params 以 JSON 字符串置于 want.parameters.params
    const paramsStr: string | undefined = want.parameters?.['params'] as string | undefined;
    if (paramsStr) {
      try {
        const params: ESObject = JSON.parse(paramsStr);
        const cmd: string = (params['control'] as string) ?? '';
        if (cmd) {
          control = cmd;
        }
      } catch (e) {
        Logger.error('Ability', `handleControlWant parse params failed: ${(e as Error).message}`);
      }
    }
    if (!control) {
      return;
    }
    Logger.info('Ability', `handleControlWant: ${control}`);
    AVSessionController.getInstance().remoteControl(control);
  }

  /**
   * 处理外部「用 Lumio 打开」音频文件（文件管理器 / 浏览器下载完成）：
   * 解析 want.uri → 命中库内已导入歌曲则直接播放，否则按 uri 生成临时 SongItem 入库存后起播。
   * 同时最佳努力地自动打开播放页（依赖 UI 就绪后的 NavPathStack）。
   */
  private async handleFileWant(want: Want): Promise<void> {
    const uri: string | undefined = want.uri;
    if (!uri || uri.length === 0) {
      return;
    }
    const lower: string = uri.toLowerCase();
    const isAudio: boolean =
      lower.endsWith('.mp3') || lower.endsWith('.flac') || lower.endsWith('.wav') ||
      lower.endsWith('.m4a') || lower.endsWith('.aac') || lower.endsWith('.ogg') ||
      lower.endsWith('.wma') || (want.type ?? '').startsWith('audio');
    if (!isAudio) {
      return;
    }
    Logger.info('Ability', `handleFileWant: ${uri}`);
    const store: MusicStore = MusicStore.getInstance();
    let song: SongItem | undefined = store.songs.find((s: SongItem) => s.src === uri);
    if (!song) {
      const fileName: string = decodeURIComponent(uri.substring(uri.lastIndexOf('/') + 1));
      const fallbackTitle: string = fileName.includes('.')
        ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
      const newSong: SongItem = new SongItem();
      newSong.id = this.hashUri(uri);
      newSong.src = uri;
      newSong.folder = this.extractFolderName(uri);
      newSong.title = fallbackTitle;
      newSong.singer = '未知艺术家';
      try {
        const meta = await AudioMetaReader.read(uri);
        if (meta) {
          newSong.title = (meta.title && meta.title.trim().length > 0) ? meta.title : fallbackTitle;
          newSong.singer = (meta.artist && meta.artist.trim().length > 0) ? meta.artist : '未知艺术家';
          newSong.album = meta.album ?? '';
          newSong.author = meta.author ?? '';
          newSong.year = meta.year ?? '';
          newSong.sampleRate = meta.sampleRate ?? 0;
          newSong.bitDepth = meta.bitDepth ?? 0;
          newSong.codec = meta.codec ?? '';
        }
      } catch (e) {
        Logger.error('Ability', 'handleFileWant meta read failed');
      }
      store.setSongs([...store.songs, newSong]);
      song = newSong;
    }
    const playIndex: number = store.songs.findIndex((s: SongItem) => s.id === song!.id);
    AudioRendererController.getInstance().setQueue(store.songs, playIndex >= 0 ? playIndex : 0, true);
    this.tryOpenPlayer();
  }

  /** 最佳努力打开播放页：UI 可能尚未就绪，最多重试若干次。 */
  private tryOpenPlayer(retry: number = 0): void {
    const nav: NavPathStack | undefined = AppStorage.get<NavPathStack>('navPathStack');
    if (nav) {
      try {
        nav.pushPathByName('PlayerPage', null);
      } catch (e) {
        Logger.error('Ability', 'tryOpenPlayer push failed');
      }
      return;
    }
    if (retry < 6) {
      setTimeout(() => this.tryOpenPlayer(retry + 1), 200);
    }
  }

  // ===== 分布式流转（跨设备接力播放）=====

  /**
   * 注册流转能力：在用户于「超级终端」选择目标设备时，回调返回携带当前播放状态的 Want，
   * 系统据此在目标设备拉起本 Ability 并触发 onContinue。设备需登录同一华为账号且开启多设备协同。
   * continuationManager 在部分 API 版本/设备上不暴露，这里以 ESObject 逃逸访问并做能力兜底，
   * 不支持时静默跳过，不影响常规播放。
   */
  private registerContinuation(): void {
    try {
      const ctx: ESObject = this.context as ESObject;
      const mgr: ESObject = ctx.continuationManager;
      if (!mgr || typeof mgr.register !== 'function') {
        Logger.info('Ability', 'continuationManager not available on this device');
        return;
      }
      mgr.register((info: ESObject): Want => {
        Logger.info('Ability', 'continuation register callback, device: ' + (info?.deviceId ?? ''));
        return this.buildContinueWant();
      });
    } catch (e) {
      Logger.error('Ability', 'register continuation failed: ' + (e as Error).message);
    }
  }

  /** 构造流转 Want：携带当前播放歌曲 id、进度、播放模式与队列，供目标设备重建会话。 */
  private buildContinueWant(): Want {
    const controller: AudioRendererController = AudioRendererController.getInstance();
    const song: SongItem | undefined = controller.getCurrentSong();
    const params: Record<string, Object> = {};
    if (song) {
      params['continueSongId'] = song.id;
      params['continuePosition'] = controller.getCurrentPosition();
      params['continuePlayMode'] = controller.getPlayMode();
      params['continueIsPlaying'] = (AppStorage.get<boolean>('isPlay') ?? false);
      const ids: number[] = controller.getQueue().map((s: SongItem) => s.id);
      params['continueQueueIds'] = ids;
    }
    return {
      bundleName: 'com.lumio.music',
      abilityName: 'EntryAbility',
      parameters: params
    } as Want;
  }

  /**
   * 流转目标侧：系统在拉起本 Ability 时回调，传入源设备保存的播放状态。
   * 仅记录待恢复标记，待 store 初始化后再由 maybeRestoreContinuation 应用（避免空库误判）。
   */
  onContinue(wantParams: Record<string, Object>): AbilityConstant.OnContinueResult {
    try {
      const songId: number = wantParams['continueSongId'] as number;
      if (songId === undefined || songId === null) {
        return AbilityConstant.OnContinueResult.AGREE;
      }
      const position: number = (wantParams['continuePosition'] as number) ?? 0;
      const isPlaying: boolean = (wantParams['continueIsPlaying'] as boolean) ?? false;
      const restore: ContinueRestore = { songId, position, isPlaying };
      AppStorage.setOrCreate<ContinueRestore>('continueRestore', restore);
      Logger.info('Ability', `onContinue received songId=${songId}, position=${position}`);
    } catch (e) {
      Logger.error('Ability', 'onContinue parse failed: ' + (e as Error).message);
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  /** 若本机是被流转目标，按保存的歌曲 id 在本地库中定位并接力恢复播放进度。 */
  private maybeRestoreContinuation(): void {
    const restore: ContinueRestore | undefined = AppStorage.get<ContinueRestore>('continueRestore');
    if (!restore || restore.songId === undefined || restore.songId === null) {
      return;
    }
    AppStorage.delete('continueRestore');
    const store: MusicStore = MusicStore.getInstance();
    const idx: number = store.songs.findIndex((s: SongItem) => s.id === restore.songId);
    if (idx < 0) {
      // 目标设备曲目库不含该歌曲（本地文件不同步），无法接力，静默放弃
      Logger.warn('Ability', 'continuation target library missing song, skip restore');
      return;
    }
    const controller: AudioRendererController = AudioRendererController.getInstance();
    controller.setQueue(store.songs, idx, true);
    // 等音频 prepare 后再 seek 并对齐播放/暂停状态（最佳努力）
    setTimeout(() => {
      if (restore.position && restore.position > 0) {
        controller.seek(restore.position);
      }
      if (restore.isPlaying) {
        controller.start();
      } else {
        controller.pause();
      }
    }, 600);
    this.tryOpenPlayer();
    Logger.info('Ability', `continuation restored to index=${idx}`);
  }

  private hashUri(str: string): number {
    let hash: number = 0;
    for (let i = 0; i < str.length; i++) {
      hash = (hash * 31 + str.charCodeAt(i)) | 0;
    }
    return Math.abs(hash);
  }

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

  onDestroy() {
    Logger.info('Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    Logger.info('Ability onWindowStageCreate');

    await this.initStore();
    // 冷启动从外部「用 Lumio 打开音频文件」拉起：store 就绪后解析 uri 起播
    if (this.pendingStartWant) {
      const w: Want = this.pendingStartWant;
      this.pendingStartWant = undefined;
      await this.handleFileWant(w);
    }
    // 跨设备流转目标：若由 onContinue 注入恢复标记，则接力恢复播放进度
    this.maybeRestoreContinuation();
    // 注册分布式流转能力（同一华为账号下的平板/智慧屏等可接力当前播放）
    this.registerContinuation();
    // 初始化设置项偏好与主题管理器（需在窗口就绪前完成，供页面与系统栏取色）
    await SettingsStore.getInstance().ensureInitialized(this.context);
    ThemeManager.init();

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error('Failed to load the content. Cause: ' + (JSON.stringify(err) ?? ''));
        return;
      }

      windowStage.getMainWindow().then((data: window.Window) => {
        this.windowObj = data;
        AppStorage.setOrCreate<window.Window>('window', data);

        // Enable full-screen immersive mode；状态栏/导航栏内容色跟随主题
        ThemeManager.applyToWindow();
        data.setWindowLayoutFullScreen(true);

        const uiContext = data.getUIContext();
        AppStorage.setOrCreate('uiContext', uiContext);
        let topArea = this.windowObj!.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        let topHeight = uiContext.px2vp(topArea.topRect.height);
        AppStorage.setOrCreate('topHeight', topHeight);
        let bottomArea = this.windowObj!.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        let bottomHeight = uiContext.px2vp(bottomArea.bottomRect.height);
        AppStorage.setOrCreate('bottomHeight', bottomHeight);
        this.updateBreakpoint(this.windowObj!.getWindowProperties().windowRect.width);
        this.windowObj!.on('windowSizeChange', (windowSize: window.Size) => {
          this.updateBreakpoint(windowSize.width);
        });
      });

      Logger.info('Succeeded in loading the content.');
    });
  }

  private updateBreakpoint(windowWidth: number): void {
    try {
      let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
      let curBp: string = '';
      if (windowWidthVp < BreakpointConstants.BREAKPOINT_VALUE_NUMBER[1]) {
        curBp = BreakpointConstants.BREAKPOINT_SM;
      } else if (windowWidthVp < BreakpointConstants.BREAKPOINT_VALUE_NUMBER[2]) {
        curBp = BreakpointConstants.BREAKPOINT_MD;
      } else {
        curBp = BreakpointConstants.BREAKPOINT_LG;
      }
      AppStorage.setOrCreate('currentBreakpoint', curBp);
    } catch (e) {
      AppStorage.setOrCreate('currentBreakpoint', BreakpointConstants.BREAKPOINT_SM);
    }
  }

  private async initStore(): Promise<void> {
    try {
      const store: MusicStore = MusicStore.getInstance();
      await store.init(this.context);
      // 一次性补扫已导入歌曲的文本元数据（标题/艺术家/专辑/作者），修复历史「未知艺术家」
      await store.refreshMetadataIfNeeded();
      if (store.songs.length === 0) {
        Logger.info('No local songs yet, import from 音乐库');
      } else {
        Logger.info(`Loaded ${store.songs.length} songs from storage`);
        // 方向 B：先做"高频封面优先预热"。
        // 优先采用 LumioCoverPreloadTask（taskPool）在后台并行预扫+文件存在校验的高频清单
        // （AppStorage('highFreqCoverSrcs')）；若 taskPool 尚未写好，回退到主线程实时计算。
        const prewarmed: string[] = AppStorage.get<string[]>('highFreqCoverSrcs') ?? [];
        const prioritySrcs: string[] = prewarmed.length > 0
          ? prewarmed
          : store.getHighFrequencySongSrcs();
        if (prioritySrcs.length > 0) {
          const mapped: CoverSrcItem[] = prioritySrcs.map((s: string): CoverSrcItem => ({ src: s }));
          CoverCache.getInstance().preload(mapped).then(() => {
            // 高频命中即先刷一次 token，让已就绪的高频封面先切到真实图
            AppStorage.setOrCreate('coverRefreshToken', Date.now());
          }).catch((err: Error) => {
            Logger.error('CoverCache high-freq preload failed: ' + err.message);
          });
        }
        // 全量预热：覆盖所有歌曲；CoverCache 内部按 src 去重，高频已抽取的会直接命中缓存
        CoverCache.getInstance().preload(store.songs).then(() => {
          AppStorage.setOrCreate('songList', [...store.songs]);
          AppStorage.setOrCreate('coverRefreshToken', Date.now());
        }).catch((err: Error) => {
          Logger.error('CoverCache full preload failed: ' + err.message);
        });
      }
    } catch (err) {
      Logger.error('Failed to init store');
    }
  }

  onConfigurationUpdated(config: Configuration): void {
    Logger.info('Ability onConfigurationUpdated');
    // 同步系统深色模式状态，供 ThemeManager 在「跟随系统」时读取
    const dark: boolean = config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.setOrCreate('systemIsDark', dark);
    // 仅当主题为「跟随系统」时，随系统深色模式刷新
    if (SettingsStore.getInstance().getThemeMode() === 'system') {
      ThemeManager.refreshSystemTheme();
    }
  }

  onWindowStageDestroy() {
    Logger.info('Ability onWindowStageDestroy');
  }

  onForeground() {
    Logger.info('Ability onForeground');
    // 回到前台时刷新桌面卡片状态（覆盖「播放中新增卡片、之后无状态变化」导致卡片为空的情况）
    AVSessionController.getInstance().pushFormUpdate();
  }

  onBackground() {
    Logger.info('Ability onBackground');
  }
}