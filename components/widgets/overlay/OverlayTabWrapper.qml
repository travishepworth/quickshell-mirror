pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.widgets.overlay.views

Item {
  id: wrapper
  required property var screen
  property var viewsConfig: OverlayConfig.views || []
  property var viewsModel: buildViewsModel(viewsConfig)
  property int currentIndex: 0
  // The configured views, then the overlay editor, which isn't in config:
  // it's always the last page and can't be removed
  readonly property int editorIndex: viewsModel.length
  readonly property int pageCount: viewsModel.length + 1
  readonly property Item currentPage: wrapper.currentIndex === wrapper.editorIndex ? editorPage : viewsRepeater.itemAt(wrapper.currentIndex)

  // The views rebuild on every config change (including the editor's own
  // saves); stay on the editor if it was showing, else keep the index valid
  property int _lastEditorIndex: 0
  onEditorIndexChanged: {
    if (wrapper.currentIndex === wrapper._lastEditorIndex)
      wrapper.currentIndex = wrapper.editorIndex;
    else
      wrapper.currentIndex = Math.min(wrapper.currentIndex, wrapper.editorIndex);
    wrapper._lastEditorIndex = wrapper.editorIndex;
  }
  Component.onCompleted: wrapper._lastEditorIndex = wrapper.editorIndex

  implicitWidth: currentViewWidth + OverlayConfig.cardSpacing * 2
  implicitHeight: currentViewHeight + OverlayConfig.cardSpacing * 2

  // Store current view dimensions to avoid binding loops
  property real currentViewWidth: wrapper.currentPage ? wrapper.currentPage.implicitWidth : 0
  property real currentViewHeight: wrapper.currentPage ? wrapper.currentPage.implicitHeight : 0

  function buildViewsModel(viewConfigArray) {
    return (viewConfigArray || []).filter(viewConf => viewConf.visible !== false).map(viewConf => {
      // views/<type>.qml; unknown types are rejected by schema validation
      return {
        "component": "views/" + viewConf.type + ".qml",
        "viewConfig": viewConf
      };
    });
  }

  Item {
    id: contentContainer
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
    height: wrapper.currentViewHeight + OverlayConfig.cardSpacing * 2
    width: wrapper.currentViewWidth + OverlayConfig.cardSpacing * 2
    clip: true

    Behavior on height {
      NumberAnimation {
        duration: Appearance.animNormal
        easing.type: Easing.InOutQuad
      }
    }

    Behavior on width {
      NumberAnimation {
        duration: Appearance.animNormal
        easing.type: Easing.InOutQuad
      }
    }

    Rectangle {
      id: mainContentBox
      anchors.centerIn: parent
      width: contentContainer.width
      height: contentContainer.height
      radius: Appearance.borderRadius
      color: Theme.backgroundAlt
      border.color: Theme.foreground
      border.width: Appearance.borderWidth

      Item {
        id: viewsContainer
        anchors.fill: parent
        anchors.margins: OverlayConfig.cardSpacing

        Repeater {
          id: viewsRepeater
          model: wrapper.viewsModel

          OverlayPage {
            id: viewPage
            required property int index
            required property var modelData
            pageIndex: index
            currentIndex: wrapper.currentIndex

            OverlayViewWrapper {
              anchors.centerIn: parent
              screen: wrapper.screen
              viewModel: viewPage.modelData
            }
          }
        }

        OverlayPage {
          id: editorPage
          pageIndex: wrapper.editorIndex
          currentIndex: wrapper.currentIndex

          OverlayEditor {
            anchors.centerIn: parent
            screen: wrapper.screen
          }
        }
      }
    }
  }
}
