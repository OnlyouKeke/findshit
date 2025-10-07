import type { common } from '@kit.AbilityKit';
import type { ToiletPoi } from './MapService';
import AppStorage from '../common/AppStorage';

/**
 * MapLauncher: 根据用户选择的地图引擎，构造深链并尝试打开导航。
 * 首选指定地图的深链，失败则回退到通用 `geo:` 链接。
 */
export class MapLauncher {
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
        // 华为地图（Petal Maps）优化：优先尝试 petalmaps 深链，其次回退到 geo: 通用协议
        // 注意：不同版本的 Petal Maps 深链参数可能不一致，此处采用较为通用的 routePlan 形式
        const mode = travelMode === 'walking' ? 'walk' : 'bike';
        const petalUriCandidates: string[] = [
          // 常见路线规划入口（destLat/destLng）
          `petalmaps://routePlan?destLat=${latitude}&destLng=${longitude}&destName=${name}&navType=${mode}`,
          // 一些版本使用 dlat/dlon/dname
          `petalmaps://routePlan?dlat=${latitude}&dlon=${longitude}&dname=${name}&navType=${mode}`,
          // 直接导航入口
          `petalmaps://navigation?dlat=${latitude}&dlon=${longitude}&dname=${name}&mode=${mode}`
        ];
        // 逐一尝试 Petal Maps 深链，若全部失败再用 geo
        for (const candidate of petalUriCandidates) {
          try {
            await (context as any).openLink({ url: candidate });
            return;
          } catch (_) {
            // 继续尝试下一个候选
          }
        }
        primaryUri = `geo:${latitude},${longitude}?q=${name}`;
        break;
      }
    }

    // 回退通用geo链接
    const fallbackUri = `geo:${latitude},${longitude}?q=${name}`;

    // 使用 UIAbilityContext.openLink 打开深链；失败则回退
    try {
      // @ts-ignore ArkTS API: openLink(options) 支持传入 { url/uri }
      await (context as any).openLink({ url: primaryUri });
    } catch (primaryErr) {
      try {
        // @ts-ignore
        await (context as any).openLink({ url: fallbackUri });
      } catch (fallbackErr) {
        // 两次都失败则抛出错误供页面提示
        throw fallbackErr || primaryErr;
      }
    }
  }
}

export default MapLauncher;