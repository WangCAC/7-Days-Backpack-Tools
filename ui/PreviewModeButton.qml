import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

Item {
    id: root
    property string text
    property string helpLabel
    property string buttonName
    property string helpName
    property bool selected: false
    signal activated()
    signal helpRequested()
    implicitWidth: 28 + 8 + Math.max(112, label.implicitWidth + 28)
    implicitHeight: 36
    Button {
        id: modeButton
        objectName: root.buttonName
        anchors.left: helpButton.right; anchors.leftMargin: 8
        anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
        padding: 0
        leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0
        hoverEnabled: true
        Accessible.name: root.text
        Accessible.role: Accessible.RadioButton
        Accessible.checked: root.selected
        onClicked: root.activated()
        onPressed: ripple.start(width / 2, height / 2)
        onReleased: ripple.release()
        onCanceled: ripple.release()
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        contentItem: Text {
            id: label
            text: root.text; color: Theme.darkPrimary
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: Theme.controlRadius
            color: Theme.darkContainer
            Rectangle {
                anchors.fill: parent; radius: parent.radius; color: Theme.darkPrimary
                opacity: modeButton.down || modeButton.visualFocus ? 0.15 : modeButton.hovered ? 0.08 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
            }
            Rectangle {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: 5; radius: Theme.controlRadius; visible: root.selected; color: "#47DFF5"
                Rectangle { anchors.right: parent.right; width: 2; height: parent.height; color: parent.color }
            }
        }
        Ripple { id: ripple; anchors.fill: parent; tint: Theme.darkPrimary; cornerRadius: Theme.controlRadius }
    }
    Button {
        id: helpButton
        objectName: root.helpName
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        width: 28; height: 28; padding: 4
        leftPadding: 4; rightPadding: 4; topPadding: 4; bottomPadding: 4
        hoverEnabled: true
        Accessible.name: root.helpLabel
        onClicked: root.helpRequested()
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        contentItem: SvgIcon { kind: "helpSolid"; tint: Theme.darkOnSurface }
        background: Rectangle {
            radius: 14
            color: Theme.darkPrimary
            opacity: helpButton.down || helpButton.visualFocus ? 0.15 : helpButton.hovered ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
        }
    }
}
