import QtQuick
import QtQuick.Layouts
import qs.components.stolen.end4.common
import qs.components.stolen.end4.common.widgets

ColumnLayout { // Window content with navigation rail and content pane
    id: root
    property bool expanded: true
    property int currentIndex: 0
    spacing: 5
}
