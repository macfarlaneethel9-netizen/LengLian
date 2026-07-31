/**
 * 设备列表页面
 *
 * 拉取 GET /api/devices，展示所有冷链设备的概览卡片。
 * 支持添加设备（POST /api/devices），直接关联华为云。
 */

import { PageTitle } from '../components/CommonBuilders';
import {
  apiService, DeviceInfo, fmtTemp, fmtHumi, fmtLux,
  getAlarm, getAlarmReason, getTemp, getLux
} from '../services/ApiService';
import { realtimeService } from '../services/RealtimeService';

@Component
export struct DeviceListPage {
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State lastRefresh: string = '--:--:--';
  private isMounted: boolean = false;

  // ---- 排序模式 ----
  @State sortMode: boolean = false;

  // ---- 添加设备 ----
  @State showAdd: boolean = false;
  @State newId: string = '';
  @State newName: string = '';
  @State newLoc: string = '';
  @State addMsg: string = '';
  @State addErr: string = '';

  aboutToAppear(): void {
    this.isMounted = true;
    this.fetchDevices();
    realtimeService.onUpdate((devices: DeviceInfo[]) => {
      this.devices = devices;
      this.updateTime();
    });
    realtimeService.start(3000);
  }

  aboutToDisappear(): void {
    this.isMounted = false;
    realtimeService.stop();
  }

  async fetchDevices(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';
    try {
      let result = await apiService.getDevices(1, 50);
      if (!this.isMounted) { return; }
      if (result.items && result.items.length > 0) {
        this.devices = result.items;
      }
    } catch (err) {
      if (this.isMounted) {
        this.errorText = '加载失败：' + String((err as Error).message || '未知错误');
      }
    }
    if (this.isMounted) {
      this.isLoading = false;
      this.updateTime();
    }
  }

  async runDiagnostic(): Promise<void> {
    this.isLoading = true;
    this.errorText = '诊断中...';
    let r = '';
    try {
      let d = await apiService.healthCheck();
      r += '✅ 后端可达: ' + JSON.stringify(d).substring(0, 100) + '\n';
    } catch (err) {
      r += '❌ 后端不可达: ' + String((err as Error).message) + '\n';
    }
    try {
      let dev = await apiService.getDevices(1, 5);
      r += `✅ 鉴权正常, 设备数=${dev.total}`;
    } catch (err) {
      r += '❌ 鉴权失败: ' + String((err as Error).message);
    }
    this.errorText = r;
    this.isLoading = false;
  }

  async doAddDevice(): Promise<void> {
    if (this.newId.trim() === '') {
      this.addErr = '设备 ID 不能为空';
      return;
    }
    this.addErr = '';
    try {
      await apiService.createDevice(this.newId.trim(), this.newName.trim(), this.newLoc.trim());
      this.addMsg = '添加成功！设备已关联华为云';
      setTimeout(() => {
        this.showAdd = false;
        this.fetchDevices();
      }, 1000);
    } catch (err) {
      this.addErr = '添加失败：' + String((err as Error).message || '');
    }
  }

  updateTime(): void {
    let now = new Date();
    this.lastRefresh =
      `${now.getHours().toString().padStart(2,'0')}:` +
      `${now.getMinutes().toString().padStart(2,'0')}:` +
      `${now.getSeconds().toString().padStart(2,'0')}`;
  }

  // ------ 拖拽排序 ------
  moveUp(index: number): void {
    if (index <= 0) { return; }
    let arr = this.devices;
    let tmp = arr[index - 1];
    arr[index - 1] = arr[index];
    arr[index] = tmp;
    this.devices = arr;
  }

  moveDown(index: number): void {
    if (index >= this.devices.length - 1) { return; }
    let arr = this.devices;
    let tmp = arr[index + 1];
    arr[index + 1] = arr[index];
    arr[index] = tmp;
    this.devices = arr;
  }

  getTempColor(t: number): string {
    if (t > 8) { return '#F44336'; }
    if (t < 2) { return '#FF9800'; }
    return '#4CAF50';
  }

  getLuxColor(l: number): string {
    if (l > 200) { return '#FF9800'; }
    if (l < 50) { return '#9E9E9E'; }
    return '#4CAF50';
  }

  formatTime(ts: number): string {
    if (!ts || ts <= 0) { return '--:--:--'; }
    let d = new Date(ts * 1000);
    return `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}:${d.getSeconds().toString().padStart(2,'0')}`;
  }

  build() {
    Stack() {
      // ========== 主内容 ==========
      Column() {
        Row() {
          PageTitle('设备列表')
          Blank()
          Row() {
            Text('🔀').fontSize(18)
              .fontColor(this.sortMode ? '#1a73e8' : '#999')
              .onClick(() => { this.sortMode = !this.sortMode; })
            Text('➕').fontSize(20).margin({ left: 8 })
              .onClick(() => {
                this.showAdd = true;
                this.newId = ''; this.newName = ''; this.newLoc = '';
                this.addMsg = ''; this.addErr = '';
              })
            Text('🔄').fontSize(20).margin({ left: 10 })
              .onClick(() => { if (!this.isLoading) { this.fetchDevices(); } })
            Text(`${this.devices.length} 个设备`).fontSize(12).fontColor('#999').margin({ left: 6 })
          }
        }.width('100%').alignItems(VerticalAlign.Center)

        if (this.isLoading) {
          Text('加载中...').fontSize(14).fontColor('#999').margin({ top: 40 })
        }
        if (this.errorText !== '') {
          Text(this.errorText).fontSize(13).fontColor('#F44336')
            .padding(12).backgroundColor('#FFEBEE').borderRadius(8).width('100%')
        }
        if (this.devices.length === 0 && !this.isLoading && this.errorText === '') {
          Column({ space: 12 }) {
            Text('暂无设备数据').fontSize(14).fontColor('#999')
            Button('🔍 网络诊断').fontSize(13).height(36)
              .backgroundColor('#1a73e8').fontColor('#FFFFFF').borderRadius(20)
              .onClick(() => { this.runDiagnostic(); })
          }.margin({ top: 40 })
        }
        if (this.devices.length > 0) {
          List({ space: 12 }) {
            ForEach(this.devices, (device: DeviceInfo, index: number) => {
              ListItem() { this.DeviceCard(device, index) }
            })
          }.width('100%').layoutWeight(1).scrollBar(BarState.Off).padding({ top: 8, bottom: 16 })
        }
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5').padding({ left: 16, right: 16 })

      // ========== 添加设备弹窗 ==========
      if (this.showAdd) {
        Column().width('100%').height('100%').backgroundColor('#00000050')
          .onClick(() => { this.showAdd = false; })

        Column({ space: 14 }) {
          Text('添加设备').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333')

          TextInput({ placeholder: '设备 ID（必填）' })
            .width('100%').height(44).fontSize(15)
            .backgroundColor('#F5F5F5').borderRadius(8)
            .onChange((v: string) => { this.newId = v; })

          TextInput({ placeholder: '设备名称（可选）' })
            .width('100%').height(44).fontSize(15)
            .backgroundColor('#F5F5F5').borderRadius(8)
            .onChange((v: string) => { this.newName = v; })

          TextInput({ placeholder: '设备位置（可选）' })
            .width('100%').height(44).fontSize(15)
            .backgroundColor('#F5F5F5').borderRadius(8)
            .onChange((v: string) => { this.newLoc = v; })

          if (this.addMsg !== '') {
            Text(this.addMsg).fontSize(13).fontColor('#4CAF50')
          }
          if (this.addErr !== '') {
            Text(this.addErr).fontSize(13).fontColor('#F44336')
          }

          Row({ space: 12 }) {
            Button('取消').fontSize(14).height(40).layoutWeight(1)
              .backgroundColor('#E0E0E0').fontColor('#666').borderRadius(20)
              .onClick(() => { this.showAdd = false; })
            Button('确认添加').fontSize(14).height(40).layoutWeight(1)
              .backgroundColor('#1a73e8').fontColor('#FFFFFF').borderRadius(20)
              .onClick(() => { this.doAddDevice(); })
          }.width('100%')
        }
        .width('85%').padding(24).backgroundColor('#FFFFFF').borderRadius(16)
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  DeviceCard(device: DeviceInfo, index: number) {
    Column({ space: 8 }) {
      Row() {
        Text(device.name || device.device_id).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
        Blank()
        // 排序按钮
        if (this.sortMode) {
          Row({ space: 4 }) {
            Text('▲').fontSize(16).fontColor(index > 0 ? '#1a73e8' : '#CCC')
              .onClick(() => { this.moveUp(index); })
            Text('▼').fontSize(16).fontColor(index < this.devices.length - 1 ? '#1a73e8' : '#CCC')
              .onClick(() => { this.moveDown(index); })
          }.margin({ right: 8 })
        }
        Text(device.online ? '🟢 在线' : '⚫ 离线').fontSize(12)
          .fontColor(device.online ? '#4CAF50' : '#999')
      }.width('100%')

      if (device.location) {
        Text(`📍 ${device.location}`).fontSize(12).fontColor('#999')
      }

      Divider().color('#F0F0F0')

      Row() {
        Column() {
          Text('温度').fontSize(11).fontColor('#999')
          Text(`${fmtTemp(device.last_telemetry)}℃`).fontSize(20)
            .fontColor(this.getTempColor(getTemp(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 2 })
        }.layoutWeight(1)
        Column() {
          Text('湿度').fontSize(11).fontColor('#999')
          Text(`${fmtHumi(device.last_telemetry)}%`).fontSize(20)
            .fontColor('#2196F3').fontWeight(FontWeight.Bold).margin({ top: 2 })
        }.layoutWeight(1)
        Column() {
          Text('光照').fontSize(11).fontColor('#999')
          Text(`${fmtLux(device.last_telemetry)} lux`).fontSize(20)
            .fontColor(this.getLuxColor(getLux(device.last_telemetry))).fontWeight(FontWeight.Bold).margin({ top: 2 })
        }.layoutWeight(1)
        Column() {
          Text('告警').fontSize(11).fontColor('#999')
          Text(getAlarm(device.last_telemetry) === 1 ? '⚠️' : '✅').fontSize(20).margin({ top: 2 })
        }.layoutWeight(1)
      }.width('100%')

      if (getAlarm(device.last_telemetry) === 1 && getAlarmReason(device.last_telemetry).length > 0) {
        Text(`告警: ${getAlarmReason(device.last_telemetry)}`).fontSize(11).fontColor('#F44336').width('100%')
      }

      Text(`更新: ${this.formatTime(device.last_seen)}`).fontSize(11).fontColor('#BBB')
        .width('100%').textAlign(TextAlign.End)
    }
    .width('100%').padding(16).backgroundColor('#FFFFFF')
    .borderRadius(12).shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }
}
