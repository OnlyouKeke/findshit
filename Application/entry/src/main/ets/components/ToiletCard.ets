/**
 * 厕所卡片组件
 * 显示附近厕所列表和一键找屎按钮
 */

import { ToiletPoi, Callback0, Callback1 } from '../common/types';
import { formatDistance } from '../common/utils/haversine';

@Component
export struct ToiletCard {
  // 列表数据与状态
  @Prop toilets: ToiletPoi[] = [];
  @Prop loading: boolean = false;
  @Prop error: string = '';

  // 交互回调（使用对象包装，兼容 ArkUI V1）
  @Prop onFindToiletClick: Callback0 = {};
  @Prop onToiletItemClick: Callback1<ToiletPoi> = {};

  build() {
    Column() {
      this.buildHeader()
      this.buildContent()
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .shadow({ radius: 8, color: '#1F000000', offsetX: 0, offsetY: -2 })
  }

  @Builder
  buildHeader() {
    Row() {
      Text('附近公共厕所')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .layoutWeight(1)

      // 一键找屎按钮
      Button('一键找屎')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('#4C8BF5')
        .borderRadius(20)
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .enabled(!this.loading)
        .onClick(() => {
          this.onFindToiletClick.handler?.();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildContent() {
    if (this.loading) {
      this.buildLoadingState();
    } else if (this.error) {
      this.buildErrorState();
    } else if (this.toilets.length === 0) {
      this.buildEmptyState();
    } else {
      this.buildToiletList();
    }
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color('#4C8BF5')

      Text('正在搜索附近厕所...')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildErrorState() {
    Column() {
      Image($r('app.media.ic_error'))
        .width(32)
        .height(32)
        .fillColor('#FF6B6B')

      Text(this.error || '搜索失败')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(120)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmptyState() {
    Column() {
      Image($r('app.media.ic_empty'))
        .width(32)
        .height(32)
        .fillColor('#CCCCCC')

      Text('附近没有找到公共厕所')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })

      Text('请尝试扩大搜索范围')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildToiletList() {
    List({ space: 0 }) {
      ForEach(this.toilets, (toilet: ToiletPoi, index: number) => {
        ListItem() {
          this.buildToiletItem(toilet, index)
        }
        .onClick(() => {
          this.onToiletItemClick.handler?.(toilet);
        })
      }, (toilet: ToiletPoi) => toilet.id)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .divider({ strokeWidth: 0.5, color: '#F0F0F0', startMargin: 16, endMargin: 16 })
  }

  @Builder
  buildToiletItem(toilet: ToiletPoi, index: number) {
    Row() {
      // 图标
      Image($r('app.media.ic_toilet'))
        .width(24)
        .height(24)
        .fillColor('#4C8BF5')
        .margin({ right: 12 })

      // 文本信息
      Column() {
        Text(toilet.name)
          .fontSize(16)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          if (toilet.distance !== undefined) {
            Text(formatDistance(toilet.distance))
              .fontSize(12)
              .fontColor('#666666')
          }

          if (toilet.openHours) {
            Text('·')
              .fontSize(12)
              .fontColor('#CCCCCC')
              .margin({ left: 8, right: 8 })

            Text(toilet.openHours)
              .fontSize(12)
              .fontColor('#666666')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }
}

