// ============================================================
// WacomHIDConfig.pde — デバイス設定 + バイトレイアウト
// ============================================================
// 設定は2段構え:
//   1. WACOM_DEVICE — デバイスの基本情報 (VID/PID/解像度等)
//   2. WACOM_LAYOUT — HIDレポートのバイト配置パターン
//
// 同じデバイスでもドライバ環境によってレイアウトが変わるため、
// デバイスとレイアウトを独立に切り替えられるようにしている。
//
// レイアウトの確認方法: 診断ツールを実行してバイトテーブルで
// 各パラメータの位置を確認する。
// ============================================================

// ★ ここを切り替えるだけ ★
final String WACOM_DEVICE = "WacomOne12";
final String WACOM_LAYOUT = "LayoutA";
// final String WACOM_LAYOUT = "LayoutB";   // X/Y間に隙間があるパターン

// ============================================================

static class WacomHIDConfig {

  // --- デバイス基本情報 ---
  int    VENDOR_ID;
  int    PRODUCT_ID;
  int    TABLET_X_MAX;
  int    TABLET_Y_MAX;
  float  DIST_RAW_MIN;
  float  DIST_RAW_MAX;
  float  DIST_MM_MAX;
  String DEVICE_NAME;
  String LAYOUT_NAME;

  // --- バイト配置 (-1 = そのデバイスにはこの項目がない) ---
  int STATUS_BYTE;
  int X_LOW,        X_HIGH;
  int Y_LOW,        Y_HIGH;
  int PRESSURE_LOW, PRESSURE_HIGH;
  int TILT_X_LOW,   TILT_X_HIGH;
  int TILT_Y_LOW,   TILT_Y_HIGH;
  int DISTANCE_LOW, DISTANCE_HIGH;  // DISTANCE_HIGH = -1 なら 1バイト距離

  // --- ステータスコード値 ---
  int STATUS_OUT_OF_RANGE = 0x00;
  int STATUS_HOVER        = 0x20;
  int STATUS_TOUCH        = 0x21;

  WacomHIDConfig(String device) {
    this(device, "LayoutA");
  }

  WacomHIDConfig(String device, String layout) {
    setDevice(device);
    setLayout(layout);
  }

  // ============================================================
  // デバイス基本情報
  // ============================================================
  void setDevice(String device) {
    DEVICE_NAME = device;
    switch (device) {

      case "WacomOne12":
        VENDOR_ID    = 0x056A;
        PRODUCT_ID   = 0x03CE;
        TABLET_X_MAX = 32767;
        TABLET_Y_MAX = 32764;
        DIST_RAW_MIN = 5300;
        DIST_RAW_MAX = 9000;
        DIST_MM_MAX  = 11.0;
        break;

      case "WacomOne13Touch":
        VENDOR_ID    = 0x056A;
        PRODUCT_ID   = 0x03CE;
        TABLET_X_MAX = 32767;
        TABLET_Y_MAX = 32764;
        DIST_RAW_MIN = 5300;
        DIST_RAW_MAX = 9000;
        DIST_MM_MAX  = 11.0;
        break;

      case "IntuosPro_PTH860":
        VENDOR_ID    = 0x056A;
        PRODUCT_ID   = 0x0357;
        TABLET_X_MAX = 44800;
        TABLET_Y_MAX = 29600;
        DIST_RAW_MIN = 3000;
        DIST_RAW_MAX = 7000;
        DIST_MM_MAX  = 10.0;
        break;

      default:
        println("[WacomHIDConfig] Unknown device: " + device);
        VENDOR_ID    = 0x056A;
        PRODUCT_ID   = 0x0000;
        TABLET_X_MAX = 32767;
        TABLET_Y_MAX = 32767;
        DIST_RAW_MIN = 5000;
        DIST_RAW_MAX = 9000;
        DIST_MM_MAX  = 11.0;
        break;
    }
  }

  // ============================================================
  // バイトレイアウト
  // ============================================================
  void setLayout(String layout) {
    LAYOUT_NAME = layout;
    switch (layout) {

      // ------------------------------------------------------
      // LayoutA: X/Y がパックされた標準フォーマット (Windows標準)
      //   status = 1, X = 2,3, Y = 4,5
      //   Pressure = 8,9, Tilt = 28-31, Distance = 32,33
      // ------------------------------------------------------
      case "LayoutA":
        STATUS_BYTE   = 1;
        X_LOW         = 2;   X_HIGH        = 3;
        Y_LOW         = 4;   Y_HIGH        = 5;
        PRESSURE_LOW  = 8;   PRESSURE_HIGH = 9;
        TILT_X_LOW    = 28;  TILT_X_HIGH   = 29;
        TILT_Y_LOW    = 30;  TILT_Y_HIGH   = 31;
        DISTANCE_LOW  = 32;  DISTANCE_HIGH = 33;
        break;

      // ------------------------------------------------------
      // LayoutB: X/Y の間に隙間があるパターン (Mac等で出現)
      //   X = 3,4, Y = 6,7
      //   Pressure = 9,10, TiltX = 11,12, TiltY = 13,14
      //   Distance = 19 (1バイト)
      //   bytes 32,33 にデバイス内部クロック
      // ------------------------------------------------------
      case "LayoutB":
        STATUS_BYTE   = 1;
        X_LOW         = 3;   X_HIGH        = 4;
        Y_LOW         = 6;   Y_HIGH        = 7;
        PRESSURE_LOW  = 9;   PRESSURE_HIGH = 10;
        TILT_X_LOW    = 11;  TILT_X_HIGH   = 12;
        TILT_Y_LOW    = 13;  TILT_Y_HIGH   = 14;
        DISTANCE_LOW  = 19;  DISTANCE_HIGH = -1;  // 1バイト距離
        break;

      default:
        println("[WacomHIDConfig] Unknown layout: " + layout + " (using LayoutA)");
        setLayout("LayoutA");
        break;
    }
  }
}
