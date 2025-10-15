import geoLocationManager from '@ohos.geoLocationManager';
import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HarmonyGeo } from '../common/geo';
import { MapServiceFactory } from '../map/MapServiceFactory';
import { MapService, ToiletPoi } from '../map/MapService';
import MapLauncher from '../map/MapLauncher';
import AppStorage from '../common/AppStorage';
import LocationLogStore, { LocationLog } from '../common/LocationLogStore';
import SearchLogStore, { SearchLog, SearchLogInfo } from '../common/SearchLogStore';
import { ToiletCard, NavigateHandler, NavigateHandlerImpl } from '../components/ToiletCard';
import { ErrorBanner } from '../components/ErrorBanner';

const TAG = 'Index';

@Entry
@Component
struct Index {
  @State isLoading: boolean = false;
  @State toilets: ToiletPoi[] = [];
  @State error: string = '';
  @State center: geoLocationManager.Location | null = null;
  @State private travelMode: string = 'walking'; // 出行方式：walking 或 cycling
  @State private buttonMoved: boolean = false; // 按钮是否已移动到底部
  @State private showToiletList: boolean = false; // 是否显示公厕列表
  @State private buttonPressed: boolean = false; // 按钮点击状态
  @State private buttonScale: number = 1.0; // 按钮缩放比例
  @State private breathingScale: number = 1.0; // 呼吸动画缩放比例
  @State private swipeStartX: number = 0; // 滑动开始的X坐标
  @State private swipeCurrentX: number = 0; // 滑动当前的X坐标
  @State private isSwipeActive: boolean = false; // 是否正在滑动
  @State private swipeOffset: number = 0; // 滑动偏移量
  @State private visibleCount: number = 0; // 已显示的卡片数量（用于逐个动画显示）
  @State private appearedIds: string[] = []; // 已出现的卡片ID列表，用于按项淡入
  private staggerTimerId: number | undefined = undefined; // 逐个显示的定时器ID
  private revealStartTs: number = 0; // 卡片逐显开始时间戳
  @StorageLink('searchDistance') searchDistance: number = 500; // 搜索距离，默认500米
  private geoService: HarmonyGeo | null = null;
  private mapService: MapService | null = null;
  private context: common.UIAbilityContext | null = null;

  async aboutToAppear() {
    try {
      this.context = getContext(this) as common.UIAbilityContext;
      if (this.context) {
        this.geoService = new HarmonyGeo(this.context);
        this.mapService = await MapServiceFactory.createMapService();
      }
      
      // 启动呼吸动画
      this.startBreathingAnimation();
    } catch (err) {
      const error = err as BusinessError;
      console.error(TAG, `Failed to get context, error: ${JSON.stringify(error)}`);
      this.error = `Failed to get context: ${error.message}`;
    }
  }

  aboutToDisappear() {
    // 组件退出时取消任何残留的逐显定时器，避免异步回调导致崩溃
    this.cancelStaggerReveal();
  }

  // 呼吸动画
  private startBreathingAnimation() {
    const breathingLoop = () => {
      if (!this.buttonMoved) {
        animateTo({
          duration: 2000,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        }, () => {
          this.breathingScale = 1.05;
        });
      }
    };
    breathingLoop();
  }

  // 点击动画效果
  private handleButtonPress() {
    // 点击缩放动画
    this.buttonPressed = true;
    animateTo({
      duration: 100,
      curve: Curve.Sharp
    }, () => {
      this.buttonScale = 0.95;
    });
    
    // 弹跳回弹动画
    setTimeout(() => {
      animateTo({
        duration: 200,
        curve: Curve.EaseOut
      }, () => {
        this.buttonScale = 1.1;
      });
      
      setTimeout(() => {
        animateTo({
          duration: 150,
          curve: Curve.EaseInOut
        }, () => {
          this.buttonScale = 1.0;
          this.buttonPressed = false;
        });
      }, 200);
    }, 100);
  }

  // 设置按钮点击处理
  private handleSettingsClick() {
    console.log('设置按钮被点击');
    router.pushUrl({
      url: 'pages/Settings'
    }).catch((error: Error) => {
      console.error('导航到设置页面失败:', error.message);
    });
  }

  // 滑动手势处理方法
  private handleSwipeStart(x: number) {
    this.swipeStartX = x;
    this.swipeCurrentX = x;
    this.isSwipeActive = true;
    this.swipeOffset = 0;
  }

  private handleSwipeMove(x: number) {
    if (!this.isSwipeActive) return;
    
    this.swipeCurrentX = x;
    this.swipeOffset = x - this.swipeStartX;
    
    // 添加实时视觉反馈 - 轻微的偏移效果
    const maxOffset = 30; // 最大偏移量
    const normalizedOffset = Math.max(-maxOffset, Math.min(maxOffset, this.swipeOffset * 0.3));
    
    // 可以在这里添加实时的视觉反馈，比如轻微的位移或透明度变化
  }

  private handleSwipeEnd() {
    if (!this.isSwipeActive) return;
    
    const swipeDistance = Math.abs(this.swipeOffset);
    const minSwipeDistance = 50; // 最小滑动距离
    
    if (swipeDistance > minSwipeDistance) {
      if (this.swipeOffset > 0) {
        // 向右滑动 - 切换到步行
        this.switchTravelMode('walking');
      } else {
        // 向左滑动 - 切换到骑行
        this.switchTravelMode('cycling');
      }
    }
    
    // 重置滑动状态
    this.isSwipeActive = false;
    this.swipeOffset = 0;
    this.swipeStartX = 0;
    this.swipeCurrentX = 0;
  }

  private switchTravelMode(mode: string) {
    if (this.travelMode !== mode) {
      // 添加触觉反馈（如果支持）
      // HapticFeedback.impactLight();
      
      animateTo({
        duration: 400,
        curve: Curve.EaseInOut,
        playMode: PlayMode.Normal
      }, () => {
        this.travelMode = mode;
      });
      
      // 添加切换成功的视觉提示
      setTimeout(() => {
        animateTo({
          duration: 200,
          curve: Curve.EaseOut
        }, () => {
          // 可以添加一个短暂的高亮效果
        });
      }, 100);
    }
  }

  // 导航到指定公厕（根据设置的地图App）
  private async navigateToToilet(toilet: ToiletPoi) {
    if (!this.context) {
      console.error('导航失败: 缺少UI上下文');
      return;
    }
    try {
      await MapLauncher.openNavigation(this.context, toilet, this.travelMode === 'walking' ? 'walking' : 'cycling');
    } catch (error) {
      console.error('导航失败:', error);
      this.error = '未能打开目标地图App，请检查是否已安装或重试。';
    }
  }

  // 生成显式类型的导航处理器，避免在 UI 声明块中书写对象字面量
  private makeNavigateHandler(toilet: ToiletPoi): NavigateHandler {
    return new NavigateHandlerImpl(() => {
      console.log(`导航到公厕: ${toilet.name}`);
      this.navigateToToilet(toilet);
    });
  }

  // 取消逐个显示动画
  private cancelStaggerReveal() {
    if (this.staggerTimerId !== undefined) {
      clearTimeout(this.staggerTimerId);
      this.staggerTimerId = undefined;
    }
  }

  // 调试：填充空白卡片列表
  private debugShowBlankCards(count: number = 20) {
    // 停止任何进行中的逐显逻辑
    this.cancelStaggerReveal();
    this.isLoading = false;
    // 构造空白卡片数据，满足 ToiletPoi 接口（避免使用泛型推断与未类型化对象）
    const blanks: ToiletPoi[] = [];
    for (let i = 0; i < count; i++) {
      const item: ToiletPoi = {
        id: `debug-${i}`,
        name: '',
        address: '',
        location: { longitude: 0, latitude: 0 },
        distance: 0
      };
      blanks.push(item);
    }
    this.toilets = blanks;
    this.appearedIds = [];
    this.showToiletList = true;
    // 保证列表区域可见
    this.buttonMoved = true;
  }

  // 启动逐个显示动画
  private async startStaggerReveal(total: number) {
    this.cancelStaggerReveal();
    this.visibleCount = 0;
    this.revealStartTs = Date.now();
    const target = Math.min(Math.max(total, 0), 200);
    // 写入“卡片显示开始”日志
    try {
      if (this.context) {
        await SearchLogStore.init(this.context);
        const top3 = this.toilets.slice(0, 3).map(t => `${t.name}(${t.distance}m)`).join(', ');
        const logStart: SearchLog = {
          timestamp: Date.now(),
          centerLatitude: this.center?.latitude,
          centerLongitude: this.center?.longitude,
          radiusMeters: this.searchDistance,
          resultCount: total,
          message: `展示卡片开始 | 模式:${this.travelMode} | 目标:${target} | 间隔:80ms | Top3:${top3}`
        };
        await SearchLogStore.getInstance().append(logStart);
      }
    } catch (e) {
      console.warn('写入卡片显示开始日志失败:', e);
    }
    const step = async () => {
      if (this.visibleCount < target) {
        this.visibleCount++;
        this.staggerTimerId = setTimeout(step, 80);
      } else {
        this.cancelStaggerReveal();
        // 写入“卡片显示完成”日志
        try {
          if (this.context) {
            await SearchLogStore.init(this.context);
            const duration = Date.now() - this.revealStartTs;
            const top3 = this.toilets.slice(0, 3).map(t => `${t.name}(${t.distance}m)`).join(', ');
            const logDone: SearchLog = {
              timestamp: Date.now(),
              centerLatitude: this.center?.latitude,
              centerLongitude: this.center?.longitude,
              radiusMeters: this.searchDistance,
              resultCount: target,
              message: `展示卡片完成 | 模式:${this.travelMode} | 用时:${duration}ms | 实际:${this.toilets.length} | Top3:${top3}`
            };
            await SearchLogStore.getInstance().append(logDone);
          }
        } catch (e) {
          console.warn('写入卡片显示完成日志失败:', e);
        }
      }
    };
    step();
  }

  async handleFindToilet() {
    if (this.isLoading || !this.geoService || !this.mapService) {
      return;
    }
    
    // 先执行点击动画
    this.handleButtonPress();
    
    // 延迟执行搜索，让动画先完成
    setTimeout(() => {
      // 触发按钮向下移动动画
      this.buttonMoved = true;
      
      this.performSearch();
    }, 450); // 等待点击动画完成
  }

  private async performSearch() {
    this.isLoading = true;
    this.error = '';
    this.showToiletList = false;
    this.toilets = [];
    this.cancelStaggerReveal();
    this.visibleCount = 0;
    this.appearedIds = [];
    
    try {
      // 检查权限
      if (!await this.geoService!.checkPermission()) {
        try {
          await this.geoService!.requestPermission();
        } catch (permissionError) {
          this.error = 'Location permission denied. Please enable location access in settings.';
          this.isLoading = false;
          return;
        }
      }
      const location = await this.geoService!.getCurrentLocation();
      this.center = location;
      // 写入定位日志
      try {
        if (this.context) {
          await LocationLogStore.init(this.context);
          const locLog: LocationLog = {
            timestamp: Date.now(),
            latitude: location.latitude,
            longitude: location.longitude
          };
          await LocationLogStore.getInstance().append(locLog);
        }
      } catch (e) {
        console.warn('写入定位日志失败:', e);
      }
      
      // 添加移动动画的延迟效果
      animateTo({
        duration: 600,
        curve: Curve.EaseInOut
      }, () => {
        // 使用用户设置的搜索距离搜索公厕
        this.mapService!.searchNearbyToilets(location.longitude, location.latitude, this.searchDistance)
          .then(async (toilets: ToiletPoi[]) => {
            this.toilets = toilets;
            // 重置每项出现状态，避免复用旧的动画标记
            this.appearedIds = [];
            this.showToiletList = true;
            // 改为按项 onAppear 淡入，避免频繁全局状态更新
            // 写入搜索成功日志
            try {
              if (this.context) {
                await SearchLogStore.init(this.context);
                const searchOk: SearchLog = {
                  timestamp: Date.now(),
                  centerLatitude: location.latitude,
                  centerLongitude: location.longitude,
                  radiusMeters: this.searchDistance,
                  resultCount: toilets.length
                };
                await SearchLogStore.getInstance().append(searchOk);
              }
            } catch (e) {
              console.warn('写入搜索成功日志失败:', e);
            }
            // 写入卡片显示日志
            try {
              if (this.context) {
                await SearchLogStore.init(this.context);
                const listLog: SearchLog = {
                  timestamp: Date.now(),
                  centerLatitude: location.latitude,
                  centerLongitude: location.longitude,
                  radiusMeters: this.searchDistance,
                  resultCount: toilets.length,
                  message: '展示卡片列表'
                };
                await SearchLogStore.getInstance().append(listLog);
              }
            } catch (e) {
              console.warn('写入卡片显示日志失败:', e);
            }
          })
          .catch(async (err: Error) => {
            const error = err as Error;
            console.error(TAG, `搜索接口异常: ${error?.message}`);
            this.error = `搜索失败：${error?.message || '未知错误'}`;
            this.showToiletList = false;
            // 记录搜索失败日志
            try {
              if (this.context) {
                await SearchLogStore.init(this.context);
                const info1: SearchLogInfo = {
                  centerLatitude: location.latitude,
                  centerLongitude: location.longitude,
                  radiusMeters: this.searchDistance
                };
                await SearchLogStore.getInstance().appendError(
                  `搜索失败: ${error?.message || 'Unknown error'}`,
                  info1
                );
              }
            } catch (e) {
              console.warn('写入搜索失败日志失败:', e);
            }
          });
      });
      
    } catch (err) {
      const error = err as Error;
      console.error(TAG, `Failed to find toilets, error: ${JSON.stringify(error)}`);
      this.error = `Failed to find toilets: ${error.message || 'Unknown error'}`;
      // 写入搜索失败日志（与定位日志分开）
      try {
        if (this.context) {
          await SearchLogStore.init(this.context);
          const center = this.center;
          const info2: SearchLogInfo = {
            centerLatitude: center?.latitude,
            centerLongitude: center?.longitude,
            radiusMeters: this.searchDistance
          };
          await SearchLogStore.getInstance().appendError(
            `搜索失败: ${error.message || 'Unknown error'}`,
            info2
          );
        }
      } catch (e) {
        console.warn('写入搜索失败日志失败:', e);
      }
    } finally {
      this.isLoading = false;
    }
  }

  build(): void {
    Column() {
      // 顶部设置按钮区域
      Row() {
        Button() {
          Text('⋮')
            .fontSize(22)
            .fontColor($r('app.color.control_button_text'))
            .fontWeight(FontWeight.Medium)
        }
        .width(40)
        .height(40)
        .backgroundColor('transparent')
        .borderRadius(20)
        .onClick(() => this.handleSettingsClick())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })
      .justifyContent(FlexAlign.End)
      
      // 主要内容区域
      Column() {
        if (!this.buttonMoved) {
          // 居中显示的圆形找屎按钮
          Button('找屎')
            .width(120)
            .height(120)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.accent_color'))
            .borderRadius(60)
            .shadow({
              radius: 25,
              color: $r('app.color.accent_color'),
              offsetX: 0,
              offsetY: 10
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.handleSwipeStart(event.touches[0].x);
              } else if (event.type === TouchType.Move) {
                this.handleSwipeMove(event.touches[0].x);
              } else if (event.type === TouchType.Up) {
                this.handleSwipeEnd();
              }
            })
            .scale({
              x: this.buttonScale * this.breathingScale,
              y: this.buttonScale * this.breathingScale
            })
            .animation({
              duration: 500,
              curve: Curve.EaseInOut
            })
            .onClick(() => this.handleFindToilet())
        }
        
        // 加载状态指示器
        if (this.isLoading) {
          Column({ space: 16 }) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color($r('app.color.accent_color'))

            Text('正在搜索附近的公厕...')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ top: 40 })
        }
        
        // 错误信息显示
        if (this.error) {
          Column({ space: 12 }) {
            Text('😔')
              .fontSize(32)

            Text(this.error)
              .fontSize(14)
              .fontColor($r('app.color.error_text'))
              .textAlign(TextAlign.Center)
              .maxLines(2)
            
            Button('重试')
              .width(80)
              .height(32)
              .fontSize(12)
              .backgroundColor($r('app.color.accent_color'))
              .borderRadius(16)
              .onClick(() => {
                this.error = '';
                this.handleFindToilet();
              })
          }
          .margin({ top: 40 })
          .padding(20)
        }
        
        // 公厕列表区域
        if (this.showToiletList && this.toilets.length > 0) {
          Column() {
            // 列表头部信息
            Row() {
              Column({ space: 4 }) {
                Text(`找到 ${this.toilets.length} 个公厕`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))

                Text(`搜索范围 ${this.searchDistance}米`)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Start)
              
              Blank()
              
              // 排序按钮
              Button() {
                Row({ space: 4 }) {
                  Text('📊')
                    .fontSize(14)
                    .fontColor($r('app.color.control_button_text'))
                  Text('距离排序')
                    .fontSize(12)
                    .fontColor($r('app.color.control_button_text'))
                }
              }
              .width(80)
              .height(32)
              .backgroundColor('transparent')
              .borderRadius(16)
              .onClick(() => {
                // 按距离重新排序
                this.toilets = this.toilets.sort((a, b) => a.distance - b.distance);
              })
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            // 公厕卡片列表（使用 List 虚拟化，并逐个淡入出现）
            List({ space: 0 }) {
              ForEach(
                this.toilets,
                (toilet: ToiletPoi, index: number) => {
                  ListItem() {
                    // 使用内层容器做动画，避免直接在 ListItem 上变换
                    Column() {
                      ToiletCard({
                        toilet: toilet,
                        travelMode: this.travelMode,
                        onNavigate: this.makeNavigateHandler(toilet)
                      })
                    }
                    .opacity(this.appearedIds.indexOf(toilet.id) >= 0 ? 1 : 0)
                    .onAppear(() => {
                      // 首次出现时标记为已出现，触发淡入动画
                      if (this.appearedIds.indexOf(toilet.id) < 0) {
                        this.appearedIds = this.appearedIds.concat([toilet.id]);
                      }
                    })
                    .animation({
                      duration: 180,
                      curve: Curve.EaseOut
                    })
                  }
                },
                (toilet: ToiletPoi, index: number) => toilet.id || `${toilet.name}-${index}`
              )
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Auto)
            .edgeEffect(EdgeEffect.Spring)
            .divider({
              strokeWidth: 0,
              color: 'transparent'
            })
            .backgroundColor('transparent')
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 16 })
          .animation({
            duration: 400,
            curve: Curve.EaseOut
          })
        }
        
        // 无结果提示
        if (this.showToiletList && this.toilets.length === 0 && !this.isLoading) {
          Column({ space: 20 }) {
            // 空状态图标
            Column({ space: 8 }) {
              Text('🚽')
                .fontSize(64)
                .opacity(0.2)
              
              Text('😔')
                .fontSize(32)
                .opacity(0.4)
            }
            
            // 提示文本
            Column({ space: 8 }) {
            Text('附近没有找到公厕')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))

            Text(`搜索范围：${this.searchDistance}米`)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))

            Text('试试扩大搜索范围或换个位置')
              .fontSize(14)
              .fontColor($r('app.color.text_tertiary'))
            }
            .alignItems(HorizontalAlign.Center)
            
            // 操作按钮
            Row({ space: 12 }) {
              Button('扩大范围')
                .width(100)
                .height(40)
                .fontSize(14)
                .backgroundColor($r('app.color.control_background'))
                .fontColor($r('app.color.accent_color'))
                .borderRadius(20)
                .border({
                  width: 1,
                  color: $r('app.color.accent_color')
                })
                .onClick(() => {
                  // 扩大搜索范围
                  if (this.searchDistance < 5000) {
                    this.searchDistance = Math.min(this.searchDistance * 2, 5000);
                    this.performSearch();
                  }
                })
              
              Button('重新搜索')
                .width(100)
                .height(40)
                .fontSize(14)
                .backgroundColor($r('app.color.accent_color'))
                .borderRadius(20)
                .onClick(() => {
                  this.showToiletList = false;
                  this.buttonMoved = false;
                })
            }
          }
          .width('100%')
          .padding(40)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .animation({
            duration: 400,
            curve: Curve.EaseOut
          })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(this.buttonMoved ? FlexAlign.Start : FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.page_background'))
      
      // 底部出行方式选择器（淡化设计）
      if (this.buttonMoved) {
        // 移动后的按钮显示在底部选择器上方
        Column({ space: 12 }) {
          Button('找屎')
            .width(80)
            .height(80)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.accent_color'))
            .borderRadius(40)
            .shadow({
              radius: 15,
              color: $r('app.color.accent_color'),
              offsetX: 0,
              offsetY: 5
            })
            .scale({
              x: this.buttonScale,
              y: this.buttonScale
            })
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })
            .onClick(() => this.handleFindToilet())
          
          // 出行方式选择器
          Column({ space: 8 }) {
            Text('出行方式')
              .fontSize(12)
              .fontColor($r('app.color.text_tertiary'))

            Row({ space: 20 }) {
              // 步行按钮
              Column({ space: 4 }) {
                Text('🚶')
                  .fontSize(20)
                  .animation({
                    duration: 200,
                    curve: Curve.EaseOut
                  })
                Text('步行')
                  .fontSize(10)
                  .fontColor(this.travelMode === 'walking' ? $r('app.color.accent_color') : $r('app.color.text_disabled'))
                  .animation({
                    duration: 200,
                    curve: Curve.EaseOut
                  })
              }
              .width(50)
              .height(50)
              .borderRadius(25)
              .backgroundColor(this.travelMode === 'walking' ? $r('app.color.accent_container') : 'transparent')
              .border({
                width: this.travelMode === 'walking' ? 2 : 1,
                color: this.travelMode === 'walking' ? $r('app.color.accent_color') : $r('app.color.control_button_border')
              })
              .justifyContent(FlexAlign.Center)
              .scale({
                x: this.travelMode === 'walking' ? 1.1 : 1.0,
                y: this.travelMode === 'walking' ? 1.1 : 1.0
              })
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
              .onClick(() => {
                this.travelMode = 'walking';
              })
              
              // 骑行按钮
              Column({ space: 4 }) {
                Text('🚴')
                  .fontSize(20)
                  .animation({
                    duration: 200,
                    curve: Curve.EaseOut
                  })
                Text('骑行')
                  .fontSize(10)
                  .fontColor(this.travelMode === 'cycling' ? $r('app.color.accent_color') : $r('app.color.text_disabled'))
                  .animation({
                    duration: 200,
                    curve: Curve.EaseOut
                  })
              }
              .width(50)
              .height(50)
              .borderRadius(25)
              .backgroundColor(this.travelMode === 'cycling' ? $r('app.color.accent_container') : 'transparent')
              .border({
                width: this.travelMode === 'cycling' ? 2 : 1,
                color: this.travelMode === 'cycling' ? $r('app.color.accent_color') : $r('app.color.control_button_border')
              })
              .justifyContent(FlexAlign.Center)
              .scale({
                x: this.travelMode === 'cycling' ? 1.1 : 1.0,
                y: this.travelMode === 'cycling' ? 1.1 : 1.0
              })
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
              .onClick(() => {
                this.travelMode = 'cycling';
              })
            }
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.handleSwipeStart(event.touches[0].x);
              } else if (event.type === TouchType.Move) {
                this.handleSwipeMove(event.touches[0].x);
              } else if (event.type === TouchType.Up) {
                this.handleSwipeEnd();
              }
            })
          }
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.handleSwipeStart(event.touches[0].x);
            } else if (event.type === TouchType.Move) {
              this.handleSwipeMove(event.touches[0].x);
            } else if (event.type === TouchType.Up) {
              this.handleSwipeEnd();
            }
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
        .backgroundColor('transparent')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 原始底部出行方式选择器
        Column({ space: 8 }) {
          Text('出行方式')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))

          Row({ space: 20 }) {
            // 步行按钮
            Column({ space: 4 }) {
              Text('🚶')
                .fontSize(20)
                .animation({
                  duration: 200,
                  curve: Curve.EaseOut
                })
              Text('步行')
                .fontSize(10)
                .fontColor(this.travelMode === 'walking' ? $r('app.color.accent_color') : $r('app.color.text_disabled'))
                .animation({
                  duration: 200,
                  curve: Curve.EaseOut
                })
            }
            .width(50)
            .height(50)
            .borderRadius(25)
            .backgroundColor(this.travelMode === 'walking' ? $r('app.color.accent_container') : 'transparent')
            .border({
              width: this.travelMode === 'walking' ? 2 : 1,
              color: this.travelMode === 'walking' ? $r('app.color.accent_color') : $r('app.color.control_button_border')
            })
            .justifyContent(FlexAlign.Center)
            .scale({
              x: this.travelMode === 'walking' ? 1.1 : 1.0,
              y: this.travelMode === 'walking' ? 1.1 : 1.0
            })
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })
            .onClick(() => {
              this.travelMode = 'walking';
            })
            
            // 骑行按钮
            Column({ space: 4 }) {
              Text('🚴')
                .fontSize(20)
                .animation({
                  duration: 200,
                  curve: Curve.EaseOut
                })
              Text('骑行')
                .fontSize(10)
                .fontColor(this.travelMode === 'cycling' ? $r('app.color.accent_color') : $r('app.color.text_disabled'))
                .animation({
                  duration: 200,
                  curve: Curve.EaseOut
                })
            }
            .width(50)
            .height(50)
            .borderRadius(25)
            .backgroundColor(this.travelMode === 'cycling' ? $r('app.color.accent_container') : 'transparent')
            .border({
              width: this.travelMode === 'cycling' ? 2 : 1,
              color: this.travelMode === 'cycling' ? $r('app.color.accent_color') : $r('app.color.control_button_border')
            })
            .justifyContent(FlexAlign.Center)
            .scale({
              x: this.travelMode === 'cycling' ? 1.1 : 1.0,
              y: this.travelMode === 'cycling' ? 1.1 : 1.0
            })
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })
            .onClick(() => {
              this.travelMode = 'cycling';
            })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
        .backgroundColor('transparent')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('white')
  }
}



