import { router } from '@kit.ArkUI';

/**
 * 首页导航 — 开发阶段的功能入口
 *
 * 后续构建完整 app 时，这里会替换为底部 Tab 导航或侧滑菜单。
 * 现在先做按钮清单，方便逐个打开功能页面调试。
 */
@Entry
@Component
struct Index {
  build() {
    Column({ space: 16 }) {
      Text('冷链监控系统')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 24 })

      this.NavButton('用户登录', 'pages/Login')
      this.NavButton('温度监控仪表盘', 'pages/Dashboard')
      this.NavButton('订单列表', 'pages/OrderList')
      this.NavButton('设备管理', 'pages/DeviceManage')
      this.NavButton('告警记录', 'pages/AlarmLog')
      this.NavButton('地图轨迹', 'pages/MapTrack')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding(24)
  }

  @Builder
  NavButton(label: string, target: string) {
    Button(label)
      .width('100%')
      .height(48)
      .fontSize(16)
      .backgroundColor('#FFFFFF')
      .fontColor('#333333')
      .borderRadius(8)
      .shadow({ radius: 4, color: '#00000010', offsetY: 2 })
      .onClick(() => {
        router.pushUrl({ url: target });
      })
  }
}
