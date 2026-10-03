import QtQuick
import "ui" as UI

Item {
    id: root
    property color tint: "#f86d69"
    property bool forbidden: false
    property bool glow: false
    implicitWidth: 28; implicitHeight: 28
    UI.SvgIcon {
        anchors.fill: parent
        kind: root.forbidden ? "forbidden" : "backpack"
        tint: root.tint; pixelated: true
        visible: root.glow; scale: 1.25; opacity: 0.10
    }
    UI.SvgIcon {
        anchors.fill: parent
        kind: root.forbidden ? "forbidden" : "backpack"
        tint: root.tint; pixelated: true
        visible: root.glow; scale: 1.10; opacity: 0.18
    }
    UI.SvgIcon {
        anchors.fill: parent
        kind: root.forbidden ? "forbidden" : "backpack"
        tint: root.tint; pixelated: true
    }
}