// ============================================================
// batchAverager.pde — フォルダ内のJSONを一括平均化
// ============================================================
// 指定フォルダ内の手書きJSONを正規表現でグルーピングし、
// 各グループの平均手書き文字を画像 + JSON で出力する。
//
// 使い方:
//   1. DATA_PATH を手書き JSON のあるフォルダに設定
//   2. グループ定義 (GROUPS) を必要に応じて編集
//   3. 実行すると自動でバッチ処理が始まる
// ============================================================

import java.io.*;

// ★ ここを編集 ★
String DATA_PATH = "";  // 手書き JSON のフォルダパス（空なら sketchPath()/data/）

// グループ定義: { 出力名, ファイル名にマッチする正規表現 }
String[][] GROUPS = {
  {"all",    "\\-"},
  {"0-19",   "0\\-9|10\\-14|15\\-19"},
  {"20-39",  "20\\-29|30\\-39"},
  {"40-59",  "40\\-49|50\\-59"},
  {"60-",    "60\\-69|70\\-"},
  {"0-9",    "0\\-9"},
  {"10-14",  "10\\-14"},
  {"15-19",  "15\\-19"},
  {"20-29",  "20\\-29"},
  {"30-39",  "30\\-39"},
  {"40-49",  "40\\-49"},
  {"50-59",  "50\\-59"},
  {"60-69",  "60\\-69"},
  {"70-",    "70\\-"}
};

ArrayList<CharData> allChars;
int currentGroup = 0;
int g_iNumOfStroke = 0;
boolean processing = true;

color[] COLORS = {
  color(255, 100, 100), color(100, 100, 255), color(50, 150, 100),
  color(250, 150, 100), color(150, 50, 255), color(0, 150, 55)
};

void setup() {
  size(1200, 1200);

  PFont font = createFont("Meiryo", 32, true);
  textFont(font);

  if (DATA_PATH.equals("")) {
    DATA_PATH = sketchPath() + "/data/";
  }

  allChars = new ArrayList<CharData>();
  loadAllFiles();

  println("[Batch] Loaded " + allChars.size() + " files from " + DATA_PATH);
  println("[Batch] Processing " + GROUPS.length + " groups...");
}

void draw() {
  if (!processing || currentGroup >= GROUPS.length) {
    if (processing) {
      println("[Batch] All groups processed.");
      processing = false;
    }
    return;
  }

  String groupName = GROUPS[currentGroup][0];
  String pattern   = GROUPS[currentGroup][1];

  // パターンにマッチするデータを収集
  ArrayList<CharData> matched = new ArrayList<CharData>();
  for (CharData cd : allChars) {
    String[] m = match(cd.sourcePath, pattern);
    if (m != null) {
      matched.add(cd);
    }
  }

  println("[Batch] Group: " + groupName + " — matched " + matched.size() + " files");

  if (matched.size() > 0) {
    // 描画
    background(255);
    fill(0);
    textSize(36);
    textAlign(CENTER, TOP);
    text(groupName + " (N=" + matched.size() + ")", width / 2, 20);

    // 個別ストローク（薄く）
    for (int i = 0; i < matched.size(); i++) {
      CharData cd = matched.get(i);
      color col = COLORS[i % COLORS.length];
      for (HWStroke st : cd.rawStrokes) {
        st.display(col, 1);
      }
    }

    // 平均
    AverageChar avg = computeAverage(matched, matched.size());
    avg.display(0, 0);

    // 画像保存
    String imgPath = "output/" + groupName + ".png";
    saveFrame(imgPath);
    println("[Batch] Saved image: " + imgPath);

    // 平均JSONも保存（元ストロークを再構築して保存）
    // ※平均化後のデータはフーリエ復元点なので、HWStrokeに変換して保存
    ArrayList<HWStroke> avgStrokes = new ArrayList<HWStroke>();
    for (int s = 0; s < avg.avgStrokePts.size(); s++) {
      PointF[] pts = avg.avgStrokePts.get(s);
      float[] pres = avg.avgPressures.get(s);
      HWStroke st = new HWStroke();
      int half = pts.length / 2;
      for (int j = 0; j < half; j++) {
        int presVal = (j < pres.length) ? (int) pres[j] : 0;
        st.addPoint(new HWPoint(pts[j].x, pts[j].y, presVal, 0, 0, 0));
      }
      avgStrokes.add(st);
    }
    saveHandwriting("output/" + groupName, avgStrokes, groupName);
  }

  currentGroup++;
}

// --- ディレクトリ内のJSONを全読み ---
void loadAllFiles() {
  File dir = new File(DATA_PATH);
  if (!dir.exists() || !dir.isDirectory()) {
    println("[Batch] Directory not found: " + DATA_PATH);
    return;
  }

  File[] files = dir.listFiles();
  for (File f : files) {
    if (!f.getName().endsWith(".json")) continue;
    String path = f.getAbsolutePath();

    int strokeLen = getStrokeLengthFromJSON(path);
    if (g_iNumOfStroke == 0) {
      g_iNumOfStroke = strokeLen;
    } else if (strokeLen != g_iNumOfStroke) {
      println("[Skip] Stroke count mismatch: " + path);
      continue;
    }

    ArrayList<HWStroke> strokes = loadHandwriting(path);
    if (strokes.size() == 0) continue;

    resizeStrokes(strokes, 100, 100, 1100, 1100);
    CharData cd = new CharData("", strokes);
    cd.sourcePath = path;
    allChars.add(cd);
  }
}
