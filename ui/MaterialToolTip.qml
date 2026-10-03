import QtQuick
import QtQuick.Controls.Basic
import "Theme.js" as Theme

ToolTip {
    id: control
    delay: 500
    padding: 8
    font.pixelSize: 12
    contentItem: Text { text: control.text; font: control.font; color: Theme.surfaceContainerLow }
    background: Rectangle { radius: 4; color: Theme.darkContainer }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100 } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 75 } }
}
