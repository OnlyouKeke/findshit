# 高德地图API配置指南

## 概述

本应用集成了高德地图路线规划API，用于在"找屎"功能中验证路线可达性和时间估算。当用户点击"找屎"按钮时，系统会：

1. 获取用户当前位置
2. 将当前位置置于地图中心
3. 搜索附近厕所
4. 使用高德地图API规划路线，筛选在指定时间内可达的厕所
5. 导航到最近的可达厕所

## API Key配置

### 1. 获取高德地图API Key

1. 访问[高德开放平台](https://lbs.amap.com/)
2. 注册并登录账号
3. 进入控制台，创建新应用
4. 选择"Web服务API"类型
5. 获取API Key

### 2. 配置API Key

在 `entry/src/main/ets/common/routeService.ts` 文件中：

```typescript
export class RouteService {
  private static instance: RouteService;
  private readonly baseUrl = 'https://restapi.amap.com/v3';
  private readonly apiKey = 'YOUR_ACTUAL_API_KEY_HERE'; // 替换为实际的API Key
  // ...
}
```

### 3. API权限配置

确保在高德开放平台控制台中为您的API Key开启以下服务：

- ✅ 步行路径规划
- ✅ 骑行路径规划
- ✅ Web服务API

## 功能说明

### 路线规划流程

1. **API可用时**：
   - 调用高德地图步行/骑行路线规划API
   - 获取精确的距离和时间信息
   - 验证路线是否在用户设定的时间限制内

2. **API不可用时**（回退方案）：
   - 使用直线距离计算
   - 根据出行方式估算时间：
     - 步行：5 km/h (1.39 m/s)
     - 骑行：15 km/h (4.17 m/s)

### 支持的出行方式

- 🚶 **步行**：调用 `/direction/walking` API
- 🚴 **骑行**：调用 `/direction/bicycling` API

### 时间筛选逻辑

用户可以选择时间限制（2分钟、5分钟、10分钟），系统会：

1. 搜索附近所有厕所
2. 为每个厕所规划路线
3. 筛选出在时间限制内可达的厕所
4. 选择距离最近的厕所进行导航

## API调用示例

### 步行路线规划

```
GET https://restapi.amap.com/v3/direction/walking
?key=YOUR_API_KEY
&origin=116.481028,39.989643
&destination=116.465302,39.999611
&extensions=all
&output=json
```

### 骑行路线规划

```
GET https://restapi.amap.com/v3/direction/bicycling
?key=YOUR_API_KEY
&origin=116.481028,39.989643
&destination=116.465302,39.999611
&extensions=all
&output=json
```

## 错误处理

系统具备完善的错误处理机制：

1. **API Key未配置**：自动使用估算模式
2. **网络请求失败**：回退到估算模式
3. **API返回错误**：回退到估算模式
4. **超时**：回退到估算模式

## 测试建议

### 1. 无API Key测试

- 保持API Key为空
- 验证估算模式是否正常工作
- 检查控制台警告信息

### 2. 有API Key测试

- 配置有效的API Key
- 测试步行和骑行路线规划
- 验证时间筛选功能
- 检查路线详细信息

### 3. 网络异常测试

- 断开网络连接
- 验证回退机制是否正常
- 确保应用不会崩溃

## 注意事项

1. **配额限制**：高德地图API有日调用量限制，请根据实际需求选择合适的套餐
2. **安全性**：在生产环境中，建议将API Key存储在安全的配置文件中
3. **缓存**：考虑对路线规划结果进行适当缓存，减少API调用次数
4. **用户体验**：即使API不可用，应用仍能正常工作，只是精度略有降低

## 相关文件

- `common/routeService.ts` - 路线规划服务实现
- `common/navigation.ts` - 导航功能集成
- `pages/Index.ets` - 主页面，包含"找屎"功能
- `components/ToiletCard.ets` - 厕所卡片组件

## 参考链接

- [高德地图步行路径规划API](https://amap.apifox.cn/api-14580622)
- [高德地图骑行路径规划API](https://amap.apifox.cn/api-14604169)
- [高德开放平台文档](https://lbs.amap.com/api/webservice/guide/api/direction)