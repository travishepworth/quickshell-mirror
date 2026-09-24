pragma Singleton
import QtQuick

import Quickshell.Io
import Quickshell.Hyprland

/*
 * KeybindManager reads the keybinds Hyprland has registered (`hyprctl binds -j`).
 * With the Lua config every action is an opaque `__lua` dispatcher, so each bind's
 * `description` option is the label. A "Section: Label" prefix picks the overlay section.
 */
QtObject {
  id: root

  // [{ title, undescribed, binds: [{ label, combos: [{ mods: ["SUPER", "SHIFT"], keys: ["H", "←"] }] }] }]
  // `title` is "" for binds with no section (shown as "Other"); `undescribed`
  // marks the section of binds without a description (label "").
  property var keybindings: []
  // How many binds Hyprland reported
  property int count: 0
  // The Keybinds page's search, here so it survives the page reloading
  property string query: ""

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
        title = null;
        label = "";
      } else if (split > 0) {
        title = description.slice(0, split).trim();
        label = description.slice(split + 2).trim();
      } else {
        title = entry.submap || "";
        label = description;
      }

      let section = title === null ? undescribed : sectionByTitle[title];
      if (!section) {
        section = {
          title: title ?? "",
          undescribed: title === null,
          binds: []
        };
        if (title === null)
          undescribed = section;
        else {
          sectionByTitle[title] = section;
          sections.push(section);
        }
      }

      const mods = root._decodeMods(entry.modmask);
      const key = root._formatKey(entry.key);
      const rowKey = `${section.title}\u0000${label}`;

      // Undescribed binds each get their own row, since they share an empty label.
      // Alternatives with the same modifiers share a combo: Super + H / ←.
      const row = label ? rowByKey[rowKey] : undefined;
      if (row) {
        const combo = row.combos.find(c => c.mods.join("+") === mods.join("+"));
        if (!combo)
          row.combos.push({
            mods: mods,
            keys: [key]
          });
        else if (!combo.keys.includes(key))
          combo.keys.push(key);
        continue;
      }
      const newRow = {
        label: label,
        combos: [
          {
            mods: mods,
            keys: [key]
          }
        ]
      };
      if (label)
        rowByKey[rowKey] = newRow;
      section.binds.push(newRow);
    }

    if (undescribed)
      sections.push(undescribed);
    for (const section of sections)
      section.binds = root._collapseNumbered(section.binds);
    return sections;
  }

  // Rows like "Go to workspace 1" … "Go to workspace 5", each bound to its
  // own number key with the same modifiers, become one "Go to workspace" row
  // with the key "1–5" (or "1 2 4" when the numbers have gaps).
  function _collapseNumbered(binds) {
    const runs = {};
    for (const row of binds) {
      const match = row.label.match(/^(.*\S)\s+(\d+)$/);
      const combo = row.combos[0];
      if (!match || row.combos.length !== 1 || combo.keys.length !== 1 || combo.keys[0] !== match[2])
        continue;
      const runKey = `${match[1]}\u0000${combo.mods.join("+")}`;
      if (!runs[runKey])
        runs[runKey] = {
          label: match[1],
          mods: combo.mods,
          rows: [],
          numbers: []
        };
      runs[runKey].rows.push(row);
      runs[runKey].numbers.push(parseInt(match[2]));
    }

    const result = [];
    const placed = {};
    for (const row of binds) {
      const runKey = Object.keys(runs).find(k => runs[k].rows.length > 1 && runs[k].rows.includes(row));
      if (runKey === undefined) {
        result.push(row);
        continue;
      }
      if (placed[runKey])
        continue;
      placed[runKey] = true;
      const run = runs[runKey];
      const numbers = run.numbers.slice().sort((a, b) => a - b);
      const contiguous = numbers.every((n, i) => i === 0 || n === numbers[i - 1] + 1);
      result.push({
        label: run.label,
        combos: [
          {
            mods: run.mods,
            keys: contiguous ? [`${numbers[0]}–${numbers[numbers.length - 1]}`] : numbers.map(String)
          }
        ]
      });
    }
    return result;
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
          const entries = JSON.parse(bindsCollector.text);
          root.keybindings = root._buildKeybindings(entries);
          root.count = entries.length;
        } catch (e) {
          console.error("KeybindManager: could not parse hyprctl binds:", e);
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
