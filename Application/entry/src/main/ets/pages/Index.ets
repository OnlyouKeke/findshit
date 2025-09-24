/**
 * 找屎应用主页
 * 包含地图视图(70%)与底部卡片(30%)，右上角悬浮设置按钮
 */

import { ToiletCard } from '../components/ToiletCard';
import { ErrorBanner, BannerType } from '../components/ErrorBanner';
import { LatLng, ToiletPoi, AppState } from '../common/types';
import { DEFAULT_CENTER, DEFAULT_ZOOM } from '../common/config';
import { HarmonyGeo } from '../common/geo';
import { LocalProvider } from '../common/localProvider';
import { MapKitAdapter } from '../common/mapKitAdapter';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  // 应用状态
  @State appState: AppState = AppState.IDLE;

  // 用户当前位置
  @State myLocation: LatLng | null = null;

  // 厕所列表
  @State toilets: ToiletPoi[] = [];

  // 加载状态与错误
  @State loading: boolean = false;
  @State error?: string = undefined;

  // 横幅提示
  @State bannerVisible: boolean = false;
  @State bannerMessage: string = '';
  @State bannerType: BannerType = BannerType.ERROR;

  // 服务实例
  private geoService = HarmonyGeo.getInstance();
  private dataProvider = new LocalProvider();
  private mapAdapter = new MapKitAdapter();

  aboutToAppear() {
    this.initializeApp();
  }

  build() {
    Column() {
      // 错误横幅
      if (this.bannerVisible) {
        ErrorBanner({
          visible: this.bannerVisible,
          message: this.bannerMessage,
          type: this.bannerType,
          actionText: this.getActionText(),
          onActionClick: () => this.handleBannerAction(),
          onClose: () => this.hideBanner()
        })
          .zIndex(9)
      }

      // 主内容区块
      Stack() {
        // 地图区域 (70%)
        this.buildMapArea()

        // 底部卡片区域 (30%)
        Column() {
          Blank()
            .layoutWeight(0.7)

          ToiletCard({
            toilets: this.toilets,
            loading: this.loading,
            error: this.error,
            onFindToiletClick: () => this.handleFindToilet(),
            onToiletItemClick: (toilet: ToiletPoi) => this.handleToiletItemClick(toilet)
          })
            .layoutWeight(0.3)
        }
        .width('100%')
        .height('100%')

        // 右上角悬浮设置按钮（替代原顶部栏）
        Row() {
          Button() {
            Image($r('app.media.ic_settings'))
              .width(22)
              .height(22)
              .fillColor('#4C8BF5')
          }
          .width(44)
          .height(44)
          .backgroundColor(Color.White)
          .borderRadius(22)
          .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/Settings' });
            } catch (err) {
              console.error('Index: 跳转设置失败', err);
            }
          })
        }
        .width('100%')
        .padding({ top: 12, right: 12 })
        .justifyContent(FlexAlign.End)
        .zIndex(20)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildMapArea() {
    // TODO: 集成 ArkTS Map Kit 的 MapView 组件
    Column() {
      Text('地图区域')
        .fontSize(16)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)

      Text('(ArkTS Map Kit 集成)')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 4 })
        .textAlign(TextAlign.Center)

      if (this.myLocation) {
        Text(`当前位置: ${this.myLocation.lat.toFixed(4)}, ${this.myLocation.lng.toFixed(4)}`)
          .fontSize(10)
          .fontColor('#999999')
          .margin({ top: 8 })
          .textAlign(TextAlign.Center)
      }

      if (this.toilets.length > 0) {
        Text(`已标记 ${this.toilets.length} 个厕所`)
          .fontSize(10)
          .fontColor('#4C8BF5')
          .margin({ top: 4 })
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .height('70%')
    .backgroundColor('#F3F6FA')
    .borderRadius(16)
    .margin(16)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /** 初始化应用 */
  private async initializeApp(): Promise<void> {
    try {
      this.appState = AppState.INIT;

      // 初始化地图适配器
      this.mapAdapter.initIfNeeded();

      // 移动地图到默认位置
      this.mapAdapter.moveCamera(DEFAULT_CENTER, DEFAULT_ZOOM);

      this.appState = AppState.IDLE;
    } catch (error) {
      console.error('Index: 初始化应用失败', error);
      this.showError('应用初始化失败');
    }
  }

  /** 处理一键找屎按钮点击 */
  private async handleFindToilet(): Promise<void> {
    try {
      this.appState = AppState.LOCATING;
      this.loading = true;
      this.error = undefined;
      this.hideBanner();

      // 获取当前位置
      const location = await this.geoService.getCurrentLatLng();
      this.myLocation = location;

      // 移动地图到当前位置，并开启我的位置
      this.mapAdapter.moveCamera(location, DEFAULT_ZOOM);
      this.mapAdapter.setMyLocationEnabled(true);

      this.appState = AppState.SEARCHING;

      // 搜索附近厕所
      const toilets = await this.dataProvider.searchToilets({
        center: location,
        radiusM: 1500,
        limit: 20
      });

      if (toilets.length === 0) {
        this.appState = AppState.EMPTY;
        this.toilets = [];
        this.showInfo('附近没有找到公共厕所');
      } else {
        this.appState = AppState.RENDERING;

        // 清除旧标记并添加新标记
        this.mapAdapter.clearMarkers();
        toilets.forEach(toilet => {
          this.mapAdapter.addMarker(toilet, toilet.name);
        });

        this.toilets = toilets;
        this.appState = AppState.IDLE;
      }
    } catch (error) {
      console.error('Index: 一键找屎失败', error);
      this.appState = AppState.ERROR;

      const msg = (error as Error)?.message || '';
      if (msg.includes('权限')) {
        this.showPermissionError();
      } else if (msg.includes('超时')) {
        this.showError('定位超时，请检查网络连接');
      } else {
        this.showError('搜索失败，请重试');
      }
    } finally {
      this.loading = false;
    }
  }

  /** 处理厕所列表项点击 */
  private handleToiletItemClick(toilet: ToiletPoi): void {
    try {
      this.mapAdapter.moveCamera(toilet, DEFAULT_ZOOM);
      // TODO: 高亮选中的标记
    } catch (error) {
      console.error('Index: 移动到厕所位置失败', error);
    }
  }

  /** 显示权限错误 */
  private showPermissionError(): void {
    this.bannerType = BannerType.WARNING;
    this.bannerMessage = '定位权限被拒绝，请在设置中开启定位权限';
    this.bannerVisible = true;
  }

  /** 显示错误信息 */
  private showError(message: string): void {
    this.error = message;
    this.bannerType = BannerType.ERROR;
    this.bannerMessage = message;
    this.bannerVisible = true;
  }

  /** 显示提示信息 */
  private showInfo(message: string): void {
    this.bannerType = BannerType.INFO;
    this.bannerMessage = message;
    this.bannerVisible = true;
  }

  /** 隐藏横幅 */
  private hideBanner(): void {
    this.bannerVisible = false;
    this.error = undefined;
  }

  /** 横幅操作按钮文案 */
  private getActionText(): string | undefined {
    if (this.bannerType === BannerType.WARNING && this.bannerMessage.includes('权限')) {
      return '重试';
    }
    if (this.bannerType === BannerType.ERROR) {
      return '重试';
    }
    return undefined;
  }

  /** 处理横幅操作 */
  private handleBannerAction(): void {
    this.hideBanner();
    if (this.bannerMessage.includes('权限') || this.bannerMessage.includes('失败')) {
      this.handleFindToilet();
    }
  }
}

