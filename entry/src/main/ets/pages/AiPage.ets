/**
 * AI 助手入口页
 *
 * 当前提供 APP 内的 AI 对话入口和基础交互，后续可在 sendMessage()
 * 中接入实际的 AI 服务接口。
 */

class AiMessage {
  text: string;
  fromUser: boolean;

  constructor(text: string, fromUser: boolean) {
    this.text = text;
    this.fromUser = fromUser;
  }
}

@Component
export struct AiPage {
  onBack?: () => void;
  @State inputText: string = '';
  @State messages: AiMessage[] = [
    new AiMessage('你好，我是冷链 AI 助手。你可以询问设备状态、告警和环境数据。', false)
  ];

  sendMessage(): void {
    let text = this.inputText.trim();
    if (text.length === 0) {
      return;
    }
    this.messages = this.messages.concat([new AiMessage(text, true)]);
    this.inputText = '';
    this.messages = this.messages.concat([
      new AiMessage('AI 服务接口尚未配置，当前先保留对话入口。', false)
    ]);
  }

  build() {
    Column() {
      Row() {
        Button('‹')
          .fontSize(30)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .backgroundColor('#00000000')
          .onClick(() => {
            if (this.onBack) {
              this.onBack();
            }
          })
        Text('AI 助手')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 8, right: 16 })
      .backgroundColor('#FFFFFF')

      List({ space: 12 }) {
        ForEach(this.messages, (message: AiMessage) => {
          ListItem() {
            Row() {
              if (!message.fromUser) {
                Text('🤖')
                  .fontSize(22)
                  .margin({ right: 8 })
              }
              Text(message.text)
                .fontSize(15)
                .fontColor(message.fromUser ? '#FFFFFF' : '#333333')
                .lineHeight(22)
                .padding(12)
                .backgroundColor(message.fromUser ? '#1A73E8' : '#FFFFFF')
                .borderRadius(14)
                .layoutWeight(1)
              if (message.fromUser) {
                Text('👤')
                  .fontSize(22)
                  .margin({ left: 8 })
              }
            }
            .width('100%')
            .justifyContent(message.fromUser ? FlexAlign.End : FlexAlign.Start)
          }
        }, (message: AiMessage) => message.text)
      }
      .layoutWeight(1)
      .width('100%')
      .padding(16)
      .scrollBar(BarState.Off)

      Row({ space: 8 }) {
        TextInput({ placeholder: '输入你的问题' })
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(22)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.inputText = value;
          })
        Button('发送')
          .height(44)
          .width(72)
          .fontColor('#FFFFFF')
          .backgroundColor('#1A73E8')
          .borderRadius(22)
          .onClick(() => {
            this.sendMessage();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 14 })
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
