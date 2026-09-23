pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.services
import qs.config
import qs.components.reusable

Item {
  id: root

  required property var wrapper
  property string currentName: "calendar"

  // Month currently on display. Day component is ignored/normalized to 1st.
  property var viewDate: new Date()

  property bool hovered: hoverHandler.hovered

  readonly property int margins: 20
  readonly property int cellSize: 30
  readonly property int cellSpacing: 4
  readonly property int headerHeight: 26
  readonly property int weekdayHeight: 18
  readonly property int sectionSpacing: 10
  readonly property int footerHeight: 32

  readonly property int gridWidth: cellSize * 7 + cellSpacing * 6
  readonly property int gridHeight: cellSize * 6 + cellSpacing * 5

  implicitWidth: gridWidth + margins * 2
  implicitHeight: margins * 2
                  + headerHeight
                  + sectionSpacing
                  + weekdayHeight + 4
                  + gridHeight
                  + sectionSpacing
                  + footerHeight
  width: implicitWidth
  height: implicitHeight

  SystemClock {
    id: todayClock
    precision: SystemClock.Hours
  }

  readonly property var weekdayLabels: ["日", "月", "火", "水", "木", "金", "土"]

  // 42-cell (6x7) grid covering the viewed month plus the leading/trailing
  // days needed to fill whole weeks.
  readonly property var gridDays: {
    const year = viewDate.getFullYear();
    const month = viewDate.getMonth();
    const firstWeekday = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrevMonth = new Date(year, month, 0).getDate();

    let days = [];
    for (let i = 0; i < 42; i++) {
      const offset = i - firstWeekday + 1;
      let day, monthDelta, inMonth;
      if (offset < 1) {
        day = daysInPrevMonth + offset;
        monthDelta = -1;
        inMonth = false;
      } else if (offset > daysInMonth) {
        day = offset - daysInMonth;
        monthDelta = 1;
        inMonth = false;
      } else {
        day = offset;
        monthDelta = 0;
        inMonth = true;
      }

      let cellMonth = month + monthDelta;
      let cellYear = year;
      if (cellMonth < 0) {
        cellMonth = 11;
        cellYear -= 1;
      } else if (cellMonth > 11) {
        cellMonth = 0;
        cellYear += 1;
      }

      days.push({
        day: day,
        month: cellMonth,
        year: cellYear,
        inMonth: inMonth,
        isToday: cellYear === todayClock.date.getFullYear()
                 && cellMonth === todayClock.date.getMonth()
                 && day === todayClock.date.getDate()
      });
    }
    return days;
  }

  function shiftMonth(delta) {
    viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1);
  }

  function goToToday() {
    viewDate = new Date(todayClock.date.getFullYear(), todayClock.date.getMonth(), 1);
  }

  StyledContainer {
    id: content
    anchors.fill: parent

    backgroundColor: Theme.background
    borderColor: Theme.backgroundAlt
    borderWidth: 0
    borderRadius: Appearance.borderRadius + 2

    HoverHandler {
      id: hoverHandler
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: root.margins
      spacing: root.sectionSpacing

      // --- Header: month navigation ---
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.headerHeight
        spacing: 8

        StyledIconButton {
          Layout.preferredWidth: root.headerHeight
          Layout.preferredHeight: root.headerHeight

          iconText: "‹"
          iconSize: root.headerHeight * 0.5
          borderRadius: root.headerHeight / 2
          iconColor: Theme.foregroundAlt
          backgroundColor: Theme.backgroundAlt
          hoverColor: Theme.accentAlt
          pressColor: Theme.accentAlt

          onClicked: root.shiftMonth(-1)
        }

        StyledText {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: Qt.formatDateTime(root.viewDate, "yyyy年 M月")
          textColor: Theme.accent
          textSize: Appearance.fontSize * 1.05
          font.bold: true
        }

        StyledIconButton {
          Layout.preferredWidth: root.headerHeight
          Layout.preferredHeight: root.headerHeight

          iconText: "›"
          iconSize: root.headerHeight * 0.5
          borderRadius: root.headerHeight / 2
          iconColor: Theme.foregroundAlt
          backgroundColor: Theme.backgroundAlt
          hoverColor: Theme.accentAlt
          pressColor: Theme.accentAlt

          onClicked: root.shiftMonth(1)
        }
      }

      // --- Weekday labels ---
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.weekdayHeight
        spacing: root.cellSpacing

        Repeater {
          model: root.weekdayLabels

          StyledText {
            required property string modelData

            Layout.preferredWidth: root.cellSize
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            textColor: Theme.foregroundAlt
            textSize: Appearance.fontSize * 0.85
            opacity: 0.7
          }
        }
      }

      // --- Day grid ---
      GridLayout {
        Layout.preferredWidth: root.gridWidth
        Layout.preferredHeight: root.gridHeight
        columns: 7
        rows: 6
        columnSpacing: root.cellSpacing
        rowSpacing: root.cellSpacing

        Repeater {
          model: root.gridDays

          Rectangle {
            id: dayCell
            required property var modelData

            Layout.preferredWidth: root.cellSize
            Layout.preferredHeight: root.cellSize
            radius: root.cellSize / 2

            color: modelData.isToday ? Theme.accent : (dayMouseArea.containsMouse && modelData.inMonth ? Theme.backgroundHighlight : "transparent")

            Behavior on color {
              ColorAnimation { duration: Appearance.animFast }
            }

            StyledText {
              anchors.centerIn: parent
              text: dayCell.modelData.day
              textSize: Appearance.fontSize * 0.9
              textColor: dayCell.modelData.isToday ? Theme.background : (dayCell.modelData.inMonth ? Theme.foreground : Theme.foregroundInactive)
              opacity: dayCell.modelData.inMonth ? 1.0 : 0.5
            }

            MouseArea {
              id: dayMouseArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.NoButton
            }
          }
        }
      }

      // --- Footer: today shortcut ---
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.footerHeight
        spacing: 8

        StyledText {
          Layout.fillWidth: true
          text: Qt.formatDateTime(todayClock.date, "yyyy年M月d日") + "（" + root.weekdayLabels[todayClock.date.getDay()] + "）"
          textColor: Theme.foregroundAlt
          textSize: Appearance.fontSize * 0.8
          opacity: 0.8
          elide: Text.ElideRight
        }

        StyledTextButton {
          Layout.preferredHeight: root.footerHeight
          text: "今日"
          textPadding: 6
          onClicked: root.goToToday()
        }
      }
    }
  }
}
