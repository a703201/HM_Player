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
 * 长按菜单 -> "添加到歌单" 的歌单选择半模态面板（Medium 高度）。
 * 列出当前所有自建歌单，点击即把指定歌曲加入；底部「新建歌单」可在面板内直接建并加入。
 */

import { MusicStore } from '../services/MusicStore';
import { SongItem, Playlist } from '../models/music';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { semanticOf } from '../tokens/LumioColor';
import { Logger } from '../utils/Logger';
import { CoverImageView } from './CoverImageView';

const TAG: string = 'AddToPlaylistSheet';

@Component
export struct AddToPlaylistSheet {
  @StorageProp('isDark') isDark: boolean = false;
  @Prop songId: number = 0;
  onClose: () => void = () => {};
  store: MusicStore = MusicStore.getInstance();
  @State playlists: Playlist[] = [];
  @State newName: string = '';

  nameDialogController: CustomDialogController = new CustomDialogController({
    builder: this.nameDialogBuilder,
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    this.playlists = [...this.store.playlists];
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (e) {
      Logger.error(TAG, 'toast failed');
    }
  }

  private addTo(playlist: Playlist): void {
    if (this.songId <= 0) {
      return;
    }
    const added: number = this.store.addSongsToPlaylist(playlist.id, [this.songId]);
    if (added > 0) {
      this.toast(`已添加到「${playlist.name}」`);
    } else {
      this.toast('歌曲已在歌单中');
    }
    this.onClose();
  }

  private onNewConfirm(name: string): void {
    const trimmed: string = name.trim();
    if (trimmed.length === 0) {
      this.toast('歌单名称不能为空');
      return;
    }
    if (this.store.hasPlaylistName(trimmed)) {
      this.toast('已存在同名歌单');
      return;
    }
    this.store.addPlaylist(trimmed, this.songId > 0 ? [this.songId] : []);
    this.nameDialogController.close();
    this.toast(`已创建并添加「${trimmed}」`);
    this.onClose();
  }

  private getCoverSrc(playlist: Playlist): string {
    const songs: SongItem[] = this.store.getPlaylistSongs(playlist);
    return songs.length > 0 ? songs[0].src : '';
  }

  @Builder
  nameDialogBuilder() {
    Column() {
      Text('新建歌单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .margin({ top: 20, bottom: 16 })

      TextInput({ text: this.newName, placeholder: '请输入歌单名称' })
        .width('86%')
        .height(44)
        .maxLength(30)
        .fontColor(this.getThemeColors().primaryText)
        .backgroundColor(this.getThemeColors().secondaryBg)
        .borderRadius(10)
        .onChange((value: string) => {
          this.newName = value;
        })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(this.getThemeColors().secondaryText)
          .backgroundColor(this.getThemeColors().secondaryBg)
          .borderRadius(20)
          .onClick(() => {
            this.nameDialogController.close();
          })

        Button('确定')
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .fontColor(semanticOf(this.isDark).onAccent)
          .backgroundColor(this.getThemeColors().accent)
          .borderRadius(20)
          .margin({ left: 12 })
          .onClick(() => {
            this.onNewConfirm(this.newName);
          })
      }
      .width('86%')
      .margin({ top: 20, bottom: 20 })
    }
    .width('100%')
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(16)
  }

  build() {
    Column() {
      Text('添加到歌单')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .margin({ top: 20, bottom: 12 })
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.playlists.length === 0) {
        Text('还没有歌单，点击下方新建')
          .fontSize(13)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: 20, bottom: 20 })
      } else {
        List() {
          ForEach(this.playlists, (playlist: Playlist) => {
            ListItem() {
              Row() {
                CoverImageView({ src: this.getCoverSrc(playlist), coverSize: 40, coverRadius: 8 })

                Column() {
                  Text(playlist.name)
                    .fontSize(15)
                    .fontColor(this.getThemeColors().primaryText)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(`${playlist.songIds.length} 首`)
                    .fontSize(12)
                    .fontColor(this.getThemeColors().secondaryText)
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .padding({ left: 12, right: 8 })
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                this.addTo(playlist);
              })
            }
          }, (playlist: Playlist): string => playlist.id)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      Row() {
        Image($r('app.media.ic_hm_folder'))
          .width(18)
          .height(18)
          .fillColor(this.getThemeColors().accent)
        Text('新建歌单')
          .fontSize(15)
          .fontColor(this.getThemeColors().accent)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16 })
      .onClick(() => {
        this.newName = '';
        this.nameDialogController.open();
      })

      Blank()
        .height(12)
    }
    .width('100%')
    .backgroundColor(this.getThemeColors().cardBg)
  }
}
