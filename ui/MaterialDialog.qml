import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

Dialog {
    padding: 0
    modal: true
    background: Rectangle { radius: Theme.dialogRadius; color: Theme.surfaceContainerHigh; border.color: Theme.outlineVariant }
    Overlay.modal: Rectangle { color: "#66000000" }
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Theme.mediumDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standardCurve }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
        NumberAnimation { property: "scale"; from: 1; to: 0.98; duration: 100 }
    }
}
