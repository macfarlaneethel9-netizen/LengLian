/**
 * 温度监控仪表盘
 *
 * 目标功能：
 *   - 实时温度数值展示
 *   - 温度曲线 / 进度条
 *   - 高温/低温告警色
 *   - 刷新间隔显示
 */
@Entry
@Component
struct Dashboard {
  @State currentTemp: number = 25.5;      // 当前温度
  @State targetTemp: number = 4.0;        // 目标温度（冷链设定）
  @State isAlarming: boolean = false;     // 是否告警
  @State updateTime: string = '--:--:--'; // 最后更新时间

  build() {
    Column() {
      Text('温度监控仪表盘')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 20 })

      // 仪表盘卡片区域（后续课程逐块实现）
      Column() {
        Text('温度数值卡片 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })

        Text('温度曲线/进度 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })

        Text('告警指示器 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })
      }
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
