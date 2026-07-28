/**
 * 设备列表页面
 *
 * 拉取 GET /api/devices，展示所有冷链设备的概览卡片。
 * 手动点 🔄 刷新，带挂载安全检查。
 */

import { PageTitle } from '../components/CommonBuilders';
import { apiService, DeviceInfo, fmtTemp, fmtHumi, fmtLux, getAlarm, getAlarmReason, getTemp, getLux } from '../services/ApiService';

@Component
export struct DeviceListPage {
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State lastRefresh: string = '--:--:--';
  private isMounted: boolean = false;

  aboutToAppear(): void {
    this.isMounted = true;
    console.info('[DeviceList] aboutToAppear → 开始加载');
    this.fetchDevices();
  }

  aboutToDisappear(): void {
    this.isMounted = false;
    console.info('[DeviceList] aboutToDisappear → 已卸载');
  }

  async fetchDevices(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';
    console.info('[DeviceList] fetchDevices 发起请求...');

    try {
      let result = await apiService.getDevices(1, 50);

      // 阶段三：页面已销毁则忽略
      if (!this.isMounted) {
        console.warn('[DeviceList] 页面已销毁，忽略返回');
        return;
      }

      console.info(`[DeviceList] 返回: total=${result.total} items=${result.items ? result.items.length : 0}`);

      if (result.items && result.items.length > 0) {
        this.devices = result.items;
      }

      let now = new Date();
      this.lastRefresh =
        `${now.getHours().toString().padStart(2, '0')}:` +
        `${now.getMinutes().toString().padStart(2, '0')}:` +
        `${now.getSeconds().toString().padStart(2, '0')}`;
    } catch (err) {
      console.error('[DeviceList] 请求异常:', JSON.stringify(err));
      if (this.isMounted) {
        this.errorText = '加载失败：' + String((err as Error).message || '未知错误');
      }
    }

    if (this.isMounted) {
      this.isLoading = false;
    }
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
      if (this.devices.length === 0 && !this.isLoading) {
        Text('暂无设备数据')
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
  // @Builder：设备概览卡片 — 使用安全格式化函数
  // ============================================================
  @Builder
  DeviceCard(device: DeviceInfo) {
    Column({ space: 8 }) {
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

      if (device.location) {
        Text(`📍 ${device.location}`)
          .fontSize(12)
          .fontColor('#999')
      }

      Divider().color('#F0F0F0')

      Row() {
        Column() {
          Text('温度').fontSize(11).fontColor('#999')
          Text(`${fmtTemp(device.last_telemetry)}℃`)
            .fontSize(20)
            .fontColor(this.getTempColor(getTemp(device.last_telemetry)))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text('湿度').fontSize(11).fontColor('#999')
          Text(`${fmtHumi(device.last_telemetry)}%`)
            .fontSize(20)
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text('光照').fontSize(11).fontColor('#999')
          Text(`${fmtLux(device.last_telemetry)} lux`)
            .fontSize(20)
            .fontColor(this.getLuxColor(getLux(device.last_telemetry)))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        Column() {
          Text('告警').fontSize(11).fontColor('#999')
          Text(getAlarm(device.last_telemetry) === 1 ? '⚠️' : '✅')
            .fontSize(20)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')

      if (getAlarm(device.last_telemetry) === 1 && getAlarmReason(device.last_telemetry).length > 0) {
        Text(`告警: ${getAlarmReason(device.last_telemetry)}`)
          .fontSize(11)
          .fontColor('#F44336')
          .width('100%')
      }

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
