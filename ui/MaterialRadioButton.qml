import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

RadioButton {
    id: control
    property int optionMode: 0
    implicitHeight: 40
    leftPadding: 4; rightPadding: 8; topPadding: 0; bottomPadding: 0
    spacing: 10
    hoverEnabled: true
    font.pixelSize: 13
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    indicator: Rectangle {
        x: control.leftPadding; y: (control.height - height) / 2
        width: 18; height: 18; radius: 9
        color: "transparent"
        border.width: 2
        border.color: control.checked ? Theme.primary : Theme.onSurfaceVariant
        Rectangle {
            anchors.centerIn: parent
            width: 8; height: 8; radius: 4
            color: Theme.primary
            visible: control.checked
        }
    }
    contentItem: Text {
        leftPadding: control.indicator.width + control.spacing
        text: control.text; font: control.font
        color: Theme.onSurface
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
    background: Rectangle {
        radius: Theme.controlRadius
        // Fade a fixed light color. Interpolating from transparent black
        // produces a muddy grey flash between hover states.
        color: Theme.secondaryContainer
        opacity: control.checked ? 1 : control.hovered || control.visualFocus ? 0.45 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
    }
}
