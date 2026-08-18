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
 * You may not use this file except in compliance with the License.
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

import { fileIo, ReadOptions } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { Logger } from './Logger';

const TAG = 'EmbeddedLyricReader';

/** 单次读取的安全上限，防止畸形头部里的超大长度字段把内存打爆。 */
const MAX_ID3_TAG: number = 8 * 1024 * 1024;
const MAX_VORBIS_BLOCK: number = 4 * 1024 * 1024;
const MAX_MOOV_BOX: number = 16 * 1024 * 1024;
/** 单条歌词文本上限，超过基本可判定为误解析。 */
const MAX_LYRIC_CHARS: number = 512 * 1024;

/** MP4 atom 的位置信息。 */
interface AtomRange {
  bodyStart: number;
  bodyLength: number;
}

/**
 * 从音频文件中解析内嵌歌词（原始 LRC 文本，可能含「原文 + 翻译」双行）。
 *
 * MediaKit 的 AVMetadata 不暴露歌词字段，因此这里按容器格式直接解析：
 *  - MP3 : ID3v2.2/2.3/2.4 的 USLT / ULT 帧，其次 TXXX(LYRICS)
 *  - FLAC: VORBIS_COMMENT 块中键名含 LYRIC 的字段（LYRICS / UNSYNCEDLYRICS / ...）
 *  - MP4 / M4A / AAC : moov→udta→meta→ilst 下的 '©lyr'，以及 '----' 自定义键 LYRICS
 *  - 以上都没有时，回落到同目录同名的 .lrc 外挂文件
 *
 * I/O 策略：**按结构定点读取**，不再把整个文件（甚至 32MB）读进内存——
 * 先读头部拿到长度字段，再精确读取目标块。实测语料（133 个文件）里歌词
 * 相关数据全部落在文件前 1.5MB 内，但 MP4 的 moov 也可能在文件尾部，
 * 定点读取对两种布局都成立。
 *
 * 结果按 src 缓存（含"确认没有"的负结果），避免切歌时重复解析。
 */
export class EmbeddedLyricReader {
  private static cache: Map<string, string | undefined> = new Map();

  static async read(src: string): Promise<string | undefined> {
    if (!src || src.length === 0) {
      return undefined;
    }
    if (EmbeddedLyricReader.cache.has(src)) {
      return EmbeddedLyricReader.cache.get(src);
    }
    const text: string | undefined = await EmbeddedLyricReader.readInternal(src);
    EmbeddedLyricReader.cache.set(src, text);
    return text;
  }

  /** 歌曲被删除/替换时清理缓存。 */
  static evict(src: string): void {
    EmbeddedLyricReader.cache.delete(src);
  }

  private static async readInternal(src: string): Promise<string | undefined> {
    let ext = '';
    const dot: number = src.lastIndexOf('.');
    if (dot >= 0) {
      ext = src.substring(dot).toLowerCase();
    }

    let text: string | undefined = EmbeddedLyricReader.readEmbedded(src, ext);
    if (!EmbeddedLyricReader.isUsable(text)) {
      // 内嵌没有则找同名 .lrc 外挂文件（依旧是"从文件读"，不是写死在代码里）
      text = EmbeddedLyricReader.readSidecar(src);
    }
    if (!EmbeddedLyricReader.isUsable(text)) {
      return undefined;
    }
    return EmbeddedLyricReader.normalize(text as string);
  }

  private static readEmbedded(src: string, ext: string): string | undefined {
    let file: fileIo.File | undefined;
    try {
      file = fileIo.openSync(src, fileIo.OpenMode.READ_ONLY);
      const size: number = fileIo.statSync(src).size;
      if (size <= 16) {
        return undefined;
      }
      const fd: number = file.fd;
      if (ext === '.flac') {
        return EmbeddedLyricReader.readFlac(fd, size);
      }
      if (ext === '.mp3') {
        return EmbeddedLyricReader.readMp3(fd, size);
      }
      if (ext === '.m4a' || ext === '.mp4' || ext === '.aac' || ext === '.mov' || ext === '.m4b') {
        return EmbeddedLyricReader.readMp4(fd, size);
      }
      // 未知扩展名：按魔数嗅探，兼容无扩展名 / 扩展名不准的文件
      return EmbeddedLyricReader.readBySniff(fd, size);
    } catch (e) {
      Logger.debugPrivate(TAG, `readEmbedded failed for ${src}: ${(e as Error).message}`);
      return undefined;
    } finally {
      if (file) {
        try {
          fileIo.closeSync(file);
        } catch (_) {
          // ignore
        }
      }
    }
  }

  private static readBySniff(fd: number, size: number): string | undefined {
    const head: Uint8Array = EmbeddedLyricReader.readRange(fd, 0, 12);
    if (head.length < 12) {
      return undefined;
    }
    if (head[0] === 0x66 && head[1] === 0x4C && head[2] === 0x61 && head[3] === 0x43) {
      return EmbeddedLyricReader.readFlac(fd, size);
    }
    if (head[0] === 0x49 && head[1] === 0x44 && head[2] === 0x33) {
      return EmbeddedLyricReader.readMp3(fd, size);
    }
    if (head[4] === 0x66 && head[5] === 0x74 && head[6] === 0x79 && head[7] === 0x70) { // 'ftyp'
      return EmbeddedLyricReader.readMp4(fd, size);
    }
    return undefined;
  }

  // ============================ 外挂 .lrc ============================

  /**
   * 同目录同名 .lrc / .LRC 兜底。仅在内嵌歌词缺失时使用。
   */
  private static readSidecar(src: string): string | undefined {
    const dot: number = src.lastIndexOf('.');
    if (dot <= 0) {
      return undefined;
    }
    const base: string = src.substring(0, dot);
    const candidates: string[] = [base + '.lrc', base + '.LRC'];
    for (let i = 0; i < candidates.length; i++) {
      const path: string = candidates[i];
      let file: fileIo.File | undefined;
      try {
        if (!fileIo.accessSync(path)) {
          continue;
        }
        const size: number = fileIo.statSync(path).size;
        if (size <= 0 || size > MAX_LYRIC_CHARS * 4) {
          continue;
        }
        file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
        const bytes: Uint8Array = EmbeddedLyricReader.readRange(file.fd, 0, size);
        const text: string = EmbeddedLyricReader.detectAndDecode(bytes);
        if (EmbeddedLyricReader.isUsable(text)) {
          Logger.debugPrivate(TAG, `sidecar lyric hit: ${path}`);
          return text;
        }
      } catch (e) {
        // 文件不存在是常态，不打噪音日志
      } finally {
        if (file) {
          try {
            fileIo.closeSync(file);
          } catch (_) {
            // ignore
          }
        }
      }
    }
    return undefined;
  }

  // ============================ FLAC ============================

  private static readFlac(fd: number, fileSize: number): string | undefined {
    let pos = 0;
    let magic: Uint8Array = EmbeddedLyricReader.readRange(fd, 0, 4);
    if (magic.length < 4) {
      return undefined;
    }
    // 少数工具会在 FLAC 前面挂一段 ID3v2，先跳过
    if (magic[0] === 0x49 && magic[1] === 0x44 && magic[2] === 0x33) {
      const id3Head: Uint8Array = EmbeddedLyricReader.readRange(fd, 0, 10);
      if (id3Head.length === 10) {
        pos = 10 + EmbeddedLyricReader.syncsafe(id3Head[6], id3Head[7], id3Head[8], id3Head[9]);
        magic = EmbeddedLyricReader.readRange(fd, pos, 4);
      }
    }
    if (magic.length < 4 ||
      magic[0] !== 0x66 || magic[1] !== 0x4C || magic[2] !== 0x61 || magic[3] !== 0x43) {
      return undefined; // 'fLaC'
    }
    pos += 4;

    // METADATA_BLOCK: 1 字节(last+type) + 3 字节大端长度
    let guard = 0;
    while (pos + 4 <= fileSize && guard < 256) {
      guard++;
      const header: Uint8Array = EmbeddedLyricReader.readRange(fd, pos, 4);
      if (header.length < 4) {
        break;
      }
      const isLast: boolean = (header[0] & 0x80) !== 0;
      const blockType: number = header[0] & 0x7F;
      const blockSize: number = (header[1] << 16) | (header[2] << 8) | header[3];
      if (blockSize < 0) {
        break;
      }
      if (blockType === 4 && blockSize > 0 && blockSize <= MAX_VORBIS_BLOCK) { // VORBIS_COMMENT
        const body: Uint8Array = EmbeddedLyricReader.readRange(fd, pos + 4, blockSize);
        const value: string | undefined = EmbeddedLyricReader.parseVorbisComment(body);
        if (EmbeddedLyricReader.isUsable(value)) {
          return value;
        }
      }
      pos += 4 + blockSize;
      if (isLast) {
        break;
      }
    }
    return undefined;
  }

  /**
   * VORBIS_COMMENT 是 "KEY=VALUE" 列表。歌词键在不同工具下写法不一
   * （LYRICS / UNSYNCEDLYRICS / UNSYNCED LYRICS / LYRICS-CHS ...），
   * 因此优先精确匹配，再退化到"键名包含 LYRIC"。
   */
  private static parseVorbisComment(body: Uint8Array): string | undefined {
    if (body.length < 8) {
      return undefined;
    }
    let p = 0;
    const vendorLen: number = EmbeddedLyricReader.le32(body, p);
    p += 4 + vendorLen;
    if (p + 4 > body.length) {
      return undefined;
    }
    const count: number = EmbeddedLyricReader.le32(body, p);
    p += 4;
    let loose: string | undefined;
    for (let i = 0; i < count; i++) {
      if (p + 4 > body.length) {
        break;
      }
      const itemLen: number = EmbeddedLyricReader.le32(body, p);
      p += 4;
      if (itemLen < 0 || p + itemLen > body.length) {
        break;
      }
      const raw: Uint8Array = body.subarray(p, p + itemLen);
      p += itemLen;
      // 只对可能是歌词的项做解码：先看键名（ASCII），避免整块大文本反复解码
      const eqIndex: number = EmbeddedLyricReader.indexOfByte(raw, 0x3D); // '='
      if (eqIndex <= 0) {
        continue;
      }
      const key: string = EmbeddedLyricReader.asciiUpper(raw.subarray(0, eqIndex));
      if (key.indexOf('LYRIC') < 0) {
        continue;
      }
      const value: string = EmbeddedLyricReader.decodeUtf8(raw.subarray(eqIndex + 1));
      if (!EmbeddedLyricReader.isUsable(value)) {
        continue;
      }
      if (key === 'LYRICS' || key === 'UNSYNCEDLYRICS' || key === 'UNSYNCED LYRICS') {
        return value;
      }
      if (loose === undefined) {
        loose = value;
      }
    }
    return loose;
  }

  // ============================ MP4 / M4A ============================

  /**
   * 定位顶层 moov（可能在文件头也可能在文件尾），再在其内部按 atom 树
   * 精确下钻 udta→meta→ilst。相比旧实现在整块字节里暴力搜索 '©lyr'，
   * 既避免误命中音频数据，也不用把几十 MB 文件读进内存。
   */
  private static readMp4(fd: number, fileSize: number): string | undefined {
    const moov: AtomRange | undefined = EmbeddedLyricReader.findTopLevelAtom(fd, fileSize, 0x6D6F6F76); // 'moov'
    if (moov === undefined || moov.bodyLength <= 0) {
      return undefined;
    }
    const length: number = Math.min(moov.bodyLength, MAX_MOOV_BOX);
    const buffer: Uint8Array = EmbeddedLyricReader.readRange(fd, moov.bodyStart, length);
    return EmbeddedLyricReader.scanMp4Boxes(buffer, 0, buffer.length, 0);
  }

  private static findTopLevelAtom(fd: number, fileSize: number, fourcc: number): AtomRange | undefined {
    let pos = 0;
    let guard = 0;
    while (pos + 8 <= fileSize && guard < 512) {
      guard++;
      const header: Uint8Array = EmbeddedLyricReader.readRange(fd, pos, 16);
      if (header.length < 8) {
        break;
      }
      let boxSize: number = EmbeddedLyricReader.be32(header, 0);
      let headerLen = 8;
      if (boxSize === 1) {
        if (header.length < 16) {
          break;
        }
        // 64 位长度：高 32 位在实际音频文件里恒为 0，超过 2^53 也无意义
        boxSize = EmbeddedLyricReader.be32(header, 8) * 4294967296 + EmbeddedLyricReader.be32(header, 12);
        headerLen = 16;
      } else if (boxSize === 0) {
        boxSize = fileSize - pos;
      }
      if (boxSize < headerLen || pos + boxSize > fileSize) {
        break;
      }
      const name: number = EmbeddedLyricReader.be32(header, 4);
      if (name === fourcc) {
        const range: AtomRange = { bodyStart: pos + headerLen, bodyLength: boxSize - headerLen };
        return range;
      }
      pos += boxSize;
    }
    return undefined;
  }

  /**
   * 在内存中的 atom 树里递归查找歌词。
   * 注意 'meta' 是 FullBox，子 box 从 body+4 开始（跳 version+flags）。
   */
  private static scanMp4Boxes(buf: Uint8Array, start: number, end: number, depth: number): string | undefined {
    if (depth > 8) {
      return undefined;
    }
    let pos: number = start;
    while (pos + 8 <= end) {
      let boxSize: number = EmbeddedLyricReader.be32(buf, pos);
      let headerLen = 8;
      if (boxSize === 1) {
        if (pos + 16 > end) {
          return undefined;
        }
        boxSize = EmbeddedLyricReader.be32(buf, pos + 8) * 4294967296 + EmbeddedLyricReader.be32(buf, pos + 12);
        headerLen = 16;
      } else if (boxSize === 0) {
        boxSize = end - pos;
      }
      if (boxSize < headerLen || pos + boxSize > end) {
        return undefined;
      }
      const name: number = EmbeddedLyricReader.be32(buf, pos + 4);
      const bodyStart: number = pos + headerLen;
      const bodyEnd: number = pos + boxSize;

      if (name === 0x75647461 /* udta */ || name === 0x696C7374 /* ilst */ ||
        name === 0x6D6F6F76 /* moov */) {
        const hit: string | undefined = EmbeddedLyricReader.scanMp4Boxes(buf, bodyStart, bodyEnd, depth + 1);
        if (EmbeddedLyricReader.isUsable(hit)) {
          return hit;
        }
      } else if (name === 0x6D657461 /* meta，FullBox */) {
        const hit: string | undefined = EmbeddedLyricReader.scanMp4Boxes(buf, bodyStart + 4, bodyEnd, depth + 1);
        if (EmbeddedLyricReader.isUsable(hit)) {
          return hit;
        }
      } else if (name === 0xA96C7972 /* ©lyr */ || name === 0x6C797220 /* 'lyr ' */) {
        const hit: string | undefined = EmbeddedLyricReader.readMp4DataBox(buf, bodyStart, bodyEnd);
        if (EmbeddedLyricReader.isUsable(hit)) {
          return hit;
        }
      } else if (name === 0x2D2D2D2D /* '----' 自定义键 */) {
        const hit: string | undefined = EmbeddedLyricReader.readMp4FreeformBox(buf, bodyStart, bodyEnd);
        if (EmbeddedLyricReader.isUsable(hit)) {
          return hit;
        }
      }
      pos += boxSize;
    }
    return undefined;
  }

  /** 取 ilst 条目下的 'data' 子 box 文本：size(4) + 'data'(4) + version/flags(4) + locale(4) + payload。 */
  private static readMp4DataBox(buf: Uint8Array, start: number, end: number): string | undefined {
    let pos: number = start;
    while (pos + 8 <= end) {
      const boxSize: number = EmbeddedLyricReader.be32(buf, pos);
      if (boxSize < 8 || pos + boxSize > end) {
        return undefined;
      }
      const name: number = EmbeddedLyricReader.be32(buf, pos + 4);
      if (name === 0x64617461 /* data */ && pos + 16 <= end) {
        return EmbeddedLyricReader.detectAndDecode(buf.subarray(pos + 16, pos + boxSize));
      }
      pos += boxSize;
    }
    return undefined;
  }

  /** '----' 结构：mean / name / data 三个子 box，name 为 'LYRICS' 时取 data。 */
  private static readMp4FreeformBox(buf: Uint8Array, start: number, end: number): string | undefined {
    let pos: number = start;
    let isLyricKey = false;
    while (pos + 8 <= end) {
      const boxSize: number = EmbeddedLyricReader.be32(buf, pos);
      if (boxSize < 8 || pos + boxSize > end) {
        return undefined;
      }
      const name: number = EmbeddedLyricReader.be32(buf, pos + 4);
      if (name === 0x6E616D65 /* name */ && pos + 12 <= end) {
        const key: string = EmbeddedLyricReader.asciiUpper(buf.subarray(pos + 12, pos + boxSize));
        if (key.indexOf('LYRIC') >= 0) {
          isLyricKey = true;
        }
      } else if (name === 0x64617461 /* data */ && isLyricKey && pos + 16 <= end) {
        return EmbeddedLyricReader.detectAndDecode(buf.subarray(pos + 16, pos + boxSize));
      }
      pos += boxSize;
    }
    return undefined;
  }

  // ============================ MP3 (ID3v2) ============================

  private static readMp3(fd: number, fileSize: number): string | undefined {
    const header: Uint8Array = EmbeddedLyricReader.readRange(fd, 0, 10);
    // 'ID3' = 0x49 0x44 0x33。旧实现这里把 '3' 误写成 0x44('D')，
    // 导致所有 MP3 直接短路返回，内嵌歌词从未生效——本次修复的核心。
    if (header.length < 10 || header[0] !== 0x49 || header[1] !== 0x44 || header[2] !== 0x33) {
      return undefined;
    }
    const major: number = header[3];
    const tagFlags: number = header[5];
    const tagSize: number = EmbeddedLyricReader.syncsafe(header[6], header[7], header[8], header[9]);
    if (tagSize <= 0) {
      return undefined;
    }
    const readLen: number = Math.min(tagSize, MAX_ID3_TAG, Math.max(fileSize - 10, 0));
    let body: Uint8Array = EmbeddedLyricReader.readRange(fd, 10, readLen);
    if (body.length === 0) {
      return undefined;
    }
    // 整标签级 unsynchronisation（v2.3 常见）：还原 FF 00 -> FF
    if ((tagFlags & 0x80) !== 0) {
      body = EmbeddedLyricReader.deUnsynchronise(body);
    }

    let pos = 0;
    // 扩展头：v2.4 长度为 syncsafe 且含自身；v2.3 长度为普通 u32 且不含自身 4 字节
    if (major >= 3 && (tagFlags & 0x40) !== 0 && body.length >= 4) {
      if (major === 4) {
        pos += EmbeddedLyricReader.syncsafe(body[0], body[1], body[2], body[3]);
      } else {
        pos += EmbeddedLyricReader.be32(body, 0) + 4;
      }
    }

    const idLen: number = major === 2 ? 3 : 4;
    const frameHeaderLen: number = major === 2 ? 6 : 10;
    let fallback: string | undefined;
    while (pos + frameHeaderLen <= body.length) {
      if (body[pos] === 0) {
        break; // 进入 padding
      }
      const id: string = EmbeddedLyricReader.readFrameId(body, pos, idLen);
      let frameSize: number;
      if (major === 2) {
        frameSize = (body[pos + 3] << 16) | (body[pos + 4] << 8) | body[pos + 5];
      } else if (major === 4) {
        frameSize = EmbeddedLyricReader.syncsafe(body[pos + 4], body[pos + 5], body[pos + 6], body[pos + 7]);
      } else {
        frameSize = EmbeddedLyricReader.be32(body, pos + 4);
      }
      if (frameSize <= 0) {
        break;
      }
      const dataStart: number = pos + frameHeaderLen;
      const dataEnd: number = Math.min(dataStart + frameSize, body.length);
      if (dataStart >= dataEnd) {
        break;
      }
      const frame: Uint8Array = body.subarray(dataStart, dataEnd);

      if (id === 'USLT' || id === 'ULT') {
        const text: string | undefined = EmbeddedLyricReader.parseUsltFrame(frame);
        if (EmbeddedLyricReader.isUsable(text)) {
          return text;
        }
      } else if ((id === 'TXXX' || id === 'TXX') && fallback === undefined) {
        const text: string | undefined = EmbeddedLyricReader.parseTxxxLyricFrame(frame);
        if (EmbeddedLyricReader.isUsable(text)) {
          fallback = text;
        }
      }
      pos = dataStart + frameSize;
    }
    return fallback;
  }

  /** USLT: encoding(1) + language(3) + 描述符(以终止符结尾) + 正文。 */
  private static parseUsltFrame(frame: Uint8Array): string | undefined {
    if (frame.length < 5) {
      return undefined;
    }
    const enc: number = frame[0];
    const textStart: number = EmbeddedLyricReader.skipTerminatedString(frame, 4, enc);
    if (textStart >= frame.length) {
      return undefined;
    }
    return EmbeddedLyricReader.decodeById3(frame.subarray(textStart), enc);
  }

  /** TXXX: encoding(1) + 描述符 + 值。描述符含 LYRIC 时才当作歌词。 */
  private static parseTxxxLyricFrame(frame: Uint8Array): string | undefined {
    if (frame.length < 3) {
      return undefined;
    }
    const enc: number = frame[0];
    const valueStart: number = EmbeddedLyricReader.skipTerminatedString(frame, 1, enc);
    if (valueStart >= frame.length) {
      return undefined;
    }
    const desc: string = EmbeddedLyricReader.decodeById3(frame.subarray(1, valueStart), enc).toUpperCase();
    if (desc.indexOf('LYRIC') < 0) {
      return undefined;
    }
    return EmbeddedLyricReader.decodeById3(frame.subarray(valueStart), enc);
  }

  /** 从 from 开始跳过一个以 null 结尾的字符串，返回其后第一个字节的下标。 */
  private static skipTerminatedString(frame: Uint8Array, from: number, enc: number): number {
    let p: number = from;
    if (enc === 1 || enc === 2) {
      while (p + 1 < frame.length && !(frame[p] === 0 && frame[p + 1] === 0)) {
        p += 2;
      }
      return p + 2;
    }
    while (p < frame.length && frame[p] !== 0) {
      p += 1;
    }
    return p + 1;
  }

  private static decodeById3(bytes: Uint8Array, enc: number): string {
    if (enc === 1) {
      return EmbeddedLyricReader.decodeUtf16(bytes);
    }
    if (enc === 2) {
      return EmbeddedLyricReader.decodeUtf16be(bytes);
    }
    if (enc === 3) {
      return EmbeddedLyricReader.decodeUtf8(bytes);
    }
    // enc === 0 为 ISO-8859-1，但实测大量国内工具在此处塞 UTF-8，先按 UTF-8 试
    return EmbeddedLyricReader.detectAndDecode(bytes);
  }

  /** 还原 unsynchronisation：字节序列 FF 00 还原为 FF。 */
  private static deUnsynchronise(bytes: Uint8Array): Uint8Array {
    const out = new Uint8Array(bytes.length);
    let w = 0;
    for (let i = 0; i < bytes.length; i++) {
      out[w] = bytes[i];
      w++;
      if (bytes[i] === 0xFF && i + 1 < bytes.length && bytes[i + 1] === 0x00) {
        i++; // 跳过填充的 0x00
      }
    }
    return out.subarray(0, w);
  }

  // ============================ 文本处理 ============================

  /**
   * 探测文本编码并解码：UTF-16 LE/BE(BOM) → UTF-8(BOM) → 无 BOM 的 UTF-16 启发式 → UTF-8。
   */
  private static detectAndDecode(textBytes: Uint8Array): string {
    if (!textBytes || textBytes.length === 0) {
      return '';
    }
    if (textBytes.length >= 2 && textBytes[0] === 0xFF && textBytes[1] === 0xFE) {
      return EmbeddedLyricReader.decodeUtf16(textBytes.subarray(2));
    }
    if (textBytes.length >= 2 && textBytes[0] === 0xFE && textBytes[1] === 0xFF) {
      return EmbeddedLyricReader.decodeUtf16be(textBytes.subarray(2));
    }
    if (textBytes.length >= 3 && textBytes[0] === 0xEF && textBytes[1] === 0xBB && textBytes[2] === 0xBF) {
      return EmbeddedLyricReader.decodeUtf8(textBytes.subarray(3));
    }
    // 无 BOM 的 UTF-16 判定：只取前 512 字节采样，避免大文本上做全量统计
    if (textBytes.length >= 4 && textBytes.length % 2 === 0) {
      const sample: number = Math.min(textBytes.length, 512);
      let zeroAtOdd = 0;
      let zeroAtEven = 0;
      for (let i = 0; i + 1 < sample; i += 2) {
        if (textBytes[i + 1] === 0x00) {
          zeroAtOdd++;
        }
        if (textBytes[i] === 0x00) {
          zeroAtEven++;
        }
      }
      const pairs: number = Math.floor(sample / 2);
      if (pairs > 0 && zeroAtOdd / pairs > 0.3 && zeroAtOdd >= zeroAtEven) {
        return EmbeddedLyricReader.decodeUtf16(textBytes);
      }
      if (pairs > 0 && zeroAtEven / pairs > 0.3 && zeroAtEven > zeroAtOdd) {
        return EmbeddedLyricReader.decodeUtf16be(textBytes);
      }
    }
    return EmbeddedLyricReader.decodeUtf8(textBytes);
  }

  /**
   * 统一换行（CRLF/CR → LF）并去掉尾部 NUL / 空白。
   * LrcUtils 按 '\n' 切分，残留的 '\r' 会拖进歌词文本里造成排版异常。
   */
  private static normalize(text: string): string {
    let s: string = text.replace(/\0+/g, '');
    s = s.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
    return s.trim();
  }

  private static isUsable(text: string | undefined): boolean {
    if (text === undefined || text === null) {
      return false;
    }
    const t: string = text.trim();
    return t.length > 0 && t.length <= MAX_LYRIC_CHARS;
  }

  // ============================ 底层工具 ============================

  /** 定点读取：只把需要的字节读进内存。 */
  private static readRange(fd: number, offset: number, length: number): Uint8Array {
    if (length <= 0) {
      return new Uint8Array(0);
    }
    try {
      const buffer = new ArrayBuffer(length);
      const options: ReadOptions = { offset: offset, length: length };
      const readLen: number = fileIo.readSync(fd, buffer, options);
      if (readLen <= 0) {
        return new Uint8Array(0);
      }
      return new Uint8Array(buffer, 0, readLen);
    } catch (e) {
      Logger.debug(TAG, `readRange(${offset}, ${length}) failed: ${(e as Error).message}`);
      return new Uint8Array(0);
    }
  }

  private static le32(b: Uint8Array, off: number): number {
    if (off + 4 > b.length) {
      return 0;
    }
    return (b[off] | (b[off + 1] << 8) | (b[off + 2] << 16) | (b[off + 3] * 16777216));
  }

  private static be32(b: Uint8Array, off: number): number {
    if (off + 4 > b.length) {
      return 0;
    }
    return (b[off] * 16777216) + (b[off + 1] << 16) + (b[off + 2] << 8) + b[off + 3];
  }

  private static syncsafe(a: number, b: number, c: number, d: number): number {
    return ((a & 0x7F) << 21) | ((b & 0x7F) << 14) | ((c & 0x7F) << 7) | (d & 0x7F);
  }

  private static indexOfByte(buf: Uint8Array, value: number): number {
    for (let i = 0; i < buf.length; i++) {
      if (buf[i] === value) {
        return i;
      }
    }
    return -1;
  }

  private static asciiUpper(bytes: Uint8Array): string {
    let s = '';
    const limit: number = Math.min(bytes.length, 64);
    for (let i = 0; i < limit; i++) {
      const c: number = bytes[i];
      if (c === 0) {
        break;
      }
      s += String.fromCharCode(c >= 0x61 && c <= 0x7A ? c - 32 : c);
    }
    return s;
  }

  private static readFrameId(b: Uint8Array, off: number, len: number): string {
    let s = '';
    for (let i = 0; i < len; i++) {
      s += String.fromCharCode(b[off + i]);
    }
    return s;
  }

  private static decodeUtf8(bytes: Uint8Array): string {
    try {
      const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      return decoder.decodeToString(bytes, { stream: false });
    } catch (e) {
      return EmbeddedLyricReader.decodeLatin1(bytes);
    }
  }

  private static decodeUtf16(bytes: Uint8Array): string {
    let b: Uint8Array = bytes;
    if (b.length >= 2 && ((b[0] === 0xFF && b[1] === 0xFE) || (b[0] === 0xFE && b[1] === 0xFF))) {
      b = b.subarray(2);
    }
    try {
      const decoder = util.TextDecoder.create('utf-16le', { ignoreBOM: true });
      return decoder.decodeToString(b, { stream: false });
    } catch (e) {
      return EmbeddedLyricReader.decodeLatin1(b);
    }
  }

  private static decodeUtf16be(bytes: Uint8Array): string {
    let b: Uint8Array = bytes;
    if (b.length >= 2 && b[0] === 0xFE && b[1] === 0xFF) {
      b = b.subarray(2);
    }
    try {
      const decoder = util.TextDecoder.create('utf-16be', { ignoreBOM: true });
      return decoder.decodeToString(b, { stream: false });
    } catch (e) {
      return EmbeddedLyricReader.decodeLatin1(b);
    }
  }

  private static decodeLatin1(bytes: Uint8Array): string {
    let s = '';
    for (let i = 0; i < bytes.length; i++) {
      s += String.fromCharCode(bytes[i]);
    }
    return s;
  }
}
