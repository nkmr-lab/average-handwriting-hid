// ============================================================
// HWPoint.pde — 筆圧・傾き・距離付きの点
// ============================================================

class HWPoint {
  float x, y;
  int   pressure;     // 0-8191
  float tiltX, tiltY; // 度
  int   distance;     // raw 距離値

  HWPoint() {
    this(0, 0, 0, 0, 0, 0);
  }

  HWPoint(float x, float y) {
    this(x, y, 0, 0, 0, 0);
  }

  HWPoint(float x, float y, int pressure, float tiltX, float tiltY, int distance) {
    this.x = x;
    this.y = y;
    this.pressure = pressure;
    this.tiltX = tiltX;
    this.tiltY = tiltY;
    this.distance = distance;
  }

  JSONObject toJSON() {
    JSONObject j = new JSONObject();
    j.setFloat("x", x);
    j.setFloat("y", y);
    j.setInt("pressure", pressure);
    j.setFloat("tiltX", tiltX);
    j.setFloat("tiltY", tiltY);
    j.setInt("distance", distance);
    return j;
  }

}

HWPoint hwPointFromJSON(JSONObject j) {
  return new HWPoint(
    j.getFloat("x"), j.getFloat("y"),
    j.hasKey("pressure") ? j.getInt("pressure") : 0,
    j.hasKey("tiltX") ? j.getFloat("tiltX") : 0,
    j.hasKey("tiltY") ? j.getFloat("tiltY") : 0,
    j.hasKey("distance") ? j.getInt("distance") : 0
  );
}
