pragma Singleton
import QtQuick
import Quickshell.Io

// Shared on/off state for keeping the session awake. The Wayland idle
// inhibitor itself needs a visible surface, so it lives in the bar widget
// (modules/IdleInhibitor.qml) and binds to `enabled` here. Not persisted:
// a restart always starts with idle allowed.
//
//   qs -c axiom ipc call idleInhibit toggle
QtObject {
  id: root

  property bool enabled: false

  function toggle() {
    root.enabled = !root.enabled;
  }

  property IpcHandler _ipc: IpcHandler {
    target: "idleInhibit"

    function toggle(): void {
      root.toggle();
    }

    function enable(): void {
      root.enabled = true;
    }

    function disable(): void {
      root.enabled = false;
    }

    function status(): bool {
      return root.enabled;
    }
  }
}
