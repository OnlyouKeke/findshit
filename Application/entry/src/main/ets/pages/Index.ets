/**
 * Home page (Index)
 * Map area + bottom list + floating settings button
 */

import { ToiletCard } from '../components/ToiletCard';
import { ErrorBanner, BannerType } from '../components/ErrorBanner';
import { LatLng, ToiletPoi, AppState, CallbackHandler, Callback0, Callback1, MinimalError } from '../common/types';
import { DEFAULT_CENTER, DEFAULT_ZOOM } from '../common/config';
import { HarmonyGeo, LocationPermissionStatus } from '../common/geo';
import { MapKitAdapter } from '../common/mapKitAdapter';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { openExternalNavigation } from '../common/navigation';
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

  private geoService = HarmonyGeo.getInstance();
  private mapAdapter = new MapKitAdapter();
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;

  aboutToAppear() {
    this.initializeApp();

    // Map init options
    this.mapOptions = {
      position: {
        target: {
          latitude: DEFAULT_CENTER.lat,
          longitude: DEFAULT_CENTER.lng
        },
        zoom: DEFAULT_ZOOM
      }
    } as mapCommon.MapOptions;

    // Map init callback
    this.callback = async (err: Error | undefined, controller: map.MapComponentController) => {
      if (!err && controller) {
        this.mapController = controller;
        this.mapAdapter.attachController(controller);

        try {
          this.mapEventManager = controller.getEventManager();
          const onLoad = () => { console.info('Index', 'mapLoad'); };
          this.mapEventManager.on('mapLoad', onLoad);
        } catch (e) {
          console.warn('Index: bind map events failed', e as Error);
        }

        const target = this.myLocation ?? DEFAULT_CENTER;
        this.mapAdapter.moveCamera(target, DEFAULT_ZOOM);
      }
    };

    // Click to navigate
    try {
      this.mapAdapter.setOnMapClickListener((pos) => {
        const ctx = getContext(this) as common.UIAbilityContext;
        openExternalNavigation(ctx, pos.lat, pos.lng, 'Target');
      });
      this.mapAdapter.setOnMarkerClickListener((_markerId, pos) => {
        const ctx = getContext(this) as common.UIAbilityContext;
        openExternalNavigation(ctx, pos.lat, pos.lng, 'Target');
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

        Column() {
          Blank().layoutWeight(0.7)
          ToiletCard({
            toilets: this.toilets,
            loading: this.loading,
            error: this.error,
            onFindToiletClick: ({ handler: () => this.handleFindToilet() } as Callback0),
            onToiletItemClick: ({ handler: (toilet: ToiletPoi) => this.handleToiletItemClick(toilet) } as Callback1<ToiletPoi>)
          })
            .layoutWeight(0.3)
        }
        .width('100%')
        .height('100%')

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
      .height('70%')
      .margin(16)
      .borderRadius(16)
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
      openExternalNavigation(ctx, toilet.lat, toilet.lng, toilet.name);
    } catch (error) {
      console.error('Index: move to toilet location failed', error as Error);
    }
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



