import geoLocationManager from '@ohos.geoLocationManager';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HarmonyGeo } from '../common/geo';
import { MapServiceFactory } from '../map/MapServiceFactory';
import { MapService, ToiletPoi } from '../map/MapService';
import AppStorage from '../common/AppStorage';
import { ToiletCard } from '../components/ToiletCard';
import { ErrorBanner } from '../components/ErrorBanner';
import { TopBar } from '../widget/TopBar';

const TAG = 'Index';

@Entry
@Component
struct Index {
  @State isLoading: boolean = false;
  @State toilets: ToiletPoi[] = [];
  @State error: string = '';
  @State center: geoLocationManager.Location | null = null;
  private geoService: HarmonyGeo | null = null;
  private mapService: MapService | null = null;
  private context: common.UIAbilityContext | null = null;

  async aboutToAppear() {
    try {
      this.context = getContext(this) as common.UIAbilityContext;
      if (this.context) {
        this.geoService = new HarmonyGeo(this.context);
        this.mapService = await MapServiceFactory.createMapService();
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(TAG, `Failed to get context, error: ${JSON.stringify(error)}`);
      this.error = `Failed to get context: ${error.message}`;
    }
  }

  async handleFindToilet() {
    if (this.isLoading || !this.geoService || !this.mapService) {
      return;
    }
    this.isLoading = true;
    this.error = '';
    try {
      const hasPermission = await this.geoService!.checkPermission();
      if (!hasPermission) {
        const granted = await this.geoService!.requestPermission();
        if (!granted) {
          this.error = 'Location permission denied';
          this.isLoading = false;
          return;
        }
      }
      const location = await this.geoService!.getCurrentLocation();
      this.center = location;
      const toilets = await this.mapService!.searchNearbyToilets(location.longitude, location.latitude);
      this.toilets = toilets;
    } catch (err) {
      const error = err as Error;
      console.error(TAG, `Failed to find toilets, error: ${JSON.stringify(error)}`);
      this.error = `Failed to find toilets: ${error.message || 'Unknown error'}`;
    } finally {
      this.isLoading = false;
    }
  }

  @State private travelMode: string = 'walking'; // 出行方式：walking 或 cycling

  build() {
    Column() {
      // 主要内容区域
      Column() {
        // 圆形找屎按钮
        Button('找屎')
          .width(120)
          .height(120)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#007DFF')
          .borderRadius(60) // 完全圆形
          .shadow({
            radius: 25,
            color: '#007DFF',
            offsetX: 0,
            offsetY: 10
          })
          .animation({
            duration: 200,
            curve: Curve.EaseInOut
          })
          .onClick(() => this.handleFindToilet())
          
        if (this.isLoading) {
          Text('定位中...')
            .fontSize(18)
            .fontColor('#666666')
            .margin({ top: 30 })
        }
        
        if (this.error) {
          Text(this.error)
            .fontSize(16)
            .fontColor('#FF5722')
            .margin({ top: 20 })
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      
      // 底部出行方式选择器 - 淡化设计
      Column() {
        Text('出行方式')
          .fontSize(14)
          .fontWeight(FontWeight.Normal)
          .fontColor('#999999')
          .margin({ bottom: 12 })
        
        Row() {
          // 步行选项
          Column() {
            Button() {
              Text('🚶')
                .fontSize(20)
            }
            .width(50)
            .height(50)
            .backgroundColor(this.travelMode === 'walking' ? '#007DFF20' : '#F8F8F8')
            .borderRadius(25)
            .border({
              width: this.travelMode === 'walking' ? 2 : 1,
              color: this.travelMode === 'walking' ? '#007DFF' : '#E0E0E0'
            })
            .onClick(() => {
              this.travelMode = 'walking';
            })
            
            Text('步行')
              .fontSize(12)
              .fontColor(this.travelMode === 'walking' ? '#007DFF' : '#999999')
              .fontWeight(this.travelMode === 'walking' ? FontWeight.Medium : FontWeight.Normal)
              .margin({ top: 6 })
          }
          .margin({ right: 40 })
          
          // 骑行选项
          Column() {
            Button() {
              Text('🚴')
                .fontSize(20)
            }
            .width(50)
            .height(50)
            .backgroundColor(this.travelMode === 'cycling' ? '#007DFF20' : '#F8F8F8')
            .borderRadius(25)
            .border({
              width: this.travelMode === 'cycling' ? 2 : 1,
              color: this.travelMode === 'cycling' ? '#007DFF' : '#E0E0E0'
            })
            .onClick(() => {
              this.travelMode = 'cycling';
            })
            
            Text('骑行')
              .fontSize(12)
              .fontColor(this.travelMode === 'cycling' ? '#007DFF' : '#999999')
              .fontWeight(this.travelMode === 'cycling' ? FontWeight.Medium : FontWeight.Normal)
              .margin({ top: 6 })
          }
        }
        .justifyContent(FlexAlign.Center)
      }
      .padding({ top: 15, bottom: 25, left: 20, right: 20 })
      .backgroundColor('#FAFAFA')
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}



