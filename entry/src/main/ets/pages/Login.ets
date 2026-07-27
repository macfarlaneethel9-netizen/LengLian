/**
 * 用户登录页面
 *
 * 对接后端 POST /api/auth/login 和 POST /api/auth/register
 */

import { apiService } from '../services/ApiService';

@Component
export struct LoginPage {
  // ------ 父组件回调 ------
  onLoginSuccess?: () => void;

  // ------ 模式切换 ------
  @State isLoginMode: boolean = true;    // true=登录  false=注册

  // ------ 登录表单 ------
  @State account: string = '';
  @State password: string = '';

  // ------ 注册表单 ------
  @State regAccount: string = '';
  @State regPassword: string = '';
  @State regConfirm: string = '';

  // ------ 错误提示 ------
  @State errorMsg: string = '';
  @State isSubmitting: boolean = false; // 防止重复提交

  build() {
    Column() {
      // ========== Logo 区域 ==========
      Column() {
        Text('🧊')
          .fontSize(56)
        Text('冷链监控系统')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .margin({ top: 8 })
        Text('Cold Chain Monitor')
          .fontSize(13)
          .fontColor('#999')
          .margin({ top: 4 })
      }
      .margin({ top: 80, bottom: 40 })

      // ========== 表单区域 ==========
      if (this.isLoginMode) {
        this.LoginForm()
      } else {
        this.RegisterForm()
      }

      // ========== 切换登录/注册 ==========
      Row() {
        Text(this.isLoginMode ? '没有账号？' : '已有账号？')
          .fontSize(13)
          .fontColor('#999')
        Text(this.isLoginMode ? '去注册' : '去登录')
          .fontSize(13)
          .fontColor('#1a73e8')
          .margin({ left: 4 })
          .onClick(() => {
            this.isLoginMode = !this.isLoginMode;
            this.errorMsg = '';
          })
      }
      .margin({ top: 24 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ============================================================
  // @Builder：登录表单
  // ============================================================
  @Builder
  LoginForm() {
    Column({ space: 16 }) {
      // ---- 错误提示 ----
      if (this.errorMsg !== '') {
        Text(this.errorMsg)
          .fontSize(13)
          .fontColor('#F44336')
          .width('100%')
          .padding(12)
          .backgroundColor('#FFEBEE')
          .borderRadius(8)
      }

      // ---- 账号输入框 ----
      TextInput({ placeholder: '请输入账号' })
        .type(InputType.Normal)
        .width('100%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ width: 1, color: '#E0E0E0' })
        .onChange((value: string) => {
          // 每次输入变化都同步到 @State
          this.account = value;
          this.errorMsg = '';  // 输入时清除旧错误
        })

      // ---- 密码输入框 ----
      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)           // ← 密码模式：显示为 ***
        .showPasswordIcon(true)             // ← 右侧小眼睛图标，点击切换可见
        .width('100%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ width: 1, color: '#E0E0E0' })
        .onChange((value: string) => {
          this.password = value;
          this.errorMsg = '';
        })

      // ---- 登录按钮 ----
      Button(this.isSubmitting ? '登录中...' : '登  录')
        .width('100%')
        .height(48)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(this.isSubmitting ? '#93C5FD' : '#1a73e8')
        .borderRadius(8)
        .margin({ top: 8 })
        .enabled(!this.isSubmitting)
        .onClick(() => {
          this.handleLogin();
        })
    }
    .width('100%')
    .padding({ left: 32, right: 32 })
  }

  // ============================================================
  // @Builder：注册表单
  // ============================================================
  @Builder
  RegisterForm() {
    Column({ space: 16 }) {
      // ---- 错误提示 ----
      if (this.errorMsg !== '') {
        Text(this.errorMsg)
          .fontSize(13)
          .fontColor('#F44336')
          .width('100%')
          .padding(12)
          .backgroundColor('#FFEBEE')
          .borderRadius(8)
      }

      // ---- 注册账号 ----
      TextInput({ placeholder: '请设置账号（至少3位）' })
        .type(InputType.Normal)
        .width('100%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ width: 1, color: '#E0E0E0' })
        .onChange((value: string) => {
          this.regAccount = value;
          this.errorMsg = '';
        })

      // ---- 注册密码 ----
      TextInput({ placeholder: '请设置密码（至少6位）' })
        .type(InputType.Password)
        .showPasswordIcon(true)
        .width('100%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ width: 1, color: '#E0E0E0' })
        .onChange((value: string) => {
          this.regPassword = value;
          this.errorMsg = '';
        })

      // ---- 确认密码 ----
      TextInput({ placeholder: '请再次输入密码' })
        .type(InputType.Password)
        .showPasswordIcon(true)
        .width('100%')
        .height(48)
        .fontSize(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ width: 1, color: '#E0E0E0' })
        .onChange((value: string) => {
          this.regConfirm = value;
          this.errorMsg = '';
        })

      // ---- 注册按钮 ----
      Button(this.isSubmitting ? '注册中...' : '注  册')
        .width('100%')
        .height(48)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor(this.isSubmitting ? '#A5D6A7' : '#4CAF50')
        .borderRadius(8)
        .margin({ top: 8 })
        .enabled(!this.isSubmitting)
        .onClick(() => {
          this.handleRegister();
        })
    }
    .width('100%')
    .padding({ left: 32, right: 32 })
  }

  // ============================================================
  // 登录逻辑 → 对接后端 POST /api/auth/login
  // ============================================================
  async handleLogin(): Promise<void> {
    if (this.account.trim() === '' || this.password.trim() === '') {
      this.errorMsg = '账号和密码不能为空';
      return;
    }

    this.isSubmitting = true;
    this.errorMsg = '';

    try {
      await apiService.login(this.account.trim(), this.password);
      console.info('[Login] 登录成功, 账号:', this.account);
      if (this.onLoginSuccess) {
        this.onLoginSuccess();
      }
    } catch (err: Object) {
      let msg = String((err as Error).message || '');
      // 后端返回 401 时尝试从响应中提取 detail
      if (msg.includes('401') || msg.includes('Invalid')) {
        this.errorMsg = '用户名或密码错误';
      } else if (msg.includes('网络')) {
        this.errorMsg = '网络请求失败，请检查网络连接';
      } else {
        this.errorMsg = msg || '登录失败，请重试';
      }
    }
    this.isSubmitting = false;
  }

  // ============================================================
  // 注册逻辑 → 对接后端 POST /api/auth/register
  // ============================================================
  async handleRegister(): Promise<void> {
    if (this.regAccount.trim().length < 3) {
      this.errorMsg = '账号至少需要3位字符';
      return;
    }
    if (this.regPassword.length < 6) {
      this.errorMsg = '密码至少需要6位字符';
      return;
    }
    if (this.regPassword !== this.regConfirm) {
      this.errorMsg = '两次输入的密码不一致';
      return;
    }

    this.isSubmitting = true;
    this.errorMsg = '';

    try {
      await apiService.register(this.regAccount.trim(), this.regPassword);
      console.info('[Login] 注册成功, 账号:', this.regAccount);

      // 清空注册表单，切换到登录模式
      this.regAccount = '';
      this.regPassword = '';
      this.regConfirm = '';
      this.isLoginMode = true;
    } catch (err: Object) {
      let msg = String((err as Error).message || '');
      if (msg.includes('409') || msg.includes('already')) {
        this.errorMsg = '该账号已被注册';
      } else if (msg.includes('网络')) {
        this.errorMsg = '网络请求失败，请检查网络连接';
      } else {
        this.errorMsg = msg || '注册失败，请重试';
      }
    }
    this.isSubmitting = false;
  }
}
