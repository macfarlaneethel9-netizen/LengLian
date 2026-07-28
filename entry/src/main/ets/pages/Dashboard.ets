/**
 * 仪表盘首页
 *
 * 实时概览所有设备状态：在线数、告警数、温度/湿度/光照分布。
 * 每 3 秒自动刷新，数据来自后端 API（后端持续从华为云 IoT 接收）。
 *
 * 数据链路：
 *   RK2206 → MQTT → 华为云 IoT → AMQP → 后端 → REST API → 本页面
 */

import { apiService, DeviceInfo } from '../services/ApiService';
import { realtimeService } from '../services/RealtimeService';

@Component
export struct DashboardPage {
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State totalCount: number = 0;
  @State onlineCount: number = 0;
  @State alarmCount: number = 0;
  @State avgTemp: number = 0;
  @State avgHumi: number = 0;
  @State lastRefresh: string = '--:--:--';

  aboutToAppear(): void {
    this.loadData();

    realtimeService.onUpdate((devices: DeviceInfo[]) => {
      this.devices = devices;
      this.calcSummary(devices);
      this.updateTime();
    });
    realtimeService.start(3000);
  }

  aboutToDisappear(): void {
    realtimeService.stop();
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      this.devices = (await apiService.getDevices(1, 50)).items;
      this.calcSummary(this.devices);
    } catch (err) {
      console.error('[Dashboard] 加载失败:', JSON.stringify(err));
    }
    this.isLoading = false;
    this.updateTime();
  }

  calcSummary(devices: DeviceInfo[]): void {
    this.totalCount = devices.length;
    this.onlineCount = devices.filter(d => d.online).length;
    this.alarmCount = devices.filter(d => d.last_telemetry.alarm === 1).length;

    if (devices.length > 0) {
      this.avgTemp = devices.reduce((s, d) => s + d.last_telemetry.temp, 0) / devices.length;
      this.avgHumi = devices.reduce((s, d) => s + d.last_telemetry.humi, 0) / devices.length;
    }
  }

  updateTime(): void {
    let now = new Date();
    this.lastRefresh =
      `${now.getHours().toString().padStart(2, '0')}:` +
      `${now.getMinutes().toString().padStart(2, '0')}:` +
      `${now.getSeconds().toString().padStart(2, '0')}`;
  }

  getTempColor(t: number): string {
    if (t > 8) { return '#F44336'; }
    if (t < 2) { return '#FF9800'; }
    return '#4CAF50';
  }

  build() {
    Column() {
      if (this.isLoading && this.devices.length === 0) {
        Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 60 })
      } else {
        // ---- 顶栏 ----
        Row() {
          Text('仪表盘')
            .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#333')
            .margin({ top: 20, bottom: 6 })
          Blank()
          Text(`刷新: ${this.lastRefresh}`)
            .fontSize(11).fontColor('#BBB')
        }
        .width('100%')

        // ---- 四宫格统计 ----
        Grid() {
          GridItem() {
            this.StatCard('设备总数', `${this.totalCount}`, '#1a73e8')
          }
          GridItem() {
            this.StatCard('在线设备', `${this.onlineCount}`, '#4CAF50')
          }
          GridItem() {
            this.StatCard('告警设备', `${this.alarmCount}`, this.alarmCount > 0 ? '#F44336' : '#999')
          }
          GridItem() {
            this.StatCard('平均温度', `${this.avgTemp.toFixed(1)}℃`, this.getTempColor(this.avgTemp))
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
        .height(200)
        .margin({ top: 16, bottom: 16 })

        // ---- 设备状态条 ----
        Text('设备实时状态')
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
          .width('100%').margin({ bottom: 10 })

        if (this.devices.length === 0) {
          Text('暂无设备').fontSize(14).fontColor('#999').margin({ top: 20 })
        } else {
          List({ space: 10 }) {
            ForEach(this.devices, (device: DeviceInfo) => {
              ListItem() {
                Row() {
                  // 状态灯
                  Circle()
                    .width(10).height(10)
                    .fill(device.online ? '#4CAF50' : '#BDBDBD')

                  Column() {
                    Text(device.name || device.device_id)
                      .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333')
                    Text(device.location || '--')
                      .fontSize(11).fontColor('#999').margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .margin({ left: 10 })

                  Blank()

                  Column() {
                    Text(`${device.last_telemetry.temp.toFixed(1)}℃`)
                      .fontSize(15).fontWeight(FontWeight.Bold)
                      .fontColor(this.getTempColor(device.last_telemetry.temp))
                    Text(`${device.last_telemetry.humi.toFixed(1)}%`)
                      .fontSize(11).fontColor('#2196F3').margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.End)
                  .margin({ right: 12 })

                  if (device.last_telemetry.alarm === 1) {
                    Text('⚠️').fontSize(16)
                  }
                }
                .width('100%')
                .padding(14)
                .backgroundColor('#FFFFFF')
                .borderRadius(10)
              }
            })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  StatCard(label: string, value: string, color: string) {
    Column() {
      Text(label).fontSize(13).fontColor('#999')
      Text(value).fontSize(32).fontWeight(FontWeight.Bold).fontColor(color).margin({ top: 6 })
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }
}
