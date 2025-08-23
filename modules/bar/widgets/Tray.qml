import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.SystemTray as SysTray

RowLayout {
    spacing: 8
    
    property color iconColor: "#cdd6f4"
    property int iconSize: 20
    
    Repeater {
        model: SysTray.SystemTray.items
        
        Item {
            width: iconSize
            height: iconSize
            
            visible: modelData && (modelData.status === SysTray.SystemTray.Active || 
                     modelData.status === SysTray.SystemTray.Passive)
            
            Image {
                id: trayIcon
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                
                source: modelData && modelData.icon ? modelData.icon : ""
                sourceSize.width: width
                sourceSize.height: height
                
                fillMode: Image.PreserveAspectFit
                smooth: true
                
                // Fallback if no icon
                Rectangle {
                    anchors.fill: parent
                    visible: !parent.source || parent.status === Image.Error
                    color: "#45475a"
                    radius: 2
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData && modelData.title ? modelData.title.charAt(0).toUpperCase() : "?"
                        color: iconColor
                        font.pixelSize: 12
                    }
                }
            }
            
            MouseArea {
                id: trayMouseArea
                anchors.fill: parent
                
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                
                onClicked: (mouse) => {
                    if (!modelData) return
                    
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate(Math.round(mouse.x), Math.round(mouse.y))
                    } else if (mouse.button === Qt.RightButton) {
                        modelData.secondaryActivate(Math.round(mouse.x), Math.round(mouse.y))
                    } else if (mouse.button === Qt.MiddleButton) {
                        if (modelData.middleClickAction) {
                            modelData.middleClickAction()
                        }
                    }
                }
                
                onWheel: (wheel) => {
                    if (modelData) {
                        modelData.scroll(wheel.angleDelta.x, wheel.angleDelta.y)
                    }
                }
                
                hoverEnabled: true
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
            }
            
            // Simple tooltip implementation
            Rectangle {
                visible: trayMouseArea.containsMouse && modelData && modelData.title
                anchors.bottom: parent.top
                anchors.bottomMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                
                color: "#313244"
                border.color: "#45475a"
                radius: 4
                padding: 4
                
                width: tooltipText.width + 8
                height: tooltipText.height + 8
                
                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    text: modelData && modelData.title ? modelData.title : ""
                    color: "#cdd6f4"
                    font.pixelSize: 11
                }
            }
        }
    }
}
