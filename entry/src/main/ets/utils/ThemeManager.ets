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

import { Logger } from './Logger';
import { window } from '@kit.ArkUI';
import { SettingsStore, ThemeMode } from './SettingsStore';
import { AppleTokens, appleColors } from '../common/utils/DesignSystem';

/**
 * 全应用主题管理器。
 * - AppStorage 存 'themeMode'（system/light/dark）与派生的 'isDark'（boolean）。
 * - 页面通过 ThemeManager.getColors() 取语义色令牌（light/dark 两套）。
 * - themeMode==='system' 时跟随系统：isDark() 读取 ApplicationContext 的 ColorMode。
 * - EntryAbility 在 onConfigurationUpdated 中调用 refreshSystemTheme() 刷新，
 *   并在窗口就绪后调用 applyToWindow() 同步状态栏/导航栏内容色。
 *
 * 品牌色 accent 始终保持 #FA2759。
 */

export interface ColorTokens {
  bg: string;            // 页面背景
  secondaryBg: string;   // 分组头/带状背景
  cardBg: string;        // 卡片背景
  primaryText: string;   // 主文字
  secondaryText: string; // 次文字/副标题
  separator: string;     // 分隔线
  accent: string;        // 品牌强调色
}

const LIGHT_TOKENS: ColorTokens = {
  bg: '#FFFFFF',
  secondaryBg: '#FAFAFA',
  cardBg: '#F2F2F7',
  primaryText: '#1C1C1E',
  secondaryText: '#8E8E93',
  separator: '#E5E5EA',
  accent: '#FA2759'
};

const DARK_TOKENS: ColorTokens = {
  bg: '#000000',
  secondaryBg: '#1C1C1E',
  cardBg: '#1C1C1E',
  primaryText: '#FFFFFF',
  secondaryText: '#98989F',
  separator: '#2C2C2E',
  accent: '#FA2759'
};

export class ThemeManager {
  /** 应用启动时调用：读取持久化 themeMode，写入 AppStorage 并派生 isDark。 */
  static init(): void {
    const mode: ThemeMode = SettingsStore.getInstance().getThemeMode();
    AppStorage.setOrCreate('themeMode', mode);
    AppStorage.setOrCreate('isDark', ThemeManager.isDark());
  }

  /** 当前是否深色：system 模式读系统 ColorMode。 */
  static isDark(): boolean {
    const mode: ThemeMode = (AppStorage.get<string>('themeMode') ?? 'system') as ThemeMode;
    if (mode === 'light') {
      return false;
    }
    if (mode === 'dark') {
      return true;
    }
    // system：读取 EntryAbility 在 onConfigurationUpdated 中写入的 systemIsDark
    return AppStorage.get<boolean>('systemIsDark') ?? false;
  }

  /** 取当前语义色令牌（页面据此着色）。 */
  static getColors(): ColorTokens {
    const isDark: boolean = AppStorage.get<boolean>('isDark') ?? false;
    return isDark ? DARK_TOKENS : LIGHT_TOKENS;
  }

  /** 浅色令牌（静态访问，供组件响应式 getter 使用）。 */
  static get lightColors(): ColorTokens {
    return LIGHT_TOKENS;
  }

  /** 深色令牌（静态访问，供组件响应式 getter 使用）。 */
  static get darkColors(): ColorTokens {
    return DARK_TOKENS;
  }

  /**
   * 取当前主题的 Apple 语义色令牌（iOS 风格分层背景/填充/标签/系统色）。
   * 组件通过 @StorageProp('isDark') 已具备响应性，直接调用即可随主题刷新。
   */
  static apple(): AppleTokens {
    return appleColors(ThemeManager.isDark());
  }

  /** 用户手动切换主题模式：持久化 + 刷新 AppStorage + 同步系统栏。 */
  static setThemeMode(mode: ThemeMode): void {
    SettingsStore.getInstance().setThemeMode(mode);
    AppStorage.setOrCreate('themeMode', mode);
    AppStorage.setOrCreate('isDark', ThemeManager.isDark());
    ThemeManager.applyToWindow();
  }

  /** 系统主题变更时刷新（仅 themeMode==='system' 时由 EntryAbility 调用生效）。 */
  static refreshSystemTheme(): void {
    AppStorage.setOrCreate('isDark', ThemeManager.isDark());
    ThemeManager.applyToWindow();
  }

  /** 同步状态栏/导航栏内容色（深色用白色，浅色用深色）。 */
  static applyToWindow(): void {
    const win: window.Window | undefined = AppStorage.get<window.Window>('window');
    if (!win) {
      return;
    }
    const isDark: boolean = ThemeManager.isDark();
    const contentColor: string = isDark ? '#FFFFFF' : '#1C1C1E';
    try {
      win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: contentColor,
        navigationBarColor: '#00000000',
        navigationBarContentColor: contentColor
      });
    } catch (e) {
      Logger.error('applyToWindow failed');
    }
  }
}
