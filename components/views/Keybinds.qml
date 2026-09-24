pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.components.content.parts.keybinds

BaseView {
  id: root

  KeybindDisplay {
    keybinds: KeybindManager.keybindings
    cardWidth: root.grid.unit
    maxHeight: root.grid.availableHeight
  }
}
