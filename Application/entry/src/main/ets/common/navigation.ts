/**
 * 导航唤起工具
 * 尝试调用常见地图App（高德、百度、腾讯），失败则回退到通用 geo/HTTP 链接。
 */

import { common } from '@kit.AbilityKit';
import type Want from '@ohos.app.ability.Want';

/** 打开外部导航应用 */
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
