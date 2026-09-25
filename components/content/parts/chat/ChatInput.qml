import QtQuick
import QtQuick.Layouts
import QtQuick.Controls // Added for TextInput.Wrap enum

import Quickshell.Wayland

import qs.services
import qs.config
import qs.components.reusable

RowLayout {
  id: root
  width: parent.width
  spacing: Widget.padding

  property bool wantsKeyboardFocus: textEntry.wantsKeyboardFocus
  property int desiredButtonHeight: 0

  Component.onCompleted: {
    desiredButtonHeight = textEntry.height;
  }

  StyledTextArea {
    id: textEntry
    expandable: true
    Layout.fillWidth: true
    placeholderText: I18n.tr("Type a message or use / for commands...")
    onAccepted: root.submit()
    onTextChanged: {
      ChatManager.updateCommandState(text);
    }
    Component.onCompleted: {
      root.wantsKeyboardFocus = true;
    }
  }

  StyledTextButton {
    id: submitButton
    iconText: "send"

    Layout.preferredHeight: root.desiredButtonHeight
    Layout.preferredWidth: root.desiredButtonHeight
    Layout.alignment: Qt.AlignBottom

    enabled: !ChatManager.waitingForResponse && textEntry.text.trim().length > 0
    opacity: enabled ? 1.0 : 0.5
    onClicked: root.submit()

    Behavior on opacity {
      OpacityAnimator {
        duration: Appearance.animNormal
      }
    }
  }

  function focus() {
    root.wantsKeyboardFocus = true;
    textEntry.forceActiveFocus();
  }

  function submit() {
    if (!submitButton.enabled)
      return;
    ChatManager.sendMessage(textEntry.text);
    textEntry.text = "";
    textEntry.input.forceActiveFocus();
  }
}
