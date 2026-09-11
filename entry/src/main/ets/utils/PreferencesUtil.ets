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
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from './Logger';
// 仅类型引用（import type 编译期擦除），避免与 SettingsStore 形成运行时循环依赖
// （SettingsStore -> AVSessionController -> PreferencesUtil）。
import type { ThemeMode } from './SettingsStore';

const TAG = 'PreferencesUtil';
const MY_STORE = 'myStore';
const FORM_ID = 'formIds';
const PERM_GUIDE_SHOWN = 'permGuideShown';
const SILENT_MODE = 'silentMode';
const ONBOARDING_SHOWN = 'onboardingShown';
// 主题模式由 SettingsStore 持久化在**独立**库 'app_settings' 的 'theme_mode' 键下，
// 与上面 MY_STORE('myStore') 不是同一个 Preferences 库。
// 两个常量必须与 SettingsStore 中的 PREF_NAME / KEY_THEME_MODE 保持一致，
// 此处不能从 SettingsStore 导入（会形成运行时循环依赖），故显式镜像。
const APP_SETTINGS_STORE = 'app_settings';
const THEME_MODE = 'theme_mode';

export class PreferencesUtil {
  private static preferencesUtil: PreferencesUtil;

  public static getInstance(): PreferencesUtil {
    if (!PreferencesUtil.preferencesUtil) {
      PreferencesUtil.preferencesUtil = new PreferencesUtil();
    }
    return PreferencesUtil.preferencesUtil;
  }

  getPreferences(context: Context): Promise<preferences.Preferences> {
    return new Promise((resolve, reject) => {
      preferences.getPreferences(context, MY_STORE, (err, pref) => {
        if (err) {
          Logger.error(TAG, `Failed to get preferences. Code:${err.code},message:${err.message}`);
          reject(err);
          return;
        }
        resolve(pref);
      })
    })
  }

  preferencesFlush(preference: preferences.Preferences) {
    preference.flush((err) => {
      if (err) {
        Logger.error(TAG, `Failed to flush. Code:${err.code}, message:${err.message}`);
      }
    })
  }

  preferencesPut(preference: preferences.Preferences, formIds: Array<string>): Promise<boolean> {
    return new Promise((resolve, reject) => {
      try {
        preference.put(FORM_ID, formIds, (err) => {
          if (err) {
            reject(err);
            Logger.error(TAG, `Failed to put data. Code:${err.code}, message:${err.message}`);
            return;
          }
          Logger.info(TAG, `preferencesPut succeed,formIds: ${JSON.stringify(formIds)}`);
          resolve(true);
        })
      } catch (error) {
        let err = error as BusinessError;
        Logger.error(TAG, `Failed to put data. message:${err.message}`);
      }
    });
  }

  async preferencesHas(preference: preferences.Preferences): Promise<boolean> {
    return new Promise((resolve, reject) => {
      preference.has(FORM_ID, (err, value) => {
        if (err) {
          reject(err);
          Logger.error(TAG, `WANG to check the key 'formIds'. Code:${err.code}, message:${err.message}`);
          return;
        }
        resolve(value);
      });
    })
  }

  removePreferencesFromCache(context: Context): void {
    try {
      preferences.removePreferencesFromCache(context, MY_STORE);
    } catch (e) {
      Logger.error(TAG, 'removePreferencesFromCache failed');
    }
  }

  async getFormIds(context: Context): Promise<Array<string>> {
    try {
      let preference = await this.getPreferences(context);
      return new Promise((resolve, reject) => {
        if (preference === null) {
          Logger.error(TAG, `preferences is null`);
          resolve([]);
          return;
        }
        preference.get(FORM_ID, [''], (err, value) => {
          if (err) {
            reject(err);
            Logger.error(TAG, `Failed to get value of 'formIds'. Code:${err.code}, message:${err.message}`);
            return;
          }
          resolve(value as Array<string>);
          Logger.info(TAG, `Succeeded in getting value of 'formIds'. val: ${value}.`);
        })
      });
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `WANG Failed to get value of 'formIds'.message:${err.message}`);
    }
    // 兜底：异常分支必须应答，避免所有 await getFormIds(...) 调用方静默挂起
    return [];
  }

  async addFormId(context: Context, formId: string) {
    try {
      let preference = await this.getPreferences(context);
      if (preference === null) {
        Logger.error(TAG, `preferences is null`);
        return;
      }

      if (await this.preferencesHas(preference)) {
        let formIds = await this.getFormIds(context);
        if (formIds.indexOf(formId) === -1) {
          formIds.push(formId);
          if (!await this.preferencesPut(preference, formIds)) {
            return;
          }
          this.preferencesFlush(preference);
        }
      } else {
        if (!await this.preferencesPut(preference, [formId])) {
          return;
        }
        this.preferencesFlush(preference);
      }
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `Failed to check the key 'formIds'. message:${err.message}`);
    }
  }

  /**
   * 同步读取主题模式（'system' | 'light' | 'dark'）。
   *
   * 存在原因：FormAbility.onAddForm 是同步签名，不能 await，
   * 而 SettingsStore 只有内存态 getThemeMode()（卡片进程内从未 init 过，恒为默认值），
   * 故需要一条同步、直接读盘的入口，让主应用未运行时卡片也能拿到正确主题。
   *
   * 注意：themeMode 存在 'app_settings' 库而非本类默认的 'myStore'，
   * 此处必须显式指定库名，否则读到的永远是默认 'system'。
   *
   * @returns 解析后的 ThemeMode；读取失败或值非法时回落到 'system'
   */
  getThemeModeSync(context: Context): ThemeMode {
    try {
      const pref: preferences.Preferences =
        preferences.getPreferencesSync(context, { name: APP_SETTINGS_STORE });
      const value: string = pref.getSync(THEME_MODE, 'system') as string;
      if (value === 'light' || value === 'dark') {
        return value as ThemeMode;
      }
      return 'system';
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      Logger.error(TAG, `getThemeModeSync failed. message:${err.message}`);
      return 'system';
    }
  }

  async isPermGuideShown(context: Context): Promise<boolean> {
    try {
      let preference = await this.getPreferences(context);
      if (preference === null) {
        return false;
      }
      return preference.getSync(PERM_GUIDE_SHOWN, false) as boolean;
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `isPermGuideShown failed. message:${err.message}`);
      return false;
    }
  }

  async markPermGuideShown(context: Context): Promise<void> {
    try {
      let preference = await this.getPreferences(context);
      if (preference === null) {
        return;
      }
      preference.put(PERM_GUIDE_SHOWN, true, (err: BusinessError) => {
        if (!err) {
          preference.flush();
        }
      });
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `markPermGuideShown failed. message:${err.message}`);
    }
  }

  async isOnboardingShown(context: Context): Promise<boolean> {
    try {
      let preference = await this.getPreferences(context);
      if (preference === null) {
        return false;
      }
      return preference.getSync(ONBOARDING_SHOWN, false) as boolean;
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `isOnboardingShown failed. message:${err.message}`);
      return false;
    }
  }

  async markOnboardingShown(context: Context): Promise<void> {
    try {
      let preference = await this.getPreferences(context);
      if (preference === null) {
        return;
      }
      preference.put(ONBOARDING_SHOWN, true, (err: BusinessError) => {
        if (!err) {
          preference.flush();
        }
      });
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `markOnboardingShown failed. message:${err.message}`);
    }
  }

  async removeFormId(context: Context, formId: string) {
    try {
      let preference = await this.getPreferences(context);
      if (preference === null) {
        Logger.error(TAG, `preferences is null`);
        return;
      }
      if (await this.preferencesHas(preference)) {
        let formIds = await this.getFormIds(context);
        let index = formIds.indexOf(formId);
        if (index !== -1) {
          formIds.splice(index, 1);
        }
        if (!await this.preferencesPut(preference, formIds)) {
          return;
        }
        this.preferencesFlush(preference);
      }
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `WANG Failed to get preferences. Code:${err.code},
      message:${err.message}`);
    }
  }

  /**
   * 读取静音（混合播放）标记。独立键，不复用 formIds，避免污染桌面卡片 ID 数组。
   */
  async getSilentMode(context: Context): Promise<boolean> {
    try {
      let preference = await this.getPreferences(context);
      if (preference === null) {
        return false;
      }
      return preference.getSync(SILENT_MODE, false) as boolean;
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `getSilentMode failed. message:${err.message}`);
      return false;
    }
  }

  /**
   * 写入静音（混合播放）标记。独立键，不复用 formIds。
   */
  async setSilentMode(context: Context, value: boolean): Promise<void> {
    try {
      let preference = await this.getPreferences(context);
      if (preference === null) {
        return;
      }
      preference.put(SILENT_MODE, value, (err: BusinessError) => {
        if (!err) {
          preference.flush();
        }
      });
    } catch (error) {
      let err = error as BusinessError;
      Logger.error(TAG, `setSilentMode failed. message:${err.message}`);
    }
  }
}