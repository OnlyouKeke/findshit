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

      // 设置定位参数 - 优化定位精度
      const locationOptions = {
        priority: this.getLocationPriority(options?.accuracy || LocationAccuracy.HIGH),
        scenario: 0x301, // SCENE_NAVIGATION - 导航场景，提供最佳精度
        timeInterval: 1, // 1秒间隔
        distanceInterval: 0, // 距离间隔0米，获取最新位置
        maxAccuracy: 3000, // 最大精度3000米
        fenceRadius: 1, // 围栏半径1米
        isOffline: false // 在线定位
      };

      console.info('HarmonyGeo: starting high-precision location request');
      
      // 模拟定位延迟（实际项目中应使用真实的定位API）
      await this.simulateLocationDelay(options?.timeout || LOCATION_TIMEOUT);
      
      // 返回上海人民广场坐标作为模拟位置
      // 在实际项目中，这里应该调用真实的定位API
      const location = { lat: 31.2304, lng: 121.4737 };
      
      console.info('HarmonyGeo: location obtained successfully', location);
      return location;
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
      
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const tokenId = bundleInfo.appInfo.accessTokenId;
      
      // 请求精确位置权限和粗略位置权限
      const permissions = [
        PERMISSIONS.LOCATION,
        PERMISSIONS.APPROXIMATELY_LOCATION
      ];
      
      const result = await atManager.requestPermissionsFromUser(ctx, permissions);
      
      // 检查权限授予结果
      const locationGranted = result?.authResults?.[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      const approximateGranted = result?.authResults?.[1] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      
      const success = locationGranted || approximateGranted;
      
      console.info('HarmonyGeo: permission request result', {
        location: locationGranted,
        approximate: approximateGranted,
        success
      });
      
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
      // TODO: 实际的定位服务检查代码
      // return await geoLocationManager.isLocationEnabled();

      // 模拟定位服务检查（开发阶段使用）
      return true;

    } catch (error) {
      console.error('HarmonyGeo: 检查定位服务失败', error);
      return false;
    }
  }

  /**
   * 获取定位优先级
   */
  private getLocationPriority(accuracy: LocationAccuracy): number {
    // TODO: 根据实际的 geoLocationManager API 返回对应的优先级
    switch (accuracy) {
      case LocationAccuracy.HIGH:
        return 0x0201; // PRIORITY_ACCURACY
      case LocationAccuracy.MEDIUM:
        return 0x0203; // PRIORITY_FAST_FIRST_FIX
      case LocationAccuracy.LOW:
        return 0x0204; // PRIORITY_LOW_POWER
      default:
        return 0x0201;
    }
  }

  /**
   * 模拟定位延迟
   */
  private async simulateLocationDelay(timeout: number): Promise<void> {
    const delay = Math.min(1000 + Math.random() * 2000, timeout); // 1-3秒随机延迟
    return new Promise((resolve, reject) => {
      const timer = setTimeout(resolve, delay);
      
      // 模拟超时
      if (Math.random() < 0.1) { // 10% 概率超时
        setTimeout(() => {
          clearTimeout(timer);
          reject(new Error('Location timeout'));
        }, timeout);
      }
    });
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
