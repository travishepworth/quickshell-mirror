pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components.reusable
import qs.components.widgets.overlay

// A clock with the date, plus a month calendar when there's room (square
// and tall slots of at least one card). Arrows page through months.
// properties: { use24h, showSeconds }
OverlayCard {
  id: root

  readonly property bool showCalendar: !root.compact && root.shape !== "horizontal" && root.rows >= 2
  readonly property date now: clock.date
  property int monthOffset: 0
  readonly property date shownMonth: new Date(root.now.getFullYear(), root.now.getMonth() + root.monthOffset, 1)
  readonly property int firstDay: Qt.locale().firstDayOfWeek % 7
  readonly property string timeFormat: (root.properties.use24h ?? true ? "HH:mm" : "h:mm") + (root.properties.showSeconds ? ":ss" : "") + (root.properties.use24h ?? true ? "" : " AP")

  // 6 weeks of days for the shown month: { day, inMonth, today }
  readonly property var days: {
    const first = root.shownMonth;
    const start = new Date(first);
    start.setDate(1 - ((first.getDay() - root.firstDay + 7) % 7));
    const out = [];
    for (let i = 0; i < 42; i++) {
      const d = new Date(start);
      d.setDate(start.getDate() + i);
      out.push({
        "day": d.getDate(),
        "inMonth": d.getMonth() === first.getMonth(),
        "today": d.toDateString() === root.now.toDateString()
      });
    }
    return out;
  }

  SystemClock {
    id: clock
    precision: root.properties.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.pad
    spacing: Widget.spacing

    // Clock
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: !root.showCalendar
      spacing: 0
      Item {
        visible: !root.showCalendar
        Layout.fillHeight: true
      }
      StyledText {
        Layout.alignment: root.showCalendar ? Qt.AlignLeft : Qt.AlignHCenter
        text: Qt.formatDateTime(root.now, root.timeFormat)
        textSize: root.compact ? Appearance.fontSize * 2 : root.showCalendar ? Appearance.fontSize * 2.6 : Math.min(root.height * 0.3, root.width * 0.16)
        font.bold: true
      }
      StyledText {
        Layout.alignment: root.showCalendar ? Qt.AlignLeft : Qt.AlignHCenter
        text: Qt.formatDate(root.now, root.compact ? "ddd d MMM" : "dddd, d MMMM")
        textSize: root.compact ? Appearance.fontSize - 2 : Appearance.fontSize
        opacity: 0.7
      }
      Item {
        visible: !root.showCalendar
        Layout.fillHeight: true
      }
    }

    // Calendar
    ColumnLayout {
      visible: root.showCalendar
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Widget.spacing / 2

      RowLayout {
        Layout.fillWidth: true
        StyledText {
          Layout.fillWidth: true
          text: Qt.formatDate(root.shownMonth, "MMMM yyyy")
          font.bold: true
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.monthOffset = 0
          }
        }
        Repeater {
          model: [["\u{F0141}", -1], ["\u{F0142}", 1]]
          StyledText {
            required property var modelData
            text: modelData[0]
            textColor: Theme.accent
            MouseArea {
              anchors.fill: parent
              anchors.margins: -4
              cursorShape: Qt.PointingHandCursor
              onClicked: root.monthOffset += parent.modelData[1]
            }
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 7
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
          model: 7
          StyledText {
            required property int index
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.NarrowFormat)
            textSize: Appearance.fontSize - 2
            opacity: 0.6
          }
        }
        Repeater {
          model: root.days
          Item {
            id: cell
            required property var modelData
            Layout.fillWidth: true
            Layout.fillHeight: true
            Rectangle {
              anchors.centerIn: parent
              width: Math.min(parent.width, parent.height) * 0.9
              height: width
              radius: width / 2
              color: cell.modelData.today ? Theme.accent : "transparent"
            }
            StyledText {
              anchors.centerIn: parent
              text: cell.modelData.day
              textColor: cell.modelData.today ? Theme.background : Theme.foreground
              opacity: cell.modelData.inMonth ? 1 : 0.3
              textSize: Appearance.fontSize - 1
            }
          }
        }
      }
    }
  }
}
