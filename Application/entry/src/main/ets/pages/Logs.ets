import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import LocationLogStore, { LocationLog } from '../common/LocationLogStore';
import { TopBar } from '../widget/TopBar';

@Entry
@Component
struct Logs {
  private context: common.UIAbilityContext | null = null;
  @State logs: LocationLog[] = [];
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    try {
      if (this.context) {
        await LocationLogStore.init(this.context);
        const items = await LocationLogStore.getInstance().getAll();
        // 新到旧排序
        this.logs = items.sort((a, b) => b.timestamp - a.timestamp);
      }
    } catch (e) {
      console.error('加载日志失败:', e);
    } finally {
      this.isLoading = false;
    }
  }

  private formatTime(ts: number): string {
    const d = new Date(ts);
    const pad = (n: number) => n.toString().padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  }

  private async clearLogs() {
    try {
      await LocationLogStore.getInstance().clear();
      this.logs = [];
    } catch (e) {
      console.error('清空日志失败:', e);
    }
  }

  build() {
    Column() {
      TopBar({ title: '查看日志', showBackButton: true })

      if (this.isLoading) {
        Column({ space: 12 }) {
          LoadingProgress().width(36).height(36)
          Text('正在载入定位日志...').fontSize(14).fontColor('#666666')
        }
        .padding(24)
      } else if (this.logs.length === 0) {
        Column({ space: 12 }) {
          Text('暂无定位记录').fontSize(16).fontColor('#666666')
          Button('返回')
            .width(80)
            .height(32)
            .backgroundColor('#F5F5F5')
            .borderRadius(16)
            .onClick(() => router.back())
        }
        .padding(24)
      } else {
        // 操作栏
        Row() {
          Blank().layoutWeight(1)
          Button('清空')
            .width(72)
            .height(32)
            .backgroundColor('#F5F5F5')
            .borderRadius(16)
            .onClick(() => this.clearLogs())
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        // 列表
        List() {
          ForEach(this.logs, (item: LocationLog) => {
            ListItem() {
              Row() {
                Column({ space: 4 }) {
                  Text(this.formatTime(item.timestamp))
                    .fontSize(14)
                    .fontColor('#333')
                  if (item.message) {
                    Text(`错误: ${item.message}`)
                      .fontSize(12)
                      .fontColor('#E34D59')
                  } else {
                    Text(`纬度: ${(item.latitude ?? 0).toFixed(6)}  经度: ${(item.longitude ?? 0).toFixed(6)}`)
                      .fontSize(12)
                      .fontColor('#666')
                  }
                }
                .layoutWeight(1)

                // 复制按钮
                Button('复制')
                  .width(56)
                  .height(28)
                  .backgroundColor('#F0F0F0')
                  .borderRadius(14)
                  .onClick(() => {
                    const text = item.message ? item.message : `${item.latitude},${item.longitude}`;
                    console.log('复制定位到剪贴板:', text);
                  })
              }
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')
            }
          })
        }
        .divider({ strokeWidth: 0.5, color: '#EEE' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}