pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay

// Screenshots with grim + slurp: region, active window or whole screen,
// saved to `directory` and copied to the clipboard. The overlay closes
// first so it isn't in the shot. Recording shows only with wf-recorder.
// properties: { directory }
OverlayCard {
  id: root

  readonly property string directory: root.properties.directory || "~/Pictures/Screenshots"
  property bool hasRecorder: false
  property bool recording: false
  property string _pending: ""

  readonly property var modes: [["region", "\u{F0EB4}", "Region"], ["window", "\u{F05B6}", "Window"], ["screen", "\u{F0E51}", "Screen"]].concat(root.hasRecorder ? [["record", root.recording ? "\u{F04DB}" : "\u{F044A}", root.recording ? "Stop" : "Record"]] : [])

  function capture(mode) {
    if (mode === "record" && root.recording) {
      Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"]);
      root.recording = false;
      return;
    }
    root._pending = mode;
    ShellManager.toggleOverlay();
    // Let the overlay slide away before capturing
    delay.restart();
  }

  Timer {
    id: delay
    interval: Appearance.animSlow + 150
    onTriggered: {
      const dir = root.directory.replace(/^~/, Quickshell.env("HOME"));
      const ext = root._pending === "record" ? "mp4" : "png";
      const file = `${dir}/${root._pending === "record" ? "Recording" : "Screenshot"}_$(date +%Y%m%d_%H%M%S).${ext}`;
      const geometry = {
        "region": `-g "$(slurp)"`,
        "window": `-g "$(hyprctl -j activewindow | jq -r '"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])"')"`,
        "screen": ""
      };
      if (root._pending === "record") {
        root.recording = true;
        Quickshell.execDetached(["sh", "-c", `mkdir -p "${dir}" && wf-recorder -g "$(slurp)" -f "${file}"`]);
      } else {
        shot.command = ["sh", "-c", `mkdir -p "${dir}" && f="${file}" && grim ${geometry[root._pending]} "$f" && wl-copy < "$f" && echo "$f"`];
        shot.running = true;
      }
    }
  }

  Process {
    id: shot
    stdout: StdioCollector {
      onStreamFinished: {
        const file = text.trim();
        if (file)
          Notifs.sendNotification("Screenshot", "Screenshot saved", `${file} (copied to clipboard)`, {});
      }
    }
  }

  Process {
    running: true
    command: ["sh", "-c", "command -v wf-recorder >/dev/null && echo yes; pgrep -x wf-recorder >/dev/null && echo rec; true"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.hasRecorder = text.includes("yes");
        root.recording = text.includes("rec");
      }
    }
  }

  GridLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    columns: root.compact ? 2 : root.shape === "horizontal" ? root.modes.length : 2
    columnSpacing: Widget.spacing
    rowSpacing: Widget.spacing

    Repeater {
      model: root.modes

      Rectangle {
        id: button
        required property var modelData
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Appearance.borderRadius
        color: button.modelData[0] === "record" && root.recording ? Theme.error : buttonArea.containsMouse ? Theme.backgroundHighlight : Theme.backgroundAlt
        border.color: Theme.border
        border.width: Appearance.borderWidth

        ColumnLayout {
          anchors.centerIn: parent
          spacing: 2
          StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: button.modelData[1]
            textSize: Math.max(Appearance.fontSize, Math.min(button.width, button.height) * 0.3)
          }
          StyledText {
            visible: !root.compact && button.height > Appearance.fontSize * 4
            Layout.alignment: Qt.AlignHCenter
            text: button.modelData[2]
            textSize: Appearance.fontSize - 2
          }
        }

        MouseArea {
          id: buttonArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.capture(button.modelData[0])
        }
      }
    }
  }
}
