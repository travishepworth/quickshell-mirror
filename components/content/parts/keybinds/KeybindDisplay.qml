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
  required property var screen

  // A flat list model that will be built from the 'keybinds' object.
  // This is used by the Repeater to create a continuous flow.
  property list<var> displayModel: []

  // --- STYLING ---

  radius: Appearance.borderRadius
  color: Theme.background
  // highly likely to break
  // kind illegal to access this here (kinda abusing qml context properties)
  implicitHeight: screen.height - 300 // TODO: magix num
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
        width: OverlayConfig.cardUnit
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
      width: OverlayConfig.cardUnit
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
      width: OverlayConfig.cardUnit - (OverlayConfig.cardPadding * 2)
      height: 1
      color: Theme.border
      anchors.bottomMargin: 8
    }
  }

  Component {
    id: keybindComponent
    KeybindPreview {
      width: OverlayConfig.cardUnit
      anchors.topMargin: 4
      anchors.bottomMargin: 4
    }
  }
}
