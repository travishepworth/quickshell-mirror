pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.content.parts
import qs.components.content.base

// Live graphs of system metrics: the current value over a minute of
// history per metric. Metrics sit side by side in wide slots and stack in
// square/tall ones; compact shows the first metric only.
// properties: { metrics: ["cpu", "mem", "gpu", "cpuTemp", "net"] }
Card {
  id: root

  readonly property var knownMetrics: ["cpu", "mem", "gpu", "cpuTemp", "net"]
  // Depends on the config only (never on live values), so the graphs and
  // the SystemManager registration aren't rebuilt on every sample
  readonly property var metrics: (root.properties.metrics ?? ["cpu", "mem"]).filter(m => root.knownMetrics.includes(m))
  readonly property var shown: root.compact ? root.metrics.slice(0, 1) : root.metrics

  function formatRate(bytes) {
    const units = ["B/s", "KB/s", "MB/s", "GB/s"];
    let i = 0;
    while (bytes >= 1024 && i < units.length - 1) {
      bytes /= 1024;
      i++;
    }
    return [bytes < 10 && i > 0 ? bytes.toFixed(1) : Math.round(bytes), units[i]];
  }

  // What each metric shows: label, value, unit, subtitle, history, scale
  function info(metric) {
    switch (metric) {
    case "cpu":
      return {
        "label": "CPU",
        "value": Math.round(SystemManager.cpuUsage),
        "unit": "%",
        "sub": SystemManager.hasCpuTemp ? `${SystemManager.cpuTemp}°C` : "",
        "history": SystemManager.cpuHistory,
        "max": 100,
        "color": Theme.accent
      };
    case "mem":
      return {
        "label": I18n.tr("Memory"),
        "value": Math.round(SystemManager.memUsage),
        "unit": "%",
        "sub": `${(SystemManager.memUsedBytes / 1073741824).toFixed(1)} / ${(SystemManager.memTotalBytes / 1073741824).toFixed(1)} GiB`,
        "history": SystemManager.memHistory,
        "max": 100,
        "color": Theme.success
      };
    case "gpu":
      return {
        "label": "GPU",
        "value": Math.round(SystemManager.gpuUsage),
        "unit": "%",
        "sub": SystemManager.gpuTemp > 0 ? `${SystemManager.gpuTemp}°C` : "",
        "history": SystemManager.gpuHistory,
        "max": 100,
        "color": Theme.info
      };
    case "cpuTemp":
      return {
        "label": I18n.tr("CPU temp"),
        "value": SystemManager.cpuTemp,
        "unit": "°C",
        "sub": "",
        "history": SystemManager.cpuTempHistory,
        "max": 100,
        "color": Theme.warning
      };
    case "net":
      {
        const rx = root.formatRate(SystemManager.netRx);
        const tx = root.formatRate(SystemManager.netTx);
        return {
          "label": I18n.tr("Network"),
          "value": rx[0],
          "unit": rx[1],
          "sub": `↑ ${tx[0]} ${tx[1]}`,
          "history": SystemManager.netRxHistory,
          "max": 0,
          "color": Theme.accentAlt
        };
      }
    }
    return null;
  }

  function register() {
    SystemManager.acquire(root, {
      "metrics": root.metrics,
      "history": true,
      "interval": 1000
    });
  }
  onMetricsChanged: register()
  Component.onCompleted: register()
  Component.onDestruction: SystemManager.release(root)

  GridLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    columns: root.shape === "horizontal" ? Math.max(1, root.shown.length) : 1
    columnSpacing: root.pad
    rowSpacing: root.pad

    Repeater {
      model: root.shown

      ColumnLayout {
        id: panel
        required property string modelData
        readonly property var metric: root.info(panel.modelData)
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 2

        RowLayout {
          Layout.fillWidth: true
          StatFigure {
            label: panel.metric.label
            value: String(panel.metric.value)
            unit: panel.metric.unit
            valueColor: panel.metric.color
            valueSize: root.compact ? Appearance.fontSize * 1.6 : Appearance.fontSize * 2
          }
          Item {
            Layout.fillWidth: true
          }
          StyledText {
            visible: !root.compact && panel.metric.sub !== ""
            Layout.alignment: Qt.AlignTop
            text: panel.metric.sub
            textSize: Appearance.fontSize - 2
            opacity: 0.7
          }
        }

        Sparkline {
          Layout.fillWidth: true
          Layout.fillHeight: true
          values: panel.metric.history
          maxValue: panel.metric.max
          lineColor: panel.metric.color
          capacity: SystemManager.historyLength
        }
      }
    }
  }
}
