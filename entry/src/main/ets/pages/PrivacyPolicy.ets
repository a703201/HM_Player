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

@Builder
export function PrivacyPolicyBuilder() {
  PrivacyPolicy()
}

@Component
struct PrivacyPolicy {
  pathStack: NavPathStack = new NavPathStack();
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('isDark') isDark: boolean = false;

  private getThemeColors(): ColorTokens {
    return this.isDark ? ThemeManager.darkColors : ThemeManager.lightColors;
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Image($r('app.media.ic_hm_back'))
            .width(24)
            .height(24)
            .fillColor(this.getThemeColors().primaryText)
            .onClick(() => {
              this.pathStack.pop();
            })

          Text('隐私政策')
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
            this.buildSection(
              '概述',
              'Lumio Music 是一款纯离线本地音乐播放器。你的歌曲、收藏、歌单与设置全部保存在设备本地，不提供云端服务、不要求注册账号、不集成任何第三方 SDK。除你主动触发的局域网投播与第三方网页跳转外，应用不会向任何外部服务器传输你的数据。'
            )
            this.buildSection(
              '我们收集的信息',
              '我们不收集任何个人身份信息。你看到的「曲库」仅由你主动导入的本地音频文件解析而来，应用仅读取并展示其元数据：曲名、歌手、专辑、时长。收藏、歌单、播放与主题设置等均由你的本地操作产生，仅保存在本机，我们不会采集你的位置、设备标识符、账号或浏览行为等任何个人信息。'
            )
            this.buildSection(
              '信息存储位置',
              '上述所有数据均存储在设备本地的应用沙箱目录（Preferences 与文件目录）中，与其他应用隔离，仅本应用可访问，不会上传到任何服务器，也不会离开你的设备。卸载应用后，本地沙箱数据会随之删除。'
            )
            this.buildSection(
              '权限说明',
              '本应用仅申请以下权限：\n' +
              '• 后台运行（KEEP_BACKGROUND_RUNNING）：用于锁屏或离开应用后继续播放音乐。\n' +
              '• 网络访问（INTERNET）：仅用于（1）将本地音频经局域网投送到你主动选择的设备；（2）点击「开发者主页」等入口时调用系统浏览器打开第三方网页 a703201sworld.top。我们不会用它上传你的音乐或个人数据。'
            )
            this.buildSection(
              '投播（局域网）传输',
              '投播通过系统 AVSessionKit 的 AVCastController，将你设备上正在播放的本地音频经局域网（Wi-Fi）传输到你主动选择的设备（如智能音箱 / 电视）。传输仅发生在你的局域网内，不经过云端，且仅在你主动点击投送并选定设备时才会发起。'
            )
            this.buildSection(
              '第三方外链',
              '在「设置 - 关于开发者」等入口，本应用提供跳转链接 https://www.a703201sworld.top/resume/（开发者主页）。点击时仅由系统浏览器打开该网页，应用不嵌入也不向其传输你的数据。该网页由第三方运营，其隐私实践由该网站自行负责。'
            )
            this.buildSection(
              '日志与脱敏',
              '我们已对日志进行整改：原先可能写入系统日志的媒体文件路径、歌名等敏感信息，已改用 Logger 的 *Private 接口脱敏，确保日志中不会出现可定位到你文件的路径或可识别的歌名，也不记录任何个人信息。'
            )
            this.buildSection(
              '我们的承诺',
              '我们不做以下事情：无云端同步 / 存储；不向任何第三方共享、出售或传输你的数据；不集成任何会收集信息的第三方 SDK；不展示广告；不进行埋点、数据统计或行为分析；不要求注册账号，不收集个人身份信息。'
            )
            this.buildSection(
              '你的权利与联系方式',
              '你完全掌控自己的本地数据：可在「设置」中清除缓存、清除听歌统计、关闭相关功能；卸载应用即可删除全部本地数据。\n' +
              '如有疑问或需行使相关权利，请联系：\n' +
              '主体 / 开发者名称：何宇翔\n' +
              '联系邮箱：Lumio_a7032@qq.com'
            )
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
    })
    .hideTitleBar(true)
  }

  @Builder
  buildSection(title: string, body: string) {
    Column() {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getThemeColors().primaryText)
        .width('100%')
        .margin({ bottom: 8 })

      Text(body)
        .fontSize(14)
        .fontColor(this.getThemeColors().secondaryText)
        .width('100%')
        .lineHeight(22)
    }
    .width('100%')
    .margin({ bottom: 24 })
  }
}
