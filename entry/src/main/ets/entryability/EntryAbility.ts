import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import hilog from '@ohos.hilog';

const TAG = '[EntryAbility]';
const DOMAIN = 0x0001;

/**
 * 智能照明系统入口能力
 * Smart Lighting System Entry Ability
 */
export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(DOMAIN, TAG, '智能照明系统启动 Ability onCreate');
  }

  onDestroy() {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, '加载页面失败 Failed to load the content. Cause: %{public}s',
          JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, TAG, '成功加载页面 Succeeded in loading the content. Data: %{public}s',
        JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground() {
    // Ability has back to background
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
