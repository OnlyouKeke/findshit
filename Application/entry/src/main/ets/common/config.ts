/**
 * 应用配置文件
 * 包含默认坐标、搜索参数等关键配置
 */

import { LatLng } from './types';

// 应用标题
export const APP_TITLE = '找屎';

// 默认地图中心点（上海市中心）
export const DEFAULT_CENTER: LatLng = { lat: 31.2304, lng: 121.4737 };

// 默认搜索半径（米）
export const DEFAULT_RADIUS_M = 1500;

// 默认结果数量限制
export const DEFAULT_LIMIT = 20;

// 地图缩放级别
export const DEFAULT_ZOOM = 15;
export const MIN_ZOOM = 10;
export const MAX_ZOOM = 20;

// 定位超时时间（毫秒）
export const LOCATION_TIMEOUT_MS = 10000;

// 权限相关
export const PERMISSIONS = {
  LOCATION: 'ohos.permission.LOCATION',
  APPROXIMATELY_LOCATION: 'ohos.permission.APPROXIMATELY_LOCATION',
  INTERNET: 'ohos.permission.INTERNET'
} as const;