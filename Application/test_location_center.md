# 用户位置居中测试指南

## 问题描述
用户反馈自己的定位要在中央，还是有点问题。

## 已实施的修复

### 1. 地图相机移动优化
- 在地图加载完成后延迟500ms再移动相机，确保地图完全初始化
- 添加了待处理相机位置的缓存机制，当地图未准备好时先保存位置
- 改进了相机移动的日志输出，便于调试

### 2. 用户位置聚焦改进
- `focusToMyLocation()` 方法现在会清除现有标记并重新添加用户位置标记
- 添加了详细的日志输出，便于跟踪位置聚焦过程
- 改进了无位置信息时的处理逻辑

### 3. 定位权限处理优化
- 在请求权限前先检查当前权限状态，避免重复请求
- 改进了权限请求的日志输出和错误处理
- 优化了权限被拒绝时的用户提示信息

## 测试步骤

### 测试1：首次启动定位
1. 清除应用数据，首次启动应用
2. 观察权限请求对话框
3. 授予定位权限
4. 检查地图是否自动移动到用户位置并居中
5. 确认用户位置标记是否正确显示

### 测试2：手动聚焦到我的位置
1. 在地图上随意移动到其他位置
2. 点击定位按钮（蓝色圆形按钮）
3. 观察地图是否平滑移动到用户位置
4. 确认用户位置在屏幕中央
5. 检查是否显示"已聚焦到您的位置"提示

### 测试3：权限被拒绝的情况
1. 在系统设置中拒绝应用的定位权限
2. 启动应用并尝试定位
3. 观察是否显示合适的错误提示
4. 检查提示信息是否为中文

### 测试4：地图加载时序
1. 在网络较慢的环境下测试
2. 观察地图加载过程中的相机移动
3. 确认相机移动不会在地图未完全加载时执行
4. 检查延迟机制是否正常工作

## 预期结果

1. **用户位置居中**：用户位置应该准确显示在屏幕中央
2. **平滑动画**：相机移动应该有平滑的动画效果
3. **标记可见**：用户位置标记应该清晰可见
4. **权限处理**：权限请求和错误处理应该用户友好
5. **时序正确**：相机移动应该在地图完全加载后执行

## 关键代码修改

### Index.ets
```typescript
// 地图加载完成后延迟移动相机
setTimeout(() => {
  this.mapAdapter.moveCamera(this.myLocation!, DEFAULT_ZOOM, true);
  console.info('Index: camera moved to user location after map load');
}, 500);

// 改进的聚焦方法
private focusToMyLocation(): void {
  if (this.myLocation) {
    console.info('Index: focusing to my location:', this.myLocation);
    this.mapAdapter.moveCamera(this.myLocation, DEFAULT_ZOOM, true);
    // 确保用户位置标记可见
    this.mapAdapter.clearMarkers();
    this.mapAdapter.addMarker(this.myLocation, '我的位置');
    this.showInfo('已聚焦到您的位置');
  }
}
```

### mapKitAdapter.ts
```typescript
// 待处理相机位置缓存
if (!this.mapController) {
  console.warn('MapKitAdapter: map not ready, saving camera position for later');
  this.pendingCameraPosition = {
    target,
    zoom: zoom || DEFAULT_ZOOM_LEVEL,
    bearing: 0,
    tilt: 0
  };
  this.pendingAnimated = animated;
  return;
}
```

## 调试信息

查看以下日志来确认修复效果：
- `Index: focusing to my location:` - 用户位置聚焦开始
- `MapKitAdapter: moving camera to` - 相机移动参数
- `Index: camera moved to user location after map load` - 地图加载后相机移动
- `MapKitAdapter: executing pending camera position` - 执行待处理的相机位置

如果仍有问题，请检查：
1. 定位权限是否正确授予
2. 地图是否完全加载
3. 网络连接是否正常
4. 设备GPS功能是否开启