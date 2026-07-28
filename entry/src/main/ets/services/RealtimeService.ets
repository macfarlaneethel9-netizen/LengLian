/**
 * 实时数据服务
 *
 * 定时轮询后端 API，获取设备最新遥测数据，
 * 驱动 App 页面实时刷新。回调模式通知各页面。
 *
 * 数据来源：后端 123.60.36.30/api/devices
 * （后端持续从华为云 IoT AMQP 接收设备上报数据）
 *
 * ============================================================
 * 完整数据链路：
 * ============================================================
 *   RK2206 开发板
 *     → MQTT → 华为云 IoT
 *     → AMQP → 后端服务器 (123.60.36.30)
 *     → REST API → App RealtimeService (本文件)
 *     → 回调 → 页面 UI 刷新
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
