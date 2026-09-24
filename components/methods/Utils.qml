pragma Singleton
import QtQuick

// Pure helpers: text width and truncation, colors, calendar grids. No
// file access, processes or services (those live in services/).
QtObject {
  id: root

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

  // Check if color is dark
  function isColorDark(color) {
    const c = Qt.color(color);
    const luminance = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    return luminance < 0.5;
  }

  // Get contrasting text color for background
  function getContrastColor(backgroundColor) {
    return isColorDark(backgroundColor) ? "#FFFFFF" : "#000000";
  }

  // The 6 weeks (42 days) shown for a month, starting on `firstDay` (0 =
  // Sunday, as Date.getDay()): [{ day, month, year, inMonth, isToday }].
  // `today` is a date string (Date.toDateString()), so callers can bind
  // it to something that only changes once a day.
  function monthGrid(year, month, firstDay, today) {
    const first = new Date(year, month, 1);
    const start = new Date(year, month, 1 - ((first.getDay() - firstDay + 7) % 7));
    const days = [];
    for (let i = 0; i < 42; i++) {
      const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
      days.push({
        "day": d.getDate(),
        "month": d.getMonth(),
        "year": d.getFullYear(),
        "inMonth": d.getMonth() === month,
        "isToday": d.toDateString() === today
      });
    }
    return days;
  }
}
