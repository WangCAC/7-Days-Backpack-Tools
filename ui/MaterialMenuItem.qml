import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

Button {
    id: control
    property bool selected: false
    implicitHeight: 42
    leftPadding: 12; rightPadding: 12; topPadding: 0; bottomPadding: 0
    hoverEnabled: true
    font.pixelSize: 13
    HoverHandler { id: pointer; cursorShape: Qt.PointingHandCursor }
    onPressed: ripple.start(pointer.point.position.x, pointer.point.position.y)
    onReleased: ripple.release()
    onCanceled: ripple.release()
    contentItem: Item {
        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: control.text; color: Theme.onSurface; font: control.font }
        SvgIcon {
            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; visible: control.selected
            kind: "check"; tint: Theme.primary
        }
    }
    background: Rectangle {
        radius: 4
        color: control.selected ? Theme.secondaryContainer : "transparent"
        Rectangle {
            anchors.fill: parent; radius: parent.radius; color: Theme.primary
            opacity: control.down || control.visualFocus ? 0.12 : control.hovered ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
        }
        Ripple { id: ripple; anchors.fill: parent; cornerRadius: parent.radius }
    }
}
