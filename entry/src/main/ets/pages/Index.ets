/**
 * 首页 — 全局路由控制
 *
 * ============================================================
 * 运行链条：
 * ============================================================
 *
 *   App 启动 → loadContent('pages/Index')
 *     ↓
 *   Index.aboutToAppear()
 *     ↓
 *   Index.build()
 *     ├─ isLoggedIn == false → LoginPage 全屏（无侧边栏）
 *     │    └─ 用户点"登录"
 *     │       → LoginPage 回调 onLoginSuccess()
 *     │       → isLoggedIn = true → build() 重跑 → 进入主界面
 *     │
 *     ├─ isLoggedIn == true → 主界面
 *     │    ├─ 顶部栏（汉堡按钮 + 标题）
 *     │    ├─ 内容区（默认温度监控，侧边栏菜单控制切换）
 *     │    └─ Stack 层叠：
 *     │         ├─ 内容区（始终显示）
 *     │         └─ showSidebar == true
 *     │              ├─ 半透明遮罩（点击关闭侧边栏）
 *     │              └─ 侧边栏抽屉（从左侧滑入）
 *     │                    ├─ 用户信息
 *     │                    ├─ 设备列表
 *     │                    ├─ 仓库状态
 *     │                    │    ├─ 温度监控
 *     │                    │    ├─ 光照监控
 *     │                    │    └─ 湿度监控
 *     │                    ├─ 告警记录
 *     │                    └─ 仓库开关
 *
 * ============================================================
 * 交互流程：
 * ============================================================
 *   登录前：全屏 LoginPage → 登录成功回调 → 进入主界面
 *   登录后：汉堡按钮 → 展开侧边栏 → 点菜单项 → 切换内容 + 关闭侧边栏
 */

import { LoginPage } from './Login';
import { DeviceListPage } from './DeviceList';
import { WarehouseStatusPage } from './WarehouseStatus';
import { AlarmLogPage } from './AlarmLog';
import { WarehouseSwitchPage } from './WarehouseSwitch';
import { apiService } from '../services/ApiService';

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
  @State currentPage: string = 'DeviceList';       // 当前显示的功能页
  @State currentLabel: string = '设备列表';         // 顶部标题

  // ====== 登录后的侧边栏菜单 ======
  private menusAfterLogin: SideMenu[] = [
    new SideMenu('UserInfo',         '用户信息', '👤'),
    new SideMenu('DeviceList',       '设备列表', '📋'),
    new SideMenu('WarehouseStatus',  '仓库状态', '🏭'),
    new SideMenu('AlarmLog',         '事件日志', '🔔'),
    new SideMenu('WarehouseSwitch',  '仓库开关', '⚡'),
  ];

  aboutToAppear(): void {
    console.info('[Index] 首页启动, 登录状态:', this.isLoggedIn);
  }

  // ====== 登录成功回调（传给 LoginPage）======
  onLoginSuccess = (): void => {
    this.isLoggedIn = true;
    this.currentPage = 'DeviceList';
    this.currentLabel = '设备列表';
    console.info('[Index] 登录成功，进入主界面');
  };

  // ====== 侧边栏菜单点击 ======
  onMenuClick(menu: SideMenu): void {
    this.currentPage = menu.pageId;
    this.currentLabel = menu.label;
    this.showSidebar = false;    // 选完自动关闭侧边栏
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
          if (this.currentPage === 'UserInfo') {
            this.UserInfoContent()
          } else if (this.currentPage === 'DeviceList') {
            DeviceListPage()
          } else if (this.currentPage === 'WarehouseStatus') {
            WarehouseStatusPage()
          } else if (this.currentPage === 'AlarmLog') {
            AlarmLogPage()
          } else if (this.currentPage === 'WarehouseSwitch') {
            WarehouseSwitchPage()
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
