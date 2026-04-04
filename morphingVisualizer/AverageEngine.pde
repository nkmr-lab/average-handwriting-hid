// ============================================================
// AverageEngine.pde — 手書き文字の平均化エンジン
// ============================================================
// 処理の流れ:
//   1. 各手書きの各ストロークをスプライン補間
//   2. フーリエ級数展開 (x/y)
//   3. フーリエ係数を平均
//   4. 復元して平均ストロークを生成
//   5. 筆圧はリサンプリングして平均
// ============================================================

static final int MAX_FOURIER_DEGREE = 100;
static final float FOURIER_THRESHOLD = 0.001;
static final int SPLINE_MULTIPLE = 200;

// --- 1つの手書きデータ（複数ストローク + メタ情報）---
class CharData {
  ArrayList<HWStroke> rawStrokes;        // 生データ
  ArrayList<Fourier>  fouriers;          // 各ストロークのフーリエ
  ArrayList<PointF[]> splinedPts;        // スプライン後の点列
  ArrayList<float[]>  splinedPressures;  // スプライン後の筆圧
  ArrayList<Integer>  degrees;           // 各ストロークの適切次数
  String character;
  String sourcePath;

  CharData(String character, ArrayList<HWStroke> strokes) {
    this.character = character;
    this.rawStrokes = strokes;
    this.fouriers = new ArrayList<Fourier>();
    this.splinedPts = new ArrayList<PointF[]>();
    this.splinedPressures = new ArrayList<float[]>();
    this.degrees = new ArrayList<Integer>();
    process();
  }

  void process() {
    Spline sp = new Spline();
    for (HWStroke st : rawStrokes) {
      PointF[] orgPts = st.toPointFArray();
      float[] orgPres = st.getPressureArray();

      // スプライン補間 + DoubleBack
      PointF[] spPts = sp.interpolate(orgPts, SPLINE_MULTIPLE);
      float[]  spPre = sp.interpolate1D(orgPres, SPLINE_MULTIPLE);
      splinedPts.add(spPts);
      splinedPressures.add(spPre);

      // フーリエ級数展開
      Fourier f = new Fourier();
      f.expand(spPts, MAX_FOURIER_DEGREE);
      fouriers.add(f);

      int deg = f.appropriateDegree(MAX_FOURIER_DEGREE, spPts.length, FOURIER_THRESHOLD);
      degrees.add(deg);
    }
  }

  int numStrokes() {
    return rawStrokes.size();
  }
}

// --- 平均文字データ ---
class AverageChar {
  ArrayList<PointF[]> avgStrokePts;     // 各ストロークの平均点列
  ArrayList<float[]>  avgPressures;     // 各ストロークの平均筆圧
  int numSamples;

  AverageChar() {
    avgStrokePts = new ArrayList<PointF[]>();
    avgPressures = new ArrayList<float[]>();
    numSamples = 0;
  }

  // 筆圧反映して描画
  void display(float offsetX, float offsetY) {
    pushMatrix();
    translate(offsetX, offsetY);
    for (int s = 0; s < avgStrokePts.size(); s++) {
      PointF[] pts = avgStrokePts.get(s);
      float[] pres = avgPressures.get(s);
      int half = pts.length / 2;
      stroke(0);
      for (int i = 0; i < half - 1; i++) {
        float w = map(pres[i], 0, 8191, 2, 20);
        strokeWeight(w);
        line(pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y);
      }
    }
    popMatrix();
  }

  // 線幅固定で描画
  void displayFlat(float offsetX, float offsetY, color col, float weight) {
    pushMatrix();
    translate(offsetX, offsetY);
    stroke(col);
    strokeWeight(weight);
    for (int s = 0; s < avgStrokePts.size(); s++) {
      PointF[] pts = avgStrokePts.get(s);
      int half = pts.length / 2;
      for (int i = 0; i < half - 1; i++) {
        line(pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y);
      }
    }
    popMatrix();
  }
}

// --- 平均化 ---
AverageChar computeAverage(ArrayList<CharData> charDataList, int count) {
  AverageChar avg = new AverageChar();
  if (charDataList.size() == 0) return avg;

  int n = min(count, charDataList.size());
  avg.numSamples = n;
  int numStrokes = charDataList.get(0).numStrokes();

  for (int s = 0; s < numStrokes; s++) {
    // フーリエ係数を平均
    Fourier avgF = new Fourier(MAX_FOURIER_DEGREE);
    int totalSplinePts = 0;

    for (int i = 0; i < n; i++) {
      CharData cd = charDataList.get(i);
      Fourier f = cd.fouriers.get(s);
      totalSplinePts += cd.splinedPts.get(s).length;
      for (int k = 0; k <= MAX_FOURIER_DEGREE; k++) {
        avgF.aX[k] += f.aX[k];
        avgF.bX[k] += f.bX[k];
        avgF.aY[k] += f.aY[k];
        avgF.bY[k] += f.bY[k];
      }
    }
    for (int k = 0; k <= MAX_FOURIER_DEGREE; k++) {
      avgF.aX[k] /= n;
      avgF.bX[k] /= n;
      avgF.aY[k] /= n;
      avgF.bY[k] /= n;
    }

    int avgNumPts = totalSplinePts / n;
    int deg = avgF.appropriateDegree(MAX_FOURIER_DEGREE, avgNumPts, FOURIER_THRESHOLD);
    PointF[] pts = avgF.reconstruct(deg, avgNumPts, FOURIER_THRESHOLD);
    avg.avgStrokePts.add(pts);

    // 筆圧を平均（等間隔リサンプリングしてから平均）
    int resampleN = avgNumPts;
    float[] avgPres = new float[resampleN];
    for (int i = 0; i < n; i++) {
      float[] pres = charDataList.get(i).splinedPressures.get(s);
      for (int j = 0; j < resampleN; j++) {
        float t = (float) j / (resampleN - 1) * (pres.length - 1);
        int idx = (int) t;
        float frac = t - idx;
        if (idx >= pres.length - 1) {
          avgPres[j] += pres[pres.length - 1];
        } else {
          avgPres[j] += lerp(pres[idx], pres[idx + 1], frac);
        }
      }
    }
    for (int j = 0; j < resampleN; j++) {
      avgPres[j] /= n;
    }
    avg.avgPressures.add(avgPres);
  }

  return avg;
}

// --- リサイズ（正規化）---
void resizeStrokes(ArrayList<HWStroke> strokes, float x1, float y1, float x2, float y2) {
  float minX = Float.MAX_VALUE, minY = Float.MAX_VALUE;
  float maxX = -Float.MAX_VALUE, maxY = -Float.MAX_VALUE;

  for (HWStroke st : strokes) {
    for (int i = 0; i < st.size(); i++) {
      HWPoint p = st.get(i);
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
  }

  float centerX = (maxX + minX) / 2;
  float centerY = (maxY + minY) / 2;
  float side = max(maxX - minX, maxY - minY);
  if (side < 1) return;

  // 正方形に正規化
  float adjMinX = centerX - side / 2;
  float adjMinY = centerY - side / 2;

  for (HWStroke st : strokes) {
    for (int i = 0; i < st.size(); i++) {
      HWPoint p = st.get(i);
      p.x = (p.x - adjMinX) * (x2 - x1) / side + x1;
      p.y = (p.y - adjMinY) * (y2 - y1) / side + y1;
    }
  }
}
