// ============================================================
// HWCanvas.pde — WacomHID でストロークを描くキャンバス
// ============================================================

class HWCanvas {
  float cx, cy;     // キャンバス左上
  int   cw, ch;     // キャンバスサイズ
  ArrayList<HWStroke> strokes;
  HWStroke currentStroke;
  boolean writing;

  HWCanvas(float x, float y, int w, int h) {
    cx = x;
    cy = y;
    cw = w;
    ch = h;
    strokes = new ArrayList<HWStroke>();
    writing = false;
  }

  void reset() {
    strokes = new ArrayList<HWStroke>();
    writing = false;
  }

  // WacomHID のペン状態に基づいて更新
  void update(WacomHID pen) {
    if (!pen.isConnected) return;

    float px = pen.screenX;
    float py = pen.screenY;
    boolean inArea = inArea(px, py);

    if (pen.isTouching && inArea) {
      HWPoint p = new HWPoint(
        px - cx, py - cy,
        pen.pressure, pen.tiltX, pen.tiltY, pen.distance
      );
      if (!writing) {
        writing = true;
        currentStroke = new HWStroke();
        currentStroke.addPoint(p);
      } else {
        HWPoint last = currentStroke.getLastPoint();
        if (dist(p.x, p.y, last.x, last.y) > 0.5) {
          currentStroke.addPoint(p);
        }
      }
    } else if (writing) {
      if (currentStroke.size() > 1) {
        strokes.add(currentStroke);
      }
      writing = false;
    }
  }

  boolean inArea(float px, float py) {
    return px >= cx && px <= cx + cw && py >= cy && py <= cy + ch;
  }

  // キャンバスを描画
  void display() {
    // 背景
    fill(255);
    stroke(0);
    strokeWeight(2);
    rect(cx, cy, cw, ch);

    // 確定済みストローク
    pushMatrix();
    translate(cx, cy);
    for (HWStroke st : strokes) {
      st.displayWithPressure(color(0, 0, 200), 8);
    }
    // 書き中のストローク
    if (writing && currentStroke != null) {
      currentStroke.displayWithPressure(color(0, 0, 200), 8);
    }
    popMatrix();
  }
}
