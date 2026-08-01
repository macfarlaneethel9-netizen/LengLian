/**
 * AI 助手入口页
 *
 * 通过服务器 /api/ai/chat 代理访问 Mimo AI，密钥不保存在 APP。
 */

import { apiService, AiMessage } from '../services/ApiService';

@Component
export struct AiPage {
  onBack?: () => void;
  @State inputText: string = '';
  @State messages: AiMessage[] = [
    new AiMessage('assistant', '你好，我是冷链 AI 助手。你可以询问设备状态、告警和环境数据。')
  ];

  @State isSending: boolean = false;

  async sendMessage(): Promise<void> {
    let text = this.inputText.trim();
    if (text.length === 0 || this.isSending) {
      return;
    }
    this.messages = this.messages.concat([new AiMessage('user', text)]);
    this.inputText = '';
    this.isSending = true;
    try {
      let result = await apiService.chatAi(this.messages);
      if (result.message && result.message.content) {
        this.messages = this.messages.concat([
          new AiMessage('assistant', result.message.content)
        ]);
      }
    } catch (err) {
      this.messages = this.messages.concat([
        new AiMessage('assistant', 'AI 请求失败：' + String((err as Error).message || '请稍后重试'))
      ]);
    }
    this.isSending = false;
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
              if (message.role !== 'user') {
                Text('🤖')
                  .fontSize(22)
                  .margin({ right: 8 })
              }
              Text(message.content)
                .fontSize(15)
                .fontColor(message.role === 'user' ? '#FFFFFF' : '#333333')
                .lineHeight(22)
                .padding(12)
                .backgroundColor(message.role === 'user' ? '#1A73E8' : '#FFFFFF')
                .borderRadius(14)
                .layoutWeight(1)
              if (message.role === 'user') {
                Text('👤')
                  .fontSize(22)
                  .margin({ left: 8 })
              }
            }
            .width('100%')
            .justifyContent(message.role === 'user' ? FlexAlign.End : FlexAlign.Start)
          }
        }, (message: AiMessage) => message.content)
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
        Button(this.isSending ? '…' : '发送')
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
