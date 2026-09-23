pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.common

// itemDelegate for each zone's SchemaObjectArray in LayoutConfig.qml: the
// widget's properties form, generated from its schema like the settings
// menu (and acting as the `form` for its SchemaField rows).
// itemData/itemIndex are assigned imperatively by SchemaObjectArray's Loader
// after construction (via Qt.binding), so they must NOT be `required`.
ColumnLayout {
  id: root

  required property string zone
  property var itemData: null
  property int itemIndex: -1

  // A string, so edits to the widget's properties don't re-evaluate what
  // depends on its type
  readonly property string widgetType: root.itemData?.type ?? ""
  readonly property var typeInfo: Bar.availableWidgetTypes.find(t => t.type === root.widgetType) || null
  readonly property var propertiesSchema: root.typeInfo?.propertiesSchema ?? ({})

  // Depends on the type only, so edits update the rows in place
  readonly property var rows: Object.keys(root.propertiesSchema).map(key => ({
        "kind": "field",
        "title": root.propertiesSchema[key].title ?? key,
        "path": [key],
        "schema": root.propertiesSchema[key]
      }))

  signal edited(var path, var value)
  onEdited: (path, value) => BarManager.updateWidgetProperty(root.zone, root.itemIndex, path[0], value)

  function valueAt(path) {
    return root.itemData?.properties?.[path[0]] ?? root.propertiesSchema[path[0]]?.default;
  }

  // `x-showIf: { sibling: value | [values] | { not: value } }`
  function isShown(fieldSchema) {
    const condition = fieldSchema["x-showIf"];
    if (!condition)
      return true;
    return Object.keys(condition).every(key => {
      const want = condition[key];
      const value = root.valueAt([key]);
      if (Array.isArray(want))
        return want.includes(value);
      if (want !== null && typeof want === "object")
        return value !== want.not;
      return value === want;
    });
  }

  Layout.fillWidth: true
  spacing: Widget.spacing

  // Collapsed by default; the header toggles the options open below it
  property bool expanded: false

  Item {
    Layout.fillWidth: true
    implicitHeight: header.implicitHeight

    RowLayout {
      id: header
      anchors.left: parent.left
      anchors.right: parent.right
      spacing: Widget.spacing

      StyledText {
        text: "▶"
        textColor: Theme.accent
        visible: root.rows.length > 0
        rotation: root.expanded ? 90 : 0

        Behavior on rotation {
          NumberAnimation {
            duration: Appearance.animNormal
            easing.type: Easing.OutCubic
          }
        }
      }

      StyledText {
        text: root.typeInfo ? root.typeInfo.label : (root.widgetType || "Unknown")
        font.bold: true
        Layout.fillWidth: true
      }

      StyledText {
        text: root.rows.length > 0 ? `${root.rows.length} options` : "No options"
        opacity: 0.6
        textSize: Appearance.fontSize - 2
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.rows.length > 0
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }

  // Grows downwards from the header, clipping the fields while it animates
  Item {
    id: body
    Layout.fillWidth: true
    Layout.preferredHeight: root.expanded ? fields.implicitHeight + Widget.spacing : 0
    visible: Layout.preferredHeight > 0
    clip: true

    Behavior on Layout.preferredHeight {
      NumberAnimation {
        duration: Appearance.animNormal
        easing.type: Easing.OutCubic
      }
    }

    ColumnLayout {
      id: fields
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.topMargin: Widget.spacing
      spacing: Widget.spacing

      Repeater {
        model: root.rows

        delegate: SchemaField {
          required property var modelData
          row: modelData
          form: root
          visible: root.isShown(modelData.schema)
        }
      }

      // Bottom breathing room, part of what the body grows to
      Item {
        Layout.preferredHeight: Widget.spacing
      }
    }
  }
}
