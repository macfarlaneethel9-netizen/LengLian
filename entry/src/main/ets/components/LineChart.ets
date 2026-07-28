/**
 * 折线图组件 — 基于 ArkUI Canvas 绘制
 *
 * 支持三条折线：温度(红)、湿度(蓝)、光照(橙)。
 * 网格 + 坐标轴 + 数据点 + 图例。
 */

import { TelemetryData } from '../services/ApiService';

// 图表常量
const PAD_L = 44;
const PAD_T = 12;
const PAD_R = 12;
const PAD_B = 28;
const C_GRID = '#E8E8E8';
const C_AXIS = '#999';
const C_T = '#F44336';
const C_H = '#2196F3';
const C_L = '#FF9800';

@Component
export struct LineChart {
  @Prop data: TelemetryData[];
  @Prop showTemp: boolean;
  @Prop showHumi: boolean;
  @Prop showLux: boolean;
  @State canvasW: number = 300;
  @State canvasH: number = 260;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Column() {
      // 图例
      if (this.showTemp || this.showHumi || this.showLux) {
        Row({ space: 16 }) {
          if (this.showTemp) { this.Dot('温度 ℃', C_T) }
          if (this.showHumi) { this.Dot('湿度 %', C_H) }
          if (this.showLux) { this.Dot('光照 LUX', C_L) }
        }
        .width('100%')
        .padding({ left: 8, bottom: 4 })
      }

      // Canvas
      Canvas(this.ctx)
        .width('100%')
        .height(this.canvasH)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)
        .onReady(() => {
          this.render();
        })
        .onAreaChange((old, nu) => {
          this.canvasW = nu.width as number;
          this.canvasH = nu.height as number;
          this.render();
        })
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000008', offsetY: 2 })
  }

  @Builder Dot(label: string, color: string) {
    Row({ space: 4 }) {
      Circle({ width: 8, height: 8 }).fill(color)
      Text(label).fontSize(11).fontColor('#666')
    }
  }

  // ============================================================
  // Canvas 绘制逻辑
  // ============================================================
  private render(): void {
    let c = this.ctx;
    let n = this.data.length;
    let W = this.canvasW;
    let H = this.canvasH;

    // 清除画布
    c.clearRect(0, 0, W, H);
    if (n < 2 || W < 100) {
      c.font = '12px sans-serif';
      c.fillStyle = '#999';
      c.fillText('数据不足', 60, H / 2);
      return;
    }

    let l = PAD_L, t = PAD_T, r = W - PAD_R, b = H - PAD_B;
    let pw = r - l, ph = b - t;

    // ---- 网格 ----
    c.strokeStyle = C_GRID;
    c.lineWidth = 0.5;
    for (let i = 0; i <= 4; i++) {
      let y = t + (ph / 4) * i;
      c.beginPath(); c.moveTo(l, y); c.lineTo(r, y); c.stroke();
    }
    for (let i = 0; i <= 6; i++) {
      let x = l + (pw / 6) * i;
      c.beginPath(); c.moveTo(x, t); c.lineTo(x, b); c.stroke();
    }

    // ---- Y 刻度 ----
    c.font = '10px sans-serif';
    c.fillStyle = C_AXIS;
    for (let i = 0; i <= 4; i++) {
      let y = t + (ph / 4) * i;
      let val = 45 - ((45 - 15) / 4) * i;
      c.fillText(String(val.toFixed(0)), l - 4, y + 4);
    }

    // ---- X 时间标签 ----
    let ix = [0, Math.floor((n - 1) / 3), Math.floor((n - 1) * 2 / 3), n - 1];
    for (let idx of ix) {
      let x = l + (pw / (n - 1)) * idx;
      let label = this.hourLabel(idx);
      c.fillText(label, x, b + 14);
    }

    // ---- 三条折线 ----
    if (this.showTemp) {
      this.drawLine(c, 15, 45, C_T, n, l, t, pw, ph, (d: TelemetryData) => d.temp);
    }
    if (this.showHumi) {
      this.drawLine(c, 20, 100, C_H, n, l, t, pw, ph, (d: TelemetryData) => d.humi);
    }
    if (this.showLux) {
      this.drawLine(c, 0, 1000, C_L, n, l, t, pw, ph, (d: TelemetryData) => d.lux);
    }
  }

  private drawLine(
    c: CanvasRenderingContext2D,
    yMin: number, yMax: number,
    color: string,
    n: number, l: number, t: number, pw: number, ph: number,
    fn: (d: TelemetryData) => number
  ): void {
    // 收集点
    let pts: number[][] = [];
    for (let i = 0; i < n; i++) {
      let d = this.data[i];
      let v = d ? fn(d) : NaN;
      if (isNaN(v)) { continue; }
      let x = l + (pw / (n - 1)) * i;
      let y = t + ph - ((v - yMin) / (yMax - yMin)) * ph;
      pts.push([x, y]);
    }
    if (pts.length < 2) { return; }

    // 画线
    c.strokeStyle = color;
    c.lineWidth = 2;
    c.lineJoin = 'round';
    c.beginPath();
    c.moveTo(pts[0][0], pts[0][1]);
    for (let i = 1; i < pts.length; i++) {
      c.lineTo(pts[i][0], pts[i][1]);
    }
    c.stroke();

    // 画点
    let step = Math.max(1, Math.floor(pts.length / 12));
    c.fillStyle = color;
    for (let i = 0; i < pts.length; i += step) {
      c.beginPath();
      c.arc(pts[i][0], pts[i][1], 2.5, 0, Math.PI * 2);
      c.fill();
    }
  }

  private hourLabel(i: number): string {
    let ts = this.data[i] ? this.data[i]._ts : 0;
    if (!ts || ts <= 0) { return ''; }
    let date = new Date(ts * 1000);
    return `${date.getHours().toString().padStart(2, '0')}:00`;
  }
}
