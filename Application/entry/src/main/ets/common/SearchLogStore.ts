import preferences from '@ohos.data.preferences';

export type SearchLog = {
  timestamp: number;
  centerLatitude?: number;
  centerLongitude?: number;
  radiusMeters?: number;
  resultCount?: number;
  message?: string; // 错误或说明信息
};

class SearchLogStore {
  private static instance: SearchLogStore | null = null;
  private pref!: preferences.Preferences;
  private static readonly PREF_NAME = 'search_logs';
  private static readonly KEY = 'logs';

  private constructor(pref: preferences.Preferences) {
    this.pref = pref;
  }

  public static async init(context: any): Promise<void> {
    if (!SearchLogStore.instance) {
      const pref = await preferences.getPreferences(context, SearchLogStore.PREF_NAME);
      SearchLogStore.instance = new SearchLogStore(pref);
    }
  }

  public static getInstance(): SearchLogStore {
    if (!SearchLogStore.instance) {
      throw new Error('SearchLogStore has not been initialized. Call init() first.');
    }
    return SearchLogStore.instance;
  }

  public async append(log: SearchLog): Promise<void> {
    const current = await this.getAll();
    current.push(log);
    const trimmed = current.slice(Math.max(0, current.length - 200));
    await this.pref.put(SearchLogStore.KEY, JSON.stringify(trimmed));
    await this.pref.flush();
  }

  public async appendError(message: string, info?: Omit<SearchLog, 'timestamp' | 'message'>): Promise<void> {
    await this.append({ timestamp: Date.now(), message, ...info });
  }

  public async getAll(): Promise<SearchLog[]> {
    const raw = (await this.pref.get(SearchLogStore.KEY, '[]')) as string;
    try {
      const arr = JSON.parse(raw) as SearchLog[];
      if (!Array.isArray(arr)) return [];
      return arr;
    } catch (_) {
      return [];
    }
  }

  public async clear(): Promise<void> {
    await this.pref.put(SearchLogStore.KEY, '[]');
    await this.pref.flush();
  }
}

export default SearchLogStore;