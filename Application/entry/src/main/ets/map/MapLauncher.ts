import { bundleManager } from '@kit.AbilityKit';
import type { common } from '@kit.AbilityKit';
import SearchLogStore, { SearchLogInfo } from '../common/SearchLogStore';
import type { ToiletPoi } from './MapService';
import AppStorage from '../common/AppStorage';

/**
 * MapLauncher: 根据用户选择的地图引擎，构造深链并尝试打开导航。
 * 首选指定地图的深链，失败则回退到通用 `geo:` 链接。
 */
export class MapLauncher {
  private static readonly TAG = 'MapLauncher';
  /** 检查是否安装了 Petal Maps */
  private static async isPetalMapsInstalled(): Promise<boolean> {
    try {
      const info = await bundleManager.getBundleInfo('com.huawei.maps', bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      return !!info;
    } catch (_) {
      return false;
    }
  }
  /** 读取当前设置的地图引擎 */
  static async getSelectedEngine(): Promise<string> {
    try {
      return await AppStorage.getInstance().getMapEngine();
    } catch (e) {
      // 如果尚未初始化或读取失败，默认使用华为地图/系统地图
      return 'huawei';
    }
  }

  /** 打开导航到指定厕所 */
  static async openNavigation(context: common.UIAbilityContext, toilet: ToiletPoi, travelMode: 'walking' | 'cycling' = 'walking'): Promise<void> {
    const engine = await MapLauncher.getSelectedEngine();
    const { latitude, longitude } = toilet.location;
    const name = encodeURIComponent(toilet.name);

    console.info(`[${MapLauncher.TAG}] openNavigation engine=${engine} name=${toilet.name} lat=${latitude} lon=${longitude} mode=${travelMode}`);

    // 各地图深链（尽量使用通用WGS84坐标）。如未安装对应App，系统可能不响应。
    // 回退使用 geo: 链接交由系统默认地图处理。
    let primaryUri = '';
    switch (engine) {
      case 'amap':
        // 高德地图通用路线规划
        // t: 0驾车/2步行/3公交；此处使用步行
        primaryUri = `amapuri://route/plan/?dlat=${latitude}&dlon=${longitude}&dname=${name}&dev=0&t=${travelMode === 'walking' ? 2 : 0}`;
        break;
      case 'baidu':
        // 百度地图路线规划（coord_type=wgs84，mode=walking）
        primaryUri = `baidumap://map/direction?destination=latlng:${latitude},${longitude}|name:${name}&coord_type=wgs84&mode=${travelMode === 'walking' ? 'walking' : 'riding'}`;
        break;
      case 'huawei':
      default: {
        // 华为地图（Petal Maps）：优先尝试 Petal 深链，若未安装或失败则回退 geo: 协议
        const mode = travelMode === 'walking' ? 'walk' : 'bike';
        const installed = await MapLauncher.isPetalMapsInstalled();
        console.info(`[${MapLauncher.TAG}] Petal Maps installed=${installed}`);
        if (installed) {
          const petalUriCandidates: string[] = [
            `petalmaps://routePlan?destLat=${latitude}&destLng=${longitude}&destName=${name}&navType=${mode}`,
            `petalmaps://routePlan?dlat=${latitude}&dlon=${longitude}&dname=${name}&navType=${mode}`,
            `petalmaps://navigation?dlat=${latitude}&dlon=${longitude}&dname=${name}&mode=${mode}`
          ];
          // 先使用 startAbility 触发外部应用；失败再尝试 openLink
          for (const candidate of petalUriCandidates) {
            const want = { action: 'ohos.want.action.view', uri: candidate } as any;
            try {
              console.info(`[${MapLauncher.TAG}] try startAbility uri=${candidate}`);
              await (context as any).startAbility(want);
              return;
            } catch (err) {
              console.warn(`[${MapLauncher.TAG}] startAbility failed uri=${candidate} err=${JSON.stringify(err)}`);
              try {
                console.info(`[${MapLauncher.TAG}] try openLink uri=${candidate}`);
                await (context as any).openLink(candidate);
                return;
              } catch (err2) {
                console.warn(`[${MapLauncher.TAG}] openLink failed uri=${candidate} err=${JSON.stringify(err2)}`);
                // 继续尝试下一个候选
              }
            }
          }
        }
        primaryUri = `geo:${latitude},${longitude}?q=${name}`;
        break;
      }
    }

    // 回退通用geo链接
    const fallbackUri = `geo:${latitude},${longitude}?q=${name}`;

    // 使用 UIAbilityContext.openLink 打开深链；失败则回退
    // 先尝试 startAbility，再回退 openLink
    const primaryWant = { action: 'ohos.want.action.view', uri: primaryUri } as any;
    const fallbackWant = { action: 'ohos.want.action.view', uri: fallbackUri } as any;
    try {
      console.info(`[${MapLauncher.TAG}] try startAbility primary uri=${primaryUri}`);
      await (context as any).startAbility(primaryWant);
      return;
    } catch (primaryErr) {
      console.warn(`[${MapLauncher.TAG}] startAbility primary failed err=${JSON.stringify(primaryErr)}`);
      try {
        console.info(`[${MapLauncher.TAG}] try startAbility fallback uri=${fallbackUri}`);
        await (context as any).startAbility(fallbackWant);
        return;
      } catch (fallbackStartErr) {
        console.warn(`[${MapLauncher.TAG}] startAbility fallback failed err=${JSON.stringify(fallbackStartErr)}`);
        try {
          console.info(`[${MapLauncher.TAG}] try openLink primary uri=${primaryUri}`);
          await (context as any).openLink(primaryUri);
          return;
        } catch (primaryErr2) {
          console.warn(`[${MapLauncher.TAG}] openLink primary failed err=${JSON.stringify(primaryErr2)}`);
          try {
            console.info(`[${MapLauncher.TAG}] try openLink fallback uri=${fallbackUri}`);
            await (context as any).openLink(fallbackUri);
            return;
          } catch (fallbackErr2) {
            const finalErr = fallbackErr2 || primaryErr2 || fallbackStartErr || primaryErr;
            console.error(`[${MapLauncher.TAG}] navigation failed final err=${JSON.stringify(finalErr)}`);
            // 写入搜索日志（导航失败），方便后续排查
            try {
              await SearchLogStore.init(context);
              const info: SearchLogInfo = {
                centerLatitude: latitude,
                centerLongitude: longitude
              };
              const msg = `导航失败: ${(finalErr as any)?.message || 'Unknown error'} | engine=${engine}`;
              await SearchLogStore.getInstance().appendError(msg, info);
            } catch (_) {
              // 忽略日志写入失败
            }
            throw finalErr;
          }
        }
      }
    }
  }
}

export default MapLauncher;