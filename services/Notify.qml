pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  // Simple send function
  function send(title, message) {
    sendNotification(title, message, "normal", "");
  }

  // Send with urgency
  function sendUrgent(title, message) {
    sendNotification(title, message, "critical", "");
  }

  // Send with icon
  function sendWithIcon(title, message, icon) {
    sendNotification(title, message, "normal", icon);
  }

  // Preset types
  function info(title, message) {
    sendNotification(title, message, "normal", "dialog-information");
  }

  function warning(title, message) {
    sendNotification(title, message, "normal", "dialog-warning");
  }

  function error(title, message) {
    sendNotification(title, message, "critical", "dialog-error");
  }

  function success(title, message) {
    sendNotification(title, message, "normal", "emblem-default");
  }

  // Full control
  function sendNotification(title, message, urgency, icon) {
    let cmd = ["notify-send"];

    if (urgency && urgency !== "normal") {
      cmd.push("-u", urgency);
    }

    if (icon) {
      cmd.push("-i", icon);
    }

    cmd.push(title || "", message || "");

    process.command = cmd;
    process.running = true;
  }

  // Internal process
  property var process: Process {
    id: process
  }
}
