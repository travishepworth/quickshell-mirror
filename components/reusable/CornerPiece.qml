import QtQuick
import QtQuick.Shapes
import qs.config

Item {
  id: root
  property int borderRadius: Appearance.borderRadius
  property color fillColor: Theme.background
  property color strokeColor: Theme.foreground
  property int strokeWidth: Appearance.borderWidth * 1.5

  property bool isLeft: true
  property bool isTop: true

  readonly property real overshoot: strokeWidth

  anchors.fill: parent

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

  Shape {
    anchors.fill: parent
    layer.enabled: true
    // layer.samples: 8
    layer.smooth: true
    antialiasing: false
    // preferredRendererType: Shape.CurveRenderer
    preferredRendererType: Shape.GeometryRenderer

    ShapePath {
      strokeColor: root.strokeColor
      strokeWidth: root.strokeWidth
      fillColor: "transparent"
      capStyle: ShapePath.FlatCap
      joinStyle: ShapePath.RoundJoin

      startX: root.isLeft ? parent.width : -root.overshoot
      startY: root.isTop ? -root.overshoot : parent.height

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
        x: root.isLeft ? -root.overshoot : parent.width + root.overshoot
        y: root.isTop ? parent.height : -root.overshoot
      }
    }
  }
}
