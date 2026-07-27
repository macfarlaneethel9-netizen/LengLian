/**
 * 用户登录页面
 *
 * ============================================================
 * 运行链条（完整版）：
 * ============================================================
 *
 *   App 启动 → isLoggedIn == false → 全屏渲染 LoginPage
 *
 *   【登录模式】
 *   用户输入账号 → TextInput.onChange → this.account = value
 *   用户输入密码 → TextInput.onChange → this.password = value
 *   用户点"登录" → onClick
 *     → 校验：账号/密码不能为空
 *     → 查询本地存储中是否有匹配的注册用户
 *     → 匹配成功 → onLoginSuccess() → Index 切换到主界面
 *     → 匹配失败 → 显示错误提示
 *
 *   【注册模式】（点"去注册"切换）
 *   用户输入账号 → this.regAccount
 *   用户输入密码 → this.regPassword
 *   用户确认密码 → this.regConfirm
 *   用户点"注册" → onClick
 *     → 校验：两次密码一致、非空
 *     → 存入本地存储（preferences）
 *     → 提示成功 → 切回登录模式
 *
 * ============================================================
 * 本课涉及的核心概念：
 * ============================================================
 *   TextInput            — 文本输入框组件
 *   InputType.Password   — 密码模式（输入内容自动隐藏）
 *   InputType.Normal     — 普通文本模式
 *   .onChange()          — 输入变化回调，每次按键都触发
 *   .placeholder         — 输入框占位提示文字
 *   showPasswordIcon     — 密码可见/不可见切换按钮
 *   @State               — 状态变量，和 TextInput 双向绑定
 */

import { preferences } from '@kit.ArkData';

// ---------- 本地存储 key ----------
const STORE_NAME = 'lenglian_user';

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
      Button('登  录')
        .width('100%')
        .height(48)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#1a73e8')
        .borderRadius(8)
        .margin({ top: 8 })
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
      Button('注  册')
        .width('100%')
        .height(48)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#4CAF50')
        .borderRadius(8)
        .margin({ top: 8 })
        .onClick(() => {
          this.handleRegister();
        })
    }
    .width('100%')
    .padding({ left: 32, right: 32 })
  }

  // ============================================================
  // 登录逻辑
  // ============================================================
  handleLogin(): void {
    // 1. 基础校验：不能为空
    if (this.account.trim() === '' || this.password.trim() === '') {
      this.errorMsg = '账号和密码不能为空';
      return;
    }

    // 2. 查询本地存储中是否有匹配的注册用户
    //    后续课程连接到真实后端时，这里替换为网络请求
    try {
      let context = this.getUIContext().getHostContext();
      let prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
      let savedPassword = prefs.getSync(this.account, '') as string;

      if (savedPassword === '') {
        this.errorMsg = '账号不存在，请先注册';
      } else if (savedPassword === this.password) {
        console.info('[Login] 登录成功，账号:', this.account);
        if (this.onLoginSuccess) {
          this.onLoginSuccess();
        }
      } else {
        this.errorMsg = '密码错误';
      }
      prefs.flush();
    } catch (err) {
      console.error('[Login] 读取存储失败:', JSON.stringify(err));
      this.errorMsg = '系统错误，请重试';
    }
  }

  // ============================================================
  // 注册逻辑
  // ============================================================
  handleRegister(): void {
    // 1. 基础校验
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

    // 2. 检查账号是否已存在
    try {
      let context = this.getUIContext().getHostContext();
      let prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
      let exist = prefs.getSync(this.regAccount, '') as string;

      if (exist !== '') {
        this.errorMsg = '该账号已被注册';
        prefs.flush();
        return;
      }

      // 3. 保存注册信息到本地存储
      prefs.putSync(this.regAccount, this.regPassword);
      prefs.flush();

      console.info('[Login] 注册成功，账号:', this.regAccount);

      // 4. 清空注册表单，切换到登录模式
      this.regAccount = '';
      this.regPassword = '';
      this.regConfirm = '';
      this.isLoginMode = true;
      this.errorMsg = '';
    } catch (err) {
      console.error('[Login] 保存注册信息失败:', JSON.stringify(err));
      this.errorMsg = '注册失败，请重试';
    }
  }
}
