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

import { MusicStore } from '../services/MusicStore';
import { SettingsStore } from '../utils/SettingsStore';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { SettingsCategoryDetail } from './SettingsCategory';

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
  /** 由外层传入：跳转到更深页（ManageSongs / PrivacyPolicy）时关闭 sheet 并走主导航栈。 */
  onNavigate: (name: string) => void = () => {};
  /** 当前选中的子分类；'' 表示根列表。用于 sheet 内二级导航（无需再开一个 NavDestination）。 */
  @State selectedCategory: string = '';
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
      { id: 'playback', title: '播放', subtitle: '自动下一首 · 播放模式', icon: $r('app.media.ic_repeat'), iconColor: '#FF9500' },
      { id: 'appearance', title: '用户界面', subtitle: '深色模式 · 主题', icon: $r('app.media.ic_hm_moon'), iconColor: '#5E5CE6' },
      { id: 'accessibility', title: '无障碍', subtitle: '降低动态效果', icon: $r('app.media.ic_hm_profile'), iconColor: '#007AFF' },
      { id: 'storage', title: '存储', subtitle: '缓存 · 播放历史 · 本地管理', icon: $r('app.media.ic_hm_trash'), iconColor: '#FF9500' },
      { id: 'notification', title: '通知', subtitle: '锁屏/状态栏控制', icon: $r('app.media.ic_bells_o'), iconColor: '#FFCC00' },
      { id: 'privacy', title: '隐私', subtitle: '听歌统计', icon: $r('app.media.ic_favorite'), iconColor: '#FA2759' },
      { id: 'about', title: '关于', subtitle: '版本 · 开发者 · 隐私政策', icon: $r('app.media.ic_hm_settings'), iconColor: '#5856D6' }
    ];
  }

  private currentTitle(): string {
    if (this.selectedCategory === '') {
      return '设置';
    }
    const found = this.categories().find((c: CategoryItem) => c.id === this.selectedCategory);
    return found ? found.title : '设置';
  }

  build() {
    Column() {
      // 头部：返回箭头在二级页显示，标题随状态切换
      Row() {
        if (this.selectedCategory !== '') {
          Image($r('app.media.ic_hm_back'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .onClick(() => {
              this.selectedCategory = '';
            })
        }
        Text(this.currentTitle())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColors().primaryText)
          .margin({ left: this.selectedCategory !== '' ? 12 : 0 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 16 })

      if (this.selectedCategory === '') {
        Scroll() {
          Column() {
            Text('设置分类')
              .fontSize(13)
              .fontColor(this.getThemeColors().secondaryText)
              .width('100%')
              .padding({ left: 4, bottom: 10 })

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
          onBack: () => {
            this.selectedCategory = '';
          },
          onNavigate: this.onNavigate
        })
          .layoutWeight(1)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 24 })))
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColors().bg)
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
      this.selectedCategory = cat.id;
    })
  }
}
