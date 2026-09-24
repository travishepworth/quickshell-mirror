pragma Singleton
import QtQuick
import qs.services

// Reader for the OSD section (the volume on-screen display). Named
// OSDConfig because `OSD` is the module type.
QtObject {
  readonly property var _c: ConfigManager.config.OSD

  readonly property bool enabled: _c.enabled
  // "general" | "primaryBar" | "focused" (see General.screensFor)
  readonly property string monitors: _c.monitors
  // A Bar.Location
  readonly property int edge: Bar.getLocationFromString(_c.edge)
  // 0-1 along the edge, as EdgePopout.position expects
  readonly property real position: _c.position / 100
  readonly property bool vertical: _c.orientation === "Vertical"
  // Bars in one line along the edge, whatever their orientation
  readonly property bool alongEdge: _c.alongEdge
  // The edge trigger strip also opens it
  readonly property bool openOnHover: _c.openOnHover
  readonly property int timeout: _c.timeout
  // [{ app, icon, showOsd }]; see the schema for the "other"/"master"
  // sentinels. Goes through a string so a reload that leaves the list
  // unchanged doesn't rebuild the OSD's volume bars.
  readonly property string _appsJson: JSON.stringify(_c.apps)
  readonly property var apps: JSON.parse(_appsJson)
}
