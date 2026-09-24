pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.views

Item {
  id: wrapper
  required property var screen
  // This screen's card grid (OverlayGrid), handed to every view
  required property OverlayGrid grid
  // The most room a page's box may take; a page bigger than that is
  // shrunk (fitScale) so any config fits any screen
  property real maxWidth: 0
  property real maxHeight: 0
  // Whether the overlay window is showing; pages unload when it isn't
  property bool open: false
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

  implicitWidth: currentViewWidth * fitScale + OverlayConfig.cardSpacing * 2
  implicitHeight: currentViewHeight * fitScale + OverlayConfig.cardSpacing * 2

  // Store current view dimensions to avoid binding loops
  property real currentViewWidth: wrapper.currentPage ? wrapper.currentPage.implicitWidth : 0
  property real currentViewHeight: wrapper.currentPage ? wrapper.currentPage.implicitHeight : 0

  // The grid already sizes cards to the screen; this is the last resort
  // for a page that still doesn't fit (many columns, a large Overlay size).
  // Item.scale doesn't feed back into implicit sizes, so no binding loop.
  readonly property real fitScale: {
    const room = OverlayConfig.cardSpacing * 2;
    const scaleW = wrapper.currentViewWidth > 0 && wrapper.maxWidth > room ? (wrapper.maxWidth - room) / wrapper.currentViewWidth : 1;
    const scaleH = wrapper.currentViewHeight > 0 && wrapper.maxHeight > room ? (wrapper.maxHeight - room) / wrapper.currentViewHeight : 1;
    return Math.min(1, scaleW, scaleH);
  }
  onFitScaleChanged: console.log(`Overlay page ${wrapper.currentIndex} scaled to ${wrapper.fitScale.toFixed(3)} (card unit ${wrapper.grid.unit})`)
  Connections {
    target: wrapper.grid
    function onUnitChanged() {
      console.log(`Overlay card unit ${wrapper.grid.unit} for ${wrapper.maxWidth}x${wrapper.maxHeight}`);
    }
  }

  // Only the current page and its neighbours (navigation wraps around) are
  // loaded, and only while the overlay is open, so hidden pages don't keep
  // polling. Neighbours stay loaded so the slide in has something to show.
  function isLoaded(pageIndex) {
    if (!wrapper.open)
      return false;
    const distance = Math.abs(pageIndex - wrapper.currentIndex);
    return Math.min(distance, wrapper.pageCount - distance) <= 1;
  }

  function buildViewsModel(viewConfigArray) {
    return (viewConfigArray || []).filter(viewConf => viewConf.visible !== false).map(viewConf => {
      // views/<type>.qml; unknown types are rejected by schema validation
      return {
        "component": Qt.resolvedUrl("../../views/" + viewConf.type + ".qml"),
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
    height: wrapper.implicitHeight
    width: wrapper.implicitWidth
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

      // Laid out at full size and scaled as a whole, so the box's own
      // border and radius stay crisp
      Item {
        id: viewsContainer
        anchors.centerIn: parent
        width: wrapper.currentViewWidth
        height: wrapper.currentViewHeight
        scale: wrapper.fitScale

        Repeater {
          id: viewsRepeater
          model: wrapper.viewsModel

          OverlayPage {
            id: viewPage
            required property int index
            required property var modelData
            pageIndex: index
            currentIndex: wrapper.currentIndex
            loaded: wrapper.isLoaded(index)

            OverlayView {
              anchors.centerIn: parent
              screen: wrapper.screen
              grid: wrapper.grid
              viewModel: viewPage.modelData
            }
          }
        }

        OverlayPage {
          id: editorPage
          pageIndex: wrapper.editorIndex
          currentIndex: wrapper.currentIndex
          loaded: wrapper.isLoaded(wrapper.editorIndex)

          OverlayEditor {
            anchors.centerIn: parent
            screen: wrapper.screen
            grid: wrapper.grid
          }
        }
      }
    }
  }
}
