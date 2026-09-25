pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable

// The Hyprland category's first card (the section's `x-card`): whether
// the chosen mode is in effect, what it needs from the user, and which
// binds didn't make it
StyledContainer {
  id: root

  readonly property string mode: HyprlandConfigManager.mode
  readonly property string status: HyprlandConfigManager.status

  // Keys bound more than once among axiom's own binds
  readonly property var duplicateKeys: {
    const seen = {};
    const result = [];
    for (const bind of HyprlandConfig.binds) {
      const id = HyprlandConfigManager.keyId(bind.key);
      if (id === "")
        continue;
      if (seen[id] && !result.includes(seen[id]))
        result.push(seen[id]);
      seen[id] = seen[id] ?? bind.key.trim();
    }
    return result;
  }

  readonly property color statusColor: {
    switch (root.status) {
    case "loaded":
    case "runtime":
      return Theme.success;
    case "fallback":
      return Theme.warning;
    }
    return Theme.foregroundAlt;
  }

  // I18n.tr("Detached") I18n.tr("Included") I18n.tr("Managed")
  readonly property string modeLabel: I18n.tr(root.mode.charAt(0).toUpperCase() + root.mode.slice(1))

  readonly property string statusLabel: {
    switch (root.status) {
    case "runtime":
      return I18n.tr("Applied at runtime");
    case "loaded":
      return I18n.tr("Loaded");
    case "fallback":
      return I18n.tr("Not loaded");
    }
    return I18n.tr("Checking…");
  }

  implicitHeight: column.implicitHeight + Widget.padding * 2
  backgroundColor: Theme.backgroundAlt

  ColumnLayout {
    id: column
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Widget.padding
    spacing: Widget.spacing * 1.5

    RowLayout {
      Layout.fillWidth: true
      spacing: Widget.spacing

      StyledText {
        text: I18n.tr("Status")
        textColor: Theme.accent
        textSize: Appearance.fontSize + 1
        font.bold: true
        Layout.fillWidth: true
      }

      StyledText {
        text: root.modeLabel
        opacity: 0.7
      }

      Rectangle {
        implicitWidth: chip.implicitWidth + Widget.padding * 2
        implicitHeight: chip.implicitHeight + 4
        radius: height / 2
        color: root.statusColor

        StyledText {
          id: chip
          anchors.centerIn: parent
          text: root.statusLabel
          textColor: Theme.background
          textSize: Appearance.fontSize - 2
          font.bold: true
        }
      }
    }

    // Why the mode isn't in effect; axiom's layer is applied at runtime
    // meanwhile
    StyledText {
      visible: root.status === "fallback"
      text: HyprlandConfigManager.problem + "\n" + I18n.tr("Until then, axiom applies its binds and settings at runtime.")
      textColor: Theme.warning
      textSize: Appearance.fontSize - 1
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    // --- What the mode needs ---

    StyledText {
      visible: root.mode === "detached"
      text: I18n.tr("Nothing to set up: axiom applies its layer with hyprctl, and again after every Hyprland reload. Binds on keys your config already uses are skipped.")
      opacity: 0.7
      textSize: Appearance.fontSize - 2
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    ColumnLayout {
      visible: root.mode === "included"
      Layout.fillWidth: true
      spacing: Widget.spacing

      StyledText {
        text: I18n.tr("Add these lines near the top of your hyprland.lua. Anything after them overrides axiom.")
        opacity: 0.7
        textSize: Appearance.fontSize - 2
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      StyledContainer {
        Layout.fillWidth: true
        implicitHeight: lines.implicitHeight + Widget.padding * 2
        backgroundColor: Theme.background

        StyledText {
          id: lines
          anchors.fill: parent
          anchors.margins: Widget.padding
          text: HyprlandConfigManager.includeLines
          textFamily: "monospace"
          textSize: Appearance.fontSize - 2
          wrapMode: Text.WrapAnywhere
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Widget.spacing

        StyledText {
          text: HyprlandConfigManager.includePath
          opacity: 0.6
          textSize: Appearance.fontSize - 2
          elide: Text.ElideMiddle
          Layout.fillWidth: true
        }

        StyledTextButton {
          implicitHeight: Widget.height - 4
          text: I18n.tr("Copy")
          onClicked: HyprlandConfigManager.copyIncludeLines()
        }
      }
    }

    ColumnLayout {
      visible: root.mode === "managed"
      Layout.fillWidth: true
      spacing: Widget.spacing

      StyledText {
        text: I18n.tr("axiom writes {0} from the cards below. Your own settings go in {1}/*.lua, loaded after it.", HyprlandConfigManager.managedPath, HyprlandConfigManager.userDir)
        opacity: 0.7
        textSize: Appearance.fontSize - 2
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      StyledTextButton {
        implicitHeight: Widget.height - 4
        text: I18n.tr("Open folder")
        onClicked: HyprlandConfigManager.openConfigDir()
      }
    }

    // --- Binds that didn't make it ---

    StyledText {
      visible: HyprlandConfigManager.skippedKeys.length > 0
      text: I18n.tr("Skipped, since your config already binds them: {0}", HyprlandConfigManager.skippedKeys.join(", "))
      textColor: Theme.warning
      textSize: Appearance.fontSize - 1
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    StyledText {
      visible: root.duplicateKeys.length > 0
      text: I18n.tr("Bound more than once: {0}", root.duplicateKeys.join(", "))
      textColor: Theme.warning
      textSize: Appearance.fontSize - 1
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    StyledText {
      visible: root.mode !== "managed"
      text: I18n.tr("Managed mode also sets the layout, decoration, keyboard, mouse and cursor.")
      opacity: 0.6
      textSize: Appearance.fontSize - 2
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
}
