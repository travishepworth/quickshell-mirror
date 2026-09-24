pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.forms
import qs.components.content.base

// The slot selected in the preview: which module it holds, and that
// module's properties (rows generated from its schema, as in the bar
// editor's WidgetItemDelegate)
Item {

  PanelCard {
    title: I18n.tr("Slot")
    showActions: false

    StyledText {
      visible: !form.sel
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      text: I18n.tr("Click a slot in the preview to choose its module.")
      opacity: 0.6
    }

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
      // Shapes and slot names are shown translated. Dynamic keys, declared for
      // scripts/check_i18n.py: I18n.tr("square") I18n.tr("horizontal") I18n.tr("vertical")
      // I18n.tr("main") I18n.tr("topLeft") I18n.tr("topRight") I18n.tr("bottomLeft")
      // I18n.tr("bottomRight") I18n.tr("top") I18n.tr("bottom") I18n.tr("left") I18n.tr("right")
      readonly property string shape: form.rect ? OverlayConfig.slotShape(form.rect) : ""
      readonly property bool fits: !form.moduleType || !form.rect || OverlayConfig.fits(form.moduleType, form.rect)
      // Modules that fit this slot (plus the current one, even if it doesn't)
      readonly property var moduleOptions: ["None", ...OverlayConfig.availableModuleTypes.filter(t => t.shapes.includes(form.shape) || t.type === form.moduleType).map(t => t.type)]
      // A string, so property edits don't rebuild the rows
      readonly property string moduleType: form.module?.type ?? ""
      readonly property var propertiesSchema: OverlayConfig.availableModuleTypes.find(t => t.type === form.moduleType)?.propertiesSchema ?? ({})
      StyledText {
        text: form.sel ? I18n.tr("Column {0} · cell {1} · {2} ({3})", form.sel.column + 1, form.sel.cell + 1, I18n.tr(form.sel.slot), I18n.tr(form.shape)) : ""
        opacity: 0.6
      }

      SchemaComboBox {
        label: I18n.tr("Module")
        description: I18n.tr("Showing modules that fit a {0} slot.", I18n.tr(form.shape))
        options: form.moduleOptions
        // Module names (their schema descriptions), translated
        optionLabels: OverlayConfig.availableModuleTypes.reduce((labels, t) => {
          labels[t.type] = I18n.tr(t.label);
          return labels;
        }, {
          "None": I18n.tr("None")
        })
        currentValue: form.moduleType || "None"
        onSelectionChanged: value => OverlayManager.setSlotModule(form.sel.column, form.sel.cell, form.sel.slot, value === "None" ? "" : value)
      }

      StyledText {
        visible: !form.fits
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: I18n.tr("{0} doesn't fit a {1} slot: pick another module or change the cell's layout.", form.moduleType, I18n.tr(form.shape))
        textColor: Theme.error
      }

      SchemaPropertiesForm {
        Layout.fillWidth: true
        spacing: Widget.spacing * 2
        propertiesSchema: form.propertiesSchema
        values: form.module?.properties ?? ({})
        onEdited: (path, value) => OverlayManager.updateModuleProperty(form.sel.column, form.sel.cell, form.sel.slot, path[0], value)
      }
    }
  }
}
