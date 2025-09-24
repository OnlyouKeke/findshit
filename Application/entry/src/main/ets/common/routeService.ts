/**
 * 路线规划服务
 * 集成高德地图API，提供步行和骑行路线规划功能
 */

import { http } from '@kit.NetworkKit';
import { LatLng, TravelMode } from './types';

/**
 * 路线规划请求参数
 */
export interface RouteRequest {
  origin: LatLng;        // 起点坐标
  destination: LatLng;   // 终点坐标
  travelMode: TravelMode; // 出行方式
  timeLimit?: number;    // 时间限制（分钟）
}

/**
 * 路线步骤信息
 */
export interface RouteStep {
  instruction: string;    // 导航指令
  orientation: string;    // 方向
  roadName: string;      // 道路名称
  stepDistance: number;  // 步骤距离（米）
  duration: number;      // 步骤耗时（秒）
}

/**
 * 路线规划结果
 */
export interface RouteResult {
  distance: number;      // 总距离（米）
  duration: number;      // 总耗时（秒）
  steps: RouteStep[];    // 路线步骤
  polyline?: string;     // 路线轨迹
}

/**
 * 路线规划服务类
 */
export class RouteService {
  private static instance: RouteService;
  private readonly baseUrl = 'https://restapi.amap.com/v3';
  private readonly apiKey = ''; // TODO: 需要配置高德地图API Key
  
  private constructor() {
    if (!this.apiKey) {
      console.warn('RouteService: Amap API key not configured, route planning will be disabled');
    }
  }

  static getInstance(): RouteService {
    if (!RouteService.instance) {
      RouteService.instance = new RouteService();
    }
    return RouteService.instance;
  }

  /**
   * 规划路线
   * @param request 路线规划请求
   * @returns Promise<RouteResult> 路线规划结果
   */
  async planRoute(request: RouteRequest): Promise<RouteResult> {
    if (!this.apiKey) {
      // 如果没有配置API Key，返回估算结果
      return this.getEstimatedRoute(request);
    }
    
    try {
      console.info('RouteService: planning route with Amap API', request);
      
      const endpoint = this.getEndpoint(request.travelMode);
      const params = this.buildParams(request);
      
      const response = await this.makeRequest(endpoint, params);
      const result = this.parseResponse(response, request.travelMode);
      
      console.info('RouteService: route planned successfully', result);
      return result;
    } catch (error) {
      console.error('RouteService: route planning failed, falling back to estimation', error);
      // 如果API调用失败，回退到估算
      return this.getEstimatedRoute(request);
    }
  }

  /**
   * 检查路线是否在时间限制内
   * @param route 路线结果
   * @param timeLimit 时间限制（分钟）
   * @returns boolean 是否在时间限制内
   */
  isWithinTimeLimit(route: RouteResult, timeLimit: number): boolean {
    const routeTimeMinutes = route.duration / 60;
    return routeTimeMinutes <= timeLimit;
  }

  /**
   * 格式化路线信息
   * @param route 路线结果
   * @returns string 格式化的路线信息
   */
  formatRouteInfo(route: RouteResult): string {
    const distanceKm = (route.distance / 1000).toFixed(1);
    const durationMin = Math.ceil(route.duration / 60);
    return `距离: ${distanceKm}km, 预计: ${durationMin}分钟`;
  }

  /**
   * 获取API端点
   */
  private getEndpoint(travelMode: TravelMode): string {
    switch (travelMode) {
      case TravelMode.WALKING:
        return '/direction/walking'; // 步行路线规划
      case TravelMode.CYCLING:
        return '/direction/bicycling'; // 骑行路线规划
      default:
        return '/direction/walking';
    }
  }

  /**
   * 构建请求参数
   */
  private buildParams(request: RouteRequest): Record<string, string> {
    return {
      key: this.apiKey,
      origin: `${request.origin.lng},${request.origin.lat}`,
      destination: `${request.destination.lng},${request.destination.lat}`,
      extensions: 'all', // 返回详细信息
      output: 'json'
    };
  }

  /**
   * 发起HTTP请求
   */
  private async makeRequest(endpoint: string, params: Record<string, string>): Promise<any> {
    const url = this.baseUrl + endpoint;
    const queryString = Object.entries(params)
      .map(([key, value]) => `${key}=${encodeURIComponent(value)}`)
      .join('&');
    
    const fullUrl = `${url}?${queryString}`;
    
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        readTimeout: 10000,
        connectTimeout: 10000
      });
      
      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}: ${response.result}`);
      }
      
      return JSON.parse(response.result as string);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 解析API响应
   */
  private parseResponse(response: any, travelMode: TravelMode): RouteResult {
    if (response.status !== '1') {
      throw new Error(`API错误: ${response.info}`);
    }
    
    const route = response.route;
    if (!route || !route.paths || route.paths.length === 0) {
      throw new Error('未找到可用路线');
    }
    
    const path = route.paths[0];
    const steps: RouteStep[] = [];
    
    if (path.steps && Array.isArray(path.steps)) {
      for (const step of path.steps) {
        steps.push({
          instruction: step.instruction || '',
          orientation: step.orientation || '',
          roadName: step.road_name || '',
          stepDistance: parseInt(step.step_distance) || 0,
          duration: step.cost?.duration || 0
        });
      }
    }
    
    return {
      distance: parseInt(path.distance) || 0,
      duration: path.cost?.duration || 0,
      steps,
      polyline: path.polyline
    };
  }
}

/**
   * 获取估算路线（当API不可用时的回退方案）
   */
  private getEstimatedRoute(request: RouteRequest): RouteResult {
    const distance = this.calculateDistance(request.origin, request.destination);
    let duration: number;
    
    // 根据出行方式估算时间
    if (request.travelMode === TravelMode.WALKING) {
      // 步行速度约 5 km/h = 1.39 m/s
      duration = distance / 1.39;
    } else {
      // 骑行速度约 15 km/h = 4.17 m/s
      duration = distance / 4.17;
    }
    
    return {
      distance: Math.round(distance),
      duration: Math.round(duration),
      steps: [{
        instruction: `${request.travelMode === TravelMode.WALKING ? '步行' : '骑行'}前往目的地`,
        orientation: '',
        roadName: '',
        stepDistance: Math.round(distance),
        duration: Math.round(duration)
      }]
    };
  }
  
  /**
   * 计算两点间直线距离（米）
   */
  private calculateDistance(pos1: LatLng, pos2: LatLng): number {
    const R = 6371000; // 地球半径（米）
    const lat1Rad = pos1.lat * Math.PI / 180;
    const lat2Rad = pos2.lat * Math.PI / 180;
    const deltaLatRad = (pos2.lat - pos1.lat) * Math.PI / 180;
    const deltaLngRad = (pos2.lng - pos1.lng) * Math.PI / 180;

    const a = Math.sin(deltaLatRad / 2) * Math.sin(deltaLatRad / 2) +
              Math.cos(lat1Rad) * Math.cos(lat2Rad) *
              Math.sin(deltaLngRad / 2) * Math.sin(deltaLngRad / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }
}

/**
 * 导出单例实例
 */
export const routeService = RouteService.getInstance();