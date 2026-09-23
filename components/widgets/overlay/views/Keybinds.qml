pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.components.widgets.overlay.modules.keybinds

BaseView {
  id: view

  KeybindDisplay {
    keybinds: HyprConfigManager.keybindings
    screen: view.screen
  }
}
