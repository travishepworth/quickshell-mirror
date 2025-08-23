pragma Singleton
import QtQuick

QtObject {
    enum Position {
        Upper,
        Center,
        Lower
    }

    property int currentPosition: Position.Center
}
