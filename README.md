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
│   │       ├── Dashboard.ets           # 温度监控仪表盘
│   │       ├── LightMonitor.ets        # 光照监控页面
│   │       ├── GoodsManage.ets         # 货物管理页面
│   │       ├── AlarmLog.ets            # 告警记录页面
│   │       └── WarehouseSwitch.ets     # 仓库开关管理页面
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
| 温度监控 | 展示当前温度、目标温度、告警状态 | 骨架已完成 |
| 光照监控 | 展示光照强度、阈值、补光灯状态 | 骨架已完成 |
| 货物管理 | 货物总数、在库 / 出库统计 | 骨架已完成 |
| 告警记录 | 告警数量、未读数量、告警列表 | 骨架已完成 |
| 仓库开关 | 仓库门、通风扇、安防布防控制 | 骨架已完成 |

## 本地运行

1. 使用 DevEco Studio 打开本项目。
2. 等待 hvigor 同步完成。
3. 连接本地模拟器或真机。
4. 点击 **Run** 按钮启动应用。

## 开发计划

- [ ] 接入真实后端 API，替换本地 preferences 登录
- [ ] 完善温度监控仪表盘（数值卡片、趋势曲线、告警指示器）
- [ ] 完善光照监控页面（实时数值、阈值设置、补光灯控制）
- [ ] 完善货物管理页面（货物列表、新增 / 编辑 / 删除）
- [ ] 完善告警记录页面（筛选、分页、告警详情）
- [ ] 完善仓库开关页面（远程控制、状态反馈）
- [ ] 地图轨迹模块（侧边栏预留入口）

## 注意事项

- 当前登录注册使用本地 `preferences` 存储，仅用于本地演示。
- 各功能页面目前为骨架占位，后续会逐步补充业务逻辑。
- 项目目标设备类型为 `phone`。

## License

MIT
