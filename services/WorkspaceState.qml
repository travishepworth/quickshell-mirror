// File: services/WorkspaceTracker.qml
// This is the singleton service that manages all workspace state
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: root
    
    // Bit flags for rows with windows (5 bits, one per row)
    property int rowFlags: 0
    
    // Cached states
    property var states: ({})
    property var icons: ({})
    
    // Version counter to detect changes
    property int version: 0
    
    function update() {
        const workspaces = Hyprland.workspaces.values
        const newStates = {}
        let newFlags = 0
        
        // Initialize all workspaces as empty
        for (let id = 1; id <= 25; id++) {
            newStates[id] = false
        }
        
        // Single pass through existing workspaces
        for (let i = 0; i < workspaces.length; i++) {
            const ws = workspaces[i]
            if (ws.id >= 1 && ws.id <= 25) {
                const hasWin = ws.toplevels && ws.toplevels.values.length > 0
                newStates[ws.id] = hasWin
                if (hasWin) {
                    newFlags |= (1 << Math.floor((ws.id - 1) / 5))
                }
            }
        }
        
        // Only update icons if something changed
        let statesChanged = false
        for (let id = 1; id <= 25; id++) {
            if (states[id] !== newStates[id]) {
                statesChanged = true
                break
            }
        }
        
        if (statesChanged || Object.keys(states).length === 0) {
            rowFlags = newFlags
            states = newStates
            updateIcons()
            version++
        }
    }
    
    function updateIcons() {
        const newIcons = {}
        
        // Pre-calculate icons for all 25 workspaces
        for (let id = 1; id <= 25; id++) {
            if (states[id]) {
                newIcons[id] = ""
                continue
            }
            
            const row = Math.floor((id - 1) / 5)
            let above = 0, below = 0
            
            // Check for nearest rows with windows using bit operations
            for (let r = row - 1; r >= 0 && above === 0; r--) {
                if (rowFlags & (1 << r)) above = row - r
            }
            for (let r = row + 1; r < 5 && below === 0; r++) {
                if (rowFlags & (1 << r)) below = r - row
            }
            
            if (above && below) {
                newIcons[id] = "󰓎"
            } else if (above) {
                newIcons[id] = ["", "", "", "", ""][Math.min(above - 1, 4)]
            } else if (below) {
                newIcons[id] = ["", "", "", "", ""][Math.min(below - 1, 4)]
            } else {
                newIcons[id] = ""
            }
        }
        
        icons = newIcons
    }
    
    function getIcon(id) {
        return icons[id] || ""
    }
    
    function hasWindows(id) {
        return states[id] || false
    }
    
    // Also provide a helper to get workspace by ID
    function getWorkspace(id) {
        const arr = Hyprland.workspaces.values
        for (let i = 0; i < arr.length; i++) {
            if (arr[i].id === id) return arr[i]
        }
        return null
    }
    
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            root.update()
        }
    }
    
    Component.onCompleted: update()
}
