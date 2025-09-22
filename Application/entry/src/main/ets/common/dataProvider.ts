/**
 * 数据提供器接口
 * 抽象数据来源，便于后续扩展（本地数据 -> Site Kit -> 云端API）
 */

import { ToiletPoi, SearchOptions } from './types';

/**
 * 数据提供器接口
 */
export interface DataProvider {
  /**
   * 搜索附近的厕所
   * @param options 搜索选项
   * @returns Promise<ToiletPoi[]> 厕所列表
   */
  searchToilets(options: SearchOptions): Promise<ToiletPoi[]>;

  /**
   * 根据ID获取厕所详情（可选实现）
   * @param id 厕所ID
   * @returns Promise<ToiletPoi | null> 厕所详情
   */
  getToiletById?(id: string): Promise<ToiletPoi | null>;

  /**
   * 获取所有厕所数据（可选实现，用于调试）
   * @returns Promise<ToiletPoi[]> 所有厕所列表
   */
  getAllToilets?(): Promise<ToiletPoi[]>;
}