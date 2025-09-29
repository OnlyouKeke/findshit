import geoLocationManager from '@ohos.geoLocationManager';
import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HarmonyGeo } from '../common/geo';
import { MapServiceFactory } from '../map/MapServiceFactory';
import { MapService, ToiletPoi } from '../map/MapService';
import AppStorage from '../common/AppStorage';
import { ToiletCard } from '../components/ToiletCard';
import { ErrorBanner } from '../components/ErrorBanner';
import { TopBar } from '../widget/TopBar';

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

  // 导航到指定公厕
  private navigateToToilet(toilet: ToiletPoi) {
    try {
      // 构建导航URL - 使用华为地图或系统默认地图
      const mapUrl = `geo:${toilet.location.latitude},${toilet.location.longitude}?q=${encodeURIComponent(toilet.name)}`;
      
      // 尝试打开地图应用进行导航
      // 这里可以根据实际需求调用华为地图SDK的导航功能
      console.log(`导航URL: ${mapUrl}`);
      console.log(`目标位置: ${toilet.name} (${toilet.location.latitude}, ${toilet.location.longitude})`);
      
      // 显示导航确认提示
      // AlertDialog.show({
      //   title: '开始导航',
      //   message: `即将导航到 ${toilet.name}`,
      //   primaryButton: {
      //     value: '确定',
      //     action: () => {
      //       // 实际的导航逻辑
      //     }
      //   },
      //   secondaryButton: {
      //     value: '取消',
      //     action: () => {}
      //   }
      // });
      
    } catch (error) {
      console.error('导航失败:', error);
    }
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
      
      // 添加移动动画的延迟效果
      animateTo({
        duration: 600,
        curve: Curve.EaseInOut
      }, () => {
        // 使用用户设置的搜索距离搜索公厕
        this.mapService!.searchNearbyToilets(location.longitude, location.latitude, this.searchDistance)
          .then(toilets => {
            this.toilets = toilets;
            this.showToiletList = true;
          });
      });
      
    } catch (err) {
      const error = err as Error;
      console.error(TAG, `Failed to find toilets, error: ${JSON.stringify(error)}`);
      this.error = `Failed to find toilets: ${error.message || 'Unknown error'}`;
    } finally {
      this.isLoading = false;
    }
  }

  build(): void {
    Column() {
      // 顶部设置按钮区域
      Row() {
        Button() {
          Text('⚙️')
            .fontSize(20)
            .fontColor('#666666')
        }
        .width(48)
        .height(48)
        .backgroundColor('#F5F5F5')
        .borderRadius(24)
        .onClick(() => this.handleSettingsClick())
        .shadow({
          radius: 4,
          color: '#00000020',
          offsetX: 0,
          offsetY: 2
        })
        
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })
      
      // 主要内容区域
      Column() {
        if (!this.buttonMoved) {
          // 居中显示的圆形找屎按钮
          Button('找屎')
            .width(120)
            .height(120)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#007DFF')
            .borderRadius(60)
            .shadow({
              radius: 25,
              color: '#007DFF',
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
              .color('#007DFF')
            
            Text('正在搜索附近的公厕...')
              .fontSize(16)
              .fontColor('#666666')
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
              .fontColor('#FF4444')
              .textAlign(TextAlign.Center)
              .maxLines(2)
            
            Button('重试')
              .width(80)
              .height(32)
              .fontSize(12)
              .backgroundColor('#007DFF')
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
                  .fontColor('#1A1A1A')
                
                Text(`搜索范围 ${this.searchDistance}米`)
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .alignItems(HorizontalAlign.Start)
              
              Blank()
              
              // 排序按钮
              Button() {
                Row({ space: 4 }) {
                  Text('📊')
                    .fontSize(14)
                  Text('距离排序')
                    .fontSize(12)
                }
              }
              .width(80)
              .height(32)
              .backgroundColor('#F5F5F5')
              .borderRadius(16)
              .onClick(() => {
                // 按距离重新排序
                this.toilets = this.toilets.sort((a, b) => a.distance - b.distance);
              })
            }
            .width('100%')
            .margin({ bottom: 16 })
            
            // 公厕列表
            List({ space: 0 }) {
              ForEach(this.toilets, (toilet: ToiletPoi, index: number) => {
                ListItem() {
                  ToiletCard({
                    toilet: toilet,
                    travelMode: this.travelMode,
                    onNavigate: () => {
                      // 导航功能 - 可以集成华为地图导航
                      console.log(`导航到公厕: ${toilet.name}`);
                      // 这里可以调用华为地图的导航API
                      // 或者打开系统默认地图应用
                      this.navigateToToilet(toilet);
                    }
                  })
                }
                .animation({
                  duration: 300,
                  delay: index * 50, // 错开动画时间
                  curve: Curve.EaseOut
                })
              })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Auto)
            .edgeEffect(EdgeEffect.Spring)
            .divider({
              strokeWidth: 0,
              color: 'transparent'
            })
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
                .fontColor('#333333')
              
              Text(`搜索范围：${this.searchDistance}米`)
                .fontSize(14)
                .fontColor('#666666')
              
              Text('试试扩大搜索范围或换个位置')
                .fontSize(14)
                .fontColor('#999999')
            }
            .alignItems(HorizontalAlign.Center)
            
            // 操作按钮
            Row({ space: 12 }) {
              Button('扩大范围')
                .width(100)
                .height(40)
                .fontSize(14)
                .backgroundColor('#F5F5F5')
                .fontColor('#007DFF')
                .borderRadius(20)
                .border({
                  width: 1,
                  color: '#007DFF'
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
                .backgroundColor('#007DFF')
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
      .backgroundColor('#F8F9FA')
      
      // 底部出行方式选择器（淡化设计）
      if (this.buttonMoved) {
        // 移动后的按钮显示在底部选择器上方
        Column({ space: 12 }) {
          Button('找屎')
            .width(80)
            .height(80)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#007DFF')
            .borderRadius(40)
            .shadow({
              radius: 15,
              color: '#007DFF',
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
              .fontColor('#999999')
            
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
                  .fontColor(this.travelMode === 'walking' ? '#007DFF' : '#CCCCCC')
                  .animation({
                    duration: 200,
                    curve: Curve.EaseOut
                  })
              }
              .width(50)
              .height(50)
              .borderRadius(25)
              .backgroundColor(this.travelMode === 'walking' ? '#F0F8FF' : 'transparent')
              .border({
                width: this.travelMode === 'walking' ? 2 : 1,
                color: this.travelMode === 'walking' ? '#007DFF' : '#E0E0E0'
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
                  .fontColor(this.travelMode === 'cycling' ? '#007DFF' : '#CCCCCC')
                  .animation({
                    duration: 200,
                    curve: Curve.EaseOut
                  })
              }
              .width(50)
              .height(50)
              .borderRadius(25)
              .backgroundColor(this.travelMode === 'cycling' ? '#F0F8FF' : 'transparent')
              .border({
                width: this.travelMode === 'cycling' ? 2 : 1,
                color: this.travelMode === 'cycling' ? '#007DFF' : '#E0E0E0'
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
        .backgroundColor('#FAFAFA')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 原始底部出行方式选择器
        Column({ space: 8 }) {
          Text('出行方式')
            .fontSize(12)
            .fontColor('#999999')
          
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
                .fontColor(this.travelMode === 'walking' ? '#007DFF' : '#CCCCCC')
                .animation({
                  duration: 200,
                  curve: Curve.EaseOut
                })
            }
            .width(50)
            .height(50)
            .borderRadius(25)
            .backgroundColor(this.travelMode === 'walking' ? '#F0F8FF' : 'transparent')
            .border({
              width: this.travelMode === 'walking' ? 2 : 1,
              color: this.travelMode === 'walking' ? '#007DFF' : '#E0E0E0'
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
                .fontColor(this.travelMode === 'cycling' ? '#007DFF' : '#CCCCCC')
                .animation({
                  duration: 200,
                  curve: Curve.EaseOut
                })
            }
            .width(50)
            .height(50)
            .borderRadius(25)
            .backgroundColor(this.travelMode === 'cycling' ? '#F0F8FF' : 'transparent')
            .border({
              width: this.travelMode === 'cycling' ? 2 : 1,
              color: this.travelMode === 'cycling' ? '#007DFF' : '#E0E0E0'
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
        .backgroundColor('#FAFAFA')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}



