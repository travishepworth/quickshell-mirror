pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable

RowLayout {
  id: root
  spacing: Widget.spacing

  Repeater {
    model: BarManager.localConfig

    delegate: StyledTabButton {
      required property int index
      required property var modelData

      text: modelData.id || ("Bar " + (index + 1))
      checked: BarManager.selectedBarIndex === index
      onClicked: BarManager.selectedBarIndex = index
    }
  }

  StyledRectButton {
    Layout.preferredWidth: Widget.height
    Layout.preferredHeight: Widget.height
    Layout.fillWidth: false
    Layout.fillHeight: false
    iconText: "+"
    tooltipText: "Add bar"
    hoverColor: Theme.accent
    onClicked: BarManager.addBar()
  }

  StyledRectButton {
    Layout.preferredWidth: Widget.height
    Layout.preferredHeight: Widget.height
    Layout.fillWidth: false
    Layout.fillHeight: false
    enabled: BarManager.localConfig.length > 1
    opacity: enabled ? 1 : 0.4
    iconText: "×"
    tooltipText: "Remove selected bar"
    hoverColor: Theme.error
    onClicked: BarManager.removeBar(BarManager.selectedBarIndex)
  }

  Item {
    Layout.fillWidth: true
  }
}
