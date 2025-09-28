/**
 * 厕所卡片组件
 * 显示附近厕所列表和一键找厕所按钮
 * 集成时间调节器和出行方式选择
 */

import { Callback0, Callback1, TravelMode } from '../common/types';
import { NavigationControls } from './NavigationControls';

@Component
export struct ToiletCard {
  // 加载状态
  @Prop loading: boolean = false;

  // 交互回调（使用对象包装，兼容 ArkUI V1）
  @Prop onFindToiletClick: Callback0 = { handler: undefined };
  @Prop onTimeChange: Callback1<number> = { handler: undefined };
  @Prop onModeChange: Callback1<TravelMode> = { handler: undefined };

  // 内部状态
  @State selectedTime: number = 2;
  @State travelMode: TravelMode = TravelMode.WALKING;

  build() {
    Column({ space: 16 }) {
      // 导航控制区域
      Row() {
        // 左侧：时间调节器
        this.buildTimeSelector()
        
        // 中间：找厕所按钮
        Button(this.loading ? '定位中...' : '找厕所')
          .width(100)
          .height(100)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(this.loading ? '#CCCCCC' : '#4C8BF5')
          .borderRadius(50)
          .enabled(!this.loading)
          .onClick(() => {
            this.onFindToiletClick.handler?.();
          })
        
        // 右侧：出行方式开关
        this.buildModeSwitch()
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(200)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({ radius: 8, color: '#1F000000', offsetX: 0, offsetY: -2 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 20, right: 20, top: 16, bottom: 0 })
  }

  @Builder
  buildTimeSelector() {
    Column({ space: 8 }) {
      // 固定标题
      Text('分钟')
        .fontSize(12)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
      
      // 滑动滚轮选择器
      Column() {
        TextPicker({ range: ['2', '5', '10'], selected: this.getSelectedIndex() })
          .width(60)
          .height(120)
          .backgroundColor('#F8F9FA')
          .borderRadius(8)
          .canLoop(false)
          .onChange((value: string | string[], index: number | number[]) => {
            const selectedValue = Array.isArray(value) ? value[0] : value;
            const timeValue = parseInt(selectedValue);
            this.selectedTime = timeValue;
            this.onTimeChange.handler?.(timeValue);
          })
      }
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildModeSwitch() {
    Column({ space: 8 }) {
      // Toggle开关组件
      Toggle({ type: ToggleType.Switch, isOn: this.travelMode === TravelMode.CYCLING })
        .selectedColor('#4C8BF5')
        .switchPointColor('#FFFFFF')
        .onChange((isOn: boolean) => {
          this.travelMode = isOn ? TravelMode.CYCLING : TravelMode.WALKING;
          this.onModeChange.handler?.(this.travelMode);
        })
      
      // 模式标签
      Row({ space: 12 }) {
        // 步行图标和文字
        Column({ space: 1 }) {
          Text('🚶')
            .fontSize(12)
          Text('步行')
            .fontSize(8)
            .fontColor(this.travelMode === TravelMode.WALKING ? '#4C8BF5' : '#999999')
        }
        .opacity(this.travelMode === TravelMode.WALKING ? 1 : 0.6)
        
        // 骑行图标和文字
        Column({ space: 1 }) {
          Text('🚴')
            .fontSize(12)
          Text('骑行')
            .fontSize(8)
            .fontColor(this.travelMode === TravelMode.CYCLING ? '#4C8BF5' : '#999999')
        }
        .opacity(this.travelMode === TravelMode.CYCLING ? 1 : 0.6)
      }
    }
    .alignItems(HorizontalAlign.Center)
  }

  // 获取当前选中时间的索引
  private getSelectedIndex(): number {
    const timeOptions = [2, 5, 10];
    const index = timeOptions.indexOf(this.selectedTime);
    return index >= 0 ? index : 0; // 默认选中2分钟（索引0）
  }
}

