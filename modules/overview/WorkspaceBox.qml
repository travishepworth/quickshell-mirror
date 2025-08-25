// modules/overview/WorkspaceBox.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/" as App
import "root:/services" as Services
import "." // WindowPreview.qml

Item {
  id: root
  property int  workspaceId: 1
  property real boxWidth: 1920
  property real boxHeight: 1080
  property real borderRadius: 12

  signal requestGoToWorkspace(int ws)
  // signal requestMoveClientToWorkspace(string address, int ws)

  Rectangle {
    anchors.fill: parent
    radius: root.borderRadius
    color: "#12141A"
    border.width: 1
    border.color: "#2A2F3A"
    opacity: 0.95

    Text {
      text: `${workspaceId}`
      font.pixelSize: 12
      color: "#B8BECC"
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.margins: 8
      opacity: 0.9
    }

    MouseArea { anchors.fill: parent; onClicked: root.requestGoToWorkspace(root.workspaceId) }

    // Content area (scaled to reference resolution for consistent aspect)
    Item {
      id: canvas
      anchors.fill: parent
      anchors.margins: 8

      readonly property real refW: App.Settings.resolutionWidth
      readonly property real refH: App.Settings.resolutionHeight

      Repeater {
        model: Hyprland.clients
        delegate: WindowPreview {
          // IMPORTANT: read roles via `model.<role>` to avoid collisions with Item.x/width etc.
          // Filter by the *client's* workspace, not the box's property
          visible: (model.workspace === root.workspaceId) && (!model.minimized)

          // Position/size scaled from reference resolution
          x:      (model.x      / canvas.refW) * canvas.width
          y:      (model.y      / canvas.refH) * canvas.height
          width:  Math.max(8, (model.width  / canvas.refW) * canvas.width)
          height: Math.max(8, (model.height / canvas.refH) * canvas.height)

          // Pass identity for thumbnail matching and DnD
          // client: {
          //   "pid":   model.pid,
          //   "class": (model._class || model.appId),
          //   "appId": model.appId,
          //   "title": model.title
          // }
          // title:   model.title
          // address: model.address
        }
      }

      // Drop target to move windows into this workspace
      DropArea {
        anchors.fill: parent
        onDropped: (event) => {
          if (event.mimeData && event.mimeData.hasText) {
            root.requestMoveClientToWorkspace(event.mimeData.text, root.workspaceId)
            event.acceptProposedAction()
          }
        }
      }
    }
  }
}

