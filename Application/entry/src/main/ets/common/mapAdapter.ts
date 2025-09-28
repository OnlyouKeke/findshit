/**
 * 地图适配器接口
 * 抽象地图能力，便于不同 Map Kit 版本适配
 */

import { LatLng, ToiletPoi } from './types';

/**
 * 地图标记信息
 */
export interface MapMarker {
  id: string;
  position: LatLng;
  title?: string;
  snippet?: string;
  icon?: string;
}

/**
 * 相机位置信息
 */
export interface CameraPosition {
  target: LatLng;
  zoom?: number;
  bearing?: number;
  tilt?: number;
}

/**
 * 地图适配器接口
 */
export interface MapAdapter {
  /**
   * 初始化地图（如果需要）
   * @param anchor 地图容器锚点
   */
  initIfNeeded(anchor?: unknown): void;

  /**
   * 移动相机到指定位置
   * @param target 目标坐标
   * @param zoom 缩放级别（可选）
   * @param animated 是否使用动画（默认true）
   */
  moveCamera(target: LatLng, zoom?: number, animated?: boolean): void;

  /**
   * 设置相机位置
   * @param position 相机位置信息
   * @param animated 是否使用动画（默认true）
   */
  setCameraPosition(position: CameraPosition, animated?: boolean): void;

  /**
   * 启用/禁用我的位置显示
   * @param enabled 是否启用
   */
  setMyLocationEnabled(enabled: boolean): void;

  /**
   * 清空所有标记
   */
  clearMarkers(): void;

  /**
   * 添加标记
   * @param poi 厕所POI或坐标
   * @param title 标题
   * @param snippet 描述
   * @param markerType 标记类型，用于选择不同的图标
   * @returns 标记ID
   */
  addMarker(poi: ToiletPoi | LatLng, title?: string, snippet?: string, markerType?: 'toilet' | 'user_location'): string;

  /**
   * 批量添加标记
   * @param pois 厕所POI列表
   * @returns 标记ID列表
   */
  addMarkers(pois: ToiletPoi[]): string[];

  /**
   * 移除指定标记
   * @param markerId 标记ID
   */
  removeMarker(markerId: string): void;

  /**
   * 高亮指定标记
   * @param markerId 标记ID
   */
  highlightMarker(markerId: string): void;

  /**
   * 取消所有标记高亮
   */
  clearHighlight(): void;

  /**
   * 设置地图点击监听器
   * @param listener 点击事件监听器
   */
  setOnMapClickListener(listener: (position: LatLng) => void): void;

  /**
   * 设置标记点击监听器
   * @param listener 标记点击事件监听器
   */
  setOnMarkerClickListener(listener: (markerId: string, position: LatLng) => void): void;

  /**
   * 获取当前相机位置
   * @returns 当前相机位置
   */
  getCameraPosition(): CameraPosition;

  /**
   * 设置地图样式
   * @param style 地图样式
   */
  setMapStyle(style: string): void;

  /**
   * 销毁地图资源
   */
  destroy(): void;
}