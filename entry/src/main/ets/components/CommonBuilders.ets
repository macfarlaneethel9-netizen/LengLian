/**
 * 通用 UI 构建器
 *
 * 供各页面复用的 @Builder 与 @Component，减少重复样式代码。
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

