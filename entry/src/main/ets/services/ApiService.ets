/**
 * API 服务层
 *
 * 封装对冷链监控后端的所有 HTTP 请求。
 * 使用 HarmonyOS @kit.NetworkKit 的 http 模块。
 *
 * Base URL: http://123.60.36.30/api
 */

import { http } from '@kit.NetworkKit';

// ============================================================
// 数据类型
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

export interface TelemetryData {
  ts: number;
  temp: number;
  humi: number;
  lux: number;
  tilt: number;
  motor: number;
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
// 请求体类（ArkTS 要求 object 字面量必须对应显式声明的 class）
// ============================================================

class LoginBody {
  username: string;
  password: string;

  constructor(username: string, password: string) {
    this.username = username;
    this.password = password;
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
  // 底层 HTTP 请求
  // ----------------------------------------------------------
  private async request(
    method: http.RequestMethod,
    path: string,
    body?: Object
  ): Promise<string> {
    let httpRequest = http.createHttp();
    let headers = this.buildHeaders();

    try {
      let resp = await httpRequest.request(BASE_URL + path, {
        method: method,
        header: headers,
        extraData: body ? JSON.stringify(body) : undefined,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      httpRequest.destroy();
      return resp.result as string;
    } catch (err) {
      httpRequest.destroy();
      console.error('[ApiService] HTTP error:', JSON.stringify(err));
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
    this.token = result.token;
    this.currentUser = result.user;
    console.info('[ApiService] 登录成功, user:', result.user.username);
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
    console.info('[ApiService] 注册成功, user:', result.user.username);
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
    return JSON.parse(data) as DeviceListResult;
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
    if (from) {
      params += `&from=${from}`;
    }
    if (to) {
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
