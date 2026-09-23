pragma ComponentBehavior: Bound
import QtQuick
import qs.config
// Imported (though modules load by URL) so qs scans the modules directory:
// without it, types there (e.g. BarIconWidget) aren't visible to each other
import qs.components.widgets.bar.modules

// Hosts one bar module and turns its sizing contract into the numbers the
// bar layout works with. A module may declare any of these on its root item:
//
//   sizePolicy:    "content" (default) - exactly its implicit size
//                  "fixed"             - exactly preferredSize, whatever it shows
//                  "elastic"           - its implicit size capped at preferredSize,
//                                        shrinks towards minimumSize when crowded
//   preferredSize: main-axis size (fixed: the size; elastic: the cap)
//   minimumSize:   smallest main-axis size an elastic module accepts
//   priority:      when a section can't fit even the minimum sizes, the
//                  lowest-priority modules are hidden first (default 0)
//
// The widget's `layout` config (`layoutOverrides`) wins over the module's
// own values. The host's main-axis size (`mainSize`) is assigned by
// WidgetGroup; the cross axis is always Widget.height. Modules must fit
// their content to whatever size they're given and report their natural
// size through implicitWidth/implicitHeight, independent of that size.
Item {
  id: component

  required property var barConfig
  property var popouts
  property var panel
  property var screen

  required property var properties
  required property string componentPath
  property var layoutOverrides: ({})
  // Where this module's section is anchored along the bar (0 start, 1 end,
  // 0.5 center): the edge that stays put as the module resizes
  property real sectionAlign: 0.5

  property alias contentItem: contentLoader.item
  readonly property bool isVertical: barConfig.vertical

  readonly property var _item: contentLoader.item
  readonly property real naturalSize: _item ? Math.ceil(isVertical ? _item.implicitHeight : _item.implicitWidth) : 0
  readonly property string sizePolicy: _item?.sizePolicy ?? "content"

  readonly property real preferredSize: {
    const override = layoutOverrides?.size;
    if (sizePolicy === "fixed")
      return override ?? _item?.preferredSize ?? naturalSize;
    if (sizePolicy === "elastic")
      return Math.min(naturalSize, override ?? _item?.preferredSize ?? naturalSize);
    return override ?? naturalSize;
  }
  readonly property real minimumSize: {
    const min = layoutOverrides?.minSize ?? (sizePolicy === "elastic" ? _item?.minimumSize : undefined);
    return min === undefined ? preferredSize : Math.min(min, preferredSize);
  }
  readonly property int priority: layoutOverrides?.priority ?? _item?.priority ?? 0

  // Assigned by WidgetGroup; standalone hosts (e.g. editor previews) just
  // get their preferred size
  property real mainSize: preferredSize

  // Set by WidgetGroup when the bar is too crowded for this module. It must
  // not become `visible: false`: positioners inside modules (Row/Column)
  // skip invisible children, which would change the size being measured
  // and flip the module between hidden and shown forever.
  property bool shown: true
  opacity: shown ? 1 : 0
  enabled: shown

  implicitWidth: isVertical ? Widget.height : preferredSize
  implicitHeight: isVertical ? preferredSize : Widget.height
  width: isVertical ? Widget.height : mainSize
  height: isVertical ? mainSize : Widget.height

  // Created with its inputs already set, so the module's own bindings
  // never see them undefined; bound afterwards so later changes (e.g. edits
  // in the bar editor's preview) reach it
  function _load() {
    contentLoader.setSource(component.componentPath, {
      "barConfig": component.barConfig,
      "popouts": component.popouts,
      "panel": component.panel,
      "screen": component.screen,
      "properties": component.properties
    });
  }
  onComponentPathChanged: _load()
  Component.onCompleted: _load()

  Loader {
    id: contentLoader
    anchors.fill: parent
    onLoaded: {
      if (item) {
        item.barConfig = Qt.binding(() => component.barConfig);
        item.popouts = Qt.binding(() => component.popouts);
        item.panel = Qt.binding(() => component.panel);
        item.screen = Qt.binding(() => component.screen);
        item.properties = Qt.binding(() => component.properties);
      }
    }
  }
}
