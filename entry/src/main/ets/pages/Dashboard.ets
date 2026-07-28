/**
 * 仪表盘（Dashboard）— 对标 Web 端主页
 *
 * ============================================================
 * 功能：
 * ============================================================
 *   1. 顶部设备选择区：显示当前设备 ID + 在线状态
 *   2. 状态指标卡片：温度、湿度、光照、倾斜量 最新值
 *   3. 24 小时 历史趋势折线图（温度/湿度/光照）
 *   4. 兜底机制：后端无数据时自动使用 Mock 数据
 *
 * ============================================================
 * 数据流：
 * ============================================================
 *   aboutToAppear()
 *     → fetchDeviceAndTelemetry()
 *       ├─ GET /api/devices → 有设备 → 用第一个设备的 ID
 *       │                    → 空     → 默认 tx-r-cc-001
 *       ├─ GET /api/devices/{id}/telemetry → 有数据 → 真实渲染
 *       └─ 无数据 → generateMockTelemetry(id) → Mock 渲染
 */

import { PageTitle } from '../components/CommonBuilders';
import { LineChart } from '../components/LineChart';
import { apiService, DeviceInfo, TelemetryData, fmtTemp, fmtHumi, fmtLux } from '../services/ApiService';
import { generateMockTelemetry, generateMockSnapshot, MOCK_DEVICE_ID } from '../services/MockData';

@Component
export struct DashboardPage {
  // ---- 设备 ----
  @State deviceId: string = '';
  @State deviceName: string = '';
  @State deviceOnline: boolean = false;
  @State deviceLocation: string = '';

  // ---- 最新快照 ----
  @State snapshot: TelemetryData | null = null;

  // ---- 历史数据 + 图表 ----
  @State telemetryHistory: TelemetryData[] = [];
  @State isMockData: boolean = false;

  // ---- UI 状态 ----
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State currentTabIndex: number = 0;
  private isMounted: boolean = false;

  // ====== 生命周期 ======

  aboutToAppear(): void {
    this.isMounted = true;
    console.info('[Dashboard] aboutToAppear → 加载数据');
    this.fetchDashboardData();
  }

  aboutToDisappear(): void {
    this.isMounted = false;
    console.info('[Dashboard] aboutToDisappear');
  }

  // ====== 核心数据加载 ======

  async fetchDashboardData(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';

    try {
      // 步骤 1：获取设备列表
      let deviceResult = await apiService.getDevices(1, 10);

      if (!this.isMounted) { return; }

      let targetId = MOCK_DEVICE_ID;

      if (deviceResult.items && deviceResult.items.length > 0) {
        // 有真实设备
        let device = deviceResult.items[0];
        targetId = device.device_id;
        this.deviceName = device.name || device.device_id;
        this.deviceOnline = device.online;
        this.deviceLocation = device.location;

        // 用最新 telemetry 作为快照
        if (device.last_telemetry &&
            device.last_telemetry._ts !== undefined &&
            device.last_telemetry.temp !== undefined) {
          this.snapshot = device.last_telemetry;
        }
      } else {
        // 无设备 → 兜底
        this.deviceName = targetId;
        this.deviceOnline = false;
        this.isMockData = true;
      }

      this.deviceId = targetId;
      console.info(`[Dashboard] 使用设备: ${targetId}`);

      // 步骤 2：获取遥测历史
      let nowSec = Math.floor(Date.now() / 1000);
      let fromSec = nowSec - 86400; // 24 小时前

      let telemetryResult = await apiService.getTelemetry(targetId, fromSec, nowSec, 1, 200);

      if (!this.isMounted) { return; }

      if (telemetryResult.items && telemetryResult.items.length >= 2) {
        // 有真实历史数据
        this.telemetryHistory = telemetryResult.items;
        this.isMockData = false;

        // 若 snapshot 为空，用最后一条
        if (!this.snapshot) {
          this.snapshot = telemetryResult.items[telemetryResult.items.length - 1];
        }
        console.info(`[Dashboard] 获取到 ${telemetryResult.items.length} 条历史数据`);
      } else {
        // 无历史数据 → Mock 兜底
        this.isMockData = true;
        this.telemetryHistory = generateMockTelemetry(targetId);
        if (!this.snapshot) {
          this.snapshot = generateMockSnapshot();
        }
        console.info(`[Dashboard] 无历史数据，使用 Mock (${this.telemetryHistory.length} 点)`);
      }
    } catch (err) {
      console.error('[Dashboard] 数据加载失败:', JSON.stringify(err));
      // 异常兜底：全部 Mock
      if (this.isMounted) {
        this.deviceId = MOCK_DEVICE_ID;
        this.deviceName = MOCK_DEVICE_ID;
        this.deviceOnline = false;
        this.isMockData = true;
        this.snapshot = generateMockSnapshot();
        this.telemetryHistory = generateMockTelemetry(MOCK_DEVICE_ID);
      }
    }

    if (this.isMounted) {
      this.isLoading = false;
    }
  }

  // ====== 工具函数 ======

  getTempColor(temp: number): string {
    if (temp > 40) { return '#F44336'; }
    if (temp < 20) { return '#FF9800'; }
    return '#4CAF50';
  }

  getHumiColor(humi: number): string {
    if (humi > 80) { return '#FF9800'; }
    if (humi < 20) { return '#F44336'; }
    return '#2196F3';
  }

  getLuxColor(lux: number): string {
    if (lux > 800) { return '#FF9800'; }
    return '#9E9E9E';
  }

  getTiltColor(tilt: number): string {
    return tilt > 15000 ? '#F44336' : '#666';
  }

  formatTime(ts: number): string {
    if (!ts || ts <= 0) { return '--:--:--'; }
    let date = new Date(ts * 1000);
    return (
      `${date.getHours().toString().padStart(2, '0')}:` +
      `${date.getMinutes().toString().padStart(2, '0')}:` +
      `${date.getSeconds().toString().padStart(2, '0')}`
    );
  }

  // ====== 安全取值 ======

  safeVal(val: number | undefined | null, def: number): number {
    return (val != null && typeof val === 'number') ? val : def;
  }

  lastUpdated(ts: number): string {
    return ts > 0 ? this.formatTime(ts) : '--:--:--';
  }

  // ====== 构建 UI ======

  build() {
    Column() {
      // ---- 标题栏 ----
      Row() {
        PageTitle('仪表盘')
        Blank()
        Row() {
          Text('🔄')
            .fontSize(20)
            .onClick(() => {
              if (!this.isLoading) { this.fetchDashboardData(); }
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // ---- 加载 ----
      if (this.isLoading) {
        Text('加载中...')
          .fontSize(14).fontColor('#999').margin({ top: 40 })
      }

      // ---- 错误 ----
      if (this.errorText !== '') {
        Text(this.errorText)
          .fontSize(13).fontColor('#F44336')
          .padding(12).backgroundColor('#FFEBEE').borderRadius(8).width('100%')
      }

      // ---- 主体内容 ----
      if (!this.isLoading) {
        Scroll() {
          Column({ space: 12 }) {
            // ====== 设备信息栏 ======
            this.DeviceInfoBar()

            // ====== 四列指标卡片 ======
            Row({ space: 8 }) {
              this.MetricCard('温度', `${fmtTemp(this.snapshot)}℃`, '℃',
                '#FFF5F5', this.getTempColor(this.safeVal(this.snapshot?.temp, 0)))
              this.MetricCard('湿度', `${fmtHumi(this.snapshot)}%`, '%',
                '#F0F7FF', this.getHumiColor(this.safeVal(this.snapshot?.humi, 0)))
            }
            .width('100%')

            Row({ space: 8 }) {
              this.MetricCard('光照', `${fmtLux(this.snapshot)} lx`, 'lx',
                '#FFF8F0', this.getLuxColor(this.safeVal(this.snapshot?.lux, 0)))
              this.MetricCard('倾斜', `${this.safeVal(this.snapshot?.tilt, 0).toFixed(0)}`, '°',
                '#F5F5F5', this.getTiltColor(this.safeVal(this.snapshot?.tilt, 0)))
            }
            .width('100%')

            // ====== 折线图 Tab ======
            Column() {
              Text('📈 历史趋势（近 24 小时）')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')
                .margin({ top: 4, bottom: 8 })

              if (this.isMockData) {
                Text('⚠ 演示数据（无设备上报）')
                  .fontSize(11)
                  .fontColor('#FF9800')
                  .margin({ bottom: 4 })
              }

              // 图表内 Tab 切换
              Row() {
                this.ChartTab('全部', 0)
                this.ChartTab('仅温度', 1)
                this.ChartTab('仅湿度', 2)
                this.ChartTab('仅光照', 3)
              }
              .width('100%')
              .margin({ bottom: 4 })

              LineChart({
                data: this.telemetryHistory,
                showTemp: this.currentTabIndex === 0 || this.currentTabIndex === 1,
                showHumi: this.currentTabIndex === 0 || this.currentTabIndex === 2,
                showLux: this.currentTabIndex === 0 || this.currentTabIndex === 3
              })
            }
            .width('100%')
            .padding({ bottom: 16 })
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 12, right: 12 })
  }

  // ============================================================
  // @Builder：设备信息栏
  // ============================================================
  @Builder
  DeviceInfoBar() {
    Row() {
      Column() {
        Text(this.deviceName)
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
        if (this.deviceLocation) {
          Text(`📍 ${this.deviceLocation}`)
            .fontSize(12).fontColor('#999').margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Column() {
        Text(this.deviceOnline ? '🟢 在线' : '⚫ 离线')
          .fontSize(13)
          .fontColor(this.deviceOnline ? '#4CAF50' : '#999')
          .fontWeight(FontWeight.Bold)
        if (this.snapshot && this.snapshot._ts > 0) {
          Text(`更新 ${this.formatTime(this.snapshot._ts)}`)
            .fontSize(11).fontColor('#BBB').margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }

  // ============================================================
  // @Builder：指标卡片
  // ============================================================
  @Builder
  MetricCard(title: string, value: string, unit: string, bgColor: string, valColor: string) {
    Column() {
      Text(title)
        .fontSize(11)
        .fontColor('#999')
        .fontWeight(FontWeight.Medium)
      Row() {
        Text(value)
          .fontSize(22)
          .fontColor(valColor)
          .fontWeight(FontWeight.Bold)
        Text(unit)
          .fontSize(11)
          .fontColor('#999')
          .margin({ left: 2 })
      }
      .alignItems(VerticalAlign.Bottom)
      .margin({ top: 6 })
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(bgColor)
    .borderRadius(10)
    .border({ width: 1, color: '#00000008' })
  }

  // ============================================================
  // @Builder：图表 Tab 切换按钮
  // ============================================================
  @Builder
  ChartTab(label: string, index: number) {
    Text(label)
      .fontSize(12)
      .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.currentTabIndex === index ? '#1a73e8' : '#999')
      .padding({ left: 9, right: 9, top: 4, bottom: 4 })
      .backgroundColor(this.currentTabIndex === index ? '#E3F2FD' : '#F5F5F5')
      .borderRadius(16)
      .margin({ right: 6 })
      .onClick(() => { this.currentTabIndex = index; })
  }
}
