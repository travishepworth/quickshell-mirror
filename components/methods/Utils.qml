pragma Singleton
import QtQuick
import Quickshell

import qs.config

/* Assorted functions, unorganized. Use your '/' key */
QtObject {
  id: utils

  function charWidth(codePoint) {
    return ((codePoint >= 0x1100 && codePoint <= 0x115F) || codePoint === 0x2329 || codePoint === 0x232A || (codePoint >= 0x2E80 && codePoint <= 0xA4CF && codePoint !== 0x303F) || (codePoint >= 0xAC00 && codePoint <= 0xD7A3) || (codePoint >= 0xF900 && codePoint <= 0xFAFF) || (codePoint >= 0xFE30 && codePoint <= 0xFE6F) || (codePoint >= 0xFF00 && codePoint <= 0xFF60) || (codePoint >= 0xFFE0 && codePoint <= 0xFFE6) || (codePoint >= 0x20000 && codePoint <= 0x3FFFD)) ? 2 : 1;
  }

  function visualWidth(text) {
    let width = 0;
    for (const ch of text)
      width += charWidth(ch.codePointAt(0));
    return width;
  }

  function truncate(text, maxLength, ellipsis = "...") {
    const fullWidth = visualWidth(text);
    if (fullWidth <= maxLength)
      return text;

    const ellipsisWidth = visualWidth(ellipsis);
    const budget = maxLength - ellipsisWidth;

    let width = 0;
    let result = "";
    for (const ch of text) {
      const w = charWidth(ch.codePointAt(0));
      if (width + w > budget)
        break;
      result += ch;
      width += w;
    }
    return result + ellipsis;
  }

  function getFileContent(filepath) {
    try {
      // WAY faster than using FileView for reads for some reason
      var xhr = new XMLHttpRequest();
      xhr.open("GET", filepath, false);
      xhr.send();
      if (xhr.status === 200 || xhr.status === 0) {
        return xhr.responseText;
      }
    } catch (e) {
      console.error("Could not read file:", filepath, e);
    }
    return null;
  }

  // Launch an external application. Detached, so launches never queue
  // behind (or get dropped by) one that is still running.
  function launch(command) {
    Quickshell.execDetached(typeof command === "string" ? [command] : command);
  }

  function executeWallpaperScript(wallpaperUrl) {
    if (!wallpaperUrl || wallpaperUrl === "")
      return;

    wallpaperUrl = wallpaperUrl.replace("file://", "");
    const scriptPath = Config.scriptsPath + "setWallpaper.sh"; // Adjust path as needed
    const command = [scriptPath, wallpaperUrl];
    launch(command);
  }

  // Launch with arguments
  function launchWithArgs(program, ...args) {
    Quickshell.execDetached([program].concat(args));
  }

  // Format time duration (for timer widgets)
  function formatDuration(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    } else {
      return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
  }

  // Format an epoch-ms timestamp as a short relative time ("now", "5m", "3h", "2d")
  function formatRelativeTime(epochMs) {
    const diffSec = Math.max(0, Math.floor((Date.now() - epochMs) / 1000));
    if (diffSec < 60)
      return I18n.tr("now");
    if (diffSec < 3600)
      return I18n.tr("{0}m", Math.floor(diffSec / 60));
    if (diffSec < 86400)
      return I18n.tr("{0}h", Math.floor(diffSec / 3600));
    return I18n.tr("{0}d", Math.floor(diffSec / 86400));
  }

  // Format bytes to human readable
  function formatBytes(bytes, decimals = 2) {
    if (bytes === 0)
      return '0 Bytes';

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];

    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }

  // Clamp value between min and max
  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  // Linear interpolation
  function lerp(start, end, amount) {
    return start + (end - start) * amount;
  }

  // Map value from one range to another
  function map(value, inMin, inMax, outMin, outMax) {
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }

  // Generate a unique ID
  function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  // Parse color and adjust alpha
  function setAlpha(color, alpha) {
    const c = Qt.color(color);
    return Qt.rgba(c.r, c.g, c.b, alpha);
  }

  // Check if color is dark
  function isColorDark(color) {
    const c = Qt.color(color);
    const luminance = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    return luminance < 0.5;
  }

  // Truncate text with ellipsis
  // function truncate(text, maxLength, ellipsis = "...") {
  //   if (text.length <= maxLength)
  //     return text;
  //   return text.slice(0, maxLength - ellipsis.length) + ellipsis;
  // }

  // Get contrasting text color for background
  function getContrastColor(backgroundColor) {
    return isColorDark(backgroundColor) ? "#FFFFFF" : "#000000";
  }

  // Array utilities
  function arrayRemove(array, item) {
    const index = array.indexOf(item);
    if (index > -1) {
      array.splice(index, 1);
    }
    return array;
  }

  function arrayUnique(array) {
    return [...new Set(array)];
  }

  function arrayChunk(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  function getDefaultColors() {
    return {
      "base00": "#0c0c0c",
      "base01": "#1c1c1c",
      "base02": "#2c2c2c",
      "base03": "#444444",
      "base04": "#a0a0a0",
      "base05": "#cccccc",
      "base06": "#e0e0e0",
      "base07": "#f0f0f0",
      "base08": "#cc0000",
      "base09": "#d75f00",
      "base0A": "#bba600",
      "base0B": "#00a800",
      "base0C": "#00a8a8",
      "base0D": "#0066cc",
      "base0E": "#a800a8",
      "base0F": "#a85f00"
    };
  }

  function getDefaultSemanticColors() {
    return {
      "background": "base00",
      "backgroundAlt": "base01",
      "backgroundHighlight": "base02",
      "foreground": "base05",
      "foregroundAlt": "base04",
      "foregroundHighlight": "base06",
      "foregroundInactive": "base03",
      "border": "base02",
      "borderFocus": "base0D",
      "accent": "base0E",
      "accentAlt": "base0C",
      "success": "base0B",
      "warning": "base0A",
      "error": "base08",
      "info": "base0C",
      "red": "base08",
      "green": "base0B",
      "yellow": "base0A",
      "blue": "base0D",
      "magenta": "base0E",
      "cyan": "base0C",
      "white": "base05",
      "bg0": "base00",
      "bg1": "base01",
      "bg2": "base02",
      "fg3": "base03",
      "fg2": "base04",
      "fg1": "base05"
    };
  }
}
