// ============================================================
// Spline.pde — スプライン補間
// ============================================================
// original: average-figure-processing

class Spline {

  PointF[] interpolate(PointF[] pts, int multiple) {
    if (pts.length < 2) return pts;

    float[] t = new float[pts.length];
    for (int i = 0; i < pts.length; i++) {
      t[i] = (float) i * PI / (pts.length - 1);
    }

    PointF[] forward = splineSeries(t, pts, multiple);

    // DoubleBack: 往復にする（フーリエ級数展開のため）
    PointF[] result = new PointF[forward.length * 2 - 1];
    for (int i = 0; i < forward.length; i++) {
      result[i] = forward[i];
      result[result.length - 1 - i] = new PointF(forward[i].x, forward[i].y);
    }
    return result;
  }

  // 1次元スプライン補間も提供（筆圧等に使う）
  float[] interpolate1D(float[] values, int multiple) {
    if (values.length < 2) return values;

    float[] t = new float[values.length];
    for (int i = 0; i < values.length; i++) {
      t[i] = (float) i * PI / (values.length - 1);
    }

    float[] forward = splineValues(t, values, multiple);

    // DoubleBack
    float[] result = new float[forward.length * 2 - 1];
    for (int i = 0; i < forward.length; i++) {
      result[i] = forward[i];
      result[result.length - 1 - i] = forward[i];
    }
    return result;
  }

  private PointF[] splineSeries(float[] t, PointF[] pts, int multiple) {
    if (pts.length == 2) {
      return linearInterpolate(pts, multiple);
    }

    float[] ax = new float[pts.length];
    float[] ay = new float[pts.length];
    for (int i = 0; i < pts.length; i++) {
      ax[i] = pts[i].x;
      ay[i] = pts[i].y;
    }

    float[] ix = splineValues(t, ax, multiple);
    float[] iy = splineValues(t, ay, multiple);

    // 近接点の除去
    ArrayList<PointF> result = new ArrayList<PointF>();
    result.add(new PointF(ix[0], iy[0]));
    for (int i = 1; i < ix.length; i++) {
      PointF last = result.get(result.size() - 1);
      if (dist(ix[i], iy[i], last.x, last.y) >= 0.05) {
        result.add(new PointF(ix[i], iy[i]));
      }
    }
    return result.toArray(new PointF[0]);
  }

  private PointF[] linearInterpolate(PointF[] pts, int multiple) {
    int n = pts.length * multiple;
    PointF[] result = new PointF[n];
    for (int i = 0; i < n; i++) {
      float t = (float) i / (n - 1);
      result[i] = new PointF(
        lerp(pts[0].x, pts[pts.length - 1].x, t),
        lerp(pts[0].y, pts[pts.length - 1].y, t)
      );
    }
    return result;
  }

  private float[] splineValues(float[] t, float[] v, int multiple) {
    int n = t.length - 1;
    float[] h = new float[n];
    float[] b = new float[n + 1];
    float[] d = new float[n + 1];
    float[] g = new float[n + 1];
    float[] u = new float[n + 1];
    float[] r = new float[n + 1];

    for (int i = 0; i < n; i++) h[i] = t[i + 1] - t[i];

    for (int i = 1; i < n; i++) {
      b[i] = 2.0 * (h[i] + h[i - 1]);
      d[i] = 3.0 * ((v[i + 1] - v[i]) / h[i] - (v[i] - v[i - 1]) / h[i - 1]);
    }

    if (n > 1) {
      g[1] = h[1] / b[1];
      for (int i = 2; i < n; i++) {
        g[i] = h[i] / (b[i] - h[i - 1] * g[i - 1]);
      }
      u[1] = d[1] / b[1];
      for (int i = 2; i < n; i++) {
        u[i] = (d[i] - h[i - 1] * u[i - 1]) / (b[i] - h[i - 1] * g[i - 1]);
      }
    }

    r[0] = 0;
    r[n] = 0;
    if (n > 1) {
      r[n - 1] = u[n - 1];
      for (int i = n - 2; i >= 1; i--) {
        r[i] = u[i] - g[i] * r[i + 1];
      }
    }

    float[] result = new float[(v.length - 1) * multiple + 1];
    int idx = 0;
    for (int i = 0; i < n; i++) {
      float step = h[i] / multiple;
      for (int j = 0; j < multiple; j++) {
        float sp = j * step;
        float qi = (v[i + 1] - v[i]) / h[i] - h[i] * (r[i + 1] + 2.0 * r[i]) / 3.0;
        float si = (r[i + 1] - r[i]) / (3.0 * h[i]);
        result[idx++] = v[i] + sp * (qi + sp * (r[i] + si * sp));
      }
    }
    result[result.length - 1] = v[v.length - 1];
    return result;
  }
}
