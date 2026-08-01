/**
 * API 服务层（全局单例）
 *
 * 封装对冷链监控后端的所有 HTTP 请求。
 * Base URL: http://123.60.36.30/api
 *
 * 功能模块：
 *   - 认证：login / register → JWT Token
 *   - 设备：getDevices / getDevice / createDevice
 *   - 遥测：getTelemetry（历史数据）
 *   - 控制：sendCommand（转发 IoTDA 命令到硬件）
 *   - 事件：getEvents（告警/命令/上下线日志）
 *   - AI：  chatAi（后端代理 Mimo，密钥不存 APP）
 *   - 诊断：healthCheck
 *
 * 设计要点：
 *   - Bearer Token 自动附加
 *   - 连接/读取双重超时 10s
 *   - HTTP 错误解析后端 detail 字段
 *   - 每个请求完整日志（method/path/耗时/preview）
 */

import { http } from '@kit.NetworkKit';

// ============================================================
// 数据类型 — 字段与后端 JSON 严格对齐
// ============================================================

export interface UserInfo {
  id: number;
  username: string;
  nickname: string;
  role: string;
  created_at?: number;
}

export interface LoginResult {
  token: string;
  user: UserInfo;
}

export class AiMessage {
  role: string;
  content: string;

  constructor(role: string, content: string) {
    this.role = role;
    this.content = content;
  }
}

class AiChatBody {
  messages: AiMessage[];

  constructor(messages: AiMessage[]) {
    this.messages = messages;
  }
}

export interface AiChatResult {
  ok: boolean;
  model: string;
  message: AiMessage;
}

export interface TelemetryData {
  ts: number;
  temp: number;
  humi: number;
  lux: number;
  tilt: number;
  motor: number;
  auto_mode?: number;
  ac?: number;
  temp_threshold_enabled?: number;
  humi_threshold_enabled?: number;
  illumination_threshold_enabled?: number;
  alarm: number;
  alarm_reason: string;
  scene: string;
  _ts: number;
}

export interface DeviceInfo {
  device_id: string;
  online: boolean;
  fw: string;
  last_seen: number;
  last_telemetry: TelemetryData;
  name: string;
  location: string;
  user_id: number;
  created_at: number;
  updated_at: number;
}

export interface DeviceListResult {
  items: DeviceInfo[];
  total: number;
  page: number;
  page_size: number;
}

export interface TelemetryListResult {
  device_id: string;
  items: TelemetryData[];
  total: number;
  page: number;
  page_size: number;
}

export interface EventItem {
  id: number;
  device_id: string;
  kind: string;
  detail: object;
  ts: number;
}

export interface EventListResult {
  events: EventItem[];
}

// ============================================================
// 安全格式化工具 — 防御 telemetry 字段为 null/undefined
// ============================================================

export function fmtTemp(telemetry: TelemetryData | undefined | null): string {
  if (!telemetry || typeof telemetry.temp !== 'number') {
    return '--';
  }
  return telemetry.temp.toFixed(1);
}

export function fmtHumi(telemetry: TelemetryData | undefined | null): string {
  if (!telemetry || typeof telemetry.humi !== 'number') {
    return '--';
  }
  return telemetry.humi.toFixed(1);
}

export function fmtLux(telemetry: TelemetryData | undefined | null): string {
  if (!telemetry || typeof telemetry.lux !== 'number') {
    return '--';
  }
  return telemetry.lux.toFixed(0);
}

export function getTemp(telemetry: TelemetryData | undefined | null): number {
  return (telemetry && typeof telemetry.temp === 'number') ? telemetry.temp : 0;
}

export function getHumi(telemetry: TelemetryData | undefined | null): number {
  return (telemetry && typeof telemetry.humi === 'number') ? telemetry.humi : 0;
}

export function getLux(telemetry: TelemetryData | undefined | null): number {
  return (telemetry && typeof telemetry.lux === 'number') ? telemetry.lux : 0;
}

export function getTilt(telemetry: TelemetryData | undefined | null): number {
  return (telemetry && typeof telemetry.tilt === 'number') ? telemetry.tilt : 0;
}

export function getAlarm(telemetry: TelemetryData | undefined | null): number {
  return (telemetry && typeof telemetry.alarm === 'number') ? telemetry.alarm : 0;
}

export function getAlarmReason(telemetry: TelemetryData | undefined | null): string {
  return (telemetry && typeof telemetry.alarm_reason === 'string') ? telemetry.alarm_reason : '';
}

// ============================================================
// 请求体类
// ============================================================

class LoginBody {
  username: string;
  password: string;

  constructor(username: string, password: string) {
    this.username = username;
    this.password = password;
  }
}

class CreateDeviceBody {
  device_id: string;
  name?: string;
  location?: string;

  constructor(deviceId: string, name?: string, location?: string) {
    this.device_id = deviceId;
    if (name) { this.name = name; }
    if (location) { this.location = location; }
  }
}

class RegisterBody {
  username: string;
  password: string;
  nickname?: string;

  constructor(username: string, password: string, nickname?: string) {
    this.username = username;
    this.password = password;
    if (nickname) {
      this.nickname = nickname;
    }
  }
}

// ============================================================
// ApiService 单例
// ============================================================

const BASE_URL = 'http://123.60.36.30/api';

class ApiService {
  token: string = '';
  currentUser: UserInfo | null = null;

  // ----------------------------------------------------------
  // 构建 headers
  // ----------------------------------------------------------
  private buildHeaders(): Record<string, string> {
    let h: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    if (this.token) {
      h['Authorization'] = `Bearer ${this.token}`;
    }
    return h;
  }

  // ----------------------------------------------------------
  // 底层 HTTP 请求 — 全量日志
  // ----------------------------------------------------------
  private async request(
    method: http.RequestMethod,
    path: string,
    body?: Object
  ): Promise<string> {
    let url = BASE_URL + path;
    let headers = this.buildHeaders();
    let hasToken = this.token.length > 0;

    // 阶段四：记录每次请求的完整信息
    console.info(
      `[ApiService] --> ${http.RequestMethod[method]} ${path} | token=${hasToken}`
    );

    let httpRequest = http.createHttp();

    try {
      let startMs = Date.now();
      let resp = await httpRequest.request(url, {
        method: method,
        header: headers,
        extraData: body ? JSON.stringify(body) : undefined,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      let elapsed = Date.now() - startMs;
      let bodyStr = (resp.result as string) || '';
      let preview = bodyStr.length > 200 ? bodyStr.substring(0, 200) + '...' : bodyStr;

      console.info(
        `[ApiService] <-- ${http.RequestMethod[method]} ${path} | ${elapsed}ms | len=${bodyStr.length} | preview=${preview}`
      );

      // HTTP 401/4xx 不能继续按成功响应解析，否则登录错误响应没有 token，
      // 后续读取 token.length/substring 会变成“undefined”异常。
      if (resp.responseCode < 200 || resp.responseCode >= 300) {
        let detail = bodyStr;
        try {
          let errorBody = JSON.parse(bodyStr) as Record<string, string>;
          if (errorBody['detail']) {
            detail = errorBody['detail'];
          }
        } catch (_) {
          // 保留原始响应文本
        }
        httpRequest.destroy();
        throw new Error(`HTTP ${resp.responseCode}: ${detail}`);
      }

      httpRequest.destroy();
      return bodyStr;
    } catch (err) {
      httpRequest.destroy();
      let message = String((err as Error).message || '');
      if (message.startsWith('HTTP ')) {
        throw new Error(message);
      }
      console.error(
        `[ApiService] ERR ${http.RequestMethod[method]} ${path} | ${JSON.stringify(err)}`
      );
      throw new Error('网络请求失败，请检查网络连接');
    }
  }

  // ----------------------------------------------------------
  // 用户认证
  // ----------------------------------------------------------

  async login(username: string, password: string): Promise<LoginResult> {
    let body = new LoginBody(username, password);
    let data = await this.request(http.RequestMethod.POST, '/auth/login', body);
    let result = JSON.parse(data) as LoginResult;
    if (!result.token || !result.user) {
      throw new Error('HTTP 401: Invalid username or password');
    }
    this.token = result.token;
    this.currentUser = result.user;
    console.info(`[ApiService] 登录成功 | user=${result.user.username} | token=${this.token.substring(0, 20)}...`);
    return result;
  }

  async register(
    username: string,
    password: string,
    nickname?: string
  ): Promise<LoginResult> {
    let body = new RegisterBody(username, password, nickname);
    let data = await this.request(http.RequestMethod.POST, '/auth/register', body);
    let result = JSON.parse(data) as LoginResult;
    this.token = result.token;
    this.currentUser = result.user;
    console.info(`[ApiService] 注册成功 | user=${result.user.username}`);
    return result;
  }

  // ----------------------------------------------------------
  // 设备列表
  // ----------------------------------------------------------

  async getDevices(
    page: number = 1,
    pageSize: number = 50
  ): Promise<DeviceListResult> {
    let data = await this.request(
      http.RequestMethod.GET,
      `/devices?page=${page}&page_size=${pageSize}`
    );
    let result = JSON.parse(data) as DeviceListResult;
    console.info(`[ApiService] getDevices → total=${result.total} items=${result.items ? result.items.length : 0}`);
    return result;
  }

  // ----------------------------------------------------------
  // 设备详情
  // ----------------------------------------------------------

  async getDevice(deviceId: string): Promise<DeviceInfo> {
    let data = await this.request(
      http.RequestMethod.GET,
      `/devices/${deviceId}`
    );
    return JSON.parse(data) as DeviceInfo;
  }

  // 添加设备
  async createDevice(deviceId: string, name?: string, location?: string): Promise<object> {
    let body = new CreateDeviceBody(deviceId, name, location);
    let data = await this.request(
      http.RequestMethod.POST,
      '/devices',
      body
    );
    return JSON.parse(data);
  }

  // ----------------------------------------------------------
  // 遥测历史
  // ----------------------------------------------------------

  async getTelemetry(
    deviceId: string,
    from?: number,
    to?: number,
    page: number = 1,
    pageSize: number = 200
  ): Promise<TelemetryListResult> {
    let params = `page=${page}&page_size=${pageSize}`;
    if (from !== undefined) {
      params += `&from=${from}`;
    }
    if (to !== undefined) {
      params += `&to=${to}`;
    }
    let data = await this.request(
      http.RequestMethod.GET,
      `/devices/${deviceId}/telemetry?${params}`
    );
    return JSON.parse(data) as TelemetryListResult;
  }

  // ----------------------------------------------------------
  // 设备控制
  // ----------------------------------------------------------

  async sendCommand(
    deviceId: string,
    cmd: Object
  ): Promise<object> {
    let data = await this.request(
      http.RequestMethod.POST,
      `/devices/${deviceId}/cmd`,
      cmd
    );
    return JSON.parse(data);
  }

  // ----------------------------------------------------------
  // AI 对话（由服务器代理调用 Mimo，密钥不放在 APP）
  // ----------------------------------------------------------

  async chatAi(messages: AiMessage[]): Promise<AiChatResult> {
    let data = await this.request(
      http.RequestMethod.POST,
      '/ai/chat',
      new AiChatBody(messages)
    );
    return JSON.parse(data) as AiChatResult;
  }

  // ----------------------------------------------------------
  // 事件日志
  // ----------------------------------------------------------

  async getEvents(
    limit: number = 100,
    deviceId?: string,
    kind?: string
  ): Promise<EventListResult> {
    let params = `limit=${limit}`;
    if (deviceId) {
      params += `&device_id=${deviceId}`;
    }
    if (kind) {
      params += `&kind=${kind}`;
    }
    let data = await this.request(
      http.RequestMethod.GET,
      `/events?${params}`
    );
    return JSON.parse(data) as EventListResult;
  }

  // ----------------------------------------------------------
  // 健康检查
  // ----------------------------------------------------------

  async healthCheck(): Promise<object> {
    let data = await this.request(http.RequestMethod.GET, '/health');
    return JSON.parse(data);
  }
}

export const apiService = new ApiService();
