pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.reusable
import qs.components.widgets.overlay
import qs.components.widgets.bar.popouts.content

// The bar's audio mixer (device picker + per-app volumes), with an
// output/input switch. properties: { mode: "output" | "input" }
OverlayCard {
  id: root

  property string mode: root.properties.mode ?? "output"

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad / 2
    spacing: 0

    RowLayout {
      Layout.fillWidth: true
      Layout.margins: root.pad / 2
      spacing: Widget.spacing / 2
      Repeater {
        model: [["output", "\u{F057E}", "Output"], ["input", "\u{F036C}", "Input"]]
        StyledTabButton {
          required property var modelData
          Layout.fillWidth: true
          text: `${modelData[1]}  ${I18n.tr(modelData[2])}`
          checked: root.mode === modelData[0]
          onClicked: root.mode = modelData[0]
        }
      }
    }

    AudioMixerPopout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      wrapper: null
      embedded: true
      mode: root.mode
    }
  }
}
