/**
 * 实时多线面积图 — 温度/湿度/光照三条线合一
 *
 * - 每收到新数据追加到尾部，自动滚动，保留最近 60 个采样点
 * - Y 轴随数据动态缩放，使变化明显
 * - 触摸 / 鼠标悬停显示十字准星 + 数值浮层
 */

class Point {
  x: number;
  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}

export class ChartData {
  time: string;
  temp: number;
  humi: number;
  lux: number;

  constructor(time: string, temp: number, humi: number, lux: number) {
    this.time = time;
    this.temp = temp;
    this.humi = humi;
    this.lux = lux;
  }
}

const PAD_L = 48, PAD_T = 10, PAD_R = 14, PAD_B = 28;
const C_GRID = '#EEEEEE', C_AXIS = '#999';
const C_TEMP = '#F44336', C_HUMI = '#2196F3', C_LUX = '#FF9800';
const F_TEMP = '#FFCDD2', F_HUMI = '#BBDEFB', F_LUX = '#FFE0B2';
const C_CROSS = '#666';       // 十字准星颜色

@Component
export struct LineChart {
  @Prop data: ChartData[];
  @State canvasW: number = 320;
  @State canvasH: number = 280;

  // ------ 触摸状态 ------
  @State touchActive: boolean = false;
  @State touchIdx: number = -1;
  @State touchX: number = 0;
  @State touchY: number = 0;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // ------ 动态 Y 轴范围（带 padding）------
  private tempMin: number = 0;   private tempMax: number = 45;
  private humiMin: number = 0;   private humiMax: number = 100;
  private luxMin: number = 0;    private luxMax: number = 1000;

  build() {
    Column({ space: 6 }) {
      // 图例
      Row({ space: 16 }) {
        this.Dot('温度', C_TEMP)
        this.Dot('湿度', C_HUMI)
        this.Dot('光照', C_LUX)
      }
      .width('100%').padding({ left: 8 })

      // 触摸提示行 — 大字体显示具体数值
      if (this.touchActive && this.touchIdx >= 0 && this.touchIdx < this.data.length) {
        Row({ space: 10 }) {
          Text(this.data[this.touchIdx].time).fontSize(14).fontColor('#333').fontWeight(FontWeight.Bold)
          Text(`🌡 ${this.data[this.touchIdx].temp.toFixed(1)}℃`).fontSize(14).fontColor(C_TEMP).fontWeight(FontWeight.Bold)
          Text(`💧 ${this.data[this.touchIdx].humi.toFixed(1)}%`).fontSize(14).fontColor(C_HUMI).fontWeight(FontWeight.Bold)
          Text(`💡 ${this.data[this.touchIdx].lux.toFixed(0)} lx`).fontSize(14).fontColor(C_LUX).fontWeight(FontWeight.Bold)
        }
        .width('100%').padding({ left: 8, top: 4, bottom: 4 })
        .backgroundColor('#F0F0F0').borderRadius(6)
      }

      Canvas(this.ctx)
        .width('100%')
        .height(this.canvasH)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)
        .onReady(() => { this.render(); })
        .onAreaChange((_old, nu) => {
          this.canvasW = nu.width as number;
          this.canvasH = nu.height as number;
          this.render();
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down || event.type === TouchType.Move) {
            let touch = event.touches[0];
            this.touchX = touch.x;
            this.touchY = touch.y;
            this.updateTouchIndex();
            this.touchActive = true;
            this.render();
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.touchActive = false;
            this.touchIdx = -1;
            this.render();
          }
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

  // ------ 根据触摸 X 坐标推算最近的数据点 ------
  private updateTouchIndex(): void {
    let n = this.data.length;
    if (n < 2) {
      this.touchIdx = -1;
      return;
    }
    let l = PAD_L, r = this.canvasW - PAD_R;
    let pw = r - l;
    let idx = Math.round(((this.touchX - l) / pw) * (n - 1));
    if (idx < 0) { idx = 0; }
    if (idx >= n) { idx = n - 1; }
    this.touchIdx = idx;
  }

  // ------ 计算动态 Y 轴范围（加 20% padding）------
  private calcRanges(): void {
    let n = this.data.length;
    if (n === 0) { return; }

    // 温度范围
    let temps = this.data.map(d => d.temp).filter(v => !isNaN(v));
    if (temps.length > 0) {
      let tMin = Math.min(...temps);
      let tMax = Math.max(...temps);
      let tPad = Math.max((tMax - tMin) * 0.2, 1);
      this.tempMin = Math.floor(tMin - tPad);
      this.tempMax = Math.ceil(tMax + tPad);
      if (this.tempMin === this.tempMax) { this.tempMax = this.tempMin + 2; }
    }

    // 湿度范围
    let humis = this.data.map(d => d.humi).filter(v => !isNaN(v));
    if (humis.length > 0) {
      let hMin = Math.min(...humis);
      let hMax = Math.max(...humis);
      let hPad = Math.max((hMax - hMin) * 0.2, 5);
      this.humiMin = Math.floor(hMin - hPad);
      this.humiMax = Math.ceil(hMax + hPad);
      if (this.humiMin < 0) { this.humiMin = 0; }
      if (this.humiMax > 100) { this.humiMax = 100; }
      if (this.humiMin === this.humiMax) { this.humiMax = this.humiMin + 10; }
    }

    // 光照范围
    let luxes = this.data.map(d => d.lux).filter(v => !isNaN(v));
    if (luxes.length > 0) {
      let lMin = Math.min(...luxes);
      let lMax = Math.max(...luxes);
      let lPad = Math.max((lMax - lMin) * 0.2, 20);
      this.luxMin = Math.floor(lMin - lPad);
      this.luxMax = Math.ceil(lMax + lPad);
      if (this.luxMin < 0) { this.luxMin = 0; }
      if (this.luxMin === this.luxMax) { this.luxMax = this.luxMin + 50; }
    }
  }

  private render(): void {
    this.calcRanges();

    let c = this.ctx;
    let W = this.canvasW, H = this.canvasH;
    let n = this.data.length;

    c.clearRect(0, 0, W, H);
    if (n < 2 || W < 100) {
      c.font = '13px sans-serif'; c.fillStyle = '#999';
      c.fillText('等待实时数据...', W / 2 - 40, H / 2);
      return;
    }

    let l = PAD_L, t = PAD_T, r = W - PAD_R, b = H - PAD_B;
    let pw = r - l, ph = b - t;

    // ---- 网格 ----
    c.strokeStyle = C_GRID; c.lineWidth = 0.5;
    for (let i = 0; i <= 4; i++) {
      let y = t + (ph / 4) * i;
      c.beginPath(); c.moveTo(l, y); c.lineTo(r, y); c.stroke();
    }

    // ---- Y 轴刻度（左侧温度，右侧湿度） ----
    c.font = '10px sans-serif'; c.fillStyle = C_TEMP;
    for (let i = 0; i <= 4; i++) {
      let y = t + (ph / 4) * i;
      let val = this.tempMax - ((this.tempMax - this.tempMin) / 4) * i;
      c.fillText(val.toFixed(1) + '°', 2, y + 3);
    }

    // 湿度右轴
    c.fillStyle = C_HUMI;
    for (let i = 0; i <= 4; i++) {
      let y = t + (ph / 4) * i;
      let val = this.humiMax - ((this.humiMax - this.humiMin) / 4) * i;
      c.fillText(val.toFixed(0) + '%', r + 2, y + 3);
    }

    // ---- X 轴时间标签 ----
    c.fillStyle = C_AXIS; c.font = '9px sans-serif';
    let xIdx: number[] = [];
    if (n <= 6) { for (let i = 0; i < n; i++) { xIdx.push(i); } }
    else {
      let step = Math.floor(n / 5);
      for (let i = 0; i < n; i += step) { xIdx.push(i); }
      if (xIdx[xIdx.length - 1] !== n - 1) { xIdx.push(n - 1); }
    }
    for (let idx of xIdx) {
      let x = l + (pw / Math.max(n - 1, 1)) * idx;
      c.fillText(this.data[idx].time, x - 10, b + 12);
    }

    // ---- 三条线 + 面积填充（各自动态 Y 范围） ----
    this.drawArea(c, l, t, pw, ph, n, this.tempMin, this.tempMax, C_TEMP, F_TEMP, (d: ChartData) => d.temp);
    this.drawArea(c, l, t, pw, ph, n, this.humiMin, this.humiMax, C_HUMI, F_HUMI, (d: ChartData) => d.humi);
    this.drawArea(c, l, t, pw, ph, n, this.luxMin, this.luxMax, C_LUX, F_LUX, (d: ChartData) => d.lux);

    // ---- 十字准星（触摸时） ----
    if (this.touchActive && this.touchIdx >= 0 && this.touchIdx < n) {
      let cx = l + (pw / Math.max(n - 1, 1)) * this.touchIdx;

      // 垂直线
      c.strokeStyle = C_CROSS; c.lineWidth = 1; c.setLineDash([4, 4]);
      c.beginPath(); c.moveTo(cx, t); c.lineTo(cx, b); c.stroke();
      c.setLineDash([]);

      // 各数据点高亮圈
      let d = this.data[this.touchIdx];
      let drawPoint = (val: number, yMin: number, yMax: number, color: string) => {
        if (val == null || isNaN(val)) { return; }
        let py = t + ph - ((val - yMin) / (yMax - yMin)) * ph;
        c.beginPath();
        c.arc(cx, py, 6, 0, Math.PI * 2);
        c.fillStyle = color; c.fill();
        c.strokeStyle = '#FFFFFF'; c.lineWidth = 2; c.stroke();
      };
      drawPoint(d.temp, this.tempMin, this.tempMax, C_TEMP);
      drawPoint(d.humi, this.humiMin, this.humiMax, C_HUMI);
      drawPoint(d.lux, this.luxMin, this.luxMax, C_LUX);

    }
  }

  private drawArea(
    c: CanvasRenderingContext2D,
    l: number, t: number, pw: number, ph: number, n: number,
    yMin: number, yMax: number, color: string, fill: string,
    fn: (d: ChartData) => number
  ): void {
    let pts: Point[] = [];
    for (let i = 0; i < n; i++) {
      let v = fn(this.data[i]);
      if (v == null || isNaN(v)) { continue; }
      let x = l + (pw / Math.max(n - 1, 1)) * i;
      let y = t + ph - ((v - yMin) / (yMax - yMin)) * ph;
      pts.push(new Point(x, y));
    }
    if (pts.length < 2) { return; }

    // 填充（半透明，避免互相遮盖）
    c.beginPath();
    c.moveTo(pts[0].x, t + ph);
    for (let p of pts) { c.lineTo(p.x, p.y); }
    c.lineTo(pts[pts.length - 1].x, t + ph);
    c.closePath();
    c.fillStyle = fill;
    c.globalAlpha = 0.3;
    c.fill();
    c.globalAlpha = 1.0;

    // 线
    c.strokeStyle = color; c.lineWidth = 2; c.lineJoin = 'round';
    c.beginPath();
    c.moveTo(pts[0].x, pts[0].y);
    for (let i = 1; i < pts.length; i++) { c.lineTo(pts[i].x, pts[i].y); }
    c.stroke();

    // 点
    let step = Math.max(1, Math.floor(pts.length / 10));
    for (let i = 0; i < pts.length; i += step) {
      c.beginPath();
      c.arc(pts[i].x, pts[i].y, 2.5, 0, Math.PI * 2);
      c.fillStyle = color; c.fill();
      c.strokeStyle = '#FFFFFF'; c.lineWidth = 1; c.stroke();
    }
  }
}
