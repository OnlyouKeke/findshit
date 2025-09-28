/**
 * 基于百度地图SDK的地图适配器实现
 * 实现 MapAdapter 接口，提供具体的地图操作功能
 */

import { MapAdapter, CameraPosition } from './mapAdapter';
import { LatLng, ToiletPoi } from './types';
import { DEFAULT_ZOOM_LEVEL, CAMERA_ANIMATION_DURATION } from './config';
import { formatDistance } from './utils/haversine';

/**
 * 百度地图适配器实现
 */
export class BaiduMapAdapter implements MapAdapter {
  private mapController?: any; // 百度地图控制器
  private markers: Map<string, any> = new Map(); // 标记管理
  private onMapClickCallback?: (position: LatLng) => void;
  private onMarkerClickCallback?: (markerId: string, position: LatLng) => void;
  private onCameraMoveCallback?: (position: CameraPosition) => void;

  /**
   * 初始化地图（如果需要）
   * @param anchor 地图容器锚点
   */
  initIfNeeded(anchor?: unknown): void {
    // 百度地图不需要额外初始化
    console.info('BaiduMapAdapter: initIfNeeded called, no action needed');
  }

  /**
   * 初始化地图
   * @param mapController 百度地图控制器
   */
  initialize(mapController: any): void {
    this.mapController = mapController;
    console.info('BaiduMapAdapter: initialized with controller');
  }

  /**
   * 移动相机到指定位置
   * @param target 目标坐标
   * @param zoom 缩放级别（可选）
   * @param animated 是否使用动画（默认true）
   */
  moveCamera(target: LatLng, zoom?: number, animated?: boolean): void {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return;
    }

    try {
      const targetZoom = zoom ?? DEFAULT_ZOOM_LEVEL;
      const useAnimation = animated !== false; // 默认使用动画
      console.info('BaiduMapAdapter: moving camera to', { target, zoom: targetZoom, animated: useAnimation });

      // 百度地图移动相机的API调用
      const mapStatus = {
        target: {
          latitude: target.lat,
          longitude: target.lng
        },
        zoom: targetZoom
      };

      if (useAnimation) {
        this.mapController.animateMapStatus(mapStatus, CAMERA_ANIMATION_DURATION);
      } else {
        this.mapController.setMapStatus(mapStatus);
      }
    } catch (error) {
      console.error('BaiduMapAdapter: moveCamera failed', error);
    }
  }

  /**
   * 设置相机位置
   * @param position 相机位置信息
   * @param animated 是否使用动画（默认true）
   */
  setCameraPosition(position: CameraPosition, animated?: boolean): void {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return;
    }

    try {
      const useAnimation = animated !== false; // 默认使用动画
      console.info('BaiduMapAdapter: setting camera position', { position, animated: useAnimation });

      const mapStatus = {
        target: {
          latitude: position.target.lat,
          longitude: position.target.lng
        },
        zoom: position.zoom ?? DEFAULT_ZOOM_LEVEL,
        bearing: position.bearing ?? 0,
        tilt: position.tilt ?? 0
      };

      if (useAnimation) {
        this.mapController.animateMapStatus(mapStatus, CAMERA_ANIMATION_DURATION);
      } else {
        this.mapController.setMapStatus(mapStatus);
      }
    } catch (error) {
      console.error('BaiduMapAdapter: setCameraPosition failed', error);
    }
  }

  /**
   * 添加标记
   * @param poi 厕所POI或坐标
   * @param title 标题
   * @param snippet 描述
   * @param markerType 标记类型，用于选择不同的图标
   * @returns 标记ID
   */
  addMarker(poi: ToiletPoi | LatLng, title?: string, snippet?: string, markerType?: 'toilet' | 'user_location'): string {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return '';
    }

    try {
      const markerId = `marker_${Date.now()}_${Math.random()}`;
      const position = poi as LatLng;
      console.info('BaiduMapAdapter: adding marker', { markerId, position, title, markerType });

      // 百度地图添加标记的API调用
      const markerOptions = {
        position: {
          latitude: position.lat,
          longitude: position.lng
        },
        title: title || '',
        snippet: snippet || '',
        icon: this.getMarkerIcon(markerType),
        zIndex: this.getMarkerZIndex(markerType),
        animation: markerType === 'user_location' ? 'DROP' : 'NONE'
      };

      const marker = this.mapController.addMarker(markerOptions);
      this.markers.set(markerId, marker);

      return markerId;
    } catch (error) {
      console.error('BaiduMapAdapter: addMarker failed', error);
      return '';
    }
  }

  /**
   * 批量添加标记
   * @param pois 厕所POI列表
   * @returns 标记ID列表
   */
  addMarkers(pois: ToiletPoi[]): string[] {
    const markerIds: string[] = [];
    for (const poi of pois) {
      const markerId = this.addMarker(poi, poi.name, `距离: ${formatDistance(poi.distance || 0)}`, 'toilet');
      if (markerId) {
        markerIds.push(markerId);
      }
    }
    return markerIds;
  }

  /**
   * 移除标记
   * @param markerId 标记ID
   */
  removeMarker(markerId: string): void {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return;
    }

    try {
      const marker = this.markers.get(markerId);
      if (marker) {
        this.mapController.removeMarker(marker);
        this.markers.delete(markerId);
        console.info('BaiduMapAdapter: marker removed', markerId);
      }
    } catch (error) {
      console.error('BaiduMapAdapter: removeMarker failed', error);
    }
  }

  /**
   * 清除所有标记
   */
  clearMarkers(): void {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return;
    }

    try {
      this.markers.forEach((marker, markerId) => {
        this.mapController.removeMarker(marker);
      });
      this.markers.clear();
      console.info('BaiduMapAdapter: all markers cleared');
    } catch (error) {
      console.error('BaiduMapAdapter: clearMarkers failed', error);
    }
  }

  /**
   * 启用我的位置显示
   * @param enabled 是否启用
   */
  setMyLocationEnabled(enabled: boolean): void {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return;
    }

    try {
      this.mapController.setMyLocationEnabled(enabled);
      console.info('BaiduMapAdapter: my location enabled', enabled);
    } catch (error) {
      console.error('BaiduMapAdapter: setMyLocationEnabled failed', error);
    }
  }

  /**
   * 设置地图点击监听器
   * @param callback 点击回调
   */
  setOnMapClickListener(callback: (position: LatLng) => void): void {
    this.onMapClickCallback = callback;
    if (this.mapController) {
      this.mapController.setOnMapClickListener((event: any) => {
        const position: LatLng = new LatLng(event.target.latitude, event.target.longitude);
        callback(position);
      });
    }
  }

  /**
   * 设置标记点击监听器
   * @param callback 点击回调
   */
  setOnMarkerClickListener(callback: (markerId: string, position: LatLng) => void): void {
    this.onMarkerClickCallback = callback;
    if (this.mapController) {
      this.mapController.setOnMarkerClickListener((marker: any) => {
        // 查找标记ID
        let markerId = '';
        for (const [id, m] of this.markers.entries()) {
          if (m === marker) {
            markerId = id;
            break;
          }
        }
        
        const position: LatLng = new LatLng(marker.position.latitude, marker.position.longitude);
        callback(markerId, position);
      });
    }
  }

  /**
   * 高亮标记
   * @param markerId 标记ID
   */
  highlightMarker(markerId: string): void {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return;
    }

    try {
      const marker = this.markers.get(markerId);
      if (marker) {
        // 百度地图高亮标记（可以通过改变图标或动画实现）
        this.mapController.updateMarker(marker, {
          icon: this.getHighlightIcon(),
          zIndex: 999 // 提高层级
        });
        console.info('BaiduMapAdapter: marker highlighted', markerId);
      }
    } catch (error) {
      console.error('BaiduMapAdapter: highlightMarker failed', error);
    }
  }

  /**
   * 清除高亮
   */
  clearHighlight(): void {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return;
    }

    try {
      // 重置所有标记为默认状态
      this.markers.forEach((marker, markerId) => {
        this.mapController.updateMarker(marker, {
          icon: this.getToiletIcon(),
          zIndex: this.getMarkerZIndex('toilet')
        });
      });
      console.info('BaiduMapAdapter: all highlights cleared');
    } catch (error) {
      console.error('BaiduMapAdapter: clearHighlight failed', error);
    }
  }

  /**
   * 获取相机位置
   * @returns 当前相机位置
   */
  getCameraPosition(): CameraPosition {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return {
        target: new LatLng(0, 0),
        zoom: DEFAULT_ZOOM_LEVEL
      };
    }

    try {
      const status = this.mapController.getMapStatus();
      return {
        target: new LatLng(status.target.latitude, status.target.longitude),
        zoom: status.zoom,
        bearing: status.bearing || 0,
        tilt: status.tilt || 0
      };
    } catch (error) {
      console.error('BaiduMapAdapter: getCameraPosition failed', error);
      return {
        target: new LatLng(0, 0),
        zoom: DEFAULT_ZOOM_LEVEL
      };
    }
  }

  /**
   * 设置地图样式
   * @param style 样式字符串
   */
  setMapStyle(style: string): void {
    if (!this.mapController) {
      console.warn('BaiduMapAdapter: mapController not initialized');
      return;
    }

    try {
      this.mapController.setMapStyle(style);
      console.info('BaiduMapAdapter: map style set', style);
    } catch (error) {
      console.error('BaiduMapAdapter: setMapStyle failed', error);
    }
  }

  /**
   * 销毁地图
   */
  destroy(): void {
    try {
      this.clearMarkers();
      this.mapController = undefined;
      this.onMapClickCallback = undefined;
      this.onMarkerClickCallback = undefined;
      this.onCameraMoveCallback = undefined;
      console.info('BaiduMapAdapter: destroyed');
    } catch (error) {
      console.error('BaiduMapAdapter: destroy failed', error);
    }
  }

  /**
   * 获取标记图标
   * @param markerType 标记类型
   * @returns 图标资源
   */
  private getMarkerIcon(markerType?: string): string {
    switch (markerType) {
      case 'user_location':
        return this.getUserLocationIcon();
      case 'toilet':
        return this.getToiletIcon();
      default:
        return this.getDefaultIcon();
    }
  }

  /**
   * 获取用户位置图标
   * @returns 用户位置图标资源
   */
  private getUserLocationIcon(): string {
    return 'navigation_icon'; // 百度地图用户位置图标
  }

  /**
   * 获取厕所图标
   * @returns 厕所图标资源
   */
  private getToiletIcon(): string {
    return 'toilet_icon'; // 厕所图标
  }

  /**
   * 获取默认图标
   * @returns 默认图标资源
   */
  private getDefaultIcon(): string {
    return 'default_marker'; // 默认标记图标
  }

  /**
   * 获取高亮图标
   * @returns 高亮图标资源
   */
  private getHighlightIcon(): string {
    return 'highlight_marker'; // 高亮标记图标
  }

  /**
   * 获取标记层级
   * @param markerType 标记类型
   * @returns 层级值
   */
  private getMarkerZIndex(markerType?: string): number {
    switch (markerType) {
      case 'user_location':
        return 1000; // 用户位置最高层级
      case 'toilet':
        return 100;  // 厕所标记中等层级
      default:
        return 1;    // 默认最低层级
    }
  }
}