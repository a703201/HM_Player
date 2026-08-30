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

import { common, wantAgent } from '@kit.AbilityKit';
// [Start avsession_controller]
import { avSession } from '@kit.AVSessionKit';
// [StartExclude avsession_controller]
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { fileIo } from '@kit.CoreFileKit';
import { formProvider, formBindingData } from '@kit.FormKit';
import { SongItem } from '../songdatacontroller/SongData';
import { Logger } from './Logger';
import { MediaTools } from './MediaTools';
import { EmbeddedLyricReader } from './EmbeddedLyricReader';
import { AudioRendererController } from './AudioRendererController';
import { MusicPlayMode, SILENT_ID } from '../songdatacontroller/PlayerData';
import { PreferencesUtil } from './PreferencesUtil';
// [StartExclude favorites_unified]
import { MusicStore } from '../services/MusicStore';
// [EndExclude favorites_unified]

const TAG = 'AVSessionController';
// [EndExclude avsession_controller]
export class AVSessionController {
  private context: common.UIAbilityContext | undefined = undefined;
  private AVSession: avSession.AVSession | undefined = undefined;
  private songList: SongItem[] = [];

  /**
   * 由 AudioRendererController 在队列变更（切歌/排序/增删）后同步元数据源，
   * 保证锁屏/桌面卡片的封面与标题与实际播放队列一致。
   */
  public setSongList(list: SongItem[], index?: number): void {
    this.songList = list;
    if (index !== undefined) {
      this.musicIndex = index;
    }
  }
  private musicIndex: number | undefined = undefined;
  private audioRendererController: AudioRendererController | undefined = undefined;
  private listenersRegistered: boolean = false;
  // [StartExclude avsession_controller]
  // 投播（Cast）相关状态
  private castController: avSession.AVCastController | undefined = undefined;
  private isCasting: boolean = false;
  private castFile: fileIo.File | undefined = undefined; // 投播独立文件句柄，与本地播放 curFile 解耦
  private castRemotePositionMs: number = 0; // 记录远端播放进度，断连后本地续播对齐
  // [EndExclude avsession_controller]
  // [StartExclude avsession_controller]
  constructor() {
    let list: SongItem[] | undefined = AppStorage.get('songList');
    if (list) {
      this.songList = list;
    }
    this.initAVSession();
  }

  public static getInstance(): AVSessionController {
    let avSessionController: AVSessionController | undefined = AppStorage.get('AVSessionController');
    if (!avSessionController) {
      avSessionController = new AVSessionController();
      AppStorage.setOrCreate<AVSessionController>('AVSessionController', avSessionController);
    }
    return avSessionController;
  }

  // [EndExclude avsession_controller]
  private async initAVSession() {
    this.context = AppStorage.get('context');
    if (!this.context) {
      Logger.info(TAG, `session create failed : context is undefined`);
      return;
    }
    try {
      this.AVSession = await avSession.createAVSession(this.context, "PLAY_AUDIO", 'audio');
      await this.AVSession.activate();
      // 声明支持投播（局域网/远端设备），AVCastPicker 才能拉起可投播设备列表
      this.AVSession.setExtras({ requireAbilityList: ['url-cast'] }).catch((err: BusinessError) => {
        Logger.error(TAG, `setExtras failed: ${err.message}`);
      });
    } catch (e) {
      Logger.error(TAG, 'AVSession create/activate failed');
      return;
    }
    // [StartExclude avsession_controller]
    Logger.info(TAG, `session create successed : sessionId : ${this.AVSession.sessionId}`);
    await this.setAVMetadata();
    this.setLaunchAbility();
    // 单一保活入口：AVSession 与 AudioRendererController 同时就绪才注册监听，
    // 解决两者异步初始化顺序导致的竞态（此前任一未就绪都会跳过注册，控制中心无法控制播放）。
    this.ensureListenersRegistered();
    if (this.musicIndex !== undefined && this.songList[this.musicIndex]) {
      this.getAndUpdateFavoriteState(this.songList[this.musicIndex].id.toString());
    }
    // [EndExclude avsession_controller]
  }

  /**
   * 绑定播放控制器。AVSessionController 在 AudioRendererController 构造期间被创建，
   * 而后者此时尚未写入 AppStorage，故不能在 initAVSession 中依赖它。
   * 在双向引用就绪后注册控制中心监听，确保系统媒体卡片（通知中心/控制中心）可正常控制播放。
   */
  public bindAudioRendererController(controller: AudioRendererController): void {
    this.audioRendererController = controller;
    this.ensureListenersRegistered();
  }

  /**
   * 单一保活的监听注册入口。仅在 AVSession 与 AudioRendererController 同时就绪后才注册，
   * 并用 listenersRegistered 去重，避免构造顺序（两者异步初始化）导致的竞态。
   */
  private ensureListenersRegistered(): void {
    if (this.listenersRegistered) {
      return;
    }
    if (!this.AVSession || !this.audioRendererController) {
      // 尚缺一方，待另一方就绪时再次调用本方法即可完成注册
      Logger.info(TAG, 'ensureListenersRegistered: waiting for AVSession + audioRendererController');
      return;
    }
    this.listenersRegistered = true;
    this.setListenerForMesFromController();
  }
  // [StartExclude avsession_controller]
  // [Start set_launch_ability]
  private setLaunchAbility() {
    if (!this.context) {
      return;
    }
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITIES,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    try {
      wantAgent.getWantAgent(wantAgentInfo).then((agent) => {
        if (this.AVSession) {
          this.AVSession.setLaunchAbility(agent);
        }
      });
    } catch (e) {
      Logger.error(TAG, 'getWantAgent failed');
    }
  }
  // [End set_launch_ability]
  private getDuration() {
    let duration: number | undefined = AppStorage.get('totalMsTime');
    if (!duration) {
      Logger.error(TAG, 'get duration failed');
      return;
    }
    return duration;
  }

  private getFirst(): boolean | undefined {
    if (!this.audioRendererController) {
      return;
    }
    return this.audioRendererController.getFirst();
  }

  // [Start set_avmetadata]
  public async setAVMetadata() {
    this.musicIndex = AppStorage.get('selectIndex');
    Logger.info(TAG, 'current musicIndex is:' + this.musicIndex);
    if (this.musicIndex === undefined) {
      this.musicIndex = 0;
    }
    try {
      if (this.context) {
        const songItem: SongItem | undefined = this.songList[this.musicIndex];
        if (!songItem) {
          Logger.error(TAG, 'setAVMetadata: current song is undefined');
          return;
        }
        // 封面优先取 CoverCache 命中的 PixelMap（getLabel 已内含缓存回退到默认 Resource），
        // PixelMap 直接用作媒体封面避免重复解码；仅当为 Resource 时才走 resourceManager 解码。
        // 此前整段强制按 Resource 解码，PixelMap 分支会抛错导致整个 setAVMetadata 中断、
        // 系统播控卡片拿不到元数据而无法正常显示。
        let mediaImage: PixelMap | undefined = undefined;
        const label: Resource | PixelMap = songItem.getLabel();
        if (label && typeof (label as PixelMap).getImageInfo === 'function') {
          mediaImage = label as PixelMap;
        } else if (label) {
          try {
            mediaImage = await MediaTools.getPixelMapFromResource(this.context, label as resourceManager.Resource);
          } catch (e) {
            Logger.error(TAG, 'getPixelMapFromResource failed');
          }
        }
        // 收藏以 song.id 为稳定主键（队列索引会漂移），与 MusicStore 收藏存储保持一致
        let metadata: avSession.AVMetadata = {
          assetId: `${songItem.id}`,
          title: songItem.title,
          artist: songItem.singer,
          mediaImage: mediaImage,
          duration: this.getDuration(),
        };
        let lrc = await MediaTools.getLrcFromRawFile(this.context, songItem.lyric);
        if (!lrc) {
          lrc = await EmbeddedLyricReader.read(songItem.src);
        }
        if (lrc) {
          metadata.lyric = lrc;
        }
        if (this.AVSession) {
          this.AVSession.setAVMetadata(metadata).then(() => {
            Logger.info(TAG, 'SetAVMetadata successfully');
          }).catch((err: BusinessError) => {
            Logger.error(TAG, `SetAVMetadata BusinessError: code: ${err.code}, message: ${err.message}`);
          });
        }
      }
    } catch (error) {
      Logger.error(TAG, `SetAVMetadata try: code: ${(error as BusinessError).code}`);
    }
    // 投播中切歌：重新投播新曲目（startPosition 归零，从曲首开始）
    if (this.isCasting) {
      this.castCurrentSong(0);
    }
    // 同步推送桌面卡片状态
    this.pushFormUpdate();
  }
  // [End set_avmetadata]

  // [Start set_listener_for_mes_from_controller]
  async setListenerForMesFromController() {
    if (!this.AVSession) {
      return;
    }
    try {
      this.AVSession.on('play', this.onPlay);
      this.AVSession.on('pause', this.onPause);
      this.AVSession.on('playNext', this.onPlayNext);
      this.AVSession.on('playPrevious', this.onPlayPrevious);
      this.AVSession.on('seek', this.onSeek);
      this.AVSession.on('setLoopMode', this.onSetLoopMode);
      this.AVSession.on('toggleFavorite', this.onToggleFavorite);
      // 投播设备连接状态：远端设备连上 -> 开始投播；断开 -> 结束投播切回本地
      this.AVSession.on('outputDeviceChange', this.onOutputDeviceChange);
    } catch (e) {
      Logger.error(TAG, 'setListenerForMesFromController failed');
    }
  }
  // [End set_listener_for_mes_from_controller]
  private onPlay: () => void = () => {
    Logger.info(TAG, `on play , do play task`);
    if (this.isCasting && this.castController) {
      // 投播态：控制远端设备播放
      this.castController.sendControlCommand({ command: 'play' }).catch((err: BusinessError) => {
        Logger.error(TAG, `cast sendControlCommand play failed: ${err.message}`);
      });
      this.setPlayState(true);
      return;
    }
    if (!this.audioRendererController) {
      Logger.error(TAG, 'audioRendererController is undefined in onPlay');
      return;
    }
    if (this.getFirst()) {
      this.audioRendererController.play();
    } else {
      this.audioRendererController.start();
    }
  }

  private onPause: () => void = () => {
    Logger.info(TAG, `on pause , do pause task`);
    if (this.isCasting && this.castController) {
      // 投播态：控制远端设备暂停
      this.castController.sendControlCommand({ command: 'pause' }).catch((err: BusinessError) => {
        Logger.error(TAG, `cast sendControlCommand pause failed: ${err.message}`);
      });
      this.setPlayState(false);
      return;
    }
    if (!this.audioRendererController) {
      Logger.error(TAG, 'audioRendererController is undefined in onPause');
      return;
    }
    this.audioRendererController.pause();
  }

  private onPlayNext: () => void = () => {
    Logger.info(TAG, `on playNext , do playNext task`);
    if (!this.audioRendererController) {
      Logger.error(TAG, 'audioRendererController is undefined in onPlayNext');
      return;
    }
    this.audioRendererController.playNext();
  }

  private onPlayPrevious: () => void = () => {
    Logger.info(TAG, `on playPrevious , do playPrevious task`);
    if (!this.audioRendererController) {
      Logger.error(TAG, 'audioRendererController is undefined in onPlayPrevious')
      return;
    }
    this.audioRendererController.playPrevious();
  }

  private onSeek: (curMs: number) => void = (curMs: number) => {
    Logger.info(TAG, `on seek , do seek task`);
    if (this.isCasting && this.castController) {
      // 投播态：控制远端设备跳转进度
      this.castController.sendControlCommand({ command: 'seek', parameter: curMs }).catch((err: BusinessError) => {
        Logger.error(TAG, `cast sendControlCommand seek failed: ${err.message}`);
      });
      this.setProgressState(curMs);
      return;
    }
    if (!this.audioRendererController) {
      Logger.error(TAG, 'audioRendererController is undefined in onSeek');
      return;
    }
    this.audioRendererController.seek(curMs);
  }
  // [Start set_loop_mode_call]
  private onSetLoopMode: (loopMode: avSession.LoopMode) => void = (loopMode: avSession.LoopMode) => {
    Logger.info(TAG, `on setLoopMode , do loopMode task`);
    if (!this.audioRendererController) {
      Logger.error(TAG, 'audioRendererController is undefined in onSetLoopMode');
      return;
    }
    switch (loopMode) {
      case avSession.LoopMode.LOOP_MODE_SINGLE:
        this.audioRendererController.setPlayModel(MusicPlayMode.ORDER);
        break;
      case avSession.LoopMode.LOOP_MODE_SEQUENCE:
        this.audioRendererController.setPlayModel(MusicPlayMode.RANDOM);
        break;
      case avSession.LoopMode.LOOP_MODE_SHUFFLE:
        this.audioRendererController.setPlayModel(MusicPlayMode.SINGLE_CYCLE);
        break;
      default:
        break;
    }
    this.setPlayModeToAVSession();
    this.setPlayModeToControlArea();
  }
  // [End set_loop_mode_call]
  private onToggleFavorite: (assetId: string) => void = (assetId: string) => {
    Logger.info(TAG, `on toggleFavorite , do toggleFavorite task`);
    this.updateFavoriteState(assetId);
  }

  // [StartExclude cast_support]
  /**
   * 投播设备连接状态回调。
   * 远端设备（局域网/Cast+/DLNA）连接成功 -> 开始投播并暂停本地出声；
   * 设备断开或非远端输出 -> 结束投播并恢复本地播放。
   */
  private onOutputDeviceChange: (state: avSession.ConnectionState, device: avSession.OutputDeviceInfo) => void =
    (state: avSession.ConnectionState, device: avSession.OutputDeviceInfo) => {
      let currentDevice: avSession.DeviceInfo | undefined = device?.devices?.[0];
      if (currentDevice && currentDevice.castCategory === avSession.AVCastCategory.CATEGORY_REMOTE
        && state === avSession.ConnectionState.STATE_CONNECTED) {
        Logger.info(TAG, `cast device connected: ${currentDevice.deviceName}`);
        this.startCast(currentDevice);
      } else if (this.isCasting) {
        Logger.info(TAG, 'cast device disconnected or switched to local output, stopping cast');
        this.stopCast();
      }
    };

  /**
   * 开始投播：获取投播控制器，暂停本地出声，把当前曲目以 fdSrc 形式投到远端设备。
   */
  private async startCast(device: avSession.DeviceInfo): Promise<void> {
    if (this.isCasting || !this.AVSession) {
      return;
    }
    try {
      this.castController = await this.AVSession.getAVCastController();
    } catch (err) {
      Logger.error(TAG, `getAVCastController failed: ${(err as BusinessError).message}`);
      return;
    }
    this.isCasting = true;
    if (this.audioRendererController) {
      this.audioRendererController.setCastActive(true); // 投播期间本地保持静音
      await this.audioRendererController.pause();
    }
    this.setPlayState(true); // 控制中心展示为“播放中（投播）”
    try {
      // 监听远端播放状态变化，回写进度以便断连后本地续播对齐
      this.castController?.on('playbackStateChange', 'all', this.onCastPlaybackStateChange);
      // 远端设备发起的下一首/上一首
      this.castController?.on('playNext', this.onPlayNext);
      this.castController?.on('playPrevious', this.onPlayPrevious);
    } catch (err) {
      Logger.error(TAG, `cast on listeners failed: ${(err as BusinessError).message}`);
    }
    await this.castCurrentSong();
  }

  /**
   * 结束投播：停止远端、注销监听、关闭独立 fd，恢复本地播放并对齐远端进度。
   */
  private async stopCast(): Promise<void> {
    if (!this.isCasting) {
      return;
    }
    this.isCasting = false;
    try {
      this.castController?.off('playbackStateChange', this.onCastPlaybackStateChange);
      // AVCastController.off 的类型重载未暴露 playNext/playPrevious，但运行时支持注销；
      // 经 ESObject 透传以绕过编译期 overload 不匹配报错。
      (this.castController as ESObject)?.off('playNext', this.onPlayNext);
      (this.castController as ESObject)?.off('playPrevious', this.onPlayPrevious);
    } catch (err) {
      Logger.error(TAG, `cast off listeners failed: ${(err as BusinessError).message}`);
    }
    try {
      await this.castController?.sendControlCommand({ command: 'stop' });
    } catch (err) {
      Logger.error(TAG, `cast stop command failed: ${(err as BusinessError).message}`);
    }
    this.castController = undefined;
    if (this.castFile) {
      try {
        fileIo.closeSync(this.castFile.fd);
      } catch (e) {
      }
      this.castFile = undefined;
    }
    if (this.audioRendererController) {
      this.audioRendererController.setCastActive(false);
      // 本地此前处于 pause，直接 resume 即可从原进度续播
      await this.audioRendererController.start();
      if (this.castRemotePositionMs > 0) {
        this.audioRendererController.seek(this.castRemotePositionMs);
      }
    }
    this.castRemotePositionMs = 0;
  }

  /**
   * 把“当前曲目”以独立 fd 投到远端设备。切歌（setAVMetadata）时也会调用以重新投播。
   * @param startPositionOverride 指定投播起始进度（ms）；切歌时传 0，初始投播不传则用本地当前进度。
   */
  private async castCurrentSong(startPositionOverride?: number): Promise<void> {
    if (!this.castController) {
      return;
    }
    const song: SongItem | undefined = this.audioRendererController?.getCurrentSong();
    if (!song) {
      Logger.error(TAG, 'castCurrentSong: current song is undefined');
      return;
    }
    // 关闭上一个投播 fd，避免泄漏（与本地播放 curFile 解耦，独立开 fd）
    if (this.castFile) {
      try {
        fileIo.closeSync(this.castFile.fd);
      } catch (e) {
      }
      this.castFile = undefined;
    }
    let file: fileIo.File;
    try {
      file = fileIo.openSync(song.src, fileIo.OpenMode.READ_ONLY);
    } catch (err) {
      Logger.errorPrivate(TAG, `cast open file failed: ${song.src}`);
      return;
    }
    this.castFile = file;
    const position: number = startPositionOverride ?? this.audioRendererController?.getCurrentPosition() ?? 0;
    const duration: number = this.audioRendererController?.getDuration() ?? 0;
    const playItem: avSession.AVQueueItem = {
      itemId: 0,
      description: {
        assetId: (song?.id ?? this.musicIndex ?? 0).toString(),
        title: song.title,
        artist: song.singer,
        mediaType: 'AUDIO',
        fdSrc: { fd: file.fd },
        startPosition: position,
        duration: duration,
        albumTitle: song.title,
        appName: 'Lumio Music'
      }
    };
    try {
      await this.castController.prepare(playItem);
      await this.castController.start(playItem);
      Logger.infoPrivate(TAG, `cast started: ${song.title}`);
    } catch (err) {
      Logger.error(TAG, `cast prepare/start failed: ${(err as BusinessError).message}`);
    }
  }

  /**
   * 远端播放状态变化：回写进度，用于断连后本地续播对齐。
   */
  private onCastPlaybackStateChange: (state: avSession.AVPlaybackState) => void = (state: avSession.AVPlaybackState) => {
    if (state?.position?.elapsedTime !== undefined) {
      this.castRemotePositionMs = state.position.elapsedTime;
      this.setProgressState(state.position.elapsedTime);
    }
  }
  // [EndExclude cast_support]

  private setPlayModeToControlArea() {
    if (!this.audioRendererController) {
      Logger.error(TAG, 'audioRendererController is undefined in setPlayModeToAVSession');
      return;
    }
    let currentPlayMode: MusicPlayMode = this.audioRendererController.getPlayMode();
    AppStorage.setOrCreate('playMode', currentPlayMode);
  }

  public setPlayModeToAVSession() {
    if (!this.audioRendererController) {
      Logger.error(TAG, 'audioRendererController is undefined in setPlayModeToAVSession');
      return;
    }
    let currentPlayMode: MusicPlayMode = this.audioRendererController.getPlayMode();
    let AVSessionLoopMode: avSession.LoopMode | undefined = undefined;
    switch (currentPlayMode) {
      case MusicPlayMode.SINGLE_CYCLE:
        AVSessionLoopMode = avSession.LoopMode.LOOP_MODE_SINGLE;
        break;
      case MusicPlayMode.ORDER:
        AVSessionLoopMode = avSession.LoopMode.LOOP_MODE_SEQUENCE;
        break;
      case MusicPlayMode.RANDOM:
        AVSessionLoopMode = avSession.LoopMode.LOOP_MODE_SHUFFLE;
        break;
      default:
        break;
    }
    if (AVSessionLoopMode !== undefined) {
      this.setLoopModeState(AVSessionLoopMode)
    }
  }
  // [Start set_favorite_state]
  private setFavoriteState(isFavorite: boolean) {
    if (this.AVSession) {
      this.AVSession.setAVPlaybackState({ isFavorite }, (err: BusinessError) => {
        if (err) {
          Logger.error(TAG, `SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
        } else {
          Logger.info(TAG, 'SetAVPlaybackState successfully');
        }
      });
    }
  }

  public setProgressState(ms: number) {
    if (this.AVSession) {
      this.AVSession.setAVPlaybackState({
        position: {
          elapsedTime: ms,
          updateTime: new Date().getTime()
        }
      }, (err: BusinessError) => {
        if (err) {
          Logger.error(TAG, `SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
        } else {
          Logger.info(TAG, 'SetAVPlaybackState successfully');
        }
      });
    }
  }

  public setPlayState(isPlay: boolean) {
    if (this.AVSession) {
      this.AVSession.setAVPlaybackState({
        state: isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      }, (err: BusinessError) => {
        if (err) {
          Logger.error(TAG, `SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
        } else {
          Logger.info(TAG, 'SetAVPlaybackState successfully');
        }
      });
    }
    // 同步推送桌面卡片状态
    this.pushFormUpdate();
  }

  // [StartExclude form_card]
  /**
   * 向所有已添加的桌面卡片推送当前播放状态（标题/艺术家/专辑/时长/是否播放中）。
   * 由 setAVMetadata / setPlayState 触发；卡片进程与主应用独立，经 formProvider 跨进程更新。
   */
  public pushFormUpdate(): void {
    if (!this.context) {
      return;
    }
    let song: SongItem | undefined = this.songList[this.musicIndex ?? -1];
    let title: string = song?.title ?? '';
    let artist: string = song?.singer ?? '';
    let album: string = song?.album ?? '';
    let isPlaying: boolean = (AppStorage.get('isPlay') as boolean) ?? false;
    let duration: number = this.getDuration() ?? 0;
    PreferencesUtil.getInstance().getFormIds(this.context)
      .then((formIds: Array<string>) => {
        formIds.forEach((formId: string) => {
          // 仅处理真实桌面卡片 ID；跳过空串与误混入的静音标记等非法项，避免误调 updateForm
          if (!formId || formId === SILENT_ID) {
            return;
          }
          formProvider.updateForm(formId, formBindingData.createFormBindingData({
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            isPlaying: isPlaying
          }))
            .catch((err: BusinessError) => {
              Logger.error(TAG, `pushFormUpdate updateForm failed: ${err.message}`);
            });
        });
      })
      .catch((err: BusinessError) => {
        Logger.error(TAG, `pushFormUpdate getFormIds failed: ${err.message}`);
      });
  }

  /**
   * 供桌面卡片（FormAbility.onFormEvent）跨进程回控播放。
   * @param cmd 'play' | 'pause' | 'next' | 'prev'
   */
  public remoteControl(cmd: string): void {
    Logger.info(TAG, `remoteControl: ${cmd}`);
    switch (cmd) {
      case 'play':
        this.onPlay();
        break;
      case 'pause':
        this.onPause();
        break;
      case 'next':
        this.onPlayNext();
        break;
      case 'prev':
        this.onPlayPrevious();
        break;
      default:
        Logger.error(TAG, `remoteControl unknown cmd: ${cmd}`);
        break;
    }
  }
  // [EndExclude form_card]

  // [StartExclude set_lock_screen]
  /**
   * 联动设置项「锁屏/状态栏控制」：
   * 开启 -> 激活 AVSession，在锁屏与通知中心展示媒体控制卡片；
   * 关闭 -> 停用 AVSession，隐藏系统媒体控制。
   */
  public setLockScreenControl(enabled: boolean): void {
    if (!this.AVSession) {
      return;
    }
    try {
      if (enabled) {
        this.AVSession.activate().catch((err: BusinessError) => {
          Logger.error(TAG, `AVSession activate failed: ${err.message}`);
        });
      } else {
        this.AVSession.deactivate().catch((err: BusinessError) => {
          Logger.error(TAG, `AVSession deactivate failed: ${err.message}`);
        });
      }
    } catch (e) {
      Logger.error(TAG, 'setLockScreenControl failed');
    }
  }
  // [EndExclude set_lock_screen]

  // [StartExclude set_favorite_state]
  /**
   * 收藏状态统一收口到 MusicStore（按 song.id）。
   * 此前收藏误写入 PreferencesUtil.myStore 的 formIds 键（与桌面卡片 formId、静音标记混用），
   * 导致与 Favorites 页（读 MusicStore）数据割裂；此处改为唯一权威存储。
   * @param assetId 当前歌曲 id（字符串）
   */
  public async updateFavoriteState(assetId: string): Promise<void> {
    const songId: number = Number(assetId);
    if (isNaN(songId)) {
      Logger.error(TAG, `updateFavoriteState invalid assetId: ${assetId}`);
      return;
    }
    const store: MusicStore = MusicStore.getInstance();
    store.toggleFavorite(songId);
    const isFav: boolean = store.isFavorite(songId);
    AppStorage.setOrCreate('isFavorite', isFav);
    this.setFavoriteState(isFav);
  }

  public async getAndUpdateFavoriteState(assetId: string): Promise<void> {
    const songId: number = Number(assetId);
    const isFavorite: boolean = !isNaN(songId) && MusicStore.getInstance().isFavorite(songId);
    AppStorage.setOrCreate('isFavorite', isFavorite);
    this.setFavoriteState(isFavorite);
  }

  // [EndExclude set_favorite_state]
  public async setLoopModeState(AVSessionLoopMode: avSession.LoopMode) {
    if (this.AVSession) {
      this.AVSession.setAVPlaybackState({ loopMode: AVSessionLoopMode }, (err: BusinessError) => {
        if (err) {
          Logger.error(TAG, `SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
        } else {
          Logger.info(TAG, 'SetAVPlaybackState successfully');
        }
      });
    }
  }

  // [End set_favorite_state]
  async unregisterSessionListener() {
    if (!this.AVSession) {
      return;
    }
    try {
      this.AVSession.off('play');
      this.AVSession.off('pause');
      this.AVSession.off('playNext');
      this.AVSession.off('playPrevious');
      this.AVSession.off('setLoopMode');
      this.AVSession.off('seek');
      this.AVSession.off('toggleFavorite');
      this.AVSession.off('outputDeviceChange', this.onOutputDeviceChange);
    } catch (e) {
      Logger.error(TAG, 'unregisterSessionListener failed');
    }
    // 退出时若仍在投播，释放投播资源
    if (this.isCasting) {
      this.stopCast();
    }
  }
  // [EndExclude avsession_controller]
}
// [End avsession_controller]