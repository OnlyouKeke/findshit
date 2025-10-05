import preferences from '@ohos.data.preferences';

export type LocationLog = {
  timestamp: number;
  latitude?: number;
  longitude?: number;
  message?: string; // 错误或说明信息
};

class LocationLogStore {
  private static instance: LocationLogStore | null = null;
  private pref!: preferences.Preferences;
  private static readonly PREF_NAME = 'location_logs';
  private static readonly KEY = 'logs';

  private constructor(pref: preferences.Preferences) {
    this.pref = pref;
  }

  public static async init(context: any): Promise<void> {
    if (!LocationLogStore.instance) {
      const pref = await preferences.getPreferences(context, LocationLogStore.PREF_NAME);
      LocationLogStore.instance = new LocationLogStore(pref);
    }
  }

  public static getInstance(): LocationLogStore {
    if (!LocationLogStore.instance) {
      throw new Error('LocationLogStore has not been initialized. Call init() first.');
    }
    return LocationLogStore.instance;
  }

  public async append(log: LocationLog): Promise<void> {
    const current = await this.getAll();
    // 只保留最近200条
    current.push(log);
    const trimmed = current.slice(Math.max(0, current.length - 200));
    await this.pref.put(LocationLogStore.KEY, JSON.stringify(trimmed));
    await this.pref.flush();
  }

  public async appendError(message: string): Promise<void> {
    await this.append({ timestamp: Date.now(), message });
  }

  public async getAll(): Promise<LocationLog[]> {
    const raw = (await this.pref.get(LocationLogStore.KEY, '[]')) as string;
    try {
      const arr = JSON.parse(raw) as LocationLog[];
      if (!Array.isArray(arr)) return [];
      return arr;
    } catch (_) {
      return [];
    }
  }

  public async clear(): Promise<void> {
    await this.pref.put(LocationLogStore.KEY, '[]');
    await this.pref.flush();
  }
}

export default LocationLogStore;