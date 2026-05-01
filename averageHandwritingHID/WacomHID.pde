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
  // Mac で接続が不安定な場合があるため、リトライ付きで初期スキャンを待つ
  boolean connect() {
    return connect(30, 200);  // 最大30回、200ms 間隔 = 最大6秒待機
  }

  boolean connect(int maxRetries, int retryIntervalMs) {
    long t0 = millis();

    println("[WacomHID] ========================================");
    println("[WacomHID] Connection start");
    println("[WacomHID] OS:        " + System.getProperty("os.name")
      + " " + System.getProperty("os.version")
      + " (" + System.getProperty("os.arch") + ")");
    println("[WacomHID] Java:      " + System.getProperty("java.version"));
    println("[WacomHID] Target:    " + cfg.device.NAME
      + " (VID=0x" + hex(cfg.device.VENDOR_ID, 4)
      + " PID=0x" + hex(cfg.device.PRODUCT_ID, 4) + ")");
    println("[WacomHID] Layout:    " + cfg.layout.NAME);
    println("[WacomHID] ----------------------------------------");

    // --- HidServices の準備 ---
    println("[WacomHID] [1] Creating HidServicesSpecification...");
    HidServicesSpecification spec = new HidServicesSpecification();
    spec.setAutoShutdown(true);
    spec.setScanInterval(200);
    spec.setPauseInterval(0);
    spec.setScanMode(ScanMode.SCAN_AT_FIXED_INTERVAL_WITH_PAUSE_AFTER_WRITE);
    println("[WacomHID]     scanInterval=200ms, autoShutdown=true");

    println("[WacomHID] [2] Getting HidServices instance...");
    HidServices hs;
    try {
      hs = HidManager.getHidServices(spec);
      println("[WacomHID]     OK");
    } catch (Exception e) {
      println("[WacomHID]     FAILED: " + e.getClass().getSimpleName() + " — " + e.getMessage());
      e.printStackTrace();
      isConnected = false;
      return false;
    }

    println("[WacomHID] [3] Starting HidServices (hs.start())...");
    try {
      hs.start();
      println("[WacomHID]     OK");
    } catch (Exception e) {
      println("[WacomHID]     FAILED: " + e.getClass().getSimpleName() + " — " + e.getMessage());
      e.printStackTrace();
      isConnected = false;
      return false;
    }

    // --- 初回スキャン待機 ---
    println("[WacomHID] [4] Waiting 500ms for initial HID scan...");
    try { Thread.sleep(500); } catch (InterruptedException e) {}

    // --- 接続中の全HIDデバイスを列挙（デバッグ用）---
    // 同じ VID/PID で複数インターフェースがあるデバイス (Wacom等) では
    // interfaceNumber / usagePage / usage を見ないと正しいインターフェースを選べない
    try {
      java.util.List<HidDevice> attached = hs.getAttachedHidDevices();
      println("[WacomHID] [5] Attached HID devices: " + attached.size());
      int wacomCount = 0, targetCount = 0;
      for (HidDevice d : attached) {
        boolean isWacom = (d.getVendorId() == cfg.device.VENDOR_ID);
        boolean isTarget = (d.getVendorId() == cfg.device.VENDOR_ID
                         && d.getProductId() == cfg.device.PRODUCT_ID);
        String marker = isTarget ? "  <== TARGET" : (isWacom ? "  (Wacom)" : "");
        if (isTarget) targetCount++;
        if (isWacom) wacomCount++;

        // 基本情報
        println("[WacomHID]     VID=0x" + hex(d.getVendorId() & 0xFFFF, 4)
          + " PID=0x" + hex(d.getProductId() & 0xFFFF, 4)
          + "  " + d.getProduct() + marker);

        // ターゲット候補は詳細情報も出す (どのインターフェースか判別するため)
        if (isTarget) {
          try {
            println("[WacomHID]         interface=" + d.getInterfaceNumber()
              + "  usagePage=0x" + hex(d.getUsagePage() & 0xFFFF, 4)
              + "  usage=0x" + hex(d.getUsage() & 0xFFFF, 4)
              + "  release=0x" + hex(d.getReleaseNumber() & 0xFFFF, 4));
            println("[WacomHID]         path=" + d.getPath());
          } catch (Exception e) {
            println("[WacomHID]         (extended info unavailable: " + e.getMessage() + ")");
          }
        }
      }
      if (wacomCount == 0) {
        println("[WacomHID]     ! No Wacom devices found at all");
      } else if (targetCount > 1) {
        println("[WacomHID]     ! Multiple TARGET interfaces (" + targetCount + ") detected.");
        println("[WacomHID]       hid4java will pick one — may not be the pen interface.");
        println("[WacomHID]       Look for: usagePage=0x000D (Digitizer) usage=0x0002 (Pen)");
      }
    } catch (Exception e) {
      println("[WacomHID]     enumeration failed: " + e.getMessage());
    }

    // --- 候補インターフェース全部を probe してデータが来るやつを採用 ---
    println("[WacomHID] [6] Looking up target device + probing for active interface");
    println("[WacomHID]     ペンをタブレット近くで動かしてください");

    HidDevice winner = null;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      // VID/PID マッチする候補を全部集める
      java.util.List<HidDevice> candidates = new java.util.ArrayList<HidDevice>();
      try {
        for (HidDevice d : hs.getAttachedHidDevices()) {
          if (d.getVendorId() == cfg.device.VENDOR_ID
              && d.getProductId() == cfg.device.PRODUCT_ID) {
            candidates.add(d);
          }
        }
      } catch (Exception e) {
        println("[WacomHID]     enumeration error: " + e.getMessage());
      }

      if (candidates.size() == 0) {
        if (attempt % 5 == 0) {
          println("[WacomHID]     attempt " + attempt + ": no candidates yet... (elapsed "
            + (millis() - t0) + "ms)");
        }
        if (attempt < maxRetries) {
          try { Thread.sleep(retryIntervalMs); } catch (InterruptedException e) {}
        }
        continue;
      }

      // HID標準 Pen (usagePage=0x000D, usage=0x0002) を優先順位の先頭に置く
      java.util.List<HidDevice> ordered = new java.util.ArrayList<HidDevice>();
      for (HidDevice d : candidates) {
        try {
          if ((d.getUsagePage() & 0xFFFF) == 0x000D && (d.getUsage() & 0xFFFF) == 0x0002) {
            ordered.add(0, d);
          } else {
            ordered.add(d);
          }
        } catch (Exception e) {
          ordered.add(d);
        }
      }

      println("[WacomHID]     attempt " + attempt + ": " + ordered.size()
        + " candidate interface(s), probing each for data...");

      // 各候補を順番に probe
      byte[] testBuf = new byte[BUF_SIZE];
      int probePerDevice = 400;  // 1個あたりの probe 時間 (ms)
      for (int ci = 0; ci < ordered.size(); ci++) {
        HidDevice d = ordered.get(ci);
        String label;
        try {
          label = "iface=" + d.getInterfaceNumber()
            + " usagePage=0x" + hex(d.getUsagePage() & 0xFFFF, 4)
            + " usage=0x" + hex(d.getUsage() & 0xFFFF, 4);
        } catch (Exception e) {
          label = "(no metadata)";
        }

        // open を試みる (戻り値は variable に受けないと Processing でパースエラーになる)
        boolean opened = false;
        try {
          boolean openResult = d.open();
          opened = openResult;
        } catch (Exception e) {
          // 既に open 済みかもしれないので無視して進む
        }

        long deadline = millis() + probePerDevice;
        boolean gotData = false;
        int sampleByte = -1;
        while (millis() < deadline) {
          int r = -1;
          try {
            r = d.read(testBuf, 50);
          } catch (Exception e) {
            // ignore — 次の候補へ
            r = -2;
            break;
          }
          if (r > 0) {
            gotData = true;
            sampleByte = testBuf[0] & 0xFF;
            break;
          }
        }

        if (gotData) {
          println("[WacomHID]       [" + ci + "] " + label
            + "  ==> DATA RECEIVED (reportId=0x" + hex(sampleByte, 2) + ") ✓");
          winner = d;
          break;
        } else {
          println("[WacomHID]       [" + ci + "] " + label + "  (no data)");
          // 次の候補のために close
          if (opened) {
            try { d.close(); } catch (Exception e) {}
          }
        }
      }

      if (winner != null) break;
      if (attempt < maxRetries) {
        try { Thread.sleep(retryIntervalMs); } catch (InterruptedException e) {}
      }
    }

    if (winner != null) {
      device = winner;
      long elapsed = millis() - t0;
      println("[WacomHID] ----------------------------------------");
      println("[WacomHID] Connected: " + device.getProduct() + " (" + cfg.device.NAME + ")");
      println("[WacomHID]   Manufacturer: " + device.getManufacturer());
      println("[WacomHID]   SerialNumber: " + device.getSerialNumber());
      println("[WacomHID]   Path:         " + device.getPath());
      try {
        println("[WacomHID]   Interface:    " + device.getInterfaceNumber());
        println("[WacomHID]   UsagePage:    0x" + hex(device.getUsagePage() & 0xFFFF, 4));
        println("[WacomHID]   Usage:        0x" + hex(device.getUsage() & 0xFFFF, 4));
      } catch (Exception e) {
        println("[WacomHID]   (interface info unavailable)");
      }
      println("[WacomHID]   Elapsed:      " + elapsed + "ms");
      println("[WacomHID] ========================================");
      isConnected = true;
      return true;
    }

    isConnected = false;
    long elapsed = millis() - t0;
    println("[WacomHID] ----------------------------------------");
    println("[WacomHID] FAILED after " + maxRetries + " attempts (" + elapsed + "ms)");
    println("[WacomHID]   Target: " + cfg.device.NAME
      + " (VID=0x" + hex(cfg.device.VENDOR_ID, 4)
      + " PID=0x" + hex(cfg.device.PRODUCT_ID, 4) + ")");
    println("[WacomHID]   Tip (Mac):");
    println("[WacomHID]    - Wacom Desktop Center / 関連プロセスが先にデバイスを掴んでいる可能性");
    println("[WacomHID]    - System Settings > Privacy & Security > Input Monitoring を確認");
    println("[WacomHID]    - USB を抜き挿し or ペンを動かしてから再起動");
    println("[WacomHID] ========================================");
    return false;
  }

  // --- 毎フレーム呼ぶ (バッファを全部読み切る) ---
  void update() {
    if (!isConnected || device == null) return;

    // バッファに溜まったレポートをすべて読み、最新を反映
    while (true) {
      int read;
      try {
        read = device.read(buf, 1);
      } catch (Exception e) {
        println("[WacomHID] read() failed: " + e.getMessage());
        isConnected = false;
        return;
      }
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

  // --- レポートのデコード (バイト位置は cfg のレイアウト設定を参照) ---
  private void decode() {
    // 座標
    rawX    = (report[cfg.layout.X_HIGH] << 8) | report[cfg.layout.X_LOW];
    rawY    = (report[cfg.layout.Y_HIGH] << 8) | report[cfg.layout.Y_LOW];
    screenX = map(rawX, 0, cfg.device.TABLET_X_MAX, 0, app.width);
    screenY = map(rawY, 0, cfg.device.TABLET_Y_MAX, 0, app.height);

    // 筆圧
    pressure = (report[cfg.layout.PRESSURE_HIGH] << 8) | report[cfg.layout.PRESSURE_LOW];

    // 傾き (符号付き 16bit → 度)
    if (cfg.layout.TILT_X_LOW >= 0 && cfg.layout.TILT_X_HIGH >= 0) {
      int rtx = (report[cfg.layout.TILT_X_HIGH] << 8) | report[cfg.layout.TILT_X_LOW];
      int rty = (report[cfg.layout.TILT_Y_HIGH] << 8) | report[cfg.layout.TILT_Y_LOW];
      tiltX = (rtx > 32767 ? rtx - 65536 : rtx) / 100.0;
      tiltY = (rty > 32767 ? rty - 65536 : rty) / 100.0;
    } else {
      tiltX = 0;
      tiltY = 0;
    }

    // 距離 (DISTANCE_HIGH = -1 なら 1バイトとして扱う)
    if (cfg.layout.DISTANCE_LOW >= 0) {
      if (cfg.layout.DISTANCE_HIGH >= 0) {
        distance = (report[cfg.layout.DISTANCE_HIGH] << 8) | report[cfg.layout.DISTANCE_LOW];
      } else {
        distance = report[cfg.layout.DISTANCE_LOW];
      }
    } else {
      distance = 0;
    }

    // 状態
    int status = report[cfg.layout.STATUS_BYTE];
    isOutOfRange = (status == cfg.layout.STATUS_OUT_OF_RANGE);
    isTouching   = (status == cfg.layout.STATUS_TOUCH);
    isHovering   = (status == cfg.layout.STATUS_HOVER);

    // 距離 mm 換算
    if (isHovering || isTouching) {
      distanceMm = map(distance, cfg.device.DIST_RAW_MIN, cfg.device.DIST_RAW_MAX,
                        cfg.device.DIST_MM_MAX, 0.0);
      distanceMm = constrain(distanceMm, 0, cfg.device.DIST_MM_MAX);
    } else {
      distanceMm = cfg.device.DIST_MM_MAX;
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
