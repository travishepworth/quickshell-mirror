import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable

RowLayout {
  id: root
  width: parent.width

  property string role: "user"
  property string content: "..."

  property string messageBackend: ""

  readonly property bool isUser: role === "user"
  readonly property bool isConfig: role === "config"

  readonly property string senderIcon: isUser ? "" : isConfig ? "󰍛" : "󱚤"
  readonly property color senderIconColor: isUser ? Theme.userColor : isConfig ? Theme.accent : Theme.robotColor
  readonly property string senderName: isUser ? General.displayName : isConfig ? "system" : messageBackend
  readonly property color senderColor: isUser ? Theme.userColor : isConfig ? Theme.accent : Theme.robotColor

  // 2. When the component is created, capture the current backend name
  Component.onCompleted: {
    if (!isUser && !isConfig) {
      messageBackend = ChatManager.currentBackend;
    }
  }

  ColumnLayout {
    Layout.alignment: isUser ? Qt.AlignRight : Qt.AlignLeft
    Layout.maximumWidth: root.width * 0.75
    Layout.leftMargin: 10
    Layout.rightMargin: 10

    spacing: 6

    RowLayout {
      spacing: 8
      Layout.alignment: isUser ? Qt.AlignRight : Qt.AlignLeft

      StyledText {
        text: root.senderIcon
        textSize: Appearance.fontSizeLarge
        color: root.senderIconColor
        Layout.alignment: Qt.AlignVCenter
      }

      StyledText {
        text: root.senderName
        textColor: root.senderColor
        textSize: Appearance.fontSizeLarge
        font.bold: true
        Layout.alignment: Qt.AlignVCenter
      }
    }

    Rectangle {
      color: isUser ? Theme.info : Theme.backgroundHighlight
      radius: Appearance.borderRadius
      // Layout.fillWidth: true
      Layout.alignment: isUser ? Qt.AlignRight : Qt.AlignLeft
      Layout.preferredWidth: contentText.implicitWidth + 20
      Layout.maximumWidth: root.width * 0.75
      implicitHeight: contentText.implicitHeight + 20

      StyledText {
        id: contentText
        text: root.content
        wrapMode: Text.WordWrap
        color: isUser ? Theme.background : Theme.foreground
        font.pixelSize: Appearance.fontSize

        anchors.fill: parent
        anchors.margins: 10
      }
    }
  }
}
