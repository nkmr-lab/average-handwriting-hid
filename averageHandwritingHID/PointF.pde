// ============================================================
// PointF.pde — Fourier/Spline 内部で使う float 点
// ============================================================

class PointF {
  float x, y;

  PointF() {
    x = 0;
    y = 0;
  }

  PointF(float x, float y) {
    this.x = x;
    this.y = y;
  }
}
