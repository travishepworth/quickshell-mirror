pragma Singleton
import QtQuick

import qs.config
import qs.services

/* BarManager holds a sandboxed, in-memory copy of the Bar config for the
 * Bar Editor overlay. Edits here only affect localConfig (and whatever
 * reads it, e.g. the editor's own preview) - the real running bars and
 * config.json are untouched until saveChanges() is called. */
QtObject {
  id: root

  property var localConfig: []
  property var _savedConfig: []
  property bool isDirty: false
  property int selectedBarIndex: 0

  Component.onCompleted: {
    loadConfig();
  }

  function loadConfig() {
    localConfig = JSON.parse(JSON.stringify(ConfigManager.config.Bar || []));
    _savedConfig = JSON.parse(JSON.stringify(ConfigManager.config.Bar || []));
    selectedBarIndex = 0;
    isDirty = false;
  }

  function checkDirty() {
    return JSON.stringify(localConfig) !== JSON.stringify(_savedConfig);
  }

  function markDirty() {
    root.isDirty = checkDirty();
  }

  // Call after mutating localConfig in place. Sandbox-only: never touches
  // ConfigManager or disk.
  function applyChanges() {
    markDirty();
    // Re-clone (next tick) purely to force QML's var-property change
    // notification, since in-place mutation doesn't fire onLocalConfigChanged
    // (same reason ConfigManager._loadObjectToConfig deep-clones). Deferred
    // via Qt.callLater so this doesn't reassign localConfig synchronously
    // inside the same call stack as the edit that triggered it - otherwise
    // any control whose own currentConfigValue depends on localConfig (e.g.
    // BarFieldsPanel's fields) re-enters its own binding and QML reports a
    // binding loop.
    Qt.callLater(root._refreshLocalConfig);
  }

  function _refreshLocalConfig() {
    root.localConfig = JSON.parse(JSON.stringify(root.localConfig));
  }

  function selectedBar() {
    return root.localConfig[root.selectedBarIndex] || null;
  }

  function addBar() {
    root.localConfig.push({
      "id": "bar-" + (root.localConfig.length + 1),
      "primary": root.localConfig.length === 0,
      "enabled": true,
      "display": "",
      "extent": 30,
      "spacing": 4,
      "location": "Top",
      "autoHide": false,
      "widgets": {
        "left": [],
        "leftCenter": [],
        "center": [],
        "rightCenter": [],
        "right": []
      }
    });
    root.selectedBarIndex = root.localConfig.length - 1;
    applyChanges();
  }

  function removeBar(index) {
    if (root.localConfig.length <= 1)
      return; // never remove the last bar
    const wasPrimary = root.localConfig[index]?.primary;
    root.localConfig.splice(index, 1);
    if (wasPrimary && root.localConfig.length > 0)
      root.localConfig[0].primary = true;
    root.selectedBarIndex = Math.max(0, Math.min(root.selectedBarIndex, root.localConfig.length - 1));
    applyChanges();
  }

  function setPrimary(index) {
    root.localConfig.forEach((bar, i) => bar.primary = (i === index));
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
    bar.widgets[zone].push({
      "type": widgetType
    });
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

  // Merge the sandboxed Bar array onto the LATEST real config (avoids
  // clobbering unrelated settings edited elsewhere meanwhile), then apply
  // and persist atomically - there's no meaningful "apply without saving"
  // step for this sandboxed flow.
  function saveChanges() {
    const merged = JSON.parse(JSON.stringify(ConfigManager.config));
    merged.Bar = JSON.parse(JSON.stringify(root.localConfig));
    ConfigManager.applyConfig(merged);
    ConfigManager.saveConfig();
    root._savedConfig = JSON.parse(JSON.stringify(root.localConfig));
    root.isDirty = false;
  }

  // Discard sandbox edits, reload fresh from the current real config.
  function resetChanges() {
    loadConfig();
  }
}
