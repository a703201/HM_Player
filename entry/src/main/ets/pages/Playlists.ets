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

import { SongItem, Playlist } from '../models/music';
import { CoverImageView } from '../components/CoverImageView';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { MusicStore } from '../services/MusicStore';
import { AudioRendererController } from '../utils/AudioRendererController';
import { Logger } from '../utils/Logger';
import { SettingsStore } from '../utils/SettingsStore';
import { SmartPlaylistService, SmartPlaylist } from '../services/SmartPlaylistService';
import { semanticOf } from '../tokens/LumioColor';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';
import { TYPE_SM, SPACE_SM } from '../tokens/LumioScale';

const TAG: string = 'Playlists';

@Builder
export function PlaylistsBuilder() {
  Playlists()
}

/**
 * 我的歌单（自建播放列表）列表页。
 * 数据源统一为 MusicStore.playlists（dataPreferences 持久化），不再另起存储。
 */
@Component
struct Playlists {
  pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('bottomHeight') bottomHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('onCoverRefreshed') coverRefreshToken: number = 0;

  @State playlists: Playlist[] = [];
  @State itemScales: number[] = [];
  @State backScale: number = 1.0;
  @State addScale: number = 1.0;
  @State emptyIconScale: number = 1.0;
  // 智能歌单折叠：默认展开，用户可收起以聚焦自定义歌单
  @State smartCollapsed: boolean = false;

  // 命名弹窗上下文：editingId 为空串表示「新建」，非空表示「重命名该歌单」
  @State editingId: string = '';
  @State editingName: string = '';

  nameDialogController: CustomDialogController = new CustomDialogController({
    builder: this.nameDialogBuilder,
    autoCancel: true,
    alignment: DialogAlignment.Center
  });

  // 呼吸动画运行态与生命周期守卫：组件销毁 / 页面不可见时必须终止递归，否则 animateTo 回调
  // 会持续持有组件引用造成泄漏，且 isBreathing 可能永久卡在 true 导致再次进入时动画不启动。
  private isBreathing: boolean = false;
  private isDisposed: boolean = false;
  private pageVisible: boolean = true;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  aboutToAppear(): void {
    this.isDisposed = false;
    this.reload();
  }

  aboutToDisappear(): void {
    // 置位后正在排队的 onFinish 回调会在下一次触发时直接返回，递归链自然终止
    this.isDisposed = true;
    this.isBreathing = false;
  }

  /**
   * 空状态图标呼吸动画：用 UIContext.animateTo 循环替代 setInterval，符合 ArkUI 声明式动效规范。
   * 注意 emptyIconScale 只能由 animateTo 驱动，节点上不得再挂 .animation()，否则同一属性
   * 被显式动画与属性动画同时接管，表现为跳变或时长错乱。
   */
  private startBreathing(): void {
    // R-18/F-13：降低动态效果开启时不做空态呼吸动画
    if (SettingsStore.getInstance().getReduceMotion() ||
      this.isDisposed || !this.pageVisible || this.playlists.length !== 0) {
      this.isBreathing = false;
      return;
    }
    if (this.isBreathing) {
      return;
    }
    this.isBreathing = true;
    this.getUIContext().animateTo({
      duration: 1000,
      curve: LumioTheme.curve(SpringKind.Crisp),
      onFinish: () => {
        this.isBreathing = false;
        if (this.isDisposed || !this.pageVisible) {
          return;
        }
        this.startBreathing();
      }
    }, () => {
      this.emptyIconScale = this.emptyIconScale === 1.0 ? 1.08 : 1.0;
    });
  }

  onCoverRefreshed(): void {
    this.reload();
  }

  private reload(): void {
    this.playlists = [...this.store.playlists];
    this.itemScales = this.playlists.map(() => 1.0);
    if (this.playlists.length === 0) {
      this.startBreathing();
    }
  }

  /** 列表入场错峰延迟：降低动态效果开启时取消错峰（R-18/F-13）。 */
  private entryDelay(index: number): number {
    return SettingsStore.getInstance().getReduceMotion() ? 0 : index * 50;
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (e) {
      Logger.error(TAG, 'toast failed');
    }
  }

  /**
   * 歌单封面取首曲的 src，交由 CoverImageView 自行订阅 coverRefreshToken 重读缓存。
   * 直接返回 PixelMap 会让 Image 在 ForEach 复用时不刷新（封面停留在默认图）。
   */
  private getPlaylistCoverSrc(playlist: Playlist): string {
    const songs: SongItem[] = this.store.getPlaylistSongs(playlist);
    return songs.length > 0 ? songs[0].src : '';
  }

  private openCreateDialog(): void {
    this.editingId = '';
    this.editingName = '';
    this.nameDialogController.open();
  }

  private openRenameDialog(playlist: Playlist): void {
    this.editingId = playlist.id;
    this.editingName = playlist.name;
    this.nameDialogController.open();
  }

  /**
   * 命名弹窗确认回调：按 editingId 区分新建 / 重命名，做空名与重名校验。
   */
  private onNameConfirm(name: string): void {
    const trimmed: string = name.trim();
    if (trimmed.length === 0) {
      this.toast('歌单名称不能为空');
      return;
    }
    if (this.store.hasPlaylistName(trimmed, this.editingId)) {
      this.toast('已存在同名歌单');
      return;
    }
    if (this.editingId.length === 0) {
      this.store.addPlaylist(trimmed, []);
      this.toast(`已创建「${trimmed}」`);
    } else {
      this.store.renamePlaylist(this.editingId, trimmed);
      this.toast('已重命名');
    }
    this.nameDialogController.close();
    this.reload();
  }

  private confirmDelete(playlist: Playlist): void {
    const id: string = playlist.id;
    const name: string = playlist.name;
    this.getUIContext().showAlertDialog({
      title: '删除歌单',
      message: `确定删除「${name}」？歌单内的歌曲不会从本地库移除。`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.store.deletePlaylist(id);
          this.reload();
          this.toast('已删除歌单');
        }
      }
    });
  }

  /**
   * 播放整张歌单：直接把歌单曲目设为播放队列，避免与本地库全量队列混淆。
   */
  private playPlaylist(playlist: Playlist): void {
    const songs: SongItem[] = this.store.getPlaylistSongs(playlist);
    if (songs.length === 0) {
      this.toast('歌单还没有歌曲');
      return;
    }
    AudioRendererController.getInstance().setQueue(songs, 0, true);
    this.pathStack.pushPathByName('PlayerPage', null);
  }

  @Builder
  buildPlaylistMenu(playlist: Playlist) {
    Menu() {
      MenuItem({ content: '播放', startIcon: $r('app.media.ic_public_play') })
        .onClick(() => {
          this.playPlaylist(playlist);
        })
      MenuItem({ content: '重命名', startIcon: $r('app.media.ic_public_edit') })
        .onClick(() => {
          this.openRenameDialog(playlist);
        })
      MenuItem({ content: '删除歌单', startIcon: $r('app.media.ic_public_delete') })
        .contentFontColor(semanticOf(this.isDark).accent)
        .onClick(() => {
          this.confirmDelete(playlist);
        })
    }
  }

  @Builder
  nameDialogBuilder() {
    PlaylistNameDialog({
      controller: this.nameDialogController,
      title: this.editingId.length === 0 ? '新建歌单' : '重命名歌单',
      defaultName: this.editingName,
      onConfirm: (v: string) => {
        this.onNameConfirm(v);
      }
    })
  }

  @Builder
  buildPlaylistItem(playlist: Playlist, index: number) {
    Row() {
      Stack() {
        CoverImageView({ src: this.getPlaylistCoverSrc(playlist), coverSize: 56, coverRadius: 10 })

        // 空歌单在封面上叠一层列表图标做区分
        if (playlist.songIds.length === 0) {
          Image($r('app.media.ic_public_view_list'))
            .width(24)
            .height(24)
            .fillColor(semanticOf(this.isDark).onAccent)
            .opacity(0.9)
        }
      }
      .width(56)
      .height(56)

      Column() {
        Text(playlist.name)
          .fontSize(TYPE_SM.headline.size)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${playlist.songIds.length} 首歌曲`)
          .fontSize(TYPE_SM.caption1.size)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: SPACE_SM.tight })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: SPACE_SM.cozy, right: SPACE_SM.compact })

      Image($r('app.media.ic_public_play'))
        .width(24)
        .height(24)
        .fillColor(semanticOf(this.isDark).accent)
        .margin({ right: SPACE_SM.base })
        .onClick(() => {
          this.playPlaylist(playlist);
        })
    }
    .width('100%')
    .height(76)
    .padding({ left: SPACE_SM.cozy, right: SPACE_SM.base })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(16)
    .margin({ left: SPACE_SM.compact, right: SPACE_SM.compact, bottom: SPACE_SM.compact })
    .scale({ x: this.itemScales[index] ?? 1.0, y: this.itemScales[index] ?? 1.0 })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 30 })))
    .animation({ duration: 300, curve: LumioTheme.curve(SpringKind.Crisp), delay: this.entryDelay(index) })
    .onClick(() => {
      this.pathStack.pushPathByName('PlaylistDetail', playlist.id);
    })
    .bindContextMenu(this.buildPlaylistMenu(playlist), ResponseType.LongPress)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        const scales: number[] = [...this.itemScales];
        scales[index] = 0.97;
        this.itemScales = scales;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        const scales: number[] = [...this.itemScales];
        scales[index] = 1.0;
        this.itemScales = scales;
      }
    })
  }

  @Builder
  buildSmartItem(pl: SmartPlaylist) {
    Row() {
      Stack() {
        Image($r('app.media.ic_public_view_list'))
          .width(24)
          .height(24)
          .fillColor(semanticOf(this.isDark).accent)
      }
      .width(56)
      .height(56)
      .borderRadius(12)
      .backgroundColor(semanticOf(this.isDark).fillAccentSoft)

      Column() {
        Text(pl.name)
          .fontSize(TYPE_SM.headline.size)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${pl.songs.length} 首`)
          .fontSize(TYPE_SM.caption1.size)
          .fontColor(this.getThemeColors().secondaryText)
          .margin({ top: SPACE_SM.tight })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: SPACE_SM.cozy, right: SPACE_SM.compact })

      Image($r('app.media.ic_public_play'))
        .width(24)
        .height(24)
        .fillColor(semanticOf(this.isDark).accent)
        .margin({ right: SPACE_SM.base })
        .onClick(() => {
          this.playSmart(pl);
        })
    }
    .width('100%')
    .height(76)
    .padding({ left: SPACE_SM.cozy, right: SPACE_SM.base })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(16)
    .margin({ left: SPACE_SM.compact, right: SPACE_SM.compact, bottom: SPACE_SM.compact })
    .onClick(() => {
      this.playSmart(pl);
    })
  }

  private playSmart(pl: SmartPlaylist): void {
    if (pl.songs.length === 0) {
      this.toast(pl.name + ' 暂无歌曲');
      return;
    }
    AudioRendererController.getInstance().setQueue(pl.songs, 0, true);
    this.pathStack.pushPathByName('PlayerPage', null);
  }

  /**
   * 智能歌单分组头部：标题 + 折叠箭头（ic_back_down 旋转表示展开/收起），点击切换 smartCollapsed。
   * 默认展开，用户可收起以聚焦自定义歌单。
   */
  @Builder
  buildSmartGroupHeader() {
    Row() {
      Text('智能歌单')
        .fontSize(TYPE_SM.footnote.size)
        .fontColor(this.getThemeColors().secondaryText)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .margin({ left: SPACE_SM.base, top: SPACE_SM.cozy, bottom: SPACE_SM.compact })

      Image($r('app.media.ic_public_arrow_right'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
        .fillColor(this.getThemeColors().secondaryText)
        .margin({ right: SPACE_SM.base, top: SPACE_SM.compact, bottom: SPACE_SM.compact })
        .rotate({ angle: this.smartCollapsed ? 180 : 0 })
        .animation({ duration: 200, curve: LumioTheme.curve(SpringKind.Crisp) })
    }
    .width('100%')
    .backgroundColor(this.getThemeColors().bg)
    .onClick(() => {
      this.smartCollapsed = !this.smartCollapsed;
    })
  }

  /**
   * 自定义歌单分组头部：仅小标题「我的歌单」（无折叠，自定义歌单为用户必看分区，保持常驻）。
   * 样式对齐智能歌单分组头部，top 略增以与上方智能歌单分组拉开间距。
   */
  @Builder
  buildCustomGroupHeader() {
    Row() {
      Text('我的歌单')
        .fontSize(TYPE_SM.footnote.size)
        .fontColor(this.getThemeColors().secondaryText)
        .fontWeight(FontWeight.Medium)
        .margin({ left: SPACE_SM.base, top: SPACE_SM.base, bottom: SPACE_SM.compact })
    }
    .width('100%')
    .backgroundColor(this.getThemeColors().bg)
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Image($r('app.media.ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .scale({ x: this.backScale, y: this.backScale })
            .animation({ duration: 150, curve: LumioTheme.curve(SpringKind.Crisp) })
            .onClick(() => {
              this.pathStack.pop();
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.backScale = 0.8;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.backScale = 1.0;
              }
            })

          Text('我的歌单')
            .fontSize(TYPE_SM.title2.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: SPACE_SM.cozy })
            .layoutWeight(1)

          Text(`${this.playlists.length} 个`)
            .fontSize(TYPE_SM.footnote.size)
            .fontColor(semanticOf(this.isDark).accent)
            .backgroundColor(semanticOf(this.isDark).fillAccentSoft)
            .borderRadius(12)
            .padding({ left: SPACE_SM.cozy, right: SPACE_SM.cozy, top: SPACE_SM.tight, bottom: SPACE_SM.tight })
            .margin({ right: SPACE_SM.cozy })

          Stack() {
            Text('+')
              .fontSize(TYPE_SM.title1.size)
              .fontWeight(FontWeight.Medium)
              .fontColor(semanticOf(this.isDark).onAccent)
          }
          .width(30)
          .height(30)
          .borderRadius(15)
          .backgroundColor(semanticOf(this.isDark).accent)
          .scale({ x: this.addScale, y: this.addScale })
          .animation({ duration: 150, curve: LumioTheme.curve(SpringKind.Crisp) })
          .onClick(() => {
            this.openCreateDialog();
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.addScale = 0.85;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.addScale = 1.0;
            }
          })
        }
        .width('100%')
        .padding({ left: SPACE_SM.base, right: SPACE_SM.base, top: this.topHeight + 12, bottom: SPACE_SM.base })

        // 整页合并为单个可滚动 List：智能歌单（可折叠分组，默认展开）+ 自定义歌单
        List() {
          ListItemGroup({ header: this.buildSmartGroupHeader() }) {
            if (!this.smartCollapsed) {
              ForEach(SmartPlaylistService.all(), (pl: SmartPlaylist) => {
                ListItem() {
                  this.buildSmartItem(pl)
                }
              }, (pl: SmartPlaylist) => pl.id)
            }
          }

          ListItemGroup({ header: this.buildCustomGroupHeader() }) {
            if (this.playlists.length === 0) {
              ListItem() {
                Column() {
                  Image($r('app.media.ic_public_view_list'))
                    .width(72)
                    .height(72)
                    .fillColor(this.getThemeColors().secondaryText)
                    .margin({ bottom: SPACE_SM.base })
                    // scale 由 startBreathing() 的 animateTo 显式驱动，此处不得再叠加 .animation()
                    .scale({ x: this.emptyIconScale, y: this.emptyIconScale })

                  Text('还没有自建歌单')
                    .fontSize(TYPE_SM.headline.size)
                    .fontColor(this.getThemeColors().secondaryText)
                    .fontWeight(FontWeight.Medium)

                  Text('点击右上角「+」创建第一个歌单')
                    .fontSize(TYPE_SM.footnote.size)
                    .fontColor(semanticOf(this.isDark).labelSecondary)
                    .margin({ top: SPACE_SM.compact })

                  Button('新建歌单')
                    .fontSize(TYPE_SM.subhead.size)
                    .fontColor(semanticOf(this.isDark).onAccent)
                    .backgroundColor(semanticOf(this.isDark).accent)
                    .borderRadius(24)
                    .height(36)
                    .margin({ top: SPACE_SM.roomy })
                    .onClick(() => {
                      this.openCreateDialog();
                    })
                }
                .width('100%')
                .padding({ top: SPACE_SM.block, bottom: SPACE_SM.block })
              }
            } else {
              ForEach(this.playlists, (playlist: Playlist, index: number) => {
                ListItem() {
                  this.buildPlaylistItem(playlist, index)
                }
              }, (playlist: Playlist): string => playlist.id)
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .padding({ bottom: this.bottomHeight + 16 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .onShown(() => {
      // 从详情页返回时刷新歌曲数量，避免计数停留在旧值；同时恢复呼吸动画
      this.pageVisible = true;
      this.reload();
    })
    .onHidden(() => {
      // 页面被压栈到后台时停止空状态动画，避免不可见时空转与回调堆积
      this.pageVisible = false;
      this.isBreathing = false;
    })
    .hideTitleBar(true)
  }
}

/**
 * 歌单命名弹窗（新建 / 重命名共用）。
 */
@CustomDialog
struct PlaylistNameDialog {
  controller: CustomDialogController;
  title: string = '';
  defaultName: string = '';
  onConfirm: (name: string) => void = () => {};
  @StorageProp('isDark') isDark: boolean = false;
  @State inputName: string = '';

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  aboutToAppear(): void {
    this.inputName = this.defaultName;
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(TYPE_SM.title3.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .margin({ top: SPACE_SM.roomy, bottom: SPACE_SM.base })

      TextInput({ text: this.inputName, placeholder: '请输入歌单名称' })
        .width('86%')
        .height(44)
        .maxLength(30)
        .fontColor(this.getThemeColors().primaryText)
        .backgroundColor(this.getThemeColors().secondaryBg)
        .borderRadius(12)
        .onChange((value: string) => {
          this.inputName = value;
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
            this.controller.close();
          })

        Button('确定')
          .layoutWeight(1)
          .height(40)
          .fontSize(TYPE_SM.body.size)
          .fontColor(semanticOf(this.isDark).onAccent)
          .backgroundColor(semanticOf(this.isDark).accent)
          .borderRadius(24)
          .margin({ left: SPACE_SM.cozy })
          .onClick(() => {
            this.onConfirm(this.inputName);
          })
      }
      .width('86%')
      .margin({ top: SPACE_SM.roomy, bottom: SPACE_SM.roomy })
    }
    .width('100%')
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(16)
  }
}
