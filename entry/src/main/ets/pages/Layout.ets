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
import { curves } from '@kit.ArkUI';
import { Motion, springSnappy } from '../common/utils/DesignSystem';
import { image } from '@kit.ImageKit';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { SettingsStore } from '../utils/SettingsStore';
import { OnboardingSheet } from '../components/OnboardingSheet';
import { deviceInfo } from '@kit.BasicServicesKit';
import { AppleUI } from 'com.hm.appleui.hw';
import { semanticOf, onMediaOf } from '../tokens/LumioColor';
import { LumioTheme, SpringKind } from '../tokens/LumioTheme';
import { TYPE_SM, SPACE_SM } from '../tokens/LumioScale';

const PLAYER_COVER_ID: string = 'player_cover';
/** 底部导航胶囊高度（vp）。 */
const NAV_H: number = 56;
/** 导航胶囊距底部安全区的间距（vp）。 */
const NAV_GAP: number = 12;

interface TabItem {
  title: string;
  /** 未选中：Linear 线型图标 */
  icon: Resource;
  /** 选中：Filled 填充图标（iOS 选中态） */
  iconActive: Resource;
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
  // 首次引导（半蒙面 Sheet）调度：AppStorage('showOnboarding') 由首启逻辑或「关于页-重新查看引导」置 true。
  @StorageLink('showOnboarding') @Watch('onShowOnboarding') showOnboarding: boolean = false;
  @State onboardingVisible: boolean = false;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  private tabsController: TabsController = new TabsController();
  private store: MusicStore = MusicStore.getInstance();
  private rotateTimer: number = -1;
  @State currentIndex: number = 0;
  @State coverRotation: number = 0;
  // 底部悬浮导航交互动画状态
  @State playerScale: number = 1.0;
  @State tabScales: number[] = [1.0, 1.0];
  // 底部迷你播放条的封面：缓存当前播放歌曲的真实封面（取自 CoverCache；未抽取到时回退默认图），
  // 通过 refreshPlayerCover() 在切歌 / 封面抽取完成（coverRefreshToken）时刷新。
  @State playerCover: Resource | image.PixelMap = $r('app.media.ic_default_cover');
  // 液态玻璃底部导航：AppleUI 透镜仅提供 arm64-v8a 原生库，ABI 不匹配时回落 cardBg 胶囊。
  @State glassSupported: boolean = false;
  // 导航胶囊实测宽度（供 AppleUI 透镜定尺寸；给合理缺省避免首帧 0 宽）。
  @State navW: number = 336;

  private tabs: TabItem[] = [
    { title: '音乐库', icon: $r('app.media.ic_public_albums'), iconActive: $r('app.media.ic_public_albums_filled') },
    { title: '我的', icon: $r('app.media.ic_public_face'), iconActive: $r('app.media.ic_public_face_filled') }
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
    this.maybeShowOnboarding();
    this.refreshPlayerCover();
    // 液态玻璃透镜自带 arm64-v8a 原生渲染库，ABI 不匹配的设备无法运行其渲染线程；
    // 不满足时回落 cardBg 胶囊，保证底栏在任何设备都可用。
    try {
      const abis: string = deviceInfo.abiList;
      this.glassSupported = abis !== undefined && abis.indexOf('arm64-v8a') >= 0;
    } catch (err) {
      this.glassSupported = false;
    }
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

  /** showOnboarding 变化（首启或关于页重入）时同步 Sheet 可见态。 */
  private onShowOnboarding(): void {
    this.onboardingVisible = this.showOnboarding;
  }

  /** 首次启动展示引导（半蒙面 Sheet），仅弹一次（持久化标记）。 */
  private maybeShowOnboarding(): void {
    const context: common.UIAbilityContext | undefined =
      AppStorage.get('context') as common.UIAbilityContext;
    if (!context) {
      return;
    }
    PreferencesUtil.getInstance().isOnboardingShown(context)
      .then((shown: boolean) => {
        if (shown) {
          return;
        }
        setTimeout(() => {
          AppStorage.setOrCreate('showOnboarding', true);
        }, 600);
      })
      .catch(() => {});
  }

  /** 关闭引导：隐藏 Sheet 并持久化已展示标记（避免下次启动重复弹出）。 */
  private closeOnboarding(): void {
    AppStorage.setOrCreate('showOnboarding', false);
    const context: common.UIAbilityContext | undefined =
      AppStorage.get('context') as common.UIAbilityContext;
    if (context) {
      PreferencesUtil.getInstance().markOnboardingShown(context);
    }
  }

  /** 引导 Sheet 内容构建器（bindSheet 要求 CustomBuilder 入参）。 */
  @Builder
  private onboardingContent() {
    OnboardingSheet({ onClose: () => this.closeOnboarding() })
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
    // 进入播放页同样包在 animateTo 里，让底部栏封面与播放页封面的
    // geometryTransition('player_cover') 接管「一镜到底」——封面从底部栏位置
    // 平滑飞到播放页位置（spring 曲线）。退出时的 back() 已对称包 animateTo，
    // 此前进入遗漏该上下文，导致进入转场消失、只剩退出转场。
    this.getUIContext().animateTo(
      { curve: curves.interpolatingSpring(0, 1, 342, 38) },
      () => {
        this.pathStack.pushPathByName('PlayerPage', null);
      }
    );
  }

  @Builder
  private capsuleTabItem(item: TabItem, index: number) {
    Column({ space: 4 }) {
      // 选中用 Filled、未选中用 Linear（iOS 导航习惯），并沿用 accent 着色
      Image(index === this.currentIndex ? item.iconActive : item.icon)
        .width(26)
        .height(26)
        .fillColor(index === this.currentIndex ? this.getThemeColors().accent : this.getThemeColors().secondaryText)
        .animation({ duration: 160, curve: LumioTheme.curve(SpringKind.Crisp) })

      Text(item.title)
        .fontSize(TYPE_SM.caption2.size)
        .fontColor(index === this.currentIndex ? this.getThemeColors().accent : this.getThemeColors().secondaryText)
        .fontWeight(index === this.currentIndex ? FontWeight.Medium : FontWeight.Regular)
        .animation({ duration: 160, curve: LumioTheme.curve(SpringKind.Crisp) })
    }
    .height('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .scale({ x: this.tabScales[index] ?? 1.0, y: this.tabScales[index] ?? 1.0 })
    .animation({ curve: springSnappy(), duration: Motion.tap })
    .onClick(() => {
      this.tabsController.changeIndex(index);
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        let scales = [...this.tabScales];
        scales[index] = 0.9;
        this.tabScales = scales;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        let scales = [...this.tabScales];
        scales[index] = 1.0;
        this.tabScales = scales;
      }
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
          .borderRadius(16)
          .clip(true)
          .shadow({
            radius: 6,
            color: this.getThemeColors().separator,
            offsetX: 0,
            offsetY: 2
          })
          .geometryTransition(PLAYER_COVER_ID, { follow: true })

        // 封面中央播放状态指示（非交互，点击由 playerButton 打开播放页）。
        // 用可靠位图资源，避免 SymbolGlyph 在部分设备渲染不确定导致图标错乱/误导。
        // 注意：AppStorage('isPlay') 在本入口的运行时绑定与播放态相反（与播放页主按钮一致），
        // 故采用反相映射——实际播放中显示「开始/播放」三角(ic_hm_play)，停止时显示「暂停」双竖条(ic_hm_pause)。
        if (this.isPlaying) {
          this.playStateOverlay($r('app.media.ic_public_pause_norm'))
        } else {
          this.playStateOverlay($r('app.media.ic_public_play_norm'))
        }
      } else {
        Image($r('app.media.ic_public_play_norm'))
          .width(24)
          .height(24)
          .fillColor(semanticOf(this.isDark).onAccent)
      }
    }
    .width(56)
    .height(56)
    .backgroundColor(this.getThemeColors().accent)
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: semanticOf(this.isDark).fillAccentMuted,
      offsetX: 0,
      offsetY: 4
    })
    .scale({ x: this.playerScale, y: this.playerScale })
    .animation({ curve: springSnappy(), duration: Motion.tap })
    .onClick(() => {
      this.openPlayer();
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.playerScale = 0.9;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.playerScale = 1.0;
      }
    })
  }

  /** 封面中央播放状态遮罩图标（不可交互，点击交由 playerButton 打开播放页）。 */
  @Builder
  private playStateOverlay(icon: ResourceStr) {
    Column() {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor(onMediaOf(true).primary)
        .hitTestBehavior(HitTestMode.None)
    }
    .width(48)
    .height(48)
    .borderRadius(16)
    .backgroundColor(onMediaOf(true).scrim)
    .justifyContent(FlexAlign.Center)
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  private miniBarInner() {
    Row({ space: 12 }) {
      Row({ space: 0 }) {
        ForEach(this.tabs, (item: TabItem, index: number) => {
          this.capsuleTabItem(item, index)
        }, (item: TabItem, index: number) => index.toString())
      }
      .layoutWeight(1)
      .height(56)
      .justifyContent(FlexAlign.SpaceEvenly)

      this.playerButton()
    }
    .width('100%')
    .padding({ left: SPACE_SM.compact, right: SPACE_SM.compact })
  }

  /**
   * 导航胶囊宽度探针（隐形，1vp 高）：实测 `92% / max 520` 的可用宽度，
   * 供 AppleUI 透镜与导航内容层定尺寸（AppleUI 的 Width/Height 必须是数值 vp）。
   */
  @Builder
  private navWidthProbe() {
    Row()
      .width('92%')
      .constraintSize({ maxWidth: 520 })
      .height(1)
      .opacity(0)
      .hitTestBehavior(HitTestMode.None)
      .onAreaChange((_oldArea: Area, newArea: Area) => {
        const w: number = typeof newArea.width === 'number' ? newArea.width as number : 0;
        if (w > 0 && Math.abs(w - this.navW) > 0.5) {
          this.navW = w;
        }
      })
  }

  /**
   * 底部导航液态玻璃层（苹果风悬浮胶囊 · 液态玻璃）。
   *
   * 关键：AppleUI 必须**紧跟在内容层（Tabs）之后**作为它的「后一个兄弟」——组件以
   * 「前一个兄弟节点」作为截帧目标，因此透镜折射的正是后方滚动的真实内容（滚动时
   * 玻璃内画面实时跟随），而不是自身。透镜尺寸＝导航胶囊实测尺寸，底部锚定。
   *
   * 回落：AppleUI 只带 arm64-v8a 原生库，ABI 不匹配时改渲染 cardBg 胶囊（同尺寸同位），
   * 保证底栏在任意设备都可用、可读。
   */
  @Builder
  private navGlass() {
    if (this.glassSupported) {
      AppleUI({
        Width: this.navW,
        Height: NAV_H,
        Circle: '100%',
        Blur: 0,
        NeoStrength: 0.26,
        ProUI: false
      })
        .width(this.navW)
        .height(NAV_H)
        .margin({ bottom: this.bottomHeight + NAV_GAP })
    } else {
      Row()
        .width(this.navW)
        .height(NAV_H)
        .backgroundColor(this.getThemeColors().cardBg)
        .borderRadius(NAV_H / 2)
        .shadow({
          radius: 22,
          color: this.getThemeColors().separator,
          offsetX: 0,
          offsetY: 8
        })
        .border({
          width: this.isDark ? 0.5 : 0,
          color: semanticOf(this.isDark).borderSubtle
        })
        .margin({ bottom: this.bottomHeight + NAV_GAP })
    }
  }

  /** 导航内容层：叠在玻璃之上（自身透明），几何与玻璃一致（同宽高同底部间距）。 */
  @Builder
  private navItems() {
    Row() {
      this.miniBarInner()
    }
    .width(this.navW)
    .height(NAV_H)
    .borderRadius(NAV_H / 2)
    .clip(true)
    .margin({ bottom: this.bottomHeight + NAV_GAP })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        this.navWidthProbe()

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
        .backgroundColor(this.getThemeColors().bg)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
        // 全屏沉浸：内容底部仅预留系统导航条安全区 + 少量余量，
        // 列表可滚动至系统导航条区域，浮动底栏覆盖其上方而非预留整块空白。
        .padding({ bottom: this.bottomHeight + 16 })

        this.navGlass()
        this.navItems()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .bindSheet($$this.onboardingVisible, this.onboardingContent(), {
        detents: ['90%'],
        dragBar: true,
        showClose: true,
        onDisappear: () => {
          this.closeOnboarding();
        }
      })
    }
    .hideTitleBar(true)
  }
}
