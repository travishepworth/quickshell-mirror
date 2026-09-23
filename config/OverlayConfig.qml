pragma Singleton
import QtQuick
import qs.services

// Overlay: the configured views, plus the card grid's layout constants.
// (Named OverlayConfig because `Overlay` is the module type.)
QtObject {
  readonly property var views: ConfigManager.config.Overlay.views

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
