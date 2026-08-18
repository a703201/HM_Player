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
import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { Logger } from './Logger';

const TAG = 'CoverCache';

/**
 * 音频内嵌封面抽取与缓存。
 *
 * 设计原则：
 * - 单例 Map 缓存 src -> PixelMap，避免重复抽取。
 * - 仅对沙箱真实媒体文件尝试抽取；.pcm / rawfile 资源名直接跳过。
 * - 抽取失败静默处理，不影响播放。
 * - 调用方在 preload 完成后自行刷新 songList / coverRefreshToken。
 */
interface CoverSource {
  src: string;
}

export class CoverCache {
  private static instance: CoverCache | null = null;
  private readonly cache = new Map<string, image.PixelMap>();
  // 在途请求：同一 src 的并发调用复用同一个 Promise，避免重复抽取，
  // 也避免旧实现里「第二个调用者拿到 undefined 且永不重试」的空窗。
  private readonly pending = new Map<string, Promise<image.PixelMap | undefined>>();
  // 负缓存：确认无内嵌封面（或不可抽取）的 src，后续直接短路，防止列表滚动反复触发 I/O。
  private readonly missing = new Set<string>();

  static getInstance(): CoverCache {
    if (!CoverCache.instance) {
      CoverCache.instance = new CoverCache();
    }
    return CoverCache.instance;
  }

  get(src: string): image.PixelMap | undefined {
    return this.cache.get(src);
  }

  /**
   * 是否已确定该 src 没有可用封面（抽取失败或格式不支持）。
   * UI 侧据此决定「继续等」还是「直接落默认图」。
   */
  isMissing(src: string): boolean {
    return this.missing.has(src);
  }

  async load(src: string): Promise<image.PixelMap | undefined> {
    if (!src) {
      return undefined;
    }
    const hit: image.PixelMap | undefined = this.cache.get(src);
    if (hit !== undefined) {
      return hit;
    }
    if (this.missing.has(src)) {
      return undefined;
    }
    const inflight: Promise<image.PixelMap | undefined> | undefined = this.pending.get(src);
    if (inflight !== undefined) {
      return inflight;
    }
    if (!this.isExtractable(src)) {
      this.missing.add(src);
      return undefined;
    }
    const task: Promise<image.PixelMap | undefined> = CoverCache.extractCover(src)
      .then((pixelMap: image.PixelMap | undefined) => {
        if (pixelMap !== undefined) {
          this.cache.set(src, pixelMap);
        } else {
          this.missing.add(src);
        }
        this.pending.delete(src);
        return pixelMap;
      })
      .catch((err: Error) => {
        this.pending.delete(src);
        this.missing.add(src);
        Logger.debugPrivate(TAG, `load failed for ${src}: ${err.message}`);
        return undefined;
      });
    this.pending.set(src, task);
    return task;
  }

  /**
   * 歌曲被移除时清理，防止长期占用内存。
   */
  evict(src: string): void {
    this.cache.delete(src);
    this.missing.delete(src);
  }

  /**
   * 批量抽取封面，限制并发数以避免 I/O 拥塞。
   */
  async preload(songs: CoverSource[], concurrency: number = 4): Promise<void> {
    for (let i = 0; i < songs.length; i += concurrency) {
      const batch = songs.slice(i, i + concurrency);
      await Promise.all(batch.map(s => this.load(s.src).then(() => {
      })));
    }
  }

  private isExtractable(src: string): boolean {
    const lower = src.toLowerCase();
    if (lower.endsWith('.pcm')) {
      return false;
    }
    return src.startsWith('/') || src.startsWith('file://') || src.startsWith('internal://');
  }

  private static async extractCover(src: string): Promise<image.PixelMap | undefined> {
    let extractor: media.AVMetadataExtractor | undefined;
    let file: fileIo.File | undefined;
    try {
      extractor = await media.createAVMetadataExtractor();
      file = fileIo.openSync(src, fileIo.OpenMode.READ_ONLY);
      extractor.fdSrc = { fd: file.fd, offset: 0, length: -1 } as media.AVFileDescriptor;
      await extractor.fetchMetadata();
      return await extractor.fetchAlbumCover();
    } catch (err) {
      Logger.debugPrivate(TAG, `extractCover failed for ${src}: ${(err as Error).message}`);
      return undefined;
    } finally {
      if (extractor) {
        try {
          await extractor.release();
        } catch (_) {
          // ignore
        }
      }
      if (file) {
        try {
          fileIo.closeSync(file);
        } catch (_) {
          // ignore
        }
      }
    }
  }
}
