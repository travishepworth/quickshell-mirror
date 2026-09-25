pragma Singleton
import QtQuick
import Quickshell
import qs.config

/*
 * Startup checks for what the whole shell needs to look right. Today that's
 * the icon font: every icon is a Material Symbols name (StyledIcon), which
 * shows as a word without it. Warns in the log and notifies once per qs
 * launch. Created from shell.qml's `_services`.
 */
Singleton {
  id: root

  readonly property bool iconFontInstalled: Qt.fontFamilies().includes(Appearance.iconFamily)

  // Survives hot reloads, so only a qs launch notifies again
  PersistentProperties {
    id: _run
    reloadableId: "axiomDependencies"
    property bool notified: false
  }

  // Let the notification server come up first
  Timer {
    id: _notify
    interval: 3000
    onTriggered: {
      _run.notified = true;
      NotificationManager.sendNotification("axiom", I18n.tr("Icon font missing"), I18n.tr("Install {0} ({1}), then restart the shell.", Appearance.iconFamily, "ttf-material-symbols-variable"));
    }
  }

  Component.onCompleted: {
    if (root.iconFontInstalled)
      return;
    console.warn(`[DependencyManager] ${Appearance.iconFamily} is not installed (ttf-material-symbols-variable): icons will show as words`);
    if (!_run.notified)
      _notify.start();
  }
}
