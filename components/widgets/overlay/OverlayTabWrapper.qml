pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config

Item {
  id: wrapper
  required property var screen
  property var viewsConfig: Menu.views || []
  property var viewsModel: buildViewsModel(viewsConfig)
  property int currentIndex: 0

  implicitWidth: currentViewWidth + Menu.cardSpacing * 2
  implicitHeight: currentViewHeight + Menu.cardSpacing * 2

  // Store current view dimensions to avoid binding loops
  property real currentViewWidth: viewsRepeater.count > 0 && viewsRepeater.itemAt(wrapper.currentIndex) ? 
                                   viewsRepeater.itemAt(wrapper.currentIndex).implicitWidth : 0
  property real currentViewHeight: viewsRepeater.count > 0 && viewsRepeater.itemAt(wrapper.currentIndex) ? 
                                    viewsRepeater.itemAt(wrapper.currentIndex).implicitHeight : 0

  function buildViewsModel(viewConfigArray) {
    if (!viewConfigArray || viewConfigArray.length === 0) {
      return [];
    }
    const array = viewConfigArray.filter(viewConf => viewConf.visible !== false).map(viewConf => {
      const componentType = "views/" + viewConf.type + ".qml";
      if (!viewConf.type) {
        console.warn("Unknown view type in menu config:", viewConf);
        return null;
      }
      return {
        component: componentType,
        properties: viewConf.properties || {}
      };
    }).filter(item => item !== null);
    return array;
  }

  Item {
    id: contentContainer
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
    height: wrapper.currentViewHeight + Menu.cardSpacing * 2
    width: wrapper.currentViewWidth + Menu.cardSpacing * 2
    clip: true

    Behavior on height {
      NumberAnimation {
        duration: Appearance.animationDuration
        easing.type: Easing.InOutQuad
      }
    }

    Behavior on width {
      NumberAnimation {
        duration: Appearance.animationDuration
        easing.type: Easing.InOutQuad
      }
    }

    Rectangle {
      id: mainContentBox
      anchors.centerIn: parent
      width: contentContainer.width
      height: contentContainer.height
      radius: Menu.cardBorderRadius
      color: Theme.backgroundAlt
      border.color: Theme.foreground
      border.width: Menu.cardBorderWidth

      Item {
        id: viewsContainer
        anchors.fill: parent
        anchors.margins: Menu.cardSpacing

        Repeater {
          id: viewsRepeater
          model: wrapper.viewsModel

          Item {
            id: viewContainer
            required property int index
            required property var modelData
            
            anchors.centerIn: parent
            implicitWidth: viewWrapper.implicitWidth
            implicitHeight: viewWrapper.implicitHeight
            visible: wrapper.currentIndex === index
            opacity: wrapper.currentIndex === index ? 1 : 0

            OverlayViewWrapper {
              id: viewWrapper
              anchors.centerIn: parent
              screen: wrapper.screen
              viewModel: viewContainer.modelData
            }

            transform: Translate {
              id: slideTransform
              x: 0
            }

            Behavior on opacity {
              NumberAnimation {
                duration: Appearance.animationDuration / 2
                easing.type: Easing.InOutQuad
              }
            }

            Behavior on visible {
              enabled: false
            }

            states: [
              State {
                name: "left"
                when: viewContainer.index < wrapper.currentIndex
                PropertyChanges {
                  target: slideTransform
                  x: -100
                }
              },
              State {
                name: "center"
                when: viewContainer.index === wrapper.currentIndex
                PropertyChanges {
                  target: slideTransform
                  x: 0
                }
              },
              State {
                name: "right"
                when: viewContainer.index > wrapper.currentIndex
                PropertyChanges {
                  target: slideTransform
                  x: 100
                }
              }
            ]

            transitions: Transition {
              NumberAnimation {
                property: "x"
                duration: Appearance.animationDuration / 2
                easing.type: Easing.InOutQuad
              }
            }
          }
        }
      }
    }
  }
}
