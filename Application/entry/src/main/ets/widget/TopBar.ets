import router from '@ohos.router';

@Component
export struct TopBar {
  @Prop title: string = '找屎';
  @Prop showBackButton: boolean = false;

  build() {
    Row() {
      // 左侧返回按钮（可选）
      if (this.showBackButton) {
        Button() {
          Text('←')
            .fontSize(20)
            .fontColor('#007DFF')
        }
        .width(40)
        .height(40)
        .backgroundColor('transparent')
        .borderRadius(20)
        .onClick(() => {
          router.back();
        })
      } else {
        // 占位空间，保持标题居中
        Row()
          .width(40)
          .height(40)
      }
      
      // 中间标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 右侧占位空间，保持标题居中
      Row()
        .width(40)
        .height(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }
}