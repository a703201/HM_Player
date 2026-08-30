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
import { UIAbility, Configuration, ConfigurationConstant, Want } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { BreakpointConstants } from '../common/constants/BreakpointConstants';
import { MusicStore } from '../services/MusicStore';
import { SettingsStore } from '../utils/SettingsStore';
import { ThemeManager } from '../utils/ThemeManager';
import { AVSessionController } from '../utils/AVSessionController';
import { CoverCache } from '../utils/CoverCache';

// 与 CoverCache.CoverSource 对齐的具名入参类型（CoverSource 在 CoverCache.ets 内未导出，这里独立声明）
interface CoverSrcItem {
  src: string;
}

export default class EntryAbility extends UIAbility {
  private windowObj?: window.Window;

  onCreate(want: Want) {
    AppStorage.setOrCreate('context', this.context);
    Logger.info('Ability onCreate');
    // 处理来自桌面卡片（FormAbility.onFormEvent）的播放控制指令
    this.handleControlWant(want);
  }

  onNewWant(want: Want) {
    Logger.info('Ability onNewWant');
    this.handleControlWant(want);
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

  onDestroy() {
    Logger.info('Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    Logger.info('Ability onWindowStageCreate');

    await this.initStore();
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