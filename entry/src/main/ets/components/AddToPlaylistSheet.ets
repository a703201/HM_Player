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
import { TYPE_SM, SPACE_SM } from '../tokens/LumioScale';

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
        .fontSize(TYPE_SM.title3.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .margin({ top: SPACE_SM.roomy, bottom: SPACE_SM.base })

      TextInput({ text: this.newName, placeholder: '请输入歌单名称' })
        .width('86%')
        .height(44)
        .maxLength(30)
        .fontColor(this.getThemeColors().primaryText)
        .backgroundColor(this.getThemeColors().secondaryBg)
        .borderRadius(12)
        .onChange((value: string) => {
          this.newName = value;
        })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .fontSize(TYPE_SM.body.size)
          .fontColor(this.getThemeColors().secondaryText)
          .backgroundColor(this.getThemeColors().secondaryBg)
          .borderRadius(24)
          .onClick(() => {
            this.nameDialogController.close();
          }).clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.96 })

        Button('确定')
          .layoutWeight(1)
          .height(40)
          .fontSize(TYPE_SM.body.size)
          .fontColor(semanticOf(this.isDark).onAccent)
          .backgroundColor(this.getThemeColors().accent)
          .borderRadius(24)
          .margin({ left: SPACE_SM.cozy })
          .onClick(() => {
            this.onNewConfirm(this.newName);
          }).clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.96 })
      }
      .width('86%')
      .margin({ top: SPACE_SM.roomy, bottom: SPACE_SM.roomy })
    }
    .width('100%')
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(16)
  }

  build() {
    Column() {
      Text('添加到歌单')
        .fontSize(TYPE_SM.title3.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .margin({ top: SPACE_SM.roomy, bottom: SPACE_SM.cozy })
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.playlists.length === 0) {
        Text('还没有歌单，点击下方新建')
          .fontSize(TYPE_SM.footnote.size)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: SPACE_SM.roomy, bottom: SPACE_SM.roomy })
      } else {
        List() {
          ForEach(this.playlists, (playlist: Playlist) => {
            ListItem() {
              Row() {
                CoverImageView({ src: this.getCoverSrc(playlist), coverSize: 40, coverRadius: 8 })

                Column() {
                  Text(playlist.name)
                    .fontSize(TYPE_SM.body.size)
                    .fontColor(this.getThemeColors().primaryText)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(`${playlist.songIds.length} 首`)
                    .fontSize(TYPE_SM.caption1.size)
                    .fontColor(this.getThemeColors().secondaryText)
                    .margin({ top: SPACE_SM.hair })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                .padding({ left: SPACE_SM.cozy, right: SPACE_SM.compact })
              }
              .width('100%')
              .height(56)
              .padding({ left: SPACE_SM.base, right: SPACE_SM.base })
              .onClick(() => {
                this.addTo(playlist);
              }).clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.96 })
            }
          }, (playlist: Playlist): string => playlist.id)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      Row() {
        Image($r('app.media.ic_public_folder'))
          .width(20)
          .height(20)
          .fillColor(this.getThemeColors().accent)
        Text('新建歌单')
          .fontSize(TYPE_SM.body.size)
          .fontColor(this.getThemeColors().accent)
          .margin({ left: SPACE_SM.compact })
      }
      .width('100%')
      .height(48)
      .padding({ left: SPACE_SM.base })
      .onClick(() => {
        this.newName = '';
        this.nameDialogController.open();
      }).clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.96 })

      Blank()
        .height(12)
    }
    .width('100%')
    .backgroundColor(this.getThemeColors().cardBg)
  }
}
