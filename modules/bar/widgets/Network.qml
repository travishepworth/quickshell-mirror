import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.services

Item {
  id: root
  
  property string iface: ""
  property string kind: "" // "wifi" | "ethernet" | ""
  property int orientation: Settings.orientation  // Accept orientation from parent
  property bool isVertical: orientation === Qt.Vertical
  property bool rotateText: true
  
  // Dynamic dimensions based on orientation
  height: isVertical ? implicitHeight : Settings.widgetHeight
  width: isVertical ? Settings.widgetHeight : implicitWidth
  
  implicitWidth: isVertical ? Settings.widgetHeight : (layoutLoader.item ? layoutLoader.item.implicitWidth + Settings.widgetPadding * 2 : 60)
  implicitHeight: isVertical ? (layoutLoader.item ? layoutLoader.item.implicitHeight + Settings.widgetPadding * 2 : Settings.widgetHeight) : Settings.widgetHeight
  
  Timer {
    id: poll
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      nm.command = ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3==\"connected\"{print $1\":\"$2; exit}'"];
      nm.running = true;
    }
  }
  
  Process {
    id: nm
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const out = (text || "").trim();
        const parts = out.split(":");
        root.iface = parts[0] || "";
        root.kind = parts[1] || "";
      }
    }
    onExited: {} // no-op; we only parse stdout above
  }
  
  function iconFor(k) {
    if (k === "wifi")
      return "";
    if (k === "ethernet")
      return "󰈀";
    return "󰤭";
  }
  
  Rectangle {
    anchors.fill: parent
    color: Colors.orange
    radius: Settings.borderRadius
  }
  
  Loader {
    id: layoutLoader
    anchors.centerIn: parent
    // sourceComponent: isVertical ? columnComponent : rowComponent
    sourceComponent: {
      if (!isVertical) {
        return rowComponent;
      } else if (rotateText) {
        return rotatedComponent;
      } else {
        return columnComponent;
      }
    }
    
    Component {
      id: rowComponent
      Row {
        spacing: 6
        
        Text {
          id: labelIconH
          color: Colors.bg
          text: iconFor(root.kind)
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize
        }
        
        Text {
          id: labelH
          color: Colors.bg
          text: root.iface || "—"
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize
        }
      }
    }
    
    Component {
      id: columnComponent
      Column {
        spacing: 2
        
        Text {
          id: labelIconV
          color: Colors.bg
          text: iconFor(root.kind)
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
          id: labelV
          color: Colors.bg
          text: root.iface || "—"
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize * 0.8  // Slightly smaller for vertical layout
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
    }
    Component {
      id: rotatedComponent
      Item {
        implicitWidth: Math.max(iconText.height, ifaceText.height) + 6
        implicitHeight: iconText.width + ifaceText.width + 6
        
        Text {
          id: iconText
          color: Colors.bg
          text: iconFor(root.kind)
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize
          anchors {
            centerIn: parent
            verticalCenterOffset: -(ifaceText.width / 2) - 3
          }
        }
        
        Text {
          id: ifaceText
          color: Colors.bg
          text: root.iface || "—"
          font.family: Settings.fontFamily
          font.pixelSize: Settings.fontSize
          rotation: -90  // Rotate counter-clockwise
          anchors {
            centerIn: parent
            verticalCenterOffset: (iconText.width / 2) + 3
          }
        }
      }
    }
  }
}
