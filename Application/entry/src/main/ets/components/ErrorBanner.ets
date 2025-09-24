/**
 * Error banner component
 * Shows error/warning/info messages with optional action and close.
 */

import { CallbackHandler } from '../common/types';

export enum BannerType {
  ERROR = 'error',
  WARNING = 'warning',
  INFO = 'info'
}

@Component
export struct ErrorBanner {
  // Type and visibility
  @Prop type: BannerType = BannerType.ERROR;
  @Prop visible: boolean = false;

  // Message text
  @Prop message: string = '';

  // Optional action button text
  @Prop actionText: string | undefined = undefined;

  // Closable and auto-hide
  @Prop closable: boolean = true;
  @Prop autoHideMs: number = 5000;

  // Callbacks wrapped to avoid function-as-prop in @Component V1
  @Prop onActionClick: CallbackHandler | undefined = undefined;
  @Prop onClose: CallbackHandler | undefined = undefined;

  // Internal auto-hide timer id
  private autoHideTimer?: number;

  aboutToAppear() {
    if (this.visible && this.autoHideMs > 0) {
      this.startAutoHideTimer();
    }
  }

  aboutToDisappear() {
    this.clearAutoHideTimer();
  }

  build() {
    Row() {
      // Icon
      Image(this.getIconResource())
        .width(20)
        .height(20)
        .fillColor(this.getIconColor())
        .margin({ right: 8 })

      // Message
      Text(this.message)
        .fontSize(14)
        .fontColor(this.getTextColor())
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // Action button
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
            this.onActionClick?.handler?.();
          });
      }

      // Close button
      if (this.closable) {
        Button() {
          Image($r('app.media.ic_close'))
            .width(16)
            .height(16)
            .fillColor(this.getCloseIconColor());
        }
          .width(24)
          .height(24)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.handleClose();
          });
      }
    }
      .visibility(this.visible ? Visibility.Visible : Visibility.None)
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.getBackgroundColor())
      .borderRadius(8)
      .margin({ left: 16, right: 16, top: 8, bottom: 8 })
      .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 2 })
      .alignItems(VerticalAlign.Center)
      .onAppear(() => {
        if (this.visible && this.autoHideMs > 0) {
          this.startAutoHideTimer();
        }
      })
      .onDisAppear(() => {
        this.clearAutoHideTimer();
      })
      .animation({ duration: 300, curve: Curve.EaseInOut });
  }

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

  private getActionTextColor(): string {
    return this.getTextColor();
  }

  private getActionBorderColor(): string {
    return this.getIconColor();
  }

  private getCloseIconColor(): string {
    return this.getTextColor();
  }

  private handleClose(): void {
    this.clearAutoHideTimer();
    this.onClose?.handler?.();
  }

  private startAutoHideTimer(): void {
    this.clearAutoHideTimer();
    if (this.autoHideMs > 0) {
      this.autoHideTimer = setTimeout((): void => {
        this.handleClose();
      }, this.autoHideMs);
    }
  }

  private clearAutoHideTimer(): void {
    if (this.autoHideTimer !== undefined) {
      clearTimeout(this.autoHideTimer);
      this.autoHideTimer = undefined;
    }
  }
}

