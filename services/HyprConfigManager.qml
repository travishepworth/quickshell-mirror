pragma Singleton
import QtQuick

import Quickshell.Io
import Quickshell.Hyprland

/*
 * HyprConfigManager reads the keybinds Hyprland has registered (`hyprctl binds -j`).
 * With the Lua config every action is an opaque `__lua` dispatcher, so each bind's
 * `description` option is the label. A "Section: Label" prefix picks the overlay section.
 */
QtObject {
  id: root

  // [{ title, binds: [{ label, combos: [{ mods: ["SUPER", "SHIFT"], key: "H" }] }] }]
  property var keybindings: []

  readonly property var _modifiers: [
    {
      name: "SUPER",
      mask: 64
    },
    {
      name: "CTRL",
      mask: 4
    },
    {
      name: "ALT",
      mask: 8
    },
    {
      name: "SHIFT",
      mask: 1
    },
    {
      name: "MOD2",
      mask: 16
    },
    {
      name: "MOD3",
      mask: 32
    },
    {
      name: "MOD5",
      mask: 128
    },
    {
      name: "CAPS",
      mask: 2
    },
  ]

  readonly property var _keyNames: ({
      "mouse:272": "LMB",
      "mouse:273": "RMB",
      "mouse:274": "MMB",
      "mouse_up": "Scroll ↑",
      "mouse_down": "Scroll ↓",
      "left": "←",
      "right": "→",
      "up": "↑",
      "down": "↓"
    })

  function refresh() {
    root._bindsProcess.running = true;
  }

  function _buildKeybindings(entries) {
    const sections = [];
    const sectionByTitle = {};
    const rowByKey = {};
    let undescribed = null;

    for (const entry of entries) {
      const description = (entry.description || "").trim();
      const split = description.indexOf(": ");
      let title;
      let label;

      if (!description) {
        title = "Undescribed";
        label = "";
      } else if (split > 0) {
        title = description.slice(0, split).trim();
        label = description.slice(split + 2).trim();
      } else {
        title = entry.submap || "Other";
        label = description;
      }

      let section = sectionByTitle[title];
      if (!section) {
        section = {
          title: title,
          binds: []
        };
        sectionByTitle[title] = section;
        if (title === "Undescribed")
          undescribed = section;
        else
          sections.push(section);
      }

      const combo = {
        mods: root._decodeMods(entry.modmask),
        key: root._formatKey(entry.key)
      };
      const rowKey = `${title}\u0000${label}`;

      // Undescribed binds each get their own row, since they share an empty label.
      if (label && rowByKey[rowKey]) {
        rowByKey[rowKey].combos.push(combo);
        continue;
      }
      const row = {
        label: label,
        combos: [combo]
      };
      rowByKey[rowKey] = row;
      section.binds.push(row);
    }

    if (undescribed)
      sections.push(undescribed);
    return sections;
  }

  function _decodeMods(modmask) {
    return root._modifiers.filter(m => (modmask & m.mask) !== 0).map(m => m.name);
  }

  function _formatKey(key) {
    if (root._keyNames[key] !== undefined)
      return root._keyNames[key];
    if (key.startsWith("XF86"))
      return key.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
    if (key.length === 1)
      return key.toUpperCase();
    return key.charAt(0).toUpperCase() + key.slice(1);
  }

  property Process _bindsProcess: Process {
    command: ["hyprctl", "binds", "-j"]

    stdout: StdioCollector {
      id: bindsCollector

      onStreamFinished: {
        try {
          root.keybindings = root._buildKeybindings(JSON.parse(bindsCollector.text));
        } catch (e) {
          console.error("HyprConfigManager: could not parse hyprctl binds:", e);
        }
      }
    }
  }

  property Connections _hyprlandEvents: Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "configreloaded")
        root.refresh();
    }
  }

  Component.onCompleted: refresh()
}
