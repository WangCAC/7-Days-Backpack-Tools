import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

CheckBox {
    id: control
    property bool dark: false
    implicitHeight: 32
    leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0
    spacing: 8
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    font.pixelSize: 11
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    onPressed: ripple.start(18, 18)
    onReleased: ripple.release()
    onCanceled: ripple.release()
    indicator: Item {
        x: 0; y: (control.height - height) / 2
        width: 18; height: 18
        Rectangle {
            x: -9; y: -9; width: 36; height: 36; radius: 18
            color: control.dark ? Theme.darkPrimary : Theme.primary
            opacity: control.down || control.visualFocus ? 0.12 : control.hovered ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
        }
        Ripple { id: ripple; x: -9; y: -9; width: 36; height: 36; tint: control.dark ? Theme.darkPrimary : Theme.primary }
        Rectangle {
            anchors.fill: parent; radius: 2
            color: control.checked ? control.dark ? Theme.darkPrimary : Theme.primary : "transparent"
            border.width: control.checked ? 0 : 2
            border.color: control.dark ? Theme.darkOnSurfaceVariant : Theme.onSurfaceVariant
            opacity: control.enabled ? 1 : 0.38
            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
            SvgIcon {
                anchors.fill: parent
                kind: "check"
                tint: control.dark ? Theme.onPrimaryContainer : Theme.onPrimary
                opacity: control.checked ? 1 : 0
                scale: control.checked ? 1 : 0.5
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
                Behavior on scale { NumberAnimation { duration: Theme.stateDuration } }
            }
        }
    }
    contentItem: Text {
        leftPadding: control.indicator.width + control.spacing
        text: control.text; font: control.font
        color: control.dark ? Theme.darkOnSurface : Theme.onSurface
        opacity: control.enabled ? 1 : 0.38
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }
}
