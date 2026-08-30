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

import { AudioRendererController } from './AudioRendererController';
import { Logger } from './Logger';

/**
 * 睡眠定时：到点自动暂停播放。基于 setTimeout，纯本地、无后台长驻。
 * 仅管理计时与到期动作，具体 UI（剩余时间提示）由播放页控件消费 getRemainingMs。
 */
export class SleepTimer {
  private static instance: SleepTimer | null = null;
  private timer: number = -1;
  private endTime: number = 0;
  /** 播完当前曲后停止模式：不计时，监听播放完成回调触发暂停。 */
  private endOfSongMode: boolean = false;

  static getInstance(): SleepTimer {
    if (!SleepTimer.instance) {
      SleepTimer.instance = new SleepTimer();
    }
    return SleepTimer.instance;
  }

  start(minutes: number, onExpire?: () => void): void {
    this.cancelTimer();
    this.endOfSongMode = false;
    if (minutes <= 0) {
      return;
    }
    this.endTime = new Date().getTime() + minutes * 60 * 1000;
    this.timer = setTimeout(() => {
      Logger.info('SleepTimer', 'expired, pausing playback');
      AudioRendererController.getInstance().pause();
      if (onExpire) {
        onExpire();
      }
      this.timer = -1;
      this.endTime = 0;
    }, minutes * 60 * 1000) as number;
  }

  /**
   * 播完当前曲后停止：进入该模式后，播放器在自然界线（onPlaybackCompleted）暂停，
   * 不再自动续播下一首。计时器与 end-of-song 模式互斥。
   */
  startEndOfSong(onExpire?: () => void): void {
    this.cancelTimer();
    this.endOfSongMode = true;
    if (onExpire) {
      onExpire();
    }
  }

  /** 当前是否处于「播完当前曲后停止」模式。由 AudioRendererController.onPlaybackCompleted 读取。 */
  isEndOfSong(): boolean {
    return this.endOfSongMode;
  }

  cancel(): void {
    this.cancelTimer();
    this.endOfSongMode = false;
  }

  private cancelTimer(): void {
    if (this.timer >= 0) {
      clearTimeout(this.timer);
      this.timer = -1;
    }
    this.endTime = 0;
  }

  getRemainingMs(): number {
    if (this.endTime <= 0) {
      return 0;
    }
    return Math.max(0, this.endTime - new Date().getTime());
  }

  isActive(): boolean {
    return this.timer >= 0 || this.endOfSongMode;
  }
}
