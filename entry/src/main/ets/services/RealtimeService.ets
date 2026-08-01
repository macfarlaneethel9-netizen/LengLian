/**
 * 实时数据服务（观察者模式，全局单例）
 *
 * 定时轮询后端 GET /api/devices，获取设备最新遥测，
 * 通过回调数组通知所有注册页面，驱动 UI 实时刷新。
 * 一个轮询周期只发一次 HTTP 请求，多个页面共享同一份数据。
 *
 * ============================================================
 * 完整数据链路：
 * ============================================================
 *   RK2206 开发板
 *     → MQTT → 华为云 IoTDA
 *     → AMQP → 后端服务器 (123.60.36.30)
 *     → REST API → App RealtimeService (本文件)
 *     → 回调数组 → Dashboard / WarehouseSwitch / DeviceList 等页面
 *
 * ============================================================
 * 使用方式：
 * ============================================================
 *   realtimeService.onUpdate(callback)   // 注册观察者
 *   realtimeService.start(3000)          // 开始 3 秒轮询
 *   realtimeService.stop()               // 停止轮询
 */

import { apiService, DeviceInfo } from './ApiService';

export type DeviceUpdateCallback = (devices: DeviceInfo[]) => void;

class RealtimeService {
  private timer: number = -1;
  private intervalMs: number = 3000;      // 3秒轮询一次
  private callbacks: DeviceUpdateCallback[] = [];

  /**
   * 注册回调：每次拿到新数据就通知你
   */
  onUpdate(cb: DeviceUpdateCallback): void {
    this.callbacks.push(cb);
  }

  /**
   * 取消注册
   */
  offUpdate(cb: DeviceUpdateCallback): void {
    let idx = this.callbacks.indexOf(cb);
    if (idx >= 0) { this.callbacks.splice(idx, 1); }
  }

  /**
   * 开始轮询
   */
  start(intervalMs?: number): void {
    if (intervalMs) { this.intervalMs = intervalMs; }
    console.info('[Realtime] 启动轮询，间隔:', this.intervalMs, 'ms');

    // 立刻拉一次
    this.poll();

    // 定时拉
    this.timer = setInterval(() => {
      this.poll();
    }, this.intervalMs);
  }

  /**
   * 停止轮询
   */
  stop(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
      console.info('[Realtime] 停止轮询');
    }
  }

  /**
   * 拉取设备列表，通知所有回调
   */
  private async poll(): Promise<void> {
    try {
      let result = await apiService.getDevices(1, 50);
      for (let cb of this.callbacks) {
        cb(result.items);
      }
    } catch (err) {
      console.error('[Realtime] 轮询失败:', JSON.stringify(err));
    }
  }
}

export const realtimeService = new RealtimeService();
