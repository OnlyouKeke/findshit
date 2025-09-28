/**
 * 导航唤起工具
 * 支持华为地图导航API的路径规划功能，包括步行和骑行规划
 * 回退到常见地图App（百度、腾讯）
 */

import { common, Want } from '@kit.AbilityKit';
import { TravelMode, LatLng } from './types';

/**
 * 打开华为地图进行路径规划
 * @param context 应用上下文
 * @param destination 目标位置
 * @param destinationName 目标位置名称
 * @param travelMode 出行方式
 */
export async function openNavigationWithPlanning(
  context: common.UIAbilityContext,
  destination: LatLng,
  destinationName: string = '目标位置',
  travelMode: TravelMode = TravelMode.WALKING
): Promise<boolean> {
  try {
    console.info('Navigation: opening Huawei Map navigation', {
      destination,
      destinationName,
      travelMode
    });

    // 华为地图导航 URI
    const vehicleType = getVehicleType(travelMode);
    const huaweiMapUri = `mapapp://navigation?` +
      `daddr=${destination.lat},${destination.lng}` +
      `&dname=${encodeURIComponent(destinationName)}` +
      `&vehicle=${vehicleType}`;

    const want: Want = {
      uri: huaweiMapUri,
      action: 'ohos.want.action.viewData'
    };

    await context.startAbility(want);
    console.info('Navigation: Huawei Map opened successfully');
    return true;

  } catch (error) {
    console.error('Navigation: failed to open Huawei Map', error);
    
    // 回退到外部导航应用
    return await openExternalNavigation(context, destination.lat, destination.lng, destinationName);
  }
}

/**
 * 将TravelMode转换为华为地图API的vehicleType参数
 * @param mode 出行方式
 * @returns vehicleType 0-驾车，1-步行，2-骑行
 */
function getVehicleType(mode: TravelMode): number {
  switch (mode) {
    case TravelMode.WALKING:
      return 1; // 步行
    case TravelMode.CYCLING:
      return 2; // 骑行
    default:
      return 1; // 默认步行
  }
}

/** 打开外部导航应用（兼容原有接口） */
export async function openExternalNavigation(
  ctx: common.UIAbilityContext,
  lat: number,
  lng: number,
  name?: string
): Promise<boolean> {
  const title = encodeURIComponent(name || '目标位置');
  const dlat = lat.toFixed(6);
  const dlng = lng.toFixed(6);

  // 常见地图 URI（按优先顺序尝试）
  const candidates: string[] = [
    // 腾讯地图
    `qqmap://map/routeplan?type=drive&to=${title}&tocoord=${dlat},${dlng}`,
    // 百度地图
    `baidumap://map/direction?destination=name:${title}|latlng:${dlat},${dlng}&mode=driving`,
    // 通用 geo（部分地图兼容）
    `geo:${dlat},${dlng}?q=${dlat},${dlng}(${title})`
  ];

  for (const uri of candidates) {
    try {
      const want: Want = {
        uri,
        action: 'ohos.want.action.viewData'
      };
      await ctx.startAbility(want);
      return true;
    } catch (err) {
      // 继续尝试下一个 URI
      console.warn('openExternalNavigation: failed uri ->', uri, err);
    }
  }

  return false;
}
