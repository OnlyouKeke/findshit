/**
 * 定位封装模块
 * 提供定位权限检查和位置获取功能
 */

import { LatLng, AppError } from './types';
import { LOCATION_TIMEOUT, ERROR_MESSAGES, PERMISSIONS } from './config';

// API 16 权限与包信息
// 说明：保持最少依赖，按官方 Stage 用法请求运行时权限
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import { common } from '@kit.AbilityKit';
// 引入地理位置管理器
import geoLocationManager from '@ohos.geoLocationManager';
// 导入百度地图SDK的LatLng类型用于类型转换
import { LatLng as BdLatLng } from '@bdmap/base';

/**
 * 定位权限状态
 */
export enum LocationPermissionStatus {
  GRANTED = 'granted',           // 已授权
  DENIED = 'denied',             // 拒绝
  NOT_DETERMINED = 'not_determined', // 未确定
  RESTRICTED = 'restricted'      // 受限制
}

/**
 * 定位精度类型
 */
export enum LocationAccuracy {
  HIGH = 'high',     // 高精度（GPS）
  MEDIUM = 'medium', // 中等精度（网络）
  LOW = 'low'        // 低精度（粗略）
}

/**
 * 定位选项
 */
export interface LocationOptions {
  accuracy?: LocationAccuracy;
  timeout?: number;
  maximumAge?: number;
}

/**
 * 定位接口
 */
export interface Geo {
  /**
   * 获取当前位置
   * @param options 定位选项
   * @returns Promise<LatLng> 当前位置坐标
   */
  getCurrentLatLng(options?: LocationOptions): Promise<LatLng>;

  /**
   * 检查定位权限状态
   * @returns Promise<LocationPermissionStatus> 权限状态
   */
  checkLocationPermission(): Promise<LocationPermissionStatus>;

  /**
   * 请求定位权限
   * @returns Promise<boolean> 是否授权成功
   */
  requestLocationPermission(ctx: common.UIAbilityContext): Promise<boolean>;

  /**
   * 检查定位服务是否可用
   * @returns Promise<boolean> 是否可用
   */
  isLocationServiceEnabled(): Promise<boolean>;
}

/**
 * HarmonyOS 定位实现
 */
export class HarmonyGeo implements Geo {
  private static instance: HarmonyGeo;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): HarmonyGeo {
    if (!HarmonyGeo.instance) {
      HarmonyGeo.instance = new HarmonyGeo();
    }
    return HarmonyGeo.instance;
  }

  /**
   * 获取当前位置
   */
  async getCurrentLatLng(options?: LocationOptions): Promise<LatLng> {
    try {
      // 检查定位权限
      const permissionStatus = await this.checkLocationPermission();
      if (permissionStatus !== LocationPermissionStatus.GRANTED) {
        throw this.createLocationError('PERMISSION_DENIED', ERROR_MESSAGES.PERMISSION_DENIED);
      }

      // 检查定位服务是否开启
      const serviceEnabled = await this.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw this.createLocationError('SERVICE_DISABLED', '定位服务未开启');
      }

      // 设置定位参数 - 使用真实的geoLocationManager API
      const requestInfo: geoLocationManager.CurrentLocationRequest = {
        priority: this.getLocationPriority(options?.accuracy || LocationAccuracy.HIGH),
        scenario: geoLocationManager.LocationRequestScenario.NAVIGATION, // 导航场景
        timeoutMs: options?.timeout || LOCATION_TIMEOUT,
        maxAccuracy: 3000 // 最大精度3000米
      };

      console.info('HarmonyGeo: starting real location request with params:', requestInfo);
      
      // 使用真实的定位API获取当前位置
      return new Promise<LatLng>((resolve, reject) => {
        geoLocationManager.getCurrentLocation(requestInfo, (err, location) => {
          if (err) {
            console.error('HarmonyGeo: getCurrentLocation failed', err);
            reject(this.createLocationError('LOCATION_ERROR', `定位失败: ${err.message}`));
            return;
          }
          
          if (!location) {
            console.error('HarmonyGeo: location is null');
            reject(this.createLocationError('LOCATION_ERROR', '无法获取位置信息'));
            return;
          }
          
          const result: LatLng = new BdLatLng(location.latitude, location.longitude);
          
          console.info('HarmonyGeo: real location obtained successfully:', result);
          console.info('HarmonyGeo: location details - accuracy:', location.accuracy, 'altitude:', location.altitude);
          resolve(result);
        });
      });
    } catch (error) {
      console.error('HarmonyGeo: getCurrentLatLng failed', error);
      throw this.createLocationError('LOCATION_ERROR', ERROR_MESSAGES.LOCATION_FAILED);
    }
  }

  /**
   * 检查定位权限状态
   */
  async checkLocationPermission(): Promise<LocationPermissionStatus> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const tokenId = bundleInfo.appInfo.accessTokenId;

      const precise = await atManager.checkAccessToken(tokenId, PERMISSIONS.LOCATION);
      const approx = await atManager.checkAccessToken(tokenId, PERMISSIONS.APPROXIMATELY_LOCATION);

      if (
        precise === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ||
        approx === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      ) {
        return LocationPermissionStatus.GRANTED;
      }
      return LocationPermissionStatus.DENIED;
    } catch (error) {
      console.error('HarmonyGeo: 检查权限失败', error);
      return LocationPermissionStatus.NOT_DETERMINED;
    }
  }

  /**
   * 请求定位权限
   */
  async requestLocationPermission(ctx: common.UIAbilityContext): Promise<boolean> {
    try {
      console.info('HarmonyGeo: requesting location permission');
      
      // 先检查当前权限状态
      const currentStatus = await this.checkLocationPermission();
      if (currentStatus === LocationPermissionStatus.GRANTED) {
        console.info('HarmonyGeo: location permission already granted');
        return true;
      }
      
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const tokenId = bundleInfo.appInfo.accessTokenId;
      
      // 请求精确位置权限和粗略位置权限
      const permissions = [
        PERMISSIONS.LOCATION,
        PERMISSIONS.APPROXIMATELY_LOCATION
      ];
      
      console.info('HarmonyGeo: showing permission dialog to user');
      const result = await atManager.requestPermissionsFromUser(ctx, permissions);
      
      // 检查权限授予结果
      const locationGranted = result?.authResults?.[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      const approximateGranted = result?.authResults?.[1] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      
      const success = locationGranted || approximateGranted;
      
      console.info('HarmonyGeo: permission request result', {
        location: locationGranted,
        approximate: approximateGranted,
        success,
        authResults: result?.authResults
      });
      
      if (!success) {
        console.warn('HarmonyGeo: user denied location permission');
      }
      
      return success;
    } catch (error) {
      console.error('HarmonyGeo: 请求权限失败', error);
      return false;
    }
  }

  /**
   * 检查定位服务是否可用
   */
  async isLocationServiceEnabled(): Promise<boolean> {
    try {
      console.info('HarmonyGeo: checking location service status');
      
      // 使用geoLocationManager检查定位服务状态
      const enabled = geoLocationManager.isLocationEnabled();
      
      console.info('HarmonyGeo: location service enabled:', enabled);
      return enabled;
    } catch (error) {
      console.error('HarmonyGeo: 检查定位服务失败', error);
      return false;
    }
  }

  /**
   * 获取定位优先级
   */
  private getLocationPriority(accuracy: LocationAccuracy): geoLocationManager.LocationRequestPriority {
    switch (accuracy) {
      case LocationAccuracy.HIGH:
        return geoLocationManager.LocationRequestPriority.ACCURACY; // 高精度定位
      case LocationAccuracy.MEDIUM:
        return geoLocationManager.LocationRequestPriority.FIRST_FIX; // 快速首次定位
      case LocationAccuracy.LOW:
        return geoLocationManager.LocationRequestPriority.LOW_POWER; // 低功耗定位
      default:
        return geoLocationManager.LocationRequestPriority.ACCURACY;
    }
  }



  /**
   * 创建定位错误
   */
  private createLocationError(code: string, message: string): AppError {
    return {
      code: `LOCATION_${code}`,
      message,
      retryable: code !== 'PERMISSION_DENIED'
    };
  }
}

/**
 * 获取默认的定位实例
 */
export function getGeoInstance(): Geo {
  return HarmonyGeo.getInstance();
}

// 兼容旧版本的简单接口
export async function getCurrentLatLng(): Promise<LatLng> {
  const geo = getGeoInstance();
  return await geo.getCurrentLatLng();
}
