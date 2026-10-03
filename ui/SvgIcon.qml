import QtQuick
import QtQuick.Controls.impl
import "Theme.js" as Theme

// SVG artwork is rendered at the current display scale and tinted by Qt.
Item {
    id: root
    property string kind: "help"
    property color tint: Theme.primary
    property bool pixelated: false
    readonly property var assetNames: ({
        help: "help-circle", helpSolid: "help-solid", language: "language-globe",
        chevron: "chevron-down", close: "close", check: "check",
        external: "external-link", weight: "weight", inventory: "inventory",
        backpack: "pixel-backpack", forbidden: "pixel-forbidden"
    })
    readonly property url source: "qrc:/assets/" + (assetNames[kind] || assetNames.help) + ".svg"
    readonly property int status: artwork.status
    implicitWidth: 24; implicitHeight: 24
    IconImage {
        id: artwork
        anchors.fill: parent
        source: root.source
        color: root.tint
        sourceSize: Qt.size(Math.max(1, Math.ceil(width * Screen.devicePixelRatio)),
                            Math.max(1, Math.ceil(height * Screen.devicePixelRatio)))
        fillMode: Image.PreserveAspectFit
        smooth: !root.pixelated
        mipmap: !root.pixelated
    }
}
