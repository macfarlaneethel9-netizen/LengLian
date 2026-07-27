/**
 * 告警记录页面
 *
 * 目标功能：
 *   - 告警列表（时间、类型、设备名、温度值）
 *   - 告警级别区分（严重 / 警告 / 提示）
 *   - 告警已读 / 未读状态
 *   - 点击查看告警详情
 *   - 筛选：按时间 / 按类型 / 按设备
 */
@Entry
@Component
struct AlarmLog {
  @State alarmCount: number = 0;       // 告警总数
  @State unreadCount: number = 0;      // 未读告警数

  build() {
    Column() {
      Text('告警记录')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 20 })

      // 筛选栏
      Text('告警筛选栏 — 后续课程添加')
        .fontSize(14)
        .fontColor('#999')
        .margin({ top: 12 })

      // 告警列表
      Column() {
        Text('告警条目列表 — 后续课程添加')
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
