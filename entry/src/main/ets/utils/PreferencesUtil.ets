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

const TAG = 'PreferencesUtil';
const MY_STORE = 'myStore';
const FORM_ID = 'formIds';

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
    return new Promise((resolve, reject) => {
      Logger.info(TAG, JSON.stringify(resolve) + JSON.stringify(reject))
    });
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
}