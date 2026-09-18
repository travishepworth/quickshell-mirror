import QtQuick
import QtQuick.Shapes
import qs.config

Item {
  id: root
  property int borderRadius: Appearance.borderRadius
  property color fillColor: Theme.background
  property color strokeColor: Theme.foreground
  property int strokeWidth: Appearance.borderWidth

  property bool isLeft: true
  property bool isTop: true

  anchors.fill: parent

  // --- FILL SHAPE ---
  Shape {
    anchors.fill: parent
    antialiasing: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.fillColor
      strokeColor: "transparent"

      startX: root.isLeft ? 0 : parent.width
      startY: root.isTop ? 0 : parent.height

      PathLine {
        x: root.isLeft ? root.borderRadius : parent.width - root.borderRadius
        y: root.isTop ? 0 : parent.height
      }

      PathArc {
        x: root.isLeft ? 0 : parent.width
        y: root.isTop ? root.borderRadius : parent.height - root.borderRadius
        radiusX: root.borderRadius
        radiusY: root.borderRadius
        direction: root.isTop === root.isLeft ? PathArc.Counterclockwise : PathArc.Clockwise
      }

      PathLine {
        x: root.isLeft ? 0 : parent.width
        y: root.isTop ? 0 : parent.height
      }
    }
  }

  // --- STROKE SHAPE ---
  Shape {
    anchors.fill: parent
    layer.enabled: true
    layer.samples: 1
    layer.smooth: true
    antialiasing: true
    preferredRendererType: Shape.GeometryRenderer

    ShapePath {
      strokeColor: root.strokeColor
      strokeWidth: root.strokeWidth
      fillColor: "transparent"
      capStyle: ShapePath.FlatCap
      joinStyle: ShapePath.RoundJoin

      // Start at the outer edge of the box
      startX: root.isLeft ? parent.width : 0
      startY: root.isTop ? Appearance.borderWidth : parent.height

      // First edge line leading to the curve
      PathLine {
        x: root.isLeft ? root.borderRadius : parent.width - root.borderRadius
        y: root.isTop ? 0 : parent.height
      }

      // The corner curve
      PathArc {
        x: root.isLeft ? 0 : parent.width
        y: root.isTop ? root.borderRadius : parent.height - root.borderRadius
        radiusX: root.borderRadius
        radiusY: root.borderRadius
        direction: root.isTop === root.isLeft ? PathArc.Counterclockwise : PathArc.Clockwise
      }

      // Second edge line extending to the other edge of the box
      PathLine {
        x: root.isLeft ? Appearance.borderWidth : parent.width
        y: root.isTop ? parent.height : 0
      }
    }
  }
}
