// ============================================================
// HWFormat.pde — JSON 保存・読み込み（筆圧・傾き・距離付き）
// ============================================================
// JSON フォーマット:
// {
//   "character": "あ",
//   "strokeLength": 3,
//   "strokes": [
//     { "points": [ {"x":10, "y":20, "pressure":1500, "tiltX":5.0, "tiltY":3.0, "distance":6400}, ... ] },
//     ...
//   ]
// }
// ============================================================

// --- 保存 ---
void saveHandwriting(String filename, ArrayList<HWStroke> strokes, String character) {
  JSONObject root = new JSONObject();
  root.setString("character", character);
  root.setInt("strokeLength", strokes.size());

  JSONArray strokesJSON = new JSONArray();
  for (HWStroke st : strokes) {
    JSONObject strokeJSON = new JSONObject();
    JSONArray pointsJSON = new JSONArray();
    for (int i = 0; i < st.size(); i++) {
      pointsJSON.append(st.get(i).toJSON());
    }
    strokeJSON.setJSONArray("points", pointsJSON);
    strokesJSON.append(strokeJSON);
  }
  root.setJSONArray("strokes", strokesJSON);

  if (!filename.endsWith(".json")) filename += ".json";
  saveJSONObject(root, filename);
  println("[HWFormat] Saved: " + filename);
}

// --- 読み込み ---
ArrayList<HWStroke> loadHandwriting(String filename) {
  ArrayList<HWStroke> strokes = new ArrayList<HWStroke>();
  JSONObject root = loadJSONObject(filename);
  if (root == null) {
    println("[HWFormat] Failed to load: " + filename);
    return strokes;
  }

  JSONArray strokesJSON = root.getJSONArray("strokes");
  for (int i = 0; i < strokesJSON.size(); i++) {
    JSONObject strokeJSON = strokesJSON.getJSONObject(i);
    JSONArray pointsJSON = strokeJSON.getJSONArray("points");
    HWStroke st = new HWStroke();
    for (int j = 0; j < pointsJSON.size(); j++) {
      st.addPoint(HWPoint.fromJSON(pointsJSON.getJSONObject(j)));
    }
    if (st.size() > 1) {
      strokes.add(st);
    }
  }
  println("[HWFormat] Loaded: " + filename + " (" + strokes.size() + " strokes)");
  return strokes;
}

// 文字名も取得する版
String getCharacterFromJSON(String filename) {
  JSONObject root = loadJSONObject(filename);
  if (root == null) return "";
  return root.getString("character", "");
}

int getStrokeLengthFromJSON(String filename) {
  JSONObject root = loadJSONObject(filename);
  if (root == null) return 0;
  return root.getInt("strokeLength", 0);
}
