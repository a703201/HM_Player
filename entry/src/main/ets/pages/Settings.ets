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

import { curves } from '@kit.ArkUI';
import { MusicStore } from '../services/MusicStore';
import { SettingsStore } from '../utils/SettingsStore';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { SettingsCategoryDetail } from './SettingsCategory';
import {
  ManageSongsBody,
  DuplicateSongsBody,
  WrappedBody,
  PrivacyPolicyBody
} from '../components/SettingsSubPageBodies';

interface SettingsCategoryParam {
  category: string;
}

interface CategoryItem {
  id: string;
  title: string;
  subtitle: string;
  icon: ResourceStr;
  iconColor: string;
}

@Builder
export function SettingsBuilder() {
  NavDestination() {
    Settings({})
  }
  .hideTitleBar(true)
}

@Component
export struct Settings {
  /** 由外层（Mine 的 bindSheet）传入：关闭整个设置 sheet。 */
  onRequestClose: () => void = () => {};
  /** 当前选中的子分类；'' 表示根列表。用于 sheet 内二级导航（无需再开一个 NavDestination）。 */
  @State selectedCategory: string = '';
  /** Settings sheet 内嵌子页（避免关闭 sheet 再开主导航栈）；'' 表示无子页。 */
  @State subPage: string = '';
  store: MusicStore = MusicStore.getInstance();
  settings: SettingsStore = SettingsStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;

  /** 主题响应式：跟随应用浅色/深色主题（sheet 内页面与全局一致，不强制灰底白字）。 */
  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  /**
   * 设置分类入口。
   */
  private categories(): Array<CategoryItem> {
    return [
      { id: 'playback', title: '播放', subtitle: '自动下一首 · 播放模式', icon: $r('app.media.ic_repeat'), iconColor: this.getThemeColors().secondaryText },
      { id: 'appearance', title: '用户界面', subtitle: '深色模式 · 主题', icon: $r('app.media.ic_hm_moon'), iconColor: this.getThemeColors().secondaryText },
      { id: 'accessibility', title: '无障碍', subtitle: '降低动态效果', icon: $r('app.media.ic_hm_profile'), iconColor: this.getThemeColors().secondaryText },
      { id: 'storage', title: '存储', subtitle: '缓存 · 播放历史 · 本地管理', icon: $r('app.media.ic_hm_trash'), iconColor: this.getThemeColors().secondaryText },
      { id: 'notification', title: '通知', subtitle: '锁屏/状态栏控制', icon: $r('app.media.ic_bells_o'), iconColor: this.getThemeColors().secondaryText },
      { id: 'privacy', title: '隐私', subtitle: '听歌统计', icon: $r('app.media.ic_favorite'), iconColor: this.getThemeColors().secondaryText }
    ];
  }

  private currentTitle(): string {
    if (this.subPage !== '') {
      return this.subPageTitle(this.subPage);
    }
    if (this.selectedCategory === '') {
      return '设置';
    }
    const found = this.categories().find((c: CategoryItem) => c.id === this.selectedCategory);
    return found ? found.title : '设置';
  }

  private subPageTitle(kind: string): string {
    switch (kind) {
      case 'manage': return '本地歌曲管理';
      case 'duplicate': return '重复歌曲清理';
      case 'wrapped': return '我的听歌报告';
      case 'privacy': return '隐私政策';
      default: return '设置';
    }
  }

  /**
   * sheet 内统一返回：优先退出 subPage，再退出 selectedCategory，最后关闭整个 sheet。
   * 系统返回手势（侧滑/虚拟返回键）应只回退这一层栈，而不是直接关掉设置 sheet。
   */
  goBackInSheet(): void {
    if (this.subPage !== '') {
      // 关闭 subPage 回到分类页或设置根
      this.getUIContext().animateTo(
        { curve: curves.interpolatingSpring(0, 1, 360, 36), duration: 240 },
        () => {
          this.subPage = '';
        }
      );
      return;
    }
    if (this.selectedCategory !== '') {
      this.getUIContext().animateTo(
        { curve: curves.interpolatingSpring(0, 1, 360, 36), duration: 240 },
        () => {
          this.selectedCategory = '';
        }
      );
      return;
    }
    // 设置根：关闭 sheet（外层 Mine 处理）
    this.onRequestClose();
  }

  /** 进入 subPage：sheet 内动画切到对应子页（管理/重复/听歌报告/隐私政策）。 */
  openSubPage(kind: string): void {
    if (this.subPage === kind) {
      return;
    }
    this.getUIContext().animateTo(
      { curve: curves.interpolatingSpring(0, 1, 360, 36), duration: 280 },
      () => {
        this.subPage = kind;
      }
    );
  }

  build() {
    Column() {
      // 头部：返回箭头在二级页显示，标题随状态切换
      Row() {
        if (this.subPage !== '' || this.selectedCategory !== '') {
          Image($r('app.media.ic_hm_back'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .onClick(() => this.goBackInSheet())
        }
        Text(this.currentTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColors().primaryText)
          .margin({ left: (this.subPage !== '' || this.selectedCategory !== '') ? 12 : 0 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 16 })

      // 渲染优先级：subPage > selectedCategory > 根列表
      if (this.subPage === 'manage') {
        ManageSongsBody({ onBack: () => this.goBackInSheet(), showHeader: false })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 32 })))
      } else if (this.subPage === 'duplicate') {
        DuplicateSongsBody({ onBack: () => this.goBackInSheet(), showHeader: false })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 32 })))
      } else if (this.subPage === 'wrapped') {
        WrappedBody({ onBack: () => this.goBackInSheet(), showHeader: false })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 32 })))
      } else if (this.subPage === 'privacy') {
        PrivacyPolicyBody({ onBack: () => this.goBackInSheet(), showHeader: false })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 32 })))
      } else if (this.selectedCategory === '') {
        Scroll() {
          Column() {
            Column() {
              ForEach(this.categories(), (cat: CategoryItem) => {
                this.buildCategoryItem(cat);
              }, (cat: CategoryItem): string => cat.id)
            }
            .margin({ bottom: 8 })

            Text('Made with HarmonyOS SDK')
              .fontSize(12)
              .fontColor(this.getThemeColors().secondaryText)
              .margin({ top: 24, bottom: 20 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: -24 })))
      } else {
        SettingsCategoryDetail({
          category: this.selectedCategory,
          onBack: () => this.goBackInSheet(),
          onNavigate: (name: string) => this.openSubPage(this.routeToSubPage(name))
        })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 24 })))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColors().bg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  /** 把分类页中 onNavigate 调用的目标名映射到 sheet 内 subPage。 */
  private routeToSubPage(name: string): string {
    if (name === 'ManageSongs') {
      return 'manage';
    }
    if (name === 'DuplicateSongs') {
      return 'duplicate';
    }
    if (name === 'Wrapped') {
      return 'wrapped';
    }
    if (name === 'PrivacyPolicy') {
      return 'privacy';
    }
    return '';
  }

  @Builder
  buildCategoryItem(cat: CategoryItem) {
    Row() {
      Image(cat.icon)
        .width(24)
        .height(24)
        .fillColor(cat.iconColor)
        .margin({ right: 16 })

      Column() {
        Text(cat.title)
          .fontSize(16)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })
        Text(cat.subtitle)
          .fontSize(13)
          .fontColor(this.getThemeColors().secondaryText)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_hm_more'))
        .width(16)
        .fillColor(this.getThemeColors().separator)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(14)
    .margin({ bottom: 2 })
    .onClick(() => {
      this.getUIContext().animateTo(
        { curve: curves.interpolatingSpring(0, 1, 360, 36), duration: 240 },
        () => {
          this.selectedCategory = cat.id;
        }
      );
    })
  }
}
