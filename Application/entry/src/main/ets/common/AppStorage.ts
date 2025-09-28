import preferences from '@ohos.data.preferences';

const MAP_ENGINE_KEY = 'map_engine';
const DEFAULT_MAP_ENGINE = 'huawei'; // 默认使用华为地图

class AppStorage {
  private static instance: AppStorage;
  private pref: preferences.Preferences;

  private constructor(pref: preferences.Preferences) {
    this.pref = pref;
  }

  public static async init(context: any): Promise<void> {
    if (!AppStorage.instance) {
      const pref = await preferences.getPreferences(context, 'map_settings');
      AppStorage.instance = new AppStorage(pref);
    }
  }

  public static getInstance(): AppStorage {
    if (!AppStorage.instance) {
      throw new Error("AppStorage has not been initialized. Call init() first.");
    }
    return AppStorage.instance;
  }

  public async getMapEngine(): Promise<string> {
    return (await this.pref.get(MAP_ENGINE_KEY, DEFAULT_MAP_ENGINE)) as string;
  }

  public async setMapEngine(engine: string): Promise<void> {
    await this.pref.put(MAP_ENGINE_KEY, engine);
    await this.pref.flush();
  }
}

// 导出类
export default AppStorage;