import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

Popup {
    id: control
    property bool dark: false
    padding: 6
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle {
        radius: Theme.popupRadius
        color: control.dark ? Theme.darkContainer : Theme.surfaceContainerHigh
        border.color: control.dark ? Theme.darkOutlineVariant : Theme.outlineVariant
        border.width: 1
    }
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.shortDuration }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standardCurve }
    }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 75 } }
}
