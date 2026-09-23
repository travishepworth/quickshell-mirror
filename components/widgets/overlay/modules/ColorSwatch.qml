import QtQuick

import qs.config
import qs.components.widgets.overlay

// properties: { color: base00-base0F (or any name Theme.resolveColor accepts), label }
OverlayCard {
  id: swatch

  color: Theme.resolveColor(swatch.properties.color)
  border.width: Math.max(Appearance.borderWidth, 3)

  Text {
    id: label
    text: swatch.properties.color
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: OverlayConfig.cardSpacing / 2
    color: (swatch.color === Theme.background || swatch.color === Theme.backgroundAlt) ? Theme.foreground : Theme.background
    font.pixelSize: Appearance.fontSize - 4
    font.bold: true
    z: 1
    opacity: 0.8
  }

  Text {
    id: semanticLabel
    text: swatch.properties.label
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: OverlayConfig.cardSpacing / 2
    color: (swatch.color === Theme.background || swatch.color === Theme.backgroundAlt) ? Theme.foreground : Theme.background
    font.pixelSize: Appearance.fontSize - 4
    font.bold: true
    z: 1
    opacity: 0.8
  }
}
