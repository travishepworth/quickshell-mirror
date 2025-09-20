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
  maxTextLength: 10
  elideText: true
}
