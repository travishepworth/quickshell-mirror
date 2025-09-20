import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.services
import qs.components.widgets

IconTextWidget {
  id: root
  icon: ""
  text: (ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.title) 
    ? ToplevelManager.activeToplevel.title 
    : "—";
  backgroundColor: Colors.blue

}

// Item {
//   id: root
//   
//   // Orientation support
//   property int orientation: Settings.orientation  // Accept orientation from parent
//   property bool isVertical: orientation === Qt.Vertical
//   property bool rotateText: orientation === Qt.Vertical  // Option to rotate text in vertical mode
//   property int maxLength: isVertical && !rotateText ? 12 : 25  // Shorter text for vertical
//   
//   // Dynamic dimensions based on orientation
//   height: isVertical ? implicitHeight : Settings.widgetHeight
//   width: isVertical ? Settings.widgetHeight : implicitWidth
//   
//   implicitWidth: isVertical ? Settings.widgetHeight : (label.implicitWidth + Settings.widgetPadding * 2)
//   implicitHeight: isVertical ? (rotateText ? Settings.widgetHeight : label.implicitHeight + Settings.widgetPadding * 2) : Settings.widgetHeight
//   
//   Rectangle {
//     anchors.fill: parent
//     color: Colors.blue
//     radius: Settings.borderRadius
//   }
//   
//   Text {
//     id: label
//     anchors.centerIn: parent
//     color: Colors.bg
//     font.family: Settings.fontFamily
//     font.pixelSize: isVertical && !rotateText ? Settings.fontSize * 0.9 : Settings.fontSize
//     
//     text: {
//       const title = (ToplevelManager.activeToplevel && ToplevelManager.activeToplevel.title) 
//         ? ToplevelManager.activeToplevel.title 
//         : "—";
//       
//       return title.length > maxLength 
//         ? title.substr(0, maxLength) + "…" 
//         : title;
//     }
//     
//     elide: Text.ElideRight
//     horizontalAlignment: Text.AlignHCenter
//     verticalAlignment: Text.AlignVCenter
//     
//     // Handle rotation for vertical mode
//     rotation: (isVertical && rotateText) ? -90 : 0
//     transformOrigin: Item.Center
//     
//     // Dynamic width constraint
//     width: {
//       if (isVertical && !rotateText) {
//         return root.width - 8;  // Smaller padding for vertical
//       } else if (isVertical && rotateText) {
//         return root.height - 16;  // When rotated, constrain to height
//       } else {
//         return root.width - 16;  // Original horizontal constraint
//       }
//     }
//     
//     // Word wrap for vertical non-rotated mode
//     wrapMode: (isVertical && !rotateText) ? Text.WordWrap : Text.NoWrap
//     maximumLineCount: (isVertical && !rotateText) ? 3 : 1
//   }
// }
