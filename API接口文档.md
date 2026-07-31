# TX-SMART-R 冷链仓储 — API 接口文档

> **Base URL**：`http://123.60.36.30/api`
> **版本**：v2.0
> **更新**：2026-07-27

---

## 目录

1. [鉴权方式](#1-鉴权方式)
2. [统一响应格式](#2-统一响应格式)
3. [用户认证](#3-用户认证)
4. [设备管理](#4-设备管理)
5. [遥测数据](#5-遥测数据)
6. [设备控制](#6-设备控制)
7. [事件日志](#7-事件日志)
8. [系统状态](#8-系统状态)
9. [数据模型](#9-数据模型)
10. [错误码](#10-错误码)

---

## 1. 鉴权方式

所有接口（除 `/api/health`）需要以下**任一**方式鉴权：

| 方式 | Header | 说明 |
|------|--------|------|
| JWT（推荐） | `Authorization: Bearer <token>` | 登录后获得，有效期 72 小时 |
| API Key | `X-API-Key: <key>` | 兼容旧版看板，无用户上下文 |

**优先级**：有 `Authorization: Bearer ...` 时走 JWT，否则检查 `X-API-Key`。

---

## 2. 统一响应格式

### 成功响应

```json
// 列表类
{
  "items": [...],
  "total": 100,
  "page": 1,
  "page_size": 20
}

// 单条/操作类
{
  "ok": true,
  ...
}
```

### 错误响应

```json
{
  "detail": "错误描述"
}
```

| HTTP 状态码 | 含义 |
|------------|------|
| 400 | 请求参数错误 |
| 401 | 未认证 / token 过期 |
| 404 | 资源不存在 |
| 409 | 资源冲突（如用户名已存在） |
| 422 | 参数校验失败 |
| 500 | 服务器内部错误 |

---

## 3. 用户认证

### 3.1 注册

```
POST /api/auth/register
```

**请求体**：

```json
{
  "username": "admin",     // 3-32 字符，唯一
  "password": "123456",    // 6-128 字符
  "nickname": "管理员"      // 可选，默认 = username
}
```

**响应 `201`**：

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "username": "admin",
    "nickname": "管理员",
    "role": "user"
  }
}
```

**错误**：`409` — 用户名已存在

---

### 3.2 登录

```
POST /api/auth/login
```

**请求体**：

```json
{
  "username": "admin",
  "password": "123456"
}
```

**响应 `200`**：

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "username": "admin",
    "nickname": "管理员",
    "role": "user"
  }
}
```

**错误**：`401` — 用户名或密码错误

---

### 3.3 获取当前用户

```
GET /api/auth/me
Authorization: Bearer <token>
```

**响应 `200`**：

```json
{
  "user": {
    "id": 1,
    "username": "admin",
    "nickname": "管理员",
    "role": "user",
    "created_at": 1721894400.0
  },
  "auth": "jwt"
}
```

API Key 鉴权时：`{"user": null, "auth": "api_key"}`

---

## 4. 设备管理

### 4.1 设备列表

```
GET /api/devices?page=1&page_size=20
Authorization: Bearer <token>
```

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `page` | int | 1 | 页码，从 1 开始 |
| `page_size` | int | 20 | 每页条数，1-100 |

**响应 `200`**：

```json
{
  "items": [
    {
      "device_id": "tx-r-cc-001",
      "online": true,
      "fw": "cold-chain-1.1",
      "last_seen": 1784967989.74,
      "last_telemetry": {
        "ts": 0,
        "temp": 33.88,
        "humi": 49.02,
        "lux": 618.33,
        "tilt": 2178.27,
        "motor": 0,
        "alarm": 1,
        "alarm_reason": "temp_high",
        "scene": "cold_chain"
      },
      "name": "冷链箱-01",
      "location": "A区-3号库",
      "user_id": 1,
      "created_at": 1784883655.48,
      "updated_at": 1784967989.74
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 20
}
```

**说明**：JWT 用户只能看到 `user_id` 匹配自己的设备。

---

### 4.2 设备详情

```
GET /api/devices/{device_id}
Authorization: Bearer <token>
```

**响应 `200`**：同列表中单个设备对象。

**错误**：`404` — 设备不存在

---

### 4.3 创建设备

```
POST /api/devices
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体**：

```json
{
  "device_id": "tx-r-cc-002",   // 必填，唯一
  "name": "冷链箱-02",           // 可选
  "location": "B区-1号库"        // 可选
}
```

**响应 `201`**：

```json
{
  "device_id": "tx-r-cc-002",
  "name": "冷链箱-02",
  "location": "B区-1号库",
  "user_id": 1,
  "online": false
}
```

**错误**：`409` — device_id 已存在

---

### 4.4 更新设备

```
PUT /api/devices/{device_id}
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体**（全部可选，只传要改的字段）：

```json
{
  "name": "冷链箱-02（新）",
  "location": "C区-2号库",
  "user_id": 2
}
```

**响应 `200`**：返回完整设备对象。

**错误**：`404` — 设备不存在

---

### 4.5 删除设备

```
DELETE /api/devices/{device_id}
Authorization: Bearer <token>
```

**响应 `200`**：

```json
{
  "ok": true,
  "device_id": "tx-r-cc-002"
}
```

**错误**：`404` — 设备不存在

---

## 5. 遥测数据

### 5.1 查询遥测历史

```
GET /api/devices/{device_id}/telemetry?from=1721800000&to=1721894400&page=1&page_size=200
Authorization: Bearer <token>
```

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `from` | float | 当前 - 24h | 起始时间戳（epoch 秒） |
| `to` | float | 当前 | 结束时间戳 |
| `page` | int | 1 | 页码 |
| `page_size` | int | 200 | 每页条数，最大 2000 |

**响应 `200`**：

```json
{
  "device_id": "tx-r-cc-001",
  "items": [
    {
      "ts": 0,
      "temp": 33.88,
      "humi": 49.02,
      "lux": 618.33,
      "tilt": 2178.27,
      "motor": 0,
      "alarm": 1,
      "alarm_reason": "temp_high",
      "scene": "cold_chain",
      "_ts": 1784967989.74
    }
  ],
  "total": 950,
  "page": 1,
  "page_size": 200
}
```

**说明**：
- 按时间**倒序**返回最新数据（第一页是最新）
- `_ts` 是服务端记录时间戳
- 传 `page_size=2000` 可获取全部数据

---

## 6. 设备控制

### 6.1 发送命令

```
POST /api/devices/{device_id}/cmd
Authorization: Bearer <token>
Content-Type: application/json
```

**请求体**（字段均可选，至少传一个）：

```json
{
  "led": {"r": 255, "g": 255, "b": 255},
  "motor": 80,
  "beep": 1,
  "ac": 1,
  "auto_mode": true,
  "threshold_enable": {
    "temperature": false,
    "humidity": true,
    "illumination": true
  },
  "clear_alarm": 1
}
```

| 字段 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `led.r` | int | 0-255 | 红色分量 |
| `led.g` | int | 0-255 | 绿色分量 |
| `led.b` | int | 0-255 | 蓝色分量 |
| `motor` | int | 0-100 | 电机 duty，>0 触发脉冲开锁，0 触发关锁 |
| `beep` | int | 0/1 | 蜂鸣器，1=响 |
| `ac` | int | 0/1 | 空调/除湿动作，1=开启一次，0=关闭 |
| `auto_mode` | bool | true/false | 自动模式开关 |
| `threshold_enable.temperature` | bool | true/false | 温度阈值判断开关；关闭会清除当前温度报警 |
| `threshold_enable.humidity` | bool | true/false | 湿度阈值判断开关；关闭会清除当前湿度报警 |
| `threshold_enable.illumination` | bool | true/false | 光照阈值判断开关；关闭会清除当前光照报警 |
| `clear_alarm` | int | 0/1 | 清除告警，1=清除 |

**响应 `200`**：

```json
{
  "ok": true,
  "device_id": "tx-r-cc-001",
  "cmd": {
    "led": {"r": 255, "g": 255, "b": 255},
    "id": "a1b2c3d4-..."
  }
}
```

**说明**：
- `id` 字段会自动生成（UUID），用于追踪命令
- LED 为 active-high（高电平点亮）
- 电机为脉冲式（自动停止），非持续转动

---

## 7. 事件日志

### 7.1 事件列表

```
GET /api/events?limit=100&device_id=tx-r-cc-001&kind=alarm
Authorization: Bearer <token>
```

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `limit` | int | 100 | 返回条数，1-500 |
| `device_id` | str | 无 | 按设备过滤 |
| `kind` | str | 无 | 按类型过滤 |

**事件类型 `kind`**：

| kind | 说明 |
|------|------|
| `online` | 设备上线 |
| `offline` | 设备离线 |
| `alarm` | 超限告警 |
| `event` | 通用事件（开锁等） |
| `cmd` | 命令下发 |
| `cmd_ack` | 命令执行回执 |
| `lock` | 锁状态变化 |
| `access` | 鉴权事件 |
| `iotda_cmd` | 华为云 IoTDA 命令 |

**响应 `200`**：

```json
{
  "events": [
    {
      "id": 42,
      "device_id": "tx-r-cc-001",
      "kind": "alarm",
      "detail": {
        "temp": 9.2,
        "threshold": "2-8"
      },
      "ts": 1784967989.74
    }
  ]
}
```

---

## 8. 系统状态

### 8.1 健康检查

```
GET /api/health
```

无需鉴权。

**响应 `200`**：

```json
{
  "ok": true,
  "service": "tx-smart-iot",
  "mqtt_host": "mosquitto",
  "iotda": {
    "enabled": true,
    "connected": true
  },
  "ts": 1784967989.74
}
```

---

## 9. 数据模型

### 9.1 设备对象

```json
{
  "device_id": "tx-r-cc-001",    // 设备唯一标识
  "online": true,                 // 是否在线
  "fw": "cold-chain-1.1",         // 固件版本
  "last_seen": 1784967989.74,     // 最后上报时间（epoch 秒）
  "last_telemetry": { ... },      // 最新遥测数据
  "name": "冷链箱-01",            // 设备名称
  "location": "A区-3号库",        // 设备位置
  "user_id": 1,                   // 归属用户 ID
  "created_at": 1784883655.48,    // 创建时间
  "updated_at": 1784967989.74     // 更新时间
}
```

### 9.2 遥测数据对象

```json
{
  "temp": 33.88,           // 温度 ℃
  "humi": 49.02,           // 湿度 %
  "lux": 618.33,           // 光照 lux
  "tilt": 2178.27,         // 倾斜量（加速度幅值）
  "motor": 0,              // 电机状态 0=关 1=开
  "auto_mode": 0,           // 自动模式 0=关 1=开
  "temp_threshold_enabled": 1,
  "humi_threshold_enabled": 1,
  "illumination_threshold_enabled": 1,
  "alarm": 1,              // 告警状态 0=正常 1=告警
  "alarm_reason": "temp_high",  // 告警原因
  "scene": "cold_chain",   // 场景标识
  "ts": 0,                 // 设备侧时间戳（通常为 0）
  "_ts": 1784967989.74     // 服务端记录时间戳
}
```

**告警原因 `alarm_reason`**：

| 值 | 含义 |
|----|------|
| `temp_high` | 温度 > 8℃ |
| `temp_low` | 温度 < 2℃ |
| `humi_high` | 湿度 > 80% |
| `light_high` | 光照 > 200 lux |
| `tilt` | 倾斜量 > 15000 |

### 9.3 用户对象

```json
{
  "id": 1,
  "username": "admin",
  "nickname": "管理员",
  "role": "user",
  "created_at": 1721894400.0
}
```

---

## 10. 错误码

| 状态码 | 场景 | detail 示例 |
|--------|------|-------------|
| 400 | 请求体格式错误 | `{"detail": "There was an error parsing the body"}` |
| 401 | 未认证 | `{"detail": "Authentication required"}` |
| 401 | token 过期 | `{"detail": "Invalid or expired token"}` |
| 401 | 密码错误 | `{"detail": "Invalid username or password"}` |
| 404 | 设备不存在 | `{"detail": "Device not found"}` |
| 409 | 用户名重复 | `{"detail": "Username already taken"}` |
| 409 | 设备 ID 重复 | `{"detail": "Device 'xxx' already exists"}` |
| 422 | 参数校验失败 | `{"detail": [{"loc": [...], "msg": "...", "type": "..."}]}` |

---

## 附录：前端对接流程

```
┌─────────────┐     POST /api/auth/login      ┌──────────────┐
│  登录页面    │ ──────────────────────────────►│  获取 token  │
└─────────────┘                                └──────┬───────┘
                                                     │
                                                     ▼
┌─────────────┐     GET /api/devices           ┌──────────────┐
│  设备列表    │ ◄──────────────────────────────│  存入        │
│  设备详情    │     Authorization: Bearer xxx  │  localStorage│
│  历史曲线    │                                └──────────────┘
│  控制面板    │
└──────┬──────┘
       │
       │  POST /api/devices/{id}/cmd
       ▼
┌─────────────┐     GET /api/events            ┌──────────────┐
│  控制下发    │ ──────────────────────────────►│  事件列表    │
└─────────────┘                                └──────────────┘
```

**注意事项**：

1. token 存 `localStorage`，每次请求带 `Authorization: Bearer <token>`
2. 收到 `401` → token 过期，跳转登录页
3. 设备列表接口 JWT 用户只能看到自己的设备
4. 遥测历史第一页是最新数据（DESC 排序）
5. 电机命令是脉冲式，不需要持续发送
6. LED 颜色值 0-255，高电平点亮
