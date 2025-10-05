import router from '@ohos.router';
import { TopBar } from '../widget/TopBar';
import AppStorage from '../common/AppStorage';

@Entry
@Component
struct Settings {
  @State selectedMapEngine: string = 'huawei';
  @StorageLink('searchDistance') searchDistance: number = 500; // 搜索距离，默认500米
  @State searchDistanceExpanded: boolean = false; // 搜索距离选项是否展开
  @State mapEngineExpanded: boolean = false; // 地图引擎选项是否展开

  async aboutToAppear() {
    // 读取已保存的地图引擎选择
    try {
      this.selectedMapEngine = await AppStorage.getInstance().getMapEngine();
    } catch (e) {
      // AppStorage 未初始化时使用默认值
      this.selectedMapEngine = 'huawei';
    }
  }

  private async saveMapEngine(engine: string) {
    try {
      await AppStorage.getInstance().setMapEngine(engine);
    } catch (e) {
      console.warn('保存地图引擎失败:', e as Error);
    }
  }

  build() {
    Column() {
      TopBar({ title: '设置', showBackButton: true })

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
      // 搜索距离设置
      this.buildSearchDistanceSelector()
      
      // 地图引擎选择
      this.buildMapEngineSelector()

      // 查看日志入口
      this.buildLogsEntry()

      // 移除占位内容，让界面更简洁
    }
    .width('100%')
    .layoutWeight(1)
    .padding(24)
  }

  @Builder
  buildSearchDistanceSelector() {
    Column() {
      // 标题行，可点击展开/折叠
      Row() {
        Text('默认搜索距离')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Text(this.getSearchDistanceLabel())
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 8 })

        Text(this.searchDistanceExpanded ? '▲' : '▼')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(16)
      .onClick(() => {
        animateTo({
          duration: 300,
          curve: Curve.EaseInOut
        }, () => {
          this.searchDistanceExpanded = !this.searchDistanceExpanded;
        });
      })

      // 展开的选项内容
      if (this.searchDistanceExpanded) {
        Column({ space: 12 }) {
          this.buildDistanceRadioItem('500米', 500);
          this.buildDistanceRadioItem('1公里', 1000);
          this.buildDistanceRadioItem('2公里', 2000);
          this.buildDistanceRadioItem('5公里', 5000);
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 16 })
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  // 获取当前搜索距离的显示标签
  getSearchDistanceLabel(): string {
    switch (this.searchDistance) {
      case 500: return '500米';
      case 1000: return '1公里';
      case 2000: return '2公里';
      case 5000: return '5公里';
      default: return '500米';
    }
  }

  @Builder
  buildDistanceRadioItem(label: string, value: number) {
    Row({ space: 12 }) {
      Radio({ group: 'searchDistanceGroup', value: value.toString() })
        .checked(this.searchDistance === value)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.searchDistance = value;
          }
        })

      Text(label)
        .fontSize(16)
        .fontColor('#333333')
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .onClick(() => {
      this.searchDistance = value;
    })
  }

  @Builder
  buildMapEngineSelector() {
    Column() {
      // 标题行，可点击展开/折叠
      Row() {
        Text('地图引擎')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)

        Text(this.getMapEngineLabel())
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 8 })

        Text(this.mapEngineExpanded ? '▲' : '▼')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(16)
      .onClick(() => {
        animateTo({
          duration: 300,
          curve: Curve.EaseInOut
        }, () => {
          this.mapEngineExpanded = !this.mapEngineExpanded;
        });
      })

      // 展开的选项内容
      if (this.mapEngineExpanded) {
        Column({ space: 12 }) {
          this.buildRadioItem('华为地图', 'huawei');
          this.buildRadioItem('高德地图', 'amap');
          this.buildRadioItem('百度地图', 'baidu');
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 16 })
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  // 获取当前地图引擎的显示标签
  getMapEngineLabel(): string {
    switch (this.selectedMapEngine) {
      case 'huawei': return '华为地图';
      case 'amap': return '高德地图';
      case 'baidu': return '百度地图';
      default: return '华为地图';
    }
  }

  @Builder
  buildRadioItem(label: string, value: string) {
    Row({ space: 12 }) {
      Radio({ group: 'mapEngineGroup', value: value })
        .checked(this.selectedMapEngine === value)
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectedMapEngine = value;
            // 同步保存到持久化存储
            this.saveMapEngine(value);
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
      this.saveMapEngine(value);
    })
  }

  @Builder
  buildLogsEntry() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text('查看日志')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text('主要内容是定位的位置')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)

        Text('打开')
          .fontSize(14)
          .fontColor('#4C8BF5')
      }
      .width('100%')
      .padding(16)
      .onClick(() => {
        router.pushUrl({ url: 'pages/Logs' });
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 16 })
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }
}