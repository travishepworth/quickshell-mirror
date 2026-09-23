pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.common

/**
 * Save the whole config under a name, and restore or delete saved ones.
 * Restore and delete ask for a second click to confirm.
 */
SchemaSection {
  id: root
  title: I18n.tr("Saved Configurations")
  description: I18n.tr("Snapshots of the entire configuration, stored in ") + SavedConfigs.savedDir + ". Restoring replaces the current configuration."
  expanded: false

  // Row awaiting a confirming click: { name, action }
  property var pending: null

  RowLayout {
    Layout.fillWidth: true
    spacing: Widget.spacing

    StyledTextEntry {
      id: nameEntry
      Layout.fillWidth: true
      Layout.preferredHeight: Widget.height
      placeholderText: I18n.tr("Configuration name")
      onAccepted: root.save()
    }

    StyledTextButton {
      Layout.preferredHeight: Widget.height
      text: I18n.tr(SavedConfigs.exists(nameEntry.text) ? "Overwrite" : "Save")
      onClicked: root.save()
    }
  }

  StyledText {
    visible: SavedConfigs.status !== ""
    text: SavedConfigs.status
    opacity: 0.7
    textSize: Appearance.fontSize - 1
    Layout.fillWidth: true
  }

  StyledText {
    visible: SavedConfigs.model.count === 0
    text: I18n.tr("No saved configurations yet.")
    opacity: 0.5
    Layout.fillWidth: true
  }

  Repeater {
    model: SavedConfigs.model

    delegate: StyledContainer {
      id: row
      required property string fileBaseName
      required property date fileModified
      readonly property string pendingAction: root.pending?.name === fileBaseName ? root.pending.action : ""

      Layout.fillWidth: true
      Layout.preferredHeight: Widget.height + Widget.padding * 2
      backgroundColor: Theme.backgroundAlt

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Widget.padding
        anchors.rightMargin: Widget.padding
        spacing: Widget.spacing

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0

          StyledText {
            text: row.fileBaseName
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          StyledText {
            text: Qt.formatDateTime(row.fileModified, "yyyy-MM-dd hh:mm")
            opacity: 0.6
            textSize: Appearance.fontSize - 2
            Layout.fillWidth: true
          }
        }

        StyledTextButton {
          Layout.preferredHeight: Widget.height
          text: row.pendingAction === "restore" ? "Confirm" : "Restore"
          onClicked: root.confirm(row.fileBaseName, "restore")
        }

        StyledTextButton {
          Layout.preferredHeight: Widget.height
          text: row.pendingAction === "delete" ? "Confirm" : "Delete"
          hoverColor: Theme.error
          onClicked: root.confirm(row.fileBaseName, "delete")
        }
      }
    }
  }

  function save() {
    SavedConfigs.save(nameEntry.text);
    nameEntry.text = "";
    root.pending = null;
  }

  // First click arms the action, a second click on the same button runs it
  function confirm(name, action) {
    if (root.pending?.name !== name || root.pending?.action !== action) {
      root.pending = {
        name: name,
        action: action
      };
      return;
    }
    root.pending = null;
    if (action === "restore")
      SavedConfigs.restore(name);
    else
      SavedConfigs.remove(name);
  }
}
