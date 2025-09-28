// Define Site interface based on HarmonyOS MapKit structure
export interface Site {
  id: string;
  name: string;
  address: string;
  location: {
    longitude: number;
    latitude: number;
  };
}

export type ToiletPoi = Site & {
  distance: number;
}

export interface MapService {
  searchNearbyToilets(longitude: number, latitude: number): Promise<ToiletPoi[]>;
}