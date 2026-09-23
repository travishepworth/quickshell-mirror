pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.overlay
import qs.components.widgets.overlay.modules.common
import qs.components.widgets.bar.popouts.content

// Pending package updates (shares the bar's PackageUpdates checks).
// Compact shows the count only.
// properties: { intervalMinutes, includeAur, aurHelper }
OverlayCard {
  id: root

  readonly property int total: PackageUpdates.repoPackages.length + PackageUpdates.aurPackages.length

  function register() {
    PackageUpdates.acquire(root, {
      "intervalMinutes": root.properties.intervalMinutes ?? 60,
      "aurHelper": root.properties.includeAur ? (root.properties.aurHelper ?? "paru") : ""
    });
  }
  onPropertiesChanged: register()
  Component.onCompleted: register()
  Component.onDestruction: PackageUpdates.release(root)

  StatFigure {
    visible: root.compact
    anchors.centerIn: parent
    value: PackageUpdates.checking && root.total === 0 ? "…" : String(root.total)
    label: I18n.tr("updates")
    valueColor: root.total > 0 ? Theme.accent : Theme.foreground
  }

  ColumnLayout {
    visible: !root.compact
    anchors.fill: parent
    anchors.margins: root.pad / 2
    spacing: 0

    ModuleHeader {
      Layout.margins: root.pad / 2
      icon: "\u{F06B0}"
      title: root.total > 0 ? I18n.tr("{0} updates", root.total) : I18n.tr("Up to date")
      StyledText {
        visible: PackageUpdates.checking
        text: I18n.tr("checking…")
        textSize: Appearance.fontSize - 2
        opacity: 0.6
      }
    }

    UpdatesPopout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      wrapper: null
      embedded: true
      repoPackages: PackageUpdates.repoPackages
      aurPackages: PackageUpdates.aurPackages
      // Rows of roughly one text line each
      maxRows: Math.max(3, Math.floor(height / (Appearance.fontSize * 2)) - 4)
    }
  }
}
