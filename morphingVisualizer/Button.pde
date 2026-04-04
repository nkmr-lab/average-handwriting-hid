// ============================================================
// Button.pde — シンプルなボタン UI
// ============================================================

class Button {
  float bx, by;
  int bw, bh;
  String label;
  color col;
  boolean visible;

  Button(float x, float y, int w, int h, String label) {
    this(x, y, w, h, label, color(50, 50, 255));
  }

  Button(float x, float y, int w, int h, String label, color c) {
    bx = x;
    by = y;
    bw = w;
    bh = h;
    this.label = label;
    col = c;
    visible = true;
  }

  void display() {
    if (!visible) return;
    stroke(0);
    strokeWeight(1);
    fill(col);
    rect(bx, by, bw, bh, 6);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(28);
    text(label, bx + bw / 2, by + bh / 2);
  }

  boolean clicked() {
    if (!visible) return false;
    return mousePressed && mouseX >= bx && mouseX <= bx + bw
                        && mouseY >= by && mouseY <= by + bh;
  }

  void show() { visible = true; }
  void hide() { visible = false; }
}
