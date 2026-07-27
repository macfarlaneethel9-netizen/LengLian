/**
 * 货物/订单列表页面
 *
 * 目标功能：
 *   - 货物列表展示（名称、状态、温度、时间）
 *   - 列表项点击跳转详情
 *   - 下拉刷新
 *   - 状态筛选（在途 / 已签收 / 异常）
 */
@Entry
@Component
struct OrderList {
  // 后续替换为实际数据模型（第5课讲 ForEach + 数据驱动）
  @State itemCount: number = 0;

  build() {
    Column() {
      Text('订单列表')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 20 })

      // 筛选栏
      Text('状态筛选栏 — 后续课程添加')
        .fontSize(14)
        .fontColor('#999')
        .margin({ top: 12 })

      // 列表区域
      Column() {
        Text('订单卡片列表 — 后续课程添加')
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
