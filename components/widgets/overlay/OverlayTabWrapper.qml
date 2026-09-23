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
  // itemAt() isn't a notifying read: `count` makes this re-evaluate once
  // the Repeater has created its pages (on launch they don't exist yet)
  readonly property Item currentPage: wrapper.currentIndex === wrapper.editorIndex ? editorPage : (viewsRepeater.count > wrapper.currentIndex ? viewsRepeater.itemAt(wrapper.currentIndex) : null)

  // A new launch opens on the first page; closing and re-opening keeps the
  // page (this wrapper lives as long as the overlay window). The views
  // rebuild on every config change, including the editor's own saves: stay
  // on the editor if the user is on it, otherwise keep the index valid.
  // Tracked from real navigation only: while the views are still loading
  // the editor briefly sits at index 0, which isn't the user being on it.
  property bool _onEditor: false
  onCurrentIndexChanged: wrapper._onEditor = wrapper.viewsModel.length > 0 && wrapper.currentIndex === wrapper.editorIndex
  onEditorIndexChanged: {
    if (wrapper._onEditor)
      wrapper.currentIndex = wrapper.editorIndex;
    else
      wrapper.currentIndex = Math.min(wrapper.currentIndex, wrapper.editorIndex);
  }

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
