/**
 * 导航控制组件
 * 包含时间调节器（时钟样式）和出行方式开关
 */

import { Callback1, TravelMode } from '../common/types';

// 时间选项（分钟）
export const TIME_OPTIONS = [2, 5, 10];

@Component
export struct NavigationControls {
  @State selectedTime: number = 5; // 默认5分钟
  @State travelMode: TravelMode = TravelMode.WALKING; // 默认步行
  
  // 回调函数
  @Prop onTimeChange?: Callback1<number>;
  @Prop onModeChange?: Callback1<TravelMode>;

  build() {
    Row({ space: 20 }) {
      // 左侧：时间调节器（时钟样式）
      this.buildTimeSelector()
      
      // 右侧：出行方式开关
      this.buildModeSwitch()
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 20, right: 20 })
  }

  @Builder
  buildTimeSelector() {
    Column({ space: 8 }) {
      // 时钟图标
      Stack() {
        // 外圆
        Circle()
          .width(40)
          .height(40)
          .fill('#E8F4FD')
          .stroke('#4C8BF5')
          .strokeWidth(2)
        
        // 时钟指针
        Column() {
          // 时针
          Rect()
            .width(2)
            .height(12)
            .fill('#4C8BF5')
            .margin({ bottom: 2 })
          
          // 分针
          Rect()
            .width(1)
            .height(16)
            .fill('#4C8BF5')
        }
        .rotate({ angle: this.getClockAngle() })
      }
      
      // 时间选项
      Row({ space: 8 }) {
        ForEach(TIME_OPTIONS, (time: number) => {
          Text(`${time}min`)
            .fontSize(12)
            .fontColor(this.selectedTime === time ? '#4C8BF5' : '#666666')
            .fontWeight(this.selectedTime === time ? FontWeight.Bold : FontWeight.Normal)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.selectedTime === time ? '#E8F4FD' : Color.Transparent)
            .borderRadius(12)
            .onClick(() => {
              this.selectedTime = time;
              this.onTimeChange?.handler?.(time);
            })
        })
      }
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildModeSwitch() {
    Column({ space: 8 }) {
      // 开关样式的出行方式选择器
      Stack() {
        // 背景轨道
        Rect()
          .width(80)
          .height(36)
          .fill('#F0F0F0')
          .borderRadius(18)
        
        // 滑动按钮
        Circle()
          .width(32)
          .height(32)
          .fill('#4C8BF5')
          .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
          .translate({
            x: this.travelMode === TravelMode.WALKING ? -20 : 20
          })
          .animation({
            duration: 200,
            curve: Curve.EaseInOut
          })
      }
      .onClick(() => {
        this.travelMode = this.travelMode === TravelMode.WALKING ? TravelMode.CYCLING : TravelMode.WALKING;
        this.onModeChange?.handler?.(this.travelMode);
      })
      
      // 模式标签
      Row({ space: 16 }) {
        // 步行图标和文字
        Column({ space: 2 }) {
          Text('🚶')
            .fontSize(16)
          Text('步行')
            .fontSize(10)
            .fontColor(this.travelMode === TravelMode.WALKING ? '#4C8BF5' : '#999999')
        }
        .opacity(this.travelMode === TravelMode.WALKING ? 1 : 0.6)
        
        // 骑行图标和文字
        Column({ space: 2 }) {
          Text('🚴')
            .fontSize(16)
          Text('骑行')
            .fontSize(10)
            .fontColor(this.travelMode === TravelMode.CYCLING ? '#4C8BF5' : '#999999')
        }
        .opacity(this.travelMode === TravelMode.CYCLING ? 1 : 0.6)
      }
    }
    .alignItems(HorizontalAlign.Center)
  }

  // 根据选择的时间计算时钟指针角度
  private getClockAngle(): number {
    // 简单的角度计算，让指针根据时间变化
    return (this.selectedTime * 30) % 360; // 每分钟30度
  }
}