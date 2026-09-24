pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.content.parts
import qs.components.content.base

// Usage bar per mount point. properties: { paths: ["/", "/home"] }
Card {
  id: root

  readonly property var paths: root.properties.paths?.length > 0 ? root.properties.paths : ["/"]

  function formatSize(bytes) {
    const gib = bytes / 1073741824;
    return gib >= 1000 ? `${(gib / 1024).toFixed(1)}T` : `${Math.round(gib)}G`;
  }

  function register() {
    SystemManager.acquire(root, {
      "metrics": ["disk"],
      "diskPaths": root.paths
    });
  }
  onPathsChanged: register()
  Component.onCompleted: register()
  Component.onDestruction: SystemManager.release(root)

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Widget.spacing

    ModuleHeader {
      visible: !root.compact
      icon: "\u{F02CA}"
      title: I18n.tr("Disks")
    }

    Repeater {
      model: root.compact ? root.paths.slice(0, 1) : root.paths

      ColumnLayout {
        id: disk
        required property string modelData
        readonly property var usage: SystemManager.disks[disk.modelData] ?? null
        readonly property real ratio: disk.usage ? disk.usage.usage / 100 : 0
        Layout.fillWidth: true
        spacing: 2

        RowLayout {
          Layout.fillWidth: true
          StyledText {
            Layout.fillWidth: true
            elide: Text.ElideMiddle
            text: disk.modelData
            font.bold: true
          }
          StyledText {
            text: disk.usage ? `${root.formatSize(disk.usage.used)} / ${root.formatSize(disk.usage.total)}` : "…"
            textSize: Appearance.fontSize - 2
            opacity: 0.7
          }
        }
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: root.compact ? 6 : 8
          radius: height / 2
          color: Theme.backgroundAlt
          Rectangle {
            width: parent.width * disk.ratio
            height: parent.height
            radius: height / 2
            color: disk.ratio > 0.9 ? Theme.error : disk.ratio > 0.75 ? Theme.warning : Theme.accent
          }
        }
      }
    }

    Item {
      Layout.fillHeight: true
    }
  }
}
