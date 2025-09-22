/**
 * Haversine距离计算工具
 * 用于计算两个经纬度坐标之间的距离
 */

import { LatLng } from '../types';

/**
 * 地球半径（千米）
 */
const EARTH_RADIUS_KM = 6371;

/**
 * 将角度转换为弧度
 * @param degrees 角度
 * @returns 弧度
 */
function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

/**
 * 使用Haversine公式计算两点间距离
 * @param point1 起点坐标
 * @param point2 终点坐标
 * @returns 距离（米）
 */
export function calculateDistance(point1: LatLng, point2: LatLng): number {
  const lat1Rad = toRadians(point1.lat);
  const lat2Rad = toRadians(point2.lat);
  const deltaLatRad = toRadians(point2.lat - point1.lat);
  const deltaLngRad = toRadians(point2.lng - point1.lng);

  const a = Math.sin(deltaLatRad / 2) * Math.sin(deltaLatRad / 2) +
    Math.cos(lat1Rad) * Math.cos(lat2Rad) *
    Math.sin(deltaLngRad / 2) * Math.sin(deltaLngRad / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distanceKm = EARTH_RADIUS_KM * c;

  // 转换为米并四舍五入
  return Math.round(distanceKm * 1000);
}

/**
 * 判断点是否在指定半径范围内
 * @param center 中心点
 * @param point 目标点
 * @param radiusM 半径（米）
 * @returns 是否在范围内
 */
export function isWithinRadius(center: LatLng, point: LatLng, radiusM: number): boolean {
  const distance = calculateDistance(center, point);
  return distance <= radiusM;
}

/**
 * 格式化距离显示
 * @param distanceM 距离（米）
 * @returns 格式化的距离字符串
 */
export function formatDistance(distanceM: number): string {
  if (distanceM < 1000) {
    return `${distanceM}m`;
  } else {
    const km = (distanceM / 1000).toFixed(1);
    return `${km}km`;
  }
}

/**
 * 按距离对POI列表进行排序
 * @param pois POI列表
 * @param center 中心点
 * @returns 按距离排序的POI列表
 */
export function sortByDistance<T extends LatLng>(pois: T[], center: LatLng): T[] {
  return pois
    .map(poi => ({
      ...poi,
      distance: calculateDistance(center, poi)
    }))
    .sort((a, b) => a.distance - b.distance);
}