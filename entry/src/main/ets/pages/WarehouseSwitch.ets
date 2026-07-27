/**
 * 仓库开关管理页面
 *
 * 对接后端 POST /api/devices/{id}/cmd 发送控制命令。
 * 支持的指令：LED、电机（锁）、蜂鸣器、清除告警。
 */

import { PageTitle } from '../components/CommonBuilders';
import { apiService, DeviceInfo } from '../services/ApiService';

// ArkTS 所有类型必须显式声明
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

  constructor(r: number, g: number, b: number) {
    this.led = new LedColor(r, g, b);
  }
}

class MotorCmd {
  motor: number;
  constructor(duty: number) { this.motor = duty; }
}

class BeepCmd {
  beep: number;
  constructor(v: number) { this.beep = v; }
}

class ClearAlarmCmd {
  clear_alarm: number;
  constructor(v: number) { this.clear_alarm = v; }
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

@Component
export struct WarehouseSwitchPage {
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State okText: string = '';                // 成功提示
  @State sendingId: string = '';             // 正在发送的命令标识
  @State selectedIndex: number = 0;          // 当前选中设备索引

  // 控制参数
  @State ledR: number = 255;
  @State ledG: number = 255;
  @State ledB: number = 255;
  @State motorDuty: number = 80;

  aboutToAppear(): void {
    this.fetchDevices();
  }

  async fetchDevices(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';
    try {
      let result = await apiService.getDevices(1, 50);
      this.devices = result.items;
    } catch (err) {
      this.errorText = '加载设备失败：' + String((err as Error).message || '');
    }
    this.isLoading = false;
  }

  async sendCommand(cmd: object, label: string): Promise<void> {
    if (this.devices.length === 0) {
      this.errorText = '没有可控制的设备';
      return;
    }
    let deviceId = this.devices[this.selectedIndex].device_id;
    this.sendingId = label;
    this.errorText = '';
    this.okText = '';
    try {
      await apiService.sendCommand(deviceId, cmd);
      console.info('[WarehouseSwitch] 命令已发送:', label);
      this.okText = `${label} 已发送`;
    } catch (err) {
      this.errorText = `${label} 失败：` + String((err as Error).message || '');
    }
    this.sendingId = '';
  }

  get selectedDevice(): DeviceInfo | null {
    if (this.devices.length === 0) { return null; }
    return this.devices[this.selectedIndex];
  }

  build() {
    Column() {
      PageTitle('仓库开关管理')

      if (this.isLoading) {
        Text('加载设备列表...').fontSize(14).fontColor('#999').margin({ top: 40 })
      } else if (this.devices.length === 0) {
        Text('暂无设备').fontSize(14).fontColor('#999').margin({ top: 40 })
      } else {
        // ---- 设备选择器（简单版：左右箭头切换） ----
        Row() {
          Text('←')
            .fontSize(24).fontColor('#1a73e8')
            .onClick(() => {
              if (this.selectedIndex > 0) { this.selectedIndex--; }
            })
          Column() {
            Text(this.selectedDevice?.name || this.selectedDevice?.device_id || '--')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
            Text(this.selectedDevice?.device_id || '')
              .fontSize(12).fontColor('#999').margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          Text('→')
            .fontSize(24).fontColor('#1a73e8')
            .onClick(() => {
              if (this.selectedIndex < this.devices.length - 1) { this.selectedIndex++; }
            })
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ bottom: 12 })

        // ---- 成功提示 ----
        if (this.okText !== '') {
          Text(this.okText)
            .fontSize(13).fontColor('#4CAF50')
            .padding(12).backgroundColor('#E8F5E9').borderRadius(8).width('100%')
            .margin({ bottom: 8 })
        }

        // ---- 错误提示 ----
        if (this.errorText !== '') {
          Text(this.errorText)
            .fontSize(13).fontColor('#F44336')
            .padding(12).backgroundColor('#FFEBEE').borderRadius(8).width('100%')
            .margin({ bottom: 8 })
        }

        // ---- 控制按钮 ----
        Column({ space: 12 }) {
          this.CtrlBtn('💡 LED 照明', '开灯', '#2196F3', () => {
            this.sendCommand(new LedCmd(this.ledR, this.ledG, this.ledB), 'LED开');
          })
          this.CtrlBtn('🔒 电机门锁', '开锁', '#FF9800', () => {
            this.sendCommand(new MotorCmd(this.motorDuty), '开锁');
          })
          this.CtrlBtn('🔒 电机门锁', '关锁', '#607D8B', () => {
            this.sendCommand(new MotorCmd(0), '关锁');
          })
          this.CtrlBtn('🔊 蜂鸣器', '响一声', '#9C27B0', () => {
            this.sendCommand(new BeepCmd(1), '蜂鸣器');
          })
          this.CtrlBtn('🔕 清除告警', '清除', '#4CAF50', () => {
            this.sendCommand(new ClearAlarmCmd(1), '清除告警');
          })
          this.CtrlBtn('🚨 紧急全关', '全关', '#F44336', () => {
            this.sendCommand(new EmergencyCmd(), '紧急全关');
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 4, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  CtrlBtn(title: string, btnLabel: string, color: string, action: () => void) {
    Row() {
      Text(title)
        .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333')
      Blank()
      Button(btnLabel)
        .fontSize(13).height(36).width(80)
        .backgroundColor(color).fontColor('#FFFFFF').borderRadius(18)
        .onClick(action)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }
}
