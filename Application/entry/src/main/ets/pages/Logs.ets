import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import LocationLogStore, { LocationLog } from '../common/LocationLogStore';
import SearchLogStore, { SearchLog } from '../common/SearchLogStore';
import { TopBar } from '../widget/TopBar';

@Entry
@Component
struct Logs {
  private context: common.UIAbilityContext | null = null;
  @State logs: LocationLog[] = [];
  @State searchLogs: SearchLog[] = [];
  @State tab: 'location' | 'search' = 'location';
  @State isLoading: boolean = true;

  async aboutToAppear() {
    this.context = getContext(this) as common.UIAbilityContext;
    try {
      if (this.context) {
        await LocationLogStore.init(this.context);
        const locItems = await LocationLogStore.getInstance().getAll();
        this.logs = locItems.sort((a, b) => b.timestamp - a.timestamp);

        await SearchLogStore.init(this.context);
        const schItems = await SearchLogStore.getInstance().getAll();
        this.searchLogs = schItems.sort((a, b) => b.timestamp - a.timestamp);
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
      if (this.tab === 'location') {
        await LocationLogStore.getInstance().clear();
        this.logs = [];
      } else {
        await SearchLogStore.getInstance().clear();
        this.searchLogs = [];
      }
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
            .backgroundColor($r('app.color.control_button_bg'))
            .fontColor($r('app.color.control_button_text'))
            .borderRadius(16)
            .border({ width: 1, color: $r('app.color.control_button_border') })
            .onClick(() => router.back())
        }
        .padding(24)
      } else {
        // 操作栏
        Row() {
          // 顶部切换标签
          Row({ space: 8 }) {
            Button(this.tab === 'location' ? '定位日志' : '定位日志')
              .width(84)
              .height(28)
              .backgroundColor(this.tab === 'location' ? '#4C8BF5' : '#F0F0F0')
              .fontColor(this.tab === 'location' ? '#FFFFFF' : '#333333')
              .borderRadius(14)
              .onClick(() => this.tab = 'location')
            Button(this.tab === 'search' ? '搜索日志' : '搜索日志')
              .width(84)
              .height(28)
              .backgroundColor(this.tab === 'search' ? '#4C8BF5' : '#F0F0F0')
              .fontColor(this.tab === 'search' ? '#FFFFFF' : '#333333')
              .borderRadius(14)
              .onClick(() => this.tab = 'search')
          }
          .layoutWeight(1)

          Button('清空')
            .width(72)
            .height(32)
            .backgroundColor($r('app.color.control_button_bg'))
            .fontColor($r('app.color.control_button_text'))
            .borderRadius(16)
            .border({ width: 1, color: $r('app.color.control_button_border') })
            .onClick(() => this.clearLogs())
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        // 列表（按类型分别渲染，避免 any）
        if (this.tab === 'location') {
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

                  Button('复制')
                    .width(56)
                    .height(28)
                    .backgroundColor($r('app.color.control_button_bg'))
                    .fontColor($r('app.color.control_button_text'))
                    .borderRadius(14)
                    .border({ width: 1, color: $r('app.color.control_button_border') })
                    .onClick(() => {
                      const text = item.message ? item.message : `${item.latitude},${item.longitude}`;
                      console.log('复制定位到剪贴板:', text);
                    })
                }
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .backgroundColor($r('app.color.surface_card'))
              }
            })
          }
          .divider({ strokeWidth: 0.5, color: $r('app.color.control_button_border') })
        } else {
          List() {
            ForEach(this.searchLogs, (item: SearchLog) => {
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
                      Text(`中心: ${(item.centerLatitude ?? 0).toFixed(6)}, ${(item.centerLongitude ?? 0).toFixed(6)}  半径: ${(item.radiusMeters ?? 0)}m  结果: ${(item.resultCount ?? 0)}`)
                        .fontSize(12)
                        .fontColor('#666')
                    }
                  }
                  .layoutWeight(1)

                  Button('复制')
                    .width(56)
                    .height(28)
                    .backgroundColor($r('app.color.control_button_bg'))
                    .fontColor($r('app.color.control_button_text'))
                    .borderRadius(14)
                    .border({ width: 1, color: $r('app.color.control_button_border') })
                    .onClick(() => {
                      const text = item.message ? item.message : `${item.centerLatitude},${item.centerLongitude}, radius=${item.radiusMeters}, count=${item.resultCount}`;
                      console.log('复制搜索到剪贴板:', text);
                    })
                }
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .backgroundColor($r('app.color.surface_card'))
              }
            })
          }
          .divider({ strokeWidth: 0.5, color: $r('app.color.control_button_border') })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}