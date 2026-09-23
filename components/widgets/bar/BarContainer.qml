pragma ComponentBehavior: Bound

import QtQuick

import qs.config

// Lays out a bar's five widget sections along its main axis in one pass,
// so they can never overlap: `left`/`right` hug the ends, `center` stays
// centered on the bar with `leftCenter`/`rightCenter` beside it. When the
// side sections crowd it, the center block slides towards the roomier side;
// then elastic widgets shrink, and if even their minimum sizes don't fit,
// the lowest-priority widgets anywhere on the bar are hidden (see
// WidgetGroup for how a section fits itself into what it's given).
Rectangle {
  id: root

  required property var barConfig
  property var screen
  property var popouts
  property var panel

  property color backgroundColor: Theme.background
  property color foregroundColor: Theme.foreground

  readonly property bool isVertical: barConfig.vertical
  readonly property real length: isVertical ? height : width

  // Emitted whenever widgets may have moved, so an open popout can follow
  // its anchor
  signal layoutUpdated

  color: backgroundColor

  readonly property var _groups: [leftGroup, leftCenterGroup, centerGroup, rightCenterGroup, rightGroup]
  // Per section, the model indices hidden so the minimum sizes fit
  readonly property var hidden: root.overflowHidden(root._groups.map(g => g.measures), root.length, Appearance.screenMargin, Appearance.screenMargin, root.barConfig.spacing)
  readonly property var slots: root.layoutSections(root._groups.map(g => g.preferredLength), root._groups.map(g => g.minimumLength), root.length, Appearance.screenMargin, Appearance.screenMargin)
  // Bindings re-run on any module change; only signal real moves
  property string _slotsKey: ""
  onSlotsChanged: {
    const key = JSON.stringify(slots);
    if (key !== _slotsKey) {
      _slotsKey = key;
      layoutUpdated();
    }
  }

  // Sections are [left, leftCenter, center, rightCenter, right]; returns
  // [{offset, extent}] for each along the main axis. `margin` is kept clear
  // at both ends and `gap` between adjacent non-empty sections.
  function layoutSections(pref, min, length, margin, gap) {
    const sum = values => values.reduce((a, b) => a + b, 0);
    const gaps = gap * [0, 1, 3, 4].filter(i => pref[i] > 0).length;
    const room = Math.max(0, length - 2 * margin - gaps);

    let size;
    const sumPref = sum(pref);
    const sumMin = sum(min);
    if (sumPref <= room) {
      size = pref.slice();
    } else if (sumMin <= room) {
      const squeeze = (sumPref - room) / (sumPref - sumMin);
      size = pref.map((p, i) => p - (p - min[i]) * squeeze);
    } else {
      size = min.map(m => sumMin > 0 ? m * room / sumMin : 0);
    }

    const [l, lc, c, rc, r] = size;
    const before = lc > 0 ? lc + gap : 0;
    const after = rc > 0 ? rc + gap : 0;
    const lo = margin + (l > 0 ? l + gap : 0) + before;
    const hi = length - margin - (r > 0 ? r + gap : 0) - after - c;
    const centerStart = Math.max(lo, Math.min((length - c) / 2, hi));

    return [
      {
        "offset": margin,
        "extent": l
      },
      {
        "offset": centerStart - before,
        "extent": lc
      },
      {
        "offset": centerStart,
        "extent": c
      },
      {
        "offset": centerStart + c + (rc > 0 ? gap : 0),
        "extent": rc
      },
      {
        "offset": length - margin - r,
        "extent": r
      }
    ];
  }

  // measures: per section, [{pref, min, priority}]. Hides the
  // lowest-priority widgets until every section's minimum length, plus
  // margins and gaps as in layoutSections, fits the bar. Ties go to the
  // outer sections first and the center last, and within a section to the
  // widget listed last.
  function overflowHidden(measures, length, margin, gap, spacing) {
    const hidden = measures.map(() => []);
    const span = s => {
      const shown = measures[s].filter((m, i) => m.pref > 0 && !hidden[s].includes(i)).map(m => m.min);
      return shown.reduce((a, b) => a + b, 0) + Math.max(0, shown.length - 1) * spacing;
    };
    const needed = () => {
      const spans = measures.map((m, s) => span(s));
      return spans.reduce((a, b) => a + b, 0) + gap * [0, 1, 3, 4].filter(s => spans[s] > 0).length;
    };
    const room = length - 2 * margin + 0.5;
    const order = [4, 0, 3, 1, 2];
    const dropped = [];
    while (length > 0 && needed() > room) {
      let drop = null;
      order.forEach(s => {
        for (let i = measures[s].length - 1; i >= 0; i--) {
          const m = measures[s][i];
          if (m.pref > 0 && !hidden[s].includes(i) && (!drop || m.priority < drop.priority))
            drop = {
              "section": s,
              "index": i,
              "priority": m.priority
            };
        }
      });
      if (!drop)
        break;
      hidden[drop.section].push(drop.index);
      dropped.push(drop);
    }
    // Hiding a big widget can free more room than was missing; bring back
    // whatever still fits, most important (last dropped) first
    for (let d = dropped.length - 1; d >= 0; d--) {
      const list = hidden[dropped[d].section];
      list.splice(list.indexOf(dropped[d].index), 1);
      if (needed() > room)
        list.push(dropped[d].index);
    }
    return hidden;
  }

  function widgetModel(widgetConfigArray) {
    return (widgetConfigArray || []).filter(widgetConf => widgetConf.visible !== false).map(widgetConf => ({
          "component": "modules/" + widgetConf.type + ".qml",
          "properties": widgetConf.properties || {},
          "layout": widgetConf.layout || {}
        }));
  }

  // A section: the group sits inside its slot at `align` (0 = start,
  // 1 = end), which only matters once hidden modules leave it spare room.
  // Inline components can't see this file's ids, hence `bar`.
  component Section: WidgetGroup {
    id: section
    required property Item bar
    required property int slotIndex
    required property real align

    readonly property var slot: section.bar.slots[section.slotIndex]
    readonly property real mainPos: Math.round(section.slot.offset + (section.slot.extent - section.usedLength) * section.align)

    barConfig: section.bar.barConfig
    popouts: section.bar.popouts
    panel: section.bar.panel
    screen: section.bar.screen
    maxExtent: section.slot.extent
    hiddenIndices: section.bar.hidden[section.slotIndex]

    x: section.bar.isVertical ? Math.round((section.bar.width - width) / 2) : section.mainPos
    y: section.bar.isVertical ? section.mainPos : Math.round((section.bar.height - height) / 2)

    onAllocationUpdated: section.bar.layoutUpdated()
  }

  Section {
    id: leftGroup
    bar: root
    slotIndex: 0
    align: 0
    model: root.widgetModel(root.barConfig.widgets?.left)
  }

  Section {
    id: leftCenterGroup
    bar: root
    slotIndex: 1
    align: 1
    model: root.widgetModel(root.barConfig.widgets?.leftCenter)
  }

  Section {
    id: centerGroup
    bar: root
    slotIndex: 2
    align: 0.5
    model: root.widgetModel(root.barConfig.widgets?.center)
  }

  Section {
    id: rightCenterGroup
    bar: root
    slotIndex: 3
    align: 0
    model: root.widgetModel(root.barConfig.widgets?.rightCenter)
  }

  Section {
    id: rightGroup
    bar: root
    slotIndex: 4
    align: 1
    model: root.widgetModel(root.barConfig.widgets?.right)
  }
}
