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

// ThemeMode 仅作类型引用（import type 编译期擦除），避免把 SettingsStore 及其
// 依赖（MusicStore / AVSessionController）拖进卡片侧的模块图。
import type { ThemeMode } from '../../utils/SettingsStore';

/**
 * 主题深浅判定的**唯一**实现（零依赖纯函数）。
 *
 * 历史缺陷：主应用（ThemeManager）与桌面卡片（FormAbility）各自维护一份
 * 「themeMode -> isDark」判定，卡片侧干脆漏判，导致 isDark 恒为 false，
 * 深色模式用户的桌面卡片一直是浅色。两处独立判定必然发生值漂移，
 * 故抽为本函数供双方共用。
 *
 * 本函数不依赖 window / AppStorage / Preferences 等单例，
 * 因此在主应用进程与 FormExtensionAbility 进程都能安全调用。
 *
 * @param mode 用户选择的主题模式（'system' | 'light' | 'dark'）
 * @param systemIsDark 系统当前是否深色；仅当 mode === 'system' 时生效。
 *                     主应用取 AppStorage('systemIsDark')；
 *                     卡片侧取 FormExtensionContext.config.colorMode。
 * @returns 是否应按深色渲染
 */
export function resolveIsDark(mode: ThemeMode, systemIsDark: boolean): boolean {
  if (mode === 'light') {
    return false;
  }
  if (mode === 'dark') {
    return true;
  }
  // 'system'：跟随系统色深，由调用方按自身可获取的来源注入
  return systemIsDark;
}
