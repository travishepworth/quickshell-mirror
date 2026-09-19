pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components.widgets.bar

// Dedicated column for the Bar Editor's live sandbox preview - reflects
// BarManager.localConfig only. The real running bar(s) and config.json are
// untouched until Save. Renders the bar scaled down uniformly (both
// thickness and length) to match how it would actually look against the
// real screen, rather than stretching only its length to fill the column
// while leaving its thickness at real/unscaled size. The column sizes
// itself to exactly the (scaled) bar thickness plus padding - no box, no
// minimum width.
Item {
  id: root

  readonly property var previewConfig: BarManager.selectedBar() ? Bar.enrichBarConfig(BarManager.selectedBar()) : null
  readonly property var previewScreen: Quickshell.screens[0] ?? null
  readonly property real screenWidth: previewScreen && previewScreen.width > 0 ? previewScreen.width : 1920
  readonly property real screenHeight: previewScreen && previewScreen.height > 0 ? previewScreen.height : 1080

  // The length axis (height for a vertical bar, width for a horizontal one)
  // is whatever the surrounding layout gives this column via fillHeight/
  // fillWidth. Scale the whole bar so that axis matches the real screen's
  // corresponding dimension, keeping thickness proportional to length.
  readonly property real availableLength: previewConfig ? (previewConfig.vertical ? root.height : root.width) : 0
  readonly property real realLength: previewConfig ? (previewConfig.vertical ? screenHeight : screenWidth) : 1
  readonly property real scaleFactor: availableLength > 0 ? availableLength / realLength : 1

  implicitWidth: (previewConfig && previewConfig.vertical) ? previewConfig.extent * scaleFactor + Widget.padding * 2 : 0
  implicitHeight: (previewConfig && !previewConfig.vertical) ? previewConfig.extent * scaleFactor + Widget.padding * 2 : 0

  Loader {
    active: root.previewConfig !== null
    anchors.centerIn: parent
    sourceComponent: StandaloneBar {
      barConfig: root.previewConfig
      screen: root.previewScreen
      panel: null
      popouts: null
      implicitWidth: barConfig.vertical ? barConfig.extent : root.screenWidth
      implicitHeight: barConfig.vertical ? root.screenHeight : barConfig.extent
      scale: root.scaleFactor
    }
  }
}
