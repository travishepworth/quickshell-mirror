pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.components.content.parts.keybinds

BaseView {
  id: view

  KeybindDisplay {
    keybinds: KeybindManager.keybindings
    screen: view.screen
  }
}
