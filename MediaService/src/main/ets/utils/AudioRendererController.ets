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
import { MusicPlayMode, SILENT_ID } from '../songdatacontroller/PlayerData';
import { SongItem } from '../songdatacontroller/SongData';
import { BackgroundUtil } from './BackgroundUtil';
import { MediaTools } from './MediaTools';
import { Logger } from './Logger';
import { PreferencesUtil } from './PreferencesUtil';

const TAG = 'AudioRendererController';

export class AudioRendererController {
  public avPlayer?: media.AVPlayer;
  private context: common.UIAbilityContext | undefined = AppStorage.get('context');
  private songItemBuilder: SongItemBuilder = new SongItemBuilder();
  private playMode: MusicPlayMode = MusicPlayMode.ORDER;
  private isFirst: boolean = true;
  private musicIndex: number = 0;
  private songList: SongItem[] = [];
  private curMs: number = 0;
  private avSessionController: AVSessionController | undefined = undefined;
  private duration: number = 0;

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

  private async initAVPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      this.setAVPlayerCallbacks();
      Logger.info(TAG, 'createAVPlayer succeeded');
    } catch (err: BusinessError) {
      Logger.error(TAG, `createAVPlayer failed: ${err.code} - ${err.message}`);
    }
  }

  private setAVPlayerCallbacks(): void {
    if (!this.avPlayer) {
      return;
    }
    this.setAvSessionCallback();

    this.avPlayer.on('stateChange', (state: string) => {
      Logger.info(TAG, 'AVPlayer stateChange: ' + state);
      if (state === 'playing') {
        this.updateIsPlay(true);
      } else if (state === 'paused') {
        this.updateIsPlay(false);
      } else if (state === 'completed') {
        this.playNext();
      } else if (state === 'stopped') {
        this.updateIsPlay(false);
      }
    });

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.curMs = time;
      AppStorage.setOrCreate('progress', time);
      AppStorage.setOrCreate('currentTime', MediaTools.msToCountdownTime(time));
      if (this.avSessionController) {
        this.avSessionController.setProgressState(time);
      }
    });

    this.avPlayer.on('durationUpdate', (dur: number) => {
      this.duration = dur;
      AppStorage.setOrCreate('totalTime', MediaTools.msToCountdownTime(dur));
      AppStorage.setOrCreate('totalMsTime', dur);
      AppStorage.setOrCreate('progressMax', dur);
    });

    this.avPlayer.on('error', (err: BusinessError) => {
      Logger.error(TAG, `AVPlayer error: ${err.code} - ${err.message}`);
    });
  }

  private setAvSessionCallback(): void {
    this.avSessionController = AVSessionController.getInstance();
  }

  public async setSilentModeAndMixWithOthers(isSupportSilent: boolean = false): Promise<void> {
    if (!this.context) {
      return;
    }
    let formIds: string[] = await PreferencesUtil.getInstance().getFormIds(this.context);
    if (isSupportSilent) {
      if (!formIds.includes(SILENT_ID)) {
        await PreferencesUtil.getInstance().addFormId(this.context, SILENT_ID);
      }
    } else {
      if (formIds.includes(SILENT_ID)) {
        await PreferencesUtil.getInstance().removeFormId(this.context, SILENT_ID);
      }
    }
    AppStorage.setOrCreate('isSilentMode', isSupportSilent);
  }

  public async play(musicIndex: number = this.musicIndex): Promise<void> {
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
    await this.loadAndPlay();
  }

  private async loadAndPlay(): Promise<void> {
    if (!this.avPlayer) {
      return;
    }
    try {
      await this.avPlayer.stop();
    } catch (e: BusinessError) {
    }
    try {
      await this.avPlayer.reset();
    } catch (e: BusinessError) {
    }

    const song: SongItem | undefined = this.songList[this.musicIndex];
    if (!song) {
      Logger.error(TAG, 'song is undefined at index: ' + this.musicIndex);
      return;
    }

    try {
      const file: fileIo.File = fileIo.openSync(song.src, fileIo.OpenMode.READ_ONLY);
      this.avPlayer.fdSrc = { fd: file.fd };
      Logger.info(TAG, 'Playing: ' + song.title + ' from ' + song.src);
    } catch (e: BusinessError) {
      Logger.error(TAG, 'Failed to open file: ' + song.src);
    }
  }

  public getFirst(): boolean {
    return this.isFirst;
  }

  public setPlayModel(playMode: MusicPlayMode): void {
    this.playMode = playMode;
    if (!this.avSessionController) {
      return;
    }
    this.avSessionController.setPlayModeToAVSession();
    Logger.info(TAG, 'setPlayModel mode: ' + this.playMode);
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
      } catch (e: BusinessError) {
        Logger.error(TAG, 'start failed');
      }
    }
  }

  public async pause(): Promise<void> {
    if (this.avPlayer) {
      try {
        await this.avPlayer.pause();
        this.updateIsPlay(false);
        Logger.info(TAG, 'pause success');
      } catch (e: BusinessError) {
        Logger.error(TAG, 'pause failed');
      }
    }
  }

  public seek(ms: number): void {
    if (this.avPlayer) {
      this.curMs = ms;
      AppStorage.setOrCreate('progress', ms);
      AppStorage.setOrCreate('currentTime', MediaTools.msToCountdownTime(ms));
      try {
        this.avPlayer.seek(ms, media.SeekMode.SEEK_CLOSEST);
      } catch (e: BusinessError) {
        Logger.error(TAG, 'seek failed');
      }
      if (this.avSessionController) {
        this.avSessionController.setProgressState(ms);
      }
    }
  }

  public async playNext(): Promise<void> {
    Logger.info(TAG, 'playNext Index:' + this.musicIndex + ', length-1:' + (this.songList.length - 1));
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
    if (this.avPlayer) {
      try {
        await this.avPlayer.stop();
        this.curMs = 0;
        this.updateIsPlay(false);
        AppStorage.setOrCreate('currentTime', "00:00");
        AppStorage.setOrCreate('progress', 0);
        Logger.info(TAG, 'stop success');
      } catch (e: BusinessError) {
        Logger.error(TAG, 'stop failed');
      }
    }
  }

  public async release(): Promise<void> {
    if (this.avPlayer && this.context) {
      try {
        await this.avPlayer.release();
        this.avSessionController?.unregisterSessionListener();
        BackgroundUtil.stopContinuousTask(this.context);
        Logger.info(TAG, 'release success');
      } catch (e: BusinessError) {
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
    this.avSessionController.getAndUpdateFavoriteState(this.musicIndex.toString());
  }
}
