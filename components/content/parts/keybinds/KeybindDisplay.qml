pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable

Rectangle {
  id: root

  // --- PROPERTIES ---

  // Ordered sections from HyprConfigManager: [{ title, binds: [{ label, combos }] }]
  required property var keybinds
  // One column's width, and the most height the display may take (the
  // overlay's card size and free height): the columns wrap to fit it
  required property real cardWidth
  required property real maxHeight

  // A flat list model that will be built from the 'keybinds' object.
  // This is used by the Repeater to create a continuous flow.
  property list<var> displayModel: []

  // --- STYLING ---

  radius: Appearance.borderRadius
  color: Theme.background
  implicitHeight: root.maxHeight
  implicitWidth: flow.implicitWidth + (OverlayConfig.cardSpacing * 2)

  border.color: Theme.border
  border.width: Appearance.borderWidth

  // --- JAVASCRIPT LOGIC ---
  // Flattens the sections into header + keybind items so the Flow can wrap continuously.
  function buildDisplayModel() {
    const newModel = [];
    for (const section of keybinds || []) {
      if (section.binds.length === 0)
        continue;
      newModel.push({
        type: "header",
        title: section.title
      });
      for (const bind of section.binds) {
        newModel.push({
          type: "keybind",
          data: bind
        });
      }
    }
    displayModel = newModel;
  }

  onKeybindsChanged: buildDisplayModel()
  Component.onCompleted: buildDisplayModel()

  // --- LAYOUT ---
  Flow {
    id: flow
    anchors.fill: parent
    anchors.margins: OverlayConfig.cardSpacing
    flow: Flow.TopToBottom
    spacing: OverlayConfig.cardPadding

    Repeater {
      model: root.displayModel
      delegate: Loader {
        id: itemLoader
        width: root.cardWidth
        required property var modelData

        sourceComponent: {
          switch (modelData.type) {
          case "header":
            return headerComponent;
          case "separator":
            return separatorComponent;
          case "keybind":
            return keybindComponent;
          default:
            return null;
          }
        }
        onLoaded: {
          if (item) {
            item.itemData = itemLoader.modelData;
          }
        }
      }
    }
  }

  Component {
    id: headerComponent
    StyledContainer {
      id: header
      property var itemData
      width: root.cardWidth
      color: Theme.backgroundHighlight
      height: 32
      StyledText {
        anchors.centerIn: parent
        text: header.itemData.title

        font.bold: true
        color: Theme.accent
      }

      Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - (OverlayConfig.cardPadding * 2)
        height: 1
        anchors.rightMargin: Widget.padding
        anchors.leftMargin: OverlayConfig.cardPadding
        color: Theme.info
      }
    }
  }

  Component {
    id: separatorComponent
    StyledContainer {
      width: root.cardWidth - (OverlayConfig.cardPadding * 2)
      height: 1
      color: Theme.border
      anchors.bottomMargin: 8
    }
  }

  Component {
    id: keybindComponent
    KeybindPreview {
      width: root.cardWidth
      anchors.topMargin: 4
      anchors.bottomMargin: 4
    }
  }
}
