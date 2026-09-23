pragma ComponentBehavior: Bound
import QtQuick

Item {
  id: viewWrapper
  required property var screen
  // { component, viewConfig } from OverlayTabWrapper.buildViewsModel
  required property var viewModel

  implicitWidth: viewLoader.item ? viewLoader.item.implicitWidth : 0
  implicitHeight: viewLoader.item ? viewLoader.item.implicitHeight : 0

  // Created with its inputs already set, then bound so config edits reach it
  function _load() {
    viewLoader.setSource(viewWrapper.viewModel.component, {
      "screen": viewWrapper.screen,
      "viewConfig": viewWrapper.viewModel.viewConfig
    });
  }
  Component.onCompleted: _load()

  Loader {
    id: viewLoader
    anchors.centerIn: parent
    onLoaded: {
      item.screen = Qt.binding(() => viewWrapper.screen);
      item.viewConfig = Qt.binding(() => viewWrapper.viewModel.viewConfig);
    }
  }
}
