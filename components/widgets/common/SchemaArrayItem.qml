pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

// itemDelegate for an array-of-objects SchemaField: the item's fields,
// generated from the array's `items` schema (and acting as the `form` for
// its SchemaField rows). itemData/itemIndex are assigned imperatively by
// SchemaObjectArray's Loader after construction, so they must NOT be
// `required`.
ColumnLayout {
  id: root

  required property var itemSchema
  property var itemData: null
  property int itemIndex: -1

  signal itemEdited(int index, string key, var value)
  signal edited(var path, var value)
  onEdited: (path, value) => root.itemEdited(root.itemIndex, path[0], value)

  // Depends on the schema only, so edits update the rows in place
  readonly property var rows: Object.keys(root.itemSchema.properties ?? {}).filter(key => {
    const prop = root.itemSchema.properties[key];
    return prop["x-settings"] !== false && ["boolean", "integer", "string"].includes(prop.type);
  }).map(key => ({
        "kind": "field",
        "title": root.itemSchema.properties[key].title ?? key,
        "path": [key],
        "schema": root.itemSchema.properties[key]
      }))

  function valueAt(path) {
    return root.itemData?.[path[0]] ?? root.itemSchema.properties[path[0]]?.default;
  }

  Layout.fillWidth: true
  spacing: Widget.spacing

  Repeater {
    model: root.rows

    // Loaded by URL: SchemaField instantiates this type, so naming it here
    // would make the two types depend on each other
    delegate: Loader {
      required property var modelData
      Layout.fillWidth: true
      Component.onCompleted: setSource(Qt.resolvedUrl("SchemaField.qml"), {
        "row": modelData,
        "form": root
      })
    }
  }
}
