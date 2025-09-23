// components/widgets/BarContainer.qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.services

Rectangle {
  id: root

  property alias workspaces: workspacesLoader.sourceComponent
  property alias leftGroup: leftGroupLoader.sourceComponent
  property alias rightGroup: rightGroupLoader.sourceComponent
  property alias leftCenterGroup: leftCenterGroupLoader.sourceComponent
  property alias rightCenterGroup: rightCenterGroupLoader.sourceComponent

  property color backgroundColor: Colors.bg
  property color foregroundColor: Colors.fg
  property var screen
  property var popouts

  color: backgroundColor

  Rectangle {
    width: 0
    anchors {
      right: parent.right
      top: parent.top
      bottom: parent.bottom
    }
    color: foregroundColor
  }

  // Workspaces centered
  Loader {
    id: workspacesLoader
    anchors.centerIn: parent
  }

  // Top/Left group
  Loader {
    id: leftGroupLoader
    anchors {
      left: Settings.verticalBar ? undefined : parent.left
      top: Settings.verticalBar ? parent.top : undefined
      horizontalCenter: Settings.verticalBar ? parent.horizontalCenter : undefined
      verticalCenter: Settings.verticalBar ? undefined : parent.verticalCenter
      leftMargin: Settings.verticalBar ? 0 : Settings.screenMargin
      topMargin: Settings.verticalBar ? Settings.screenMargin : 0
    }
  }

  // Left-Center/Top-Center group
  Loader {
    id: leftCenterGroupLoader
    anchors {
      right: Settings.verticalBar ? undefined : workspacesLoader.left
      bottom: Settings.verticalBar ? workspacesLoader.top : undefined
      horizontalCenter: Settings.verticalBar ? parent.horizontalCenter : undefined
      verticalCenter: Settings.verticalBar ? undefined : parent.verticalCenter
      rightMargin: Settings.verticalBar ? 0 : Settings.screenMargin
      bottomMargin: Settings.verticalBar ? Settings.screenMargin : 0
    }
  }

  // Right-Center/Bottom-Center group
  Loader {
    id: rightCenterGroupLoader
    anchors {
      left: Settings.verticalBar ? undefined : workspacesLoader.right
      top: Settings.verticalBar ? workspacesLoader.bottom : undefined
      horizontalCenter: Settings.verticalBar ? parent.horizontalCenter : undefined
      verticalCenter: Settings.verticalBar ? undefined : parent.verticalCenter
      leftMargin: Settings.verticalBar ? 0 : Settings.screenMargin
      topMargin: Settings.verticalBar ? Settings.screenMargin : 0
    }
  }

  // Bottom/Right group
  Loader {
    id: rightGroupLoader
    anchors {
      right: Settings.verticalBar ? undefined : parent.right
      bottom: Settings.verticalBar ? parent.bottom : undefined
      horizontalCenter: Settings.verticalBar ? parent.horizontalCenter : undefined
      verticalCenter: Settings.verticalBar ? undefined : parent.verticalCenter
      rightMargin: Settings.verticalBar ? 0 : Settings.screenMargin
      bottomMargin: Settings.verticalBar ? Settings.screenMargin : 0
    }
  }
}
