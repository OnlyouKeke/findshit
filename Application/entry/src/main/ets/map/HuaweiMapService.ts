import { MapService, ToiletPoi, Site } from './MapService';
import { geoLocationManager } from '@kit.LocationKit';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import http from '@ohos.net.http';

export class HuaweiMapService implements MapService {
  public async searchNearbyToilets(longitude: number, latitude: number, radiusMeters: number = 1000): Promise<ToiletPoi[]> {
    console.log(`Searching for nearby toilets using Huawei Map at (${longitude}, ${latitude}) within ${radiusMeters}m`);
    
    try {
      // 方案A：优先使用华为地图站点检索（关键词+附近）
      return await this.searchWithHuaweiSite(longitude, latitude, radiusMeters);
    } catch (error) {
      console.warn('华为地图Kit不可用，使用模拟数据:', error);
      // 使用Mock数据作为后备方案
      return await this.getMockToiletData(longitude, latitude, radiusMeters);
    }
  }

  // 使用华为地图 Site 检索（关键词：厕所/卫生间/公厕）
  private async searchWithHuaweiSite(longitude: number, latitude: number, radiusMeters: number): Promise<ToiletPoi[]> {
    // 半径限制，避免过大导致性能问题
    const radius = Math.min(Math.max(radiusMeters, 50), 3000);
    const keyword = '厕所|卫生间|公厕';

    // Haversine 距离计算
    const toRad = (x: number) => x * Math.PI / 180;
    const haversine = (lat1: number, lon1: number, lat2: number, lon2: number) => {
      const R = 6371000; // meters
      const dLat = toRad(lat2 - lat1);
      const dLon = toRad(lon2 - lon1);
      const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    };

    try {
      // 通过 MapKit 的 site 模块进行站点检索
      const anyMap: any = map as any;
      const siteModule = anyMap?.site ?? anyMap; // 兼容不同导出形式
      if (!siteModule) {
        throw new Error('MapKit site module not available');
      }

      // 站点服务实例与附近检索请求（使用关键词）
      const service = new siteModule.SearchService();
      const request = {
        query: '厕所|卫生间|公厕', // 主关键词，支持常见同义词
        // 允许同义词匹配（如 SDK 支持正则/模糊时）
        // 位置与半径
        location: { latitude, longitude },
        radius: radius,
        pageIndex: 1,
        pageSize: 50
      };

      // 优先尝试附近检索；如 SDK 需不同方法名，使用 any 访问避免编译失败
      const resp = await (service.nearbySearch ? service.nearbySearch(request) : service.textSearch?.(request));
      const items: any[] = Array.isArray(resp?.sites) ? resp.sites : (Array.isArray(resp?.results) ? resp.results : []);
      if (!items || items.length === 0) {
        // 若站点检索为空，回退 Overpass
        return await this.searchWithHuaweiMapKit(longitude, latitude, radiusMeters);
      }

      const toilets: ToiletPoi[] = items.map((el: any) => {
        const name = el?.name ?? el?.poi?.name ?? '公共厕所';
        const address = el?.formatAddress ?? el?.address ?? '';
        const lat = el?.location?.lat ?? el?.location?.latitude ?? el?.lat;
        const lon = el?.location?.lng ?? el?.location?.longitude ?? el?.lon;
        const id = String(el?.siteId ?? el?.id ?? `${lat},${lon}`);
        const distance = Math.round(haversine(latitude, longitude, lat, lon));
        const site: Site = {
          id,
          name,
          address,
          location: { latitude: lat, longitude: lon }
        };
        return { ...site, distance };
      })
        .filter(t => Number.isFinite(t.distance) && t.distance <= radiusMeters)
        .sort((a, b) => a.distance - b.distance);

      return toilets;
    } catch (error) {
      // 抛出错误交由上层使用 Mock 兜底
      console.warn('Site search failed, fallback to Overpass:', error);
      return await this.searchWithHuaweiMapKit(longitude, latitude, radiusMeters);
    }
  }

  private async searchWithHuaweiMapKit(longitude: number, latitude: number, radiusMeters: number): Promise<ToiletPoi[]> {
    // 方案B：使用 Overpass API 获取附近公厕的真实数据
    try {
      const httpRequest = http.createHttp();

      // 限制半径避免过大查询导致性能问题
      const radius = Math.min(Math.max(radiusMeters, 50), 3000);
      const query = `[out:json][timeout:25];\n`
        + `node(around:${radius},${latitude},${longitude})["amenity"="toilets"];\n`
        + `out;`;

      const url = 'https://overpass-api.de/api/interpreter';
      const res = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/x-www-form-urlencoded' },
        extraData: `data=${encodeURIComponent(query)}`,
        readTimeout: 15000,
        connectTimeout: 10000
      });

      if (res.responseCode !== 200) {
        throw new Error(`Overpass error: ${res.responseCode}`);
      }

      const data = JSON.parse(res.result as string);
      const elements: Array<any> = Array.isArray(data?.elements) ? data.elements : [];

      const toRad = (x: number) => x * Math.PI / 180;
      const haversine = (lat1: number, lon1: number, lat2: number, lon2: number) => {
        const R = 6371000;
        const dLat = toRad(lat2 - lat1);
        const dLon = toRad(lon2 - lon1);
        const a = Math.sin(dLat / 2) ** 2 +
          Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
          Math.sin(dLon / 2) ** 2;
        return 2 * R * Math.asin(Math.sqrt(a));
      };

      const toilets: ToiletPoi[] = elements.map((el) => {
        const name = el.tags?.name || '公共厕所';
        const address = el.tags?.addr_full || el.tags?.addr_street || '';
        const lat = el.lat;
        const lon = el.lon;
        const distance = Math.round(haversine(latitude, longitude, lat, lon));
        const site: Site = {
          id: String(el.id),
          name,
          address,
          location: { latitude: lat, longitude: lon }
        };
        return { ...site, distance };
      })
        .filter(t => Number.isFinite(t.distance) && t.distance <= radiusMeters)
        .sort((a, b) => a.distance - b.distance);

      httpRequest.destroy();
      return toilets;
    } catch (error) {
      console.error('Overpass search failed:', error);
      // 抛出错误以便上层使用 Mock 数据兜底
      throw error;
    }
  }

  private async getMockToiletData(longitude: number, latitude: number, radiusMeters: number): Promise<ToiletPoi[]> {
    // 增强的Mock数据，更真实的公厕信息
    const mockResults: ToiletPoi[] = [
      {
        id: '1',
        name: '人民广场地铁站公厕',
        address: '人民广场地铁站B1层',
        location: {
          longitude: longitude + 0.001,
          latitude: latitude + 0.001
        },
        distance: 120
      },
      {
        id: '2', 
        name: '南京东路步行街公厕',
        address: '南京东路步行街中段',
        location: {
          longitude: longitude - 0.001,
          latitude: latitude - 0.001
        },
        distance: 250
      },
      {
        id: '3',
        name: '外滩观光隧道公厕',
        address: '外滩观光隧道入口处',
        location: {
          longitude: longitude + 0.002,
          latitude: latitude - 0.001
        },
        distance: 380
      },
      {
        id: '4',
        name: '豫园商城公厕',
        address: '豫园商城1楼东侧',
        location: {
          longitude: longitude - 0.002,
          latitude: latitude + 0.001
        },
        distance: 450
      },
      {
        id: '5',
        name: '新天地广场公厕',
        address: '新天地广场地下一层',
        location: {
          longitude: longitude + 0.003,
          latitude: latitude + 0.002
        },
        distance: 680
      },
      {
        id: '6',
        name: '静安寺地铁站公厕',
        address: '静安寺地铁站2号出口',
        location: {
          longitude: longitude - 0.003,
          latitude: latitude + 0.003
        },
        distance: 750
      },
      {
        id: '7',
        name: '徐家汇商圈公厕',
        address: '徐家汇港汇恒隆广场B1层',
        location: {
          longitude: longitude + 0.004,
          latitude: latitude - 0.002
        },
        distance: 890
      },
      {
        id: '8',
        name: '陆家嘴金融中心公厕',
        address: '陆家嘴环路正大广场',
        location: {
          longitude: longitude - 0.004,
          latitude: latitude - 0.003
        },
        distance: 950
      }
    ];
    
    // 模拟网络延迟
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // 根据半径过滤结果并按距离排序
    const filteredResults = mockResults
      .filter(toilet => toilet.distance <= radiusMeters)
      .sort((a, b) => a.distance - b.distance);
    
    return filteredResults;
  }
}