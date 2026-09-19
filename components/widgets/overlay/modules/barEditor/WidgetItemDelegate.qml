pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.common

// itemDelegate for each zone's SchemaObjectArray in LayoutConfig.qml.
// itemData/itemIndex are assigned imperatively by SchemaObjectArray's Loader
// after construction (via Qt.binding), so they must NOT be `required`.
ColumnLayout {
  id: root

  required property string zone
  property var itemData: null
  property int itemIndex: -1

  readonly property var typeInfo: Bar.availableWidgetTypes.find(t => t.type === root.itemData?.type) || null
  readonly property var propertyKeys: root.typeInfo?.propertiesSchema ? Object.keys(root.typeInfo.propertiesSchema) : []

  Layout.fillWidth: true
  spacing: Widget.spacing

  StyledText {
    text: root.typeInfo ? root.typeInfo.label : (root.itemData?.type || "Unknown")
    font.bold: true
  }

  ColumnLayout {
    Layout.fillWidth: true
    visible: root.propertyKeys.length > 0
    spacing: Widget.spacing

    Repeater {
      model: root.propertyKeys

      delegate: SchemaTextField {
        id: fieldDelegate
        required property string modelData

        readonly property var fieldSchema: root.typeInfo.propertiesSchema[fieldDelegate.modelData]

        Layout.fillWidth: true
        label: fieldDelegate.fieldSchema?.description || fieldDelegate.modelData
        placeholderText: fieldDelegate.fieldSchema?.default || ""
        currentConfigValue: root.itemData?.properties?.[fieldDelegate.modelData] ?? (fieldDelegate.fieldSchema?.default || "")

        onValueChanged: {
          BarManager.updateWidgetProperty(root.zone, root.itemIndex, fieldDelegate.modelData, value);
        }
      }
    }
  }
}
