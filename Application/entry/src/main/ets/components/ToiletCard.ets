/**
 * 厕所卡片组件
 * 显示单个厕所的详细信息
 */

import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import { ToiletPoi } from '../map/MapService';

// 通过对象回调传递导航动作，避免直接传函数导致的编译/运行限制
export interface NavigateHandler {
  run(): void;
}

// 为 ArkTS V1 显式提供一个类实现，方便在调用方避免对象字面量
export class NavigateHandlerImpl implements NavigateHandler {
  private fn: () => void;
  constructor(fn: () => void) {
    this.fn = fn;
  }
  run(): void {
    this.fn();
  }
}

@Component
export struct ToiletCard {
  @Prop toilet: ToiletPoi;
  @Prop travelMode: string;
  @Prop onNavigate: NavigateHandler | null = null;

  // 根据距离获取颜色
  private getDistanceColor(): string {
    if (this.toilet.distance <= 200) return '#00C851'; // 绿色 - 很近
    if (this.toilet.distance <= 500) return '#FF8800'; // 橙色 - 中等
    return '#FF4444'; // 红色 - 较远
  }

  // 根据距离获取步行时间估算
  private getWalkingTime(): string {
    const walkingSpeed = 80; // 米/分钟
    const cyclingSpeed = 200; // 米/分钟
    
    const speed = this.travelMode === 'walking' ? walkingSpeed : cyclingSpeed;
    const minutes = Math.ceil(this.toilet.distance / speed);
    
    return `约${minutes}分钟`;
  }

  // 获取距离显示文本
  private getDistanceText(): string {
    if (this.toilet.distance < 1000) {
      return `${this.toilet.distance}m`;
    } else {
      return `${(this.toilet.distance / 1000).toFixed(1)}km`;
    }
  }

  private buildShareText(): string {
    const name = this.toilet.name || '附近公厕';
    const distance = this.getDistanceText();
    const address = this.toilet.address ? `，地址：${this.toilet.address}` : '';
    const { longitude, latitude } = this.toilet.location;
    const lon = Number.isFinite(longitude) ? longitude.toFixed(6) : `${longitude}`;
    const lat = Number.isFinite(latitude) ? latitude.toFixed(6) : `${latitude}`;
    const markerName = encodeURIComponent(name);
    const markerAddress = this.toilet.address ? encodeURIComponent(this.toilet.address) : '';
    const mapUrl = `https://uri.amap.com/marker?position=${lon},${lat}&name=${markerName}${markerAddress ? `&address=${markerAddress}` : ''}&callnative=0`;
    return `「${name}」距离大约${distance}${address}。\n地图链接：${mapUrl}\n（已复制，粘贴到微信即可分享）`;
  }

  private async copyShareLink(): Promise<void> {
    const shareText = this.buildShareText();
    try {
      const systemPasteboard = pasteboard.getSystemPasteboard();
      const data = pasteboard.createData(pasteboard.PasteboardDataType.PASTEBOARD_DATA_PLAIN_TEXT, shareText);
      await systemPasteboard.setPasteboardData(data);
      promptAction.showToast({ message: '已复制链接，快去微信分享吧' });
    } catch (error) {
      console.error('复制分享链接失败', JSON.stringify(error));
      promptAction.showToast({ message: '复制失败，请稍后重试' });
    }
  }

  build() {
    Row() {
      // 左侧图标和距离指示器
      Column({ space: 4 }) {
        Text('🚽')
          .fontSize(28)
        
        // 距离圆点指示器
        Circle({ width: 8, height: 8 })
          .fill(this.getDistanceColor())
      }
      .width(60)
      .height(70)
      .backgroundColor($r('app.color.control_background'))
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      
      // 中间信息区域
      Column({ space: 6 }) {
        // 公厕名称
        Text(this.toilet.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        // 地址信息（兜底为空字符串，避免未定义导致异常）
        Text(this.toilet.address || '')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(18)
        
        // 距离和时间信息
        Row({ space: 12 }) {
          // 距离标签
          Row({ space: 4 }) {
            Text('📍')
              .fontSize(12)
            Text(this.getDistanceText())
              .fontSize(13)
              .fontColor(this.getDistanceColor())
              .fontWeight(FontWeight.Medium)
          }
          
          // 时间估算
          Row({ space: 4 }) {
            Text(this.travelMode === 'walking' ? '🚶' : '🚴')
              .fontSize(12)
            Text(this.getWalkingTime())
              .fontSize(13)
              .fontColor($r('app.color.accent_color'))
          }
        }
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16, right: 12 })
      .justifyContent(FlexAlign.SpaceBetween)

      // 右侧操作按钮
      Column({ space: 8 }) {
        Button() {
          Row({ space: 4 }) {
            Text('🧭')
              .fontSize(14)
            Text('导航')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width(70)
        .height(36)
        .backgroundColor($r('app.color.accent_color'))
        .borderRadius(18)
        .onClick(() => {
          // 触发父组件的导航事件（防止未传入时异常）
          if (this.onNavigate) {
            this.onNavigate.run();
          }
        })

        Button() {
          Row({ space: 4 }) {
            Text('🟢')
              .fontSize(14)
            Text('微信')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width(70)
        .height(36)
        .backgroundColor('#07C160')
        .borderRadius(18)
        .onClick(() => {
          this.copyShareLink();
        })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(90)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.surface_card'))
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: '#00000008',
      offsetX: 0,
      offsetY: 4
    })
    .border({
      width: 1,
      color: $r('app.color.control_button_border')
    })
    .margin({ bottom: 12 })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
  }
}

