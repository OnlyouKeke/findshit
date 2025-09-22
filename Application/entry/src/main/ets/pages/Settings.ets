/**
 * 设置页面
 * 暂时作为占位页面，包含基本的返回功能
 */

import router from '@ohos.router';

@Entry
@Component
struct Settings {
  build() {
    Column() {
      // 顶部导航栏
      this.buildTopBar()
      
      // 主内容区域
      this.buildContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildTopBar() {
    Row() {
      // 返回按钮
      Button() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#333333')
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .borderRadius(20)
      .onClick(() => {
        this.handleBack();
      })

      // 标题
      Text('设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧占位
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
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .shadow({
      radius: 2,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 1
    })
  }

  @Builder
  buildContent() {
    Column() {
      // 占位内容
      Column() {
        Image($r('app.media.ic_settings'))
          .width(64)
          .height(64)
          .fillColor('#CCCCCC')
          .margin({ bottom: 16 })

        Text('设置页面')
          .fontSize(24)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })

        Text('功能开发中...')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 24 })

        Text('未来可能包含的功能：')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 16 })

        this.buildFeatureList()
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .padding(24)
  }

  @Builder
  buildFeatureList() {
    Column({ space: 8 }) {
      this.buildFeatureItem('• 搜索半径设置');
      this.buildFeatureItem('• 地图主题切换');
      this.buildFeatureItem('• 定位精度选择');
      this.buildFeatureItem('• 数据源配置');
      this.buildFeatureItem('• 隐私设置');
      this.buildFeatureItem('• 关于应用');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildFeatureItem(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#999999')
      .width('100%')
      .textAlign(TextAlign.Start)
  }

  /**
   * 处理返回操作
   */
  private handleBack(): void {
    try {
      router.back();
    } catch (error) {
      console.error('Settings: 返回失败', error);
      // 如果router.back()失败，尝试跳转到首页
      router.replaceUrl({
        url: 'pages/Index'
      });
    }
  }
}