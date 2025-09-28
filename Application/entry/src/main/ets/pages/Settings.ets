import router from '@ohos.router';
import { TopBar } from '../widget/TopBar';

@Entry
@Component
struct Settings {
  @State selectedMapEngine: string = 'huawei';

  build() {
    Column() {
      TopBar({ title: '设置' })

      // 主内容区域
      this.buildContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildContent() {
    Column() {
      // 地图引擎选择
      this.buildMapEngineSelector()

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
  buildMapEngineSelector() {
    Column({ space: 12 }) {
      Text('地图引擎')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
        .textAlign(TextAlign.Start)

      Column({ space: 12 }) {
        this.buildRadioItem('华为地图', 'huawei');
        this.buildRadioItem('高德地图', 'amap');
        this.buildRadioItem('百度地图', 'baidu');
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 24 })
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  buildRadioItem(label: string, value: string) {
    Row({ space: 12 }) {
      Radio({ group: 'mapEngineGroup', value: value })
        .checked(this.selectedMapEngine === value)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectedMapEngine = value;
          }
        })

      Text(label)
        .fontSize(16)
        .fontColor('#333333')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      this.selectedMapEngine = value;
    })
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
}