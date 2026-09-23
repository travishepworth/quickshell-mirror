pragma Singleton
import QtQuick

import qs.config
import qs.components.methods
import qs.services

/* OverlayManager holds a sandboxed, in-memory copy of Overlay.views for the
 * overlay editor (the pinned last page). Edits only affect localViews (and
 * the editor's preview) - the real overlay pages and config.json are
 * untouched until saveChanges(). Mirrors BarManager. */
QtObject {
  id: root

  property var localViews: []
  property var _savedViews: []
  property bool isDirty: false
  property int selectedViewIndex: 0
  // { column, cell, slot } of the slot being edited, or null
  property var selectedSlot: null

  // Why the sandbox can't be saved as is (empty = savable)
  readonly property var problems: {
    const out = [];
    root.localViews.forEach((view, v) => {
      if (view.type !== "Custom")
        return;
      const name = view.name || `View ${v + 1}`;
      if (!view.columns || view.columns.length === 0)
        out.push(`${name} has no columns`);
      else
        view.columns.forEach((column, c) => {
          if (!column.cells || column.cells.length === 0)
            out.push(`${name}: column ${c + 1} has no cells`);
          (column.cells ?? []).forEach(cell => {
            const slots = OverlayConfig.layouts[cell.layout]?.slots ?? {};
            Object.keys(cell.slots ?? {}).forEach(slot => {
              const type = cell.slots[slot]?.type;
              if (type && slots[slot] && !OverlayConfig.fits(type, slots[slot]))
                out.push(`${name}: ${type} doesn't fit a ${OverlayConfig.slotShape(slots[slot])} slot`);
            });
          });
        });
    });
    return out;
  }

  Component.onCompleted: {
    loadConfig();
  }

  function loadConfig() {
    localViews = JSON.parse(JSON.stringify(ConfigManager.config.Overlay.views));
    _savedViews = JSON.parse(JSON.stringify(ConfigManager.config.Overlay.views));
    selectedViewIndex = Math.max(0, Math.min(selectedViewIndex, localViews.length - 1));
    selectedSlot = null;
    isDirty = false;
  }

  function markDirty() {
    root.isDirty = JSON.stringify(root.localViews) !== JSON.stringify(root._savedViews);
  }

  // Call after mutating localViews in place. The re-clone is deferred for
  // the same binding-loop reason as BarManager.applyChanges.
  function applyChanges() {
    markDirty();
    Qt.callLater(root._refreshLocalViews);
  }

  function _refreshLocalViews() {
    root.localViews = JSON.parse(JSON.stringify(root.localViews));
  }

  function _defaults(value, definition) {
    return SchemaValidation.applyDefaults(value, {
      "$ref": "#/definitions/" + definition
    }, ConfigManager.configSchema);
  }

  function _move(arr, from, delta) {
    const to = from + delta;
    if (!arr || from < 0 || from >= arr.length || to < 0 || to >= arr.length)
      return false;
    const [item] = arr.splice(from, 1);
    arr.splice(to, 0, item);
    return true;
  }

  // --- Views ---

  function selectedView() {
    return root.localViews[root.selectedViewIndex] || null;
  }

  function selectView(index) {
    root.selectedViewIndex = index;
    root.selectedSlot = null;
  }

  function _newCell() {
    return {
      "layout": "Single",
      "slots": {}
    };
  }

  function addView(type) {
    const view = type === "Custom" ? {
      "type": "Custom",
      "name": "View " + (root.localViews.length + 1),
      "columns": [
        {
          "cells": [root._newCell()]
        }
      ]
    } : {
      "type": type
    };
    root.localViews.push(root._defaults(view, "OverlayView"));
    root.selectView(root.localViews.length - 1);
    applyChanges();
  }

  function removeView(index) {
    root.localViews.splice(index, 1);
    root.selectView(Math.max(0, Math.min(root.selectedViewIndex, root.localViews.length - 1)));
    applyChanges();
  }

  function moveView(index, delta) {
    if (!root._move(root.localViews, index, delta))
      return;
    root.selectView(index + delta);
    applyChanges();
  }

  function renameView(index, name) {
    const view = root.localViews[index];
    if (!view || view.name === name)
      return;
    view.name = name;
    applyChanges();
  }

  // --- Columns (of the selected view) ---

  function _columns() {
    return root.selectedView()?.columns ?? null;
  }

  function addColumn() {
    const columns = root._columns();
    if (!columns)
      return;
    columns.push({
      "cells": [root._newCell()]
    });
    applyChanges();
  }

  function removeColumn(c) {
    root._columns()?.splice(c, 1);
    root.selectedSlot = null;
    applyChanges();
  }

  function moveColumn(c, delta) {
    if (!root._move(root._columns(), c, delta))
      return;
    root.selectedSlot = null;
    applyChanges();
  }

  // --- Cells ---

  function _cell(c, k) {
    return root._columns()?.[c]?.cells?.[k] ?? null;
  }

  function addCell(c) {
    root._columns()?.[c]?.cells.push(root._newCell());
    applyChanges();
  }

  function removeCell(c, k) {
    root._columns()?.[c]?.cells.splice(k, 1);
    root.selectedSlot = null;
    applyChanges();
  }

  function moveCell(c, k, delta) {
    if (!root._move(root._columns()?.[c]?.cells, k, delta))
      return;
    root.selectedSlot = null;
    applyChanges();
  }

  // Keeps the modules in slots the new layout also has
  function setCellLayout(c, k, layout) {
    const cell = root._cell(c, k);
    const slotNames = Object.keys(OverlayConfig.layouts[layout]?.slots ?? {});
    if (!cell || cell.layout === layout || slotNames.length === 0)
      return;
    cell.layout = layout;
    const kept = {};
    slotNames.forEach(name => {
      if (cell.slots?.[name])
        kept[name] = cell.slots[name];
    });
    cell.slots = kept;
    root.selectedSlot = null;
    applyChanges();
  }

  // --- Slots ---

  function selectSlot(c, k, slot) {
    root.selectedSlot = {
      "column": c,
      "cell": k,
      "slot": slot
    };
  }

  function slotModule(c, k, slot) {
    return root._cell(c, k)?.slots?.[slot] ?? null;
  }

  // An empty type clears the slot; a new module starts at its schema defaults
  function setSlotModule(c, k, slot, type) {
    const cell = root._cell(c, k);
    if (!cell || (cell.slots?.[slot]?.type ?? "") === type)
      return;
    if (!cell.slots)
      cell.slots = {};
    if (type)
      cell.slots[slot] = root._defaults({
        "type": type
      }, "OverlayModule");
    else
      delete cell.slots[slot];
    applyChanges();
  }

  function updateModuleProperty(c, k, slot, key, value) {
    const module = root.slotModule(c, k, slot);
    if (!module)
      return;
    if (!module.properties)
      module.properties = {};
    module.properties[key] = value;
    applyChanges();
  }

  // --- Save / reset ---

  // Merges onto the LATEST real config, as BarManager.saveChanges does
  function saveChanges() {
    if (root.problems.length > 0)
      return;
    const merged = JSON.parse(JSON.stringify(ConfigManager.config));
    merged.Overlay.views = JSON.parse(JSON.stringify(root.localViews));
    if (!ConfigManager.commit(merged))
      return;
    root._savedViews = JSON.parse(JSON.stringify(root.localViews));
    root.isDirty = false;
  }

  function resetChanges() {
    loadConfig();
  }
}
