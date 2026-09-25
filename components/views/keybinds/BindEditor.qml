pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable

// The Keybinds page's editor for axiom's own binds (Hyprland.binds):
// presets, then one row per bind. Edits wait in KeybindManager's draft
// until Save.
ColumnLayout {
  id: root

  // What the last preset did, shown next to the presets
  property string presetResult: ""

  spacing: Widget.spacing * 2

  Component.onDestruction: KeybindManager.stopRecording()

  // --- Presets ---

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Widget.spacing

    RowLayout {
      Layout.fillWidth: true

      StyledText {
        text: I18n.tr("Presets")
        textColor: Theme.accent
        font.bold: true
      }

      StyledText {
        text: root.presetResult
        opacity: 0.7
        textSize: Appearance.fontSize - 2
        elide: Text.ElideRight
        Layout.fillWidth: true
        Layout.leftMargin: Widget.spacing
      }
    }

    Flow {
      Layout.fillWidth: true
      spacing: Widget.spacing

      Repeater {
        model: KeybindManager.presets

        delegate: StyledContainer {
          id: preset
          required property var modelData

          width: Math.min(parent.width, Math.max(260, (parent.width - Widget.spacing * 3) / 4))
          implicitHeight: presetColumn.implicitHeight + Widget.padding * 2
          backgroundColor: presetArea.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt

          ColumnLayout {
            id: presetColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Widget.padding
            spacing: 2

            RowLayout {
              Layout.fillWidth: true

              StyledText {
                text: preset.modelData.title
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              StyledText {
                text: "+" + preset.modelData.binds.length
                textColor: Theme.accent
                textSize: Appearance.fontSize - 1
              }
            }

            StyledText {
              text: preset.modelData.description
              opacity: 0.7
              textSize: Appearance.fontSize - 2
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
            }
          }

          MouseArea {
            id: presetArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              const result = KeybindManager.applyPreset(preset.modelData.id);
              root.presetResult = result.skipped > 0 ? I18n.tr("Added {0}, skipped {1} already bound", result.added, result.skipped) : I18n.tr("Added {0}", result.added);
            }
          }
        }
      }
    }
  }

  // --- The binds ---

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Widget.spacing

    RowLayout {
      Layout.fillWidth: true

      StyledText {
        text: I18n.tr("Axiom binds")
        textColor: Theme.accent
        font.bold: true
      }

      StyledText {
        text: KeybindManager.issueCount > 0 ? I18n.tr("{0} with issues", KeybindManager.issueCount) : I18n.tr("Click a key to record a combo. Changes apply on Save.")
        textColor: KeybindManager.issueCount > 0 ? Theme.warning : Theme.foreground
        opacity: KeybindManager.issueCount > 0 ? 1 : 0.6
        textSize: Appearance.fontSize - 2
        elide: Text.ElideRight
        Layout.fillWidth: true
        Layout.leftMargin: Widget.spacing
      }
    }

    StyledText {
      visible: KeybindManager.binds.length === 0
      text: I18n.tr("No binds yet. Add one, or start from a preset.")
      opacity: 0.6
      Layout.fillWidth: true
    }

    // By count: rows follow edits in place instead of rebuilding
    Repeater {
      model: KeybindManager.binds.length

      delegate: BindEditorRow {}
    }

    StyledTextButton {
      implicitHeight: Widget.height
      iconText: "add"
      text: I18n.tr("Add bind")
      onClicked: KeybindManager.addBind()
    }
  }
}
