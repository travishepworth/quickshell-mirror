import QtQuick
import qs.config

// One overlay's card grid, sized to its screen: the card unit is what fits
// the free space (OverlayConfig.fitCardsHigh / fitCardsWide), capped at the
// reference cardUnit, then scaled by the user's Overlay size. Each
// OverlayPanel has its own, so every monitor gets cards that fit it; pages
// that still overflow are shrunk by OverlayPages.
QtObject {
  id: root

  // The space a page may take, set by the panel
  property real availableWidth: 0
  property real availableHeight: 0

  readonly property real fit: Math.min(root.availableHeight / OverlayConfig.fitCardsHigh, root.availableWidth / OverlayConfig.fitCardsWide)
  readonly property int unit: Math.round(Math.max(OverlayConfig.minCardUnit, Math.min(OverlayConfig.cardUnit, root.fit) * OverlayConfig.size / 100))
  readonly property real halfUnit: OverlayConfig.halfUnitOf(root.unit)

  function span(n) {
    return OverlayConfig.span(n, root.unit);
  }

  function columnFlow(cells) {
    return OverlayConfig.columnFlow(cells, root.unit);
  }
}
