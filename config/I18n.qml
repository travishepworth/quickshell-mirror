pragma Singleton
import QtQuick
import qs.config
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Translation and locale for the shell's text (General.language).
//
// English is the source language: write strings in English, inline, as
// I18n.tr("Text"). Each other language is one file, config/i18n/<code>.json:
//   { "_meta": { "name": "日本語", "locale": "ja_JP", "formats": { ... } },
//     "strings": { "English text": "translation", ... } }
// Dropping in a file adds the language to the settings (x-options
// "languages"); a string with no entry falls back to English. Placeholders
// {0}, {1}, ... take the extra arguments, so dynamic text stays one
// translatable string: I18n.tr("{0} updates", count).
// Settings titles/descriptions come from the schema and are translated by
// the settings UI, so they need no code. scripts/check_i18n.py lists
// missing/unused entries (--fill adds the missing ones, empty).
//
// tr() and formatDate() read the language, so bindings using them update
// when it (or the active dictionary file) changes.
QtObject {
  id: root

  readonly property string language: General.language

  // [{ code, name, locale }], English first, then one per dictionary file
  property var languages: [root._english]
  readonly property var current: root.languages.find(l => l.code === root.language) ?? root._english
  // For day/month names and date formats
  readonly property var locale: Qt.locale(root.current.locale)

  function tr(text, ...args) {
    let result = (root.current.code !== "en" && root._strings[text]) || text;
    args.forEach((arg, i) => result = result.split(`{${i}}`).join(String(arg)));
    return result;
  }

  // Qt date format strings, with names (ddd, MMMM, AP) in the shell's language
  function formatDate(date, format) {
    return date.toLocaleString(root.locale, format);
  }

  // A named date format in the shell's language: the dictionary's
  // _meta.formats entry, else the English one below
  function dateFormat(name) {
    return root.current.formats?.[name] ?? root._formats[name] ?? name;
  }

  function languageName(code) {
    return root.languages.find(l => l.code === code)?.name ?? code;
  }

  // -- Private --
  readonly property var _english: ({
      "code": "en",
      "name": "English",
      "locale": "en_US"
    })
  readonly property var _formats: ({
      "longDate": "dddd, d MMMM",
      "mediumDate": "MMM d, yyyy",
      "shortDate": "ddd d MMM",
      "monthYear": "MMMM yyyy",
      "fullDate": "dddd, MMMM d, yyyy",
      "time24": "HH:mm",
      "time12": "h:mm AP"
    })
  readonly property string _dir: Quickshell.shellPath("config/i18n")
  property var _strings: ({})

  function _read(path) {
    try {
      const xhr = new XMLHttpRequest();
      xhr.open("GET", "file://" + path, false);
      xhr.send();
      return JSON.parse(xhr.responseText);
    } catch (e) {
      console.warn("[I18n] Could not read dictionary:", path, e);
      return null;
    }
  }

  function _scan() {
    const found = [root._english];
    for (let i = 0; i < root._files.count; i++) {
      const code = root._files.get(i, "fileBaseName");
      const meta = root._read(`${root._dir}/${code}.json`)?._meta ?? {};
      found.push({
        "code": code,
        "name": meta.name ?? code,
        "locale": meta.locale ?? code,
        "formats": meta.formats ?? {}
      });
    }
    root.languages = found;
  }

  property FolderListModel _files: FolderListModel {
    folder: "file://" + root._dir
    nameFilters: ["*.json"]
    showDirs: false
    onCountChanged: root._scan()
  }

  // The active dictionary, reloaded when the file is edited
  property FileView _dictionary: FileView {
    path: root.current.code !== "en" ? `${root._dir}/${root.current.code}.json` : ""
    watchChanges: true
    onFileChanged: reload()
    onPathChanged: {
      if (path === "")
        root._strings = {};
    }
    onLoaded: {
      try {
        root._strings = JSON.parse(text()).strings ?? {};
        console.log(`[I18n] ${root.current.name}: ${Object.keys(root._strings).length} strings`);
      } catch (e) {
        console.warn("[I18n] Invalid dictionary:", path, e);
      }
    }
  }
}
