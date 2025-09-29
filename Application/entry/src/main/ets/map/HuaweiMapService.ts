import { MapService, ToiletPoi, Site } from './MapService';

// Mock implementation since @kit.MapKit exports are not available
export class HuaweiMapService implements MapService {
  public async searchNearbyToilets(longitude: number, latitude: number, radiusMeters: number = 1000): Promise<ToiletPoi[]> {
    console.log(`Searching for nearby toilets using Huawei Map at (${longitude}, ${latitude}) within ${radiusMeters}m`);
    
    // Mock data for testing - replace with actual MapKit implementation when available
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
      }
    ];
    
    // 模拟网络延迟
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // 根据半径过滤结果
    const filteredResults = mockResults.filter(toilet => toilet.distance <= radiusMeters);
    
    return filteredResults;
  }
}