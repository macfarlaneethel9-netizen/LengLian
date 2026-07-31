/**
 * 仓库开关管理 — 硬件控制面板
 *
 * ============================================================
 * 命令下发链路（点击按钮 → 硬件响应）：
 * ============================================================
 *
 *   App 按钮点击
 *     → sendCommand()
 *     → POST /api/devices/{id}/cmd     (后端 REST API)
 *     → 后端转发到华为云 IoT              (AMQP / MQTT)
 *     → 华为云下发到 RK2206 通晓开发板    (MQTT)
 *     → 开发板 GPIO 驱动
 *     → 电机转动 / LED 亮灭
 *
 * ============================================================
 * 控制功能：
 * ============================================================
 *   灯光（💡 LED）     — 对应硬件 LED 灯，可开关
 *   大门（🚪 电机）    — 对应硬件电机驱动，脉冲式开/关锁
 *   空调（❄️ 制冷）    — 冷链仓库制冷设备开关
 *   设定温度           — 冷链系统目标温度
 *   温度阈值           — 温度告警上下限
 *   湿度阈值           — 湿度告警上下限
 *   光照阈值           — 光照告警上限
 *   倾斜阈值           — 倾斜告警上限
 */

import { PageTitle } from '../components/CommonBuilders';
import { apiService, DeviceInfo } from '../services/ApiService';
import { realtimeService } from '../services/RealtimeService';

// ================================================================
// 命令体类型 — 字段名对齐华为云 IoTDA 设备影子
// ================================================================
// light = 灯    motor = 门锁   ac  = 空调   auto = 自动模式
// tm    = 温度阈值   hu   = 湿度阈值
// lig   = 光照阈值   lncli = 倾斜阈值
// de    = 清除告警   all  = 紧急全关
// ================================================================

class LightCmd {
  light: number;
  constructor(on: boolean) { this.light = on ? 1 : 0; }
}

class MotorCmd {
  motor: number;
  constructor(open: boolean) { this.motor = open ? 80 : 0; }
}

class AcCmd {
  ac: number;
  constructor(on: boolean) { this.ac = on ? 1 : 0; }
}

class AutoCmd {
  auto: number;
  constructor(on: boolean) { this.auto = on ? 1 : 0; }
}

class TmCmd {
  tm: number;
  constructor(on: boolean) { this.tm = on ? 1 : 0; }
}

class HuCmd {
  hu: number;
  constructor(on: boolean) { this.hu = on ? 1 : 0; }
}

class LigCmd {
  lig: number;
  constructor(on: boolean) { this.lig = on ? 1 : 0; }
}

class IncliCmd {
  lncli: number;
  constructor(on: boolean) { this.lncli = on ? 1 : 0; }
}

class ClearAlarmCmd {
  de: number;
  constructor() { this.de = 1; }
}

class EmergencyCmd {
  all: number;
  constructor() { this.all = 1; }
}

@Component
export struct WarehouseSwitchPage {
  // ------ 设备列表 ------
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State selectedIndex: number = 0;

  // ------ 灯光状态 ------
  @State lightOn: boolean = false;

  // ------ 大门状态 ------
  @State doorOpen: boolean = false;

  // ------ 空调状态 ------
  @State acOn: boolean = false;

  // ------ 自动模式 ------
  @State autoOn: boolean = false;

  // ------ 阈值开关 ------
  @State tmOn: boolean = true;
  @State huOn: boolean = true;
  @State ligOn: boolean = true;
  @State incliOn: boolean = true;

  // ------ 反馈消息 ------
  @State okText: string = '';
  @State errorText: string = '';
  @State sendingLabel: string = '';    // 哪个按钮正在发送

  aboutToAppear(): void {
    this.fetchDevices();

    // 订阅实时推送，保持设备列表和状态最新
    realtimeService.onUpdate((devices: DeviceInfo[]) => {
      this.devices = devices;
      // 从最新遥测同步电机状态
      let d = this.curDevice();
      if (d) {
        this.doorOpen = d.last_telemetry.motor === 1;
      }
    });
    realtimeService.start(3000);
  }

  aboutToDisappear(): void {
    realtimeService.stop();
  }

  async fetchDevices(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';
    try {
      let result = await apiService.getDevices(1, 50);
      this.devices = result.items;
      // 从最新遥测数据同步状态
      if (this.devices.length > 0) {
        let t = this.devices[0].last_telemetry;
        this.lightOn = false;       // LED 状态不直接包含在遥测中
        this.doorOpen = t.motor === 1;
      }
    } catch (err) {
      this.errorText = '加载设备失败：' + String((err as Error).message || '');
    }
    this.isLoading = false;
  }

  // ------ 安全取当前设备（避免 ?. 渲染问题）------
  private curDevice(): DeviceInfo | null {
    if (this.devices.length === 0) { return null; }
    if (this.selectedIndex < 0) { return null; }
    if (this.selectedIndex >= this.devices.length) { return null; }
    return this.devices[this.selectedIndex];
  }

  curName(): string {
    let d = this.curDevice();
    if (d) {
      if (d.name && d.name.length > 0) { return d.name; }
      if (d.device_id && d.device_id.length > 0) { return d.device_id; }
    }
    return '--';
  }

  curId(): string {
    let d = this.curDevice();
    return (d && d.device_id) ? d.device_id : '--';
  }

  curLoc(): string {
    let d = this.curDevice();
    return (d && d.location) ? d.location : '';
  }

  curOnline(): boolean {
    let d = this.curDevice();
    return d ? d.online : false;
  }

  curTemp(): string {
    let d = this.curDevice();
    if (d && d.last_telemetry && typeof d.last_telemetry.temp === 'number') {
      return d.last_telemetry.temp.toFixed(1);
    }
    return '--';
  }

  curHumi(): string {
    let d = this.curDevice();
    if (d && d.last_telemetry && typeof d.last_telemetry.humi === 'number') {
      return d.last_telemetry.humi.toFixed(1);
    }
    return '--';
  }

  curLux(): string {
    let d = this.curDevice();
    if (d && d.last_telemetry && typeof d.last_telemetry.lux === 'number') {
      return d.last_telemetry.lux.toFixed(0);
    }
    return '--';
  }

  // ------ 发送命令 ------
  async sendCommand(cmd: object, label: string): Promise<void> {
    let d = this.curDevice();
    if (!d) { return; }
    let deviceId = d.device_id;
    this.sendingLabel = label;
    this.errorText = '';
    this.okText = '';
    try {
      await apiService.sendCommand(deviceId, cmd);
      console.info('[WarehouseSwitch]', label, '→', deviceId);
      this.okText = `✅ ${label} → 已通过华为云下发到 ${deviceId}`;
    } catch (err) {
      this.errorText = `❌ ${label} 失败：` + String((err as Error).message || '');
    }
    this.sendingLabel = '';
    // 3秒后自动清除提示
    setTimeout(() => { this.okText = ''; }, 3000);
  }

  // ------ 灯光开关 ------
  toggleLight(): void {
    this.lightOn = !this.lightOn;
    this.sendCommand(new LightCmd(this.lightOn), this.lightOn ? '开灯' : '关灯');
  }

  // ------ 大门开关 ------
  toggleDoor(): void {
    this.doorOpen = !this.doorOpen;
    this.sendCommand(new MotorCmd(this.doorOpen), this.doorOpen ? '开门' : '关门');
  }

  // ------ 空调开关 ------
  toggleAc(): void {
    this.acOn = !this.acOn;
    this.sendCommand(new AcCmd(this.acOn), this.acOn ? '开空调' : '关空调');
  }

  // ------ 自动模式 ------
  toggleAuto(): void {
    this.autoOn = !this.autoOn;
    this.sendCommand(new AutoCmd(this.autoOn), this.autoOn ? '开启自动模式' : '关闭自动模式');
  }


  build() {
    Column() {
      PageTitle('仓库开关管理')

      if (this.isLoading) {
        Text('加载设备列表...').fontSize(14).fontColor('#999').margin({ top: 40 })
      } else if (this.devices.length === 0) {
        Text('暂无设备').fontSize(14).fontColor('#999').margin({ top: 40 })
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // ====== 设备选择器（明确显示当前管理的设备） ======
            Column() {
              Row() {
                Text('←').fontSize(28).fontColor(this.selectedIndex > 0 ? '#1a73e8' : '#CCC')
                  .onClick(() => { if (this.selectedIndex > 0) { this.selectedIndex--; } })
                Column() {
                  Text('正在管理: ' + this.curName())
                    .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
                  Text('设备ID: ' + this.curId())
                    .fontSize(12).fontColor('#666').margin({ top: 2 })
                  if (this.curLoc() !== '') {
                    Text('📍 ' + this.curLoc())
                      .fontSize(11).fontColor('#999').margin({ top: 1 })
                  }
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Center)
                Text('→').fontSize(28).fontColor(this.selectedIndex < this.devices.length - 1 ? '#1a73e8' : '#CCC')
                  .onClick(() => { if (this.selectedIndex < this.devices.length - 1) { this.selectedIndex++; } })
              }.width('100%')

              // 当前设备实时数值
              Row({ space: 12 }) {
                Text((this.selectedIndex + 1) + '/' + this.devices.length)
                  .fontSize(11).fontColor('#999')
                Circle().width(8).height(8)
                  .fill(this.curOnline() ? '#4CAF50' : '#BDBDBD')
                Text(this.curOnline() ? '在线' : '离线')
                  .fontSize(11).fontColor(this.curOnline() ? '#4CAF50' : '#999')
                Text('|').fontSize(11).fontColor('#E0E0E0')
                Text('🌡 ' + this.curTemp() + '℃')
                  .fontSize(11).fontColor('#F44336')
                Text('💧 ' + this.curHumi() + '%')
                  .fontSize(11).fontColor('#2196F3')
                Text('💡 ' + this.curLux() + ' lx')
                  .fontSize(11).fontColor('#FF9800')
              }
              .width('100%').margin({ top: 8 })
            }
            .width('100%').padding(14)
            .backgroundColor('#FFFFFF').borderRadius(12)
            .shadow({ radius: 4, color: '#00000008', offsetY: 2 })

            // ====== 反馈消息 ======
            if (this.okText !== '') {
              Text(this.okText)
                .fontSize(13).fontColor('#2E7D32')
                .padding(12).backgroundColor('#E8F5E9').borderRadius(8).width('100%')
            }
            if (this.errorText !== '') {
              Text(this.errorText)
                .fontSize(13).fontColor('#C62828')
                .padding(12).backgroundColor('#FFEBEE').borderRadius(8).width('100%')
            }

            // ================================================================
            // 三大开关控制
            // ================================================================

            // ---- 灯光控制 ----
            Row() {
              Column() {
                Text('💡')
                  .fontSize(48)
                Text('灯光')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
                  .margin({ top: 4 })
                Text(this.lightOn ? '已开启' : '已关闭')
                  .fontSize(13).fontColor(this.lightOn ? '#FF9800' : '#999')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Center)
              .width(100)

              Column() {
                Text('控制仓库照明，下达 LED 指令')
                  .fontSize(12).fontColor('#999')
                  .margin({ bottom: 10 })

                Toggle({ type: ToggleType.Switch, isOn: this.lightOn })
                  .selectedColor('#FF9800')
                  .onChange((isOn: boolean) => {
                    this.lightOn = isOn;
                    this.sendCommand(new LightCmd(isOn), isOn ? '开灯' : '关灯');
                  })
              }
              .layoutWeight(1).alignItems(HorizontalAlign.End)
            }
            .width('100%').padding(20)
            .backgroundColor('#FFFFFF').borderRadius(16)
            .shadow({ radius: 6, color: '#0000000A', offsetY: 3 })

            // ---- 大门控制 ----
            Row() {
              Column() {
                Text('🚪')
                  .fontSize(48)
                Text('大门')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
                  .margin({ top: 4 })
                Text(this.doorOpen ? '已打开' : '已关闭')
                  .fontSize(13).fontColor(this.doorOpen ? '#4CAF50' : '#999')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Center)
              .width(100)

              Column() {
                Text('控制仓库门锁，驱动电机')
                  .fontSize(12).fontColor('#999')
                  .margin({ bottom: 10 })

                Row({ space: 12 }) {
                  Button('关门')
                    .fontSize(14).height(40).width(80)
                    .backgroundColor(this.doorOpen ? '#E0E0E0' : '#607D8B')
                    .fontColor(this.doorOpen ? '#999' : '#FFFFFF')
                    .borderRadius(20)
                    .onClick(() => {
                      if (this.doorOpen) {
                        this.doorOpen = false;
                        this.sendCommand(new MotorCmd(false), '关门');
                      }
                    })

                  Button('开门')
                    .fontSize(14).height(40).width(80)
                    .backgroundColor(this.doorOpen ? '#4CAF50' : '#E0E0E0')
                    .fontColor(this.doorOpen ? '#FFFFFF' : '#999')
                    .borderRadius(20)
                    .onClick(() => {
                      if (!this.doorOpen) {
                        this.doorOpen = true;
                        this.sendCommand(new MotorCmd(true), '开门');
                      }
                    })
                }
              }
              .layoutWeight(1).alignItems(HorizontalAlign.End)
            }
            .width('100%').padding(20)
            .backgroundColor('#FFFFFF').borderRadius(16)
            .shadow({ radius: 6, color: '#0000000A', offsetY: 3 })

            // ---- 空调控制 ----
            Row() {
              Column() {
                Text('❄️')
                  .fontSize(48)
                Text('空调')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
                  .margin({ top: 4 })
                Text(this.acOn ? '已开启' : '已关闭')
                  .fontSize(13).fontColor(this.acOn ? '#2196F3' : '#999')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Center)
              .width(100)

              Column() {
                Text('冷链仓库制冷设备控制')
                  .fontSize(12).fontColor('#999')
                  .margin({ bottom: 10 })

                Toggle({ type: ToggleType.Switch, isOn: this.acOn })
                  .selectedColor('#2196F3')
                  .onChange((isOn: boolean) => {
                    this.acOn = isOn;
                    this.sendCommand(new AcCmd(isOn), isOn ? '开空调' : '关空调');
                  })
              }
              .layoutWeight(1).alignItems(HorizontalAlign.End)
            }
            .width('100%').padding(20)
            .backgroundColor('#FFFFFF').borderRadius(16)
            .shadow({ radius: 6, color: '#0000000A', offsetY: 3 })

            // ---- 自动模式 ----
            Row() {
              Column() {
                Text('🤖')
                  .fontSize(48)
                Text('自动模式')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
                  .margin({ top: 4 })
                Text(this.autoOn ? '已开启' : '已关闭')
                  .fontSize(13).fontColor(this.autoOn ? '#9C27B0' : '#999')
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Center)
              .width(100)

              Column() {
                Text('根据阈值自动控制灯光/空调/门锁')
                  .fontSize(12).fontColor('#999')
                  .margin({ bottom: 10 })

                Toggle({ type: ToggleType.Switch, isOn: this.autoOn })
                  .selectedColor('#9C27B0')
                  .onChange((isOn: boolean) => {
                    this.autoOn = isOn;
                    this.sendCommand(new AutoCmd(isOn), isOn ? '开启自动模式' : '关闭自动模式');
                  })
              }
              .layoutWeight(1).alignItems(HorizontalAlign.End)
            }
            .width('100%').padding(20)
            .backgroundColor('#FFFFFF').borderRadius(16)
            .shadow({ radius: 6, color: '#0000000A', offsetY: 3 })

            // ================================================================
            // 告警阈值开关
            // ================================================================
            Column({ space: 10 }) {
              Text('⚙️ 告警阈值开关')
                .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#333')
                .width('100%')

              // 🌡️ 温度告警
              Row() {
                Text(this.tmOn ? ' ON ' : 'OFF')
                  .fontSize(11).fontWeight(FontWeight.Bold)
                  .fontColor(this.tmOn ? '#FFFFFF' : '#999')
                  .backgroundColor(this.tmOn ? '#F44336' : '#E0E0E0')
                  .borderRadius(4)
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .margin({ right: 10 })
                Text('🌡️').fontSize(18)
                Column() {
                  Text('温度告警').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                  Text(this.tmOn ? '-2℃ ~ 8℃' : '-20℃ ~ 60℃').fontSize(11).fontColor('#999')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 6 })
                Toggle({ type: ToggleType.Switch, isOn: this.tmOn })
                  .selectedColor('#F44336')
                  .onChange((isOn: boolean) => { this.tmOn = isOn; this.sendCommand(new TmCmd(isOn), isOn ? '温度告警已开启' : '温度告警已关闭'); })
              }.width('100%')

              // 💧 湿度告警
              Row() {
                Text(this.huOn ? ' ON ' : 'OFF')
                  .fontSize(11).fontWeight(FontWeight.Bold)
                  .fontColor(this.huOn ? '#FFFFFF' : '#999')
                  .backgroundColor(this.huOn ? '#2196F3' : '#E0E0E0')
                  .borderRadius(4)
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .margin({ right: 10 })
                Text('💧').fontSize(18)
                Column() {
                  Text('湿度告警').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                  Text(this.huOn ? '20% ~ 80%' : '0% ~ 100%').fontSize(11).fontColor('#999')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 6 })
                Toggle({ type: ToggleType.Switch, isOn: this.huOn })
                  .selectedColor('#2196F3')
                  .onChange((isOn: boolean) => { this.huOn = isOn; this.sendCommand(new HuCmd(isOn), isOn ? '湿度告警已开启' : '湿度告警已关闭'); })
              }.width('100%')

              // 💡 光照告警
              Row() {
                Text(this.ligOn ? ' ON ' : 'OFF')
                  .fontSize(11).fontWeight(FontWeight.Bold)
                  .fontColor(this.ligOn ? '#FFFFFF' : '#999')
                  .backgroundColor(this.ligOn ? '#FF9800' : '#E0E0E0')
                  .borderRadius(4)
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .margin({ right: 10 })
                Text('💡').fontSize(18)
                Column() {
                  Text('光照告警').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                  Text(this.ligOn ? '0 ~ 200 lx' : '0 ~ 5000 lx').fontSize(11).fontColor('#999')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 6 })
                Toggle({ type: ToggleType.Switch, isOn: this.ligOn })
                  .selectedColor('#FF9800')
                  .onChange((isOn: boolean) => { this.ligOn = isOn; this.sendCommand(new LigCmd(isOn), isOn ? '光照告警已开启' : '光照告警已关闭'); })
              }.width('100%')

              // 📐 倾斜告警
              Row() {
                Text(this.incliOn ? ' ON ' : 'OFF')
                  .fontSize(11).fontWeight(FontWeight.Bold)
                  .fontColor(this.incliOn ? '#FFFFFF' : '#999')
                  .backgroundColor(this.incliOn ? '#607D8B' : '#E0E0E0')
                  .borderRadius(4)
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .margin({ right: 10 })
                Text('📐').fontSize(18)
                Column() {
                  Text('倾斜告警').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                  Text(this.incliOn ? '0 ~ 15000' : '0 ~ 30000').fontSize(11).fontColor('#999')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 6 })
                Toggle({ type: ToggleType.Switch, isOn: this.incliOn })
                  .selectedColor('#607D8B')
                  .onChange((isOn: boolean) => { this.incliOn = isOn; this.sendCommand(new IncliCmd(isOn), isOn ? '倾斜告警已开启' : '倾斜告警已关闭'); })
              }.width('100%')
            }
            .width('100%').padding(20)
            .backgroundColor('#FFFFFF').borderRadius(16)
            .shadow({ radius: 6, color: '#0000000A', offsetY: 3 })

            // ================================================================
            // 辅助操作
            // ================================================================
            Text('其他操作')
              .fontSize(13).fontColor('#999').margin({ top: 8 })
              .width('100%')

            Row({ space: 12 }) {
              Button('🔕 清除告警')
                .fontSize(13).height(40).layoutWeight(1)
                .backgroundColor('#FFFFFF').fontColor('#333')
                .borderRadius(20).border({ width: 1, color: '#E0E0E0' })
                .onClick(() => { this.sendCommand(new ClearAlarmCmd(), '清除告警'); })

              Button('🚨 紧急全关')
                .fontSize(13).height(40).layoutWeight(1)
                .backgroundColor('#FF5252').fontColor('#FFFFFF')
                .borderRadius(20)
                .onClick(() => {
                  this.lightOn = false;
                  this.doorOpen = false;
                  this.acOn = false;
                  this.autoOn = false;
                  this.sendCommand(new EmergencyCmd(), '紧急全关');
                })
            }
            .width('100%')

            Column().height(16)
          }
          .width('100%')
        }
        .width('100%').layoutWeight(1).scrollBar(BarState.Off)
        .padding({ top: 4, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }

}
