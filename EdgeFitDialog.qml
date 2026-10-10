import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "ui" as UI
import "ui/Theme.js" as Theme

UI.MaterialDialog {
    id: dialog
    property var host
    property int explanationMode: 0
    readonly property int desiredExplanation: normalOption.hovered ? 0 : strongOption.hovered ? 1
        : keepOption.hovered ? 2 : modeGroup.checkedButton ? modeGroup.checkedButton.optionMode : 0
    onDesiredExplanationChanged: if (visible) explanationDelay.restart()
    signal applyRequested(int mode)
    width: Math.min(530, host.width - 40)
    onOpened: { normalOption.checked = true; explanationMode = 0 }
    onClosed: explanationDelay.stop()
    Timer {
        id: explanationDelay
        interval: 150
        onTriggered: dialog.explanationMode = dialog.desiredExplanation
    }
    header: Item {
        implicitHeight: 58
        Text {
            anchors.left: parent.left; anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: dialog.host.t("edgeFitTitle")
            color: Theme.onSurface; font.pixelSize: 18; font.bold: true
        }
    }
    ButtonGroup { id: modeGroup }
    contentItem: ColumnLayout {
        spacing: 8
        Text {
            Layout.fillWidth: true; Layout.leftMargin: 20; Layout.rightMargin: 20
            text: dialog.host.t("edgeFitIntro")
            wrapMode: Text.WordWrap
            color: Theme.onSurfaceVariant; font.pixelSize: 12
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
            Layout.topMargin: 4; Layout.bottomMargin: 4
            spacing: 6
            UI.MaterialRadioButton {
                id: normalOption
                objectName: "normalEdgeOption"
                Layout.fillWidth: true
                optionMode: 0; checked: true
                ButtonGroup.group: modeGroup
                text: dialog.host.t("edgeFitNormal")
            }
            UI.MaterialRadioButton {
                id: strongOption
                objectName: "strongEdgeOption"
                Layout.fillWidth: true
                optionMode: 1
                ButtonGroup.group: modeGroup
                text: dialog.host.t("edgeFitStrong")
            }
            UI.MaterialRadioButton {
                id: keepOption
                objectName: "keepHeightOption"
                Layout.fillWidth: true
                optionMode: 2
                ButtonGroup.group: modeGroup
                text: dialog.host.t("edgeFitKeep")
            }
        }
        Rectangle {
            objectName: "edgeExplanationPanel"
            Layout.fillWidth: true
            Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.bottomMargin: 12
            Layout.preferredHeight: 116
            color: Theme.surface
            border.color: Theme.outlineVariant
            radius: Theme.controlRadius
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 12
                spacing: 5
                RowLayout {
                    spacing: 6
                    UI.SvgIcon { Layout.preferredWidth: 16; Layout.preferredHeight: 16; kind: "help" }
                    Text { text: dialog.host.t("edgeFitExplanation"); color: Theme.onSurface; font.pixelSize: 12; font.bold: true }
                }
                Text {
                    objectName: "edgeExplanationText"
                    Layout.fillWidth: true; Layout.fillHeight: true
                    text: dialog.host.t(["edgeFitNormalTip", "edgeFitStrongTip", "edgeFitKeepTip"][dialog.explanationMode])
                    color: Theme.onSurfaceVariant; font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignTop
                }
            }
        }
    }
    footer: Item {
        implicitHeight: 58
        Row {
            anchors.right: parent.right; anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            UI.MaterialButton {
                objectName: "edgeFitCancelButton"
                width: 90; height: 34
                text: dialog.host.t("cancel")
                onClicked: dialog.close()
            }
            UI.MaterialButton {
                objectName: "edgeFitConfirmButton"
                width: 90; height: 34; buttonStyle: "primary"
                text: dialog.host.t("confirm")
                onClicked: {
                    const mode = modeGroup.checkedButton ? modeGroup.checkedButton.optionMode : 0
                    dialog.close()
                    dialog.applyRequested(mode)
                }
            }
        }
    }
}
