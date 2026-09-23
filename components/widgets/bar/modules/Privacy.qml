pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import qs.services
import qs.config
import qs.components.reusable

// Mic / screen share / camera indicators, derived from active Pipewire
// links (no polling). Hidden entirely while nothing is capturing.
//   mic:    Audio.micCaptures (an app recording from a microphone)
//   screen: a video source from xdg-desktop-portal linked to a stream
//   camera: any other video source linked to a stream
IconTextWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  readonly property var ignoredApps: (properties.ignoreApps || "").split(",").map(a => a.trim().toLowerCase()).filter(a => a !== "")

  readonly property var activeGroups: Pipewire.linkGroups.values.filter(g => g && g.state === PwLinkState.Active && g.source && g.target)

  function appName(node) {
    return node.properties?.["application.name"] || node.nickname || node.name || "Unknown";
  }
  function ignored(node) {
    const names = [node.name, node.properties?.["application.name"], node.properties?.["application.process.binary"]];
    return names.some(n => n && root.ignoredApps.includes(n.toLowerCase()));
  }
  // Quickshell has no type for `Stream/Input/Video`, so a screen/camera
  // consumer is Untracked and `isStream` is false; read the media class.
  function isVideoStream(node) {
    return (node.properties?.["media.class"] ?? "") === "Stream/Input/Video";
  }
  function isPortal(node) {
    return (node.name || "").startsWith("xdg-desktop-portal");
  }
  // Unique app names capturing from sources matching `sourceTest`
  function users(sourceTest, targetTest) {
    const names = activeGroups.filter(g => sourceTest(g.source) && targetTest(g.target) && !ignored(g.target)).map(g => appName(g.target));
    return [...new Set(names)];
  }

  readonly property var micUsers: properties.showMic ? [...new Set(Audio.micCaptures.filter(n => !ignored(n)).map(n => appName(n)))] : []
  readonly property var screenUsers: properties.showScreen ? users(s => s.type === PwNodeType.VideoSource && isPortal(s), t => isVideoStream(t)) : []
  readonly property var cameraUsers: properties.showCamera ? users(s => s.type === PwNodeType.VideoSource && !isPortal(s), t => isVideoStream(t)) : []

  readonly property var glyphs: [...(micUsers.length ? ["\u{F036C}"] : []), ...(screenUsers.length ? ["\u{F0379}"] : []), ...(cameraUsers.length ? ["\u{F0100}"] : [])]
  readonly property bool hidden: glyphs.length === 0

  isVertical: barConfig.vertical

  icon: glyphs.join(isVertical ? "\n" : " ")
  showIcon: !hidden
  showText: false
  padding: hidden ? 0 : Widget.padding

  backgroundColor: Theme.resolveColor(properties.activeColor)
  foregroundColor: Theme.resolveColor(properties.foregroundColor)

  // Binds the linked nodes so their properties (application.name) load
  PwObjectTracker {
    objects: [].concat(...root.activeGroups.map(g => [g.source, g.target]))
  }

  MouseArea {
    anchors.fill: parent
    enabled: !root.hidden
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      const lines = [];
      if (root.micUsers.length)
        lines.push(`Microphone: ${root.micUsers.join(", ")}`);
      if (root.screenUsers.length)
        lines.push(`Screen: ${root.screenUsers.join(", ")}`);
      if (root.cameraUsers.length)
        lines.push(`Camera: ${root.cameraUsers.join(", ")}`);
      Quickshell.execDetached(["notify-send", "-a", "Privacy", "In use", lines.join("\n")]);
    }
  }
}
