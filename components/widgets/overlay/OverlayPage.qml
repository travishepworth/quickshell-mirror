pragma ComponentBehavior: Bound
import QtQuick
import qs.config

// One page of the overlay: shown when it's the current page, sliding in
// from the side it sits on relative to the current one
Item {
  id: page

  required property int pageIndex
  required property int currentIndex
  default property alias content: page.data

  readonly property Item _content: page.children.length > 0 ? page.children[0] : null

  anchors.centerIn: parent
  implicitWidth: page._content ? page._content.implicitWidth : 0
  implicitHeight: page._content ? page._content.implicitHeight : 0
  visible: page.currentIndex === page.pageIndex
  opacity: page.currentIndex === page.pageIndex ? 1 : 0

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
