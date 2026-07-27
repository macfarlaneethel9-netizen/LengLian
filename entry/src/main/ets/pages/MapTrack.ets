/**
 * 地图轨迹页面
 *
 * 目标功能：
 *   - 地图显示运输车辆当前位置
 *   - 运输轨迹回放
 *   - 途径点标注（出发地 / 中转站 / 目的地）
 *   - 预计到达时间展示
 */
@Entry
@Component
struct MapTrack {
  @State vehicleNo: string = '--';     // 车牌号
  @State eta: string = '--:--';        // 预计到达时间
  @State distance: number = 0;         // 剩余距离（km）

  build() {
    Column() {
      Text('地图轨迹')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 20 })

      // 地图占位区域
      Column() {
        Text('地图组件区域 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 60 })
      }
      .width('100%')
      .height(240)
      .backgroundColor('#E8E8E8')
      .borderRadius(12)
      .margin({ left: 16, right: 16 })

      // 轨迹信息栏
      Column() {
        Text('轨迹信息卡片 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })
      }
      .width('100%')
      .layoutWeight(1)
      .padding(24)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
