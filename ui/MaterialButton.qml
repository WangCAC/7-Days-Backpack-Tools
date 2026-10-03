import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

Button {
    id: control
    // primary: filled; accent: filled tonal; secondary: outlined; ghost: text.
    property string buttonStyle: "secondary"
    readonly property bool filled: buttonStyle === "primary"
    readonly property bool tonal: buttonStyle === "accent"
    readonly property bool outlined: buttonStyle === "secondary"
    readonly property color labelColor: !enabled ? Theme.alpha(Theme.onSurface, 0.38)
        : filled ? Theme.onPrimary : tonal ? Theme.onSecondaryContainer : Theme.primary
    implicitHeight: 40
    leftPadding: 16; rightPadding: 16
    topPadding: 0; bottomPadding: 0
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    font.pixelSize: 13
    font.weight: Font.Medium
    HoverHandler { id: pointer; cursorShape: Qt.PointingHandCursor }
    onPressed: ripple.start(pointer.hovered ? pointer.point.position.x : width / 2,
                            pointer.hovered ? pointer.point.position.y : height / 2)
    onReleased: ripple.release()
    onCanceled: ripple.release()
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.labelColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: Math.min(Theme.controlRadius, height / 2)
        color: !control.enabled && (control.filled || control.tonal) ? Theme.alpha(Theme.onSurface, 0.12)
            : control.filled ? control.down ? Theme.primaryPressed : control.hovered ? Theme.primaryHover : Theme.primary
            : control.tonal ? Theme.secondaryContainer : "transparent"
        border.width: control.outlined ? 1 : control.visualFocus ? 2 : 0
        border.color: !control.enabled ? Theme.outlineVariant : control.visualFocus ? Theme.focusOutline
            : control.hovered ? Theme.hoverOutline : Theme.outline
        Behavior on border.color { ColorAnimation { duration: Theme.shortDuration } }
        Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
        Rectangle {
            anchors.fill: parent; radius: parent.radius
            color: control.tonal ? Theme.onSecondaryContainer : Theme.primary
            opacity: !control.enabled || control.filled ? 0 : control.down || control.visualFocus ? 0.12 : control.hovered ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
        }
        Ripple { id: ripple; anchors.fill: parent; cornerRadius: parent.radius; tint: control.filled ? Theme.onPrimary : control.tonal ? Theme.onSecondaryContainer : Theme.primary }
    }
}
