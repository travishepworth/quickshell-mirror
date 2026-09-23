pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay
import qs.components.widgets.overlay.modules.common

// The primary connection (name, IP, wifi signal), live throughput with a
// graph, and Tailscale's state when it's installed.
OverlayCard {
  id: root

  readonly property var info: SystemManager.netInfo
  readonly property string kindIcon: root.info.kind === "wifi" ? "\u{F0928}" : root.info.kind === "ethernet" ? "\u{F0200}" : "\u{F0B8C}"
  property string tailscale: ""

  function rate(bytes) {
    const units = ["B/s", "KB/s", "MB/s", "GB/s"];
    let i = 0;
    while (bytes >= 1024 && i < units.length - 1) {
      bytes /= 1024;
      i++;
    }
    return `${bytes < 10 && i > 0 ? bytes.toFixed(1) : Math.round(bytes)} ${units[i]}`;
  }

  Component.onCompleted: SystemManager.acquire(root, {
    "metrics": ["net"],
    "history": true,
    "interval": 1000
  })
  Component.onDestruction: SystemManager.release(root)

  // Tailscale state every 30s, if it's installed
  Process {
    id: tailscaleCheck
    command: ["sh", "-c", "command -v tailscale >/dev/null || exit 0; tailscale status --json 2>/dev/null | jq -r '.BackendState + \" \" + (.Self.TailscaleIPs[0] // \"\")'"]
    stdout: StdioCollector {
      onStreamFinished: root.tailscale = text.trim()
    }
  }
  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: tailscaleCheck.running = true
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Widget.spacing / 2

    ModuleHeader {
      icon: root.kindIcon
      title: root.info.name || I18n.tr("Disconnected")
      StyledText {
        visible: root.info.kind === "wifi" && !root.compact
        text: `${root.info.signal}%`
        textSize: Appearance.fontSize - 2
        opacity: 0.7
      }
    }
    StyledText {
      visible: !root.compact && root.info.ip !== ""
      text: root.info.ip
      textSize: Appearance.fontSize - 2
      opacity: 0.7
    }
    StyledText {
      visible: !root.compact && root.tailscale !== ""
      Layout.fillWidth: true
      elide: Text.ElideRight
      text: I18n.tr("Tailscale · {0}", root.tailscale)
      textSize: Appearance.fontSize - 2
      textColor: root.tailscale.startsWith("Running") ? Theme.success : Theme.foreground
      opacity: 0.8
    }

    Sparkline {
      visible: !root.compact
      Layout.fillWidth: true
      Layout.fillHeight: true
      values: SystemManager.netRxHistory
      maxValue: 0
      lineColor: Theme.accentAlt
      capacity: SystemManager.historyLength
    }

    RowLayout {
      Layout.fillWidth: true
      StyledText {
        text: `\u{F0045} ${root.rate(SystemManager.netRx)}`
        textSize: Appearance.fontSize - 1
      }
      Item {
        Layout.fillWidth: true
      }
      StyledText {
        text: `\u{F005D} ${root.rate(SystemManager.netTx)}`
        textSize: Appearance.fontSize - 1
        opacity: 0.8
      }
    }
  }
}
