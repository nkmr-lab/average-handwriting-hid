// ============================================================
// WacomHIDConfig.pde — 使用するデバイス + レイアウトの選択
// ============================================================
// データ本体は以下のファイルに分離:
//   WacomHIDDevice.pde — VID/PID/解像度等 (物理特性)
//   WacomHIDLayout.pde — HIDレポートのバイト配置パターン
//
// このファイルは「どれを使うか」を選んで、両者を組み合わせる。
// 値の参照は cfg.device.VENDOR_ID, cfg.layout.X_LOW のように行う。
// ============================================================

// ★ ここを切り替えるだけ ★
final String WACOM_DEVICE = "WacomOne12";
final String WACOM_LAYOUT = "LayoutA";
// final String WACOM_LAYOUT = "LayoutB";   // X/Y間に隙間があるパターン

// ============================================================

static class WacomHIDConfig {
  WacomHIDDevice device;
  WacomHIDLayout layout;

  WacomHIDConfig(String deviceName) {
    this(deviceName, "LayoutA");
  }

  WacomHIDConfig(String deviceName, String layoutName) {
    device = WacomHIDDevices.get(deviceName);
    layout = WacomHIDLayouts.get(layoutName);
  }
}
