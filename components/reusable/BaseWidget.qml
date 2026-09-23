pragma ComponentBehavior: Bound
import QtQuick

import qs.services
import qs.config

// Rounded background box for bar modules. Its size is set by the bar
// (BarModule); subclasses report their natural size through
// implicitWidth/implicitHeight and fit their content inside whatever size
// they're actually given. Content never draws outside the box.
Item {
  id: root

  property color backgroundColor: Theme.background
  property alias content: contentLoader.sourceComponent
  property alias contentItem: contentLoader.item
  property int padding: Widget.padding
  property bool isVertical: false

  implicitWidth: isVertical ? Widget.height : (contentLoader.item ? contentLoader.item.implicitWidth + padding * 2 : 0)
  implicitHeight: isVertical ? (contentLoader.item ? contentLoader.item.implicitHeight + padding * 2 : 0) : Widget.height

  clip: true

  Rectangle {
    anchors.fill: parent
    color: root.backgroundColor
    radius: Appearance.borderRadius
  }

  Loader {
    id: contentLoader
    anchors.centerIn: parent
  }
}
