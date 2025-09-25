/**
 * 导航唤起工具
 * 支持华为地图导航API的路径规划功能，包括步行和骑行规划
 * 集成高德地图路线规划API
 * 回退到常见地图App（高德、百度、腾讯）
 */

import { common, Want } from '@kit.AbilityKit';
import { TravelMode, LatLng } from './types';
import { RouteService, RouteRequest } from './routeService';

/**
 * 打开华为地图进行路径规划
 * 首先尝试使用高德地图API进行路线规划验证，然后启动导航
 * @param context 应用上下文
 * @param destination 目标位置
 * @param destinationName 目标位置名称
 * @param travelMode 出行方式
 * @param timeLimit 时间限制（分钟）
 * @param origin 起点位置（可选，默认使用当前位置）
 */
export async function openNavigationWithPlanning(
  context: common.UIAbilityContext,
  destination: LatLng,
  destinationName: string = '目标位置',
  travelMode: TravelMode = TravelMode.WALKING,
  timeLimit?: number,
  origin?: LatLng
): Promise<boolean> {
  try {
    // 如果提供了起点和时间限制，先使用高德API验证路线
    if (origin && timeLimit) {
      try {
        const routeService = RouteService.getInstance();
        const routeRequest: RouteRequest = {
          origin,
          destination,
          travelMode,
          timeLimit
        };
        
        console.info('Navigation: planning route with Amap API', routeRequest);
        const routeResult = await routeService.planRoute(routeRequest);
        
        // 检查路线是否在时间限制内
        const estimatedMinutes = routeResult.duration / 60;
        if (estimatedMinutes > timeLimit) {
          console.warn('Navigation: route exceeds time limit', {
            estimated: estimatedMinutes,
            limit: timeLimit
          });
          // 仍然继续导航，但给出提示
        }
        
        console.info('Navigation: route validated', {
          distance: routeResult.distance,
          duration: routeResult.duration,
          estimatedMinutes
        });
      } catch (routeError) {
        console.warn('Navigation: route planning failed, proceeding with direct navigation', routeError);
        // 路线规划失败不影响导航，继续使用华为地图
      }
    }
    
    // 转换出行方式为华为地图API参数
    const vehicleType = getVehicleType(travelMode);
    
    // 构建华为地图导航意图
    const petalMapWant: Want = {
      bundleName: 'com.huawei.hmos.maps.app',
      uri: 'maps://routes', // 路径规划
      parameters: {
        // 接入方业务名或包名，Link请求来源
        linkSource: 'com.example.findingshit',
        destinationLatitude: destination.lat,
        destinationLongitude: destination.lng,
        destinationName: destinationName,
        vehicleType: vehicleType, // 交通出行工具：0-驾车，1-步行，2-骑行
        // 如果有起点，添加起点参数
        ...(origin && {
          originLatitude: origin.lat,
          originLongitude: origin.lng
        }),
        // 如果有时间限制，可以添加额外参数
        ...(timeLimit && { timeLimit: timeLimit })
      }
    };

    // 启动华为地图应用
    await context.startAbility(petalMapWant);
    
    console.info('Navigation', `Started navigation to ${destinationName} with mode ${travelMode}`);
    return true;
  } catch (error) {
    console.error('Navigation', 'Failed to start Huawei Map navigation:', error);
    // 回退到传统导航方式
    return openExternalNavigation(context, destination.lat, destination.lng, destinationName);
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
    // 高德地图
    `amapuri://route/plan/?dlat=${dlat}&dlon=${dlng}&dname=${title}&dev=0&t=0`,
    // 腾讯地图
    `qqmap://map/routeplan?type=drive&to=${title}&tocoord=${dlat},${dlng}`,
    // 百度地图
    `baidumap://map/direction?destination=name:${title}|latlng:${dlat},${dlng}&mode=driving`,
    // 通用 geo（部分地图兼容）
    `geo:${dlat},${dlng}?q=${dlat},${dlng}(${title})`,
    // Web 回退（高德H5导航）
    `https://uri.amap.com/navigation?to=${dlng},${dlat},${title}&mode=car&src=findshit`
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
