import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.config
import qs.components.reusable

StyledContainer {
  id: chatView

  width: 400
  height: 600
  backgroundColor: Theme.background
  readonly property alias wantsKeyboardFocus: chatInputBar.wantsKeyboardFocus

  readonly property var backendNames: Object.keys(ChatConfig.backends)
  readonly property var tabs: backendNames.map(name => ({
        "name": name.charAt(0).toUpperCase() + name.slice(1)
      }))
  property int currentTab: backendNames.indexOf(ChatManager.currentBackend)
  readonly property real tabBarHeight: 40
  readonly property int contentPadding: Widget.padding

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: contentPadding
    spacing: 0

    TabBar {
      Layout.fillWidth: true
      Layout.preferredHeight: chatView.tabBarHeight
      // Layout.rightMargin: Widget.padding
      // Layout.leftMargin: Widget.padding
      currentTab: chatView.currentTab
      activeColor: Theme.accentAlt
      tabs: chatView.tabs
      onTabClicked: index => {
        ChatManager.currentBackend = chatView.backendNames[index];
      }
    }

    StyledScrollView {
      id: scrollView
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      StyledContainer {
        anchors.fill: parent
        backgroundColor: Theme.backgroundAlt
      }

      ListView {
        id: listView
        anchors.fill: parent

        model: ChatManager.chatModel
        delegate: ChatMessage {
          role: model.role
          content: model.content
        }
        spacing: contentPadding
      }
    }

    ChatInput {
      id: chatInputBar
      Layout.fillWidth: true
      Layout.topMargin: contentPadding
      Layout.bottomMargin: Widget.padding
    }
  }
}
