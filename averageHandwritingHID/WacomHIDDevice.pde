// ============================================================
// WacomHIDDevice.pde — デバイスの基本情報定義
// ============================================================
// 同じデバイスでもドライバ環境によってバイトレイアウトが
// 変わるが、デバイスの物理特性 (VID/PID/解像度等) は変わらない。
// この情報だけをここに集めて、レイアウトとは独立に管理する。
//
// 新しいデバイスを追加したら下の static {} ブロックに登録する。
// ============================================================

// --- デバイス1個分のデータ ---
static class WacomHIDDevice {
  String NAME;
  int    VENDOR_ID;
  int    PRODUCT_ID;
  int    TABLET_X_MAX;
  int    TABLET_Y_MAX;
  float  DIST_RAW_MIN;
  float  DIST_RAW_MAX;
  float  DIST_MM_MAX;

  WacomHIDDevice(String name) {
    NAME = name;
  }
}

// --- デバイス レジストリ ---
static class WacomHIDDevices {
  static java.util.HashMap<String, WacomHIDDevice> ALL = new java.util.HashMap<String, WacomHIDDevice>();

  static {
    // ============================================================
    // Wacom One 12 (DTC-121) — ペン入力液タブ
    // ============================================================
    WacomHIDDevice wo12 = new WacomHIDDevice("WacomOne12");
    wo12.VENDOR_ID    = 0x056A;
    wo12.PRODUCT_ID   = 0x03CE;
    wo12.TABLET_X_MAX = 32767;
    wo12.TABLET_Y_MAX = 32764;
    wo12.DIST_RAW_MIN = 5300;
    wo12.DIST_RAW_MAX = 9000;
    wo12.DIST_MM_MAX  = 11.0;
    ALL.put(wo12.NAME, wo12);

    // ============================================================
    // Wacom One 13 Touch (DTH-134) — ペン＋タッチ液タブ
    // ============================================================
    WacomHIDDevice wo13t = new WacomHIDDevice("WacomOne13Touch");
    wo13t.VENDOR_ID    = 0x056A;
    wo13t.PRODUCT_ID   = 0x03CE;
    wo13t.TABLET_X_MAX = 32767;
    wo13t.TABLET_Y_MAX = 32764;
    wo13t.DIST_RAW_MIN = 5300;
    wo13t.DIST_RAW_MAX = 9000;
    wo13t.DIST_MM_MAX  = 11.0;
    ALL.put(wo13t.NAME, wo13t);

    // ============================================================
    // Intuos Pro Large (PTH-860) — プロ用板タブ
    // ============================================================
    WacomHIDDevice ip860 = new WacomHIDDevice("IntuosPro_PTH860");
    ip860.VENDOR_ID    = 0x056A;
    ip860.PRODUCT_ID   = 0x0357;
    ip860.TABLET_X_MAX = 44800;
    ip860.TABLET_Y_MAX = 29600;
    ip860.DIST_RAW_MIN = 3000;
    ip860.DIST_RAW_MAX = 7000;
    ip860.DIST_MM_MAX  = 10.0;
    ALL.put(ip860.NAME, ip860);
  }

  static WacomHIDDevice get(String name) {
    WacomHIDDevice d = ALL.get(name);
    if (d == null) {
      println("[WacomHIDDevices] Unknown device: " + name);
      // フォールバック用ダミー
      WacomHIDDevice fallback = new WacomHIDDevice("Unknown");
      fallback.VENDOR_ID    = 0x056A;
      fallback.PRODUCT_ID   = 0x0000;
      fallback.TABLET_X_MAX = 32767;
      fallback.TABLET_Y_MAX = 32767;
      fallback.DIST_RAW_MIN = 5000;
      fallback.DIST_RAW_MAX = 9000;
      fallback.DIST_MM_MAX  = 11.0;
      return fallback;
    }
    return d;
  }
}
