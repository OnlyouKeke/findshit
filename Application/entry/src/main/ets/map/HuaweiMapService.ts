import { MapService, ToiletPoi, Site } from './MapService';

// Mock implementation since @kit.MapKit exports are not available
export class HuaweiMapService implements MapService {
  public async searchNearbyToilets(longitude: number, latitude: number): Promise<ToiletPoi[]> {
    console.log(`Searching for nearby toilets using Huawei Map at (${longitude}, ${latitude})`);
    
    // Mock data for testing - replace with actual MapKit implementation when available
    const mockResults: ToiletPoi[] = [
      {
        id: '1',
        name: '公共厕所1',
        address: '示例地址1',
        location: {
          longitude: longitude + 0.001,
          latitude: latitude + 0.001
        },
        distance: 100
      },
      {
        id: '2', 
        name: '公共厕所2',
        address: '示例地址2',
        location: {
          longitude: longitude - 0.001,
          latitude: latitude - 0.001
        },
        distance: 200
      }
    ];
    
    return mockResults;
  }
}