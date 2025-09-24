/**
 * 基础类型定义
 * 用于「找屎」应用的数据模型
 */

// 经纬度坐标
export interface LatLng {
  lat: number;  // 纬度
  lng: number;  // 经度
}

// 厕所POI信息
export interface ToiletPoi extends LatLng {
  id: string;          // 全局唯一ID
  name: string;        // 展示名称
  distance?: number;   // 距离（米，端侧计算填充）
  openHours?: string;  // 营业时间："06:00-23:00" / "24h" / "无障碍" 等
}

// 搜索选项
export interface SearchOptions {
  center: LatLng;      // 搜索中心点
  radiusM: number;     // 搜索半径（米）
  limit?: number;      // 结果上限（默认 20）
}

// 应用状态枚举
export enum AppState {
  INIT = 'init',           // 初始化
  IDLE = 'idle',           // 空闲状态
  LOCATING = 'locating',   // 定位中
  SEARCHING = 'searching', // 搜索中
  RENDERING = 'rendering', // 渲染中
  EMPTY = 'empty',         // 无结果
  ERROR = 'error'          // 错误状态
}

// 错误类型
export interface AppError {
  code: string;
  message: string;
  retryable?: boolean;
}

// UI 回调包装（用于 ArkUI V1 组件避免直接传函数作为 Prop）
export interface CallbackHandler {
  handler?: () => void;
}

// 0/1 参数回调包装（用于更复杂组件）
export interface Callback0 { handler?: () => void }
export interface Callback1<T> { handler?: (arg: T) => void }

// 最小错误类型（用于宽松捕获）
export interface MinimalError { code?: string; message?: string }
