import QtQuick
import "Theme.js" as Theme

Canvas {
    id: root
    property color tint: Theme.primary
    property real cornerRadius: height / 2
    property real originX: width / 2
    property real originY: height / 2
    property real progress: 0
    property real strength: 0
    property real targetRadius: Math.sqrt(width * width + height * height)
    function start(x, y) {
        fade.stop()
        expand.stop()
        originX = x; originY = y
        progress = 0; strength = 0.12
        expand.start()
    }
    function release() { fade.restart() }
    onProgressChanged: requestPaint()
    onStrengthChanged: requestPaint()
    onTintChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (strength <= 0 || progress <= 0)
            return
        const r = Math.min(cornerRadius, width / 2, height / 2)
        ctx.beginPath()
        ctx.moveTo(r, 0); ctx.lineTo(width-r, 0)
        ctx.quadraticCurveTo(width, 0, width, r); ctx.lineTo(width, height-r)
        ctx.quadraticCurveTo(width, height, width-r, height); ctx.lineTo(r, height)
        ctx.quadraticCurveTo(0, height, 0, height-r); ctx.lineTo(0, r)
        ctx.quadraticCurveTo(0, 0, r, 0); ctx.closePath(); ctx.clip()
        ctx.globalAlpha = strength
        ctx.fillStyle = tint
        ctx.beginPath(); ctx.arc(originX, originY, targetRadius * progress, 0, 2 * Math.PI); ctx.fill()
    }
    NumberAnimation { id: expand; target: root; property: "progress"; to: 1; duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.standardCurve }
    NumberAnimation { id: fade; target: root; property: "strength"; to: 0; duration: 250 }
}
