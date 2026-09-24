import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable

StyledContainer {
  id: root

  // Set by the KeybindDisplay Loader; data is { label, combos: [{ mods, key }] }
  property var itemData

  property var keybindGroup: itemData ? itemData.data : null

  property var iconLookupTbl: ({
      SHIFT: "󰘶",
      CTRL: "⌃",
      ALT: "ALT",
      SUPER: "󰘳",
      META: "󰘳"
    })

  // Container styling
  color: Theme.backgroundAlt
  implicitHeight: contentRow.implicitHeight + 16
  visible: keybindGroup !== null

  RowLayout {
    id: contentRow
    anchors.fill: parent
    anchors.margins: 8
    spacing: 12

    // Vertical list of key combinations for the same action
    ColumnLayout {
      id: keyCombosColumn
      spacing: OverlayConfig.cardPadding

      Repeater {
        model: root.keybindGroup ? root.keybindGroup.combos : []

        delegate: RowLayout {
          spacing: OverlayConfig.cardSpacing / 2

          // Modifier keys
          RowLayout {
            spacing: OverlayConfig.cardPadding / 3

            Item {
              Layout.preferredWidth: OverlayConfig.cardSpacing
              visible: modelData.mods.length === 0
            }

            Repeater {
              model: modelData.mods

              Rectangle {
                id: modRect
                required property var modelData
                Layout.preferredHeight: 28
                Layout.preferredWidth: modText.width + 16
                color: "transparent"
                visible: modText.text !== ""
                border.color: Theme.foreground
                border.width: Math.max(1, Appearance.borderWidth)
                radius: 4

                Text {
                  id: modText
                  anchors.centerIn: parent
                  text: {
                    const lookup = root.iconLookupTbl[modRect.modelData];
                    return lookup !== undefined ? lookup : modRect.modelData.toUpperCase();
                  }
                  font.pixelSize: 20
                  font.family: "monospace"
                  color: Theme.foreground
                }
              }
            }
          }

          // Key bind
          Rectangle {
            Layout.preferredHeight: 28
            Layout.preferredWidth: bindText.width + 16
            color: "transparent"
            border.color: Theme.foreground
            border.width: Math.max(1, Appearance.borderWidth)
            radius: 4

            Text {
              id: bindText
              anchors.centerIn: parent
              text: modelData.key
              font.pixelSize: 13
              font.family: "monospace"
              color: Theme.foreground
            }
          }
        }
      }
    }

    // Action description
    Text {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      text: root.keybindGroup ? root.keybindGroup.label : ""
      font.pixelSize: 14
      color: Theme.foreground
      opacity: 0.8
      elide: Text.ElideRight
      horizontalAlignment: Text.AlignRight
    }
  }
}
