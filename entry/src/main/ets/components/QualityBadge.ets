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

import { AudioQuality } from '../models/music';

/**
 * 音质徽标：仅对无损(flac/wav/alac)与 Hi-Res(位深≥24 或 采样率≥96k)显示，
 * 苹果风细边框小标签。损耗编码(mp3/aac)与未知规格不展示，避免列表杂乱。
 */
@Component
export struct QualityBadge {
  @Prop quality: AudioQuality = 'unknown';

  build() {
    if (this.quality === 'lossless' || this.quality === 'hires') {
      Text(this.quality === 'hires' ? 'Hi-Res' : '无损')
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FA2759')
        .border({ width: 1, color: 'rgba(250, 39, 89, 0.5)' })
        .borderRadius(4)
        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
    } else {
      Row() {
      }
      .width(0)
      .height(0)
    }
  }
}
