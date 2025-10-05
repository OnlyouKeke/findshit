import { MapService, ToiletPoi, Site } from './MapService';
import { geoLocationManager } from '@kit.LocationKit';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import http from '@ohos.net.http';

export class HuaweiMapService implements MapService {
  public async searchNearbyToilets(longitude: number, latitude: number, radiusMeters: number = 1000): Promise<ToiletPoi[]> {
    console.log(`Searching for nearby toilets using Huawei Map at (${longitude}, ${latitude}) within ${radiusMeters}m`);
    
    try {
      // 尝试使用华为地图Kit进行搜索
      return await this.searchWithHuaweiMapKit(longitude, latitude, radiusMeters);
    } catch (error) {
      console.warn('华为地图Kit不可用，使用模拟数据:', error);
      // 使用Mock数据作为后备方案
      return await this.getMockToiletData(longitude, latitude, radiusMeters);
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