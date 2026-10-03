import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Theme.js" as Theme

Rectangle {
    id: root
    property string label: ""
    property string fieldName: ""
    property int minimum: 0
    property int maximum: 5000
    property alias text: numberInput.text
    implicitHeight: 44
    radius: Theme.controlRadius
    color: Theme.surfaceContainerLow
    border.color: Theme.outlineVariant
    RowLayout {
        anchors.fill: parent; spacing: 0
        Text {
            Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 8
            text: root.label; color: Theme.onSurfaceVariant; font.pixelSize: 12
            wrapMode: Text.WordWrap; verticalAlignment: Text.AlignVCenter
        }
        TextField {
            id: numberInput
            objectName: root.fieldName
            Layout.preferredWidth: Math.max(86, root.width * 0.31); Layout.fillHeight: true
            selectByMouse: true
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: root.minimum; top: root.maximum }
            leftPadding: 6; rightPadding: 6; topPadding: 0; bottomPadding: 0
            horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
            color: Theme.onSurface
            selectionColor: Theme.primaryContainer; selectedTextColor: Theme.onPrimaryContainer
            font.pixelSize: 17; font.weight: Font.Medium
            Accessible.name: root.label
            background: Rectangle {
                radius: Theme.controlRadius; color: Theme.surface
                border.width: numberInput.activeFocus ? 2 : 1
                border.color: numberInput.activeFocus ? Theme.focusOutline : numberInput.hovered ? Theme.hoverOutline : Theme.outline
                Behavior on border.color { ColorAnimation { duration: Theme.shortDuration } }
            }
        }
    }
}
