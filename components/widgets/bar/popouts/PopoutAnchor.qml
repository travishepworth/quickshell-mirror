pragma ComponentBehavior: Bound
import QtQuick

/**
 * Drop this into any bar widget that wants to open a bar popout on hover.
 * Handles hover detection, open-delay timing, position/size computation,
 * and the popoutOpen guard flag.
 *
 * Usage:
 *   PopoutAnchor {
 *     id: anchor
 *     popouts: root.popouts
 *     panel: root.panel
 *     popoutName: "workspace-grid"
 *     extraData: ({ monitor: root.monitor, workspaceBase: root.workspaceBase })
 *   }
 *
 * The content-type name travels as a `name` field inside the payload
 * (not a separate argument) so Popout.qml's open/close/queue logic can
 * stay fully generic — see PopoutWrapperBase.qml.
 */
Item {
  id: root

  required property var popouts
  required property var panel
  required property string popoutName

  property var extraData: ({})
  property int openDelay: 10
  property bool active: true

  property alias hovered: hoverHandler.hovered
  property bool popoutOpen: false

  anchors.fill: parent

  function open() {
    if (!root.active || !root.popouts || !root.panel || root.popoutOpen)
      return;

    let parentPosition = root.mapToItem(null, 0, 0);
    root.popoutOpen = true;

    let payload = {
      name: root.popoutName,
      anchorX: parentPosition.x,
      anchorY: parentPosition.y,
      anchorWidth: root.width,
      anchorHeight: root.height,
      anchorItem: root
    };

    for (let key in root.extraData) {
      payload[key] = root.extraData[key];
    }

    root.popouts.safeOpenPopout(root.panel, payload);
  }

  HoverHandler {
    id: hoverHandler
    onHoveredChanged: {
      if (hovered && root.active) {
        if (root.popouts)
          openTimer.restart();
      } else {
        openTimer.stop();
      }
    }
  }

  Timer {
    id: openTimer
    interval: root.openDelay
    repeat: false
    onTriggered: {
      if (hoverHandler.hovered && root.active)
        root.open();
    }
  }
}
