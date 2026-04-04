// ============================================================
// DragAndDrop.pde — ファイルドロップで JSON を読み込む
// ============================================================

import java.awt.datatransfer.*;
import java.awt.dnd.*;
import java.awt.Component;
import javax.swing.*;
import java.io.File;
import java.io.IOException;
import java.util.List;

DropTarget dropTarget;

void initFileDrop() {
  java.awt.Canvas awtCanvas = (java.awt.Canvas) surface.getNative();
  JLayeredPane pane = (JLayeredPane) awtCanvas.getParent().getParent();

  dropTarget = new DropTarget(pane, new DropTargetListener() {
    public void dragEnter(DropTargetDragEvent dtde) {}
    public void dragOver(DropTargetDragEvent dtde) {}
    public void dropActionChanged(DropTargetDragEvent dtde) {}
    public void dragExit(DropTargetEvent dte) {}

    public void drop(DropTargetDropEvent dtde) {
      dtde.acceptDrop(DnDConstants.ACTION_COPY_OR_MOVE);
      Transferable trans = dtde.getTransferable();
      List<File> files = null;
      if (trans.isDataFlavorSupported(DataFlavor.javaFileListFlavor)) {
        try {
          files = (List<File>) trans.getTransferData(DataFlavor.javaFileListFlavor);
        } catch (UnsupportedFlavorException | IOException e) {
          e.printStackTrace();
        }
      }
      if (files == null) return;
      for (File f : files) {
        onFileDrop(f.getAbsolutePath());
      }
    }
  });
}
