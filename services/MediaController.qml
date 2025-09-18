pragma Singleton
import QtQuick

QtObject {
  property var panelWindow: null

  function toggle() {
    if (panelWindow)
      panelWindow.visible = !panelWindow.visible;
  }
  function open() {
    if (panelWindow)
      panelWindow.visible = true;
  }
  function close() {
    if (panelWindow)
      panelWindow.visible = false;
  }
}
