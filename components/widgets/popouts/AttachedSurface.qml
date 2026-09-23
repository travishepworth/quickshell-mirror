pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

import qs.config
import qs.components.widgets.popouts

/**
 * The shared "grows out of an edge" shape used by both bar popouts and
 * screen-edge popouts: a content box joined to the attach edge by two
 * concave fillets, with the bar/border stroke cut open where it joins.
 * The whole thing slides in/out from the attach edge.
 *
 * The outline is a single path (fill + stroke), with the stroke centred
 * half a border width inside the edge. That way every segment (the line
 * along the attach edge, the fillets, the sides and the far corners) is
 * the same full width, pixel-aligned with the bar/border stroke it
 * continues. Composing rectangles + clipped corner pieces left some
 * segments half-clipped and anti-aliased.
 *
 * `edge` is the side the surface attaches to, as a Bar.Location value.
 * `boxWidth`/`boxHeight` are the size of the content box; the implicit
 * size adds the connector and fillet margins around it.
 *
 * Place this at the attach edge of its window: for a Top edge, y = 0 of
 * this item should sit on the top of the bar/border stroke line.
 */
Item {
  id: root

  required property int edge
  property bool active: false
  property real boxWidth: 100
  property real boxHeight: 100
  property int connectorGap: Appearance.borderRadius * 2
  property int animationDuration: Appearance.animNormal

  // Breathing room between the box edge and its content: clears the
  // stroke, plus a share of the corner radius so content keeps away from
  // the curve as corners get rounder. Callers that size the box from
  // their content add this on each side (see bar Popouts, tray submenus).
  readonly property int contentInset: Widget.spacing + Appearance.borderWidth + Math.round(Appearance.borderRadius / 4)

  property color fillColor: Theme.background
  property color strokeColor: Theme.foreground

  default property alias content: contentContainer.data

  readonly property bool vertical: edge === Bar.Left || edge === Bar.Right
  readonly property bool attachLeft: edge === Bar.Left
  readonly property bool attachRight: edge === Bar.Right
  readonly property bool attachTop: edge === Bar.Top
  readonly property bool attachBottom: edge === Bar.Bottom

  // Along the edge: box + one fillet square on each side, minus the
  // stroke overlap. Away from the edge: box + connector gap.
  implicitWidth: vertical ? boxWidth + connectorGap : boxWidth + connectorGap * 2 - Appearance.borderWidth * 2
  implicitHeight: vertical ? boxHeight + connectorGap * 2 - Appearance.borderWidth * 2 : boxHeight + connectorGap

  // The content box in this item's coordinates, at rest (not slid). On
  // every side but the attach edge it coincides with the outer edge of
  // the stroke, so things attaching to this surface (tray submenus) can
  // line their own stroke up with it.
  readonly property rect boxRect: Qt.rect((width - boxWidth) / 2, (height - boxHeight) / 2, boxWidth, boxHeight)

  // ---- Outline geometry, in edge-local coordinates ----
  // u runs along the attach edge, v away from it (v = 0 is the attach
  // edge). Everything below is laid out as if attached to the Top edge,
  // then mapped onto the real edge by px()/py().
  readonly property real alongLength: vertical ? height : width
  readonly property real depth: vertical ? width : height

  readonly property real strokeWidth: Appearance.borderWidth
  // Stroke centre line offset, so the full stroke lies inside the shape
  readonly property real half: strokeWidth / 2
  // Box sides (stroke centre line)
  readonly property real sideU: connectorGap - half
  readonly property real farSideU: alongLength - sideU
  // Far edge of the box (stroke centre line)
  readonly property real farV: depth - connectorGap / 2 - half
  // Concave fillet radius (where the box meets the attach edge) and
  // convex corner radius at the far side, matching a Rectangle's radius
  readonly property real filletRadius: Appearance.borderRadius
  readonly property real cornerRadius: Math.max(0, Appearance.borderRadius - half)

  // Reflections flip the sweep direction of arcs; rotations don't
  readonly property bool mirrored: edge === Bar.Bottom || edge === Bar.Left

  function px(u, v) {
    switch (edge) {
    case Bar.Left:
      return v;
    case Bar.Right:
      return width - v;
    default:
      return u;
    }
  }

  function py(u, v) {
    switch (edge) {
    case Bar.Left:
    case Bar.Right:
      return u;
    case Bar.Bottom:
      return height - v;
    default:
      return v;
    }
  }

  // Sweep direction of an arc as drawn in Top-edge coordinates
  function sweep(clockwise) {
    return clockwise !== mirrored ? PathArc.Clockwise : PathArc.Counterclockwise;
  }

  SlideAnimation {
    id: slideContainer
    anchors.fill: parent

    active: root.active
    slideFromRight: root.attachRight
    slideFromLeft: root.attachLeft
    slideFromTop: root.attachTop
    slideFromBottom: root.attachBottom
    animationDuration: root.animationDuration

    containerHeight: root.height
    containerWidth: root.width
    enableFade: false

    Shape {
      id: outline
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      // Fill: the outline closed along v = 0, so it also covers the
      // bar/border stroke between the fillets (the "cut open" join)
      ShapePath {
        fillColor: root.fillColor
        strokeColor: "transparent"
        strokeWidth: 0

        startX: root.px(0, 0)
        startY: root.py(0, 0)

        PathLine { x: root.px(0, root.half); y: root.py(0, root.half) }
        PathLine { x: root.px(root.sideU - root.filletRadius, root.half); y: root.py(root.sideU - root.filletRadius, root.half) }
        PathArc {
          x: root.px(root.sideU, root.half + root.filletRadius); y: root.py(root.sideU, root.half + root.filletRadius)
          radiusX: root.filletRadius; radiusY: root.filletRadius
          direction: root.sweep(true)
        }
        PathLine { x: root.px(root.sideU, root.farV - root.cornerRadius); y: root.py(root.sideU, root.farV - root.cornerRadius) }
        PathArc {
          x: root.px(root.sideU + root.cornerRadius, root.farV); y: root.py(root.sideU + root.cornerRadius, root.farV)
          radiusX: root.cornerRadius; radiusY: root.cornerRadius
          direction: root.sweep(false)
        }
        PathLine { x: root.px(root.farSideU - root.cornerRadius, root.farV); y: root.py(root.farSideU - root.cornerRadius, root.farV) }
        PathArc {
          x: root.px(root.farSideU, root.farV - root.cornerRadius); y: root.py(root.farSideU, root.farV - root.cornerRadius)
          radiusX: root.cornerRadius; radiusY: root.cornerRadius
          direction: root.sweep(false)
        }
        PathLine { x: root.px(root.farSideU, root.half + root.filletRadius); y: root.py(root.farSideU, root.half + root.filletRadius) }
        PathArc {
          x: root.px(root.farSideU + root.filletRadius, root.half); y: root.py(root.farSideU + root.filletRadius, root.half)
          radiusX: root.filletRadius; radiusY: root.filletRadius
          direction: root.sweep(true)
        }
        PathLine { x: root.px(root.alongLength, root.half); y: root.py(root.alongLength, root.half) }
        PathLine { x: root.px(root.alongLength, 0); y: root.py(root.alongLength, 0) }
        PathLine { x: root.px(0, 0); y: root.py(0, 0) }
      }

      // Stroke: the same outline left open at the attach edge. The two
      // end segments sit exactly on the bar/border stroke they continue.
      ShapePath {
        fillColor: "transparent"
        strokeColor: root.strokeColor
        strokeWidth: root.strokeWidth
        capStyle: ShapePath.FlatCap
        joinStyle: ShapePath.MiterJoin

        startX: root.px(0, root.half)
        startY: root.py(0, root.half)

        PathLine { x: root.px(root.sideU - root.filletRadius, root.half); y: root.py(root.sideU - root.filletRadius, root.half) }
        PathArc {
          x: root.px(root.sideU, root.half + root.filletRadius); y: root.py(root.sideU, root.half + root.filletRadius)
          radiusX: root.filletRadius; radiusY: root.filletRadius
          direction: root.sweep(true)
        }
        PathLine { x: root.px(root.sideU, root.farV - root.cornerRadius); y: root.py(root.sideU, root.farV - root.cornerRadius) }
        PathArc {
          x: root.px(root.sideU + root.cornerRadius, root.farV); y: root.py(root.sideU + root.cornerRadius, root.farV)
          radiusX: root.cornerRadius; radiusY: root.cornerRadius
          direction: root.sweep(false)
        }
        PathLine { x: root.px(root.farSideU - root.cornerRadius, root.farV); y: root.py(root.farSideU - root.cornerRadius, root.farV) }
        PathArc {
          x: root.px(root.farSideU, root.farV - root.cornerRadius); y: root.py(root.farSideU, root.farV - root.cornerRadius)
          radiusX: root.cornerRadius; radiusY: root.cornerRadius
          direction: root.sweep(false)
        }
        PathLine { x: root.px(root.farSideU, root.half + root.filletRadius); y: root.py(root.farSideU, root.half + root.filletRadius) }
        PathArc {
          x: root.px(root.farSideU + root.filletRadius, root.half); y: root.py(root.farSideU + root.filletRadius, root.half)
          radiusX: root.filletRadius; radiusY: root.filletRadius
          direction: root.sweep(true)
        }
        PathLine { x: root.px(root.alongLength, root.half); y: root.py(root.alongLength, root.half) }
      }
    }

    // Content box: same placement the old bordered Rectangle had, so
    // popout content is laid out exactly as before
    Item {
      id: contentContainer
      anchors.centerIn: parent
      width: root.boxWidth
      height: root.boxHeight
    }
  }
}
