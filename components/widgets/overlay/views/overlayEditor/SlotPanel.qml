pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.common
import qs.components.widgets.overlay

// The slot selected in the preview: which module it holds, and that
// module's properties (rows generated from its schema, as in the bar
// editor's WidgetItemDelegate)
Item {

  PanelCard {
    title: "Slot"
    showActions: false

    StyledText {
      visible: !form.sel
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      text: "Click a slot in the preview to choose its module."
      opacity: 0.6
    }

    // Acts as the `form` for its SchemaField rows (valueAt + edited)
    ColumnLayout {
      id: form
      visible: form.sel !== null
      Layout.fillWidth: true
      spacing: Widget.spacing * 2

      readonly property var sel: OverlayManager.selectedSlot
      readonly property var module: form.sel ? OverlayManager.slotModule(form.sel.column, form.sel.cell, form.sel.slot) : null
      // The slot's rect in its cell's layout, and so its shape
      readonly property var rect: {
        if (!form.sel)
          return null;
        const cell = OverlayManager.selectedView()?.columns?.[form.sel.column]?.cells?.[form.sel.cell];
        return OverlayConfig.layouts[cell?.layout]?.slots?.[form.sel.slot] ?? null;
      }
      readonly property string shape: form.rect ? OverlayConfig.slotShape(form.rect) : ""
      readonly property bool fits: !form.moduleType || !form.rect || OverlayConfig.fits(form.moduleType, form.rect)
      // Modules that fit this slot (plus the current one, even if it doesn't)
      readonly property var moduleOptions: ["None", ...OverlayConfig.availableModuleTypes.filter(t => t.shapes.includes(form.shape) || t.type === form.moduleType).map(t => t.type)]
      // A string, so property edits don't rebuild the rows
      readonly property string moduleType: form.module?.type ?? ""
      readonly property var propertiesSchema: OverlayConfig.availableModuleTypes.find(t => t.type === form.moduleType)?.propertiesSchema ?? ({})
      readonly property var rows: Object.keys(form.propertiesSchema).map(key => ({
            "kind": "field",
            "title": form.propertiesSchema[key].title ?? key,
            "path": [key],
            "schema": form.propertiesSchema[key]
          }))

      signal edited(var path, var value)
      onEdited: (path, value) => OverlayManager.updateModuleProperty(form.sel.column, form.sel.cell, form.sel.slot, path[0], value)

      function valueAt(path) {
        return form.module?.properties?.[path[0]] ?? form.propertiesSchema[path[0]]?.default;
      }

      // `x-showIf: { sibling: value | [values] | { not: value } }`
      function isShown(fieldSchema) {
        const condition = fieldSchema["x-showIf"];
        if (!condition)
          return true;
        return Object.keys(condition).every(key => {
          const want = condition[key];
          const value = form.valueAt([key]);
          if (Array.isArray(want))
            return want.includes(value);
          if (want !== null && typeof want === "object")
            return value !== want.not;
          return value === want;
        });
      }

      StyledText {
        text: form.sel ? `Column ${form.sel.column + 1} · cell ${form.sel.cell + 1} · ${form.sel.slot} (${form.shape})` : ""
        opacity: 0.6
      }

      SchemaComboBox {
        label: "Module"
        description: `Showing modules that fit a ${form.shape} slot.`
        options: form.moduleOptions
        currentValue: form.moduleType || "None"
        onSelectionChanged: value => OverlayManager.setSlotModule(form.sel.column, form.sel.cell, form.sel.slot, value === "None" ? "" : value)
      }

      StyledText {
        visible: !form.fits
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: `${form.moduleType} doesn't fit a ${form.shape} slot: pick another module or change the cell's layout.`
        textColor: Theme.error
      }

      Repeater {
        model: form.rows

        delegate: SchemaField {
          required property var modelData
          row: modelData
          form: form
          visible: form.isShown(modelData.schema)
        }
      }
    }
  }
}
