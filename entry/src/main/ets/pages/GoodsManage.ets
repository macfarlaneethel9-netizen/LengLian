/**
 * 货物管理页面
 */

@Component
export struct GoodsManagePage {
  @State goodsCount: number = 0;          // 货物总数
  @State inStockCount: number = 0;        // 在库数量
  @State outboundCount: number = 0;       // 已出库数量

  build() {
    Column() {
      Text('货物管理')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Text('货物概览统计 — 后续课程添加')
        .fontSize(14)
        .fontColor('#999')
        .margin({ top: 12 })

      Column() {
        Text('货物卡片列表 — 后续课程添加')
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
