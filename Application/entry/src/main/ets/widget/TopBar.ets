import router from '@ohos.router';

@Component
export struct TopBar {
  private title: string = '';
  private showBackButton: boolean = false;

  build() {
    Row() {
      // 返回按钮
      if (this.showBackButton) {
        Button() {
          Text('←')
            .fontSize(24)
            .fontColor('#333333')
        }
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .backgroundColor('#F0F0F0')
        .onClick(() => {
          router.back();
        })
      }

      // 标题
      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(this.showBackButton ? TextAlign.Center : TextAlign.Center)

      // 占位空间（保持标题居中）
      if (this.showBackButton) {
        Row()
          .width(40)
          .height(40)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }
}