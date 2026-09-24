pragma ComponentBehavior: Bound
import QtQuick

// The Themes page: wallpapers, the theme list and the palette's 16 colors.
// Pinned by OverlayPages before the overlay editor, not part of config;
// laid out by Custom from the fixed columns below.
Custom {
  id: root

  function swatches(first) {
    const labels = ["bg0", "bg1", "bg2", "bg3", "fg4", "fg3", "fg2", "fg1", "error", "warning", "info", "success", "accentAlt", "accentHighlight", "accent", "decorative"];
    const slots = ["topLeft", "topRight", "bottomLeft", "bottomRight"];
    return {
      "layout": "Grid2x2",
      "slots": slots.reduce((cell, slot, i) => {
        const n = first + i;
        cell[slot] = {
          "type": "ColorSwatch",
          "properties": {
            "color": "base0" + n.toString(16).toUpperCase(),
            "label": labels[n]
          }
        };
        return cell;
      }, {})
    };
  }

  viewConfig: ({
      "columns": [
        {
          "cells": [
            {
              "layout": "Tall",
              "slots": {
                "main": {
                  "type": "WallpaperPicker"
                }
              }
            }
          ]
        },
        {
          "cells": [
            {
              "layout": "Tall",
              "slots": {
                "main": {
                  "type": "ThemeEditor"
                }
              }
            }
          ]
        },
        {
          "cells": [root.swatches(0), root.swatches(4)]
        },
        {
          "cells": [root.swatches(8), root.swatches(12)]
        }
      ]
    })
}
