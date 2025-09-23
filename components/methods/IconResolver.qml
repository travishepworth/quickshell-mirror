pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
  id: root

  function resolveWindowIcon(windowClass, windowTitle) {
    let baseIcon = Quickshell.iconPath(AppSearch.guessIcon(windowClass), "image-missing");
    
    // Special case for kitty running nvim
    if (baseIcon.includes("kitty") && windowTitle?.toLowerCase().includes("nvim")) {
      return Quickshell.iconPath("nvim", "image-missing");
    }
    
    return baseIcon;
  }
}
