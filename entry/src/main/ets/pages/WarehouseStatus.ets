/**
 * 仓库状态页面
 *
 * 用一个页面集中展示仓库内所有设备的温度、光照、湿度，
 * 数据来源于后端 GET /api/devices，按 Tab 分维度查看。
 *
 * Tab 布局：
 *   Tab 0：温度监控   — 各设备温度 + 告警
 *   Tab 1：光照监控   — 各设备光照 + 倾斜
 *   Tab 2：湿度监控   — 各设备湿度
 */

import { PageTitle } from '../components/CommonBuilders';
import { apiService, DeviceInfo } from '../services/ApiService';

@Component
export struct WarehouseStatusPage {
  @State currentTabIndex: number = 0;
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

  // ---- 温度判断 ----
  getTempLevel(temp: number): string {
    if (temp > 8) { return '高温告警'; }
    if (temp < 2) { return '低温告警'; }
    return '正常';
  }

  getTempColor(temp: number): string {
    if (temp > 8) { return '#F44336'; }
    if (temp < 2) { return '#FF9800'; }
    return '#4CAF50';
  }

  // ---- 光照判断 ----
  getLuxLevel(lux: number): string {
    if (lux > 200) { return '过亮'; }
    if (lux < 50)  { return '偏暗'; }
    return '正常';
  }

  getLuxColor(lux: number): string {
    if (lux > 200) { return '#FF9800'; }
    if (lux < 50)  { return '#9E9E9E'; }
    return '#4CAF50';
  }

  // ---- 湿度判断 ----
  getHumiLevel(humi: number): string {
    if (humi > 80) { return '湿度过高'; }
    if (humi < 20) { return '湿度过低'; }
    return '正常';
  }

  getHumiColor(humi: number): string {
    if (humi > 80) { return '#FF9800'; }
    if (humi < 20) { return '#F44336'; }
    return '#2196F3';
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
        PageTitle('仓库状态')
        Blank()
        Row() {
          Text('🔄')
            .fontSize(20)
            .onClick(() => {
              if (!this.isLoading) { this.fetchDevices(); }
            })
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
        Text('暂无设备数据')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 40 })
      }

      // ---- Tabs ----
      Tabs({ barPosition: BarPosition.Start }) {
        // ====== Tab 0：温度监控 ======
        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() {
                  this.TemperatureCard(device)
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabBarLabel('🌡️ 温度', 0))

        // ====== Tab 1：光照监控 ======
        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() {
                  this.LightCard(device)
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabBarLabel('💡 光照', 1))

        // ====== Tab 2：湿度监控 ======
        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() {
                  this.HumidityCard(device)
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabBarLabel('💧 湿度', 2))
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }

  // ============================================================
  // @Builder：Tab 标签
  // ============================================================
  @Builder
  TabBarLabel(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? '#1a73e8' : '#666')
        .padding({ top: 12, bottom: 12 })
    }
    .width('100%')
    .border({
      width: { bottom: this.currentTabIndex === index ? 2 : 0 },
      color: '#1a73e8'
    })
  }

  // ============================================================
  // @Builder：温度监控卡片
  // ============================================================
  @Builder
  TemperatureCard(device: DeviceInfo) {
    Column({ space: 10 }) {
      Row() {
        Text(device.name || device.device_id)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Blank()
        Text(device.online ? '在线' : '离线')
          .fontSize(11)
          .fontColor(device.online ? '#4CAF50' : '#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(device.online ? '#E8F5E9' : '#F5F5F5')
          .borderRadius(4)
      }
      .width('100%')

      Row() {
        Column() {
          Text('当前温度').fontSize(12).fontColor('#999')
          Text(`${device.last_telemetry.temp.toFixed(1)} ℃`)
            .fontSize(36)
            .fontColor(this.getTempColor(device.last_telemetry.temp))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        Blank()
        Column() {
          Text('温度状态').fontSize(12).fontColor('#999')
          Text(this.getTempLevel(device.last_telemetry.temp))
            .fontSize(14)
            .fontColor(this.getTempColor(device.last_telemetry.temp))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      Row() {
        Text('0℃').fontSize(10).fontColor('#999')
        Column() {}
        .layoutWeight(1)
        .height(6)
        .backgroundColor('#E0E0E0')
        .borderRadius(3)
        .margin({ left: 8, right: 8 })
        Text('12℃').fontSize(10).fontColor('#999')
      }
      .width('100%')

      if (device.last_telemetry.alarm === 1 && device.last_telemetry.alarm_reason) {
        Row() {
          Text('⚠️').fontSize(14)
          Text(device.last_telemetry.alarm_reason)
            .fontSize(13)
            .fontColor('#F44336')
            .margin({ left: 4 })
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF3F0')
        .borderRadius(8)
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

  // ============================================================
  // @Builder：光照监控卡片
  // ============================================================
  @Builder
  LightCard(device: DeviceInfo) {
    Column({ space: 10 }) {
      Row() {
        Text(device.name || device.device_id)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Blank()
        Text(device.online ? '在线' : '离线')
          .fontSize(11)
          .fontColor(device.online ? '#4CAF50' : '#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(device.online ? '#E8F5E9' : '#F5F5F5')
          .borderRadius(4)
      }
      .width('100%')

      Row() {
        Column() {
          Text('当前光照').fontSize(12).fontColor('#999')
          Text(`${device.last_telemetry.lux.toFixed(0)} lux`)
            .fontSize(36)
            .fontColor(this.getLuxColor(device.last_telemetry.lux))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        Blank()
        Column() {
          Text('光照状态').fontSize(12).fontColor('#999')
          Text(this.getLuxLevel(device.last_telemetry.lux))
            .fontSize(14)
            .fontColor(this.getLuxColor(device.last_telemetry.lux))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      Row() {
        Text('暗').fontSize(10).fontColor('#999')
        Column() {}
        .layoutWeight(1)
        .height(6)
        .backgroundColor('#E0E0E0')
        .borderRadius(3)
        .margin({ left: 8, right: 8 })
        Text('亮').fontSize(10).fontColor('#999')
      }
      .width('100%')

      Row() {
        Text('倾斜量').fontSize(12).fontColor('#999')
        Text(`${device.last_telemetry.tilt.toFixed(0)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(device.last_telemetry.tilt > 15000 ? '#F44336' : '#333')
          .margin({ left: 8 })
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

  // ============================================================
  // @Builder：湿度监控卡片
  // ============================================================
  @Builder
  HumidityCard(device: DeviceInfo) {
    Column({ space: 10 }) {
      Row() {
        Text(device.name || device.device_id)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        Blank()
        Text(device.online ? '在线' : '离线')
          .fontSize(11)
          .fontColor(device.online ? '#4CAF50' : '#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(device.online ? '#E8F5E9' : '#F5F5F5')
          .borderRadius(4)
      }
      .width('100%')

      Row() {
        Column() {
          Text('当前湿度').fontSize(12).fontColor('#999')
          Text(`${device.last_telemetry.humi.toFixed(1)}%`)
            .fontSize(36)
            .fontColor(this.getHumiColor(device.last_telemetry.humi))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        Blank()
        Column() {
          Text('湿度状态').fontSize(12).fontColor('#999')
          Text(this.getHumiLevel(device.last_telemetry.humi))
            .fontSize(14)
            .fontColor(this.getHumiColor(device.last_telemetry.humi))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      Row() {
        Text('0%').fontSize(10).fontColor('#999')
        Column() {}
        .layoutWeight(1)
        .height(6)
        .backgroundColor('#E0E0E0')
        .borderRadius(3)
        .margin({ left: 8, right: 8 })
        Text('100%').fontSize(10).fontColor('#999')
      }
      .width('100%')

      // 附带温度和告警信息
      Row() {
        Text('附带温度').fontSize(12).fontColor('#999')
        Text(`${device.last_telemetry.temp.toFixed(1)}℃`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTempColor(device.last_telemetry.temp))
          .margin({ left: 8 })
      }

      if (device.last_telemetry.alarm === 1 && device.last_telemetry.alarm_reason) {
        Row() {
          Text('⚠️').fontSize(14)
          Text(device.last_telemetry.alarm_reason)
            .fontSize(13)
            .fontColor('#F44336')
            .margin({ left: 4 })
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF3F0')
        .borderRadius(8)
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
