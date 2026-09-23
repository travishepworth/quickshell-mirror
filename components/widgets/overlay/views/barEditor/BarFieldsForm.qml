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

  title: root.bar ? (root.bar.id || I18n.tr("Bar")) : I18n.tr("Bar")
  expanded: true

  GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: Widget.spacing * 2
    rowSpacing: Widget.spacing

    SchemaSwitch {
      label: I18n.tr("Enabled")
      checked: root.bar?.enabled || false
      onToggled: value => {
        root.bar.enabled = value;
        BarManager.applyChanges();
      }
    }

    SchemaSwitch {
      label: I18n.tr("Primary")
      checked: BarManager.selectedBarIndex === 0
      description: I18n.tr("The primary bar is the first one")
      onToggled: value => {
        if (value)
          BarManager.setPrimary(BarManager.selectedBarIndex);
      }
    }

    SchemaSwitch {
      label: I18n.tr("Reserve Space")
      checked: root.bar?.reserveSpace ?? true
      description: I18n.tr("Keep windows from tiling underneath the bar")
      onToggled: value => {
        root.bar.reserveSpace = value;
        BarManager.applyChanges();
      }
    }

    SchemaComboBox {
      label: I18n.tr("Location")
      options: ["Top", "Bottom", "Left", "Right"]
      currentValue: root.bar?.location || "Top"
      onSelectionChanged: newValue => {
        root.bar.location = newValue;
        BarManager.applyChanges();
      }
    }

    SchemaComboBox {
      label: I18n.tr("Monitor")
      options: ["", ...Quickshell.screens.map(s => s.name)]
      currentValue: root.bar?.monitor || ""
      description: I18n.tr("Which monitor this bar is shown on")
      onSelectionChanged: newValue => {
        root.bar.monitor = newValue;
        BarManager.applyChanges();
      }
    }

    SchemaSpinBox {
      label: I18n.tr("Extent")
      description: I18n.tr("Thickness of the bar (px)")
      currentConfigValue: root.bar?.extent || 30
      minimum: 10
      maximum: 200
      onValueChanged: {
        root.bar.extent = value;
        BarManager.applyChanges();
      }
    }

    SchemaSpinBox {
      label: I18n.tr("Spacing")
      description: I18n.tr("Spacing between widgets (px)")
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
