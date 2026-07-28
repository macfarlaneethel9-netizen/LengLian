/**
 * Mock 数据生成器
 *
 * 当后端返回空数据时，生成 24 小时模拟遥测数据，
 * 确保页面始终有图表可渲染，不显示空白。
 */

import { TelemetryData } from './ApiService';

const DEFAULT_DEVICE_ID = 'tx-r-cc-001';

/**
 * 生成近 24 小时模拟采样数据（每小时 1 个点，共 24 点）。
 *
 * 参数范围对标实际冷链场景：
 *   温度 20~35℃（波动 ±5）
 *   湿度 40~60%
 *   光照 200~500 LUX
 */
export function generateMockTelemetry(deviceId: string): TelemetryData[] {
  let points: TelemetryData[] = [];
  let nowSec = Math.floor(Date.now() / 1000);
  // 24 小时 = 86400 秒，每小时一个点
  let stepSec = 3600;
  let baseTemp = 28.0;
  let baseHumi = 50.0;
  let baseLux = 350.0;

  for (let i = 23; i >= 0; i--) {
    // 用 sin 制造周期性波动，更像真实传感器数据
    let phase = (i / 24) * Math.PI * 2;
    let t = nowSec - i * stepSec;

    let temp = baseTemp + Math.sin(phase) * 5 + (Math.random() - 0.5) * 3;
    let humi = baseHumi + Math.cos(phase * 0.7) * 8 + (Math.random() - 0.5) * 4;
    let lux = baseLux + Math.sin(phase * 0.5) * 120 + (Math.random() - 0.5) * 40;

    points.push({
      ts: 0,
      temp: Math.round(temp * 10) / 10,
      humi: Math.round(humi * 10) / 10,
      lux: Math.round(lux),
      tilt: Math.round((Math.random() * 500 + 200)),
      motor: 0,
      alarm: 0,
      alarm_reason: '',
      scene: 'cold_chain',
      _ts: t
    } as TelemetryData);
  }

  return points;
}

/**
 * 当前时间的模拟快照数据
 */
export function generateMockSnapshot(): TelemetryData {
  let nowSec = Math.floor(Date.now() / 1000);
  return {
    ts: 0,
    temp: 28.5,
    humi: 52.3,
    lux: 380,
    tilt: 350,
    motor: 0,
    alarm: 0,
    alarm_reason: '',
    scene: 'cold_chain',
    _ts: nowSec
  } as TelemetryData;
}

/**
 * 默认设备名称
 */
export const MOCK_DEVICE_ID = DEFAULT_DEVICE_ID;
