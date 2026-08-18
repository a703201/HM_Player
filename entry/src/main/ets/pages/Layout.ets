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

import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { LocalLibrary } from './LocalLibrary';
import { Mine } from './Mine';
import { MusicStore } from '../services/MusicStore';
import { SongItem } from '../models/music';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { SettingsStore } from '../utils/SettingsStore';

const ACCENT: string = '#FA2759';
const PLAYER_COVER_ID: string = 'player_cover';

interface TabItem {
  title: string;
  icon: Resource;
}

@Builder
export function LayoutBuilder() {
  Layout()
}

@Component
struct Layout {
  @Consume('navPathStack') pathStack: NavPathStack;
  @StorageLink('isPlay') isPlaying: boolean = false;
  @StorageLink('songList') @Watch('refreshPlayerCover') songList: SongItem[] = [];
  @StorageProp('selectIndex') @Watch('refreshPlayerCover') selectIndex: number = 0;
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('bottomHeight') bottomHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;
  @StorageProp('coverRefreshToken') @Watch('onCoverRefreshed') coverRefreshToken: number = 0;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  private tabsController: TabsController = new TabsController();
  private store: MusicStore = MusicStore.getInstance();
  private rotateTimer: number = -1;
  @State currentIndex: number = 0;
  @State coverRotation: number = 0;
  // 底部迷你播放条的封面：缓存当前播放歌曲的真实封面（取自 CoverCache；未抽取到时回退默认图），
  // 通过 refreshPlayerCover() 在切歌 / 封面抽取完成（coverRefreshToken）时刷新。
  @State playerCover: Resource | image.PixelMap = $r('app.media.ic_default_cover');

  private tabs: TabItem[] = [
    { title: '音乐库', icon: $r('sys.symbol.music_square_stack_fill') },
    { title: '我的', icon: $r('sys.symbol.person') }
  ];

  aboutToAppear(): void {
    AppStorage.setOrCreate('songList', this.store.songs);
    // R-18/F-13：降低动态效果开启时禁用封面旋转定时器
    if (!SettingsStore.getInstance().getReduceMotion()) {
      this.rotateTimer = setInterval(() => {
        if (this.isPlaying) {
          this.coverRotation = (this.coverRotation + 1.6) % 360;
        }
      }, 40);
    }
    this.maybeShowPermissionGuide();
    this.refreshPlayerCover();
  }

  // 首次启动展示权限用途说明，仅弹一次（持久化标记）
  private maybeShowPermissionGuide(): void {
    const context: common.UIAbilityContext | undefined =
      AppStorage.get('context') as common.UIAbilityContext;
    if (!context) {
      return;
    }
    PreferencesUtil.getInstance().isPermGuideShown(context)
      .then((shown: boolean) => {
        if (shown) {
          return;
        }
        // 延迟一点，避免与首屏转场抢弹窗
        setTimeout(() => {
          this.getUIContext().showAlertDialog({
            title: $r('app.string.perm_guide_title'),
            message: $r('app.string.perm_guide_message'),
            primaryButton: {
              value: $r('app.string.perm_guide_ok'),
              action: () => {
                PreferencesUtil.getInstance().markPermGuideShown(context);
              }
            }
          });
        }, 400);
      })
      .catch(() => {});
  }

  aboutToDisappear(): void {
    if (this.rotateTimer >= 0) {
      clearInterval(this.rotateTimer);
    }
  }

  private onCoverRefreshed(): void {
    // coverRefreshToken 变化（导入/重启后 CoverCache 批量抽取完成）即重读当前播放歌曲的封面。
    this.refreshPlayerCover();
  }

  /**
   * 刷新迷你播放条封面：始终取当前播放歌曲的真实封面（CoverCache 命中时为 PixelMap，否则回退默认图）。
   * 在切歌（selectIndex 变化）、队列变化（songList 变化）、封面抽取完成（coverRefreshToken）时调用。
   */
  private refreshPlayerCover(): void {
    if (this.songList.length === 0 || !this.songList[this.selectIndex]) {
      this.playerCover = $r('app.media.ic_default_cover');
      return;
    }
    this.playerCover = this.songList[this.selectIndex].getLabel();
  }

  private openPlayer(): void {
    // 直接 push：让底部栏封面与播放页封面的 geometryTransition('player_cover') 接管"一镜到底"，
    // 封面从底部栏位置平滑飞到播放页位置，而不是整页滑动（背景位移）的感觉。
    this.pathStack.pushPathByName('PlayerPage', null);
  }

  @Builder
  private capsuleTabItem(item: TabItem, index: number) {
    Column({ space: 4 }) {
      SymbolGlyph(item.icon)
        .fontSize(22)
        .fontColor([index === this.currentIndex ? ACCENT : this.getThemeColors().secondaryText])
        .animation({ duration: 160, curve: Curve.EaseOut })

      Text(item.title)
        .fontSize(11)
        .fontColor(index === this.currentIndex ? ACCENT : this.getThemeColors().secondaryText)
        .fontWeight(index === this.currentIndex ? FontWeight.Medium : FontWeight.Regular)
        .animation({ duration: 160, curve: Curve.EaseOut })
    }
    .height('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.tabsController.changeIndex(index);
    })
  }

  @Builder
  private playerButton() {
    Stack() {
      if (this.songList.length > 0) {
        // 一镜到底共享元素：与播放页同用 getLabel() 取到的真实封面，两端内容一致、过渡更稳
        Image(this.playerCover)
          .width(48)
          .height(48)
          .borderRadius(14)
          .clip(true)
          .shadow({
            radius: 6,
            color: 'rgba(0, 0, 0, 0.20)',
            offsetX: 0,
            offsetY: 2
          })
          .geometryTransition(PLAYER_COVER_ID, { follow: true })

        // 暂停时在封面中央显示暂停图标
        if (!this.isPlaying) {
          Column()
            .width(48)
            .height(48)
            .borderRadius(14)
            .backgroundColor('rgba(0, 0, 0, 0.35)')
            .justifyContent(FlexAlign.Center)
            .hitTestBehavior(HitTestMode.None)
          SymbolGlyph($r('sys.symbol.pause_fill'))
            .fontSize(22)
            .fontColor(['#FFFFFF'])
            .hitTestBehavior(HitTestMode.None)
        }
      } else {
        Image($r('app.media.ic_hm_play'))
          .width(24)
          .height(24)
          .fillColor('#FFFFFF')
      }
    }
    .width(56)
    .height(56)
    .backgroundColor(ACCENT)
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: 'rgba(250, 39, 89, 0.35)',
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.openPlayer();
    })
  }

  @Builder
  private customBottomBar() {
    Row({ space: 16 }) {
      Row({ space: 0 }) {
        ForEach(this.tabs, (item: TabItem, index: number) => {
          this.capsuleTabItem(item, index)
        }, (item: TabItem, index: number) => index.toString())
      }
      .width('100%')
      .height(64)
      .backgroundColor(this.getThemeColors().cardBg)
      .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
      .borderRadius(32)
      .padding({ left: 8, right: 8 })
      .shadow({
        radius: 16,
        color: 'rgba(0, 0, 0, 0.10)',
        offsetX: 0,
        offsetY: 6
      })
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceEvenly)

      this.playerButton()
    }
    .width('100%')
    .height(80)
    .padding({ left: 16, right: 16, bottom: this.bottomHeight + 8 })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
          TabContent() {
            LocalLibrary()
          }

          TabContent() {
            Mine()
          }
        }
        .barHeight(0)
        .scrollable(false)
        .animationDuration(200)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
        .padding({ bottom: 96 + this.bottomHeight })

        this.customBottomBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
  }
}
