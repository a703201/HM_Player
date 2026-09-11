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

import { SongItem } from '../models/music';
import { MusicStore } from '../services/MusicStore';
import { AudioRendererController } from '../utils/AudioRendererController';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { CoverImageView } from '../components/CoverImageView';
import { Logger } from '../utils/Logger';
import { common } from '@kit.AbilityKit';
import { semanticOf } from '../tokens/LumioColor';

const TAG: string = 'FolderBrowse';

interface FolderGroup {
  name: string;
  songs: SongItem[];
}

@Builder
export function FolderBrowseBuilder() {
  FolderBrowse()
}

/**
 * 文件夹浏览：按歌曲来源文件夹（导入时从 picker URI 父目录解析）分组本地音乐。
 * 顶层列出各文件夹，点击进入后展示该目录下的歌曲并可播放。
 */
@Component
export struct FolderBrowse {
  @Consume('navPathStack') pathStack: NavPathStack;
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('bottomHeight') bottomHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('reload') coverRefreshToken: number = 0;

  @State folders: FolderGroup[] = [];
  @State selectedFolder: string = '';
  @State backScale: number = 1.0;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  aboutToAppear(): void {
    this.reload();
  }

  /** 按 folder 聚合（空 folder 归入「导入音乐」），按歌曲数降序。 */
  reload(): void {
    const map: Map<string, SongItem[]> = new Map<string, SongItem[]>();
    for (const s of this.store.songs) {
      const key: string = (s.folder && s.folder.trim().length > 0) ? s.folder : '导入音乐';
      const arr: SongItem[] = map.get(key) ?? [];
      arr.push(s);
      map.set(key, arr);
    }
    const list: FolderGroup[] = [];
    map.forEach((songs: SongItem[], name: string) => {
      list.push({ name, songs });
    });
    list.sort((a: FolderGroup, b: FolderGroup) => b.songs.length - a.songs.length);
    this.folders = list;
  }

  private currentFolderSongs(): SongItem[] {
    const f: FolderGroup | undefined = this.folders.find((x: FolderGroup) => x.name === this.selectedFolder);
    return f ? f.songs : [];
  }

  private playFolder(name: string): void {
    const f: FolderGroup | undefined = this.folders.find((x: FolderGroup) => x.name === name);
    if (!f || f.songs.length === 0) {
      return;
    }
    AudioRendererController.getInstance().setQueue(f.songs, 0, true);
    this.pathStack.pushPathByName('PlayerPage', null);
  }

  private playSong(song: SongItem): void {
    const idx: number = this.store.songs.findIndex((s: SongItem) => s.id === song.id);
    if (idx >= 0) {
      AudioRendererController.getInstance().playFromList(this.store.songs, idx);
      this.pathStack.pushPathByName('PlayerPage', null);
    }
  }

  @Builder
  private folderItem(f: FolderGroup) {
    Row() {
      Stack() {
        Image($r('app.media.ic_hm_folder'))
          .width(26)
          .height(26)
          .fillColor(this.getThemeColors().accent)
      }
      .width(56)
      .height(56)
      .borderRadius(10)
      .backgroundColor(semanticOf(this.isDark).fillAccentSoft)

      Column() {
        Text(f.name)
          .fontSize(16)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${f.songs.length} 首歌曲`)
          .fontSize(12)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 8 })

      Image($r('app.media.ic_play_all'))
        .width(22)
        .height(22)
        .fillColor(this.getThemeColors().accent)
        .margin({ right: 14 })
        .onClick(() => {
          this.playFolder(f.name);
        })
    }
    .width('100%')
    .height(76)
    .padding({ left: 12, right: 14 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(14)
    .margin({ left: 8, right: 8, bottom: 8 })
    .onClick(() => {
      this.selectedFolder = f.name;
    })
  }

  @Builder
  private songRow(song: SongItem) {
    Row() {
      CoverImageView({ src: song.src, coverSize: 48, coverRadius: 8 })

      Column() {
        Text(song.title)
          .fontSize(15)
          .fontColor(this.getThemeColors().primaryText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(song.singer)
          .fontSize(12)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: 3 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12 })
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(12)
    .margin({ left: 8, right: 8, bottom: 8 })
    .onClick(() => {
      this.playSong(song);
    })
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          if (this.selectedFolder !== '') {
            Image($r('app.media.ic_back'))
              .width(24)
              .height(24)
              .fillColor(this.getThemeColors().primaryText)
              .scale({ x: this.backScale, y: this.backScale })
              .animation({ duration: 150, curve: Curve.EaseOut })
              .onClick(() => {
                this.selectedFolder = '';
              })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) {
                  this.backScale = 0.8;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.backScale = 1.0;
                }
              })

            Text(this.selectedFolder)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getThemeColors().primaryText)
              .margin({ left: 12 })
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          } else {
            Text('文件夹')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getThemeColors().primaryText)
              .margin({ left: 16 })
              .layoutWeight(1)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 16 })

        if (this.selectedFolder === '') {
          if (this.folders.length === 0) {
            Column() {
              Image($r('app.media.ic_hm_folder'))
                .width(72)
                .height(72)
                .fillColor(this.getThemeColors().secondaryText)
                .opacity(0.5)
                .margin({ bottom: 16 })
              Text('还没有可浏览的文件夹')
                .fontSize(16)
                .fontColor(this.getThemeColors().secondaryText)
                .fontWeight(FontWeight.Medium)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.folders, (f: FolderGroup) => {
                ListItem() {
                  this.folderItem(f)
                }
              }, (f: FolderGroup): string => f.name)
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .padding({ bottom: this.bottomHeight + 16 })
          }
        } else {
          List() {
            ForEach(this.currentFolderSongs(), (song: SongItem) => {
              ListItem() {
                this.songRow(song)
              }
            }, (song: SongItem): string => song.id.toString())
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .padding({ bottom: this.bottomHeight + 16 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .hideTitleBar(true)
  }
}
