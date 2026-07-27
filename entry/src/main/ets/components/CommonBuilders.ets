/**
 * 通用 UI 构建器
 *
 * 供各页面复用的 @Builder，减少重复样式代码。
 */

/**
 * 页面大标题
 */
@Builder
export function PageTitle(title: string) {
  Text(title)
    .fontSize(28)
    .fontWeight(FontWeight.Bold)
    .fontColor('#333')
    .margin({ top: 20, bottom: 20 })
}

/**
 * 占位提示文本
 */
@Builder
export function PlaceholderText(text: string) {
  Text(text)
    .fontSize(14)
    .fontColor('#999')
    .margin({ top: 12 })
}

/**
 * 内容卡片容器
 */
@Builder
export function ContentCard(content: () => void) {
  Column() {
    content()
  }
  .width('100%')
  .padding(24)
  .backgroundColor('#FFFFFF')
  .borderRadius(12)
  .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
}
