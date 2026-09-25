pragma Singleton
import QtQuick
import qs.services

// Reader for the Workspaces section: the workspace layout the bar widget,
// the overview, the WorkspacesMap module and HyprlandManager's navigation
// share. Named WorkspacesConfig because `Workspaces` is a bar widget type.
QtObject {
  id: root

  readonly property var _c: ConfigManager.config.Workspaces

  // Grid: each monitor owns columns × rows ids, in Hyprland's monitor order.
  // Standard: ids 1..count, shared by every monitor.
  readonly property bool grid: _c.layout === "grid"
  readonly property int count: _c.count
  readonly property int columns: grid ? _c.columns : count
  readonly property int rows: grid ? _c.rows : 1
  // Workspaces a monitor shows
  readonly property int size: grid ? columns * rows : count
  readonly property bool wrap: _c.wrap
  readonly property bool animate: grid && _c.animate
  // The overview board's columns: the grid's, else near square
  readonly property int boardColumns: grid ? columns : Math.ceil(Math.sqrt(count))
  readonly property int boardRows: Math.ceil(size / boardColumns)

  // First id of the monitor at `monitorIndex` (in Hyprland's order)
  function baseFor(monitorIndex) {
    return grid ? Math.max(0, monitorIndex) * size + 1 : 1;
  }
}
