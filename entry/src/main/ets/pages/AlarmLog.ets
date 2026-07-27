/**
 * 告警记录页面
 *
 * 拉取 GET /api/events?kind=alarm，展示所有告警事件。
 * 设备告警来源：上游物联网平台实时推送。
 */

import { PageTitle } from '../components/CommonBuilders';
import { apiService, EventItem } from '../services/ApiService';

@Component
export struct AlarmLogPage {
  @State events: EventItem[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State totalCount: number = 0;
  @State selectedKind: string = 'alarm';  // 默认只显示告警，可选 'cmd' 等

  aboutToAppear(): void {
    this.fetchEvents();
  }

  async fetchEvents(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';
    try {
      let result = await apiService.getEvents(200, undefined, this.selectedKind);
      this.events = result.events;
      this.totalCount = result.events.length;
    } catch (err) {
      this.errorText = '加载失败：' + String((err as Error).message || '未知错误');
    }
    this.isLoading = false;
  }

  formatTime(ts: number): string {
    if (!ts || ts <= 0) { return '--:--:--'; }
    let d = new Date(ts * 1000);
    return (
      `${d.getFullYear()}-${(d.getMonth()+1).toString().padStart(2,'0')}-${d.getDate().toString().padStart(2,'0')} ` +
      `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}:${d.getSeconds().toString().padStart(2,'0')}`
    );
  }

  getKindLabel(kind: string): string {
    switch (kind) {
      case 'alarm': return '告警';
      case 'online': return '上线';
      case 'offline': return '离线';
      case 'cmd': return '命令下发';
      case 'cmd_ack': return '命令回执';
      case 'lock': return '开锁记录';
      case 'access': return '鉴权事件';
      default: return kind;
    }
  }

  getKindColor(kind: string): string {
    switch (kind) {
      case 'alarm': return '#F44336';
      case 'online': return '#4CAF50';
      case 'offline': return '#9E9E9E';
      case 'cmd': return '#2196F3';
      case 'lock': return '#FF9800';
      default: return '#999';
    }
  }

  build() {
    Column() {
      // ---- 标题栏 ----
      Row() {
        PageTitle('事件日志')
        Blank()
        Text(`共 ${this.totalCount} 条`)
          .fontSize(12)
          .fontColor('#999')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // ---- 筛选栏 ----
      Row({ space: 8 }) {
        ForEach(['alarm', 'cmd', 'lock', 'online', 'offline'], (kind: string) => {
          Text(this.getKindLabel(kind))
            .fontSize(12)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(14)
            .fontColor(this.selectedKind === kind ? '#FFFFFF' : '#666')
            .backgroundColor(this.selectedKind === kind ? this.getKindColor(kind) : '#F0F0F0')
            .onClick(() => {
              this.selectedKind = kind;
              this.fetchEvents();
            })
        })
        Blank()
        Text('🔄')
          .fontSize(20)
          .onClick(() => { if (!this.isLoading) { this.fetchEvents(); } })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // ---- 加载 ----
      if (this.isLoading) {
        Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 40 })
      }

      // ---- 错误 ----
      if (this.errorText !== '') {
        Text(this.errorText)
          .fontSize(13).fontColor('#F44336')
          .padding(12).backgroundColor('#FFEBEE').borderRadius(8).width('100%')
      }

      // ---- 空数据 ----
      if (this.events.length === 0 && !this.isLoading && this.errorText === '') {
        Text('暂无记录').fontSize(14).fontColor('#999').margin({ top: 40 })
      }

      // ---- 事件列表 ----
      if (this.events.length > 0) {
        List({ space: 8 }) {
          ForEach(this.events, (event: EventItem) => {
            ListItem() {
              Row() {
                // 类型标记
                Text(this.getKindLabel(event.kind))
                  .fontSize(11)
                  .fontColor('#FFFFFF')
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor(this.getKindColor(event.kind))
                  .borderRadius(4)

                Column() {
                  Text(event.device_id)
                    .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                  Text(this.formatTime(event.ts))
                    .fontSize(11).fontColor('#BBB').margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 10 })

                Blank()

                Text('>')
                  .fontSize(16).fontColor('#CCC').fontWeight(FontWeight.Bold)
              }
              .width('100%')
              .padding(14)
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }
}
