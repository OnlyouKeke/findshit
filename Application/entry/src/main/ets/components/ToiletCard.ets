/**
 * 厕所卡片组件
 * 显示单个厕所的详细信息
 */

import { ToiletPoi } from '../map/MapService';

@Component
export struct ToiletCard {
  @Prop toilet: ToiletPoi;
  @Prop travelMode: string;
  @Prop onNavigate: () => void;

  build() {
    Row() {
      // 左侧图标
      Column() {
        Text('🚽')
          .fontSize(24)
      }
      .width(50)
      .height(50)
      .backgroundColor('#F0F8FF')
      .borderRadius(25)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      
      // 中间信息
      Column({ space: 4 }) {
        Text(this.toilet.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(this.toilet.address)
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Row({ space: 8 }) {
          Text(`${this.toilet.distance}m`)
            .fontSize(12)
            .fontColor('#007DFF')
            .fontWeight(FontWeight.Medium)
          
          Text(this.travelMode === 'walking' ? '🚶 步行' : '🚴 骑行')
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12, right: 12 })
      
      // 右侧导航按钮
      Button('导航')
        .width(60)
        .height(32)
        .fontSize(12)
        .backgroundColor('#007DFF')
        .borderRadius(16)
        .onClick(() => {
          this.onNavigate();
        })
    }
    .width('100%')
    .height(80)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#00000010',
      offsetX: 0,
      offsetY: 2
    })
    .margin({ bottom: 8 })
  }
}

