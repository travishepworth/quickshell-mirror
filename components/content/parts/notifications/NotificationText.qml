pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.components.reusable

// A notification's summary and body; clicking runs its default action
// (then emits activated)
MouseArea {
  id: root

  required property var notification
  property int summaryLines: 1
  property int bodyLines: 4

  signal activated

  readonly property var defaultAction: (notification.actions ?? []).find(a => a.identifier === "default")

  Layout.fillWidth: true
  implicitHeight: textColumn.implicitHeight
  cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
  onClicked: {
    if (root.defaultAction) {
      root.defaultAction.invoke();
      root.activated();
    }
  }

  ColumnLayout {
    id: textColumn
    width: parent.width
    spacing: 2

    StyledText {
      Layout.fillWidth: true
      text: root.notification.summary || ""
      font.bold: true
      elide: Text.ElideRight
      maximumLineCount: root.summaryLines
      wrapMode: root.summaryLines > 1 ? Text.Wrap : Text.NoWrap
    }

    StyledText {
      visible: (root.notification.body ?? "") !== ""
      Layout.fillWidth: true
      text: root.notification.body ?? ""
      textColor: Theme.foregroundAlt
      textSize: Appearance.fontSize - 1
      wrapMode: Text.Wrap
      maximumLineCount: root.bodyLines
      elide: Text.ElideRight
    }
  }
}
