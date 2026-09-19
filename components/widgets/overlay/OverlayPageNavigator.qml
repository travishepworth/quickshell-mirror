pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

// Fixed page navigator for the overlay's tabbed views (arrows + dots).
// Kept as its own item, anchored directly to the overlay's screen edge,
// so it doesn't move when the current page's content height changes.
Rectangle {
  id: root

  required property int currentIndex
  required property int count

  signal previous()
  signal next()
  signal select(int index)

  width: controlLayout.implicitWidth + 20
  height: 40
  radius: 8
  color: "transparent"
  border.color: Theme.foreground
  border.width: 0

  RowLayout {
    id: controlLayout
    anchors.centerIn: parent
    spacing: 12

    // Left arrow
    Rectangle {
      Layout.preferredWidth: 30
      Layout.preferredHeight: 30
      radius: Menu.cardBorderRadius
      color: leftArrowMouse.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt
      border.color: Theme.border
      border.width: Menu.cardBorderWidth

      Text {
        anchors.centerIn: parent
        text: "‹"
        font.pixelSize: 20
        font.bold: true
        color: Theme.foreground
      }

      MouseArea {
        id: leftArrowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.previous()
      }
    }

    // View indicators
    Rectangle {
      Layout.preferredWidth: indicatorRow.implicitWidth + 12
      Layout.preferredHeight: 30
      radius: Menu.cardBorderRadius
      color: Theme.backgroundAlt
      border.color: Theme.border
      border.width: Menu.cardBorderWidth

      Row {
        id: indicatorRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
          model: root.count

          Rectangle {
            id: indicatorDot
            required property int index
            width: 12
            height: 12
            radius: Menu.cardBorderRadius
            color: root.currentIndex === index ? Theme.accent : dotMouse.containsMouse ? Theme.foreground : Theme.background
            border.color: Theme.border
            border.width: Menu.cardBorderWidth

            MouseArea {
              id: dotMouse
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onClicked: root.select(indicatorDot.index)
            }

            Behavior on color {
              ColorAnimation {
                duration: Appearance.animationDuration / 2
              }
            }
          }
        }
      }
    }

    // Right arrow
    Rectangle {
      Layout.preferredWidth: 30
      Layout.preferredHeight: 30
      radius: Menu.cardBorderRadius
      color: rightArrowMouse.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt
      border.color: Theme.border
      border.width: Menu.cardBorderWidth

      Text {
        anchors.centerIn: parent
        text: "›"
        font.pixelSize: 20
        font.bold: true
        color: Theme.foreground
      }

      MouseArea {
        id: rightArrowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.next()
      }
    }
  }
}
