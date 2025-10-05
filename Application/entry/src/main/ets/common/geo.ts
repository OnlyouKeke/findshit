import { abilityAccessCtrl, PermissionRequestResult, bundleManager, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import geoLocationManager from '@ohos.geoLocationManager';

const TAG = 'HarmonyGeo';
const PERMISSIONS: Array<Permissions> = [
  'ohos.permission.LOCATION',
  'ohos.permission.APPROXIMATELY_LOCATION',
];

export class HarmonyGeo {
  private context: common.UIAbilityContext;
  private atManager: abilityAccessCtrl.AtManager;
  private tokenId: number = 0;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.atManager = abilityAccessCtrl.createAtManager();
  }

  private async initTokenId(): Promise<void> {
    if (this.tokenId !== 0) {
      return;
    }
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      this.tokenId = appInfo.accessTokenId;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(TAG, `Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
    }
  }

  async checkPermission(): Promise<boolean> {
    await this.initTokenId();
    if (this.tokenId === 0) {
        console.error(TAG, 'Failed to get tokenId');
        return false;
    }
    try {
      const grantStatus = await this.atManager.checkAccessToken(this.tokenId, PERMISSIONS[0]);
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      const error = err as BusinessError;
      console.error(TAG, `Failed to check permission, error: ${JSON.stringify(error)}`);
      return false;
    }
  }

  async requestPermission(): Promise<boolean> {
    try {
      const data: PermissionRequestResult = await this.atManager.requestPermissionsFromUser(this.context, PERMISSIONS);
      const grants = data.authResults;
      if (grants.length > 0 && grants.every(item => item === 0)) {
        return true;
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(TAG, `Failed to request permission, error: ${JSON.stringify(error)}`);
    }
    return false;
  }

  async getCurrentLocation(): Promise<geoLocationManager.Location> {
    // 先检查系统定位开关
    try {
      // 某些版本不支持该API，调用失败时忽略
      const enabled = (geoLocationManager as any).isLocationEnabled ? (geoLocationManager as any).isLocationEnabled() : true;
      if (enabled === false) {
        throw new Error('系统定位未开启，请打开定位服务');
      }
    } catch (_) {
      // 忽略不可用的API或检查异常
    }

    // 首次尝试：高精度，较长超时
    const highAcc: geoLocationManager.CurrentLocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.ACCURACY,
      timeoutMs: 20000,
    };
    try {
      return await geoLocationManager.getCurrentLocation(highAcc);
    } catch (err) {
      const error = err as BusinessError | Error;
      console.warn(TAG, `高精度定位失败，降级重试。error=${(error as any).message || ''}`);
      // 第二次尝试：低功耗，更长超时，适配弱信号或仅网络定位
      const lowPower: geoLocationManager.CurrentLocationRequest = {
        priority: geoLocationManager.LocationRequestPriority.LOW_POWER,
        timeoutMs: 25000,
      };
      return await geoLocationManager.getCurrentLocation(lowPower);
    }
  }
}