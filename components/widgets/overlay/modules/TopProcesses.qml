pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay
import qs.components.widgets.overlay.modules.common

// The busiest processes, with a kill button on hover.
// properties: { count, sortBy: "cpu" | "mem" }
OverlayCard {
  id: root

  readonly property string sortBy: root.properties.sortBy ?? "cpu"
  readonly property real rowHeight: Widget.height
  // As many as asked for, and as fit
  readonly property int fitting: Math.max(1, Math.floor((list.height + Widget.spacing / 2) / (root.rowHeight + Widget.spacing / 2)))
  readonly property var rows: SystemManager.processes.slice().sort((a, b) => b[root.sortBy] - a[root.sortBy]).slice(0, Math.min(root.properties.count ?? 8, root.fitting))

  Component.onCompleted: SystemManager.acquire(root, {
    "metrics": ["processes"],
    "interval": 3000
  })
  Component.onDestruction: SystemManager.release(root)

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Widget.spacing

    ModuleHeader {
      visible: !root.compact
      icon: "\u{F0A30}"
      title: I18n.tr("Processes")
      StyledText {
        text: I18n.tr(root.sortBy === "cpu" ? "by CPU" : "by memory")
        textSize: Appearance.fontSize - 2
        opacity: 0.6
      }
    }

    Item {
      id: list
      Layout.fillWidth: true
      Layout.fillHeight: true

      Column {
        width: parent.width
        spacing: Widget.spacing / 2

        // Modelled by count: the rows are a new array every sample, which
        // would recreate the delegates (and drop the hover) each time
        Repeater {
          model: root.rows.length

          Rectangle {
            id: row
            required property int index
            readonly property var proc: root.rows[index] ?? ({
                "command": "",
                "cpu": 0,
                "mem": 0,
                "pid": 0
              })
            width: parent.width
            height: root.rowHeight
            radius: Appearance.borderRadius
            color: rowHover.hovered ? Theme.backgroundHighlight : "transparent"

            HoverHandler {
              id: rowHover
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Widget.spacing
              anchors.rightMargin: Widget.spacing / 2
              spacing: Widget.spacing

              StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: row.proc.command
              }
              StyledText {
                visible: !root.compact
                text: `${row.proc.cpu.toFixed(1)}%`
                textColor: root.sortBy === "cpu" ? Theme.accent : Theme.foreground
                textSize: Appearance.fontSize - 1
              }
              StyledText {
                visible: !root.compact
                text: `${row.proc.mem.toFixed(1)}%`
                textColor: root.sortBy === "mem" ? Theme.accent : Theme.foreground
                textSize: Appearance.fontSize - 1
                opacity: 0.8
              }
              StyledText {
                visible: rowHover.hovered
                text: "\u{F0156}"
                textColor: Theme.error
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: SystemManager.kill(row.proc.pid)
                }
              }
            }
          }
        }
      }
    }
  }
}
