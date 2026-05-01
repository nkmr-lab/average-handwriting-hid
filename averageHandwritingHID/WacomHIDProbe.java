// ============================================================
// WacomHIDProbe.java — HidDevice の open/close を扱うヘルパー
// ============================================================
// .pde ファイルは Processing の preprocessor を通るため、
// hid4java の HidDevice.open() を直接呼ぶと Syntax error になる。
// .java ファイルは preprocessor を通らないので問題なく書ける。
//
// このファイルではインターフェース切り替えに必要な
// open / close / 候補列挙だけを扱う。
// ============================================================

import org.hid4java.HidDevice;
import org.hid4java.HidServices;
import java.util.ArrayList;
import java.util.List;

public class WacomHIDProbe {

  // VID/PID マッチする全候補インターフェースを返す
  public static List<HidDevice> findCandidates(HidServices hs, int vendorId, int productId) {
    List<HidDevice> result = new ArrayList<HidDevice>();
    if (hs == null) return result;
    for (HidDevice d : hs.getAttachedHidDevices()) {
      if (d.getVendorId() == vendorId && d.getProductId() == productId) {
        result.add(d);
      }
    }
    return result;
  }

  // open を試みる。成功したら true。
  public static boolean openDevice(HidDevice d) {
    if (d == null) return false;
    try {
      return d.open();
    } catch (Exception e) {
      System.out.println("[WacomHIDProbe] open() failed: " + e.getMessage());
      return false;
    }
  }

  // close を試みる (例外は飲み込む)
  public static void closeDevice(HidDevice d) {
    if (d == null) return;
    try {
      d.close();
    } catch (Exception e) {
      // ignore
    }
  }

  // 候補リスト中で指定 path を持つもののインデックスを返す (見つからなければ -1)
  public static int indexOfPath(List<HidDevice> candidates, String path) {
    if (candidates == null || path == null) return -1;
    for (int i = 0; i < candidates.size(); i++) {
      String p = candidates.get(i).getPath();
      if (path.equals(p)) return i;
    }
    return -1;
  }
}
