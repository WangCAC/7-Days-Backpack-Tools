import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

ScrollBar {
    id: control
    property bool dark: false
    property color handleColor: dark ? Theme.darkOutline : Theme.outline
    property color trackColor: dark ? Theme.darkContainer : Theme.outlineVariant
    implicitWidth: 6
    implicitHeight: 6
    padding: 1
    minimumSize: 0.08
    policy: ScrollBar.AsNeeded
    visible: policy === ScrollBar.AlwaysOn || (policy !== ScrollBar.AlwaysOff && size < 1)
    contentItem: Rectangle {
        implicitWidth: 4; implicitHeight: 4; radius: 2
        color: control.handleColor
        opacity: control.policy === ScrollBar.AlwaysOn
            ? (control.active || control.hovered || control.pressed ? 0.95 : 0.7)
            : control.size >= 1 ? 0 : control.active || control.hovered || control.pressed ? 0.8 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.stateDuration } }
    }
    background: Rectangle {
        visible: control.policy === ScrollBar.AlwaysOn
        radius: 2
        color: control.trackColor
    }
}
