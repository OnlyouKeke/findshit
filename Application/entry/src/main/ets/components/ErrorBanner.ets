/**
 * 错误横幅组件
 * 用于显示权限拒绝、定位失败等错误提示
 */

export enum BannerType {
  ERROR = 'error',
  WARNING = 'warning',
  INFO = 'info'
}

@Component
export struct ErrorBanner {
  // 横幅类型
  @Prop type: BannerType = BannerType.ERROR;

  // 显示状态
  @Prop @Watch('onVisibleChange') visible: boolean = false;

  // 错误消息
  @Prop message: string = '';

  // 操作按钮文本
  @Prop actionText?: string;

  // 是否可关闭
  @Prop closable: boolean = true;

  // 自动隐藏时间（毫秒，0 表示不自动隐藏）
  @Prop autoHideMs: number = 5000;

  // 操作按钮点击回调
  private onActionClick?: () => void;

  // 关闭按钮点击回调
  private onClose?: () => void;

  // 自动隐藏定时器
  private autoHideTimer?: number;

  aboutToAppear() {
    if (this.visible && this.autoHideMs > 0) {
      this.startAutoHideTimer();
    }
  }

  aboutToDisappear() {
    this.clearAutoHideTimer();
  }

  // 注意：@Watch 回调建议带 new/old 参数
  onVisibleChange(newVal: boolean, oldVal: boolean) {
    if (newVal && this.autoHideMs > 0) {
      this.startAutoHideTimer();
    } else {
      this.clearAutoHideTimer();
    }
  }

  build() {
    if (!this.visible) {
      // ⚠️ DevEco 5.1.1：无块体组件无法安全链式，须写成 Row() {} 再链
      Row() {}
      .width(0)
      .height(0);
      return;
    }

    Row() {
      // 图标
      Image(this.getIconResource())
        .width(20)
        .height(20)
        .fillColor(this.getIconColor())
        .margin({ right: 8 })

      // 消息文本
      Text(this.message)
        .fontSize(14)
        .fontColor(this.getTextColor())
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 操作按钮
      if (this.actionText) {
        Button(this.actionText)
          .fontSize(12)
          .fontColor(this.getActionTextColor())
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor(this.getActionBorderColor())
          .borderRadius(4)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .margin({ left: 8, right: 8 })
          .onClick(() => {
            this.onActionClick?.();
          })
      }

      // 关闭按钮
      if (this.closable) {
        Button() {
          Image($r('app.media.ic_close'))
            .width(16)
            .height(16)
            .fillColor(this.getCloseIconColor())
        }
        .width(24)
        .height(24)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.handleClose();
        })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(8)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
    .alignItems(VerticalAlign.Center)
    .animation({ duration: 300, curve: Curve.EaseInOut });
  }

  /**
   * 获取图标资源
   */
  private getIconResource(): Resource {
    switch (this.type) {
      case BannerType.ERROR:
        return $r('app.media.ic_error');
      case BannerType.WARNING:
        return $r('app.media.ic_warning');
      case BannerType.INFO:
        return $r('app.media.ic_info');
      default:
        return $r('app.media.ic_error');
    }
  }

  /**
   * 获取图标颜色
   */
  private getIconColor(): string {
    switch (this.type) {
      case BannerType.ERROR:
        return '#FF6B6B';
      case BannerType.WARNING:
        return '#FFA726';
      case BannerType.INFO:
        return '#42A5F5';
      default:
        return '#FF6B6B';
    }
  }

  /**
   * 获取背景颜色
   */
  private getBackgroundColor(): string {
    switch (this.type) {
      case BannerType.ERROR:
        return '#FFEBEE';
      case BannerType.WARNING:
        return '#FFF8E1';
      case BannerType.INFO:
        return '#E3F2FD';
      default:
        return '#FFEBEE';
    }
  }

  /**
   * 获取文本颜色
   */
  private getTextColor(): string {
    switch (this.type) {
      case BannerType.ERROR:
        return '#C62828';
      case BannerType.WARNING:
        return '#F57C00';
      case BannerType.INFO:
        return '#1976D2';
      default:
        return '#C62828';
    }
  }

  /**
   * 获取操作按钮文本颜色
   */
  private getActionTextColor(): string {
    return this.getTextColor();
  }

  /**
   * 获取操作按钮边框颜色
   */
  private getActionBorderColor(): string {
    return this.getIconColor();
  }

  /**
   * 获取关闭图标颜色
   */
  private getCloseIconColor(): string {
    return this.getTextColor();
  }

  /**
   * 处理关闭操作
   */
  private handleClose(): void {
    this.clearAutoHideTimer();
    if (this.onClose) {
      this.onClose();
    }
  }

  /**
   * 启动自动隐藏定时器
   */
  private startAutoHideTimer(): void {
    this.clearAutoHideTimer();
    if (this.autoHideMs > 0) {
      this.autoHideTimer = setTimeout(() => {
        this.handleClose();
      }, this.autoHideMs) as unknown as number;
    }
  }

  /**
   * 清除自动隐藏定时器
   */
  private clearAutoHideTimer(): void {
    if (this.autoHideTimer !== undefined) {
      clearTimeout(this.autoHideTimer as unknown as number);
      this.autoHideTimer = undefined;
    }
  }
}
