pragma Singleton
import QtQuick

QtObject {
  id: ring

  enum Position {
    Upper,
    Center,
    Lower,
    CenterAndUpper,
    CenterAndLower,
    UpperAndLower,
    None,
    Full
  }

  readonly property int _Upper: 0
  readonly property int _Center: 1
  readonly property int _Lower: 2
  readonly property int _CenterAndUpper: 3
  readonly property int _CenterAndLower: 4
  readonly property int _UpperAndLower: 5
  readonly property int _None: 6
  readonly property int _Full: 7

  // Tunable radius (lowercase!)
  readonly property int radius: 5

  // Bitmask flags (lowercase!)
  readonly property int bitCenter: 1
  readonly property int bitLower: 2
  readonly property int bitUpper: 4

  // State
  property var occ: ({})     // { [id]: true }
  property var masks: ({})   // { [id]: bitmask }

  signal maskChanged(int id, int mask)

  // ---------- Public API ----------

  function positionFor(id) {
    const m = masks[id] || 0;
    const c = (m & bitCenter) !== 0;
    const l = (m & bitLower)  !== 0;
    const u = (m & bitUpper)  !== 0;

    if (c && u && l) return _Full;
    if (!c && u && l) return _UpperAndLower;
    if (c && u)       return _CenterAndUpper;
    if (c && l)       return _CenterAndLower;
    if (u)            return _Upper;
    if (l)            return _Lower;
    if (c)            return _Center;
    return _None;
  }

  function iconFor(id) {
    switch (positionFor(id)) {
      case _Full:           return "●↕";
      case _UpperAndLower:  return "↕";
      case _CenterAndUpper: return "●↑";
      case _CenterAndLower: return "●↓";
      case _Upper:          return "↑";
      case _Lower:          return "↓";
      case _Center:         return "●";
      default:                      return "";
    }
  }

  function ringFor(id) {
    const lowers = [];
    const uppers = [];
    for (let d = 1; d <= radius; d++) {
      if (occ[id - d]) lowers.push(id - d);
      if (occ[id + d]) uppers.push(id + d);
    }
    return { center: !!occ[id], lowers, uppers };
  }

  // ---------- Mutations ----------

  function setOccupiedIds(ids) {
    const old = occ;
    occ = {};
    for (let i = 0; i < ids.length; i++) occ[ids[i]] = true;

    const touched = _changedCenters(old, occ);
    for (let j = 0; j < touched.length; j++) _recalcAround(touched[j]);
  }

  function add(id) {
    if (occ[id]) return;
    occ[id] = true;
    _recalcAround(id);
  }

  function remove(id) {
    if (!occ[id]) return;
    delete occ[id];
    _recalcAround(id);
  }

  // ---------- Internals ----------

  function _changedCenters(a, b) {
    const seen = Object.create(null), out = [];
    for (const k in a) seen[k] = 1;
    for (const k in b) seen[k] = 1;
    for (const k in seen) {
      if (!!a[k] !== !!b[k]) out.push(Number(k));
    }
    return out.length ? out : [];
  }

  function _recalcAround(centerId) {
    const start = centerId - radius;
    const end   = centerId + radius;
    for (let i = start; i <= end; i++) {
      const newMask = _calcMask(i);
      const oldMask = masks[i] || 0;
      if (newMask !== oldMask) {
        masks[i] = newMask;
        maskChanged(i, newMask);
      }
    }
  }

  function _calcMask(i) {
    let m = 0;
    if (occ[i]) m |= bitCenter;
    for (let d = 1; d <= radius; d++) { if (occ[i - d]) { m |= bitLower; break; } }
    for (let d = 1; d <= radius; d++) { if (occ[i + d]) { m |= bitUpper; break; } }
    return m;
  }
}
