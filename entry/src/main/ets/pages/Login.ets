/**
 * 用户登录页面
 *
 * 运行链条说明（后续课程逐一展开）：
 *   1. @Entry 标记 → 这是一个页面入口，导航系统可以路由到这里
 *   2. @Component 标记 → 这是一个 ArkUI 组件，拥有 build() 方法
 *   3. @State 变量 → 状态驱动渲染，变量变化 → UI 自动刷新
 *   4. build() → 每次状态变化都会重新执行，生成最新的 UI 树
 */
@Entry
@Component
struct Login {
  @State account: string = '';
  @State password: string = '';
  @State errorMsg: string = '';

  build() {
    Column() {
      // 标题
      Text('用户登录')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 40 })

      // 登录表单区域（第2课：布局；第3课：样式；第4课：交互）
      Column() {
        Text('账号输入框 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })

        Text('密码输入框 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 12 })

        Text('登录按钮 — 后续课程添加')
          .fontSize(14)
          .fontColor('#999')
          .margin({ top: 24 })
      }
      .width('100%')
      .padding(24)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
