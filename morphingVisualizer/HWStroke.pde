// ============================================================
// HWStroke.pde — 1画分のストローク（HWPoint の配列）
// ============================================================

class HWStroke {
  ArrayList<HWPoint> points;

  HWStroke() {
    points = new ArrayList<HWPoint>();
  }

  void addPoint(HWPoint p) {
    points.add(p);
  }

  HWPoint getLastPoint() {
    if (points.size() == 0) return new HWPoint();
    return points.get(points.size() - 1);
  }

  int size() {
    return points.size();
  }

  HWPoint get(int i) {
    return points.get(i);
  }

  // PointF 配列に変換（Fourier/Spline 用、x/y のみ）
  PointF[] toPointFArray() {
    PointF[] arr = new PointF[points.size()];
    for (int i = 0; i < points.size(); i++) {
      arr[i] = new PointF(points.get(i).x, points.get(i).y);
    }
    return arr;
  }

  // 筆圧配列を取得（Fourier 平均化用）
  float[] getPressureArray() {
    float[] arr = new float[points.size()];
    for (int i = 0; i < points.size(); i++) {
      arr[i] = points.get(i).pressure;
    }
    return arr;
  }

  // 描画
  void display(color col, float weight) {
    stroke(col);
    strokeWeight(weight);
    for (int i = 0; i < points.size() - 1; i++) {
      line(points.get(i).x, points.get(i).y,
           points.get(i + 1).x, points.get(i + 1).y);
    }
  }

  // 筆圧で太さを変えて描画
  void displayWithPressure(color col, float maxWeight) {
    stroke(col);
    for (int i = 0; i < points.size() - 1; i++) {
      float w = map(points.get(i).pressure, 0, 8191, 1, maxWeight);
      strokeWeight(w);
      line(points.get(i).x, points.get(i).y,
           points.get(i + 1).x, points.get(i + 1).y);
    }
  }
}
