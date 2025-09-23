import QtQuick
import qs.services
import qs.components.stolen.end4.common
import qs.components.stolen.end4.common.widgets
import qs.components.stolen.end4.common.functions

Image {
    asynchronous: true
    retainWhileLoading: true
    visible: opacity > 0
    opacity: (status === Image.Ready) ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }
}
