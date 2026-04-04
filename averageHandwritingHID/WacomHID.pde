// ============================================================
// WacomHID.pde — Wacom ペンの HID 生データを取得するクラス
// ============================================================
// 使い方:
//   WacomHIDConfig cfg = new WacomHIDConfig("WacomOne12");
//   WacomHID pen = new WacomHID(this, cfg);
//   pen.connect();          // setup() 内で呼ぶ
//   pen.update();           // draw() 内で毎フレーム呼ぶ
//
// 取得できる値:
//   pen.screenX, pen.screenY   — スクリーン座標 (float)
//   pen.rawX, pen.rawY         — タブレット生座標 (int)
//   pen.pressure               — 筆圧 (int, 0-8191)
//   pen.tiltX, pen.tiltY       — 傾き (float, 度)
//   pen.distance               — 距離 raw 値 (int)
//   pen.distanceMm             — 距離 mm 換算 (float)
//   pen.isHovering             — ホバー中か
//   pen.isTouching             — 接触中か
//   pen.isOutOfRange           — 範囲外か
//   pen.isConnected            — HID 接続済みか
//
// ログ機能:
//   pen.startLog()             — CSV 記録開始
//   pen.stopLog()              — CSV 記録停止
//   pen.isLogging              — 記録中か
//
// 生データアクセス:
//   pen.getRawByte(int index)  — HID レポートの任意バイト取得
//   pen.getRawReport()         — レポート全体 (int[])
//
// デバイス設定は WacomHIDConfig.pde で変更する。
// ============================================================

import org.hid4java.*;

class WacomHID {

  // --- 取得できる値 ---
  int   rawX       = 0;
  int   rawY       = 0;
  float screenX    = 0;
  float screenY    = 0;
  int   pressure   = 0;
  float tiltX      = 0;
  float tiltY      = 0;
  int   distance   = 0;
  float distanceMm = 0;

  boolean isOutOfRange = true;
  boolean isHovering   = false;
  boolean isTouching   = false;
  boolean isConnected  = false;

  // --- ログ ---
  boolean isLogging    = false;
  String  logFilePath  = "";

  // --- 内部 ---
  private PApplet app;
  private WacomHIDConfig cfg;
  private HidDevice device;
  private final int BUF_SIZE    = 65;
  private final int REPORT_SIZE = 36;
  private byte[] buf;
  private int[]  report;
  private PrintWriter logWriter;
  private long logStartTime;
  private long logSeq;

  // --- コンストラクタ ---
  WacomHID(PApplet app, WacomHIDConfig cfg) {
    this.app    = app;
    this.cfg    = cfg;
    this.buf    = new byte[BUF_SIZE];
    this.report = new int[REPORT_SIZE];
  }

  // --- HID 接続 ---
  boolean connect() {
    HidServicesSpecification spec = new HidServicesSpecification();
    spec.setAutoShutdown(true);
    spec.setScanInterval(500);
    spec.setPauseInterval(0);
    spec.setScanMode(ScanMode.SCAN_AT_FIXED_INTERVAL_WITH_PAUSE_AFTER_WRITE);

    HidServices hs = HidManager.getHidServices(spec);
    device = hs.getHidDevice(cfg.VENDOR_ID, cfg.PRODUCT_ID, null);
    if (device != null) {
      isConnected = true;
      println("[WacomHID] Connected: " + device.getProduct()
        + " (" + cfg.DEVICE_NAME + ")");
    } else {
      isConnected = false;
      println("[WacomHID] Device not found: " + cfg.DEVICE_NAME
        + " (VID=0x" + hex(cfg.VENDOR_ID, 4)
        + " PID=0x" + hex(cfg.PRODUCT_ID, 4) + ")");
    }
    return isConnected;
  }

  // --- 毎フレーム呼ぶ (バッファを全部読み切る) ---
  void update() {
    if (!isConnected || device == null) return;

    // バッファに溜まったレポートをすべて読み、最新を反映
    while (true) {
      int read = device.read(buf, 1);
      if (read <= 0) break;

      for (int b = 0; b < min(REPORT_SIZE, read); b++) {
        report[b] = buf[b] & 0xFF;
      }
      decode();

      if (isLogging && logWriter != null) {
        writeLogLine();
      }
    }
  }

  // --- レポートのデコード ---
  private void decode() {
    // 座標
    rawX    = (report[3] << 8) | report[2];
    rawY    = (report[5] << 8) | report[4];
    screenX = map(rawX, 0, cfg.TABLET_X_MAX, 0, app.width);
    screenY = map(rawY, 0, cfg.TABLET_Y_MAX, 0, app.height);

    // 筆圧
    pressure = (report[9] << 8) | report[8];

    // 傾き (符号付き 16bit → 度)
    int rtx = (report[29] << 8) | report[28];
    int rty = (report[31] << 8) | report[30];
    tiltX = (rtx > 32767 ? rtx - 65536 : rtx) / 100.0;
    tiltY = (rty > 32767 ? rty - 65536 : rty) / 100.0;

    // 距離
    distance = (report[33] << 8) | report[32];

    // 状態
    int status = report[1];
    isOutOfRange = (status == 0x00);
    isTouching   = (status == 0x21);
    isHovering   = (status == 0x20);

    // 距離 mm 換算
    if (isHovering || isTouching) {
      distanceMm = map(distance, cfg.DIST_RAW_MIN, cfg.DIST_RAW_MAX,
                        cfg.DIST_MM_MAX, 0.0);
      distanceMm = constrain(distanceMm, 0, cfg.DIST_MM_MAX);
    } else {
      distanceMm = cfg.DIST_MM_MAX;
    }
  }

  // ============================================================
  // ログ機能
  // ============================================================

  void startLog() {
    String timestamp = year() + nf(month(), 2) + nf(day(), 2)
                     + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
    logFilePath = app.sketchPath("log_" + timestamp + ".csv");
    logWriter = app.createWriter(logFilePath);
    logWriter.println("seq,millis,status,rawX,rawY,screenX,screenY,"
                    + "pressure,tiltX,tiltY,distance,distanceMm");
    logStartTime = millis();
    logSeq = 0;
    isLogging = true;
    println("[WacomHID] Log started: " + logFilePath);
  }

  void stopLog() {
    if (logWriter != null) {
      logWriter.flush();
      logWriter.close();
      logWriter = null;
    }
    isLogging = false;
    println("[WacomHID] Log stopped: " + logFilePath);
  }

  private void writeLogLine() {
    long elapsed = millis() - logStartTime;
    logWriter.println(
      logSeq++
      + "," + elapsed
      + "," + getStatusText()
      + "," + rawX + "," + rawY
      + "," + nf(screenX, 0, 1) + "," + nf(screenY, 0, 1)
      + "," + pressure
      + "," + nf(tiltX, 0, 2) + "," + nf(tiltY, 0, 2)
      + "," + distance
      + "," + nf(distanceMm, 0, 2)
    );
  }

  // --- 生データアクセス ---
  int getRawByte(int index) {
    if (index < 0 || index >= REPORT_SIZE) return 0;
    return report[index];
  }

  int[] getRawReport() {
    return report;
  }

  // --- 状態テキスト ---
  String getStatusText() {
    if (isOutOfRange) return "OUT_OF_RANGE";
    if (isTouching)   return "TOUCH";
    return "HOVER";
  }
}
