// ============================================================
// WacomHIDConfig.pde — デバイス設定
// ============================================================
// 使うデバイスに合わせて下の行を切り替える。
// 新しいデバイスを追加するときは preset() 内に case を追加。
// 値の確認方法: WacomPenDetectorByHID (診断ツール) を実行して
// バイトテーブルで各パラメータの範囲を確認する。
// ============================================================

// ★ ここを切り替えるだけ ★
final String WACOM_DEVICE = "WacomOne12";
// final String WACOM_DEVICE = "WacomOne13Touch";
// final String WACOM_DEVICE = "IntuosPro_PTH860";

// ============================================================

static class WacomHIDConfig {

  int   VENDOR_ID;
  int   PRODUCT_ID;
  int   TABLET_X_MAX;
  int   TABLET_Y_MAX;
  float DIST_RAW_MIN;
  float DIST_RAW_MAX;
  float DIST_MM_MAX;
  String DEVICE_NAME;

  WacomHIDConfig(String device) {
    DEVICE_NAME = device;
    switch (device) {

      // ------------------------------------------------
      // Wacom One 12 (DTC-121) — ペン入力液タブ
      // ------------------------------------------------
      case "WacomOne12":
        VENDOR_ID    = 0x056A;
        PRODUCT_ID   = 0x03CE;
        TABLET_X_MAX = 32767;
        TABLET_Y_MAX = 32764;
        DIST_RAW_MIN = 5300;
        DIST_RAW_MAX = 9000;
        DIST_MM_MAX  = 11.0;
        break;

      // ------------------------------------------------
      // Wacom One 13 Touch (DTH-134) — ペン＋タッチ液タブ
      // ------------------------------------------------
      case "WacomOne13Touch":
        VENDOR_ID    = 0x056A;
        PRODUCT_ID   = 0x03CE;
        TABLET_X_MAX = 32767;
        TABLET_Y_MAX = 32764;
        DIST_RAW_MIN = 5300;
        DIST_RAW_MAX = 9000;
        DIST_MM_MAX  = 11.0;
        break;

      // ------------------------------------------------
      // Intuos Pro Large (PTH-860) — プロ用板タブ
      // ------------------------------------------------
      case "IntuosPro_PTH860":
        VENDOR_ID    = 0x056A;
        PRODUCT_ID   = 0x0357;
        TABLET_X_MAX = 44800;
        TABLET_Y_MAX = 29600;
        DIST_RAW_MIN = 3000;
        DIST_RAW_MAX = 7000;
        DIST_MM_MAX  = 10.0;
        break;

      // ------------------------------------------------
      // 不明なデバイス（診断ツールで値を調べて追加する）
      // ------------------------------------------------
      default:
        println("[WacomHIDConfig] Unknown device: " + device);
        println("[WacomHIDConfig] 診断ツールで値を確認してプリセットを追加してください");
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
}
