import { ConfigurationConstant, UIAbility } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import AppStorage from '../common/AppStorage';
// import { Initializer } from '@bdmap/base';

const HILOG_DOMAIN = 0x0000;
const TAG = '[EntryAbility]';

export default class EntryAbility extends UIAbility {
  async onCreate() {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onCreate');

    try {
      await AppStorage.init(this.context.getApplicationContext());
      hilog.info(HILOG_DOMAIN, TAG, 'AppStorage initialized successfully.');
    } catch (error) {
      hilog.error(HILOG_DOMAIN, TAG, 'Failed to initialize AppStorage: %{public}s', JSON.stringify(error));
    }

    // // 初始化百度地图SDK，传入AK密钥
    // try {
    //   const AK_KEY = "xTn4vwunlUWLWilFpx5QcDUOycbq34YZ";
    //   const initializer = Initializer.getInstance();
    //   initializer.initialize(AK_KEY, this.context.getApplicationContext());
    //   hilog.info(HILOG_DOMAIN, TAG, 'Baidu Map SDK initialized successfully with AK');
    // } catch (error) {
    //   hilog.error(HILOG_DOMAIN, TAG, 'Failed to initialize Baidu Map SDK: %{public}s', JSON.stringify(error));
    // }
  }

  onDestroy(): void {
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(HILOG_DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(HILOG_DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(HILOG_DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}
