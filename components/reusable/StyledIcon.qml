// qs/components/reusable/StyledIcon.qml
pragma ComponentBehavior: Bound
import QtQuick
import qs.config

// A Material Symbols icon: `text` is its name ("wifi"), or several names
// separated by spaces or newlines. Anything else (a glyph or text a user
// typed into an icon field) is drawn in the text font instead.
StyledText {
  id: root

  // -- Public API --
  readonly property bool isSymbol: /^\s*[a-z][a-z0-9_]*(\s+[a-z][a-z0-9_]*)*\s*$/.test(text)
  // Material Symbols' variable axes
  property real fill: 0
  property int weight: 400

  // -- Implementation --
  textFamily: isSymbol ? Appearance.iconFamily : Appearance.fontFamily
  font.variableAxes: isSymbol ? {
    "FILL": root.fill,
    "wght": root.weight
  } : ({})
}
