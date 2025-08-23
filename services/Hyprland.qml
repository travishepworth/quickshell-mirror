import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    // Hyprland IPC socket path
    property string socketPath: "/tmp/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
    
    // Current active workspace
    property int activeWorkspace: 1
    
    // List of workspaces
    property var workspaces: []
    
    // Socket for Hyprland IPC
    property var hyprlandSocket: Socket {
        path: socketPath
        connected: true
        parser: SplitParser {
            splitMarker: "\n"
            onRead: message => handleHyprlandEvent(message)
        }
    }

    property var hyprctl: Process {
        id: hyprctlProcess
        property var pendingCallback: null
        property string buffer: ""   // <-- declare the buffer on this object

        function run(args, callback) {
            pendingCallback = callback
            buffer = ""              // <-- reset via the object's property
            command = ["hyprctl", ...args, "-j"]
            running = true
        }

        stdout: SplitParser {
            splitMarker: ""          // don't split; accumulate raw chunks
            onRead: data => {
                hyprctlProcess.buffer += data
                const s = hyprctlProcess.buffer.trim()
                if (!s)
                    return
                try {
                    const json = JSON.parse(s)
                    if (hyprctlProcess.pendingCallback)
                        hyprctlProcess.pendingCallback(json)
                    hyprctlProcess.pendingCallback = null
                    hyprctlProcess.buffer = ""   // clear after successful parse
                } catch (e) {
                    // not complete JSON yet; wait for more chunks
                }
            }
        }

        onRunningChanged: {
            if (!running && buffer.trim().length) {
                try {
                    const json = JSON.parse(buffer)
                    if (pendingCallback) pendingCallback(json)
                } catch (e) {
                    console.error("Failed to parse full hyprctl output:", buffer, e)
                }
                pendingCallback = null
                buffer = ""
            }
        }
    }
    // Initialize workspaces on startup
    Component.onCompleted: {
        updateWorkspaces()
        updateActiveWorkspace()
    }
    
    function handleHyprlandEvent(message) {
        const parts = message.split(">>")
        if (parts.length < 2) return
        
        const event = parts[0]
        const data = parts[1]
        
        switch(event) {
            case "workspace":
                activeWorkspace = parseInt(data)
                break
            case "createworkspace":
            case "destroyworkspace":
                updateWorkspaces()
                break
        }
    }
    
    function updateWorkspaces() {
        hyprctl.run(["workspaces"], (data) => {
            workspaces = data.map(ws => ({
                id: ws.id,
                name: ws.name,
                monitor: ws.monitor,
                windows: ws.windows
            })).sort((a, b) => a.id - b.id)
        })
    }
    
    function updateActiveWorkspace() {
        hyprctl.run(["activeworkspace"], (data) => {
            activeWorkspace = data.id
        })
    }
    
    function switchToWorkspace(id) {
        hyprctl.run(["dispatch", "workspace", id.toString()], null)
    }
}
