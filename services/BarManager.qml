pragma Singleton
import QtQuick

import qs.config
import qs.components.methods
import qs.services

/* BarManager holds a sandboxed, in-memory copy of the Bars config for the
 * Bar Editor overlay. Edits here only affect localConfig (and whatever
 * reads it, e.g. the editor's own preview) - the real running bars and
 * config.json are untouched until saveChanges() is called. */
QtObject {
  id: root

  property ConfigDraft _draft: ConfigDraft {
    id: draft
    path: ["Bars"]
  }
  readonly property alias localConfig: draft.local
  readonly property alias isDirty: draft.isDirty
  property int selectedBarIndex: 0

  function loadConfig() {
    draft.load();
    selectedBarIndex = 0;
  }

  // Call after mutating localConfig in place. Sandbox-only: never touches
  // ConfigManager or disk.
  function applyChanges() {
    draft.changed();
  }

  function selectedBar() {
    return root.localConfig[root.selectedBarIndex] || null;
  }

  function addBar() {
    // Every other field comes from the Bar schema's defaults
    const bar = SchemaValidation.applyDefaults({
      "id": "bar-" + (root.localConfig.length + 1)
    }, {
      "$ref": "#/definitions/Bar"
    }, ConfigManager.configSchema);
    root.localConfig.push(bar);
    root.selectedBarIndex = root.localConfig.length - 1;
    applyChanges();
  }

  function removeBar(index) {
    if (root.localConfig.length <= 1)
      return; // never remove the last bar
    root.localConfig.splice(index, 1);
    root.selectedBarIndex = Math.max(0, Math.min(root.selectedBarIndex, root.localConfig.length - 1));
    applyChanges();
  }

  // The first bar is the primary one: move the chosen bar to the front
  function setPrimary(index) {
    if (index <= 0 || index >= root.localConfig.length)
      return;
    const [bar] = root.localConfig.splice(index, 1);
    root.localConfig.unshift(bar);
    root.selectedBarIndex = 0;
    applyChanges();
  }

  function addWidget(zone, widgetType) {
    const bar = selectedBar();
    if (!bar)
      return;
    if (!bar.widgets)
      bar.widgets = {};
    if (!bar.widgets[zone])
      bar.widgets[zone] = [];
    // Properties start at the widget schema's defaults
    bar.widgets[zone].push(SchemaValidation.applyDefaults({
      "type": widgetType
    }, {
      "$ref": "#/definitions/BarWidget"
    }, ConfigManager.configSchema));
    applyChanges();
  }

  function removeWidget(zone, index) {
    selectedBar()?.widgets?.[zone]?.splice(index, 1);
    applyChanges();
  }

  function moveWidget(zone, fromIndex, toIndex) {
    const arr = selectedBar()?.widgets?.[zone];
    if (!arr || toIndex < 0 || toIndex >= arr.length)
      return;
    const [item] = arr.splice(fromIndex, 1);
    arr.splice(toIndex, 0, item);
    applyChanges();
  }

  function updateWidgetProperty(zone, index, key, value) {
    const widget = selectedBar()?.widgets?.[zone]?.[index];
    if (!widget)
      return;
    if (!widget.properties)
      widget.properties = {};
    widget.properties[key] = value;
    applyChanges();
  }

  // Merged onto the latest real config; stays dirty if rejected
  function saveChanges() {
    draft.save();
  }

  // Discard sandbox edits, reload fresh from the current real config.
  function resetChanges() {
    loadConfig();
  }
}
