/**
 * 仪表盘 — 四宫格指标 + 24 小时实时曲线
 *
 * 每 3 秒轮询后端，追加采样点到实时曲线，
 * 保留最近 28800 点（覆盖 24 小时），自动滚动。
 * 四宫格卡片：温度 / 光照 / 湿度 / 倾斜。
 *
 * 数据链路：
 *   RK2206 → MQTT → 华为云 IoT → 后端 API → RealtimeService → 本页面
 */

import { PageTitle } from '../components/CommonBuilders';
import { LineChart, ChartData } from '../components/LineChart';
import {
  apiService, DeviceInfo, fmtTemp, fmtHumi, fmtLux, getAlarm, getAlarmReason
} from '../services/ApiService';
import { realtimeService } from '../services/RealtimeService';

const MAX_POINTS = 28800;  // 3秒×28800点 = 24小时

@Component
export struct DashboardPage {
  @State deviceName: string = '';
  @State deviceOnline: boolean = false;
  @State deviceLocation: string = '';
  @State devices: DeviceInfo[] = [];

  // 最新快照
  @State temp: number = 0;
  @State humi: number = 0;
  @State lux: number = 0;
  @State tilt: number = 0;
  @State alarm: number = 0;
  @State alarmReason: string = '';

  // 实时曲线数据
  @State chartData: ChartData[] = [];
  @State isLoading: boolean = true;
  @State lastRefresh: string = '--:--:--';

  private isMounted: boolean = false;

  aboutToAppear(): void {
    this.isMounted = true;
    this.loadFirstData();

    realtimeService.onUpdate((devices: DeviceInfo[]) => {
      if (!this.isMounted) { return; }
      this.devices = devices;
      if (devices.length > 0) {
        let d = devices[0];
        this.deviceName = d.name || d.device_id;
        this.deviceOnline = d.online;
        this.deviceLocation = d.location || '';
        this.temp = d.last_telemetry.temp;
        this.humi = d.last_telemetry.humi;
        this.lux = d.last_telemetry.lux;
        this.tilt = d.last_telemetry.tilt;
        this.alarm = d.last_telemetry.alarm;
        this.alarmReason = d.last_telemetry.alarm_reason || '';

        let now = new Date();
        let timeLabel = `${now.getHours().toString().padStart(2,'0')}:${now.getMinutes().toString().padStart(2,'0')}:${now.getSeconds().toString().padStart(2,'0')}`;
        this.chartData.push(new ChartData(timeLabel, this.temp, this.humi, this.lux));

        // 保持最多 MAX_POINTS 个点
        while (this.chartData.length > MAX_POINTS) {
          this.chartData.splice(0, 1);
        }
      }
      this.updateTime();
    });
    realtimeService.start(3000);  // 3秒一次
  }

  aboutToDisappear(): void {
    this.isMounted = false;
    realtimeService.stop();
  }

  async loadFirstData(): Promise<void> {
    this.isLoading = true;
    try {
      let result = await apiService.getDevices(1, 50);
      if (!this.isMounted) { return; }
      if (result.items && result.items.length > 0) {
        let d = result.items[0];
        this.devices = result.items;
        this.deviceName = d.name || d.device_id;
        this.deviceOnline = d.online;
        this.deviceLocation = d.location || '';
        this.temp = d.last_telemetry.temp;
        this.humi = d.last_telemetry.humi;
        this.lux = d.last_telemetry.lux;
        this.tilt = d.last_telemetry.tilt;
        this.alarm = d.last_telemetry.alarm;
        this.alarmReason = d.last_telemetry.alarm_reason || '';

        let now = new Date();
        let tl = `${now.getHours().toString().padStart(2,'0')}:${now.getMinutes().toString().padStart(2,'0')}:${now.getSeconds().toString().padStart(2,'0')}`;
        this.chartData.push(new ChartData(tl, this.temp, this.humi, this.lux));
      }
    } catch (err) {
      console.error('[Dashboard] 加载失败:', JSON.stringify(err));
    }
    this.isLoading = false;
    this.updateTime();
  }

  updateTime(): void {
    let now = new Date();
    this.lastRefresh =
      `${now.getHours().toString().padStart(2,'0')}:` +
      `${now.getMinutes().toString().padStart(2,'0')}:` +
      `${now.getSeconds().toString().padStart(2,'0')}`;
  }

  getTempColor(t: number): string {
    if (t > 8) { return '#F44336'; }
    if (t < 2) { return '#FF9800'; }
    return '#4CAF50';
  }

  getHumiColor(h: number): string {
    if (h > 80) { return '#FF9800'; }
    if (h < 20) { return '#F44336'; }
    return '#2196F3';
  }

  getLuxColor(l: number): string {
    if (l > 200) { return '#FF9800'; }
    return '#4CAF50';
  }

  getTiltColor(t: number): string {
    if (t > 15000) { return '#F44336'; }
    return '#666';
  }

  build() {
    Column() {
      Row() {
        PageTitle('仪表盘')
        Blank()
        Text(`刷新: ${this.lastRefresh}`).fontSize(11).fontColor('#BBB')
      }
      .width('100%').alignItems(VerticalAlign.Center)

      if (this.isLoading) {
        Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 60 })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            // ====== 设备信息条 ======
            Row() {
              Circle().width(10).height(10).fill(this.deviceOnline ? '#4CAF50' : '#BDBDBD')
              Text(this.deviceName)
                .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333').margin({ left: 8 })
              Blank()
              Text(this.deviceOnline ? '🟢 在线' : '⚫ 离线')
                .fontSize(12).fontColor(this.deviceOnline ? '#4CAF50' : '#999')
              if (this.deviceLocation !== '') {
                Text(` 📍 ${this.deviceLocation}`)
                  .fontSize(12).fontColor('#999').margin({ left: 8 })
              }
            }
            .width('100%').padding(14)
            .backgroundColor('#FFFFFF').borderRadius(12)
            .shadow({ radius: 4, color: '#00000008', offsetY: 2 })

            // ====== 四宫格指标卡片 ======
            Row({ space: 8 }) {
              this.MetricCard('🌡️ 温度', `${this.temp.toFixed(1)}℃`, this.getTempColor(this.temp))
              this.MetricCard('💡 光照', `${this.lux.toFixed(0)} lx`, this.getLuxColor(this.lux))
            }.width('100%')

            Row({ space: 8 }) {
              this.MetricCard('💧 湿度', `${this.humi.toFixed(1)}%`, this.getHumiColor(this.humi))
              this.MetricCard('📐 倾斜', `${this.tilt.toFixed(0)}`, this.getTiltColor(this.tilt))
            }.width('100%')

            // ====== 告警 ======
            if (this.alarm === 1) {
              Row() {
                Text('⚠️').fontSize(16)
                Text(`告警: ${this.alarmReason}`)
                  .fontSize(14).fontColor('#F44336').margin({ left: 8 })
              }
              .width('100%').padding(14)
              .backgroundColor('#FFF3F0').borderRadius(10)
            }

            // ====== 实时曲线 ======
            Text('实时曲线')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
              .width('100%').margin({ top: 4 })

            LineChart({ data: this.chartData })

            Column().height(16)
          }
          .width('100%')
        }
        .width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  MetricCard(label: string, value: string, color: string) {
    Column() {
      Text(label).fontSize(12).fontColor('#999')
      Text(value).fontSize(24).fontWeight(FontWeight.Bold).fontColor(color).margin({ top: 4 })
    }
    .width('100%').height(90).justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF').borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }
}
