pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay

// App launcher buttons. `apps` lists desktop entry ids (e.g. firefox,
// kitty); left empty, it shows the most recently launched apps.
// properties: { apps: [...], showLabels }
OverlayCard {
  id: root

  readonly property int capacity: Math.max(1, root.cols * root.rows * 2)
  readonly property var ids: {
    const configured = root.properties.apps ?? [];
    if (configured.length > 0)
      return configured;
    const times = LauncherManager.launchTimes ?? {};
    return Object.keys(times).sort((a, b) => times[b] - times[a]).slice(0, root.capacity);
  }
  readonly property var entries: root.ids.map(id => DesktopEntries.heuristicLookup(id)).filter(e => e)
  readonly property int columns: Math.max(1, Math.round(Math.sqrt(root.entries.length * Math.max(0.25, width / Math.max(1, height)))))

  StyledText {
    anchors.centerIn: parent
    visible: root.entries.length === 0
    width: parent.width - root.pad * 2
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    text: "Add apps in this module's settings"
    opacity: 0.6
  }

  GridLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    columns: root.columns
    columnSpacing: Widget.spacing / 2
    rowSpacing: Widget.spacing / 2

    Repeater {
      model: root.entries

      Rectangle {
        id: app
        required property var modelData
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Appearance.borderRadius
        color: appArea.containsMouse ? Theme.backgroundHighlight : "transparent"

        ColumnLayout {
          anchors.centerIn: parent
          width: parent.width - 4
          spacing: 2
          Image {
            readonly property real side: Math.min(app.width, app.height) * ((root.properties.showLabels ?? true) && app.height > 70 ? 0.55 : 0.7)
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: side
            Layout.preferredHeight: side
            sourceSize: Qt.size(128, 128)
            source: Quickshell.iconPath(app.modelData.icon, "application-x-executable")
          }
          StyledText {
            visible: (root.properties.showLabels ?? true) && app.height > 70
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: app.modelData.name
            textSize: Appearance.fontSize - 3
          }
        }

        MouseArea {
          id: appArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            LauncherManager.launchApp(app.modelData);
            ShellManager.toggleOverlay();
          }
        }
      }
    }
  }
}
