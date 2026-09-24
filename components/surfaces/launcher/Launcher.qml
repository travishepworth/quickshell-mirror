pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

import qs.components.reusable
import qs.config
import qs.services

// The search launcher. LauncherManager builds the rows from the text and
// runs them; this is the window, the search field and the list.
PanelWindow {
  id: root

  required property var screen

  property bool shown: false
  // The row kept selected when the rows are rebuilt for the same text
  property int selected: 0

  function open(text) {
    input.text = text ?? "";
    input.cursorPosition = input.text.length;
    LauncherManager.query(input.text);
    root.selected = 0;
    list.currentIndex = 0;
    root.shown = true;
    input.forceActiveFocus();
  }

  function close() {
    root.shown = false;
  }

  function toggle() {
    if (root.shown)
      close();
    else
      open("");
  }

  function select(index) {
    if (list.count === 0)
      return;
    root.selected = (index + list.count) % list.count;
    list.currentIndex = root.selected;
  }

  function activate(shift) {
    const result = LauncherManager.activate(list.currentIndex, shift);
    if (typeof result === "string") {
      input.text = result;
      input.cursorPosition = result.length;
    } else if (result === true) {
      close();
    }
  }

  function complete() {
    const text = LauncherManager.completion(list.currentIndex);
    if (text !== "") {
      input.text = text;
      input.cursorPosition = text.length;
    }
  }

  Connections {
    target: ShellManager
    enabled: ShellManager.isTarget(root.screen)
    function onToggleAppLauncher() {
      root.toggle();
    }
  }

  // Locking from anywhere closes it, so it isn't still up on unlock
  Connections {
    target: LockManager
    function onLockStarted() {
      root.close();
    }
  }

  IpcHandler {
    target: "appLauncher"
    enabled: ShellManager.isTarget(root.screen)

    function toggle(): void {
      root.toggle();
    }
    // Not "show": `qs ipc call <target> show` is taken by the CLI
    function open(): void {
      if (!root.shown)
        root.open("");
    }
    function close(): void {
      root.close();
    }
    // Opens with `text` searched, e.g. "/theme " or "="
    function search(text: string): void {
      root.open(text);
    }
  }

  screen: root.screen
  anchors {
    left: true
    right: true
    top: true
    bottom: true
  }
  color: "transparent"
  focusable: true
  // Stays mapped while the card fades out
  visible: shown || card.opacity > 0

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "axiom-launcher"

  HyprlandFocusGrab {
    active: root.shown
    windows: [root]
    onCleared: root.close()
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, LauncherConfig.backdrop)
    opacity: root.shown ? 1 : 0
    Behavior on opacity {
      NumberAnimation {
        duration: Appearance.animNormal
      }
    }
    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }
  }

  Rectangle {
    id: card

    readonly property int rowHeight: Math.max(LauncherConfig.iconSize + 14, LauncherConfig.showDescriptions ? Appearance.fontSize * 2 + 24 : Appearance.fontSize + 22)
    // The tallest the card gets, so a centred card doesn't move as rows come and go
    readonly property int maxHeight: searchRow.height + rowHeight * LauncherConfig.maxResults + 80

    width: Math.min(LauncherConfig.width, root.width - 32)
    height: column.implicitHeight
    x: (root.width - width) / 2
    y: LauncherConfig.position === "center" ? Math.max(16, (root.height - maxHeight) / 2) : LauncherConfig.position === "top" ? root.height * 0.06 : root.height * 0.18
    color: Theme.background
    border.color: Theme.border
    border.width: Appearance.borderWidth
    radius: Appearance.borderRadius
    clip: true

    opacity: root.shown ? 1 : 0
    scale: root.shown ? 1 : 0.97
    transformOrigin: Item.Top
    Behavior on opacity {
      NumberAnimation {
        duration: Appearance.animNormal
        easing.type: Appearance.easing
      }
    }
    Behavior on scale {
      NumberAnimation {
        duration: Appearance.animNormal
        easing.type: Appearance.easing
      }
    }
    Behavior on height {
      NumberAnimation {
        duration: Appearance.animFast
        easing.type: Appearance.easing
      }
    }

    // Swallow clicks so they don't reach the backdrop
    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: column
      width: parent.width
      spacing: 0

      // --- Search field ---
      RowLayout {
        id: searchRow
        Layout.fillWidth: true
        Layout.preferredHeight: Appearance.fontSizeLarge + 36
        Layout.leftMargin: 20
        Layout.rightMargin: 16
        spacing: 12

        StyledText {
          readonly property var glyphs: ({
              apps: "\u{F0349}",
              commands: "\u{F0493}",
              calc: "\u{F00EC}",
              run: "\u{F018D}",
              web: "\u{F059F}"
            })
          text: glyphs[LauncherManager.mode] ?? glyphs.apps
          textColor: Theme.accent
          textSize: Appearance.fontSizeLarge + 2
        }

        TextField {
          id: input
          Layout.fillWidth: true
          color: Theme.foreground
          font.family: Appearance.fontFamily
          font.pixelSize: Appearance.fontSizeLarge
          selectByMouse: true
          selectedTextColor: Theme.background
          selectionColor: Theme.accent
          placeholderText: LauncherConfig.commands ? I18n.tr("Search apps, or type / for commands") : I18n.tr("Search apps")
          placeholderTextColor: Theme.foregroundInactive
          background: null
          padding: 0

          onTextChanged: {
            root.selected = 0;
            LauncherManager.query(text);
          }

          Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
              root.close();
            } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
              root.select(list.currentIndex + 1);
            } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
              root.select(list.currentIndex - 1);
            } else if (event.key === Qt.Key_PageDown) {
              root.select(Math.min(list.count - 1, list.currentIndex + LauncherConfig.maxResults));
            } else if (event.key === Qt.Key_PageUp) {
              root.select(Math.max(0, list.currentIndex - LauncherConfig.maxResults));
            } else if (event.key === Qt.Key_Tab) {
              root.complete();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.activate(event.modifiers & Qt.ShiftModifier);
            } else {
              return;
            }
            event.accepted = true;
          }

          cursorDelegate: Rectangle {
            width: 2
            color: Theme.accent
            visible: input.activeFocus
            SequentialAnimation on opacity {
              loops: Animation.Infinite
              running: input.activeFocus && root.shown
              // Cursor blink: a behaviour timing, not motion, so not scaled
              PropertyAnimation {
                to: 1
                duration: 500
              }
              PropertyAnimation {
                to: 0
                duration: 500
              }
            }
          }
        }

        // The mode, when it isn't a plain search
        Rectangle {
          readonly property var labels: ({
              commands: I18n.tr("Commands"),
              calc: I18n.tr("Calculator"),
              run: I18n.tr("Run"),
              web: I18n.tr("Web")
            })
          visible: LauncherManager.mode !== "apps"
          implicitWidth: modeLabel.implicitWidth + 16
          implicitHeight: modeLabel.implicitHeight + 8
          radius: Appearance.borderRadius
          color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)

          StyledText {
            id: modeLabel
            anchors.centerIn: parent
            text: parent.labels[LauncherManager.mode] ?? ""
            textColor: Theme.accent
            textSize: Appearance.fontSize - 2
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Appearance.borderWidth
        visible: list.count > 0 || empty.visible
        color: Theme.border
      }

      StyledText {
        Layout.leftMargin: 22
        Layout.topMargin: 10
        visible: LauncherManager.frequent && list.count > 0
        text: I18n.tr("Frequent")
        textColor: Theme.foregroundInactive
        textSize: Appearance.fontSize - 3
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
      }

      StyledText {
        id: empty
        Layout.fillWidth: true
        Layout.margins: 18
        visible: list.count === 0 && input.text.trim() !== ""
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr("No results")
        textColor: Theme.foregroundInactive
      }

      // --- Results ---
      ListView {
        id: list
        Layout.fillWidth: true
        Layout.topMargin: count > 0 ? 6 : 0
        Layout.bottomMargin: count > 0 ? 6 : 0
        Layout.preferredHeight: Math.min(count, LauncherConfig.maxResults) * card.rowHeight
        clip: true
        interactive: count > LauncherConfig.maxResults
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Appearance.animFast
        highlightFollowsCurrentItem: true
        currentIndex: 0
        model: LauncherManager.results
        // A rebuild for the same text (a command that keeps the launcher
        // open) keeps the selection
        onModelChanged: currentIndex = Math.max(0, Math.min(root.selected, count - 1))

        delegate: LauncherRow {
          width: ListView.view.width
          height: card.rowHeight
          current: ListView.isCurrentItem
          onHovered: {
            root.selected = index;
            list.currentIndex = index;
          }
          onClicked: {
            list.currentIndex = index;
            root.activate(false);
          }
        }
      }

      // --- Controls hint ---
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Appearance.borderWidth
        visible: LauncherConfig.showHint
        color: Theme.border
      }

      Flow {
        Layout.fillWidth: true
        Layout.margins: 10
        Layout.leftMargin: 18
        Layout.rightMargin: 18
        visible: LauncherConfig.showHint
        spacing: 14

        Repeater {
          // I18n.tr("commands") I18n.tr("calculate") I18n.tr("run") I18n.tr("web")
          // I18n.tr("complete") I18n.tr("open")
          model: [[LauncherConfig.commands, "/", "commands"], [LauncherConfig.calculator, "=", "calculate"], [LauncherConfig.runCommands, ">", "run"], [LauncherConfig.webSearch, "?", "web"], [true, "Tab", "complete"], [true, "↵", "open"]].filter(hint => hint[0])

          Row {
            id: hintItem
            required property var modelData
            spacing: 5

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              width: Math.max(height, key.implicitWidth + 8)
              height: key.implicitHeight + 4
              radius: Appearance.borderRadius / 2
              color: Theme.backgroundAlt
              border.color: Theme.border
              border.width: 1

              StyledText {
                id: key
                anchors.centerIn: parent
                text: hintItem.modelData[1]
                textColor: Theme.foregroundAlt
                textSize: Appearance.fontSize - 4
              }
            }

            StyledText {
              anchors.verticalCenter: parent.verticalCenter
              text: I18n.tr(hintItem.modelData[2])
              textColor: Theme.foregroundInactive
              textSize: Appearance.fontSize - 3
            }
          }
        }
      }
    }
  }
}
