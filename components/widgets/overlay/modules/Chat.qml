pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.components.widgets.overlay
import qs.components.widgets.menu.chat

// The AI chat (same conversation and backends as the menu's chat)
OverlayCard {
  id: root

  ChatView {
    anchors.fill: parent
    anchors.margins: root.border.width
    backgroundColor: "transparent"
  }
}
