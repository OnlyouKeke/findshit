import { HuaweiMapService } from './HuaweiMapService';
import { MapService } from './MapService';

export class MapServiceFactory {
  public static async createMapService(): Promise<MapService> {
    return new HuaweiMapService();
  }
}