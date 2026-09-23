pragma Singleton
import QtQuick
import qs.services

// Overlay: the configured views, plus the card grid's layout constants.
// (Named OverlayConfig because `Overlay` is the module type.)
QtObject {
  readonly property var views: ConfigManager.config.Overlay.views

  // What the overlay editor offers, read from the schema's oneOfs so new
  // module/view types show up there automatically
  function _oneOfTypes(definition) {
    const schema = ConfigManager.configSchema;
    return (schema?.definitions?.[definition]?.oneOf ?? []).map(option => {
      const def = schema.definitions[option.$ref.replace("#/definitions/", "")];
      const type = def?.properties?.type;
      if (!type?.const)
        return null;
      return {
        "type": type.const,
        "label": type.description || type.const,
        "propertiesSchema": def.properties?.properties?.properties ?? null,
        // Slot shapes a module fits (`x-shapes`); views don't declare any
        "shapes": def["x-shapes"] ?? ["square", "horizontal", "vertical"]
      };
    }).filter(t => t !== null);
  }
  readonly property var availableModuleTypes: _oneOfTypes("OverlayModule")
  readonly property var availableViewTypes: _oneOfTypes("OverlayView")

  // Card grid layout — internal design constants, not user settings.
  // Card radius/border follow Appearance so the overlay matches the shell.
  readonly property int cardUnit: 500
  readonly property int cardSpacing: 20
  readonly property int cardPadding: 12

  // Cells are laid out on a grid of half cards: a span of n half units is
  // n halves plus the n - 1 gaps between them, so span(2) is one card and
  // span(4) is two cards plus the gap between them.
  readonly property real halfUnit: (cardUnit - cardSpacing) / 2
  function span(n) {
    return n * halfUnit + (n - 1) * cardSpacing;
  }

  // A slot's shape, from its [col, row, colSpan, rowSpan] rect
  function slotShape(rect) {
    return rect[2] === rect[3] ? "square" : rect[2] > rect[3] ? "horizontal" : "vertical";
  }

  // Whether a module type may sit in a slot of the given rect
  function fits(type, rect) {
    const info = availableModuleTypes.find(t => t.type === type);
    return !info || info.shapes.includes(slotShape(rect));
  }

  // How a column flows its cells: left to right, wrapping at the widest
  // cell. Returns the unscaled size and the number of rows, matching the
  // Flow in OverlayColumn.
  function columnFlow(cells) {
    const sizes = (cells ?? []).map(cell => {
      const layout = layouts[cell.layout] ?? layouts.Single;
      return [span(layout.cols), span(layout.rows)];
    });
    const width = Math.max(0, ...sizes.map(size => size[0]));
    let x = 0, rowHeight = 0, height = 0, rows = 0;
    sizes.forEach(([w, h]) => {
      if (x > 0 && x + w > width + 0.5) {
        height += rowHeight + cardSpacing;
        x = 0;
        rowHeight = 0;
      }
      if (x === 0)
        rows++;
      x += w + cardSpacing;
      rowHeight = Math.max(rowHeight, h);
    });
    return {
      "width": width,
      "height": height + rowHeight,
      "rows": rows
    };
  }

  // Cell layouts, keyed by the `layout` name in config (keep in sync with
  // the OverlayCell enum in the schema). cols/rows are the cell's size in
  // half units; each slot is [col, row, colSpan, rowSpan] in half units.
  readonly property var layouts: ({
      "Single": {
        "cols": 2,
        "rows": 2,
        "slots": {
          "main": [0, 0, 2, 2]
        }
      },
      "Tall": {
        "cols": 2,
        "rows": 4,
        "slots": {
          "main": [0, 0, 2, 4]
        }
      },
      "Wide": {
        "cols": 4,
        "rows": 2,
        "slots": {
          "main": [0, 0, 4, 2]
        }
      },
      "Large": {
        "cols": 4,
        "rows": 4,
        "slots": {
          "main": [0, 0, 4, 4]
        }
      },
      "Grid2x2": {
        "cols": 2,
        "rows": 2,
        "slots": {
          "topLeft": [0, 0, 1, 1],
          "topRight": [1, 0, 1, 1],
          "bottomLeft": [0, 1, 1, 1],
          "bottomRight": [1, 1, 1, 1]
        }
      },
      "Vert1x1": {
        "cols": 2,
        "rows": 2,
        "slots": {
          "left": [0, 0, 1, 2],
          "right": [1, 0, 1, 2]
        }
      },
      "Vert1x2": {
        "cols": 2,
        "rows": 2,
        "slots": {
          "left": [0, 0, 1, 2],
          "topRight": [1, 0, 1, 1],
          "bottomRight": [1, 1, 1, 1]
        }
      },
      "Vert2x1": {
        "cols": 2,
        "rows": 2,
        "slots": {
          "topLeft": [0, 0, 1, 1],
          "bottomLeft": [0, 1, 1, 1],
          "right": [1, 0, 1, 2]
        }
      },
      "Horiz1x1": {
        "cols": 2,
        "rows": 2,
        "slots": {
          "top": [0, 0, 2, 1],
          "bottom": [0, 1, 2, 1]
        }
      },
      "Horiz1x2": {
        "cols": 2,
        "rows": 2,
        "slots": {
          "top": [0, 0, 2, 1],
          "bottomLeft": [0, 1, 1, 1],
          "bottomRight": [1, 1, 1, 1]
        }
      },
      "Horiz2x1": {
        "cols": 2,
        "rows": 2,
        "slots": {
          "topLeft": [0, 0, 1, 1],
          "topRight": [1, 0, 1, 1],
          "bottom": [0, 1, 2, 1]
        }
      }
    })
}
