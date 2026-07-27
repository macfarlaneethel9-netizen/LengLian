/**
 * 设备管理模块 — 对接后端 API
 *
 * 将温度监控、光照监控、货物管理合并为一个页面，
 * 数据来源于后端 GET /api/devices，实时展示遥测数据。
 *
 * Tab 布局：
 *   Tab 0：设备列表   — 设备卡片（在线状态、温度、湿度、光照、告警）
 *   Tab 1：温度监控   — 各设备温度详情 + 告警
 *   Tab 2：光照监控   — 各设备光照详情
 */

import { PageTitle, PlaceholderText } from '../components/CommonBuilders';
import { apiService, DeviceInfo } from '../services/ApiService';

@Component
export struct DeviceManagePage {
  // Tab 索引
  @State currentTabIndex: number = 0;

  // 设备数据
  @State devices: DeviceInfo[] = [];
  @State isLoading: boolean = true;
  @State errorText: string = '';
  @State lastRefresh: string = '--:--:--';

  // ====== 生命周期 ======

  aboutToAppear(): void {
    this.fetchDevices();
  }

  // ====== 拉取设备列表 ======

  async fetchDevices(): Promise<void> {
    this.isLoading = true;
    this.errorText = '';

    try {
      let result = await apiService.getDevices(1, 50);
      this.devices = result.items;
      // 更新时间戳
      let now = new Date();
      this.lastRefresh = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    } catch (err) {
      this.errorText = '加载失败：' + String((err as Error).message || '未知错误');
      console.error('[DeviceManage] 获取设备列表失败:', JSON.stringify(err));
    }
    this.isLoading = false;
  }

  // ====== 温度告警等级 ======

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

  // ====== 光照等级 ======

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

  build() {
    Column() {
      // ---- 顶部标题与刷新 ----
      Row() {
        PageTitle('设备管理')
        Blank()
        Row() {
          Text('🔄')
            .fontSize(20)
            .onClick(() => {
              if (!this.isLoading) { this.fetchDevices(); }
            })
            .rotate({ angle: this.isLoading ? 360 : 0 })
            .animation({ duration: 800, curve: Curve.Linear, iterations: this.isLoading ? -1 : 1 })
          Text(`${this.devices.length} 个设备`)
            .fontSize(12)
            .fontColor('#999')
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // ---- 加载/错误提示 ----
      if (this.isLoading) {
        Text('加载中...')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 40 })
      }

      if (this.errorText !== '') {
        Text(this.errorText)
          .fontSize(13)
          .fontColor('#F44336')
          .padding(12)
          .backgroundColor('#FFEBEE')
          .borderRadius(8)
          .width('100%')
      }

      if (this.devices.length === 0 && !this.isLoading && this.errorText === '') {
        Text('暂无设备，请先添加设备')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 40 })
      }

      // ---- Tabs ----
      Tabs({ barPosition: BarPosition.Start }) {
        // ====== Tab 0：设备列表 ======
        TabContent() {
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
        .tabBar(this.TabBarBuilder('设备列表', 0))

        // ====== Tab 1：温度监控 ======
        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() {
                  this.TempCard(device)
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabBarBuilder('温度监控', 1))

        // ====== Tab 2：光照监控 ======
        TabContent() {
          if (this.devices.length > 0) {
            List({ space: 12 }) {
              ForEach(this.devices, (device: DeviceInfo) => {
                ListItem() {
                  this.LuxCard(device)
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .padding({ top: 8, bottom: 16 })
          }
        }
        .tabBar(this.TabBarBuilder('光照监控', 2))
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
  TabBarBuilder(label: string, index: number) {
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
  // @Builder：设备概览卡片
  // ============================================================
  @Builder
  DeviceCard(device: DeviceInfo) {
    Column({ space: 8 }) {
      // 顶部：设备名称 + 在线状态
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

      // 遥测数据
      let t = device.last_telemetry;
      Row() {
        // 温度
        Column() {
          Text('温度')
            .fontSize(11)
            .fontColor('#999')
          Text(`${t.temp.toFixed(1)}℃`)
            .fontSize(20)
            .fontColor(this.getTempColor(t.temp))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        // 湿度
        Column() {
          Text('湿度')
            .fontSize(11)
            .fontColor('#999')
          Text(`${t.humi.toFixed(1)}%`)
            .fontSize(20)
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        // 光照
        Column() {
          Text('光照')
            .fontSize(11)
            .fontColor('#999')
          Text(`${t.lux.toFixed(0)} lux`)
            .fontSize(20)
            .fontColor(this.getLuxColor(t.lux))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        // 告警
        Column() {
          Text('告警')
            .fontSize(11)
            .fontColor('#999')
          Text(t.alarm === 1 ? '⚠️' : '✅')
            .fontSize(20)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 告警原因
      if (t.alarm === 1 && t.alarm_reason) {
        Text(`告警原因: ${t.alarm_reason}`)
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

  // ============================================================
  // @Builder：温度监控卡片
  // ============================================================
  @Builder
  TempCard(device: DeviceInfo) {
    let t = device.last_telemetry;
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

      // 温度大数字
      Row() {
        Column() {
          Text('当前温度')
            .fontSize(12)
            .fontColor('#999')
          Text(`${t.temp.toFixed(1)} ℃`)
            .fontSize(36)
            .fontColor(this.getTempColor(t.temp))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }

        Blank()

        // 告警状态
        Column() {
          Text('温度状态')
            .fontSize(12)
            .fontColor('#999')
          Text(this.getTempLevel(t.temp))
            .fontSize(14)
            .fontColor(this.getTempColor(t.temp))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      // 温控范围参考线
      Row() {
        Text('0℃')
          .fontSize(10)
          .fontColor('#999')
        // 温度指示条
        Column() {
        }
        .layoutWeight(1)
        .height(6)
        .backgroundColor('#E0E0E0')
        .borderRadius(3)
        .margin({ left: 8, right: 8 })
        Text('12℃')
          .fontSize(10)
          .fontColor('#999')
      }
      .width('100%')

      // 告警原因
      if (t.alarm === 1 && t.alarm_reason) {
        Row() {
          Text('⚠️')
            .fontSize(14)
          Text(t.alarm_reason)
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
  LuxCard(device: DeviceInfo) {
    let t = device.last_telemetry;
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

      // 光照大数字
      Row() {
        Column() {
          Text('当前光照')
            .fontSize(12)
            .fontColor('#999')
          Text(`${t.lux.toFixed(0)} lux`)
            .fontSize(36)
            .fontColor(this.getLuxColor(t.lux))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }

        Blank()

        Column() {
          Text('光照状态')
            .fontSize(12)
            .fontColor('#999')
          Text(this.getLuxLevel(t.lux))
            .fontSize(14)
            .fontColor(this.getLuxColor(t.lux))
            .fontWeight(FontWeight.Bold)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      // 光照指示条
      Row() {
        Text('暗')
          .fontSize(10)
          .fontColor('#999')
        Column() {
        }
        .layoutWeight(1)
        .height(6)
        .backgroundColor('#E0E0E0')
        .borderRadius(3)
        .margin({ left: 8, right: 8 })
        Text('亮')
          .fontSize(10)
          .fontColor('#999')
      }
      .width('100%')

      // 湿度
      Row() {
        Text('附带湿度')
          .fontSize(12)
          .fontColor('#999')
        Text(`${t.humi.toFixed(1)}%`)
          .fontSize(14)
          .fontColor('#2196F3')
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
      }

      // 倾斜量
      Row() {
        Text('倾斜量')
          .fontSize(12)
          .fontColor('#999')
        Text(`${t.tilt.toFixed(0)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(t.tilt > 15000 ? '#F44336' : '#333')
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
  // 工具：格式化时间戳为 HH:MM:SS
  // ============================================================
  formatTime(ts: number): string {
    if (!ts || ts <= 0) { return '--:--:--'; }
    let date = new Date(ts * 1000);
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`;
  }
}
