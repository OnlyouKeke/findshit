/**
 * 基于 ArkTS Map Kit 的地图适配器实现
 * 实现 MapAdapter 接口，提供具体的地图操作功能
 */

import { MapAdapter, CameraPosition } from './mapAdapter';
import { LatLng, ToiletPoi } from './types';
import { DEFAULT_ZOOM_LEVEL, CAMERA_ANIMATION_DURATION } from './config';
import { formatDistance } from './utils/haversine';
import { map, mapCommon } from '@kit.MapKit';

export class MapKitAdapter implements MapAdapter {
  private mapController: any | undefined;
  private markers: Map<string, any> = new Map();
  private highlightedMarkerId: string | null = null;
  private markerIdCounter = 0;
  private pendingMapClickListener?: (position: LatLng) => void;
  private pendingMarkerClickListener?: (markerId: string, position: LatLng) => void;
  private pendingCameraPosition?: CameraPosition;
  private pendingAnimated: boolean = true;

  constructor() {}

  /** 初始化地图（若需要） */
  initIfNeeded(anchor?: unknown): void {
    if (this.mapController) {
      return;
    }
    console.log('MapKitAdapter: initIfNeeded called');
  }

  /** 绑定 MapController（由 UI 构建后调用） */
  attachController(controller: any): void {
    this.mapController = controller;
    try {
      if (this.mapController?.setMyLocationEnabled) {
        this.mapController.setMyLocationEnabled(false);
      }
      if (this.pendingMapClickListener) {
        this.setOnMapClickListener(this.pendingMapClickListener);
      }
      if (this.pendingMarkerClickListener) {
        this.setOnMarkerClickListener(this.pendingMarkerClickListener);
      }
      
      // 如果有待处理的相机位置，现在执行
      if (this.pendingCameraPosition) {
        console.info('MapKitAdapter: executing pending camera position');
        const position = this.pendingCameraPosition;
        const animated = this.pendingAnimated;
        this.pendingCameraPosition = undefined;
        
        // 延迟执行确保地图完全初始化
        setTimeout(() => {
          this.setCameraPosition(position, animated);
        }, 200);
      }
      
      console.log('MapKitAdapter: controller attached');
    } catch (error) {
      console.error('MapKitAdapter: attachController failed', error);
    }
  }

  /** 移动相机到指定位置信息 - 优化动画效果 */
  moveCamera(target: LatLng, zoom?: number, animated: boolean = true): void {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready, saving camera position for later');
      // 保存相机位置，等地图准备好后再移动
      this.pendingCameraPosition = {
        target,
        zoom: zoom || DEFAULT_ZOOM_LEVEL,
        bearing: 0,
        tilt: 0
      };
      this.pendingAnimated = animated;
      return;
    }
    try {
      const cameraPosition: CameraPosition = {
        target,
        zoom: zoom || DEFAULT_ZOOM_LEVEL,
        // 添加相机角度和倾斜
        bearing: 0, // 方位角
        tilt: 0 // 倾斜角
      };
      
      console.info('MapKitAdapter: moving camera to', target, 'zoom:', zoom, 'animated:', animated);
      
      if (animated) {
        // 使用平滑动画移动相机
        const animationOptions = {
          duration: CAMERA_ANIMATION_DURATION, // 使用配置的动画时长
          curve: 'ease-in-out' // 缓动曲线
        };
        this.setCameraPosition(cameraPosition, true, animationOptions);
      } else {
        this.setCameraPosition(cameraPosition, false);
      }
    } catch (error) {
      console.error('MapKitAdapter: moveCamera error', error);
    }
  }

  /** 设置相机位置 - 使用HarmonyOS MapKit官方API */
  setCameraPosition(position: CameraPosition, animated: boolean = true, animationOptions?: any): void {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready');
      return;
    }
    try {
      const target = position.target;
      const zoom = position.zoom || DEFAULT_ZOOM_LEVEL;
      
      console.log('MapKitAdapter: attempting to set camera position:', target, 'zoom:', zoom);
      
      // 使用HarmonyOS MapKit官方API - map.newLatLng方法
       // 根据官方文档，需要使用map.newLatLng来创建相机位置
       try {
         if (map && typeof map.newLatLng === 'function') {
           // 使用官方推荐的map.newLatLng方法
           const latLng: mapCommon.LatLng = {
             latitude: target.lat,
             longitude: target.lng
           };
           
           if (animated) {
             // 使用animateCamera进行动画移动
             this.mapController.animateCamera(map.newLatLng(latLng, zoom));
             console.log('MapKitAdapter: used animateCamera with map.newLatLng (animated)');
           } else {
             // 对于非动画移动，也使用animateCamera但可能需要设置duration为0
             // 或者尝试直接设置相机位置
             this.mapController.animateCamera(map.newLatLng(latLng, zoom));
             console.log('MapKitAdapter: used animateCamera with map.newLatLng (instant)');
           }
         } else {
           console.warn('MapKitAdapter: map.newLatLng not available, trying alternative methods');
           this.fallbackCameraPosition(target, zoom, animated);
         }
       } catch (error) {
         console.warn('MapKitAdapter: error using map.newLatLng, using fallback:', error);
         this.fallbackCameraPosition(target, zoom, animated);
       }
      
      console.log(`MapKitAdapter: camera moved to ${target.lat}, ${target.lng} (zoom: ${zoom}, animated: ${animated})`);
    } catch (error) {
      console.error('MapKitAdapter: setCameraPosition error', error);
      console.error('MapKitAdapter: available methods:', Object.getOwnPropertyNames(this.mapController));
    }
  }
  
  /** 备用相机位置设置方法 */
  private fallbackCameraPosition(target: LatLng, zoom: number, animated: boolean): void {
    const latLng = {
      latitude: target.lat,
      longitude: target.lng
    };
    
    const cameraPosition = {
      target: latLng,
      zoom: zoom
    };
    
    // 尝试不同的API调用方式
    if (typeof this.mapController?.animateCamera === 'function') {
      this.mapController.animateCamera(cameraPosition);
      console.log('MapKitAdapter: used fallback animateCamera');
    } else if (typeof this.mapController?.setCameraPosition === 'function') {
      this.mapController.setCameraPosition(cameraPosition);
      console.log('MapKitAdapter: used fallback setCameraPosition');
    } else if (typeof this.mapController?.moveCamera === 'function') {
      this.mapController.moveCamera(cameraPosition);
      console.log('MapKitAdapter: used fallback moveCamera');
    } else {
      console.error('MapKitAdapter: no camera control methods available');
    }
  }

  /** 启用/禁用我的位置显示 */
  setMyLocationEnabled(enabled: boolean): void {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready');
      return;
    }
    try {
      if (typeof this.mapController.setMyLocationEnabled === 'function') {
        this.mapController.setMyLocationEnabled(enabled);
      }
      console.log(`MapKitAdapter: myLocation ${enabled ? 'enabled' : 'disabled'}`);
    } catch (error) {
      console.error('MapKitAdapter: setMyLocationEnabled error', error);
    }
  }

  /** 清空所有标记 */
  clearMarkers(): void {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready');
      return;
    }
    try {
      if (typeof this.mapController.clear === 'function') {
        this.mapController.clear();
      } else if (typeof this.mapController.removeMarker === 'function') {
        this.markers.forEach(marker => {
          try { this.mapController.removeMarker(marker); } catch {}
        });
      }
      this.markers.clear();
      this.highlightedMarkerId = null;
      console.log('MapKitAdapter: markers cleared');
    } catch (error) {
      console.error('MapKitAdapter: clearMarkers error', error);
    }
  }

  /** 添加单个标记 - 优化标记样式和动画 */
  addMarker(poi: ToiletPoi | LatLng, title?: string, snippet?: string): string {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready');
      return '';
    }
    try {
      const markerId = `marker_${++this.markerIdCounter}`;
      const markerTitle = title || ('name' in (poi as any) ? (poi as any).name : '厕所');
      const markerSnippet = snippet || this.buildSnippet(poi);
      
      if (typeof this.mapController.addMarker === 'function') {
        const markerOptions: any = {
          position: { latitude: poi.lat, longitude: poi.lng },
          title: markerTitle,
          snippet: markerSnippet,
          icon: this.getToiletIcon(),
          // 优化标记显示效果
          anchor: { x: 0.5, y: 1.0 }, // 锚点设置为底部中心
          zIndex: 1, // 设置层级
          alpha: 1.0, // 透明度
          flat: false, // 3D效果
          rotation: 0, // 旋转角度
          visible: true, // 可见性
          draggable: false, // 不可拖拽
          // 添加动画效果
          animation: {
            type: 'drop', // 掉落动画
            duration: 300 // 动画时长300ms
          }
        };
        
        const marker = this.mapController.addMarker(markerOptions);
        this.markers.set(markerId, marker);
        
        // 添加标记点击动画
        if (marker && typeof marker.setAnimation === 'function') {
          marker.setAnimation('bounce');
        }
      } else {
        this.markers.set(markerId, { poi, title: markerTitle, snippet: markerSnippet });
      }
      
      console.log(`MapKitAdapter: addMarker ${markerId} - ${markerTitle}`);
      return markerId;
    } catch (error) {
      console.error('MapKitAdapter: addMarker error', error);
      return '';
    }
  }

  /** 批量添加标记 */
  addMarkers(pois: ToiletPoi[]): string[] {
    const markerIds: string[] = [];
    pois.forEach(poi => {
      const id = this.addMarker(poi);
      if (id) markerIds.push(id);
    });
    return markerIds;
  }

  /** 移除指定标记 */
  removeMarker(markerId: string): void {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready');
      return;
    }
    const marker = this.markers.get(markerId);
    if (!marker) {
      console.warn(`MapKitAdapter: marker ${markerId} not exist`);
      return;
    }
    try {
      if (typeof this.mapController.removeMarker === 'function') {
        this.mapController.removeMarker(marker);
      }
      this.markers.delete(markerId);
      if (this.highlightedMarkerId === markerId) this.highlightedMarkerId = null;
      console.log(`MapKitAdapter: removeMarker ${markerId}`);
    } catch (error) {
      console.error('MapKitAdapter: removeMarker error', error);
    }
  }

  /** 高亮指定标记 */
  highlightMarker(markerId: string): void {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready');
      return;
    }
    this.clearHighlight();
    const marker = this.markers.get(markerId);
    if (!marker) {
      console.warn(`MapKitAdapter: marker ${markerId} not exist`);
      return;
    }
    try {
      // 可根据 SDK 能力设置不同图标/动画
      this.highlightedMarkerId = markerId;
      console.log(`MapKitAdapter: highlight ${markerId}`);
    } catch (error) {
      console.error('MapKitAdapter: highlightMarker error', error);
    }
  }

  /** 取消所有标记高亮 */
  clearHighlight(): void {
    if (!this.highlightedMarkerId) return;
    try {
      // 恢复图标等
      console.log(`MapKitAdapter: clearHighlight ${this.highlightedMarkerId}`);
    } catch (error) {
      console.error('MapKitAdapter: clearHighlight error', error);
    }
    this.highlightedMarkerId = null;
  }

  /** 设置地图点击监听器 */
  setOnMapClickListener(listener: (position: LatLng) => void): void {
    this.pendingMapClickListener = listener;
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready, listener saved');
      return;
    }
    try {
      if (typeof this.mapController.on === 'function') {
        this.mapController.on('mapClick', (e: any) => {
          const lat = e?.latitude ?? e?.lat ?? e?.latLng?.latitude ?? e?.latLng?.lat;
          const lng = e?.longitude ?? e?.lng ?? e?.latLng?.longitude ?? e?.latLng?.lng;
          if (lat != null && lng != null) listener({ lat, lng });
        });
      } else if (typeof this.mapController.setOnMapClickListener === 'function') {
        this.mapController.setOnMapClickListener((p: any) => {
          const lat = p?.latitude ?? p?.lat;
          const lng = p?.longitude ?? p?.lng;
          listener({ lat, lng });
        });
      }
      console.log('MapKitAdapter: map click listener set');
    } catch (error) {
      console.error('MapKitAdapter: setOnMapClickListener error', error);
    }
  }

  /** 设置标记点击监听器 */
  setOnMarkerClickListener(listener: (markerId: string, position: LatLng) => void): void {
    this.pendingMarkerClickListener = listener;
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready, listener saved');
      return;
    }
    try {
      if (typeof this.mapController.on === 'function') {
        this.mapController.on('markerClick', (marker: any) => {
          const markerId = this.getMarkerIdByMarker(marker) || `${marker?.id ?? ''}`;
          const pos = marker?.position ?? marker?.latLng;
          const lat = pos?.latitude ?? pos?.lat;
          const lng = pos?.longitude ?? pos?.lng;
          if (lat != null && lng != null) listener(markerId, { lat, lng });
        });
      } else if (typeof this.mapController.setOnMarkerClickListener === 'function') {
        this.mapController.setOnMarkerClickListener((m: any) => {
          const markerId = this.getMarkerIdByMarker(m) || `${m?.id ?? ''}`;
          const pos = m?.position ?? m?.latLng;
          listener(markerId, { lat: pos?.latitude ?? pos?.lat, lng: pos?.longitude ?? pos?.lng });
        });
      }
      console.log('MapKitAdapter: marker click listener set');
    } catch (error) {
      console.error('MapKitAdapter: setOnMarkerClickListener error', error);
    }
  }

  /** 获取当前相机位置 */
  getCameraPosition(): CameraPosition {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready');
      return {
        target: { lat: 0, lng: 0 },
        zoom: DEFAULT_ZOOM_LEVEL
      };
    }
    try {
      // 若 SDK 支持，优先从控制器读取
      const cp: any = typeof (this.mapController as any).getCameraPosition === 'function'
        ? (this.mapController as any).getCameraPosition()
        : undefined;
      if (cp) {
        const lat = cp?.target?.latitude ?? cp?.target?.lat ?? cp?.latitude ?? cp?.lat;
        const lng = cp?.target?.longitude ?? cp?.target?.lng ?? cp?.longitude ?? cp?.lng;
        return { target: { lat, lng }, zoom: cp?.zoom ?? DEFAULT_ZOOM_LEVEL };
      }
      // 退化返回默认
      return { target: { lat: 31.2304, lng: 121.4737 }, zoom: DEFAULT_ZOOM_LEVEL };
    } catch (error) {
      console.error('MapKitAdapter: getCameraPosition error', error);
      return { target: { lat: 0, lng: 0 }, zoom: DEFAULT_ZOOM_LEVEL };
    }
  }

  /** 设置地图样式 */
  setMapStyle(style: string): void {
    if (!this.mapController) {
      console.warn('MapKitAdapter: map not ready');
      return;
    }
    try {
      if (typeof this.mapController.setMapStyle === 'function') {
        this.mapController.setMapStyle(style);
      }
      console.log(`MapKitAdapter: set style ${style}`);
    } catch (error) {
      console.error('MapKitAdapter: setMapStyle error', error);
    }
  }

  /** 销毁资源 */
  destroy(): void {
    try {
      this.clearMarkers();
      if (this.mapController && typeof this.mapController.destroy === 'function') {
        try { this.mapController.destroy(); } catch {}
      }
      this.mapController = undefined;
      console.log('MapKitAdapter: destroyed');
    } catch (error) {
      console.error('MapKitAdapter: destroy error', error);
    }
  }

  /** 构建标记描述信息 */
  private buildSnippet(poi: ToiletPoi | LatLng): string {
    if ((poi as any).name) {
      const parts: string[] = [];
      if ((poi as any).distance !== undefined) parts.push(`距离: ${formatDistance((poi as any).distance)}`);
      if ((poi as any).openHours) parts.push(`营业时间: ${(poi as any).openHours}`);
      return parts.join(' | ');
    }
    return '厕所位置';
  }

  private getToiletIcon(): string {
    return 'toilet_icon';
  }

  private getHighlightToiletIcon(): string {
    return 'toilet_icon_highlight';
  }

  private getMarkerIdByMarker(marker: any): string {
    for (const [id, m] of this.markers.entries()) {
      if (m === marker) return id;
    }
    return '';
  }
}

