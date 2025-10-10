import { bundleManager, OpenLinkOptions } from '@kit.AbilityKit';
import type { common } from '@kit.AbilityKit';
import SearchLogStore, { SearchLogInfo } from '../common/SearchLogStore';
import type { ToiletPoi } from './MapService';
import AppStorage from '../common/AppStorage';

export class MapLauncher {
  private static readonly TAG = 'MapLauncher';

  /** 读取当前设置的地图引擎 */
  static async getSelectedEngine(): Promise<string> {
    try {
      return await AppStorage.getInstance().getMapEngine();
    } catch {
      return 'huawei';
    }
  }

  /** 统一的 canOpen + openLink（强制带 OpenLinkOptions） */
  private static async canOpen(ctx: common.UIAbilityContext, link: string): Promise<boolean> {
    try {
      const opts: OpenLinkOptions = { appLinkingOnly: false };
      // @ts-ignore: Harmony API
      if (typeof (ctx as any).canOpenLink === 'function') {
        const ok = await (ctx as any).canOpenLink(link, opts);
        return !!ok;
      }
    } catch (_) {}
    // 老系统可能没有 canOpenLink，就返回 true 让上层去尝试
    return true;
  }

  private static async openViaStartAbility(ctx: common.UIAbilityContext, uri: string): Promise<boolean> {
    const want = {
      action: 'ohos.want.action.viewData',               // 关键：用 viewData
      entities: ['entity.system.browsable'],             // 关键：允许外部可浏览
      uri
    } as any;
    try {
      await (ctx as any).startAbility(want);
      return true;
    } catch (e) {
      console.warn(`[${MapLauncher.TAG}] startAbility failed, uri=${uri}, e=${JSON.stringify(e)}`);
      return false;
    }
  }

  private static async openViaLink(ctx: common.UIAbilityContext, link: string): Promise<boolean> {
    const opts: OpenLinkOptions = { appLinkingOnly: false };
    try {
      await (ctx as any).openLink(link, opts);
      return true;
    } catch (e) {
      console.warn(`[${MapLauncher.TAG}] openLink failed, link=${link}, e=${JSON.stringify(e)}`);
      return false;
    }
  }

  private static async tryOpen(ctx: common.UIAbilityContext, uri: string): Promise<boolean> {
    if (typeof uri !== 'string' || uri.length === 0) return false;
    // 先探测（如果支持）
    const probe = await MapLauncher.canOpen(ctx, uri);
    if (!probe) {
      console.info(`[${MapLauncher.TAG}] canOpenLink=false, skip ${uri}`);
      return false;
    }
    // 先 startAbility（对自定义 scheme 成功率更高），失败再 openLink
    if (await MapLauncher.openViaStartAbility(ctx, uri)) return true;
    if (await MapLauncher.openViaLink(ctx, uri)) return true;
    return false;
  }

  /** 打开导航到指定厕所 */
  static async openNavigation(
    context: common.UIAbilityContext,
    toilet: ToiletPoi,
    travelMode: 'walking' | 'cycling' = 'walking'
  ): Promise<void> {
    const engine = await MapLauncher.getSelectedEngine();
    const { latitude, longitude } = toilet.location;
    const name = encodeURIComponent(toilet.name);

    console.info(`[${MapLauncher.TAG}] engine=${engine} name=${toilet.name} lat=${latitude} lon=${longitude} mode=${travelMode}`);

    // 尽量覆盖 Petal/MapApp 不同版本参数；以及最终的 geo/https 兜底
    const petalModeA = travelMode === 'walking' ? 'walking' : 'cycling'; // 有些版本接受全词
    const petalModeB = travelMode === 'walking' ? 'walk' : 'bike';       // 有些版本接受简写
    const mapAppMode = travelMode === 'walking' ? 'walk' : 'cycle';      // 官方示例里出现的取值（如 drive/walk/cycle）:contentReference[oaicite:3]{index=3}

    const candidates: string[] = [];

    if (engine === 'amap') {
      candidates.push(`amapuri://route/plan/?dlat=${latitude}&dlon=${longitude}&dname=${name}&dev=0&t=${travelMode === 'walking' ? 2 : 0}`);
    } else if (engine === 'baidu') {
      candidates.push(
        `baidumap://map/direction?destination=latlng:${latitude},${longitude}|name:${name}&coord_type=wgs84&mode=${travelMode === 'walking' ? 'walking' : 'riding'}`
      );
    } else {
      // Huawei 优先：Petal/MapApp 多方案
      candidates.push(
        // Petal 官方常见 routePlan
        `petalmaps://routePlan?destLat=${latitude}&destLng=${longitude}&destName=${name}&navType=${petalModeA}`,
        `petalmaps://routePlan?destLat=${latitude}&destLng=${longitude}&destName=${name}&navType=${petalModeB}`,
        // 旧/替代 navigation 写法
        `petalmaps://navigation?dlat=${latitude}&dlon=${longitude}&dname=${name}&type=${petalModeB}`,
        // 官方答复里给过的 MapApp Deep Link（Android/Harmony 设备大多可识别）
        `mapapp://navigation?daddr=${latitude},${longitude}&language=zh&type=${mapAppMode}`  // :contentReference[oaicite:4]{index=4}
      );
    }

    // 通用兜底
    const geo = `geo:${latitude},${longitude}?q=${name}`;
    const httpsFallback = `https://petalmaps.com/?q=${latitude},${longitude}`; // 浏览器打开也可让用户再跳 App

    // geo、https 放到最后兜底
    candidates.push(geo, httpsFallback);

    try {
      for (const uri of candidates) {
        console.info(`[${MapLauncher.TAG}] try open ${uri}`);
        if (await MapLauncher.tryOpen(context, uri)) return;
      }
      throw new Error('all navigation attempts failed');
    } catch (err) {
      console.error(`[${MapLauncher.TAG}] navigation failed err=${JSON.stringify(err)}`);
      try {
        await SearchLogStore.init(context);
        const info: SearchLogInfo = { centerLatitude: latitude, centerLongitude: longitude };
        const msg = `导航失败: ${(err as any)?.message || 'Unknown error'} | engine=${engine}`;
        await SearchLogStore.getInstance().appendError(msg, info);
      } catch {}
      throw err;
    }
  }
}

export default MapLauncher;
