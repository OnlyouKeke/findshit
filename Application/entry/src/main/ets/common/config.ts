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
// 兼容旧命名
export const LOCATION_TIMEOUT = LOCATION_TIMEOUT_MS;

// 权限相关
export const PERMISSIONS = {
  LOCATION: 'ohos.permission.LOCATION',
  APPROXIMATELY_LOCATION: 'ohos.permission.APPROXIMATELY_LOCATION',
  INTERNET: 'ohos.permission.INTERNET'
} as const;

// 错误消息常量（供 geo.ts 使用）
export const ERROR_MESSAGES = {
  LOCATION_PERMISSION_DENIED: '定位权限未授权',
  LOCATION_UNAVAILABLE: '定位服务不可用',
  LOCATION_TIMEOUT: '定位超时',
  UNKNOWN_ERROR: '未知错误',
  PERMISSION_DENIED: '权限被拒绝',
  LOCATION_FAILED: '定位失败'
} as const;

// 地图动画与默认缩放（兼容旧命名）
export const CAMERA_ANIMATION_DURATION = 300; // ms
export const DEFAULT_ZOOM_LEVEL = DEFAULT_ZOOM;