pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components.widgets.common

SchemaSection {
  id: root

  required property var bar

  title: root.bar ? (root.bar.id || "Bar") : "Bar"
  expanded: true

  GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: Widget.spacing * 2
    rowSpacing: Widget.spacing

    SchemaSwitch {
      label: "Enabled"
      checked: root.bar?.enabled || false
      onToggled: value => {
        root.bar.enabled = value;
        BarManager.applyChanges();
      }
    }

    SchemaSwitch {
      label: "Primary"
      checked: BarManager.selectedBarIndex === 0
      description: "The primary bar is the first one"
      onToggled: value => {
        if (value)
          BarManager.setPrimary(BarManager.selectedBarIndex);
      }
    }

    SchemaSwitch {
      label: "Reserve Space"
      checked: root.bar?.reserveSpace ?? true
      description: "Keep windows from tiling underneath the bar"
      onToggled: value => {
        root.bar.reserveSpace = value;
        BarManager.applyChanges();
      }
    }

    SchemaComboBox {
      label: "Location"
      options: ["Top", "Bottom", "Left", "Right"]
      currentValue: root.bar?.location || "Top"
      onSelectionChanged: newValue => {
        root.bar.location = newValue;
        BarManager.applyChanges();
      }
    }

    SchemaComboBox {
      label: "Monitor"
      options: ["", ...Quickshell.screens.map(s => s.name)]
      currentValue: root.bar?.monitor || ""
      description: "Which monitor this bar is shown on"
      onSelectionChanged: newValue => {
        root.bar.monitor = newValue;
        BarManager.applyChanges();
      }
    }

    SchemaSpinBox {
      label: "Extent"
      description: "Thickness of the bar (px)"
      currentConfigValue: root.bar?.extent || 30
      minimum: 10
      maximum: 200
      onValueChanged: {
        root.bar.extent = value;
        BarManager.applyChanges();
      }
    }

    SchemaSpinBox {
      label: "Spacing"
      description: "Spacing between widgets (px)"
      currentConfigValue: root.bar?.spacing || 4
      minimum: 0
      maximum: 50
      onValueChanged: {
        root.bar.spacing = value;
        BarManager.applyChanges();
      }
    }
  }
}
