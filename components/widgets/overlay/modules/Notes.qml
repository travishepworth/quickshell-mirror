pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay
import qs.components.widgets.overlay.modules.common

// A scratchpad, saved as you type to the state directory. Modules with the
// same `name` share one note.
// properties: { name }
OverlayCard {
  id: root

  readonly property string noteName: (root.properties.name || "notes").replace(/[^A-Za-z0-9_-]/g, "_")
  // One state file per note name (createStateHandler makes a new file
  // handle each call, so it's only called when the name changes)
  property var store: null
  function open() {
    root.store = StateManager.createStateHandler("note-" + root.noteName);
    editor.text = root.store.load({
      "text": ""
    }).text ?? "";
  }
  property bool _ready: false
  onNoteNameChanged: if (_ready)
    open()
  Component.onCompleted: {
    _ready = true;
    open();
  }

  Timer {
    id: saveSoon
    interval: 800
    onTriggered: root.store.save({
      "text": editor.text
    })
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Widget.spacing

    ModuleHeader {
      visible: !root.compact
      icon: "\u{F09ED}"
      title: root.properties.name || I18n.tr("Notes")
    }

    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      TextArea {
        id: editor
        wrapMode: TextArea.Wrap
        placeholderText: I18n.tr("Write something…")
        color: Theme.foreground
        placeholderTextColor: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.4)
        font.family: Appearance.fontFamily
        font.pixelSize: Appearance.fontSize
        selectByMouse: true
        selectionColor: Theme.accent
        selectedTextColor: Theme.background
        background: null
        onTextChanged: if (activeFocus)
          saveSoon.restart()
      }
    }
  }
}
