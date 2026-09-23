pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.config
import qs.components.reusable

// Shared "pick a module type to add" popup, reused by every zone in
// LayoutConfig.qml. The caller tracks which zone it opened this for.
Popup {
  id: root

  signal typeSelected(string type)

  width: 220
  padding: 0

  background: StyledContainer {
    backgroundColor: Theme.background
    borderColor: Theme.border

    layer.enabled: true
    layer.effect: DropShadow {
      transparentBorder: true
      horizontalOffset: 0
      verticalOffset: 2
      radius: 8
      samples: 17
      color: "#40000000"
    }
  }

  contentItem: ListView {
    implicitHeight: Math.min(contentHeight, 320)
    clip: true
    model: Bar.availableWidgetTypes

    ScrollIndicator.vertical: ScrollIndicator {}

    delegate: Rectangle {
      id: rowDelegate
      required property var modelData

      width: ListView.view.width
      height: Widget.height
      color: rowArea.containsMouse ? Theme.backgroundHighlight : "transparent"

      StyledText {
        anchors.fill: parent
        anchors.leftMargin: Widget.padding
        anchors.rightMargin: Widget.padding
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        text: rowDelegate.modelData.label
      }

      MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.typeSelected(rowDelegate.modelData.type);
          root.close();
        }
      }
    }
  }
}
