import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    
    property int workspaceId: 1
    property bool isActive: false
    property real scale: 0.15
    
    signal clicked()
    
    color: "#3c3836" // Gruvbox bg1
    radius: 4
    border.width: isActive ? 3 : 1
    border.color: isActive ? "#d79921" : "#504945" // Gruvbox yellow/bg2
    
    Component.onCompleted: {
        console.log("WorkspaceCell", workspaceId, "created at position", x, y, "with size", width, "x", height);
    }
    
    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }
    
    Behavior on border.width {
        NumberAnimation { duration: 150 }
    }
    
    // Workspace number label
    Text {
        anchors.centerIn: parent
        text: root.workspaceId.toString()
        font.family: "VictorMono Nerd Font"
        font.pixelSize: Math.min(root.width, root.height) * 0.3
        font.weight: Font.Bold
        color: "#a89984" // Gruvbox fg3
        opacity: 0.3
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        
        onClicked: {
            root.clicked();
        }
    }
    
    // Drop area for windows
    DropArea {
        id: dropArea
        anchors.fill: parent
        
        property bool containsDrag: false
        
        onEntered: {
            containsDrag = true;
            root.color = "#504945"; // Gruvbox bg2
        }
        
        onExited: {
            containsDrag = false;
            root.color = "#3c3836"; // Gruvbox bg1
        }
        
        onDropped: {
            containsDrag = false;
            root.color = "#3c3836"; // Gruvbox bg1
        }
    }
    
    states: [
        State {
            name: "hovered"
            when: mouseArea.containsMouse && !dropArea.containsDrag
            PropertyChanges {
                target: root
                color: "#504945" // Gruvbox bg2
            }
        },
        State {
            name: "dragging"
            when: dropArea.containsDrag
            PropertyChanges {
                target: root
                color: "#665c54" // Gruvbox bg3
                border.color: "#d79921" // Gruvbox yellow
            }
        }
    ]
    
    transitions: Transition {
        ColorAnimation {
            properties: "color"
            duration: 150
        }
    }
}
