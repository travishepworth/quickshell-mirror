pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.components.content.parts.chat
import qs.components.content.base

// The AI chat (same conversation and backends as the menu's chat)
Card {
  id: root

  ChatView {
    anchors.fill: parent
    anchors.margins: root.border.width
    backgroundColor: "transparent"
  }
}
