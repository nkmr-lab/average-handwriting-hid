// ============================================================
// morphingVisualizer.pde — 平均文字間のモーフィング
// ============================================================
// 2つ以上の平均化済みJSONをドロップすると、
// フーリエ係数の加重平均で中間状態をモーフィング表示する。
//
// 使い方:
//   1. batchAverager 等で出力した平均JSONを2つ以上D&D
//   2. 自動でモーフィングアニメーション + 画像連番出力
//
// キー操作:
//   Space — モーフィング開始/リセット
//   C     — データクリア
// ============================================================

import java.io.*;

ArrayList<CharData> charDataList;
int g_iNumOfStroke = 0;

// モーフィング設定
int MORPH_STEPS = 4;  // 2つの文字間の補間ステップ数
int morphFrame = 0;
int totalFrames = 0;
boolean morphing = false;

color[] COLORS = {
  color(255, 100, 100), color(100, 100, 255), color(50, 150, 100),
  color(250, 150, 100), color(150, 50, 255), color(0, 150, 55)
};

void setup() {
  size(1200, 1200);

  PFont font = createFont("Meiryo", 32, true);
  textFont(font);

  charDataList = new ArrayList<CharData>();
  initFileDrop();
}

void draw() {
  if (morphing && charDataList.size() >= 2) {
    drawMorphFrame();
  } else if (!morphing) {
    drawWaiting();
  }
}

void drawWaiting() {
  background(255);
  fill(0);
  textSize(24);
  textAlign(CENTER, CENTER);

  if (charDataList.size() < 2) {
    text("平均化済み JSON を2つ以上ドロップしてください\n(現在: " + charDataList.size() + " 個)", width / 2, height / 3);
    text("[Space] モーフィング開始", width / 2, height * 2 / 3);
  } else {
    text(charDataList.size() + " 個のデータをロード済み\n[Space] でモーフィング開始", width / 2, height / 2);
  }
}

void drawMorphFrame() {
  if (morphFrame >= totalFrames) {
    println("[Morphing] Complete. " + totalFrames + " frames saved.");
    morphing = false;
    return;
  }

  // どの2つの文字の間か、比率はいくつかを計算
  int pairIndex = morphFrame / MORPH_STEPS;
  int step = morphFrame % MORPH_STEPS;

  // 最後の文字は単独表示
  if (pairIndex >= charDataList.size() - 1) {
    pairIndex = charDataList.size() - 2;
    step = MORPH_STEPS;
  }

  float ratio = (float) step / MORPH_STEPS; // 0.0 → 1.0

  CharData cdA = charDataList.get(pairIndex);
  CharData cdB = charDataList.get(pairIndex + 1);

  // フーリエ係数を加重平均
  AverageChar morphed = morphBetween(cdA, cdB, ratio);

  // 描画
  background(255);
  fill(0);
  textSize(28);
  textAlign(CENTER, TOP);
  String labelA = getLabel(cdA, pairIndex);
  String labelB = getLabel(cdB, pairIndex + 1);
  text(labelA + " (" + nf((1 - ratio) * 100, 0, 0) + "%) → "
     + labelB + " (" + nf(ratio * 100, 0, 0) + "%)", width / 2, 20);

  morphed.display(0, 0);

  // 画像保存
  String frameName = "morph/" + nf(morphFrame + 1, 4) + ".png";
  saveFrame(frameName);
  println("[Morphing] Frame " + (morphFrame + 1) + "/" + totalFrames + " → " + frameName);

  morphFrame++;
}

String getLabel(CharData cd, int idx) {
  if (cd.character != null && !cd.character.equals("")) return cd.character;
  if (cd.sourcePath != null) {
    File f = new File(cd.sourcePath);
    String name = f.getName();
    if (name.endsWith(".json")) name = name.substring(0, name.length() - 5);
    return name;
  }
  return "data" + idx;
}

// --- 2つの CharData 間をモーフィング ---
AverageChar morphBetween(CharData a, CharData b, float ratio) {
  AverageChar result = new AverageChar();
  result.numSamples = 2;

  int numStrokes = min(a.numStrokes(), b.numStrokes());

  for (int s = 0; s < numStrokes; s++) {
    Fourier fA = a.fouriers.get(s);
    Fourier fB = b.fouriers.get(s);

    // 係数を補間
    Fourier fM = new Fourier(MAX_FOURIER_DEGREE);
    for (int k = 0; k <= MAX_FOURIER_DEGREE; k++) {
      fM.aX[k] = lerp(fA.aX[k], fB.aX[k], ratio);
      fM.bX[k] = lerp(fA.bX[k], fB.bX[k], ratio);
      fM.aY[k] = lerp(fA.aY[k], fB.aY[k], ratio);
      fM.bY[k] = lerp(fA.bY[k], fB.bY[k], ratio);
    }

    int numPts = (a.splinedPts.get(s).length + b.splinedPts.get(s).length) / 2;
    int deg = fM.appropriateDegree(MAX_FOURIER_DEGREE, numPts, FOURIER_THRESHOLD);
    PointF[] pts = fM.reconstruct(deg, numPts, FOURIER_THRESHOLD);
    result.avgStrokePts.add(pts);

    // 筆圧も補間
    float[] presA = a.splinedPressures.get(s);
    float[] presB = b.splinedPressures.get(s);
    float[] presM = new float[numPts];
    for (int j = 0; j < numPts; j++) {
      float tA = (float) j / (numPts - 1) * (presA.length - 1);
      float tB = (float) j / (numPts - 1) * (presB.length - 1);
      int iA = constrain((int) tA, 0, presA.length - 2);
      int iB = constrain((int) tB, 0, presB.length - 2);
      float pA = lerp(presA[iA], presA[min(iA + 1, presA.length - 1)], tA - iA);
      float pB = lerp(presB[iB], presB[min(iB + 1, presB.length - 1)], tB - iB);
      presM[j] = lerp(pA, pB, ratio);
    }
    result.avgPressures.add(presM);
  }

  return result;
}

// --- ファイルドロップ ---
void onFileDrop(String path) {
  if (!path.endsWith(".json")) return;

  int strokeLen = getStrokeLengthFromJSON(path);
  if (g_iNumOfStroke == 0) {
    g_iNumOfStroke = strokeLen;
  } else if (strokeLen != g_iNumOfStroke) {
    println("[Skip] Stroke count mismatch: " + path);
    return;
  }

  ArrayList<HWStroke> strokes = loadHandwriting(path);
  if (strokes.size() == 0) return;

  resizeStrokes(strokes, 100, 100, 1100, 1100);
  String ch = getCharacterFromJSON(path);
  CharData cd = new CharData(ch, strokes);
  cd.sourcePath = path;
  charDataList.add(cd);

  println("[Loaded] " + path + " (total: " + charDataList.size() + ")");
}

// --- キー操作 ---
void keyPressed() {
  if (key == ' ' && charDataList.size() >= 2) {
    morphFrame = 0;
    totalFrames = (charDataList.size() - 1) * MORPH_STEPS + 1;
    morphing = true;
    println("[Morphing] Start: " + charDataList.size() + " chars, "
          + totalFrames + " frames");
  }
  if (key == 'c' || key == 'C') {
    charDataList.clear();
    g_iNumOfStroke = 0;
    morphing = false;
    println("[Clear]");
  }
}
