pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.forms

// i18n: keys from callers and the schema (titles, descriptions, type labels)
// itemDelegate for each zone's SchemaObjectArray in LayoutConfig.qml: the
// widget's properties form, generated from its schema like the settings
// menu.
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

  readonly property int optionCount: propertiesForm.rows.length

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
        visible: root.optionCount > 0
        rotation: root.expanded ? 90 : 0

        Behavior on rotation {
          NumberAnimation {
            duration: Appearance.animNormal
            easing.type: Easing.OutCubic
          }
        }
      }

      StyledText {
        text: root.typeInfo ? I18n.tr(root.typeInfo.label) : (root.widgetType || I18n.tr("Unknown"))
        font.bold: true
        Layout.fillWidth: true
      }

      StyledText {
        text: root.optionCount > 0 ? I18n.tr("{0} options", root.optionCount) : I18n.tr("No options")
        opacity: 0.6
        textSize: Appearance.fontSize - 2
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.optionCount > 0
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

      SchemaPropertiesForm {
        id: propertiesForm
        Layout.fillWidth: true
        propertiesSchema: root.propertiesSchema
        values: root.itemData?.properties ?? ({})
        onEdited: (path, value) => BarManager.updateWidgetProperty(root.zone, root.itemIndex, path[0], value)
      }

      // Bottom breathing room, part of what the body grows to
      Item {
        Layout.preferredHeight: Widget.spacing
      }
    }
  }
}
