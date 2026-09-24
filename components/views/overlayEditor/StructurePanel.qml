pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.hosts.overlay
import qs.components.content.base

// i18n: keys from callers and the schema (titles, descriptions, type labels)
// The overlay's pages, and the selected Custom page's columns and cells.
// Sized by OverlayEditor.
Item {
  id: root

  readonly property var view: OverlayManager.selectedView()
  readonly property bool isCustom: root.view?.type === "Custom"

  function viewLabel(view, index) {
    if (view.type === "Custom")
      return view.name || I18n.tr("Page {0}", index + 1);
    return I18n.tr(OverlayConfig.availableViewTypes.find(t => t.type === view.type)?.label ?? view.type);
  }

  // StyledTextEntry writes each keystroke back to its `text`, which drops
  // any binding on it, so the name is pushed in whenever the selected page
  // (or the sandbox) changes rather than bound
  function syncName() {
    if (!nameEntry.input.activeFocus)
      nameEntry.text = root.view?.name ?? "";
  }
  Connections {
    target: OverlayManager
    function onSelectedViewIndexChanged() {
      root.syncName();
    }
    function onLocalViewsChanged() {
      root.syncName();
    }
  }
  Component.onCompleted: root.syncName()

  TitledCard {
    title: I18n.tr("Overlay")
    dirty: OverlayManager.isDirty
    canSave: OverlayManager.problems.length === 0
    onSave: OverlayManager.saveChanges()
    onReset: OverlayManager.resetChanges()

    headerExtras: StyledText {
      Layout.fillWidth: true
      visible: OverlayManager.problems.length > 0
      wrapMode: Text.WordWrap
      text: I18n.tr("Can't save: {0}", OverlayManager.problems[0] ?? "")
      textColor: Theme.error
    }

    // --- Pages ---

    SectionTitle {
      text: I18n.tr("Pages")
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Widget.spacing / 2

      Repeater {
        model: OverlayManager.localViews

        Rectangle {
          id: pageRow
          required property int index
          required property var modelData
          readonly property bool selected: OverlayManager.selectedViewIndex === pageRow.index

          Layout.fillWidth: true
          Layout.preferredHeight: Widget.height + Widget.padding * 2
          radius: Appearance.borderRadius
          color: pageRow.selected ? Theme.accent : pageArea.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt
          border.color: pageRow.selected ? Theme.accent : Theme.border
          border.width: Appearance.borderWidth

          MouseArea {
            id: pageArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: OverlayManager.selectView(pageRow.index)
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Widget.padding
            anchors.rightMargin: Widget.padding / 2
            spacing: Widget.spacing / 2

            StyledText {
              text: pageRow.index + 1
              textColor: pageRow.selected ? Theme.background : Theme.foreground
              opacity: 0.6
            }
            StyledText {
              Layout.fillWidth: true
              elide: Text.ElideRight
              text: root.viewLabel(pageRow.modelData, pageRow.index)
              textColor: pageRow.selected ? Theme.background : Theme.foreground
              font.bold: true
            }
            StyledText {
              visible: pageRow.modelData.type !== "Custom"
              text: I18n.tr("fixed")
              textColor: pageRow.selected ? Theme.background : Theme.foreground
              textSize: Appearance.fontSize - 2
              opacity: 0.6
            }
            SquareIconButton {
              iconText: "▴"
              tooltipText: I18n.tr("Move page up")
              enabled: pageRow.index > 0
              onClicked: OverlayManager.moveView(pageRow.index, -1)
            }
            SquareIconButton {
              iconText: "▾"
              tooltipText: I18n.tr("Move page down")
              enabled: pageRow.index < OverlayManager.localViews.length - 1
              onClicked: OverlayManager.moveView(pageRow.index, 1)
            }
            SquareIconButton {
              iconText: "×"
              tooltipText: I18n.tr("Remove page")
              hoverColor: Theme.error
              onClicked: OverlayManager.removeView(pageRow.index)
            }
          }
        }
      }

      // The editor itself: always last, not editable
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Widget.height + Widget.padding * 2
        radius: Appearance.borderRadius
        color: "transparent"
        border.color: Theme.border
        border.width: Appearance.borderWidth
        opacity: 0.5

        StyledText {
          anchors.fill: parent
          anchors.leftMargin: Widget.padding
          verticalAlignment: Text.AlignVCenter
          text: `${OverlayManager.localViews.length + 1}   ` + I18n.tr("Overlay editor (always last)")
        }
      }
    }

    StyledTextButton {
      id: addPageButton
      text: I18n.tr("+ page")
      onClicked: viewPicker.open()
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: Theme.border
      opacity: 0.3
    }

    // --- Selected page ---

    SectionTitle {
      visible: root.view !== null
      text: root.view ? root.viewLabel(root.view, OverlayManager.selectedViewIndex) : ""
    }

    StyledText {
      visible: root.view !== null && !root.isCustom
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      text: I18n.tr("A fixed page: it has no layout to edit.")
      opacity: 0.6
    }

    StyledTextEntry {
      id: nameEntry
      Layout.fillWidth: true
      visible: root.isCustom
      placeholderText: I18n.tr("Page name")
      onAccepted: OverlayManager.renameView(OverlayManager.selectedViewIndex, nameEntry.text)

      Connections {
        target: nameEntry.input
        function onEditingFinished() {
          OverlayManager.renameView(OverlayManager.selectedViewIndex, nameEntry.text);
        }
      }
    }

    Repeater {
      model: root.isCustom ? (root.view.columns ?? []) : []

      ColumnLayout {
        id: column
        required property int index
        required property var modelData
        Layout.fillWidth: true
        spacing: Widget.spacing

        RowLayout {
          Layout.fillWidth: true
          spacing: Widget.spacing / 2

          StyledText {
            Layout.fillWidth: true
            text: I18n.tr("Column {0}", column.index + 1)
            font.bold: true
          }
          SquareIconButton {
            iconText: "‹"
            tooltipText: I18n.tr("Move column left")
            enabled: column.index > 0
            onClicked: OverlayManager.moveColumn(column.index, -1)
          }
          SquareIconButton {
            iconText: "›"
            tooltipText: I18n.tr("Move column right")
            enabled: column.index < root.view.columns.length - 1
            onClicked: OverlayManager.moveColumn(column.index, 1)
          }
          SquareIconButton {
            iconText: "×"
            tooltipText: I18n.tr("Remove column")
            hoverColor: Theme.error
            onClicked: OverlayManager.removeColumn(column.index)
          }
        }

        Repeater {
          model: column.modelData.cells ?? []

          RowLayout {
            id: cellRow
            required property int index
            required property var modelData
            Layout.fillWidth: true
            Layout.leftMargin: Widget.padding
            spacing: Widget.spacing / 2

            StyledText {
              Layout.fillWidth: true
              elide: Text.ElideRight
              text: {
                const modules = Object.values(cellRow.modelData.slots ?? {}).map(m => m.type);
                return cellRow.modelData.layout + " · " + (modules.length > 0 ? modules.join(", ") : I18n.tr("empty"));
              }
            }
            SquareIconButton {
              iconText: "▴"
              tooltipText: I18n.tr("Move cell up")
              enabled: cellRow.index > 0
              onClicked: OverlayManager.moveCell(column.index, cellRow.index, -1)
            }
            SquareIconButton {
              iconText: "▾"
              tooltipText: I18n.tr("Move cell down")
              enabled: cellRow.index < column.modelData.cells.length - 1
              onClicked: OverlayManager.moveCell(column.index, cellRow.index, 1)
            }
            SquareIconButton {
              iconText: "×"
              tooltipText: I18n.tr("Remove cell")
              hoverColor: Theme.error
              onClicked: OverlayManager.removeCell(column.index, cellRow.index)
            }
          }
        }

        StyledTextButton {
          Layout.leftMargin: Widget.padding
          text: I18n.tr("+ cell")
          onClicked: OverlayManager.addCell(column.index)
        }
      }
    }

    StyledTextButton {
      visible: root.isCustom
      text: I18n.tr("+ column")
      onClicked: OverlayManager.addColumn()
    }
  }

  TypePickerPopup {
    id: viewPicker
    parent: addPageButton
    y: addPageButton.height + Widget.spacing / 2
    types: OverlayConfig.availableViewTypes
    onTypeSelected: type => OverlayManager.addView(type)
  }
}
