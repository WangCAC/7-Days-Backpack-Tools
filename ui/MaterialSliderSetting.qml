import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "Theme.js" as Theme

ColumnLayout {
    id: root
    property string label: ""
    property string minimumLabel: ""
    property string maximumLabel: ""
    property string sliderName: ""
    property bool showValue: false
    property alias value: control.value
    property alias from: control.from
    property alias to: control.to
    property alias stepSize: control.stepSize
    spacing: 0
    implicitHeight: 52

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 20
        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.onSurfaceVariant
            font.pixelSize: 12
        }
        Rectangle {
            visible: root.showValue
            Layout.preferredWidth: 36
            Layout.preferredHeight: 20
            radius: Theme.compactRadius
            color: Theme.secondaryContainer
            Text {
                anchors.centerIn: parent
                text: Math.round(control.value)
                color: Theme.onSecondaryContainer
                font.pixelSize: 12
            }
        }
    }
    Slider {
        id: control
        objectName: root.sliderName
        Layout.fillWidth: true
        Layout.preferredHeight: 20
        leftPadding: 8; rightPadding: 8
        topPadding: 0; bottomPadding: 0
        stepSize: 1
        live: true
        snapMode: Slider.SnapAlways
        wheelEnabled: false
        Accessible.name: root.label
        background: Rectangle {
            x: control.leftPadding
            y: (control.height - height) / 2
            width: control.availableWidth
            height: 4
            radius: 2
            color: Theme.outlineVariant
            Rectangle {
                width: control.position * parent.width
                height: parent.height
                radius: 2
                color: Theme.primary
            }
        }
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: (control.height - height) / 2
            width: 14; height: 14; radius: 7
            color: control.pressed ? Theme.primaryPressed : control.hovered ? Theme.primaryHover : Theme.primary
            border.width: 2; border.color: Theme.surface
            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8; Layout.rightMargin: 8
        Layout.preferredHeight: 12
        Text { text: root.minimumLabel; color: Theme.onSurfaceVariant; font.pixelSize: 10 }
        Item { Layout.fillWidth: true }
        Text { text: root.maximumLabel; color: Theme.onSurfaceVariant; font.pixelSize: 10 }
    }
}
