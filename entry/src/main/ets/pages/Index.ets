/**
 * 首页 — 全局路由 + 侧边栏 + 告警轮询 + AI 悬浮按钮
 *
 * ============================================================
 * 主界面结构：
 * ============================================================
 *
 *   已登录 → Stack 层叠：
 *     ├─ 内容区（顶部栏 + 页面切换）
 *     ├─ 侧边栏（汉堡按钮 → 左侧滑入 → 半透明遮罩 → 点击关闭）
 *     └─ AI 悬浮按钮（可拖拽，点击打开 AI 助手页）
 *
 * ============================================================
 * 侧边栏菜单：
 * ============================================================
 *   📊 仪表盘  → DashboardPage
 *   📋 设备列表 → DeviceListPage
 *   🏭 仓库状态 → WarehouseStatusPage (温度/光照/湿度/倾斜 Tab)
 *   🔔 事件日志 → AlarmLogPage
 *   ⚡ 仓库开关 → WarehouseSwitchPage
 *   🤖 AI 助手 → AiPage
 *   👤 系统管理 → 用户信息
 *
 * ============================================================
 * 告警轮询：
 * ============================================================
 *   每 5 秒 GET /api/events?kind=alarm
 *   → 新告警 → promptAction.showDialog 弹窗
 *   → 查看详情 → 跳转事件日志页
 *   → 顶部栏显示 🔔 红色徽章计数
 *
 * ============================================================
 * 登录流程：
 * ============================================================
 *   未登录 → LoginPage 全屏
 *   登录成功 → onLoginSuccess() → 进入仪表盘 + 启动告警轮询
 */

import { LoginPage } from './Login';
import { DashboardPage } from './Dashboard';
import { DeviceListPage } from './DeviceList';
import { WarehouseStatusPage } from './WarehouseStatus';
import { AlarmLogPage } from './AlarmLog';
import { WarehouseSwitchPage } from './WarehouseSwitch';
import { AiPage } from './AiPage';
import { apiService } from '../services/ApiService';
import { promptAction } from '@kit.ArkUI';
import window from '@ohos.window';
import display from '@ohos.display';

// 初始化跨页面共享数据（阈值已改为开关，无需 AppStorage）

// ---------- 侧边栏菜单项 ----------
class SideMenu {
  pageId: string;
  label: string;
  icon: string;

  constructor(pageId: string, label: string, icon: string) {
    this.pageId = pageId;
    this.label = label;
    this.icon = icon;
  }
}

@Entry
@Component
struct Index {
  // ====== 全局状态 ======
  @State isLoggedIn: boolean = false;              // 是否已登录（控制显示哪个界面）
  @State showSidebar: boolean = false;             // 侧边栏是否展开
  @State currentPage: string = 'Dashboard';        // 当前显示的功能页
  @State currentLabel: string = '仪表盘';            // 顶部标题

  // ====== 告警轮询 ======
  @State aiPositionX: number = 284;
  @State aiPositionY: number = 698;
  private aiDragStartX: number = 0;
  private aiDragStartY: number = 0;
  private aiWindowWidth: number = 360;
  private aiWindowHeight: number = 780;
  private aiPositionInitialized: boolean = false;
  private aiDragMoved: boolean = false;

  private lastAlarmId: number = 0;
  private alarmPollTimer: number = -1;
  @State alarmCount: number = 0;

  // ====== 登录后的侧边栏菜单 ======
  private menusAfterLogin: SideMenu[] = [
    new SideMenu('Dashboard',       '仪表盘',   '📊'),
    new SideMenu('DeviceList',       '设备列表', '📋'),
    new SideMenu('WarehouseStatus',  '仓库状态', '🏭'),
    new SideMenu('AlarmLog',         '事件日志', '🔔'),
    new SideMenu('WarehouseSwitch',  '仓库开关', '⚡'),
    new SideMenu('AI',               'AI 助手',   '🤖'),
    new SideMenu('UserInfo',         '系统管理', '👤'),
  ];

  aboutToAppear(): void {
    console.info('[Index] 首页启动, 登录状态:', this.isLoggedIn);
    if (this.isLoggedIn) {
      this.startAlarmPoll();
    }
  }

  onPageShow(): void {
    this.updateAiWindowSize();
  }

  async updateAiWindowSize(): Promise<void> {
    try {
      let currentWindow = await window.getLastWindow(getContext(this));
      let rect = currentWindow.getWindowProperties().windowRect;
      let density = Math.max(1, display.getDefaultDisplaySync().densityPixels);
      // windowRect uses physical pixels while position() uses vp.
      this.aiWindowWidth = rect.width / density;
      this.aiWindowHeight = rect.height / density;
      if (!this.aiPositionInitialized) {
        this.aiPositionX = this.aiWindowWidth - 76;
        this.aiPositionY = this.aiWindowHeight - 82;
        this.aiPositionInitialized = true;
      } else {
        this.aiPositionX = this.clampAiPositionX(this.aiPositionX);
        this.aiPositionY = this.clampAiPositionY(this.aiPositionY);
      }
    } catch (err) {
      console.warn('[Index] AI floating button uses fallback window size');
    }
  }

  clampAiPositionX(value: number): number {
    return Math.max(0, Math.min(this.aiWindowWidth - 58, value));
  }

  clampAiPositionY(value: number): number {
    return Math.max(0, Math.min(this.aiWindowHeight - 58, value));
  }

  aboutToDisappear(): void {
    this.stopAlarmPoll();
  }

  // ====== 告警轮询 ======
  startAlarmPoll(): void {
    this.stopAlarmPoll();
    this.alarmPollTimer = setInterval(() => {
      this.checkNewAlarms();
    }, 5000);
    console.info('[Index] 告警轮询已启动(5s)');
  }

  stopAlarmPoll(): void {
    if (this.alarmPollTimer >= 0) {
      clearInterval(this.alarmPollTimer);
      this.alarmPollTimer = -1;
    }
  }

  async checkNewAlarms(): Promise<void> {
    try {
      let result = await apiService.getEvents(10, undefined, 'alarm');
      if (result.events.length === 0) {
        return;
      }
      let latest = result.events[0];
      if (latest.id > this.lastAlarmId) {
        this.alarmCount += (latest.id - this.lastAlarmId);
        let reason = '';
        if (latest.detail && typeof latest.detail === 'object') {
          reason = (latest.detail as Record<string, string>)['reason'] || '';
        }
        promptAction.showDialog({
          title: '⚠️ 告警',
          message: `设备 ${latest.device_id}\n原因: ${reason || latest.kind}\n时间: ${new Date(latest.ts * 1000).toLocaleString()}`,
          buttons: [
            { text: '查看详情', color: '#1a73e8' },
            { text: '忽略', color: '#999' }
          ]
        }).then((result) => {
          if (result.index === 0) {
            this.currentPage = 'AlarmLog';
            this.currentLabel = '事件日志';
            this.alarmCount = 0;
          }
        });
        this.lastAlarmId = latest.id;
      }
    } catch (err) {
      // 静默失败
    }
  }

  // ====== 登录成功回调（传给 LoginPage）======
  onLoginSuccess = (): void => {
    this.isLoggedIn = true;
    this.currentPage = 'Dashboard';
    this.currentLabel = '仪表盘';
    this.lastAlarmId = 0;
    this.alarmCount = 0;
    this.startAlarmPoll();
    console.info('[Index] 登录成功，进入主界面');
  };

  // ====== 侧边栏菜单点击 ======
  onMenuClick(menu: SideMenu): void {
    this.currentPage = menu.pageId;
    this.currentLabel = menu.label;
    this.showSidebar = false;
    if (menu.pageId === 'AlarmLog') {
      this.alarmCount = 0;
    }
    console.info('[Index] 切换页面:', menu.pageId);
  }

  build() {
    // ============================================================
    // 未登录 → 全屏 LoginPage
    // ============================================================
    if (!this.isLoggedIn) {
      LoginPage({ onLoginSuccess: this.onLoginSuccess })
    } else {
      // ============================================================
      // 已登录 → 主界面（顶部栏 + 内容 + 左侧抽屉侧边栏）
      // ============================================================
      Stack() {
        // ========== 第1层：主内容区 ==========
        Column() {
          // ---- 顶部栏 ----
          Row() {
            // 汉堡按钮（打开侧边栏）
            Button('☰')
              .fontSize(24)
              .fontColor('#333')
              .width(40)
              .height(40)
              .backgroundColor('#00000000')
              .onClick(() => {
                this.showSidebar = !this.showSidebar;
              })

            Text(this.currentLabel)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333')
              .margin({ left: 8 })

            Blank()

            if (this.alarmCount > 0) {
              Text(`🔔 ${this.alarmCount}`)
                .fontSize(12)
                .fontColor('#F44336')
                .backgroundColor('#FFEBEE')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(10)
                .margin({ right: 8 })
                .onClick(() => {
                  this.currentPage = 'AlarmLog';
                  this.currentLabel = '事件日志';
                  this.alarmCount = 0;
                })
            }

            Text('🟢 在线')
              .fontSize(12)
              .fontColor('#4CAF50')
          }
          .width('100%')
          .height(52)
          .padding({ left: 8, right: 16 })
          .backgroundColor('#FFFFFF')
          .shadow({ radius: 2, color: '#00000008', offsetY: 1 })

          // ---- 内容切换区 ----
          if (this.currentPage === 'Dashboard') {
            DashboardPage()
          } else if (this.currentPage === 'UserInfo') {
            this.UserInfoContent()
          } else if (this.currentPage === 'Dashboard') {
            DashboardPage()
          } else if (this.currentPage === 'DeviceList') {
            DeviceListPage()
          } else if (this.currentPage === 'WarehouseStatus') {
            WarehouseStatusPage()
          } else if (this.currentPage === 'AlarmLog') {
            AlarmLogPage()
          } else if (this.currentPage === 'WarehouseSwitch') {
            WarehouseSwitchPage()
          } else if (this.currentPage === 'AI') {
            AiPage({
              onBack: () => {
                this.currentPage = 'Dashboard';
                this.currentLabel = '仪表盘';
              }
            })
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')

        // ========== 第2层：侧边栏（从左边伸出）==========
        if (this.showSidebar) {
          Row() {
            // ---- 侧边栏本体 ----
            this.SidebarDrawer()

            // ---- 右侧剩余区域：半透明 + 点击关闭 ----
            Column()
              .layoutWeight(1)
              .height('100%')
              .backgroundColor('#00000040')
              .onClick(() => {
                this.showSidebar = false;
              })
          }
          .width('100%')
          .height('100%')
        }

        // 右下角悬浮 AI 入口；打开侧边栏或已在 AI 页时隐藏。
        if (!this.showSidebar && this.currentPage !== 'AI') {
          Button('🤖')
            .width(58)
            .height(58)
            .fontSize(28)
            .backgroundColor('#1A73E8')
            .borderRadius(29)
            .shadow({ radius: 10, color: '#1A73E855', offsetY: 4 })
            .position({ x: this.aiPositionX, y: this.aiPositionY })
            .gesture(
              PanGesture()
                .onActionStart(() => {
                  this.aiDragStartX = this.aiPositionX;
                  this.aiDragStartY = this.aiPositionY;
                  this.aiDragMoved = false;
                })
                .onActionUpdate((event: GestureEvent) => {
                  if (Math.abs(event.offsetX) > 4 || Math.abs(event.offsetY) > 4) {
                    this.aiDragMoved = true;
                  }
                  this.aiPositionX = this.clampAiPositionX(this.aiDragStartX + event.offsetX);
                  this.aiPositionY = this.clampAiPositionY(this.aiDragStartY + event.offsetY);
                })
                .onActionEnd(() => {
                  this.aiPositionX = this.clampAiPositionX(this.aiPositionX);
                  this.aiPositionY = this.clampAiPositionY(this.aiPositionY);
                })
            )
            .onClick(() => {
              if (this.aiDragMoved) {
                this.aiDragMoved = false;
                return;
              }
              this.currentPage = 'AI';
              this.currentLabel = 'AI 助手';
              this.showSidebar = false;
            })
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  // ============================================================
  // @Builder：侧边栏抽屉内容
  // ============================================================
  @Builder
  SidebarDrawer() {
    Column() {
      // ---- Logo ----
      Column() {
        Text('🧊')
          .fontSize(32)
        Text('冷链监控')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .margin({ top: 2 })
      }
      .width('100%')
      .padding({ top: 20, bottom: 14 })
      .backgroundColor('#1a73e8')

      // ---- 菜单列表 ----
      List({ space: 0 }) {
        ForEach(this.menusAfterLogin, (menu: SideMenu, index: number) => {
          ListItem() {
            Row() {
              Text(menu.icon).fontSize(18)
              Text(menu.label)
                .fontSize(14)
                .margin({ left: 10 })
              if (menu.pageId === 'AlarmLog' && this.alarmCount > 0) {
                Text(`${this.alarmCount}`)
                  .fontSize(10)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#F44336')
                  .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                  .borderRadius(8)
                  .margin({ left: 6 })
              }
            }
            .width('100%')
            .height(46)
            .padding({ left: 14, right: 14 })
            .borderRadius(8)
            .margin({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(this.currentPage === menu.pageId ? '#E3F2FD' : '#00000000')
            .onClick(() => {
              this.onMenuClick(menu);
            })
          }
        })
      }
      .layoutWeight(1)
      .divider(null)
      .scrollBar(BarState.Off)
      .padding({ top: 6 })

      // ---- 底部：退出登录 ----
      Divider().color('#E0E0E0')

      Row() {
        Text('← 退出登录')
          .fontSize(13)
          .fontColor('#F44336')
      }
      .width('100%')
      .height(44)
      .padding({ left: 14, right: 14 })
      .onClick(() => {
        this.isLoggedIn = false;
        this.showSidebar = false;
        this.stopAlarmPoll();
        this.alarmCount = 0;
        console.info('[Index] 用户退出登录');
      })
    }
    .width(220)
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  // ============================================================
  // @Builder：用户信息页（侧边栏第一项"用户信息"的内容）
  // ============================================================
  @Builder
  UserInfoContent() {
    Column() {
      Text('用户信息')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Column({ space: 16 }) {
        // 头像
        Text('👤')
          .fontSize(56)
          .width(80)
          .height(80)
          .textAlign(TextAlign.Center)
          .borderRadius(40)
          .backgroundColor('#E3F2FD')

        Text(apiService.currentUser?.nickname || apiService.currentUser?.username || '--')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Divider().width('60%').color('#E0E0E0')

        Row() {
          Text('用户名').fontSize(14).fontColor('#999').width(80)
          Text(apiService.currentUser?.username || '--')
            .fontSize(14).fontColor('#333')
        }

        Row() {
          Text('角色').fontSize(14).fontColor('#999').width(80)
          Text(apiService.currentUser?.role === 'admin' ? '管理员' : '普通用户')
            .fontSize(14).fontColor('#333')
        }

        Row() {
          Text('用户 ID').fontSize(14).fontColor('#999').width(80)
          Text(`${apiService.currentUser?.id || '--'}`)
            .fontSize(14).fontColor('#333')
        }

        if (apiService.currentUser?.created_at) {
          Row() {
            Text('注册时间').fontSize(14).fontColor('#999').width(80)
            Text(new Date(apiService.currentUser!.created_at! * 1000).toLocaleDateString())
              .fontSize(14).fontColor('#333')
          }
        }
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding(16)
  }
}
