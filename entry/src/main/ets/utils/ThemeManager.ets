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
import { resolveIsDark } from '../common/utils/ThemeResolver';
import { AVSessionController } from './AVSessionController';
import { LIGHT_SEMANTIC, DARK_SEMANTIC } from '../tokens/LumioColor';

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
  surfaceOverlay: string;// 覆盖表面（sheet/弹层/毛玻璃兜底），值同 cardBg(#FFF/#1C1C1E)，仅命名不同
  primaryText: string;   // 主文字
  secondaryText: string; // 次文字/副标题
  separator: string;     // 分隔线
  accent: string;        // 品牌强调色
}

// 收敛到 tokens/LumioColor 语义令牌（单一权威来源）。
// 仅映射 ColorTokens 的 7 个字段；其余语义色经 LumioTheme 取用。
// 注意：secondaryText(light) 由 #8E8E93 收敛为 labelSecondary 的 #6E6E73（对比度 3.26→5.07:1，达 WCAG AA）。
const LIGHT_TOKENS: ColorTokens = {
  // P3 表面层级翻转：浅色模式页面底改为分组灰(surfaceGrouped)，卡片改为白(surfaceGroupedContent)，
  // 形成 iOS「灰底白卡」分组层级。深色模式 surfaceGrouped/surfaceGroupedContent 与原值一致，无回归。
  bg: LIGHT_SEMANTIC.surfaceGrouped,
  secondaryBg: LIGHT_SEMANTIC.backgroundSecondary,
  cardBg: LIGHT_SEMANTIC.surfaceGroupedContent,
  surfaceOverlay: LIGHT_SEMANTIC.surfaceOverlay,
  primaryText: LIGHT_SEMANTIC.label,
  secondaryText: LIGHT_SEMANTIC.labelSecondary,
  separator: LIGHT_SEMANTIC.separator,
  accent: LIGHT_SEMANTIC.accent
};

const DARK_TOKENS: ColorTokens = {
  bg: DARK_SEMANTIC.surfaceGrouped,
  secondaryBg: DARK_SEMANTIC.backgroundSecondary,
  cardBg: DARK_SEMANTIC.surfaceGroupedContent,
  surfaceOverlay: DARK_SEMANTIC.surfaceOverlay,
  primaryText: DARK_SEMANTIC.label,
  secondaryText: DARK_SEMANTIC.labelSecondary,
  separator: DARK_SEMANTIC.separator,
  accent: DARK_SEMANTIC.accent
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
    // 判定统一委托给 resolveIsDark()，与桌面卡片（FormAbility）同源，避免两处独立判定产生值漂移。
    // system：读取 EntryAbility 在 onConfigurationUpdated 中写入的 systemIsDark
    return resolveIsDark(mode, AppStorage.get<boolean>('systemIsDark') ?? false);
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

  /** 用户手动切换主题模式：持久化 + 刷新 AppStorage + 同步系统栏。 */
  static setThemeMode(mode: ThemeMode): void {
    SettingsStore.getInstance().setThemeMode(mode);
    AppStorage.setOrCreate('themeMode', mode);
    AppStorage.setOrCreate('isDark', ThemeManager.isDark());
    ThemeManager.applyToWindow();
    ThemeManager.pushCardThemeUpdate();
  }

  /**
   * 系统主题变更时刷新（仅 themeMode==='system' 时由 EntryAbility 调用生效）。
   *
   * ⚠️ 这是卡片主题更新的**主要**路径，不是可选优化：SettingsStore 里 themeMode 默认值就是
   * 'system'，绝大多数用户处于跟随系统模式，他们切换系统深色的唯一触发点就是这里。
   * 若此处不推卡片，这些用户的桌面卡片会一直停在浅色，缺陷 1 对他们等于没修。
   */
  static refreshSystemTheme(): void {
    AppStorage.setOrCreate('isDark', ThemeManager.isDark());
    ThemeManager.applyToWindow();
    ThemeManager.pushCardThemeUpdate();
  }

  /**
   * 主题变化后向已添加的桌面卡片推送一次新的 isDark。
   * 卡片运行在独立进程，不会跟随主应用重绘，必须由主应用显式推送。
   * 卡片可能尚未创建 / 主应用 context 未就绪，失败仅记日志，绝不打断主题切换流程。
   */
  private static pushCardThemeUpdate(): void {
    try {
      AVSessionController.getInstance().pushFormUpdate();
    } catch (e) {
      Logger.error('pushFormUpdate on theme change failed');
    }
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
