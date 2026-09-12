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
 * 歌曲信息详情半模态面板（Medium 高度）。
 * 显示文件名、歌手、作曲家、合集、年代、添加时间等元数据。
 * 入参只用 songId（@Prop），歌曲实体在内部从 MusicStore 实时取出，避免传递可能为 undefined 的对象。
 */

import { SongItem } from '../models/music';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { MusicStore } from '../services/MusicStore';
import { fileIo as fs } from '@kit.CoreFileKit';
import type uiMaterial from '@ohos.arkui.uiMaterial';
import { ApiCompat } from '../common/utils/ApiCompat';
import { TYPE_SM, SPACE_SM } from '../tokens/LumioScale';

function getFileName(src: string): string {
  try {
    const decoded = decodeURIComponent(src);
    const idx = decoded.lastIndexOf('/');
    return idx >= 0 ? decoded.substring(idx + 1) : decoded;
  } catch (e) {
    const idx = src.lastIndexOf('/');
    return idx >= 0 ? src.substring(idx + 1) : src;
  }
}

function formatDate(timestamp: number): string {
  if (timestamp <= 0) {
    return '未知';
  }
  const d = new Date(timestamp);
  const y = d.getFullYear();
  const m = d.getMonth() + 1;
  const day = d.getDate();
  const h = d.getHours().toString().padStart(2, '0');
  const min = d.getMinutes().toString().padStart(2, '0');
  return `${y}-${m}-${day} ${h}:${min}`;
}

function getFileModifiedTime(src: string): string {
  try {
    const stat = fs.statSync(src);
    // fs.Stat.mtime 为 number 时间戳（秒或毫秒，按官方定义通常为毫秒），此处做兜底兼容
    const t: number = stat.mtime;
    const ts: number = t < 1e12 ? t * 1000 : t;
    return formatDate(ts);
  } catch (e) {
    return '未知';
  }
}

@Component
export struct SongDetailSheet {
  @StorageProp('isDark') isDark: boolean = false;
  @Prop songId: number = 0;
  store: MusicStore = MusicStore.getInstance();
  // 系统材质实例（API 26 经动态 import 注入；API 24 恒为 undefined，走背景色兜底）
  @State material: uiMaterial.Material | undefined = undefined;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  private getSong(): SongItem | undefined {
    if (this.songId <= 0) {
      return undefined;
    }
    return this.store.songs.find((s: SongItem) => s.id === this.songId);
  }

  aboutToAppear(): void {
    // API 26 才动态加载 @ohos.arkui.uiMaterial（该模块为 API 26 整模块新增，API 24 不存在）；
    // 动态 import 失败仅进入 catch 兜底，确保 API 24 真机不加载此模块、不调用 systemMaterial，避免崩溃。
    if (ApiCompat.isAtLeast(ApiCompat.API_26)) {
      import('@ohos.arkui.uiMaterial').then((mod: ESObject): void => {
        const def: ESObject = mod.default;
        const materialObj: ESObject = new (def.ImmersiveMaterial as ESObject)({
          style: (def.ImmersiveStyle as ESObject).REGULAR
        });
        this.material = materialObj as uiMaterial.Material;
      }).catch((): void => {
        this.material = undefined;
      });
    }
  }

  @Builder
  private infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(TYPE_SM.subhead.size)
        .fontColor(this.getThemeColors().secondaryText)
        .width(80)

      Text(value)
        .fontSize(TYPE_SM.subhead.size)
        .fontColor(this.getThemeColors().primaryText)
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  build() {
    if (ApiCompat.isAtLeast(ApiCompat.API_26) && this.material !== undefined) {
      // 鸿蒙新特性 uiMaterial（API 26 沉浸系统材质）：半模态根容器启用系统级毛玻璃，
      // 自动适配深浅色与设备算力档位，与苹果风系统材质一致。material 仅在 API 26 动态加载成功后有值。
      Column() {
        this.SheetBody()
      }
      .width('100%')
      .padding({ left: SPACE_SM.roomy, right: SPACE_SM.roomy, bottom: SPACE_SM.loose })
      .systemMaterial(this.material)
    } else {
      // API 24 降级：uiMaterial 模块/方法均不存在，用主题卡片背景色模拟毛玻璃兜底，保证面板可用。
      Column() {
        this.SheetBody()
      }
      .width('100%')
      .padding({ left: SPACE_SM.roomy, right: SPACE_SM.roomy, bottom: SPACE_SM.loose })
      .backgroundColor(this.getThemeColors().cardBg)
    }
  }

  @Builder
  private SheetBody() {
    Text('歌曲信息')
      .fontSize(TYPE_SM.title3.size)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.getThemeColors().primaryText)
      .margin({ top: SPACE_SM.roomy, bottom: SPACE_SM.base })

    if (this.getSong()) {
      this.songContent(this.getSong()!)
    } else {
      Text('未选择歌曲')
        .fontSize(TYPE_SM.subhead.size)
        .fontColor(this.getThemeColors().secondaryText)
    }
  }

  @Builder
  private songContent(song: SongItem) {
    this.infoRow('文件名', getFileName(song.src))
    this.infoRow('标题', song.title.length > 0 ? song.title : '未知')
    this.infoRow('歌手', song.singer.length > 0 ? song.singer : '未知')
    this.infoRow('作曲家', song.author.length > 0 ? song.author : '未知')
    this.infoRow('合集', song.album.length > 0 ? song.album : '未知')
    this.infoRow('年代', song.year.length > 0 ? song.year : '未知')
    this.infoRow('添加时间', getFileModifiedTime(song.src))
  }
}
