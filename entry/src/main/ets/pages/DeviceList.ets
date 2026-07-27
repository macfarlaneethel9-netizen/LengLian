/**
 * 设备列表页面 — 独立模块
 *
 * 拉取 GET /api/devices，展示所有冷链设备的概览卡片。
 * 每张卡片显示：名称、在线状态、温度、湿度、光照、告警、位置、更新时间。
 */

import { PageTitle } from '../components/CommonBuilders';
import { apiService, DeviceInfo } from '../services/ApiService';

@Component
export struct DeviceListPage {
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State lastRefresh: string = '--:--:--';

  aboutToAppear(): void {
    this.fetchDevices();
  }

  async fetchDevices(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';
    try {
      let result = await apiService.getDevices(1, 50);
      this.devices = result.items;
      let now = new Date();
      this.lastRefresh =
        `${now.getHours().toString().padStart(2, '0')}:` +
        `${now.getMinutes().toString().padStart(2, '0')}:` +
        `${now.getSeconds().toString().padStart(2, '0')}`;
    } catch (err) {
      this.errorText = '加载失败：' + String((err as Error).message || '未知错误');
    }
    this.isLoading = false;
  }

  getTempColor(temp: number): string {
    if (temp > 8) { return '#F44336'; }
    if (temp < 2) { return '#FF9800'; }
    return '#4CAF50';
  }

  getLuxColor(lux: number): string {
    if (lux > 200) { return '#FF9800'; }
    if (lux < 50)  { return '#9E9E9E'; }
    return '#4CAF50';
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

  build() {
    Column() {
      // ---- 标题栏 ----
      Row() {
        PageTitle('设备列表')
        Blank()
        Row() {
          Text('🔄')
            .fontSize(20)
            .onClick(() => {
              if (!this.isLoading) { this.fetchDevices(); }
            })
          Text(`${this.devices.length} 个设备`)
            .fontSize(12)
            .fontColor('#999')
            .margin({ left: 6 })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // ---- 加载 ----
      if (this.isLoading) {
        Text('加载中...')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 40 })
      }

      // ---- 错误 ----
      if (this.errorText !== '') {
        Text(this.errorText)
          .fontSize(13)
          .fontColor('#F44336')
          .padding(12)
          .backgroundColor('#FFEBEE')
          .borderRadius(8)
          .width('100%')
      }

      // ---- 空数据 ----
      if (this.devices.length === 0 && !this.isLoading && this.errorText === '') {
        Text('暂无设备，请先添加设备')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 40 })
      }

      // ---- 设备卡片列表 ----
      if (this.devices.length > 0) {
        List({ space: 12 }) {
          ForEach(this.devices, (device: DeviceInfo) => {
            ListItem() {
              this.DeviceCard(device)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .padding({ top: 8, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }

  // ============================================================
  // @Builder：设备概览卡片
  // ============================================================
  @Builder
  DeviceCard(device: DeviceInfo) {
    Column({ space: 8 }) {
      // 名称 + 在线
      Row() {
        Text(device.name || device.device_id)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Blank()
        Text(device.online ? '🟢 在线' : '⚫ 离线')
          .fontSize(12)
          .fontColor(device.online ? '#4CAF50' : '#999')
      }
      .width('100%')

      // 位置
      if (device.location) {
        Text(`📍 ${device.location}`)
          .fontSize(12)
          .fontColor('#999')
      }

      Divider().color('#F0F0F0')

      // 四列遥测
      Row() {
        Column() {
          Text('温度').fontSize(11).fontColor('#999')
          Text(`${device.last_telemetry.temp.toFixed(1)}℃`)
            .fontSize(20)
            .fontColor(this.getTempColor(device.last_telemetry.temp))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text('湿度').fontSize(11).fontColor('#999')
          Text(`${device.last_telemetry.humi.toFixed(1)}%`)
            .fontSize(20)
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text('光照').fontSize(11).fontColor('#999')
          Text(`${device.last_telemetry.lux.toFixed(0)} lux`)
            .fontSize(20)
            .fontColor(this.getLuxColor(device.last_telemetry.lux))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text('告警').fontSize(11).fontColor('#999')
          Text(device.last_telemetry.alarm === 1 ? '⚠️' : '✅')
            .fontSize(20)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 告警原因
      if (device.last_telemetry.alarm === 1 && device.last_telemetry.alarm_reason) {
        Text(`告警: ${device.last_telemetry.alarm_reason}`)
          .fontSize(11)
          .fontColor('#F44336')
          .width('100%')
      }

      // 更新时间
      Text(`更新: ${this.formatTime(device.last_seen)}`)
        .fontSize(11)
        .fontColor('#BBB')
        .width('100%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }
}
