/**
 * Home page (Index)
 * Map area + bottom list + floating settings button
 */

import { ToiletCard } from '../components/ToiletCard';
import { ErrorBanner, BannerType } from '../components/ErrorBanner';
import { ToiletPoi, AppState, CallbackHandler, Callback0, Callback1, MinimalError, TravelMode } from '../common/types';
import { DEFAULT_CENTER, DEFAULT_ZOOM, DEFAULT_RADIUS_M } from '../common/config';
import { HarmonyGeo, LocationPermissionStatus, LocationAccuracy } from '../common/geo';
import { BaiduMapAdapter } from '../common/baiduMapAdapter';
import { LocalProvider } from '../common/localProvider';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { openExternalNavigation, openNavigationWithPlanning } from '../common/navigation';
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';
import { MapComponent, MapController, MapOptions, MapStatus } from '@bdmap/map';
import { LatLng, Initializer } from '@bdmap/base';
import { MapEvent } from '@bdmap/map/src/main/ets/e/h/g1/h1';

// 定义厕所距离信息接口
interface ToiletWithDistance {
  toilet: ToiletPoi;
  distance: number;
  estimatedTime: number;
}

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
  private mapAdapter = new BaiduMapAdapter();
  private dataProvider = new LocalProvider();
  private mapOptions?: MapOptions; // 百度地图选项
  private callback?: (err: Error | undefined, controller: MapController) => void; // 百度地图回调
  private mapController?: MapController; // 百度地图控制器
  private mapEventManager?: object; // 百度地图事件管理器

  aboutToAppear() {
    // 确保百度地图SDK已经初始化
    this.ensureBaiduSDKInitialized();
    
    this.initializeApp();

    // 百度地图初始化选项
    this.mapOptions = new MapOptions();
    
    // 创建地图状态对象，设置中心点和缩放级别
    const mapStatus = new MapStatus({
      center: new LatLng(DEFAULT_CENTER.lat, DEFAULT_CENTER.lng),
      zoom: DEFAULT_ZOOM,
      rotate: 0,
      overlook: 0,
      ptOffset: [0, 0]
    });
    
    this.mapOptions.mapStatus = mapStatus;
    
    // 手势控制
    this.mapOptions.zoomGesturesEnabled = true;
    this.mapOptions.moveGesturesEnabled = true;
    this.mapOptions.rotateGesturesEnabled = true;
    this.mapOptions.overlookingGesturesEnabled = true;

    // 百度地图初始化回调
    this.callback = async (err: Error | undefined, controller: MapController) => {
      if (!err && controller) {
        this.mapController = controller;
        this.mapAdapter.initialize(controller);

        try {
          // 地图加载完成事件
          const onLoad = () => {
            console.info('Index', 'Baidu map loaded successfully');
            // 启用我的位置显示，显示蓝色定位点
            this.mapAdapter.setMyLocationEnabled(true);
            // 如果有位置信息，移动到用户位置并确保居中
            if (this.myLocation) {
              // 延迟一点时间确保地图完全加载，然后居中显示用户位置
              setTimeout(() => {
                this.mapAdapter.moveCamera(this.myLocation!, DEFAULT_ZOOM, true);
                console.info('Index: camera moved to user location after map load - ensuring centered');
              }, 500);
            }
          };
          
          // 设置百度地图事件监听器
          controller.addEventListener(MapEvent.MAPRENDERFINISH, onLoad);
          
        } catch (e) {
          console.warn('Index: bind map events failed', (e as Error).message || e);
        }

        // 初始相机位置
        const target = this.myLocation ?? DEFAULT_CENTER;
        this.mapAdapter.moveCamera(target, DEFAULT_ZOOM, false);
      } else {
        console.error('Index: map initialization failed', (err as Error)?.message || 'Unknown error');
        this.showError('地图初始化失败');
      }
    };

    // 设置地图点击监听器
    try {
      this.mapAdapter.setOnMapClickListener((pos) => {
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
        openNavigationWithPlanning(ctx, pos, 'Target', this.travelMode);
      });
      this.mapAdapter.setOnMarkerClickListener((_markerId, pos) => {
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
        openNavigationWithPlanning(ctx, pos, 'Target', this.travelMode);
      });
    } catch (err) {
      console.warn('Index: register map listeners failed', (err as Error).message || err);
    }
  }

  build() {
    Stack() {
      // 地图区域作为背景
      this.buildMapArea()

      // 找屎按钮放在下方
      Column() {
        Blank().layoutWeight(1)
        ToiletCard({
          loading: this.loading,
          onFindToiletClick: { handler: () => this.handleFindToilet() } as Callback0,
          onTimeChange: { handler: (time: number) => this.handleTimeChange(time) } as Callback1<number>,
          onModeChange: { handler: (mode: TravelMode) => this.handleModeChange(mode) } as Callback1<TravelMode>
        })
      }
      .width('100%')
      .height('100%')
      .zIndex(10)

      // 悬浮的Banner，不影响地图布局
      if (this.bannerVisible) {
        Column() {
          ErrorBanner({
            visible: this.bannerVisible,
            message: this.bannerMessage,
            type: this.bannerType,
            actionText: this.getActionText(),
            onActionClick: { handler: () => this.handleBannerAction() } as CallbackHandler,
            onClose: { handler: () => this.hideBanner() } as CallbackHandler
          })
          Blank()
        }
        .width('100%')
        .height('100%')
        .zIndex(30)
        .padding({ top: 12 })
      }

      // 左上角设置按钮
      Column() {
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
            router.pushNamedRoute({ name: 'Settings' });
          } catch (err) {
          console.error('Index: navigate to settings failed', (err as Error).message || err);
        }
        })
        Blank()
      }
      .width('100%')
      .padding({ top: 12, left: 12 })
      .alignItems(HorizontalAlign.Start)
      .zIndex(20)

      // 右上角定位按钮
      Column() {
        Button() {
          Text('📍')
            .fontSize(20)
        }
        .width(44)
        .height(44)
        .backgroundColor(Color.White)
        .borderRadius(22)
        .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
        .onClick(() => {
          this.focusToMyLocation();
        })
        Blank()
      }
      .width('100%')
      .padding({ top: 12, right: 12 })
      .alignItems(HorizontalAlign.End)
      .zIndex(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildMapArea() {
    MapComponent({
      onReady: this.callback,
      mapOptions: this.mapOptions
    })
      .width('100%')
      .height('100%')
  }

  private async initializeApp(): Promise<void> {
    try {
      this.appState = AppState.INIT;
      // 百度地图适配器不需要initIfNeeded调用
      this.mapAdapter.moveCamera(DEFAULT_CENTER, DEFAULT_ZOOM);
      
      // 主动申请位置权限
      console.info('Index: requesting location permission on startup');
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const granted = await this.geoService.requestLocationPermission(ctx);
      
      if (granted) {
        console.info('Index: location permission granted');
        // 启用系统的我的位置显示，但通过配置禁用控件按钮
        this.mapAdapter.setMyLocationEnabled(true);
        
        // 自动获取当前位置并显示在地图上
        try {
          console.info('Index: auto-locating user position');
          const location = await this.geoService.getCurrentLatLng({
            accuracy: LocationAccuracy.HIGH,
            timeout: 10000 // 10秒超时
          });
          
          console.info('Index: auto-location successful:', location);
          this.myLocation = location;
          // 确保用户位置居中显示
          this.mapAdapter.moveCamera(location, DEFAULT_ZOOM, true);
          // 不清除标记，让系统蓝色定位点和自定义标记共存
          // this.mapAdapter.clearMarkers();
          // this.mapAdapter.addMarker(location, '我的位置', undefined, 'user_location');
          this.showInfo('已显示定位，地图已聚焦到您的位置');
        } catch (locationError) {
          console.warn('Index: auto-location failed:', locationError);
          // 定位失败不影响应用启动，只是不显示当前位置
        }
      } else {
        console.warn('Index: location permission denied');
      }
      
      this.appState = AppState.IDLE;
    } catch (error) {
      console.error('Index: initialize app failed', (error as Error).message || error);
      this.showError('应用初始化失败');
    }
  }

  private async handleFindToilet(): Promise<void> {
    try {
      this.appState = AppState.LOCATING;
      this.loading = true;
      this.error = undefined;
      this.hideBanner();

      // 运行时权限：检查并申请定位权限（API 16）
      const perm = await this.geoService.checkLocationPermission();
      if (perm !== LocationPermissionStatus.GRANTED) {
        console.info('Index: location permission not granted, requesting permission');
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const granted = await this.geoService.requestLocationPermission(ctx);
        if (!granted) {
          console.warn('Index: user denied location permission');
          this.showPermissionError();
          throw new Error('LOCATION_PERMISSION_DENIED');
        }
        console.info('Index: location permission granted by user');
      }

      // 获取当前位置
      console.info('Index: getting current location for toilet search');
      let currentLocation: LatLng;
      
      try {
        currentLocation = await this.geoService.getCurrentLatLng({
          accuracy: LocationAccuracy.HIGH,
          timeout: 15000 // 15秒超时
        });
        console.info('Index: current location obtained:', currentLocation);
        this.myLocation = currentLocation;
        
        // 确保当前位置在地图中心
        console.info('Index: centering map to current location');
        this.mapAdapter.moveCamera(currentLocation, DEFAULT_ZOOM, true);
      } catch (locationError) {
         console.error('Index: failed to get current location:', locationError);
         this.appState = AppState.ERROR;
         this.showError('定位失败，请检查GPS设置或网络连接');
         return;
       }
      // 启用系统的我的位置显示，显示蓝色定位点
      this.mapAdapter.setMyLocationEnabled(true);
      // 清除厕所标记，但保留系统蓝色定位点
      this.mapAdapter.clearMarkers();

      // 搜索附近厕所
      this.appState = AppState.SEARCHING;
      
      // 使用LocalProvider搜索附近厕所
      console.info('Index: searching toilets near location:', currentLocation);
      const toilets = await this.dataProvider.searchToilets({
        center: currentLocation,
        radiusM: DEFAULT_RADIUS_M,
        limit: 20
      });
      console.info('Index: found toilets:', toilets.length);
      
      if (toilets.length === 0) {
        this.appState = AppState.EMPTY;
        this.showError('附近没有找到厕所');
        return;
      }
      
      // 根据选择的时长筛选最近的厕所
      const nearestToilet = await this.findNearestToiletWithinTime(currentLocation, toilets);
      
      if (!nearestToilet) {
        this.showError(`在${this.selectedTime}分钟内未找到可达厕所`);
        return;
      }
      
      // 渲染结果
      this.appState = AppState.RENDERING;
      this.toilets = toilets;
      
      // 添加厕所标记，高亮最近的厕所
      toilets.forEach(toilet => {
        const isNearest = toilet.id === nearestToilet.id;
        this.mapAdapter.addMarker(toilet, toilet.name);
      });
      
      // 自动导航到最近的厕所
      console.info('Index: navigating to nearest toilet:', nearestToilet);
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      openNavigationWithPlanning(
        ctx, 
        nearestToilet, 
        nearestToilet.name, 
        this.travelMode
      );
      
      this.appState = AppState.IDLE;
      const modeText = this.travelMode === TravelMode.WALKING ? '步行' : '骑行';
      this.showInfo(`已为您规划${modeText}路线到"${nearestToilet.name}"`);
      
   } catch (error) {
      console.error('Index: handleFindToilet failed', (error as Error).message || error);
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

  private async findNearestToiletWithinTime(currentLocation: LatLng, toilets: ToiletPoi[]): Promise<ToiletPoi | null> {
    if (toilets.length === 0) {
      return null;
    }

    // 计算每个厕所的距离和预估时间
    const toiletsWithTime = toilets.map(toilet => {
      // 计算直线距离（米）
      const distance = this.calculateDistance(currentLocation, toilet);
      
      // 根据出行方式估算时间（分钟）
      let estimatedTime: number;
      if (this.travelMode === TravelMode.WALKING) {
        // 步行速度约 5 km/h = 83.33 m/min
        estimatedTime = distance / 83.33;
      } else {
        // 骑行速度约 15 km/h = 250 m/min
        estimatedTime = distance / 250;
      }
      
      return {
        toilet,
        distance,
        estimatedTime
      } as ToiletWithDistance;
    });

    // 筛选在指定时间内可达的厕所
    const reachableToilets = toiletsWithTime.filter(item => item.estimatedTime <= this.selectedTime);
    
    if (reachableToilets.length === 0) {
      return null;
    }

    // 返回距离最近的厕所
    const nearest = reachableToilets.reduce((prev, current) => 
      prev.distance < current.distance ? prev : current
    );
    
    return nearest.toilet;
  }

  private calculateDistance(pos1: LatLng, pos2: LatLng | ToiletPoi): number {
    const R = 6371000; // 地球半径（米）
    const lat1Rad = pos1.lat * Math.PI / 180;
    const lat2Rad = pos2.lat * Math.PI / 180;
    const deltaLatRad = (pos2.lat - pos1.lat) * Math.PI / 180;
    const deltaLngRad = (pos2.lng - pos1.lng) * Math.PI / 180;

    const a = Math.sin(deltaLatRad / 2) * Math.sin(deltaLatRad / 2) +
              Math.cos(lat1Rad) * Math.cos(lat2Rad) *
              Math.sin(deltaLngRad / 2) * Math.sin(deltaLngRad / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // 返回距离（米）
  }

  private handleToiletItemClick(toilet: ToiletPoi): void {
    try {
      this.mapAdapter.moveCamera(toilet, DEFAULT_ZOOM);
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      openNavigationWithPlanning(ctx, toilet, toilet.name, this.travelMode);
    } catch (error) {
      console.error('Index: move to toilet location failed', (error as Error).message || error);
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
    this.bannerType = BannerType.ERROR;
    this.bannerMessage = '定位权限被拒绝，请在设置中开启位置权限以使用定位功能';
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

  private focusToMyLocation(): void {
    if (this.myLocation) {
      // 如果已有定位信息，直接聚焦到该位置并确保居中
      console.info('Index: focusing to my location:', this.myLocation);
      this.mapAdapter.moveCamera(this.myLocation, DEFAULT_ZOOM, true);
      // 确保用户位置标记可见并居中
      this.mapAdapter.clearMarkers();
      this.mapAdapter.addMarker(this.myLocation, '我的位置', undefined, 'user_location');
      this.showInfo('已聚焦到您的位置');
    } else {
      // 如果没有定位信息，重新获取位置
      console.info('Index: no location available, requesting new location');
      this.handleFindToilet();
    }
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

  /**
   * 确保百度地图SDK已经初始化
   */
  private ensureBaiduSDKInitialized(): void {
    try {
      const initializer = Initializer.getInstance();
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      initializer.initialize("xTn4vwunlUWLWilFpx5QcDUOycbq34YZ", context.getApplicationContext());
      console.info('Index: Baidu SDK re-initialized to ensure availability');
    } catch (error) {
      console.warn('Index: Baidu SDK initialization check failed:', error);
    }
  }
}



