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

import { Logger } from '../utils/Logger';
import { common, Want } from '@kit.AbilityKit';
import { getAppVersionDisplay } from '../utils/AppInfoUtil';
import { MusicStore } from '../services/MusicStore';
import { SettingsStore, ThemeMode, RepeatModeSetting } from '../utils/SettingsStore';
import { ThemeManager, ColorTokens } from '../utils/ThemeManager';
import { fileIo as fs } from '@kit.CoreFileKit';

interface SettingsCategoryParam {
  category: string;
}

interface CategorySelectOption {
  value: string;
}

@Builder
export function SettingsCategoryBuilder() {
  SettingsCategory()
}

@Component
struct SettingsCategory {
  pathStack: NavPathStack = new NavPathStack();
  store: MusicStore = MusicStore.getInstance();
  settings: SettingsStore = SettingsStore.getInstance();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;

  /** 由上级设置页经路由参数传入的分类 id。 */
  @State category: string = '';

  @State autoNext: boolean = true;
  @State repeatMode: RepeatModeSetting = 'list';
  @State themeMode: ThemeMode = 'system';
  @State notificationLockScreen: boolean = true;
  @State privacyStats: boolean = true;
  @State reduceMotion: boolean = false;
  @State cacheSizeText: string = '约 0.0 MB';
  @State appVersionDisplay: string = 'Lumio Music';

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  aboutToAppear(): void {
    this.appVersionDisplay = getAppVersionDisplay();
    const hostCtx: Context | undefined = this.getUIContext().getHostContext();
    if (hostCtx) {
      this.settings.ensureInitialized(hostCtx).then(() => {
        this.syncFromStore();
      });
    } else {
      this.syncFromStore();
    }
    this.refreshCacheSize();
  }

  private syncFromStore(): void {
    this.autoNext = this.settings.getAutoNext();
    this.repeatMode = this.settings.getRepeatMode();
    this.themeMode = this.settings.getThemeMode();
    this.notificationLockScreen = this.settings.getNotificationLockScreen();
    this.privacyStats = this.settings.getPrivacyStats();
    this.reduceMotion = this.settings.getReduceMotion();
  }

  private toast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message });
    } catch (e) {
      Logger.error('toast failed');
    }
  }

  // ===== 当前分类标题 =====
  private categoryTitle(): string {
    switch (this.category) {
      case 'playback': return '播放';
      case 'appearance': return '用户界面';
      case 'accessibility': return '无障碍';
      case 'storage': return '存储';
      case 'notification': return '通知';
      case 'privacy': return '隐私';
      case 'about': return '关于';
      default: return '设置';
    }
  }

  // ===== Select 选项 =====
  private repeatOptions(): CategorySelectOption[] {
    return [
      { value: '列表循环' },
      { value: '单曲循环' },
      { value: '随机播放' }
    ];
  }

  private repeatIndex(): number {
    const order: RepeatModeSetting[] = ['list', 'single', 'random'];
    return order.indexOf(this.repeatMode);
  }

  private themeOptions(): CategorySelectOption[] {
    return [
      { value: '跟随系统' },
      { value: '浅色' },
      { value: '深色' }
    ];
  }

  private themeIndex(): number {
    const order: ThemeMode[] = ['system', 'light', 'dark'];
    return order.indexOf(this.themeMode);
  }

  // ===== 外跳网页 =====
  private openUrl(url: string): void {
    try {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: url
      };
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      context.startAbility(want).catch((err: Error) => {
        Logger.error('Failed to open url: ' + (err as Error).message);
        this.toast('无法打开网页');
      });
    } catch (err) {
      Logger.error('Failed to open url: ' + (err as Error).message);
      this.toast('无法打开网页');
    }
  }

  private openDeveloper(): void {
    this.openUrl('https://www.a703201sworld.top/resume/');
  }

  // ===== 缓存估算与清理 =====
  private refreshCacheSize(): void {
    this.cacheSizeText = this.computeCacheSize();
  }

  private computeCacheSize(): string {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let total: number = 0;
      total += this.dirSize(ctx.cacheDir);
      const downloadDir: string = ctx.filesDir + '/download';
      total += this.dirSize(downloadDir);
      const mb: number = total / (1024 * 1024);
      return `约 ${mb.toFixed(1)} MB`;
    } catch (e) {
      return '约 0.0 MB';
    }
  }

  private dirSize(path: string): number {
    let size: number = 0;
    try {
      if (!fs.accessSync(path)) {
        return 0;
      }
      const files: string[] = fs.listFileSync(path);
      for (const f of files) {
        const full: string = path + '/' + f;
        try {
          const stat = fs.statSync(full);
          if (stat.isDirectory()) {
            size += this.dirSize(full);
          } else {
            size += stat.size;
          }
        } catch (e) {
          // skip unreadable entry
        }
      }
    } catch (e) {
      // skip
    }
    return size;
  }

  private async clearCache(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.deleteDirContents(ctx.cacheDir);
      const downloadDir: string = ctx.filesDir + '/download';
      this.deleteDirContents(downloadDir);
    } catch (e) {
      // ignore
    }
    this.refreshCacheSize();
  }

  private deleteDirContents(path: string): void {
    try {
      if (!fs.accessSync(path)) {
        return;
      }
      const files: string[] = fs.listFileSync(path);
      for (const f of files) {
        const full: string = path + '/' + f;
        try {
          fs.rmdirSync(full);
        } catch (e) {
          try {
            fs.unlinkSync(full);
          } catch (e2) {
            // ignore
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  // ===== 通用卡片 @Builder =====
  @Builder
  buildSectionLabel(text: string) {
    Text(text)
      .fontSize(13)
      .fontColor(this.getThemeColors().secondaryText)
      .width('100%')
      .padding({ left: 4, top: 16, bottom: 10 })
  }

  @Builder
  buildToggleItem(icon: ResourceStr, title: string, subtitle: string, index: number,
    iconColor: string, isOn: boolean, onToggle: (v: boolean) => void) {
    Row() {
      Stack() {
        Image(icon)
          .width(20)
          .height(20)
          .fillColor(Color.White)
      }
      .width(36)
      .height(36)
      .borderRadius(10)
      .backgroundColor(iconColor)
      .margin({ right: 14 })
      .shadow({ radius: 6, color: `${iconColor}33`, offsetX: 0, offsetY: 2 })

      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: subtitle ? 4 : 0 })
        if (subtitle) {
          Text(subtitle)
            .fontSize(13)
            .fontColor(this.getThemeColors().secondaryText)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.getThemeColors().accent)
        .onChange((value: boolean) => {
          onToggle(value);
        })
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(14)
    .margin({ bottom: 2 })
  }

  @Builder
  buildSelectItem(icon: ResourceStr, title: string, options: CategorySelectOption[], selectedIndex: number,
    index: number, iconColor: string, onSelect: (i: number) => void) {
    Row() {
      Stack() {
        Image(icon)
          .width(20)
          .height(20)
          .fillColor(Color.White)
      }
      .width(36)
      .height(36)
      .borderRadius(10)
      .backgroundColor(iconColor)
      .margin({ right: 14 })
      .shadow({ radius: 6, color: `${iconColor}33`, offsetX: 0, offsetY: 2 })

      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Select(options)
        .selected(selectedIndex)
        .value(options[selectedIndex]?.value?.toString() ?? '')
        .onSelect((i: number, text: string) => {
          onSelect(i);
        })
        .width(140)
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(14)
    .margin({ bottom: 2 })
  }

  @Builder
  buildNavItem(icon: ResourceStr, title: string, subtitle: string, index: number,
    iconColor: string, onClick: () => void) {
    Row() {
      Stack() {
        Image(icon)
          .width(20)
          .height(20)
          .fillColor(Color.White)
      }
      .width(36)
      .height(36)
      .borderRadius(10)
      .backgroundColor(iconColor)
      .margin({ right: 14 })
      .shadow({ radius: 6, color: `${iconColor}33`, offsetX: 0, offsetY: 2 })

      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(this.getThemeColors().primaryText)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: subtitle ? 4 : 0 })
        if (subtitle) {
          Text(subtitle)
            .fontSize(13)
            .fontColor(this.getThemeColors().secondaryText)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_hm_more'))
        .width(16)
        .fillColor(this.getThemeColors().separator)
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.getThemeColors().cardBg)
    .borderRadius(14)
    .margin({ bottom: 2 })
    .onClick(() => {
      onClick();
    })
  }

  // ===== 各分类内容 =====
  @Builder
  buildPlaybackGroup() {
    this.buildSectionLabel('播放');
    Column() {
      this.buildToggleItem(
        $r('app.media.ic_auto'), '自动下一首', '', 0, '#34C759', this.autoNext,
        (v: boolean) => { this.autoNext = v; this.settings.setAutoNext(v); }
      )
      this.buildSelectItem(
        $r('app.media.ic_repeat'), '播放模式', this.repeatOptions(), this.repeatIndex(), 1, '#FF9500',
        (i: number) => {
          const order: RepeatModeSetting[] = ['list', 'single', 'random'];
          this.repeatMode = order[i];
          this.settings.setRepeatMode(order[i]);
        }
      )
    }
    .margin({ bottom: 8 })
  }

  @Builder
  buildAppearanceGroup() {
    this.buildSectionLabel('用户界面');
    Column() {
      this.buildSelectItem(
        $r('app.media.ic_hm_moon'), '深色模式', this.themeOptions(), this.themeIndex(), 0, '#5E5CE6',
        (i: number) => {
          const order: ThemeMode[] = ['system', 'light', 'dark'];
          this.themeMode = order[i];
          ThemeManager.setThemeMode(order[i]);
        }
      )
    }
    .margin({ bottom: 8 })
  }

  @Builder
  buildAccessibilityGroup() {
    this.buildSectionLabel('无障碍');
    Column() {
      this.buildToggleItem(
        $r('app.media.ic_hm_profile'), '降低动态效果', '减少歌词流光等动画', 0, '#007AFF', this.reduceMotion,
        (v: boolean) => { this.reduceMotion = v; this.settings.setReduceMotion(v); }
      )
    }
    .margin({ bottom: 8 })
    // 分类已预置，后续可在本组追加大字号、高对比度等无障碍开关
  }

  @Builder
  buildStorageGroup() {
    this.buildSectionLabel('存储');
    Column() {
      this.buildNavItem(
        $r('app.media.ic_hm_trash'), '清除缓存', this.cacheSizeText, 0, '#FF9500',
        () => { this.showClearCacheDialog(); }
      )
      this.buildNavItem(
        $r('app.media.ic_hm_list'), '清空播放历史', `共 ${this.store.recentlyPlayed.length} 首`, 1, '#FF9500',
        () => {
          this.store.clearRecentlyPlayed();
          this.toast('已清空播放历史');
        }
      )
      this.buildNavItem(
        $r('app.media.ic_hm_folder'), '本地歌曲管理', '', 2, '#FA2759',
        () => { this.pathStack.pushPathByName('ManageSongs', null); }
      )
    }
    .margin({ bottom: 8 })
  }

  @Builder
  buildNotificationGroup() {
    this.buildSectionLabel('通知');
    Column() {
      this.buildToggleItem(
        $r('app.media.ic_bells_o'), '锁屏/状态栏控制', '', 0, '#FFCC00', this.notificationLockScreen,
        (v: boolean) => { this.notificationLockScreen = v; this.settings.setNotificationLockScreen(v); }
      )
    }
    .margin({ bottom: 8 })
  }

  @Builder
  buildPrivacyGroup() {
    this.buildSectionLabel('隐私');
    Column() {
      this.buildToggleItem(
        $r('app.media.ic_favorite'), '启用听歌统计', '', 0, '#FA2759', this.privacyStats,
        (v: boolean) => { this.privacyStats = v; this.settings.setPrivacyStats(v); }
      )
      this.buildNavItem(
        $r('app.media.ic_hm_trash'), '清除统计数据', '', 1, '#FF9500',
        () => { this.showClearStatsDialog(); }
      )
    }
    .margin({ bottom: 8 })
  }

  @Builder
  buildAboutGroup() {
    this.buildSectionLabel('关于');
    Column() {
      this.buildNavItem(
        $r('app.media.ic_hm_settings'), '版本信息', this.appVersionDisplay, 0, '#5856D6',
        () => {}
      )
      this.buildNavItem(
        $r('app.media.ic_hm_profile'), '开发者', '何宇翔', 1, '#34C759',
        () => { this.openDeveloper(); }
      )
      this.buildNavItem(
        $r('app.media.ic_review'), '隐私政策', '', 2, '#007AFF',
        () => { this.pathStack.pushPathByName('PrivacyPolicy', null); }
      )
    }
    .margin({ bottom: 8 })
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Image($r('app.media.ic_hm_back'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .onClick(() => {
              this.pathStack.pop();
            })
          Text(this.categoryTitle())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColors().primaryText)
            .margin({ left: 12 })
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.topHeight + 12, bottom: 16 })

        Scroll() {
          Column() {
            if (this.category === 'playback') {
              this.buildPlaybackGroup();
            } else if (this.category === 'appearance') {
              this.buildAppearanceGroup();
            } else if (this.category === 'accessibility') {
              this.buildAccessibilityGroup();
            } else if (this.category === 'storage') {
              this.buildStorageGroup();
            } else if (this.category === 'notification') {
              this.buildNotificationGroup();
            } else if (this.category === 'privacy') {
              this.buildPrivacyGroup();
            } else if (this.category === 'about') {
              this.buildAboutGroup();
            } else {
              Text('请选择设置分类')
                .fontSize(14)
                .fontColor(this.getThemeColors().secondaryText)
                .width('100%')
                .padding({ left: 4, top: 16 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.getThemeColors().bg)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      const param: Object = context.pathInfo.param as Object;
      if (param !== undefined && param !== null && typeof param === 'object') {
        const cat: string = (param as SettingsCategoryParam).category;
        if (cat !== undefined && cat !== null && cat.length > 0) {
          this.category = cat;
        }
      }
    })
    .hideTitleBar(true)
  }

  private showClearCacheDialog(): void {
    this.getUIContext().showAlertDialog({
      title: '清除缓存',
      message: `确定清除 ${this.cacheSizeText} 的缓存文件？`,
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '清除',
        action: () => {
          this.clearCache().then(() => {
            this.toast('已清除缓存');
          });
        }
      }
    });
  }

  private showClearStatsDialog(): void {
    this.getUIContext().showAlertDialog({
      title: '清除统计数据',
      message: '将清空播放历史等统计数据，且不可恢复。是否继续？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '清除',
        action: () => {
          this.store.clearRecentlyPlayed();
          this.toast('已清除统计数据');
        }
      }
    });
  }
}
