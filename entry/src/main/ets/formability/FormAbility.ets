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

import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { ConfigurationConstant, Want } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { resolveIsDark } from '../common/utils/ThemeResolver';
import type { ThemeMode } from '../utils/SettingsStore';

const TAG = 'FormAbility';

/**
 * 桌面音乐播控卡片能力。
 * - onAddForm/onRemoveForm：登记/注销卡片 formId（持久化到 Preferences，供主应用推送状态）。
 * - 卡片按钮（播放/暂停/上一首/下一首）通过 postCardAction 的 router 事件直接拉起主 EntryAbility，
 *   控制指令经 want.parameters.params 传至 EntryAbility.handleControlWant（onNewWant 处理），实现跨进程回控。
 * - onAddForm 同步下发 isDark（主题深浅），否则卡片首帧恒按浅色渲染。
 */
export default class FormAbility extends FormExtensionAbility {
  /**
   * 读取本进程可见的系统色深，作为 themeMode==='system' 时的跟随来源。
   * 卡片进程无法共享主应用的 AppStorage('systemIsDark')，只能读 Configuration.colorMode；
   * 读取失败时回落到浅色（与 ThemeManager 的兜底策略一致）并记日志，不影响卡片创建。
   */
  private readSystemIsDark(): boolean {
    try {
      return this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    } catch (e) {
      Logger.error(TAG, 'readSystemIsDark failed, fallback to light');
      return false;
    }
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    let formId: string = (want.parameters?.['ohos.extra.param.key.form_identity'] ?? '') as string;
    Logger.info(TAG, `onAddForm formId: ${formId}`);
    // onAddForm 是同步签名，不能 await：主题必须同步读盘得到，不能等主应用推送，
    // 否则主应用未运行时卡片首帧就是浅色。
    // 判定统一走 resolveIsDark()，与主应用 ThemeManager.isDark() 同源，避免两边值漂移。
    let mode: ThemeMode = 'system';
    let systemIsDark: boolean = false;
    if (this.context) {
      mode = PreferencesUtil.getInstance().getThemeModeSync(this.context);
      systemIsDark = this.readSystemIsDark();
      if (formId) {
        PreferencesUtil.getInstance().addFormId(this.context, formId);
      }
    }
    return formBindingData.createFormBindingData({
      title: '',
      artist: '',
      album: '',
      duration: 0,
      isPlaying: false,
      isDark: resolveIsDark(mode, systemIsDark)
    });
  }

  onUpdateForm(formId: string): void {
    // 系统周期性刷新入口；本卡片的状态主要由主应用经 formProvider.updateForm 主动推送，此处无需处理。
    Logger.info(TAG, `onUpdateForm formId: ${formId}`);
  }

  onFormEvent(formId: string, message: string): void {
    // 播放控制已改为卡片 router 事件直接拉起 EntryAbility（见 WidgetCard），
    // 三方应用无法在 FormExtensionAbility 内调用系统 API startAbility，故本回调仅作事件记录。
    Logger.info(TAG, `onFormEvent formId: ${formId}, message: ${message}`);
  }

  onRemoveForm(formId: string): void {
    Logger.info(TAG, `onRemoveForm formId: ${formId}`);
    if (this.context) {
      PreferencesUtil.getInstance().removeFormId(this.context, formId);
    }
  }
}
