// components/widgets/menu/chat/ChatView.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.config
import qs.components.reusable
import qs.components.widgets.menu
import qs.components.widgets.menu.chat
import qs.components.methods // Added for TabBar, based on reference component

StyledContainer {
  id: chatView
  
  width: 400
  height: 600
  containerColor: Theme.background
  readonly property alias wantsKeyboardFocus: chatInputBar.wantsKeyboardFocus
  
  // Properties for the TabBar, derived from the reference component and project singletons
  readonly property var backendNames: Object.keys(ChatConfig.backends)
  readonly property var tabs: backendNames.map(name => ({ "name": name.charAt(0).toUpperCase() + name.slice(1) }))
  property int currentTab: backendNames.indexOf(Chat.currentBackend)
  readonly property real tabBarHeight: 40
  readonly property int contentPadding: Widget.padding

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: contentPadding
    spacing: 0
    
    // TabBar integrated here to select the backend, as demonstrated in the reference component
    TabBar {
      Layout.fillWidth: true
      Layout.preferredHeight: chatView.tabBarHeight
      Layout.rightMargin: Widget.padding
      Layout.leftMargin: Widget.padding
      currentTab: chatView.currentTab
      activeColor: Theme.accentAlt
      tabs: chatView.tabs
      onTabClicked: index => {
        // Update the backend in the singleton. The currentTab property will update via its binding.
        Chat.currentBackend = chatView.backendNames[index];
      }
    }
    
    StyledScrollView {
      id: scrollView
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      
      StyledContainer {
        anchors.fill: parent
        containerColor: Theme.backgroundAlt
      }
      
      ListView {
        id: listView
        anchors.fill: parent
        
        model: Chat.chatModel
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
    
    MenuBottomArea {
      id: bottomArea
      Layout.fillWidth: true
      
      quickSettingsHeight: 40
      showMediaControl: true
      mediaPlaying: true
    }
  }
}
