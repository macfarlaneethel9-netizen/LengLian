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

// ------ 命令体类型（ArkTS 要求显式声明）------
class LedColor {
  r: number;
  g: number;
  b: number;

  constructor(r: number, g: number, b: number) {
    this.r = r;
    this.g = g;
    this.b = b;
  }
}

class LedCmd {
  led: LedColor;
  constructor(on: boolean) {
    this.led = on ? new LedColor(255, 255, 255) : new LedColor(0, 0, 0);
  }
}

class MotorCmd {
  motor: number;
  constructor(open: boolean) {
    this.motor = open ? 80 : 0;   // 80: 开锁脉冲, 0: 关锁
  }
}

class ClearAlarmCmd {
  clear_alarm: number;
  constructor() { this.clear_alarm = 1; }
}

class EmergencyCmd {
  motor: number;
  led: LedColor;
  beep: number;
  constructor() {
    this.motor = 0;
    this.led = new LedColor(0, 0, 0);
    this.beep = 0;
  }
}

// ------ 新增命令体：空调 ------
class AcCmd {
  ac: number;
  constructor(on: boolean) { this.ac = on ? 1 : 0; }
}

// ------ 新增命令体：温度阈值 ------
class TempThresholdCmd {
  temp_threshold_high: number;
  temp_threshold_low: number;
  constructor(high: number, low: number) {
    this.temp_threshold_high = high;
    this.temp_threshold_low = low;
  }
}

// ------ 新增命令体：湿度阈值 ------
class HumiThresholdCmd {
  humi_threshold_high: number;
  humi_threshold_low: number;
  constructor(high: number, low: number) {
    this.humi_threshold_high = high;
    this.humi_threshold_low = low;
  }
}

// ------ 新增命令体：光照阈值 ------
class LuxThresholdCmd {
  lux_threshold: number;
  constructor(v: number) { this.lux_threshold = v; }
}

// ------ 新增命令体：倾斜阈值 ------
class TiltThresholdCmd {
  tilt_threshold: number;
  constructor(v: number) { this.tilt_threshold = v; }
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

  // ------ 温度阈值 ------
  @StorageLink('tempThresholdHigh') tempThresholdHigh: number = 8;
  @StorageLink('tempThresholdLow') tempThresholdLow: number = 2;
  @State tempHighSlider: number = 8;
  @State tempLowSlider: number = 2;

  // ------ 湿度阈值 ------
  @StorageLink('humiThresholdHigh') humiThresholdHigh: number = 80;
  @StorageLink('humiThresholdLow') humiThresholdLow: number = 20;
  @State humiHighSlider: number = 80;
  @State humiLowSlider: number = 20;

  // ------ 光照阈值 ------
  @StorageLink('luxThreshold') luxThreshold: number = 200;
  @State luxSlider: number = 200;

  // ------ 倾斜阈值 ------
  @StorageLink('tiltThreshold') tiltThreshold: number = 15000;
  @State tiltSlider: number = 15000;

  // ------ 阈值面板折叠 ------
  @State thresholdExpanded: boolean = false;

  // ------ 反馈消息 ------
  @State okText: string = '';
  @State errorText: string = '';
  @State sendingLabel: string = '';    // 哪个按钮正在发送

  aboutToAppear(): void {
    this.fetchDevices();

    // 同步滑块到 AppStorage 值
    this.tempHighSlider = this.tempThresholdHigh;
    this.tempLowSlider = this.tempThresholdLow;
    this.humiHighSlider = this.humiThresholdHigh;
    this.humiLowSlider = this.humiThresholdLow;
    this.luxSlider = this.luxThreshold;
    this.tiltSlider = this.tiltThreshold;

    // 订阅实时推送，保持设备列表和状态最新
    realtimeService.onUpdate((devices: DeviceInfo[]) => {
      this.devices = devices;
      // 从最新遥测同步电机/灯光状态
      if (this.devices.length > 0) {
        let t = this.devices[this.selectedIndex].last_telemetry;
        this.doorOpen = t.motor === 1;
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

  get selectedDevice(): DeviceInfo | null {
    if (this.devices.length === 0) { return null; }
    return this.devices[this.selectedIndex];
  }

  // ------ 发送命令 ------
  async sendCommand(cmd: object, label: string): Promise<void> {
    if (this.devices.length === 0) { return; }
    let deviceId = this.devices[this.selectedIndex].device_id;
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
    this.sendCommand(new LedCmd(this.lightOn), this.lightOn ? '开灯' : '关灯');
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

  // ------ 发送温度阈值 ------
  setTempThreshold(): void {
    this.tempThresholdHigh = this.tempHighSlider;
    this.tempThresholdLow = this.tempLowSlider;
    this.sendCommand(
      new TempThresholdCmd(this.tempHighSlider, this.tempLowSlider),
      `温度阈值 ${this.tempLowSlider.toFixed(1)}~${this.tempHighSlider.toFixed(1)}℃`
    );
  }

  // ------ 发送湿度阈值 ------
  setHumiThreshold(): void {
    this.humiThresholdHigh = this.humiHighSlider;
    this.humiThresholdLow = this.humiLowSlider;
    this.sendCommand(
      new HumiThresholdCmd(this.humiHighSlider, this.humiLowSlider),
      `湿度阈值 ${this.humiLowSlider.toFixed(0)}~${this.humiHighSlider.toFixed(0)}%`
    );
  }

  // ------ 发送光照阈值 ------
  setLuxThreshold(): void {
    this.luxThreshold = this.luxSlider;
    this.sendCommand(
      new LuxThresholdCmd(this.luxSlider),
      `光照阈值 ${this.luxSlider.toFixed(0)} lx`
    );
  }

  // ------ 发送倾斜阈值 ------
  setTiltThreshold(): void {
    this.tiltThreshold = this.tiltSlider;
    this.sendCommand(
      new TiltThresholdCmd(this.tiltSlider),
      `倾斜阈值 ${this.tiltSlider.toFixed(0)}`
    );
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
            // ====== 设备选择器 ======
            Row() {
              Text('←').fontSize(24).fontColor('#1a73e8')
                .onClick(() => { if (this.selectedIndex > 0) { this.selectedIndex--; } })
              Column() {
                Text(this.selectedDevice?.name || this.selectedDevice?.device_id || '--')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
                Text(`ID: ${this.selectedDevice?.device_id || ''}`)
                  .fontSize(12).fontColor('#999').margin({ top: 2 })
              }
              .layoutWeight(1).alignItems(HorizontalAlign.Center)
              Text('→').fontSize(24).fontColor('#1a73e8')
                .onClick(() => { if (this.selectedIndex < this.devices.length - 1) { this.selectedIndex++; } })
            }
            .width('100%').padding(14).backgroundColor('#FFFFFF')
            .borderRadius(12).margin({ bottom: 0 })

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
                    this.sendCommand(new LedCmd(isOn), isOn ? '开灯' : '关灯');
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

            // ================================================================
            // 阈值设置面板（可折叠）
            // ================================================================
            Column() {
              Row() {
                Text('⚙️ 告警阈值设置')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
                Blank()
                Text(this.thresholdExpanded ? '收起 ▲' : '展开 ▼')
                  .fontSize(12).fontColor('#1a73e8')
              }
              .width('100%')
              .onClick(() => { this.thresholdExpanded = !this.thresholdExpanded; })

              if (this.thresholdExpanded) {
                Column({ space: 14 }) {
                  Divider().color('#E0E0E0').margin({ top: 8 })

                  // ---- 温度阈值 ----
                  Text('🌡️ 温度告警阈值')
                    .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                    .width('100%')

                  Row({ space: 8 }) {
                    Text(`${this.tempLowSlider.toFixed(1)}`).fontSize(12).fontColor('#FF9800').width(36)
                    Slider({
                      value: this.tempLowSlider,
                      min: -10,
                      max: 20,
                      step: 0.5,
                      style: SliderStyle.InSet
                    })
                      .layoutWeight(1)
                      .blockColor('#FF9800')
                      .trackColor('#FFE0B2')
                      .selectedColor('#FF9800')
                      .onChange((value: number) => { this.tempLowSlider = value; })
                    Text('下限').fontSize(11).fontColor('#999').width(28)
                  }.width('100%')

                  Row({ space: 8 }) {
                    Text(`${this.tempHighSlider.toFixed(1)}`).fontSize(12).fontColor('#F44336').width(36)
                    Slider({
                      value: this.tempHighSlider,
                      min: -10,
                      max: 20,
                      step: 0.5,
                      style: SliderStyle.InSet
                    })
                      .layoutWeight(1)
                      .blockColor('#F44336')
                      .trackColor('#FFCDD2')
                      .selectedColor('#F44336')
                      .onChange((value: number) => { this.tempHighSlider = value; })
                    Text('上限').fontSize(11).fontColor('#999').width(28)
                  }.width('100%')

                  Button('设定温度阈值')
                    .fontSize(13).height(36)
                    .backgroundColor('#F44336').fontColor('#FFFFFF').borderRadius(18)
                    .onClick(() => { this.setTempThreshold(); })

                  Divider().color('#E0E0E0')

                  // ---- 湿度阈值 ----
                  Text('💧 湿度告警阈值')
                    .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                    .width('100%')

                  Row({ space: 8 }) {
                    Text(`${this.humiLowSlider.toFixed(0)}`).fontSize(12).fontColor('#F44336').width(36)
                    Slider({
                      value: this.humiLowSlider,
                      min: 0,
                      max: 100,
                      step: 5,
                      style: SliderStyle.InSet
                    })
                      .layoutWeight(1)
                      .blockColor('#F44336')
                      .trackColor('#FFCDD2')
                      .selectedColor('#F44336')
                      .onChange((value: number) => { this.humiLowSlider = value; })
                    Text('下限').fontSize(11).fontColor('#999').width(28)
                  }.width('100%')

                  Row({ space: 8 }) {
                    Text(`${this.humiHighSlider.toFixed(0)}`).fontSize(12).fontColor('#FF9800').width(36)
                    Slider({
                      value: this.humiHighSlider,
                      min: 0,
                      max: 100,
                      step: 5,
                      style: SliderStyle.InSet
                    })
                      .layoutWeight(1)
                      .blockColor('#FF9800')
                      .trackColor('#FFE0B2')
                      .selectedColor('#FF9800')
                      .onChange((value: number) => { this.humiHighSlider = value; })
                    Text('上限').fontSize(11).fontColor('#999').width(28)
                  }.width('100%')

                  Button('设定湿度阈值')
                    .fontSize(13).height(36)
                    .backgroundColor('#2196F3').fontColor('#FFFFFF').borderRadius(18)
                    .onClick(() => { this.setHumiThreshold(); })

                  Divider().color('#E0E0E0')

                  // ---- 光照阈值 ----
                  Text('💡 光照告警阈值')
                    .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                    .width('100%')

                  Row({ space: 8 }) {
                    Text(`${this.luxSlider.toFixed(0)}`).fontSize(12).fontColor('#FF9800').width(36)
                    Slider({
                      value: this.luxSlider,
                      min: 0,
                      max: 1000,
                      step: 10,
                      style: SliderStyle.InSet
                    })
                      .layoutWeight(1)
                      .blockColor('#FF9800')
                      .trackColor('#FFE0B2')
                      .selectedColor('#FF9800')
                      .onChange((value: number) => { this.luxSlider = value; })
                    Text('上限').fontSize(11).fontColor('#999').width(28)
                  }.width('100%')

                  Button('设定光照阈值')
                    .fontSize(13).height(36)
                    .backgroundColor('#FF9800').fontColor('#FFFFFF').borderRadius(18)
                    .onClick(() => { this.setLuxThreshold(); })

                  Divider().color('#E0E0E0')

                  // ---- 倾斜阈值 ----
                  Text('📐 倾斜告警阈值')
                    .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                    .width('100%')

                  Row({ space: 8 }) {
                    Text(`${this.tiltSlider.toFixed(0)}`).fontSize(12).fontColor('#607D8B').width(48)
                    Slider({
                      value: this.tiltSlider,
                      min: 0,
                      max: 30000,
                      step: 500,
                      style: SliderStyle.InSet
                    })
                      .layoutWeight(1)
                      .blockColor('#607D8B')
                      .trackColor('#E0E0E0')
                      .selectedColor('#607D8B')
                      .onChange((value: number) => { this.tiltSlider = value; })
                    Text('上限').fontSize(11).fontColor('#999').width(28)
                  }.width('100%')

                  Button('设定倾斜阈值')
                    .fontSize(13).height(36)
                    .backgroundColor('#607D8B').fontColor('#FFFFFF').borderRadius(18)
                    .onClick(() => { this.setTiltThreshold(); })
                }
                .width('100%')
                .margin({ top: 4 })
              }
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
