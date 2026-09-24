pragma ComponentBehavior: Bound
import QtQuick
import qs.config

// One page of the overlay: shown when it's the current page, sliding in
// from the side it sits on relative to the current one. The content is
// only instantiated while `loaded`.
Item {
  id: page

  required property int pageIndex
  required property int currentIndex
  required property bool loaded
  default property Component content

  anchors.centerIn: parent
  implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
  implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0
  visible: page.currentIndex === page.pageIndex
  opacity: page.currentIndex === page.pageIndex ? 1 : 0

  Loader {
    id: contentLoader
    anchors.centerIn: parent
    active: page.loaded
    sourceComponent: page.content
  }

  transform: Translate {
    id: slideTransform
    x: 0
  }

  Behavior on opacity {
    NumberAnimation {
      duration: Appearance.animFast
      easing.type: Easing.InOutQuad
    }
  }

  states: [
    State {
      name: "left"
      when: page.pageIndex < page.currentIndex
      PropertyChanges {
        target: slideTransform
        x: -100
      }
    },
    State {
      name: "center"
      when: page.pageIndex === page.currentIndex
      PropertyChanges {
        target: slideTransform
        x: 0
      }
    },
    State {
      name: "right"
      when: page.pageIndex > page.currentIndex
      PropertyChanges {
        target: slideTransform
        x: 100
      }
    }
  ]

  transitions: Transition {
    NumberAnimation {
      property: "x"
      duration: Appearance.animFast
      easing.type: Easing.InOutQuad
    }
  }
}
