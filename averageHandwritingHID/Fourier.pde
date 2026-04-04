// ============================================================
// Fourier.pde — フーリエ級数展開（x/y 座標用）
// ============================================================
// original: average-figure-processing

class Fourier {
  float[] aX, bX; // x のフーリエ係数 (cos, sin)
  float[] aY, bY; // y のフーリエ係数 (cos, sin)

  Fourier() {}

  Fourier(int degree) {
    init(degree);
  }

  void init(int degree) {
    aX = new float[degree + 1];
    bX = new float[degree + 1];
    aY = new float[degree + 1];
    bY = new float[degree + 1];
  }

  // フーリエ級数展開
  void expand(PointF[] pts, int maxDegree) {
    int N = pts.length;
    aX = new float[maxDegree + 1];
    bX = new float[maxDegree + 1];
    aY = new float[maxDegree + 1];
    bY = new float[maxDegree + 1];

    for (int k = 0; k <= min(maxDegree, N / 2); k++) {
      aX[k] = 0; bX[k] = 0;
      aY[k] = 0; bY[k] = 0;
      for (int n = 0; n < N; n++) {
        float t = TWO_PI * (float) n / N - PI;
        aX[k] += pts[n].x * cos(k * t);
        bX[k] += pts[n].x * sin(k * t);
        aY[k] += pts[n].y * cos(k * t);
        bY[k] += pts[n].y * sin(k * t);
      }
      aX[k] *= 2.0 / N;
      bX[k] *= 2.0 / N;
      aY[k] *= 2.0 / N;
      bY[k] *= 2.0 / N;
    }
    aX[0] /= 2;
    aY[0] /= 2;
    bX[0] /= 2;
    bY[0] /= 2;
  }

  // 適切な次数を求める
  int appropriateDegree(int maxDegree, int numPoints, float threshold) {
    if (maxDegree >= 100) return maxDegree;
    PointF[] prev = null;
    int deg = 2;
    for (int l = 2; l <= maxDegree; l++) {
      PointF[] cur = reconstruct(l, numPoints, threshold);
      if (prev != null) {
        float sum = 0;
        for (int i = 0; i < cur.length; i++) {
          sum += dist(cur[i].x, cur[i].y, prev[i].x, prev[i].y);
        }
        if (sum / cur.length < 1) {
          deg = l;
          break;
        }
      }
      deg = l;
      prev = cur;
    }
    return deg;
  }

  // フーリエ級数から点列を復元
  PointF[] reconstruct(int degree, int numPoints, float threshold) {
    PointF[] pts = new PointF[numPoints];
    for (int i = 0; i < numPoints; i++) {
      float x = aX[0];
      float y = aY[0];
      for (int k = 1; k <= degree; k++) {
        float t = TWO_PI * (float) i / numPoints;
        if (abs(aX[k]) > threshold) x += aX[k] * cos(k * t);
        if (abs(bX[k]) > threshold) x += bX[k] * sin(k * t);
        if (abs(aY[k]) > threshold) y += aY[k] * cos(k * t);
        if (abs(bY[k]) > threshold) y += bY[k] * sin(k * t);
      }
      pts[i] = new PointF(x, y);
    }
    return pts;
  }
}
