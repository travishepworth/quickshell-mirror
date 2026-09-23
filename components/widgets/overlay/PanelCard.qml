pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

// A titled, scrolling panel card (settings, theme, bar editor panels):
// header with optional Save/Reset, divider, optional fixed extras (e.g. a
// tab strip), then the scrolling body that children go into.
OverlayCard {
  id: root

  property alias title: header.title
  property alias dirty: header.dirty
  property alias showActions: header.showActions
  property alias canSave: header.canSave
  // Fixed content between the divider and the scrolling body
  property alias headerExtras: extras.data
  property alias contentSpacing: body.spacing
  default property alias content: body.data

  signal save
  signal reset

  border.color: Theme.border

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Widget.padding
    spacing: 0

    PanelHeader {
      id: header
      onSave: root.save()
      onReset: root.reset()
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      Layout.topMargin: Widget.spacing / 2
      Layout.bottomMargin: Widget.spacing / 2
      color: Theme.border
      opacity: 0.3
    }

    ColumnLayout {
      id: extras
      Layout.fillWidth: true
      Layout.bottomMargin: children.length > 0 ? Widget.spacing / 2 : 0
      visible: children.length > 0
      spacing: Widget.spacing
    }

    ScrollView {
      id: scroll
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

      ColumnLayout {
        id: body
        width: scroll.width - Widget.padding * 2
        spacing: Widget.spacing * 2
      }
    }
  }
}
