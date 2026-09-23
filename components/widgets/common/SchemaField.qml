pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.components.reusable
import qs.components.widgets.common

// One row of a SchemaForm: picks the control for the row's schema type.
Loader {
  id: root

  required property var row
  required property var form

  readonly property var fieldSchema: row.schema ?? ({})
  readonly property var current: form.valueAt(row.path)
  readonly property string label: row.title
  readonly property string description: fieldSchema.description ?? ""

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
      return form.options(fieldSchema) ? comboField : textField;
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
      options: root.form.options(root.fieldSchema)
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
