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

import { image } from '@kit.ImageKit';
import { CoverCache } from '../utils/CoverCache';

/** 音质分级：用于列表/播放页徽标展示。 */
export type AudioQuality = 'unknown' | 'lossy' | 'lossless' | 'hires';

/**
 * Music information entity class.
 * Single source of truth for SongItem across the project.
 */
export class SongItem {
  id: number = 0;
  title: string = '';
  singer: string = '';
  album: string = '';
  author: string = '';
  /** 发行年份（4 位字符串，如 "2019"；未解析到时为空串）。与 AudioMeta.year 类型一致。 */
  year: string = '';
  mark: Resource | undefined = undefined;
  label: Resource | undefined = undefined;
  src: string = '';
  index: number = 0;
  lyric: string = '';
  isDarkBackground: boolean = false;
  /** 采样率（Hz），如 44100 / 48000 / 96000；无数据时 0。 */
  sampleRate: number = 0;
  /** 位深（bit），如 16 / 24；损耗编码（MP3/AAC）为 0 表示不适用。 */
  bitDepth: number = 0;
  /** 容器/编码：flac / mp3 / m4a / alac / wav 等；无数据时空串。 */
  codec: string = '';
  /** 来源文件夹名（导入时从 picker URI 的父目录解析，如「周杰伦」）；空串表示未归类（归入「导入音乐」）。 */
  folder: string = '';

  /** 音质分级：无损(flac/wav/alac) / Hi-Res(位深≥24 或 采样率≥96k) / 损耗(mp3/aac) / 未知。 */
  getQuality(): AudioQuality {
    const lossless: boolean = this.codec === 'flac' || this.codec === 'wav' || this.codec === 'alac';
    const lossy: boolean = this.codec === 'mp3' || this.codec === 'm4a' || this.codec === 'aac';
    if (this.bitDepth >= 24 || this.sampleRate >= 96000) {
      return 'hires';
    }
    if (lossless) {
      return 'lossless';
    }
    if (lossy) {
      return 'lossy';
    }
    return 'unknown';
  }

  getMark(): Resource | image.PixelMap {
    return CoverCache.getInstance().get(this.src) ?? this.mark ?? $r('app.media.ic_default_cover');
  }

  getLabel(): Resource | image.PixelMap {
    return CoverCache.getInstance().get(this.src) ?? this.label ?? $r('app.media.ic_default_cover');
  }
}

export type RepeatMode = 'single' | 'list' | 'random'

export interface Playlist {
  id: string
  name: string
  songIds: number[]
  coverUri?: string
}
