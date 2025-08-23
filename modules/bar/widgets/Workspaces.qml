// Widgets/Workspaces.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "root:/services" as Services

RowLayout {
    id: root
    required property var screen   // pass panel.screen from the window

    property color activeColor: "#89b4fa"
    property color inactiveColor: "#45475a"
    property color emptyColor: "#313244"

    // The Hyprland monitor object for this window's screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.workspaces.focused

    // Derive which 10-workspace block to show (1-10, 11-20, …) from the current ws
    readonly property int groupBase: {
        const id = monitor.activeWorkspace ? monitor.activeWorkspace.id : 1;
        return Math.floor((id - 1) / 10) * 10 + 1;
    }
    readonly property int groupSize: 10

    Repeater {
        model: root.groupSize
        delegate: Rectangle {

            readonly property int realId: root.groupBase + index
            readonly property HyprlandWorkspace ws: wsById(realId)

            readonly property bool isActive: monitor.activeWorkspace && monitor.activeWorkspace.id === realId
            readonly property bool exists: ws !== null

            function wsById(id) {
                const arr = Hyprland.workspaces.values;
                for (let i = 0; i < arr.length; i++) {
                    if (arr[i].id === id)
                        return arr[i];
                }
                return null;
            }

            readonly property bool hasWindows: (function () {
                    if (!ws)
                        return false;
                    const tops = ws.toplevels;
                    return tops && tops.values && tops.values.length > 0;
                })()

            function printWs() {
                console.log(`realId: ${realId}`);
                console.log(`${hasWindows} toplevels`);
                console.log("---");
            }

            width: 24
            height: 24
            radius: 4
            color: isActive ? root.activeColor : hasWindows ? root.inactiveColor : root.emptyColor
            border.width: isActive ? 2 : 0
            border.color: "#cdd6f4"

            Text {
                anchors.centerIn: parent
                // Show local 1..10; switch to `realId.toString()` if you prefer 11..20
                text: (index + 1).toString()
                color: "#cdd6f4"
                font.pixelSize: 12
                font.bold: isActive
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    printWs();
                    Hyprland.dispatch(`workspace ${realId}`); // create/activate it
                }
                hoverEnabled: true
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
            }

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }
    }
}
