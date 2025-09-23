pragma Singleton

import Quickshell
import Quickshell.Hyprland

import qs.config

Singleton {
  id: root

  function getToplevelFromAddress(address) {
    for (let toplevel of Hyprland.toplevels.values) {
      let formattedAddress = "0x" + toplevel.address;
      if (formattedAddress === address) {
        return toplevel.wayland;
      }
    }
    return null;
  }

  function moveWindowToWorkspace(windowAddress, targetWorkspace) {
    Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${windowAddress}`);
  }

  function closeWindow(windowAddress) {
    Hyprland.dispatch(`closewindow address:${windowAddress}`);
  }

  function focusWindow(windowAddress) {
    Hyprland.dispatch(`focuswindow address:${windowAddress}`);
  }

  function getWorkspacePosition(workspaceId, gridSize) {
    let index = workspaceId - 1;
    return {
      row: Math.floor(index / gridSize),
      col: index % gridSize
    };
  }

  function calculateWindowConstraints(windowData, scale, workspaceWidth, workspaceHeight) {
    let scaledX = ((windowData?.at[0] ?? 0) * scale);
    let scaledY = ((windowData?.at[1] ?? 0) * scale);
    let scaledWidth = Math.max((windowData?.size[0] ?? 100) * scale, 20);
    let scaledHeight = Math.max((windowData?.size[1] ?? 100) * scale, 20);

    return {
      x: Math.min(Math.max(scaledX, 0), Math.max(workspaceWidth - scaledWidth, 0)),
      y: Math.min(Math.max(scaledY, 0), Math.max(workspaceHeight - scaledHeight, 0)),
      width: scaledWidth,
      height: scaledHeight
    };
  }

  function getTargetWorkspaceFromPosition(x, y, width, height, workspaceWidth, workspaceHeight, workspaceSpacing, gridSize) {
    let centerX = x + (width / 2);
    let centerY = y + (height / 2);

    let col = Math.floor(centerX / (workspaceWidth + workspaceSpacing));
    let row = Math.floor(centerY / (workspaceHeight + workspaceSpacing));

    col = Math.max(0, Math.min(col, gridSize - 1));
    row = Math.max(0, Math.min(row, gridSize - 1));

    return row * gridSize + col + 1;
  }
}
