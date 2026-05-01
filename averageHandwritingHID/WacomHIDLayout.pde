// ============================================================
// WacomHIDLayout.pde — HID レポートのバイト配置パターン定義
// ============================================================
// 同じデバイスでもドライバ環境によってレイアウトが変わるため、
// パターンを名前付きで登録しておき、必要に応じて切り替える。
//
// 新しいパターンを発見したら addLayout() で追加するだけ。
// ============================================================

// --- レイアウト1個分のデータ ---
static class WacomHIDLayout {
  String NAME;

  // バイト位置 (-1 = そのレイアウトには無い)
  int STATUS_BYTE   = 1;
  int X_LOW         = -1, X_HIGH        = -1;
  int Y_LOW         = -1, Y_HIGH        = -1;
  int PRESSURE_LOW  = -1, PRESSURE_HIGH = -1;
  int TILT_X_LOW    = -1, TILT_X_HIGH   = -1;
  int TILT_Y_LOW    = -1, TILT_Y_HIGH   = -1;
  int DISTANCE_LOW  = -1, DISTANCE_HIGH = -1;  // DISTANCE_HIGH = -1 なら 1バイト距離

  // ステータスコード値
  int STATUS_OUT_OF_RANGE = 0x00;
  int STATUS_HOVER        = 0x20;
  int STATUS_TOUCH        = 0x21;

  WacomHIDLayout(String name) {
    NAME = name;
  }
}

// --- レイアウト レジストリ ---
static class WacomHIDLayouts {
  static java.util.HashMap<String, WacomHIDLayout> ALL = new java.util.HashMap<String, WacomHIDLayout>();

  static {
    // ============================================================
    // LayoutA: X/Y がパックされた標準フォーマット (Windows標準)
    // ============================================================
    WacomHIDLayout a = new WacomHIDLayout("LayoutA");
    a.STATUS_BYTE   = 1;
    a.X_LOW         = 2;   a.X_HIGH        = 3;
    a.Y_LOW         = 4;   a.Y_HIGH        = 5;
    a.PRESSURE_LOW  = 8;   a.PRESSURE_HIGH = 9;
    a.TILT_X_LOW    = 28;  a.TILT_X_HIGH   = 29;
    a.TILT_Y_LOW    = 30;  a.TILT_Y_HIGH   = 31;
    a.DISTANCE_LOW  = 32;  a.DISTANCE_HIGH = 33;
    ALL.put(a.NAME, a);

    // ============================================================
    // LayoutB: X/Y の間に隙間があるパターン (Mac等で出現)
    //   bytes 32,33 にデバイス内部クロックが入っている
    // ============================================================
    WacomHIDLayout b = new WacomHIDLayout("LayoutB");
    b.STATUS_BYTE   = 1;
    b.X_LOW         = 3;   b.X_HIGH        = 4;
    b.Y_LOW         = 6;   b.Y_HIGH        = 7;
    b.PRESSURE_LOW  = 9;   b.PRESSURE_HIGH = 10;
    b.TILT_X_LOW    = 11;  b.TILT_X_HIGH   = 12;
    b.TILT_Y_LOW    = 13;  b.TILT_Y_HIGH   = 14;
    b.DISTANCE_LOW  = 19;  b.DISTANCE_HIGH = -1;  // 1バイト距離
    ALL.put(b.NAME, b);
  }

  static WacomHIDLayout get(String name) {
    WacomHIDLayout l = ALL.get(name);
    if (l == null) {
      println("[WacomHIDLayouts] Unknown layout: " + name + " — using LayoutA");
      return ALL.get("LayoutA");
    }
    return l;
  }
}
