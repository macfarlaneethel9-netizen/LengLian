/**
 * 光照监控页面
 */

@Component
export struct LightMonitorPage {
  @State currentLux: number = 0;         // 当前光照值（勒克斯）
  @State threshold: number = 500;        // 告警阈值
  @State isLightOn: boolean = false;     // 补光灯状态
  @State updateTime: string = '--:--:--'; // 最后更新时间

  build() {
    Column() {
      Text('光照监控')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Column() {
        Text('光照数值卡片 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })
        Text('光照曲线/进度 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })
        Text('补光灯控制 — 后续课程添加')
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
