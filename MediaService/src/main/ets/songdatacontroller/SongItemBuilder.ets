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
import { resourceManager } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { SongItem } from './SongData';
import { Logger } from '../utils/Logger';

export default class SongItemBuilder {
  private context: common.UIAbilityContext | undefined = AppStorage.get('context');
  private rawFileDescriptor?: resourceManager.RawFileDescriptor;
  private songItem: SongItem | null = null;
  private fileFd: number = -1;

  public async build(songItem: SongItem): Promise<SongItem> {
    this.songItem = songItem;
    if (!this.context) {
      return this.songItem;
    }
    this.releaseFileFd();
    if (this.isFilePath(songItem.src)) {
      try {
        const file = fileIo.openSync(songItem.src, fileIo.OpenMode.READ_ONLY);
        this.fileFd = file.fd;
        const stat = fileIo.statSync(songItem.src);
        this.rawFileDescriptor = {
          fd: file.fd,
          offset: 0,
          length: stat.size
        };
        Logger.info('SongItemBuilder', 'Opened file path: ' + songItem.src + ', size: ' + stat.size);
      } catch (e: BusinessError) {
        Logger.error('SongItemBuilder', 'Failed to open file: ' + songItem.src);
      }
    } else {
      let rawFileDescriptor = await this.context.resourceManager.getRawFd(songItem.src)
        .catch((error: BusinessError) => {
          Logger.error(`resourceManager error code ${error.code} message ${error.message}`);
        })
      if (rawFileDescriptor) {
        this.rawFileDescriptor = rawFileDescriptor;
      }
      Logger.info('MediaAssetBuilder build rawFileDescriptor:' + this.rawFileDescriptor);
    }
    return this.songItem;
  }

  private isFilePath(src: string): boolean {
    return src.startsWith('/') || src.startsWith('file://') || src.startsWith('internal://');
  }

  public getRawFileDescriptor(): resourceManager.RawFileDescriptor | undefined {
    Logger.info(`rawFileDescriptor: ${this.rawFileDescriptor}`);
    return this.rawFileDescriptor;
  }

  private releaseFileFd(): void {
    if (this.fileFd >= 0) {
      try {
        fileIo.closeSync(this.fileFd);
      } catch (e: BusinessError) {
      }
      this.fileFd = -1;
    }
    this.rawFileDescriptor = undefined;
  }

  public async release(): Promise<void> {
    this.releaseFileFd();
    if (this.context && this.context !== null && this.songItem !== null && !this.isFilePath(this.songItem.src)) {
      this.context.resourceManager.closeRawFd(this.songItem.src);
    }
    this.songItem = null;
  }
}
