/**
 * 设备管理页面
 *
 * 目标功能：
 *   - 设备列表（名称、编号、在线状态）
 *   - 设备详情（型号、固件版本、电池电量）
 *   - 设备绑定 / 解绑
 *   - 固件升级入口
 */
@Entry
@Component
struct DeviceManage {
  @State deviceCount: number = 0;   // 设备总数
  @State onlineCount: number = 0;   // 在线设备数

  build() {
    Column() {
      Text('设备管理')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 20 })

      // 设备概览
      Text('设备概览统计 — 后续课程添加')
        .fontSize(14)
        .fontColor('#999')
        .margin({ top: 12 })

      // 设备列表
      Column() {
        Text('设备卡片列表 — 后续课程添加')
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
