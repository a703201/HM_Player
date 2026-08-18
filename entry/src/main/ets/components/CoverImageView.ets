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
import { Logger } from '../utils/Logger';

const TAG = 'CoverImageView';

/**
 * 响应式封面组件。
 *
 * 解决列表项直接 `Image(song.getMark())` 时的刷新失效：ForEach 复用列表项节点时，
 * Image 的源从默认 Resource 切换到真实 PixelMap 不会可靠重渲染。本组件把封面放在
 * `@State` 中，并在两个时机主动重读 CoverCache：
 *   1. aboutToAppear（首次挂载，命中已缓存封面）；
 *   2. coverRefreshToken 变化（导入/重启后 CoverCache 批量抽取完成，由 EntryAbility/
 *      LocalLibrary 负责 bump token）——这是播放页 `PlayerInfoComponent` 已验证可行的模式。
 * 同时监听传入的 src：列表项被复用/回收导致歌曲切换时也能即时刷新。
 */
@Component
export struct CoverImageView {
  @StorageProp('coverRefreshToken') @Watch('refresh') coverToken: number = 0;
  @Prop @Watch('refresh') src: string = '';
  // 注意：属性名不可用 size / width / height 等，会与 CustomComponent 内置属性方法冲突
  // （ArkTS 报 "Property 'size' ... is not assignable to the same property in base type"）。
  @Prop coverSize: number = 56;
  @Prop coverRadius: number = 8;
  @State cover: Resource | image.PixelMap = $r('app.media.ic_default_cover');

  aboutToAppear(): void {
    this.refresh();
  }

  /**
   * token 变化 / src 变化 都触发。
   * 1) 命中缓存 → 立即显示真实封面；
   * 2) 未命中且未确认无封面 → 先落默认图，再异步自取（不依赖外部 preload 的时序）；
   *    回调里比对 src，避免列表项复用导致把 A 的封面画到 B 上。
   */
  refresh(): void {
    const current: string = this.src;
    if (!current || current.length === 0) {
      this.cover = $r('app.media.ic_default_cover');
      return;
    }
    const cache: CoverCache = CoverCache.getInstance();
    const cached: image.PixelMap | undefined = cache.get(current);
    if (cached !== undefined) {
      this.cover = cached;
      return;
    }
    this.cover = $r('app.media.ic_default_cover');
    if (cache.isMissing(current)) {
      return;
    }
    cache.load(current).then((pixelMap: image.PixelMap | undefined) => {
      if (pixelMap !== undefined && this.src === current) {
        this.cover = pixelMap;
      }
    }).catch((err: Error) => {
      Logger.debug(TAG, `cover load failed for ${current}: ${err.message}`);
    });
  }

  build() {
    Image(this.cover)
      .width(this.coverSize)
      .height(this.coverSize)
      .borderRadius(this.coverRadius)
      .objectFit(ImageFit.Cover)
      .clip(true)
      .animation({ duration: 300, curve: Curve.EaseOut })
      .onError(() => {
        Logger.debugPrivate(TAG, `cover render error for ${this.src}`);
      })
  }
}
