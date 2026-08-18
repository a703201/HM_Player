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

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  private getSong(): SongItem | undefined {
    if (this.songId <= 0) {
      return undefined;
    }
    return this.store.songs.find((s: SongItem) => s.id === this.songId);
  }

  @Builder
  private infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(this.getThemeColors().secondaryText)
        .width(80)

      Text(value)
        .fontSize(14)
        .fontColor(this.getThemeColors().primaryText)
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }

  build() {
    Column() {
      Text('歌曲信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .margin({ top: 20, bottom: 16 })

      if (this.getSong()) {
        this.songContent(this.getSong()!)
      } else {
        Text('未选择歌曲')
          .fontSize(14)
          .fontColor(this.getThemeColors().secondaryText)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 24 })
    .backgroundColor(this.getThemeColors().cardBg)
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
