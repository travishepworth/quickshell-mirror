// StatusIconWidget.qml
import QtQuick

import qs.services
import qs.components

BaseWidget {
  id: root

  // Status configuration
  property var command: []
  property int pollInterval: 2000
  property bool useExitCode: true  // Use exit code vs stdout for status

  // Icon configuration
  property var iconMap: ({})  // Map of status -> icon
  property string defaultIcon: "?"
  property string errorIcon: "⚠"
  property string loadingIcon: "⟳"
  property real iconScale: 1.2

  // Loading behavior
  property bool showLoadingIcon: true  // Set to false to prevent loading icon
  property int loadingDelay: 500  // Only show loading after this delay (ms)

  // Color mappings
  property var colorMap: ({})  // Map of status -> color
  property color defaultColor: Colors.orange
  property color errorColor: Colors.red
  property color loadingColor: Colors.surfaceAlt3

  // State
  property var currentStatus: undefined
  property string currentIcon: defaultIcon
  property bool isLoading: false
  property bool hasInitialized: false  // Track if we've gotten data at least once

  // Set background color based on status
  backgroundColor: getColorForStatus()

  function getIconForStatus() {
    // Only show loading icon if we haven't initialized yet or if explicitly enabled
    if (isLoading && showLoadingIcon && loadingIcon && !hasInitialized) {
      return loadingIcon;
    }

    if (currentStatus === undefined)
      return defaultIcon;
    if (currentStatus in iconMap)
      return iconMap[currentStatus];
    if (currentStatus < 0)
      return errorIcon;
    return defaultIcon;
  }

  function getColorForStatus() {
    // Similar logic for colors
    if (isLoading && showLoadingIcon && loadingColor && !hasInitialized) {
      return loadingColor;
    }

    if (currentStatus === undefined)
      return defaultColor;
    if (currentStatus in colorMap)
      return colorMap[currentStatus];
    if (currentStatus < 0)
      return errorColor;
    return defaultColor;
  }

  // Update icon when status changes
  onCurrentStatusChanged: {
    currentIcon = getIconForStatus();
  }

  // Icon display
  content: Component {
    Text {
      color: Colors.bg
      text: root.currentIcon
      font.family: Settings.fontFamily
      font.pixelSize: (Settings.fontSize)
    }
  }

  // Timer for delayed loading indicator
  Timer {
    id: loadingDelayTimer
    interval: root.loadingDelay
    repeat: false
    onTriggered: {
      if (poller.running && !root.hasInitialized) {
        root.isLoading = true;
        root.currentIcon = root.getIconForStatus();
      }
    }
  }

  // Status polling
  PollingProcess {
    id: poller
    interval: root.pollInterval
    command: root.command
    treatExitCodeAsStatus: root.useExitCode
    autoStart: root.command.length > 0

    onStatusChanged: (exitCode, stdout, stderr) => {
      // Clear loading state
      loadingDelayTimer.stop();
      root.isLoading = false;
      root.hasInitialized = true;

      if (root.useExitCode) {
        root.currentStatus = exitCode;
      } else {
        // Use stdout directly as the status (or icon if it's an icon)
        let output = stdout.trim();

        // Check if output is directly an icon (single character/emoji)
        if (output && output.length <= 4) {
          // Direct icon output - bypass iconMap
          root.currentIcon = output;
          root.currentStatus = output;
        } else {
          // Use as status key for iconMap
          root.currentStatus = output || exitCode;
        }
      }
    }

    onRunningChanged: {
      if (running) {
        // Only show loading after a delay, and only if we haven't initialized
        if (!root.hasInitialized && root.showLoadingIcon) {
          loadingDelayTimer.restart();
        }
      } else {
        loadingDelayTimer.stop();
        root.isLoading = false;
      }
    }
  }
}
