pragma ComponentBehavior: Bound
import QtQuick

Item {
  id: root
  required property var screen
  // { component, viewConfig } from OverlayPages.buildViewsModel
  required property var viewModel

  implicitWidth: viewLoader.item ? viewLoader.item.implicitWidth : 0
  implicitHeight: viewLoader.item ? viewLoader.item.implicitHeight : 0

  // Created with its inputs already set, then bound so config edits reach it
  function _load() {
    viewLoader.setSource(root.viewModel.component, {
      "screen": root.screen,
      "viewConfig": root.viewModel.viewConfig
    });
  }
  Component.onCompleted: _load()

  Loader {
    id: viewLoader
    anchors.centerIn: parent
    onLoaded: {
      item.screen = Qt.binding(() => root.screen);
      item.viewConfig = Qt.binding(() => root.viewModel.viewConfig);
    }
  }
}
