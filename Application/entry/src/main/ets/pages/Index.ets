/**
 * Home page (Index)
 * Map area + bottom list + floating settings button
 */

import { ToiletCard } from '../components/ToiletCard';
import { ErrorBanner, BannerType } from '../components/ErrorBanner';
import { LatLng, ToiletPoi, AppState, CallbackHandler, Callback0, Callback1, MinimalError, TravelMode } from '../common/types';
import { DEFAULT_CENTER, DEFAULT_ZOOM } from '../common/config';
import { HarmonyGeo, LocationPermissionStatus } from '../common/geo';
import { MapKitAdapter } from '../common/mapKitAdapter';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { openExternalNavigation, openNavigationWithPlanning } from '../common/navigation';
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State appState: AppState = AppState.IDLE;
  @State myLocation: LatLng | null = null;
  @State toilets: ToiletPoi[] = [];
  @State loading: boolean = false;
  @State error?: string = undefined;
  @State bannerVisible: boolean = false;
  @State bannerMessage: string = '';
  @State bannerType: BannerType = BannerType.ERROR;
  @State selectedTime: number = 5; // 默认5分钟
  @State travelMode: TravelMode = TravelMode.WALKING; // 默认步行

  private geoService = HarmonyGeo.getInstance();
  private mapAdapter = new MapKitAdapter();
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear() {
    this.initializeApp();

    // Map init options - 根据HarmonyOS NEXT MapKit API配置
    this.mapOptions = {
      position: {
        target: {
          latitude: DEFAULT_CENTER.lat,
          longitude: DEFAULT_CENTER.lng
        },
        zoom: DEFAULT_ZOOM
      },
      // 地图类型
      mapType: mapCommon.MapType.STANDARD,
      // 地图最小图层,默认值为2
      minZoom: 2,
      // 地图最大图层,默认值为20
      maxZoom: 20,
      // 是否支持旋转手势
      rotateGesturesEnabled: true,
      // 是否支持滑动手势
      scrollGesturesEnabled: true,
      // 是否支持缩放手势
      zoomGesturesEnabled: true,
      // 是否支持倾斜手势
      tiltGesturesEnabled: true,
      // 是否展示缩放控件
      zoomControlsEnabled: true,
      // 是否展示定位按钮
      myLocationControlsEnabled: true,
      // 是否展示指南针控件
      compassControlsEnabled: false,
      // 是否展示比例尺
      scaleControlsEnabled: true,
      // 是否一直显示比例尺，只有比例尺启用时该参数才生效
      alwaysShowScaleEnabled: true
    };

    // Map init callback - 优化地图初始化
    this.callback = async (err: Error | undefined, controller: map.MapComponentController) => {
      if (!err && controller) {
        this.mapController = controller;
        this.mapAdapter.attachController(controller);

        try {
          this.mapEventManager = controller.getEventManager();
          
          // 地图加载完成事件
          const onLoad = () => {
            console.info('Index', 'mapLoad completed');
            // 启用我的位置显示
            this.mapAdapter.setMyLocationEnabled(true);
            // 如果有位置信息，移动到用户位置
            if (this.myLocation) {
              this.mapAdapter.moveCamera(this.myLocation, DEFAULT_ZOOM, true);
            }
          };
          
          // 地图点击事件
          const onMapClick = (event: object) => {
            console.info('Index', 'map clicked at:', event);
          };
          
          // 相机移动事件
          const onCameraMove = () => {
            // 可以在这里处理相机移动逻辑
          };
          
          this.mapEventManager.on('mapLoad', onLoad);
          this.mapEventManager.on('mapClick', onMapClick);
          this.mapEventManager.on('cameraMove', onCameraMove);
          
        } catch (e) {
          console.warn('Index: bind map events failed', e as Error);
        }

        // 初始相机位置
        const target = this.myLocation ?? DEFAULT_CENTER;
        this.mapAdapter.moveCamera(target, DEFAULT_ZOOM, false);
      } else {
        console.error('Index: map initialization failed', err);
        this.showError('地图初始化失败');
      }
    };

    // Click to navigate with planning
    try {
      this.mapAdapter.setOnMapClickListener((pos) => {
        const ctx = getContext(this) as common.UIAbilityContext;
        openNavigationWithPlanning(ctx, pos, 'Target', this.travelMode, this.selectedTime);
      });
      this.mapAdapter.setOnMarkerClickListener((_markerId, pos) => {
        const ctx = getContext(this) as common.UIAbilityContext;
        openNavigationWithPlanning(ctx, pos, 'Target', this.travelMode, this.selectedTime);
      });
    } catch (err) {
      console.warn('Index: register map listeners failed', err as Error);
    }
  }

  build() {
    Column() {
      if (this.bannerVisible) {
        ErrorBanner({
          visible: this.bannerVisible,
          message: this.bannerMessage,
          type: this.bannerType,
          actionText: this.getActionText(),
          onActionClick: ({ handler: () => this.handleBannerAction() } as CallbackHandler),
          onClose: ({ handler: () => this.hideBanner() } as CallbackHandler)
        })
          .zIndex(9)
      }

      Stack() {
        this.buildMapArea()

        // 找屎按钮放在下方
        Column() {
          Blank().layoutWeight(1)
          ToiletCard({
            loading: this.loading,
            onFindToiletClick: ({ handler: () => this.handleFindToilet() } as Callback0),
            onTimeChange: ({ handler: (time: number) => this.handleTimeChange(time) } as Callback1<number>),
            onModeChange: ({ handler: (mode: TravelMode) => this.handleModeChange(mode) } as Callback1<TravelMode>)
          })
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 20 })
        .zIndex(10)

        Row() {
          Button() {
            Image(('app.media.ic_settings'))
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
              console.error('Index: navigate to settings failed', err as Error);
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
    MapComponent({
      mapOptions: this.mapOptions,
      mapCallback: this.callback
    })
      .width('100%')
      .height('100%')
  }

  private async initializeApp(): Promise<void> {
    try {
      this.appState = AppState.INIT;
      this.mapAdapter.initIfNeeded();
      this.mapAdapter.moveCamera(DEFAULT_CENTER, DEFAULT_ZOOM);
      this.appState = AppState.IDLE;
    } catch (error) {
      console.error('Index: initialize app failed', error as Error);
      this.showError('应用初始化失败');
    }
  }

  private async handleFindToilet(): Promise<void> {
    try {
      this.appState = AppState.LOCATING;
      this.loading = true;
      this.error = undefined;
      this.hideBanner();

      const location = await this.geoService.getCurrentLatLng();
      // 运行时权限：检查并申请定位权限（API 16）
      const perm = await this.geoService.checkLocationPermission();
      if (perm !== LocationPermissionStatus.GRANTED) {
        const ctx = getContext(this) as common.UIAbilityContext;
        const granted = await this.geoService.requestLocationPermission(ctx);
        if (!granted) {
          this.showPermissionError();
          throw new Error('LOCATION_PERMISSION_DENIED');
        }
      }
      this.myLocation = location;
      this.mapAdapter.moveCamera(location, DEFAULT_ZOOM);
      this.mapAdapter.setMyLocationEnabled(true);
      this.mapAdapter.clearMarkers();
      this.mapAdapter.addMarker(location, 'My Location');

      this.toilets = [];
      this.appState = AppState.IDLE;
      this.showInfo('Located. Tap map to navigate.');
    } catch (error) {
      console.error('Index: one-tap locate failed', error as Error);
      this.appState = AppState.ERROR;
      const appErr = error as MinimalError;
      const code: string = appErr.code ?? '';
      const msg: string = appErr.message ?? '';
      if (code.includes('PERMISSION')) {
        this.showPermissionError();
      } else if (code.includes('TIMEOUT') || msg.includes('超时')) {
        this.showError('定位超时，请检查网络连接');
      } else {
        this.showError('搜索失败，请重试');
      }
    } finally {
      this.loading = false;
    }
  }

  private handleToiletItemClick(toilet: ToiletPoi): void {
    try {
      this.mapAdapter.moveCamera(toilet, DEFAULT_ZOOM);
      const ctx = getContext(this) as common.UIAbilityContext;
      openNavigationWithPlanning(ctx, toilet, toilet.name, this.travelMode, this.selectedTime);
    } catch (error) {
      console.error('Index: move to toilet location failed', error as Error);
    }
  }

  private handleTimeChange(time: number): void {
    this.selectedTime = time;
    console.info('Index', `Time changed to ${time} minutes`);
  }

  private handleModeChange(mode: TravelMode): void {
    this.travelMode = mode;
    const modeText = mode === TravelMode.WALKING ? '步行' : '骑行';
    console.info('Index', `Travel mode changed to ${modeText}`);
    this.showInfo(`已切换到${modeText}模式`);
  }

  private showPermissionError(): void {
    this.bannerType = BannerType.WARNING;
    this.bannerMessage = 'Location permission denied. Enable it in Settings.';
    this.bannerVisible = true;
  }

  private showError(message: string): void {
    this.error = message;
    this.bannerType = BannerType.ERROR;
    this.bannerMessage = message;
    this.bannerVisible = true;
  }

  private showInfo(message: string): void {
    this.bannerType = BannerType.INFO;
    this.bannerMessage = message;
    this.bannerVisible = true;
  }

  private hideBanner(): void {
    this.bannerVisible = false;
    this.error = undefined;
  }

  private getActionText(): string | undefined {
    return (this.bannerType === BannerType.WARNING || this.bannerType === BannerType.ERROR) ? 'Retry' : undefined;
  }

  private handleBannerAction(): void {
    this.hideBanner();
    if (this.bannerType === BannerType.WARNING || this.bannerType === BannerType.ERROR) {
      this.handleFindToilet();
    }
  }
}



