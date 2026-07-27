/**
 * 设备管理模块
 *
 * 将温度监控、光照监控、货物管理三个功能合并到一个页面内，
 * 通过顶部 Tabs 进行切换。
 *
 * 运行链条：
 *   Index.currentPage = 'DeviceManage'
 *     → Index.build() 重新执行
 *     → DeviceManagePage() 渲染
 *     → Tabs 默认显示温度监控 Tab
 */

import { PageTitle, PlaceholderText } from '../components/CommonBuilders';

@Component
export struct DeviceManagePage {
  // 当前激活的 Tab 索引：0=温度监控 1=光照监控 2=货物管理
  @State currentTabIndex: number = 0;

  build() {
    Column() {
      PageTitle('设备管理')

      Tabs({ barPosition: BarPosition.Start }) {
        // ====== Tab 1：温度监控 ======
        TabContent() {
          TempTab()
        }
        .tabBar(this.TabBarBuilder('温度监控', 0))

        // ====== Tab 2：光照监控 ======
        TabContent() {
          LightTab()
        }
        .tabBar(this.TabBarBuilder('光照监控', 1))

        // ====== Tab 3：货物管理 ======
        TabContent() {
          GoodsTab()
        }
        .tabBar(this.TabBarBuilder('货物管理', 2))
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.currentTabIndex = index;
        console.info('[DeviceManage] 切换到 Tab:', index);
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding({ left: 16, right: 16 })
  }

  // ============================================================
  // @Builder：自定义 Tab 标签
  // ============================================================
  @Builder
  TabBarBuilder(label: string, index: number) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTabIndex === index ? '#1a73e8' : '#666')
        .padding({ top: 12, bottom: 12 })
    }
    .width('100%')
    .border({
      width: { bottom: this.currentTabIndex === index ? 2 : 0 },
      color: '#1a73e8'
    })
  }
}

// ============================================================
// 温度监控子组件
// ============================================================
@Component
struct TempTab {
  @State currentTemp: number = 25.5;   // 当前温度
  @State targetTemp: number = 4.0;     // 目标温度
  @State isAlarming: boolean = false;  // 是否告警
  @State updateTime: string = '--:--:--';

  build() {
    Column({ space: 16 }) {
      // 温度数值卡片
      Column() {
        PlaceholderText('温度数值卡片 — 后续课程添加')
        PlaceholderText(`当前温度: ${this.currentTemp}°C / 目标: ${this.targetTemp}°C`)
        PlaceholderText(`告警状态: ${this.isAlarming ? '告警中' : '正常'}`)
        PlaceholderText(`更新时间: ${this.updateTime}`)
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      // 温度曲线
      Column() {
        PlaceholderText('温度曲线/进度 — 后续课程添加')
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      // 告警指示器
      Column() {
        PlaceholderText('告警指示器 — 后续课程添加')
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 8, bottom: 16 })
  }
}

// ============================================================
// 光照监控子组件
// ============================================================
@Component
struct LightTab {
  @State currentLux: number = 0;         // 当前光照值（勒克斯）
  @State threshold: number = 500;        // 告警阈值
  @State isLightOn: boolean = false;     // 补光灯状态
  @State updateTime: string = '--:--:--';

  build() {
    Column({ space: 16 }) {
      // 光照数值卡片
      Column() {
        PlaceholderText('光照数值卡片 — 后续课程添加')
        PlaceholderText(`当前光照: ${this.currentLux} lux / 阈值: ${this.threshold} lux`)
        PlaceholderText(`补光灯: ${this.isLightOn ? '开启' : '关闭'}`)
        PlaceholderText(`更新时间: ${this.updateTime}`)
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      // 光照曲线
      Column() {
        PlaceholderText('光照曲线/进度 — 后续课程添加')
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      // 补光灯控制
      Column() {
        PlaceholderText('补光灯控制 — 后续课程添加')
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 8, bottom: 16 })
  }
}

// ============================================================
// 货物管理子组件
// ============================================================
@Component
struct GoodsTab {
  @State goodsCount: number = 0;      // 货物总数
  @State inStockCount: number = 0;    // 在库数量
  @State outboundCount: number = 0;   // 已出库数量

  build() {
    Column({ space: 16 }) {
      // 货物概览统计
      Column() {
        PlaceholderText('货物概览统计 — 后续课程添加')
        PlaceholderText(`总数: ${this.goodsCount} / 在库: ${this.inStockCount} / 出库: ${this.outboundCount}`)
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      // 货物卡片列表
      Column() {
        PlaceholderText('货物卡片列表 — 后续课程添加')
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 8, bottom: 16 })
  }
}
