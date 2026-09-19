pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.widgets.common

// The 5-zone widget/module layout editor for the currently selected bar.
ColumnLayout {
  id: root

  property string pendingZone: ""

  Layout.fillWidth: true
  spacing: Widget.spacing * 2

  AddWidgetPopup {
    id: addPopup
    parent: root
    x: (root.width - width) / 2
    y: (root.height - height) / 2
    onTypeSelected: type => BarManager.addWidget(root.pendingZone, type)
  }

  Repeater {
    model: [
      {
        "key": "left",
        "label": "Left"
      },
      {
        "key": "leftCenter",
        "label": "Left Center"
      },
      {
        "key": "center",
        "label": "Center"
      },
      {
        "key": "rightCenter",
        "label": "Right Center"
      },
      {
        "key": "right",
        "label": "Right"
      }
    ]

    delegate: SchemaObjectArray {
      required property var modelData

      Layout.fillWidth: true
      label: modelData.label
      items: BarManager.selectedBar()?.widgets?.[modelData.key] || []

      itemDelegate: Component {
        WidgetItemDelegate {
          zone: modelData.key
        }
      }

      itemHeaderExtra: Component {
        WidgetPreviewChip {}
      }

      onItemAdded: {
        root.pendingZone = modelData.key;
        addPopup.open();
      }
      onItemRemoved: index => BarManager.removeWidget(modelData.key, index)
      onItemMoved: (from, to) => BarManager.moveWidget(modelData.key, from, to)
    }
  }
}
