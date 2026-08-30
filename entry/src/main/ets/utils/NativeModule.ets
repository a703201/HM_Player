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

import nativeModule from 'libnative_module.so';

interface AudioMetadata {
  title: string;
  artist: string;
  album: string;
  year: string;
  duration: number;
  sampleRate: number;
  channels: number;
  bitDepth: number;
  codec: string;
}

export class NativeUtils {
  private static instance: NativeUtils | null = null;

  private constructor() {
  }

  static getInstance(): NativeUtils {
    if (!NativeUtils.instance) {
      NativeUtils.instance = new NativeUtils();
    }
    return NativeUtils.instance;
  }

  public add(a: number, b: number): number {
    return nativeModule.add(a, b);
  }

  public parseAudioMetadata(filePath: string): AudioMetadata {
    return nativeModule.parseAudioMetadata(filePath);
  }
}
