import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

ComboBox {
    id: control
    property bool dark: false
    property int selectedIndex: 0
    property bool bindSelection: true
    property string placeholderText: ""
    property int textElide: Text.ElideRight
    property int itemHeight: 34
    currentIndex: selectedIndex
    function applySelection() { if (bindSelection) currentIndex = selectedIndex }
    onSelectedIndexChanged: applySelection()
    onModelChanged: Qt.callLater(applySelection)
    Component.onCompleted: applySelection()
    implicitHeight: 32; implicitWidth: 100
    font.pixelSize: 11
    leftPadding: dark ? 9 : 12; rightPadding: 28
    hoverEnabled: true
    contentItem: Text {
        text: control.currentIndex < 0 ? control.placeholderText : control.displayText
        font: control.font
        color: control.dark ? Theme.darkOnSurface : Theme.onSurface
        opacity: control.enabled ? 1 : 0.38
        verticalAlignment: Text.AlignVCenter
        elide: control.textElide
    }
    background: Rectangle {
        radius: control.dark ? Theme.compactRadius : Theme.controlRadius
        color: control.dark ? Theme.darkContainer : Theme.surface
        border.width: control.activeFocus || control.popup.visible ? 2 : 1
        border.color: control.activeFocus || control.popup.visible ? control.dark ? Theme.darkPrimary : Theme.focusOutline
            : control.hovered ? control.dark ? Theme.darkOnSurfaceVariant : Theme.hoverOutline
            : control.dark ? Theme.darkOutline : Theme.outline
        opacity: control.enabled ? 1 : 0.38
        Behavior on border.color { ColorAnimation { duration: Theme.shortDuration } }
    }
    indicator: SvgIcon {
        kind: "chevron"; tint: control.dark ? Theme.darkOnSurfaceVariant : Theme.onSurfaceVariant
        x: control.width - width - 5; y: (control.height - height) / 2
        width: 20; height: 20
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standardCurve } }
    }
    delegate: ItemDelegate {
        required property int index
        required property var modelData
        width: control.width - 12; height: control.itemHeight
        highlighted: control.highlightedIndex === index
        hoverEnabled: true
        contentItem: Text {
            text: modelData; color: control.dark ? Theme.darkOnSurface : Theme.onSurface
            font: control.font; elide: control.textElide
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 4
            color: control.dark ? Theme.darkPrimary : Theme.primary
            opacity: parent.down ? 0.12 : parent.highlighted || parent.hovered ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.shortDuration } }
        }
    }
    popup: MaterialPopup {
        dark: control.dark
        y: control.height + 4; width: control.width
        height: Math.min(250, Math.max(46, control.count * control.itemHeight + 12))
        contentItem: ListView {
            clip: true
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: MaterialScrollBar { dark: control.dark }
        }
    }
}
