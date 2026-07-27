/**
 * 仓库开关管理页面
 */

@Component
export struct WarehouseSwitchPage {
  @State doorOpen: boolean = false;       // 仓库门开关状态
  @State fanOn: boolean = false;          // 通风扇状态
  @State alarmEnabled: boolean = true;    // 安防布防状态
  @State lastAction: string = '无操作';   // 最后一次操作记录

  build() {
    Column() {
      Text('仓库开关管理')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Column() {
        Text('仓库门开关 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })
        Text('通风扇控制 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })
        Text('安防布防 — 后续课程添加')
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
