import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

ScrollBar {
    id: control
    property bool dark: false
    implicitWidth: 6
    implicitHeight: 6
    padding: 1
    minimumSize: 0.08
    policy: ScrollBar.AsNeeded
    visible: policy !== ScrollBar.AlwaysOff && size < 1
    contentItem: Rectangle {
        implicitWidth: 4; implicitHeight: 4; radius: 2
        color: control.dark ? Theme.darkOutline : Theme.outline
        opacity: control.size >= 1 ? 0 : control.active || control.hovered || control.pressed ? 0.8 : control.policy === ScrollBar.AlwaysOn ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.stateDuration } }
    }
    background: Item {}
}
