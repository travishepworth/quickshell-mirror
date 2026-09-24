pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

Item {
  id: root
  property var screen
  // This view's entry in Overlay.views
  property var viewConfig
  default property alias content: rowLayout.data

  implicitWidth: rowLayout.implicitWidth
  implicitHeight: rowLayout.implicitHeight

  RowLayout {
    id: rowLayout
    spacing: OverlayConfig.cardSpacing
  }
}
