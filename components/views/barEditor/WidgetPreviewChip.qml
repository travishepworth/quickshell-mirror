pragma ComponentBehavior: Bound
import QtQuick
import qs.config
import qs.components.bar

// Small always-horizontal live preview of what a module actually looks like,
// shown inline next to a zone list item's "#N" label. itemData/itemIndex are
// assigned imperatively by SchemaObjectArray's Loader after construction
// (via Qt.binding), so they must NOT be `required`.
Item {
  id: root

  property var itemData: null
  property int itemIndex: -1

  // Force horizontal rendering regardless of the real bar's orientation -
  // this is just a "what does this module look like" swatch.
  readonly property var previewBarConfig: Bar.enrichBarConfig({
    "location": "Top",
    "extent": Widget.height
  })

  implicitWidth: loader.item ? loader.item.implicitWidth : 0
  implicitHeight: Widget.height

  Loader {
    id: loader
    anchors.verticalCenter: parent.verticalCenter
    active: !!root.itemData?.type
    sourceComponent: BarModule {
      barConfig: root.previewBarConfig
      properties: root.itemData.properties || {}
      componentPath: "widgets/" + root.itemData.type + ".qml"
      panel: null
      popouts: null
      screen: null
    }
  }
}
