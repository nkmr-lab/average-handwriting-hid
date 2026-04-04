// ============================================================
// averageHandwritingHID.pde — 平均手書き文字システム
// ============================================================
// WacomHID で手書きを収集し、フーリエ係数の平均化で
// 「平均手書き文字」を生成する。
//
// モード:
//   COLLECT  — ペンで文字を書いて JSON 保存
//   VISUALIZE — JSON をドラッグ＆ドロップして平均文字を生成
//
// キー操作:
//   Tab — モード切替
// ============================================================

// --- モード ---
static final int MODE_COLLECT   = 0;
static final int MODE_VISUALIZE = 1;
int appMode = MODE_COLLECT;

// --- WacomHID ---
WacomHIDConfig cfg;
WacomHID pen;

// --- 収集モード ---
HWCanvas canvas;
Button btnSave, btnReset;
String collectChar = "あ";
int saveCount = 0;

// --- 可視化モード ---
ArrayList<CharData> charDataList;
AverageChar averageChar;
boolean needRedraw = true;
int g_iNumOfStroke = 0; // 画数の一致チェック用

// --- 共通色 ---
color[] STROKE_COLORS = {
  color(255, 100, 100), color(100, 100, 255), color(50, 150, 100),
  color(250, 150, 100), color(150, 50, 255), color(0, 150, 55)
};

void setup() {
  size(1200, 900);
  frameRate(60);

  // 日本語フォント（Windowsに入っているメイリオを使用）
  PFont font = createFont("Meiryo", 32, true);
  textFont(font);

  cfg = new WacomHIDConfig(WACOM_DEVICE);
  pen = new WacomHID(this, cfg);
  pen.connect();

  // 収集モード UI
  canvas = new HWCanvas(100, 120, 700, 700);
  btnSave  = new Button(850, 700, 250, 70, "ほぞん");
  btnReset = new Button(850, 600, 250, 70, "かきなおし", color(255, 50, 50));

  // 可視化モード
  charDataList = new ArrayList<CharData>();
  initFileDrop();
}

void draw() {
  pen.update();

  if (appMode == MODE_COLLECT) {
    drawCollectMode();
  } else {
    drawVisualizeMode();
  }

  // モード表示
  fill(80);
  textSize(14);
  textAlign(RIGHT, TOP);
  text("[Tab] モード切替  |  現在: " +
    (appMode == MODE_COLLECT ? "収集" : "可視化"), width - 20, 10);
}

// ============================================================
// 収集モード
// ============================================================
void drawCollectMode() {
  background(220);

  // ヘッダー
  fill(0);
  textSize(32);
  textAlign(CENTER, TOP);
  text("「" + collectChar + "」を書いてください", width / 2, 30);

  // ペン状態
  fill(100);
  textSize(14);
  textAlign(LEFT, TOP);
  String statusStr = pen.isConnected ?
    (pen.isTouching ? "TOUCH  P=" + pen.pressure : pen.isHovering ? "HOVER" : "OUT OF RANGE") :
    "NOT CONNECTED";
  text("Pen: " + statusStr, 20, 80);
  text("保存済み: " + saveCount + " 件", 20, 96);

  canvas.update(pen);
  canvas.display();
  btnSave.display();
  btnReset.display();
}

// ============================================================
// 可視化モード
// ============================================================
void drawVisualizeMode() {
  if (!needRedraw) return;
  background(255);

  fill(0);
  textSize(24);
  textAlign(CENTER, TOP);
  text("JSON ファイルをドラッグ＆ドロップ (N=" + charDataList.size() + ")", width / 2, 30);

  if (charDataList.size() > 0) {
    // 各個人のストロークを薄く表示
    for (int i = 0; i < charDataList.size(); i++) {
      CharData cd = charDataList.get(i);
      color col = STROKE_COLORS[i % STROKE_COLORS.length];
      for (HWStroke st : cd.rawStrokes) {
        st.display(col, 1);
      }
    }

    // 平均文字を太く描画
    averageChar = computeAverage(charDataList, charDataList.size());
    averageChar.display(0, 0);

    fill(0);
    textSize(18);
    textAlign(LEFT, BOTTOM);
    text("N=" + averageChar.numSamples, 20, height - 20);
  } else {
    fill(150);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("JSON ファイルをここにドロップ", width / 2, height / 2);
  }

  needRedraw = false;
}

// ============================================================
// 入力イベント
// ============================================================
void mousePressed() {
  if (appMode == MODE_COLLECT) {
    if (btnReset.clicked()) {
      canvas.reset();
    } else if (btnSave.clicked()) {
      if (canvas.strokes.size() > 0) {
        String timestamp = year() + nf(month(), 2) + nf(day(), 2) + "_"
                         + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
        String filename = "save/handwriting_" + collectChar + "_" + timestamp;
        saveHandwriting(filename, canvas.strokes, collectChar);
        saveCount++;
        canvas.reset();
      }
    }
  }
}

void keyPressed() {
  if (key == TAB) {
    appMode = (appMode == MODE_COLLECT) ? MODE_VISUALIZE : MODE_COLLECT;
    needRedraw = true;
  }
  if (appMode == MODE_VISUALIZE && (key == 'c' || key == 'C')) {
    charDataList.clear();
    g_iNumOfStroke = 0;
    needRedraw = true;
  }
}

// ============================================================
// ファイルドロップで呼ばれる
// ============================================================
void loadStrokeFile(String path) {
  if (!path.endsWith(".json")) return;

  int strokeLen = getStrokeLengthFromJSON(path);
  if (g_iNumOfStroke == 0) {
    g_iNumOfStroke = strokeLen;
  } else if (strokeLen != g_iNumOfStroke) {
    println("[Skip] Stroke count mismatch: " + strokeLen + " vs " + g_iNumOfStroke);
    return;
  }

  ArrayList<HWStroke> strokes = loadHandwriting(path);
  if (strokes.size() == 0) return;

  // 正規化（100,100 - 900,800 の領域に収める）
  resizeStrokes(strokes, 100, 100, 900, 800);

  String ch = getCharacterFromJSON(path);
  CharData cd = new CharData(ch, strokes);
  cd.sourcePath = path;
  charDataList.add(cd);

  needRedraw = true;
  appMode = MODE_VISUALIZE;
  println("[Loaded] " + path + " (total: " + charDataList.size() + ")");
}
