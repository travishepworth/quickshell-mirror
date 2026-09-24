pragma Singleton
import QtQuick

// Synchronous whole-file reads, for the few places that need a file's
// contents during a binding or initializer (config, schema, theme, state).
// Watching and writing stay with FileView.
QtObject {
  // Contents of a file URL (file:// or relative to the caller's resolved
  // URL), or null if it can't be read. Much faster than FileView for a
  // one-off read.
  function read(url) {
    try {
      const xhr = new XMLHttpRequest();
      xhr.open("GET", url, false);
      xhr.send();
      if (xhr.status === 200 || xhr.status === 0)
        return xhr.responseText;
    } catch (e) {
      console.error("[FileManager] Could not read file:", url, e);
    }
    return null;
  }
}
