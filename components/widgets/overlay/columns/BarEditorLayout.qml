pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.components.widgets.overlay.modules.barEditor

ColumnLayout {
  spacing: OverlayConfig.cardSpacing

  property int requiredVerticalCells: 2
  property int requiredHorizontalCells: 2

  Item {
    id: cell

    readonly property int requiredVerticalCells: 1
    readonly property int requiredHorizontalCells: 2

    implicitHeight: OverlayConfig.cardUnit * 2 + OverlayConfig.cardSpacing
    implicitWidth: OverlayConfig.cardUnit

    Rectangle {
      anchors.fill: parent
      color: Theme.background
      radius: Appearance.borderRadius
      border.color: Theme.border
      border.width: Appearance.borderWidth

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Widget.padding
        spacing: Widget.spacing

        Text {
          text: "Modules"
          color: Theme.foreground
          font.family: Appearance.fontFamily
          font.pixelSize: Appearance.fontSize + 4
          font.bold: true
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 1
          color: Theme.border
          opacity: 0.3
        }

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

          LayoutConfig {
            width: parent.parent.width - Widget.padding * 2
          }
        }
      }
    }
  }
}
