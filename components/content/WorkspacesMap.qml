pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components.methods
import qs.components.reusable
import qs.components.content.parts
import qs.components.content.base

// Workspaces as tiles with their windows' app icons; click one to go there.
// properties: { count: number of workspaces shown, showEmpty }
Card {
  id: root

  readonly property int count: root.properties.count ?? 10
  readonly property int activeId: HyprlandManager.activeWorkspace?.id ?? -1
  // A string, so the tiles are only rebuilt when the set of workspaces
  // shown changes, not on every window event
  readonly property string _idsKey: {
    const ids = [];
    for (let i = 1; i <= root.count; i++)
      ids.push(i);
    if (root.properties.showEmpty === false)
      return ids.filter(id => HyprlandManager.windowList.some(w => w.workspace?.id === id) || id === root.activeId).join(",");
    return ids.join(",");
  }
  readonly property var ids: root._idsKey === "" ? [] : root._idsKey.split(",").map(Number)
  TileGrid {
    id: grid
    anchors.fill: parent
    anchors.margins: root.pad
    count: root.ids.length
    spacing: Widget.spacing / 2
    // Screen-shaped tiles
    maxAspect: 1.8

    Repeater {
      model: root.ids

      Rectangle {
        id: tile
        required property int modelData
        required property int index
        readonly property bool active: tile.modelData === root.activeId
        readonly property var windows: HyprlandManager.windowList.filter(w => w.workspace?.id === tile.modelData)

        x: grid.tileX(index)
        y: grid.tileY(index)
        width: grid.tileWidth
        height: grid.tileHeight
        radius: Appearance.borderRadius
        color: tile.active ? Theme.accent : tileArea.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt
        border.color: tile.active ? Theme.accent : Theme.border
        border.width: Appearance.borderWidth

        StyledText {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.margins: 4
          text: tile.modelData
          textSize: Appearance.fontSize - 3
          textColor: tile.active ? Theme.background : Theme.foreground
          opacity: 0.7
        }

        Flow {
          anchors.centerIn: parent
          width: parent.width - 8
          spacing: 2
          readonly property real iconSize: Math.max(12, Math.min(parent.height * 0.4, (parent.width - 8) / Math.max(1, Math.min(tile.windows.length, 3)) - 2))

          Repeater {
            model: Math.min(tile.windows.length, 6)
            Image {
              required property int index
              readonly property var window: tile.windows[index]
              width: parent.iconSize
              height: parent.iconSize
              sourceSize: Qt.size(64, 64)
              source: window ? IconResolver.resolveWindowIcon(window.class, window.title) : ""
            }
          }
        }

        MouseArea {
          id: tileArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: HyprlandManager.gotoWorkspace(tile.modelData)
        }
      }
    }
  }
}
