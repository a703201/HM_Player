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

#pragma once

#include <string>

struct AudioMetadata {
    std::string title;
    std::string artist;
    std::string album;
    std::string year;   // 年代（4 位年份，从 DATE / TYER / TDRC / ©day 提取）
    int durationMs;
    int sampleRate;
    int channels;
    int bitDepth;       // 位深（FLAC/WAV/ALAC 真实值；MP3/AAC 等损耗编码为 0 表示不适用）
    std::string codec;  // 容器/编码：flac / mp3 / m4a / alac / wav 等，用于无损/Hi-Res 判定
};

AudioMetadata parseAudioMetadata(const std::string& filePath);
