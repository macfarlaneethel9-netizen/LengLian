/**
 * 仓库状态页面
 *
 * 集中展示所有设备的温度、光照、湿度、倾斜，
 * 数据来源于后端 GET /api/devices，手动刷新。
 *
 * Tab：🌡️ 温度 / 💡 光照 / 💧 湿度 / 📐 倾斜
 */

import { PageTitle } from '../components/CommonBuilders';
import {
  apiService, DeviceInfo,
  fmtTemp, fmtHumi, fmtLux,
  getTemp, getHumi, getLux, getTilt,
  getAlarm, getAlarmReason
} from '../services/ApiService';

@Component
export struct WarehouseStatusPage {
  @State currentTabIndex: number = 0;
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State lastRefresh: string = '--:--:--';
  private isMounted: boolean = false;

  aboutToAppear(): void {
    this.isMounted = true;
    console.info('[WarehouseStatus] aboutToAppear → 开始加载');
    this.fetchDevices();
  }

  aboutToDisappear(): void {
    this.isMounted = false;
    console.info('[WarehouseStatus] aboutToDisappear → 已卸载');
  }

  async fetchDevices(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';
    console.info('[WarehouseStatus] fetchDevices 发起请求...');

    try {
      let result = await apiService.getDevices(1, 50);

      if (!this.isMounted) {
        console.warn('[WarehouseStatus] 页面已销毁，忽略返回');
        return;
      }

      console.info(`[WarehouseStatus] 返回: total=${result.total} items=${result.items ? result.items.length : 0}`);

      if (result.items && result.items.length > 0) {
        this.devices = result.items;
      }

      let now = new Date();
      this.lastRefresh =
        `${now.getHours().toString().padStart(2, '0')}:` +
        `${now.getMinutes().toString().padStart(2, '0')}:` +
        `${now.getSeconds().toString().padStart(2, '0')}`;
    } catch (err) {
      console.error('[WarehouseStatus] 请求异常:', JSON.stringify(err));
      if (this.isMounted) {
        this.errorText = '加载失败：' + String((err as Error).message || '未知错误');
      }
    }

    if (this.isMounted) {
      this.isLoading = false;
    }
  }

  // ---- 温度告警判断 ----
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

  // ---- 光照告警判断 ----
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

  // ---- 湿度告警判断 ----
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

  // ---- 倾斜告警判断 ----
  getTiltLevel(tilt: number): string {
    if (tilt > 15000) { return '倾斜告警'; }
    if (tilt > 8000)  { return '轻微倾斜'; }
    return '正常';
  }
  getTiltColor(tilt: number): string {
    if (tilt > 15000) { return '#F44336'; }
    if (tilt > 8000)  { return '#FF9800'; }
    return '#4CAF50';
  }
  getTiltRatio(tilt: number): number {
    return Math.min(tilt / 30000, 1);
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

      if (this.isLoading) {
        Text('加载中...')
          .fontSize(14).fontColor('#999').margin({ top: 40 })
      }

      if (this.errorText !== '') {
        Text(this.errorText)
          .fontSize(13).fontColor('#F44336')
          .padding(12).backgroundColor('#FFEBEE').borderRadius(8).width('100%')
      }

      if (this.devices.length === 0 && !this.isLoading) {
        Text('暂无设备数据')
          .fontSize(14).fontColor('#999').margin({ top: 40 })
      }

      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() { this.TemperatureCard(device) }
              })
            }
            .width('100%').layoutWeight(1).scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabLabel('🌡️ 温度', 0))

        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() { this.LightCard(device) }
              })
            }
            .width('100%').layoutWeight(1).scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabLabel('💡 光照', 1))

        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() { this.HumidityCard(device) }
              })
            }
            .width('100%').layoutWeight(1).scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabLabel('💧 湿度', 2))

        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() { this.TiltCard(device) }
              })
            }
            .width('100%').layoutWeight(1).scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabLabel('📐 倾斜', 3))
      }
      .width('100%').layoutWeight(1).backgroundColor('#F5F5F5').barMode(BarMode.Fixed)
      .onChange((index: number) => { this.currentTabIndex = index; })
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }

  @Builder TabLabel(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? '#1a73e8' : '#666')
        .padding({ top: 12, bottom: 12 })
    }
    .width('100%')
    .border({ width: { bottom: this.currentTabIndex === index ? 2 : 0 }, color: '#1a73e8' })
  }

  // ---- 温度卡片 ----
  @Builder TemperatureCard(device: DeviceInfo) {
    Column({ space: 10 }) {
      Row() {
        Text(device.name || device.device_id).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        Text(device.online ? '在线' : '离线')
          .fontSize(11).fontColor(device.online ? '#4CAF50' : '#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(device.online ? '#E8F5E9' : '#F5F5F5').borderRadius(4)
      }.width('100%')

      Row() {
        Column() {
          Text('当前温度').fontSize(12).fontColor('#999')
          Text(`${fmtTemp(device.last_telemetry)} ℃`)
            .fontSize(36).fontColor(this.getTempColor(getTemp(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }
        Blank()
        Column() {
          Text('温度状态').fontSize(12).fontColor('#999')
          Text(this.getTempLevel(getTemp(device.last_telemetry)))
            .fontSize(14).fontColor(this.getTempColor(getTemp(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }.alignItems(HorizontalAlign.End)
      }.width('100%')

      Row() {
        Text('0℃').fontSize(10).fontColor('#999')
        Column() {}.layoutWeight(1).height(6).backgroundColor('#E0E0E0').borderRadius(3).margin({ left: 8, right: 8 })
        Text('12℃').fontSize(10).fontColor('#999')
      }.width('100%')

      if (getAlarm(device.last_telemetry) === 1 && getAlarmReason(device.last_telemetry).length > 0) {
        Row() {
          Text('⚠️').fontSize(14)
          Text(getAlarmReason(device.last_telemetry)).fontSize(13).fontColor('#F44336').margin({ left: 4 })
        }.width('100%').padding(10).backgroundColor('#FFF3F0').borderRadius(8)
      }

      Text(`更新: ${this.formatTime(device.last_seen)}`)
        .fontSize(11).fontColor('#BBB').width('100%').textAlign(TextAlign.End)
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }

  // ---- 光照卡片 ----
  @Builder LightCard(device: DeviceInfo) {
    Column({ space: 10 }) {
      Row() {
        Text(device.name || device.device_id).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        Text(device.online ? '在线' : '离线')
          .fontSize(11).fontColor(device.online ? '#4CAF50' : '#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(device.online ? '#E8F5E9' : '#F5F5F5').borderRadius(4)
      }.width('100%')

      Row() {
        Column() {
          Text('当前光照').fontSize(12).fontColor('#999')
          Text(`${fmtLux(device.last_telemetry)} lux`)
            .fontSize(36).fontColor(this.getLuxColor(getLux(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }
        Blank()
        Column() {
          Text('光照状态').fontSize(12).fontColor('#999')
          Text(this.getLuxLevel(getLux(device.last_telemetry)))
            .fontSize(14).fontColor(this.getLuxColor(getLux(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }.alignItems(HorizontalAlign.End)
      }.width('100%')

      Row() {
        Text('暗').fontSize(10).fontColor('#999')
        Column() {}.layoutWeight(1).height(6).backgroundColor('#E0E0E0').borderRadius(3).margin({ left: 8, right: 8 })
        Text('亮').fontSize(10).fontColor('#999')
      }.width('100%')

      Text(`更新: ${this.formatTime(device.last_seen)}`)
        .fontSize(11).fontColor('#BBB').width('100%').textAlign(TextAlign.End)
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }

  // ---- 湿度卡片 ----
  @Builder HumidityCard(device: DeviceInfo) {
    Column({ space: 10 }) {
      Row() {
        Text(device.name || device.device_id).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        Text(device.online ? '在线' : '离线')
          .fontSize(11).fontColor(device.online ? '#4CAF50' : '#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(device.online ? '#E8F5E9' : '#F5F5F5').borderRadius(4)
      }.width('100%')

      Row() {
        Column() {
          Text('当前湿度').fontSize(12).fontColor('#999')
          Text(`${fmtHumi(device.last_telemetry)}%`)
            .fontSize(36).fontColor(this.getHumiColor(getHumi(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }
        Blank()
        Column() {
          Text('湿度状态').fontSize(12).fontColor('#999')
          Text(this.getHumiLevel(getHumi(device.last_telemetry)))
            .fontSize(14).fontColor(this.getHumiColor(getHumi(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }.alignItems(HorizontalAlign.End)
      }.width('100%')

      Row() {
        Text('0%').fontSize(10).fontColor('#999')
        Column() {}.layoutWeight(1).height(6).backgroundColor('#E0E0E0').borderRadius(3).margin({ left: 8, right: 8 })
        Text('100%').fontSize(10).fontColor('#999')
      }.width('100%')

      Row() {
        Text('附带温度').fontSize(12).fontColor('#999')
        Text(`${fmtTemp(device.last_telemetry)}℃`)
          .fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(this.getTempColor(getTemp(device.last_telemetry)))
          .margin({ left: 8 })
      }

      if (getAlarm(device.last_telemetry) === 1 && getAlarmReason(device.last_telemetry).length > 0) {
        Row() {
          Text('⚠️').fontSize(14)
          Text(getAlarmReason(device.last_telemetry)).fontSize(13).fontColor('#F44336').margin({ left: 4 })
        }.width('100%').padding(10).backgroundColor('#FFF3F0').borderRadius(8)
      }

      Text(`更新: ${this.formatTime(device.last_seen)}`)
        .fontSize(11).fontColor('#BBB').width('100%').textAlign(TextAlign.End)
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }

  // ---- 倾斜卡片 ----
  @Builder TiltCard(device: DeviceInfo) {
    Column({ space: 10 }) {
      Row() {
        Text(device.name || device.device_id).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        Text(device.online ? '在线' : '离线')
          .fontSize(11).fontColor(device.online ? '#4CAF50' : '#999')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(device.online ? '#E8F5E9' : '#F5F5F5').borderRadius(4)
      }.width('100%')

      Row() {
        Column() {
          Text('当前倾斜').fontSize(12).fontColor('#999')
          Text(`${getTilt(device.last_telemetry).toFixed(0)}`)
            .fontSize(36).fontColor(this.getTiltColor(getTilt(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }
        Blank()
        Column() {
          Text('倾斜状态').fontSize(12).fontColor('#999')
          Text(this.getTiltLevel(getTilt(device.last_telemetry)))
            .fontSize(14).fontColor(this.getTiltColor(getTilt(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 4 })
        }.alignItems(HorizontalAlign.End)
      }.width('100%')

      // 倾斜进度条
      Row() {
        Text('0').fontSize(10).fontColor('#999')
        Column() {}.layoutWeight(1).height(6).backgroundColor('#E0E0E0').borderRadius(3).margin({ left: 8, right: 8 })
        Text('30000').fontSize(10).fontColor('#999')
      }.width('100%')

      // 倾斜量可视化：根据数值填充进度条
      Row() {
        Text('倾斜量').fontSize(12).fontColor('#999')
        Text(`${getTilt(device.last_telemetry).toFixed(0)}`)
          .fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(this.getTiltColor(getTilt(device.last_telemetry)))
          .margin({ left: 8 })
        Blank()
        // 倾斜比例条
        Row() {
          Column() {}
            .width(`${(this.getTiltRatio(getTilt(device.last_telemetry)) * 100).toFixed(0)}%`)
            .height(8)
            .backgroundColor(this.getTiltColor(getTilt(device.last_telemetry)))
            .borderRadius(4)
          Column() {}.layoutWeight(1)
        }
        .width(80).height(8).backgroundColor('#F0F0F0').borderRadius(4)
      }.width('100%')

      if (getAlarm(device.last_telemetry) === 1 && getAlarmReason(device.last_telemetry).length > 0) {
        Row() {
          Text('⚠️').fontSize(14)
          Text(getAlarmReason(device.last_telemetry)).fontSize(13).fontColor('#F44336').margin({ left: 4 })
        }.width('100%').padding(10).backgroundColor('#FFF3F0').borderRadius(8)
      }

      Text(`更新: ${this.formatTime(device.last_seen)}`)
        .fontSize(11).fontColor('#BBB').width('100%').textAlign(TextAlign.End)
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF').borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }
}
