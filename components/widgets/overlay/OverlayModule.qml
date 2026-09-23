pragma ComponentBehavior: Bound
import QtQuick
// Modules are loaded by URL; importing their directory is what makes qs
// scan them, so their own qs.* imports (e.g. modules.settings) resolve
import qs.components.widgets.overlay.modules

// Hosts one overlay module in a cell slot: loads modules/<type>.qml and
// hands it the entry's `properties` (defaults filled from the schema, as
// for bar widgets). An empty slot renders nothing.
Item {
  id: host

  // A slot entry: { type, properties }, or undefined for an empty slot
  property var config

  anchors.fill: parent

  readonly property string componentPath: host.config?.type ? "modules/" + host.config.type + ".qml" : ""

  // Created with its properties already set, then bound so later config
  // edits reach it (as BarModule does)
  function _load() {
    if (!host.componentPath) {
      loader.source = "";
      return;
    }
    loader.setSource(host.componentPath, {
      "properties": host.config.properties || {}
    });
  }
  onComponentPathChanged: _load()
  Component.onCompleted: _load()

  Loader {
    id: loader
    anchors.fill: parent
    onLoaded: item.properties = Qt.binding(() => host.config?.properties || {})
  }
}
