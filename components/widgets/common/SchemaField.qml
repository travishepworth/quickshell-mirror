pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.common

// One row of a schema-driven form: picks the control for the row's schema
// type. `form` provides valueAt(path) and an edited(path, value) signal
// (SchemaForm, or the bar editor's WidgetItemDelegate).
Loader {
  id: root

  required property var row
  required property var form

  readonly property var fieldSchema: row.schema ?? ({})
  readonly property var current: form.valueAt(row.path)
  readonly property string label: row.title
  readonly property string description: fieldSchema.description ?? ""
  readonly property bool isColor: fieldSchema["x-options"] === "colors"
  readonly property var options: {
    if (fieldSchema.enum)
      return fieldSchema.enum;
    switch (fieldSchema["x-options"]) {
    case "screens":
      return ["", ...Quickshell.screens.map(screen => screen.name)];
    case "chatBackends":
      return Object.keys(ConfigManager.config.Chat.backends);
    case "colors":
      return Theme.baseColorNames;
    }
    return null;
  }

  Layout.fillWidth: true

  function commit(value) {
    if (value !== root.current)
      root.form.edited(root.row.path, value);
  }

  sourceComponent: {
    if (row.kind === "group")
      return groupHeader;
    switch (fieldSchema.type) {
    case "boolean":
      return switchField;
    case "integer":
      return spinField;
    default:
      return root.options ? comboField : textField;
    }
  }

  Component {
    id: groupHeader
    StyledText {
      text: root.label
      font.bold: true
      textColor: Theme.accent
      topPadding: Widget.spacing
    }
  }

  Component {
    id: switchField
    SchemaSwitch {
      label: root.label
      description: root.description
      checked: root.current === true
      onToggled: value => root.commit(value)
    }
  }

  Component {
    id: spinField
    SchemaSpinBox {
      label: root.label
      description: root.description
      currentConfigValue: root.current ?? 0
      minimum: root.fieldSchema.minimum ?? 0
      maximum: root.fieldSchema.maximum ?? 9999
      onValueChanged: root.commit(value)
    }
  }

  Component {
    id: comboField
    SchemaComboBox {
      label: root.label
      description: root.description
      options: root.options
      swatches: root.isColor
      currentValue: root.current ?? ""
      onSelectionChanged: value => root.commit(value)
    }
  }

  Component {
    id: textField
    SchemaTextField {
      label: root.label
      description: root.description
      currentConfigValue: root.current ?? ""
      onValueChanged: root.commit(value)
    }
  }
}
