// BaseWidget.qml
import QtQuick

import qs.services

Item {
  id: root

  // Core properties
  property int orientation: Settings.orientation
  property bool isVertical: orientation === Qt.Vertical
  property color backgroundColor: Colors.orange
  property alias content: contentLoader.sourceComponent
  property alias contentItem: contentLoader.item
  property int padding: Settings.widgetPadding

  // Dimension handling
  height: isVertical ? implicitHeight : Settings.widgetHeight
  width: isVertical ? Settings.widgetHeight : implicitWidth

  implicitWidth: isVertical ? Settings.widgetHeight : (contentLoader.item ? contentLoader.item.implicitWidth + padding * 2 : 60)

  implicitHeight: isVertical ? (contentLoader.item ? contentLoader.item.implicitHeight + padding * 2 : Settings.widgetHeight) : Settings.widgetHeight

  // Background
  Rectangle {
    anchors.fill: parent
    color: root.backgroundColor
    radius: Settings.borderRadius
  }

  // Content
  Loader {
    id: contentLoader
    anchors.centerIn: parent
  }
}
