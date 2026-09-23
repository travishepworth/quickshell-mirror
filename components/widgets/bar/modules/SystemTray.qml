// SystemTray.qml - Fixed icon rendering
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.config
import qs.components.widgets.bar.popouts

Item {
  id: tray

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  property bool isVertical: barConfig.vertical
  property int iconSize: 18
  property int leftPadding: 8
  property int rightPadding: 8
  property int topPadding: 4
  property int bottomPadding: 4
  property int spacing: 6
  property bool showPassive: true
  property color backgroundColor: Theme.backgroundAlt
  property int backgroundRadius: Appearance.borderRadius
  property color backgroundBorderColor: "transparent"
  property real backgroundBorderWidth: 0

  implicitWidth: isVertical ? Widget.height : (layoutLoader.item ? layoutLoader.item.implicitWidth + leftPadding + rightPadding : 0)
  implicitHeight: isVertical ? (layoutLoader.item ? layoutLoader.item.implicitHeight + topPadding + bottomPadding : 0) : Widget.height

  Rectangle {
    anchors.fill: parent
    radius: tray.backgroundRadius
    color: tray.backgroundColor
  }

  Loader {
    id: layoutLoader
    anchors.centerIn: parent
    sourceComponent: isVertical ? columnComponent : rowComponent

    Component {
      id: rowComponent
      Row {
        spacing: tray.spacing
        leftPadding: tray.leftPadding
        rightPadding: tray.rightPadding

        Repeater {
          model: SystemTray.items
          delegate: trayItemDelegate
        }
      }
    }

    Component {
      id: columnComponent
      Column {
        spacing: tray.spacing
        topPadding: tray.topPadding
        bottomPadding: tray.bottomPadding

        Repeater {
          model: SystemTray.items
          delegate: trayItemDelegate
        }
      }
    }
  }

  Component {
    id: trayItemDelegate

    Item {
      id: delegateRoot
      required property QtObject modelData
      readonly property QtObject ti: modelData
      visible: ti && (tray.showPassive || ti.status !== Status.Passive)
      width: visible ? tray.iconSize : 0
      height: visible ? tray.iconSize : 0

      Image {
        id: iconImage
        anchors.centerIn: parent
        source: {
          if (!delegateRoot.ti)
            return "";
          const appName = delegateRoot.ti.id || delegateRoot.ti.title || "";
          if (appName && IconConfig.overrides[appName]) {
            return IconConfig.overrides[appName];
          }
          return delegateRoot.ti.icon || "";
        }
        sourceSize.width: tray.iconSize
        sourceSize.height: tray.iconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
      }

      PopoutAnchor {
        id: anchor
        popouts: tray.popouts
        panel: tray.panel
        popoutName: "system-tray-menu"
        openDelay: 150
        active: !!(delegateRoot.ti && delegateRoot.ti.hasMenu)
        extraData: ({
          trayItem: delegateRoot.ti,
          barConfig: tray.barConfig,
          isVertical: tray.isVertical
        })
      }
    }
  }
}
