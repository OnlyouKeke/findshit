/**
 * 顶部栏组件
 * 包含左上角设置按钮和中间标题
 */

import router from '@ohos.router';
import { APP_TITLE } from '../common/config';

@Component
export struct TopBar {
  // 设置按钮点击回调
  private onSettingsClick?: () => void;

  build() {
    // 顶栏已移除，避免占位
    Blank()
      .width(0)
      .height(0)
      .visibility(Visibility.None)
  }

  /**
   * 处理设置按钮点击
   */
  private handleSettingsClick(): void {
    try {
      if (this.onSettingsClick) {
        this.onSettingsClick();
      } else {
        // 默认跳转到设置页面
        router.pushUrl({
          url: 'pages/Settings'
        });
      }
    } catch (error) {
      console.error('TopBar: 跳转设置页面失败', error);
    }
  }
}
