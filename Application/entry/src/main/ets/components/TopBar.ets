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
    Row() {
      // 左侧设置按钮
      Button() {
        Image($r('app.media.ic_settings'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .borderRadius(20)
      .onClick(() => {
        this.handleSettingsClick();
      })

      // 中间标题
      Text(APP_TITLE)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .layoutWeight(1)

      // 右侧占位（保持对称）
      Blank()
        .width(40)
        .height(40)
    }
    .width('100%')
    .height(56)
    .padding({
      left: 16,
      right: 16,
      top: 8,
      bottom: 8
    })
    .backgroundColor('#FF4081')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
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