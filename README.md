# 冷链监控系统（LengLian）

一个基于 HarmonyOS / OpenHarmony 的手机端冷链仓库监控应用。

## 项目简介

本应用用于实时监控冷链仓库的环境状态，包括温度、光照等关键指标，并提供货物管理、告警记录、仓库开关控制等功能。

## 技术栈

- **平台**：HarmonyOS / OpenHarmony
- **开发语言**：ArkTS
- **UI 框架**：ArkUI
- **SDK 版本**：6.1.1(24)
- **构建工具**：hvigor
- **包名**：`com.example.lenglian`

## 项目结构

```
LengLian/
├── AppScope/                           # 应用级配置与资源
│   ├── app.json5                       # 应用基本信息（包名、版本、图标）
│   └── resources/
│
├── entry/                              # 入口模块
│   ├── src/main/ets/
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets        # 应用入口 Ability
│   │   ├── entrybackupability/
│   │   │   └── EntryBackupAbility.ets  # 备份扩展 Ability
│   │   └── pages/                      # 页面组件
│   │       ├── Index.ets               # 主框架（路由 + 侧边栏）
│   │       ├── Login.ets               # 登录 / 注册页面
│   │       ├── DeviceManage.ets        # 设备管理（温度/光照/货物）
│   │       ├── AlarmLog.ets            # 告警记录页面
│   │       └── WarehouseSwitch.ets     # 仓库开关管理页面
│   │   └── components/                 # 公共组件
│   │       └── CommonBuilders.ets      # 通用 UI 构建器
│   └── src/main/resources/             # 模块资源（字符串、颜色、媒体等）
│
├── build-profile.json5                 # 编译配置
├── oh-package.json5                    # 依赖配置
├── oh-package-lock.json5               # 依赖锁定文件
└── hvigorfile.ts                       # 构建入口脚本
```

## 功能模块

| 页面 | 说明 | 状态 |
|------|------|------|
| 登录 / 注册 | 基于本地 preferences 存储账号密码 | 已实现 |
| 设备管理 | 温度监控 / 光照监控 / 货物管理，Tab 切换 | 骨架已完成 |
| 告警记录 | 告警数量、未读数量、告警列表 | 骨架已完成 |
| 仓库开关 | 仓库门、通风扇、安防布防控制 | 骨架已完成 |

## 本地运行

1. 使用 DevEco Studio 打开本项目。
2. 等待 hvigor 同步完成。
3. 连接本地模拟器或真机。
4. 点击 **Run** 按钮启动应用。

## 开发计划

- [ ] 接入真实后端 API，替换本地 preferences 登录
- [ ] 完善设备管理模块（温度/光照/货物各 Tab 的详细功能）
- [ ] 完善告警记录页面（筛选、分页、告警详情）
- [ ] 完善仓库开关页面（远程控制、状态反馈）

## 注意事项

- 当前登录注册使用本地 `preferences` 存储，仅用于本地演示。
- 各功能页面目前为骨架占位，后续会逐步补充业务逻辑。
- 项目目标设备类型为 `phone`。

## License

MIT
