/**
 * 本地数据提供器实现
 * MVP版本使用内置种子数据 + Haversine距离筛选
 */

import { DataProvider } from './dataProvider';
import { ToiletPoi, SearchOptions, LatLng } from './types';
import { calculateDistance, isWithinRadius, sortByDistance } from './utils/haversine';
import { DEFAULT_LIMIT } from './config';

/**
 * 本地数据提供器
 */
export class LocalProvider implements DataProvider {
  private seedData: ToiletPoi[];

  constructor(seedData?: ToiletPoi[]) {
    this.seedData = seedData || this.getDefaultSeedData();
  }

  /**
   * 搜索附近的厕所
   */
  async searchToilets(options: SearchOptions): Promise<ToiletPoi[]> {
    const { center, radiusM, limit = DEFAULT_LIMIT } = options;

    // 模拟异步操作
    await new Promise(resolve => setTimeout(resolve, 100));

    // 筛选半径内的厕所
    const nearbyToilets = this.seedData.filter(toilet => 
      isWithinRadius(center, toilet, radiusM)
    );

    // 计算距离并排序
    const toiletsWithDistance = sortByDistance(nearbyToilets, center);

    // 限制结果数量
    return toiletsWithDistance.slice(0, limit);
  }

  /**
   * 根据ID获取厕所详情
   */
  async getToiletById(id: string): Promise<ToiletPoi | null> {
    const toilet = this.seedData.find(t => t.id === id);
    return toilet || null;
  }

  /**
   * 获取所有厕所数据
   */
  async getAllToilets(): Promise<ToiletPoi[]> {
    return [...this.seedData];
  }

  /**
   * 获取默认种子数据
   */
  private getDefaultSeedData(): ToiletPoi[] {
    return [
      Object.assign(new LatLng(31.2317, 121.4750), {
        id: 'toilet_001',
        name: '人民广场地铁站公厕',
        openHours: '06:00-23:00'
      }),
      Object.assign(new LatLng(31.2342, 121.4789), {
        id: 'toilet_002',
        name: '南京东路步行街公厕',
        openHours: '24h'
      }),
      Object.assign(new LatLng(31.2396, 121.4906), {
        id: 'toilet_003',
        name: '外滩观光隧道公厕',
        openHours: '07:00-22:00'
      }),
      Object.assign(new LatLng(31.2267, 121.4920), {
        id: 'toilet_004',
        name: '豫园商城公厕',
        openHours: '08:00-21:00'
      }),
      Object.assign(new LatLng(31.2198, 121.4762), {
        id: 'toilet_005',
        name: '新天地广场公厕',
        openHours: '24h'
      }),
      Object.assign(new LatLng(31.2289, 121.4478), {
        id: 'toilet_006',
        name: '静安寺地铁站公厕',
        openHours: '06:00-23:30'
      }),
      Object.assign(new LatLng(31.1956, 121.4370), {
        id: 'toilet_007',
        name: '徐家汇商圈公厕',
        openHours: '07:00-22:30'
      }),
      Object.assign(new LatLng(31.2352, 121.5058), {
        id: 'toilet_008',
        name: '陆家嘴金融中心公厕',
        openHours: '24h'
      }),
      Object.assign(new LatLng(31.2231, 121.4242), {
        id: 'toilet_009',
        name: '中山公园地铁站公厕',
        openHours: '06:00-23:00'
      }),
      Object.assign(new LatLng(31.2108, 121.4661), {
        id: 'toilet_010',
        name: '田子坊文化街公厕',
        openHours: '08:00-20:00'
      }),
      Object.assign(new LatLng(31.2289, 121.4756), {
        id: 'toilet_011',
        name: '上海博物馆公厕',
        openHours: '09:00-17:00'
      }),
      Object.assign(new LatLng(31.2258, 121.4928), {
        id: 'toilet_012',
        name: '城隍庙旅游区公厕',
        openHours: '07:00-21:00'
      }),
      Object.assign(new LatLng(31.2198, 121.4689), {
        id: 'toilet_013',
        name: '淮海中路商业街公厕',
        openHours: '24h'
      }),
      Object.assign(new LatLng(31.1979, 121.3364), {
        id: 'toilet_014',
        name: '虹桥机场T2航站楼公厕',
        openHours: '24h'
      }),
      Object.assign(new LatLng(31.2495, 121.4558), {
        id: 'toilet_015',
        name: '上海火车站公厕',
        openHours: '24h'
      })
    ];
  }
}