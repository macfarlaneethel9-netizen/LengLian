/**
 * 温度监控仪表盘
 *
 * @Component 子组件，由 Index 根据 currentPage 状态切换显示。
 * 运行链条：
 *   Index.currentPage = 'Dashboard'
 *     → Index.build() 重新执行
 *     → if 分支命中 → DashboardPage() 渲染
 */

@Component
export struct DashboardPage {
  @State currentTemp: number = 25.5;
  @State targetTemp: number = 4.0;
  @State isAlarming: boolean = false;
  @State updateTime: string = '--:--:--';

  build() {
    Column() {
      Text('温度监控仪表盘')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

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
