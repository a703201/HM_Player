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

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { AVSessionController } from './AVSessionController';
import SongItemBuilder from '../songdatacontroller/SongItemBuilder';
import { MusicPlayMode } from '../songdatacontroller/PlayerData';
import { SongItem } from '../songdatacontroller/SongData';
import { BackgroundUtil } from './BackgroundUtil';
import { MediaTools } from './MediaTools';
import { Logger } from './Logger';
import { PreferencesUtil } from './PreferencesUtil';
import { MusicStore } from '../services/MusicStore';
import { SettingsStore } from './SettingsStore';
import { SleepTimer } from './SleepTimer';

const TAG = 'AudioRendererController';

export class AudioRendererController {
  public avPlayer?: media.AVPlayer;
  // 冷启动修复：createAVPlayer 是异步的，play() 必须先 await 它就绪，否则会在 avPlayer 未创建时静默返回。
  private avPlayerReady: Promise<void> | undefined = undefined;
  private context: common.UIAbilityContext | undefined = AppStorage.get('context');
  private songItemBuilder: SongItemBuilder = new SongItemBuilder();
  private playMode: MusicPlayMode = MusicPlayMode.ORDER;
  private isFirst: boolean = true;
  private musicIndex: number = 0;
  private songList: SongItem[] = [];
  private curMs: number = 0;
  private avSessionController: AVSessionController | undefined = undefined;
  private duration: number = 0;
  private curFile?: fileIo.File;
  // 投播状态标记：为 true 时本地播放器在 prepared 后不自动起播，保持静音（由远端设备出声）
  public castActive: boolean = false;
  // 播放速度（倍速），默认 1.0
  private speed: number = 1.0;
  private isSilent: boolean = false;
  // 听歌统计：当前曲目累计播放时长（ms）与上一帧时间，避免在 timeUpdate 高频回写偏好
  private playMsAccum: number = 0;
  private prevTimeMs: number = 0;
  private curStatSongId: number = -1;
  // ===== Gapless 无缝播放 =====
  // 第二路 AVPlayer，用于预加载「下一首」到 prepared 状态，曲终时无缝接管（消除 reset/prepare 间隙）。
  private nextAvPlayer?: media.AVPlayer;
  private nextFile?: fileIo.File;
  private nextIndex: number = -1;
  private nextReady: boolean = false;
  private gaplessEnabled: boolean = true;
  // 主播放器监听句柄（具名，便于在释放旧播放器时 off 掉，避免交接后旧曲迟到的 completed 再次触发推进）
  private avStateHandler?: (state: string) => void;
  private avTimeHandler?: (time: number) => void;
  private avDurationHandler?: (dur: number) => void;

  constructor() {
    let list: SongItem[] | undefined = AppStorage.get('songList');
    if (list) {
      this.songList = list;
    }
    this.songItemBuilder = new SongItemBuilder();
    this.initAVPlayer();
  }

  public static getInstance(): AudioRendererController {
    let audioRendererController: AudioRendererController | undefined = AppStorage.get('audioRendererController');
    if (!audioRendererController) {
      audioRendererController = new AudioRendererController();
      AppStorage.setOrCreate<AudioRendererController>('audioRendererController', audioRendererController);
    }
    return audioRendererController;
  }

  private initAVPlayer(): void {
    this.avPlayerReady = (async () => {
      try {
        this.avPlayer = await media.createAVPlayer();
        this.setAVPlayerCallbacks();
        Logger.info(TAG, 'createAVPlayer succeeded');
      } catch (err) {
        Logger.error(TAG, `createAVPlayer failed: ${err.code} - ${err.message}`);
      }
    })();
  }

  private setAVPlayerCallbacks(): void {
    if (!this.avPlayer) {
      return;
    }
    this.setAvSessionCallback();

    // 监听句柄只创建一次，并以「先 off 再 on」方式挂载，保证每次 handoff/接管后主播放器上
    // 仅有这一个 stateChange/timeUpdate/durationUpdate 监听（避免重复挂载导致回调多次触发）。
    if (!this.avStateHandler) {
      this.avStateHandler = (state: string) => {
        Logger.info(TAG, 'AVPlayer stateChange: ' + state);
        if (state === 'initialized') {
          // fdSrc 已设置，进入 prepared 状态准备播放（官方推荐：在状态回调中驱动状态机）
          this.avPlayer?.prepare();
        } else if (state === 'prepared') {
          // 准备完成。投播状态下本地保持静音（由远端设备出声），不自动起播。
          if (!this.castActive) {
            this.applySpeed();
            this.applySilentMode();
            this.start();
          }
        } else if (state === 'playing') {
          this.updateIsPlay(true);
        } else if (state === 'paused') {
          this.updateIsPlay(false);
        } else if (state === 'completed') {
          this.onPlaybackCompleted();
        } else if (state === 'stopped') {
          this.updateIsPlay(false);
        }
      };
    }
    if (!this.avTimeHandler) {
      this.avTimeHandler = (time: number) => {
        this.curMs = time;
        AppStorage.setOrCreate('progress', time);
        AppStorage.setOrCreate('currentTime', MediaTools.msToCountdownTime(time));
        if (this.curStatSongId > 0 && this.prevTimeMs > 0 && time >= this.prevTimeMs) {
          this.playMsAccum += (time - this.prevTimeMs);
        }
        this.prevTimeMs = time;
        if (this.avSessionController) {
          this.avSessionController.setProgressState(time);
        }
      };
    }
    if (!this.avDurationHandler) {
      this.avDurationHandler = (dur: number) => {
        this.duration = dur;
        AppStorage.setOrCreate('totalTime', MediaTools.msToCountdownTime(dur));
        AppStorage.setOrCreate('totalMsTime', dur);
        AppStorage.setOrCreate('progressMax', dur);
      };
    }

    // 先 off 再 on：幂等，确保主播放器上监听器唯一
    this.avPlayer.off('stateChange', this.avStateHandler);
    this.avPlayer.on('stateChange', this.avStateHandler);
    this.avPlayer.off('timeUpdate', this.avTimeHandler);
    this.avPlayer.on('timeUpdate', this.avTimeHandler);
    this.avPlayer.off('durationUpdate', this.avDurationHandler);
    this.avPlayer.on('durationUpdate', this.avDurationHandler);

    this.avPlayer.on('error', (err: BusinessError) => {
      Logger.error(TAG, `AVPlayer error: ${err.code} - ${err.message}`);
    });
  }

  private setAvSessionCallback(): void {
    this.avSessionController = AVSessionController.getInstance();
    this.avSessionController.bindAudioRendererController(this);
  }

  public async setSilentModeAndMixWithOthers(isSupportSilent: boolean = false): Promise<void> {
    if (!this.context) {
      return;
    }
    // 静音（混合播放）标记走独立 Preferences 键，不再写入 formIds 桌面卡片数组，避免污染
    this.isSilent = isSupportSilent;
    try {
      await PreferencesUtil.getInstance().setSilentMode(this.context, isSupportSilent);
    } catch (e) {
      Logger.error(TAG, 'setSilentMode failed');
    }
    AppStorage.setOrCreate('isSilentMode', isSupportSilent);
    // 真正调节音量：非静音恢复为 1.0，静音置 0。修复"只变图标不静音"的 Bug B。
    this.applySilentMode();
  }

  /**
   * 应用静音状态到 AVPlayer 音量。仅在 avPlayer 就绪后调用；
   * 切歌/重播后由 prepared 状态机再次调用，避免 reset 把音量重置为默认值。
   */
  private applySilentMode(): void {
    if (!this.avPlayer) {
      return;
    }
    try {
      this.avPlayer.setVolume(this.isSilent ? 0 : 1);
    } catch (e) {
      Logger.error(TAG, 'applySilentMode setVolume failed');
    }
  }

  public async play(musicIndex: number = this.musicIndex): Promise<void> {
    if (this.avPlayerReady) {
      try {
        await this.avPlayerReady;
      } catch (e) {
        Logger.error(TAG, 'avPlayer init failed, cannot play');
      }
    }
    if (!this.avPlayer) {
      Logger.error(TAG, 'avPlayer is undefined');
      return;
    }
    if (musicIndex >= this.songList.length) {
      Logger.error(TAG, `current musicIndex ${musicIndex} out of range`);
      return;
    }
    BackgroundUtil.startContinuousTask(this.context);
    this.updateMusicIndex(musicIndex);
    // 记录播放历史：每次起播（含切歌/点歌）都将当前歌曲写入"最近播放"
    const playedSong: SongItem | undefined = this.songList[this.musicIndex];
    if (playedSong) {
      MusicStore.getInstance().addToRecentlyPlayed(playedSong);
      this.curStatSongId = playedSong.id;
      this.playMsAccum = 0;
      this.prevTimeMs = 0;
      MusicStore.getInstance().recordPlayStart(playedSong.id);
    }
    await this.loadAndPlay();
    // 起播后预加载下一首，为 Gapless 无缝接管做准备
    this.preloadNext();
  }

  private async loadAndPlay(): Promise<void> {
    if (!this.avPlayer) {
      return;
    }
    // 手动切歌会使已预加载的「下一首」失效，先释放，play() 末尾会重新预加载
    this.disposeNextPlayer();
    // 关闭上一首歌曲占用的文件句柄，避免 fd 泄漏
    if (this.curFile) {
      try {
        fileIo.closeSync(this.curFile.fd);
      } catch (e) {
      }
      this.curFile = undefined;
    }
    try {
      await this.avPlayer.stop();
    } catch (e) {
    }
    try {
      await this.avPlayer.reset();
    } catch (e) {
    }

    const song: SongItem | undefined = this.songList[this.musicIndex];
    if (!song) {
      Logger.error(TAG, 'song is undefined at index: ' + this.musicIndex);
      return;
    }

    try {
      const file: fileIo.File = fileIo.openSync(song.src, fileIo.OpenMode.READ_ONLY);
      this.curFile = file;
      this.avPlayer.fdSrc = { fd: file.fd };
      Logger.infoPrivate(TAG, 'Playing: ' + song.title + ' from ' + song.src);
    } catch (e) {
      Logger.errorPrivate(TAG, 'Failed to open file: ' + song.src);
    }
  }

  public getFirst(): boolean {
    return this.isFirst;
  }

  public getCurrentSong(): SongItem | undefined {
    return this.songList[this.musicIndex];
  }

  public getCurrentPosition(): number {
    return this.curMs;
  }

  // ===== 播放队列管理（队列权威持有者）=====
  public getQueue(): SongItem[] {
    return [...this.songList];
  }

  public getCurrentIndex(): number {
    return this.musicIndex;
  }

  /**
   * 覆盖当前播放队列并（可选）立即起播。
   * 用于：从列表/历史/收藏切歌时统一设置队列，以及智能排序后重排队列。
   * autoPlay=false 时仅重排队列与索引，不重载当前正在播放的音频（排序场景）。
   */
  public setQueue(songs: SongItem[], startIndex: number, autoPlay: boolean = true): void {
    if (!songs || songs.length === 0) {
      Logger.error(TAG, 'setQueue: empty songs');
      return;
    }
    if (startIndex < 0 || startIndex >= songs.length) {
      startIndex = 0;
    }
    this.songList = [...songs];
    this.musicIndex = startIndex;
    this.syncQueue();
    if (autoPlay) {
      this.play(startIndex);
    } else {
      AppStorage.setOrCreate('selectIndex', startIndex);
      this.preloadNext();
    }
  }

  /**
   * 点歌即播：以给定列表作为播放队列，立即播放指定位置歌曲并进入播放页。
   * 用于库/收藏/历史列表行点击——统一取代原先「只跳转不播放」的行为。
   * 等价于 setQueue(list, index, true)（设队列 + 索引 + syncQueue + 起播）。
   */
  public playFromList(list: SongItem[], index: number): void {
    if (!list || list.length === 0) {
      Logger.warn(TAG, 'playFromList: empty song list');
      return;
    }
    if (index < 0 || index >= list.length) {
      Logger.warn(TAG, `playFromList: index ${index} out of range [0, ${list.length})`);
      return;
    }
    this.setQueue(list, index, true);
  }

  /**
   * 从队列移除指定位置歌曲，并维持当前播放位置正确：
   * - 移除位于当前之前的项：current 前移
   * - 移除当前项：停止并续播相邻项（若有）
   */
  public removeFromQueue(index: number): void {
    if (index < 0 || index >= this.songList.length) {
      return;
    }
    this.songList.splice(index, 1);
    if (index < this.musicIndex) {
      this.musicIndex--;
    } else if (index === this.musicIndex) {
      if (this.songList.length === 0) {
        this.musicIndex = 0;
        this.stop();
      } else {
        const idx: number = Math.min(this.musicIndex, this.songList.length - 1);
        this.musicIndex = idx;
        this.updateMusicIndex(idx);
        this.play(idx);
      }
    }
    this.syncQueue();
    this.preloadNext();
  }

  /**
   * 将指定位置歌曲移动到"当前歌曲的下一首"，实现"下一首播放"。
   * 不改变当前正在播放的曲目，仅影响后续播放顺序。
   */
  public moveToPlayNext(index: number): void {
    if (index < 0 || index >= this.songList.length) {
      return;
    }
    if (index === this.musicIndex) {
      return;
    }
    const item: SongItem | undefined = this.songList.splice(index, 1)[0];
    if (!item) {
      return;
    }
    if (index < this.musicIndex) {
      this.musicIndex--;
    }
    const insertAt: number = this.musicIndex + 1;
    this.songList.splice(insertAt, 0, item);
    this.syncQueue();
    this.preloadNext();
  }

  private syncQueue(): void {
    AppStorage.setOrCreate('songList', [...this.songList]);
    AppStorage.setOrCreate('selectIndex', this.musicIndex);
    if (this.avSessionController) {
      this.avSessionController.setSongList([...this.songList], this.musicIndex);
    }
  }

  /**
   * 将引擎内部播放队列与真实曲库对齐（差量合并，保留用户在队列弹窗里的手动排序/下一首播放/移除结果）：
   * - 移除队列中已在曲库中被删除的歌曲，并修正当前播放索引，避免 next/prev 跳到已删除文件。
   * - 把新导入的歌曲追加到队列尾部，使"下一首"能逐步覆盖到新歌。
   * 仅在导入/删除歌曲后调用，不在进入播放页时调用，以免覆盖用户在队列弹窗里的手动移除。
   */
  public reconcileWithLibrary(library: SongItem[]): void {
    if (!library || library.length === 0) {
      return;
    }
    const libIds: Set<number> = new Set<number>();
    library.forEach((s: SongItem) => libIds.add(s.id));

    const cur: SongItem | undefined = this.songList[this.musicIndex];
    const curId: number | undefined = cur ? cur.id : undefined;

    // 1. 移除已删除项
    this.songList = this.songList.filter((s: SongItem) => libIds.has(s.id));

    // 2. 修正当前索引（当前曲被删除时选相邻曲目续播）
    let newIndex: number = 0;
    if (curId !== undefined) {
      const found: number = this.songList.findIndex((s: SongItem) => s.id === curId);
      newIndex = found >= 0 ? found : Math.max(0, Math.min(this.musicIndex, this.songList.length - 1));
    } else {
      newIndex = Math.max(0, Math.min(this.musicIndex, this.songList.length - 1));
    }
    this.musicIndex = newIndex;

    // 3. 追加新导入的歌曲到队尾
    const queueIds: Set<number> = new Set<number>();
    this.songList.forEach((s: SongItem) => queueIds.add(s.id));
    for (const s of library) {
      if (!queueIds.has(s.id)) {
        this.songList.push(s);
      }
    }

    this.syncQueue();

    // 当前正在播放的歌曲被删除：续播相邻曲目，空队列则停止
    if (curId !== undefined && this.songList.findIndex((s: SongItem) => s.id === curId) < 0) {
      if (this.songList.length === 0) {
        this.stop();
      } else {
        this.play(newIndex);
      }
    } else {
      // 队列顺序变化后重新预加载下一首
      this.preloadNext();
    }
  }

  public setCastActive(active: boolean): void {
    this.castActive = active;
  }

  public setPlayModel(playMode: MusicPlayMode): void {
    this.playMode = playMode;
    if (!this.avSessionController) {
      return;
    }
    this.avSessionController.setPlayModeToAVSession();
    Logger.info(TAG, 'setPlayModel mode: ' + this.playMode);
    // 播放模式变化会改变「下一首」是谁，重建预加载
    this.preloadNext();
  }

  public getPlayMode(): MusicPlayMode {
    return this.playMode;
  }

  private updateIsPlay(isPlay: boolean): void {
    AppStorage.setOrCreate<boolean>('isPlay', isPlay);
    if (!this.avSessionController) {
      return;
    }
    this.avSessionController.setPlayState(isPlay);
  }

  public getSpeed(): number {
    return this.speed;
  }

  public async setSpeed(rate: number): Promise<void> {
    if (rate <= 0) {
      return;
    }
    this.speed = rate;
    AppStorage.setOrCreate('playSpeed', rate);
    if (this.avPlayer) {
      try {
        await this.avPlayer.setSpeed(rate);
      } catch (e) {
        Logger.error(TAG, 'setSpeed failed');
      }
    }
    // 同步倍速到系统媒体中心（锁屏/控制中心）
    if (this.avSessionController) {
      this.avSessionController.setSpeedState(rate);
    }
  }

  private applySpeed(): void {
    if (this.avPlayer && this.speed !== 1.0) {
      try {
        this.avPlayer.setSpeed(this.speed);
      } catch (e) {
        Logger.error(TAG, 'applySpeed failed');
      }
    }
  }

  // ===== Gapless 无缝播放 =====

  /** 同步最新无缝/交叉淡变设置（每次起播与预加载前读取，确保设置页改动即时生效）。 */
  private refreshGaplessSettings(): void {
    try {
      const s: SettingsStore = SettingsStore.getInstance();
      this.gaplessEnabled = s.getGapless();
    } catch (e) {
    }
  }

  /** 设置项变动回调：关闭无缝或改交叉淡变时长后立即刷新（关闭时清理已预加载缓冲）。 */
  public onGaplessSettingChanged(): void {
    this.refreshGaplessSettings();
    if (!this.gaplessEnabled) {
      this.disposeNextPlayer();
      return;
    }
    this.preloadNext();
  }

  /** 计算「下一首」在队列中的下标（与 playNext 的索引推进逻辑保持一致，但不真正播放）。 */
  private computeNextIndex(): number {
    if (this.songList.length === 0) {
      return -1;
    }
    if (this.songList.length === 1) {
      return 0;
    }
    switch (this.playMode) {
      case MusicPlayMode.SINGLE_CYCLE:
        return this.musicIndex;
      case MusicPlayMode.RANDOM:
        let num: number = Math.round(Math.random() * (this.songList.length - 1));
        if (num === this.musicIndex) {
          num = (num + 1) % this.songList.length;
        }
        return num;
      case MusicPlayMode.ORDER:
      default:
        return this.musicIndex === this.songList.length - 1 ? 0 : this.musicIndex + 1;
    }
  }

  /**
   * 预加载下一首到 prepared 状态。创建第二路 AVPlayer 并 openSync 下一首 fd，
   * 由状态机驱动到 'prepared'；曲终时由 handoffToNext 接管。
   * 投播态与无缝关闭时不预加载（远端设备负责切换，本地单路即可）。
   */
  private preloadNext(): void {
    this.refreshGaplessSettings();
    // 已预加载且仍有效：保留
    if (this.nextAvPlayer && this.nextReady && this.nextIndex >= 0) {
      return;
    }
    this.disposeNextPlayer();
    if (!this.gaplessEnabled || this.castActive || !this.avPlayer) {
      return;
    }
    const idx: number = this.computeNextIndex();
    if (idx < 0 || idx === this.musicIndex) {
      return;
    }
    const song: SongItem | undefined = this.songList[idx];
    if (!song) {
      return;
    }
    try {
      const file: fileIo.File = fileIo.openSync(song.src, fileIo.OpenMode.READ_ONLY);
      this.nextFile = file;
      this.nextIndex = idx;
      this.nextReady = false;
      media.createAVPlayer().then((player: media.AVPlayer) => {
        // 创建可能因资源紧张失败，此时放弃预加载，回退普通切歌
        if (!this.nextFile || this.nextIndex !== idx) {
          try {
            fileIo.closeSync(file.fd);
          } catch (e) {
          }
          player.release().catch(() => {});
          return;
        }
        this.nextAvPlayer = player;
        // 仅挂载最小状态监听：initialized→prepare 驱动到 prepared 后标记就绪。
        // 接管后由 setAVPlayerCallbacks 挂载主回调，避免重复监听。
        player.on('stateChange', (state: string) => {
          if (player !== this.nextAvPlayer) {
            return;
          }
          if (state === 'initialized') {
            player.prepare();
          } else if (state === 'prepared') {
            this.nextReady = true;
          }
        });
        player.on('error', (err: BusinessError) => {
          Logger.error(TAG, `nextPlayer error: ${err.code} - ${err.message}`);
        });
        player.fdSrc = { fd: file.fd };
      }).catch((err: Error) => {
        Logger.error(TAG, 'create next AVPlayer failed: ' + (err as Error).message);
        try {
          fileIo.closeSync(file.fd);
        } catch (e) {
        }
        this.nextFile = undefined;
        this.nextIndex = -1;
      });
    } catch (e) {
      Logger.error(TAG, 'preloadNext open failed');
      this.nextFile = undefined;
      this.nextIndex = -1;
    }
  }

  /** 释放第二路 AVPlayer 与 fd，避免资源泄漏。 */
  private disposeNextPlayer(): void {
    if (this.nextAvPlayer) {
      const p: media.AVPlayer = this.nextAvPlayer;
      try {
        p.stop().then(() => {
          p.release().catch(() => {});
        }).catch(() => {
          p.release().catch(() => {});
        });
      } catch (e) {
        try {
          p.release().catch(() => {});
        } catch (e2) {
        }
      }
    }
    if (this.nextFile) {
      try {
        fileIo.closeSync(this.nextFile.fd);
      } catch (e) {
      }
    }
    this.nextAvPlayer = undefined;
    this.nextFile = undefined;
    this.nextIndex = -1;
    this.nextReady = false;
  }

  /** 释放指定（旧）播放器与 fd（handoff 后对旧路做善后）。 */
  private disposePlayer(player?: media.AVPlayer, file?: fileIo.File): void {
    if (player) {
      // 关键：先摘掉旧播放器的主监听，避免交叉淡变提升新曲后，旧曲迟到（stop/release 异步）的
      // 'completed' 事件再次进入 onPlaybackCompleted 造成「跳过下一首」的双推进。
      try {
        if (this.avStateHandler) {
          player.off('stateChange', this.avStateHandler);
        }
        if (this.avTimeHandler) {
          player.off('timeUpdate', this.avTimeHandler);
        }
        if (this.avDurationHandler) {
          player.off('durationUpdate', this.avDurationHandler);
        }
      } catch (e) {
      }
      try {
        player.stop().then(() => {
          player.release().catch(() => {});
        }).catch(() => {
          player.release().catch(() => {});
        });
      } catch (e) {
        try {
          player.release().catch(() => {});
        } catch (e2) {
        }
      }
    }
    if (file) {
      try {
        fileIo.closeSync(file.fd);
      } catch (e) {
      }
    }
  }

  /**
   * 无缝硬切接管：当前曲自然结束后，将已 prepared 的下一首提升为主播放器，
   * 立即起播（仅含 play() 极短延迟，远小于 reset+prepare 间隙），随后预加载再下一首。
   */
  private handoffToNext(): void {
    const oldPlayer: media.AVPlayer | undefined = this.avPlayer;
    const oldFile: fileIo.File | undefined = this.curFile;
    const promoted: media.AVPlayer | undefined = this.nextAvPlayer;
    const promotedFile: fileIo.File | undefined = this.nextFile;
    const nextIdx: number = this.nextIndex;
    if (!promoted || nextIdx < 0 || nextIdx >= this.songList.length) {
      this.disposeNextPlayer();
      this.playNext();
      return;
    }
    // 提升下一首为主播放器
    this.avPlayer = promoted;
    this.curFile = promotedFile;
    this.nextAvPlayer = undefined;
    this.nextFile = undefined;
    this.nextIndex = -1;
    this.nextReady = false;
    // 挂载主回调（接管时间/进度/完成等事件）
    this.setAVPlayerCallbacks();
    // 更新队列索引与歌曲元数据
    this.musicIndex = nextIdx;
    this.updateMusicIndex(nextIdx);
    const song: SongItem | undefined = this.songList[nextIdx];
    if (song) {
      MusicStore.getInstance().addToRecentlyPlayed(song);
      this.curStatSongId = song.id;
      this.playMsAccum = 0;
      this.prevTimeMs = 0;
      MusicStore.getInstance().recordPlayStart(song.id);
    }
    this.syncQueue();
    // 预加载时已 prepared，durationUpdate 未挂载：手动同步总时长，避免进度条时长错乱
    this.syncDurationFromPlayer();
    // 应用速度与静音并起播（已 prepared）
    this.applySpeed();
    this.applySilentMode();
    this.start();
    // 预加载再下一首
    this.preloadNext();
    // 善后旧路
    this.disposePlayer(oldPlayer, oldFile);
    Logger.info(TAG, 'Gapless handoff to index: ' + nextIdx);
  }

  /** 接管后从当前播放器读取总时长并同步到 AppStorage（预加载期间 durationUpdate 未挂载）。 */
  private syncDurationFromPlayer(): void {
    if (!this.avPlayer) {
      return;
    }
    try {
      const dur: number = this.avPlayer.duration;
      if (dur > 0) {
        this.duration = dur;
        AppStorage.setOrCreate('totalTime', MediaTools.msToCountdownTime(dur));
        AppStorage.setOrCreate('totalMsTime', dur);
        AppStorage.setOrCreate('progressMax', dur);
      }
    } catch (e) {
    }
  }

  private flushStat(): void {
    if (this.curStatSongId > 0 && this.playMsAccum > 0) {
      MusicStore.getInstance().recordPlayDuration(this.curStatSongId, this.playMsAccum);
      this.playMsAccum = 0;
    }
  }

  public getDuration(): number {
    return this.duration;
  }

  public async start(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.play();
        this.updateIsPlay(true);
        BackgroundUtil.startContinuousTask(this.context);
        Logger.info(TAG, 'start success');
      } catch (e) {
        Logger.error(TAG, 'start failed');
      }
    }
  }

  public async pause(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.pause();
        this.updateIsPlay(false);
        this.flushStat();
        Logger.info(TAG, 'pause success');
      } catch (e) {
        Logger.error(TAG, 'pause failed');
      }
    }
  }

  public seek(ms: number): void {
    if (this.avPlayer) {
      this.curMs = ms;
      this.flushStat();
      this.prevTimeMs = ms;
      AppStorage.setOrCreate('progress', ms);
      AppStorage.setOrCreate('currentTime', MediaTools.msToCountdownTime(ms));
      try {
        this.avPlayer.seek(ms, media.SeekMode.SEEK_CLOSEST);
      } catch (e) {
        Logger.error(TAG, 'seek failed');
      }
      if (this.avSessionController) {
        this.avSessionController.setProgressState(ms);
      }
    }
  }

  /**
   * 播放完成回调：尊重「自动下一首」设置（FR-B8）。
   * 开启 → 按当前播放模式切到下一首；关闭 → 停止并停在当前曲。
   * 空队列守卫由 playNext() 内部保证（stop() 不依赖队列）。
   */
  private onPlaybackCompleted(): void {
    this.flushStat();
    // 睡眠定时「播完当前曲后停止」模式：自然界线后暂停，不再自动续播
    if (SleepTimer.getInstance().isEndOfSong()) {
      SleepTimer.getInstance().cancel();
      this.pause();
      return;
    }
    // Gapless：若下一首已预加载就绪，直接无缝接管（消除 reset/prepare 间隙）
    if (this.gaplessEnabled && !this.castActive && this.nextReady && this.nextAvPlayer) {
      this.handoffToNext();
      return;
    }
    if (SettingsStore.getInstance().getAutoNext()) {
      if (this.songList.length > 0 && this.avPlayer) {
        this.playNext();
      }
    } else {
      this.stop();
    }
  }

  public async playNext(): Promise<void> {
    Logger.info(TAG, 'playNext Index:' + this.musicIndex + ', length-1:' + (this.songList.length - 1));
    if (this.songList.length === 0) {
      Logger.warn(TAG, 'playNext: song list is empty');
      return;
    }
    if (!this.avPlayer) {
      Logger.error(TAG, 'avPlayer is undefined');
      return;
    }
    switch (this.playMode) {
      case MusicPlayMode.SINGLE_CYCLE:
        this.play(this.musicIndex);
        break;
      case MusicPlayMode.ORDER:
        if (this.musicIndex === this.songList.length - 1) {
          this.musicIndex = 0;
        } else {
          this.musicIndex += 1;
        }
        this.play(this.musicIndex);
        break;
      case MusicPlayMode.RANDOM:
        this.playRandom();
        break;
      default:
        break;
    }
  }

  public async playPrevious(): Promise<void> {
    Logger.info(TAG, 'playPrevious Index:' + this.musicIndex + ', length-1:' + (this.songList.length - 1));
    if (this.songList.length === 0) {
      Logger.warn(TAG, 'playPrevious: song list is empty');
      return;
    }
    if (!this.avPlayer) {
      Logger.error(TAG, 'avPlayer is undefined');
      return;
    }
    if (this.curMs > 3000) {
      this.seek(0);
      return;
    }
    switch (this.playMode) {
      case MusicPlayMode.SINGLE_CYCLE:
        this.play(this.musicIndex);
        break;
      case MusicPlayMode.ORDER:
        if (this.musicIndex === 0) {
          this.musicIndex = this.songList.length - 1;
        } else {
          this.musicIndex -= 1;
        }
        this.play(this.musicIndex);
        break;
      case MusicPlayMode.RANDOM:
        this.playRandom();
        break;
      default:
        break;
    }
  }

  private playRandom(): void {
    if (this.songList.length === 0) {
      Logger.warn(TAG, 'playRandom: song list is empty');
      return;
    }
    if (this.songList.length === 1) {
      this.play(0);
      return;
    }
    let num: number = Math.round(Math.random() * (this.songList.length - 1));
    if (this.musicIndex === num) {
      this.playRandom();
    } else {
      this.updateMusicIndex(num);
      this.play(num);
    }
    Logger.info(TAG, 'play Random:' + this.musicIndex);
  }

  public async stop(): Promise<void> {
    this.disposeNextPlayer();
    if (this.avPlayer) {
      try {
        await this.avPlayer.stop();
        this.curMs = 0;
        this.flushStat();
        this.updateIsPlay(false);
        AppStorage.setOrCreate('currentTime', "00:00");
        AppStorage.setOrCreate('progress', 0);
        Logger.info(TAG, 'stop success');
      } catch (e) {
        Logger.error(TAG, 'stop failed');
      }
    }
  }

  public async release(): Promise<void> {
    this.disposeNextPlayer();
    if (this.avPlayer && this.context) {
      try {
        await this.avPlayer.release();
        if (this.curFile) {
          try {
            fileIo.closeSync(this.curFile.fd);
          } catch (e) {
          }
          this.curFile = undefined;
        }
        this.avSessionController?.unregisterSessionListener();
        BackgroundUtil.stopContinuousTask(this.context);
        Logger.info(TAG, 'release success');
      } catch (e) {
        Logger.error(TAG, 'release failed');
      }
    }
  }

  private updateMusicIndex(musicIndex: number): void {
    Logger.info(TAG, 'updateMusicIndex ===> ' + musicIndex);
    AppStorage.setOrCreate('selectIndex', musicIndex);
    if (this.musicIndex !== musicIndex) {
      this.musicIndex = musicIndex;
    }
    this.isFirst = false;
    if (!this.avSessionController) {
      return;
    }
    Logger.info(TAG, 'this.session !== undefined ');
    this.avSessionController.setAVMetadata();
    // 收藏态一律按稳定的 song.id 查询，不能用会漂移的队列下标
    const cur: SongItem | undefined = this.songList[this.musicIndex];
    if (cur) {
      this.avSessionController.getAndUpdateFavoriteState(cur.id.toString());
    }
  }
}
