pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.forms

// The selected bar's own settings, generated from the schema's Bar
// definition (its widgets are edited in the zone lists)
SchemaSection {
  id: root

  required property var bar

  title: root.bar ? (root.bar.id || I18n.tr("Bar")) : I18n.tr("Bar")
  expanded: true

  SchemaSwitch {
    label: I18n.tr("Primary")
    checked: BarManager.selectedBarIndex === 0
    description: I18n.tr("The primary bar is the first one")
    onToggled: value => {
      if (value)
        BarManager.setPrimary(BarManager.selectedBarIndex);
    }
  }

  SchemaPropertiesForm {
    Layout.fillWidth: true
    propertiesSchema: ConfigManager.configSchema.definitions?.Bar?.properties ?? ({})
    values: root.bar ?? ({})
    // root.bar is BarManager's draft copy, not the live config
    onEdited: (path, value) => {
      root.bar[path[0]] = value;
      BarManager.applyChanges();
    }
  }
}
