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
    const request: geoLocationManager.CurrentLocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.ACCURACY,
      timeoutMs: 10000, // 10 seconds
    };
    return await geoLocationManager.getCurrentLocation(request);
  }
}