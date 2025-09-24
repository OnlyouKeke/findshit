/**
 * HarmonyOS NEXT 权限申请示例代码
 * 展示如何在应用中正确申请和处理位置权限
 */

import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import { common } from '@kit.AbilityKit';

/**
 * 权限管理器类
 * 负责处理应用的权限申请和检查
 */
export class PermissionManager {
  private static instance: PermissionManager;
  private atManager: abilityAccessCtrl.AtManager;

  private constructor() {
    this.atManager = abilityAccessCtrl.createAtManager();
  }

  public static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager();
    }
    return PermissionManager.instance;
  }

  /**
   * 检查权限状态
   * @param permission 权限名称
   * @returns Promise<boolean> 是否已授权
   */
  async checkPermission(permission: string): Promise<boolean> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      const tokenId = bundleInfo.appInfo.accessTokenId;
      
      const result = await this.atManager.checkAccessToken(tokenId, permission);
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      console.error('PermissionManager: checkPermission failed', error);
      return false;
    }
  }

  /**
   * 请求单个权限
   * @param context 应用上下文
   * @param permission 权限名称
   * @returns Promise<boolean> 是否授权成功
   */
  async requestPermission(context: common.UIAbilityContext, permission: string): Promise<boolean> {
    try {
      const result = await this.atManager.requestPermissionsFromUser(context, [permission]);
      return result?.authResults?.[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      console.error('PermissionManager: requestPermission failed', error);
      return false;
    }
  }

  /**
   * 请求多个权限
   * @param context 应用上下文
   * @param permissions 权限数组
   * @returns Promise<boolean[]> 各权限的授权结果
   */
  async requestPermissions(context: common.UIAbilityContext, permissions: string[]): Promise<boolean[]> {
    try {
      const result = await this.atManager.requestPermissionsFromUser(context, permissions);
      return result?.authResults?.map(status => 
        status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      ) || [];
    } catch (error) {
      console.error('PermissionManager: requestPermissions failed', error);
      return new Array(permissions.length).fill(false);
    }
  }

  /**
   * 检查并请求位置权限
   * @param context 应用上下文
   * @returns Promise<boolean> 是否获得位置权限
   */
  async ensureLocationPermission(context: common.UIAbilityContext): Promise<boolean> {
    const permissions = [
      'ohos.permission.LOCATION',
      'ohos.permission.APPROXIMATELY_LOCATION'
    ];

    // 先检查是否已有权限
    const hasLocation = await this.checkPermission(permissions[0]);
    const hasApproxLocation = await this.checkPermission(permissions[1]);

    if (hasLocation || hasApproxLocation) {
      console.info('PermissionManager: location permission already granted');
      return true;
    }

    // 请求权限
    console.info('PermissionManager: requesting location permissions');
    const results = await this.requestPermissions(context, permissions);
    
    const granted = results[0] || results[1]; // 任一权限授权即可
    console.info('PermissionManager: location permission result:', granted);
    
    return granted;
  }

  /**
   * 检查并请求网络权限
   * @param context 应用上下文
   * @returns Promise<boolean> 是否获得网络权限
   */
  async ensureInternetPermission(context: common.UIAbilityContext): Promise<boolean> {
    const permission = 'ohos.permission.INTERNET';
    
    const hasPermission = await this.checkPermission(permission);
    if (hasPermission) {
      console.info('PermissionManager: internet permission already granted');
      return true;
    }

    console.info('PermissionManager: requesting internet permission');
    const granted = await this.requestPermission(context, permission);
    console.info('PermissionManager: internet permission result:', granted);
    
    return granted;
  }

  /**
   * 一次性申请应用所需的所有权限
   * @param context 应用上下文
   * @returns Promise<{location: boolean, internet: boolean}> 权限申请结果
   */
  async requestAllPermissions(context: common.UIAbilityContext): Promise<{
    location: boolean;
    internet: boolean;
  }> {
    console.info('PermissionManager: requesting all required permissions');
    
    const [locationGranted, internetGranted] = await Promise.all([
      this.ensureLocationPermission(context),
      this.ensureInternetPermission(context)
    ]);

    const result = {
      location: locationGranted,
      internet: internetGranted
    };

    console.info('PermissionManager: all permissions result:', result);
    return result;
  }
}

/**
 * 在EntryAbility中使用权限管理器的示例
 */
export class EntryAbilityPermissionExample {
  private permissionManager = PermissionManager.getInstance();

  /**
   * 在onCreate中申请权限
   */
  async onCreate(want: any, launchParam: any) {
    console.info('EntryAbility onCreate');
    
    // 获取应用上下文
    const context = this.context as common.UIAbilityContext;
    
    // 申请所有必要权限
    const permissions = await this.permissionManager.requestAllPermissions(context);
    
    if (!permissions.location) {
      console.warn('EntryAbility: location permission denied, some features may not work');
      // 可以显示提示信息给用户
    }
    
    if (!permissions.internet) {
      console.warn('EntryAbility: internet permission denied, app may not function properly');
    }
    
    // 继续应用初始化...
  }

  /**
   * 在需要使用定位功能前检查权限
   */
  async beforeUsingLocation(): Promise<boolean> {
    const context = this.context as common.UIAbilityContext;
    const hasPermission = await this.permissionManager.ensureLocationPermission(context);
    
    if (!hasPermission) {
      // 显示权限说明对话框
      console.warn('Location permission required for this feature');
      return false;
    }
    
    return true;
  }
}

/**
 * 在页面组件中使用权限管理器的示例
 */
export class PagePermissionExample {
  private permissionManager = PermissionManager.getInstance();

  /**
   * 在点击"找厕所"按钮时检查权限
   */
  async onFindToiletClick() {
    try {
      // 获取应用上下文
      const context = getContext(this) as common.UIAbilityContext;
      
      // 确保有定位权限
      const hasLocationPermission = await this.permissionManager.ensureLocationPermission(context);
      
      if (!hasLocationPermission) {
        // 显示权限被拒绝的提示
        this.showPermissionDeniedDialog();
        return;
      }
      
      // 继续执行定位和搜索逻辑
      await this.performLocationSearch();
      
    } catch (error) {
      console.error('onFindToiletClick failed:', error);
    }
  }

  private showPermissionDeniedDialog() {
    // 显示权限说明对话框
    console.info('Showing permission denied dialog');
    // 实际实现中可以使用AlertDialog或自定义弹窗
  }

  private async performLocationSearch() {
    // 执行实际的定位和搜索逻辑
    console.info('Performing location search');
  }
}

// 导出权限管理器实例
export const permissionManager = PermissionManager.getInstance();

// 常用权限常量
export const PERMISSIONS = {
  LOCATION: 'ohos.permission.LOCATION',
  APPROXIMATELY_LOCATION: 'ohos.permission.APPROXIMATELY_LOCATION',
  INTERNET: 'ohos.permission.INTERNET'
} as const;