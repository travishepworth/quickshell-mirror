// KeybindSection.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.widgets.common

Rectangle {
  id: root
  required property var keybinds
  color: Theme.background
  Layout.fillHeight: true
  Layout.preferredWidth: OverlayConfig.cardUnit
  border.color: Theme.border
  border.width: Appearance.borderWidth

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: OverlayConfig.cardPadding
    spacing: OverlayConfig.cardSpacing
    SchemaSection {
      title: "Workspace Management"
      expanded: true
      Layout.leftMargin: Widget.padding
      Layout.rightMargin: Widget.padding
      
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        
        Repeater {
          model: root.keybinds.WORKSPACE
          
          KeybindPreview {
            required property var modelData
            keybind: modelData
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}

