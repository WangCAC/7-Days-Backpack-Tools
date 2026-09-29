import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Button {
    id: control
    property string buttonStyle: "secondary"
    // The source must not contain this button, or rendering would recurse.
    property Item backdropSource: null
    property real backdropScrollOffset: 0

    implicitHeight: 40
    leftPadding: 14
    rightPadding: 14
    focusPolicy: Qt.NoFocus
    hoverEnabled: true
    font.pixelSize: 13
    font.weight: buttonStyle === "primary" || buttonStyle === "accent"
                 ? Font.DemiBold : Font.Medium

    HoverHandler { id: hoverSensor }

    contentItem: Text {
        text: control.text
        font: control.font
        color: !control.enabled ? "#75899c"
               : control.buttonStyle === "primary" ? "#ffffff"
               : control.buttonStyle === "accent" ? "#155079" : "#174b70"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Item {
        id: glassBackground
        property int blurPadding: 18

        Rectangle {
            x: 0; y: 2
            width: parent.width; height: parent.height
            radius: 11
            color: control.buttonStyle === "primary" ? "#274b76" : "#527795"
            opacity: control.enabled ? 0.14 : 0.07
        }

        // Sample beyond the button edges, so the blur has neighboring pixels.
        ShaderEffectSource {
            id: backdropTexture
            x: -glassBackground.blurPadding
            y: -glassBackground.blurPadding
            width: glassBackground.width + 2 * glassBackground.blurPadding
            height: glassBackground.height + 2 * glassBackground.blurPadding
            visible: false
            sourceItem: control.backdropSource
            live: true
            sourceRect: {
                if (!control.backdropSource)
                    return Qt.rect(0, 0, 0, 0)
                // Explicit dependencies update the crop while scrolling.
                const movement = control.backdropScrollOffset + control.x + control.y
                const point = glassBackground.mapToItem(
                    control.backdropSource,
                    -glassBackground.blurPadding,
                    -glassBackground.blurPadding)
                return Qt.rect(point.x, point.y, width, height)
            }
        }

        Item {
            id: roundedMask
            x: backdropTexture.x; y: backdropTexture.y
            width: backdropTexture.width; height: backdropTexture.height
            visible: false
            Rectangle {
                x: glassBackground.blurPadding
                y: glassBackground.blurPadding
                width: glassBackground.width
                height: glassBackground.height
                radius: 11
                color: "white"
            }
        }
        ShaderEffectSource {
            id: maskTexture
            anchors.fill: roundedMask
            visible: false
            sourceItem: roundedMask
            live: true
        }

        MultiEffect {
            anchors.fill: backdropTexture
            source: backdropTexture
            // The solid primary action keeps its contrast and hover response
            // without waiting for the backdrop effect to redraw.
            visible: control.backdropSource !== null && control.buttonStyle !== "primary"
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: 16
            blur: 0.55
            maskEnabled: true
            maskSource: maskTexture
        }

        Rectangle {
            anchors.fill: parent
            radius: 11
            color: !control.enabled ? "#e6eff4f8"
                   : control.buttonStyle === "primary"
                     ? (control.down ? "#155d98" : hoverSensor.hovered ? "#176fae" : "#277fb9")
                   : control.buttonStyle === "accent"
                     ? (control.down ? "#e6a8cce7" : hoverSensor.hovered ? "#dfbedcf0" : "#d7d6e9f8")
                     : (control.down ? "#e3dcebf5" : hoverSensor.hovered ? "#e3f2faff" : "#dcf1f8fd")
            border.width: 1
            border.color: !control.enabled ? "#c5d3df"
                          : control.buttonStyle === "primary" ? "#13588e"
                          : control.buttonStyle === "accent" ? "#8cb8d8" : "#b5ccdd"
        }
    }
}
