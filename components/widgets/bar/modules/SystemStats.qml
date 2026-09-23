pragma ComponentBehavior: Bound
import QtQuick

import qs.services
import qs.config
import qs.components.reusable

// CPU / memory / temperature / GPU / disk readouts from SystemManager, one
// icon + value segment per enabled metric. Metrics the machine can't report
// (no GPU, no CPU sensor) are left out.
BaseWidget {
  id: root

  property var barConfig
  property var popouts
  property var panel
  property var screen
  property var properties

  readonly property var segments: {
    const p = properties;
    const list = [];
    if (p.showCpu)
      list.push({
        "icon": "\u{F0EE0}",
        "value": `${SystemManager.cpuUsage}%`,
        "level": SystemManager.cpuUsage
      });
    if (p.showMemory)
      list.push({
        "icon": "\u{F035B}",
        "value": p.memoryFormat === "used" ? `${(SystemManager.memUsedBytes / 1073741824).toFixed(1)}G` : `${SystemManager.memUsage}%`,
        "level": SystemManager.memUsage
      });
    if (p.showTemp && SystemManager.hasCpuTemp)
      list.push({
        "icon": "\u{F050F}",
        "value": `${SystemManager.cpuTemp}°`,
        "level": SystemManager.cpuTemp
      });
    if (p.showGpu && SystemManager.hasGpu)
      list.push({
        "icon": "\u{F08AE}",
        "value": `${SystemManager.gpuUsage}%`,
        "level": SystemManager.gpuUsage
      });
    const disk = SystemManager.disks[p.diskPath];
    if (p.showDisk && disk)
      list.push({
        "icon": "\u{F02CA}",
        "value": `${disk.usage}%`,
        "level": disk.usage
      });
    return list;
  }
  readonly property bool warning: segments.some(s => s.level >= properties.warnThreshold)
  readonly property color foregroundColor: Theme.resolveColor(properties.foregroundColor)

  isVertical: barConfig.vertical
  padding: segments.length > 0 ? Widget.padding : 0
  backgroundColor: Theme.resolveColor(warning ? properties.warnColor : properties.backgroundColor)

  // Ask only for what's shown; re-registering replaces the old request
  function register() {
    const p = properties;
    const metrics = [];
    if (p.showCpu)
      metrics.push("cpu");
    if (p.showMemory)
      metrics.push("mem");
    if (p.showTemp)
      metrics.push("cpuTemp");
    if (p.showGpu)
      metrics.push("gpu");
    if (p.showDisk)
      metrics.push("disk");
    SystemManager.acquire(root, {
      "interval": p.interval,
      "metrics": metrics,
      "diskPaths": p.showDisk ? [p.diskPath] : []
    });
  }
  onPropertiesChanged: register()
  Component.onCompleted: register()
  Component.onDestruction: SystemManager.release(root)

  content: Grid {
    columns: root.isVertical ? 1 : Math.max(1, root.segments.length)
    spacing: root.isVertical ? Widget.spacing : Widget.padding

    Repeater {
      model: root.segments

      delegate: Grid {
        id: segment
        required property var modelData

        columns: root.isVertical ? 1 : 2
        spacing: root.isVertical ? 0 : 4
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Text {
          text: segment.modelData.icon
          color: root.foregroundColor
          font.family: Appearance.fontFamily
          font.pixelSize: Appearance.fontSize
        }
        Text {
          text: segment.modelData.value
          color: root.foregroundColor
          font.family: Appearance.fontFamily
          font.pixelSize: Appearance.fontSize * (root.isVertical ? 0.7 : 0.9)
        }
      }
    }
  }
}
