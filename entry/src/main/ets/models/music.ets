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
