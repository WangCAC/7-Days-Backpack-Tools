import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: Math.min(1200, Math.max(760, Screen.width - 80))
    height: Math.min(700, Math.max(520, Screen.height - 100))
    minimumWidth: 760
    minimumHeight: 520
    visible: true
    title: "七日杀 V3.3 背包模组生成器"
    color: "#edf2ef"

    property int capacity: Number(capacityInput.text)
    property int freeSlots: Number(freeInput.text)
    property bool inputsValid: capacityInput.text.length > 0 && freeInput.text.length > 0
                               && Number.isInteger(Number(capacityInput.text))
                               && Number.isInteger(Number(freeInput.text))
                               && capacity >= 1 && capacity <= 5000
                               && freeSlots >= 0 && freeSlots <= capacity
    property var currentLayout: inputsValid ? backpackGenerator.layout(capacity, freeSlots) : ({"valid": false})
    property string statusMessage: ""
    property bool saveSucceeded: false

    onCurrentLayoutChanged: { if (gridCanvas) gridCanvas.requestPaint() }

    FileDialog {
        id: saveDialog
        title: "保存背包模组 ZIP"
        fileMode: FileDialog.SaveFile
        nameFilters: ["ZIP 压缩包 (*.zip)"]
        onAccepted: {
            const result = backpackGenerator.saveZip(window.capacity, window.freeSlots, selectedFile)
            window.saveSucceeded = result.ok
            window.statusMessage = result.ok ? "已保存：" + result.path : "生成失败：" + result.message
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 19
            color: "white"
            border.color: "#d9e3dc"
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#16231f"
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18; Layout.rightMargin: 18
                            Layout.topMargin: 14; Layout.bottomMargin: 10
                            Text { text: "背包实时预览"; color: "#ecf4ee"; font.pixelSize: 16; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Rectangle { Layout.preferredWidth: 7; Layout.preferredHeight: 7; radius: 4; color: "#6ce0a7" }
                            Text { text: "LIVE PREVIEW"; color: "#b6d7c4"; font.pixelSize: 11 }
                        }
                        Rectangle {
                            id: previewStage
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Layout.leftMargin: 14; Layout.rightMargin: 14
                            radius: 15; border.color: "#35443c"; clip: true
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#293f34" }
                                GradientStop { position: 1; color: "#111d19" }
                            }
                            Item {
                                id: previewHolder
                                anchors.fill: parent
                                anchors.topMargin: 14; anchors.leftMargin: 14
                                anchors.rightMargin: 14; anchors.bottomMargin: 14
                                clip: true
                                property real previewScale: currentLayout.valid
                                    ? Math.min((width - 12) / currentLayout.width,
                                               (height - 12) / currentLayout.height, 0.84) : 0.5
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: currentLayout.valid ? currentLayout.width : 603
                                    height: currentLayout.valid ? currentLayout.height : 349
                                    scale: previewHolder.previewScale
                                    transformOrigin: Item.Center
                                    color: "#343637"; border.width: 3; border.color: "#0b0d0d"; clip: true
                                    Rectangle {
                                        id: gameHeader
                                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                        anchors.margins: 3
                                        height: 43; color: "#090b0b"
                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 3; color: "#d9d5bf" }
                                        Text {
                                            anchors.left: parent.left; anchors.leftMargin: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "▣ 物品栏"; color: "#f3f3f0"; font.pixelSize: 25; font.bold: true
                                        }
                                        Text {
                                            anchors.right: parent.right; anchors.rightMargin: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "◧  ☷   0 $"; color: "#f7de80"; font.pixelSize: 18
                                        }
                                    }
                                    Canvas {
                                        id: gridCanvas
                                        anchors.top: gameHeader.bottom; anchors.left: parent.left
                                        anchors.topMargin: 3; anchors.leftMargin: 3
                                        width: currentLayout.valid ? currentLayout.cols * currentLayout.cell : 0
                                        height: currentLayout.valid ? Math.min(currentLayout.rows, 10) * currentLayout.cell : 0
                                        onPaint: {
                                            const ctx = getContext("2d")
                                            ctx.clearRect(0, 0, width, height)
                                            if (!currentLayout.valid) return
                                            const side = currentLayout.cell
                                            const count = currentLayout.cols * Math.min(currentLayout.rows, 10)
                                            for (let i = 0; i < count; ++i) {
                                                const x = (i % currentLayout.cols) * side
                                                const y = Math.floor(i / currentLayout.cols) * side
                                                const padding = i >= currentLayout.capacity
                                                const weighted = i >= currentLayout.free && !padding
                                                ctx.fillStyle = padding ? "#222626" : weighted ? "#353738" : "#676a6b"
                                                ctx.fillRect(x, y, side, side)
                                                ctx.strokeStyle = padding ? "#343838" : "#101211"
                                                ctx.lineWidth = 2
                                                ctx.strokeRect(x + 1, y + 1, side - 2, side - 2)
                                                if (weighted) {
                                                    ctx.fillStyle = "#626665"
                                                    ctx.font = "27px Segoe UI Symbol"
                                                    ctx.textAlign = "center"; ctx.textBaseline = "middle"
                                                    ctx.fillText("♟", x + side / 2, y + side / 2)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18; Layout.rightMargin: 18
                            Layout.topMargin: 10; Layout.bottomMargin: 12
                            spacing: 14
                            Repeater {
                                model: [
                                    {"name": "免负重", "swatch": "#676a6b"},
                                    {"name": "负重", "swatch": "#353738"},
                                    {"name": "排版余位", "swatch": "#222626"}
                                ]
                                RowLayout {
                                    spacing: 5
                                    Rectangle { Layout.preferredWidth: 11; Layout.preferredHeight: 11; color: modelData.swatch; border.color: "#858d87" }
                                    Text { text: modelData.name; color: "#a7beb0"; font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 340; Layout.fillHeight: true
                    color: "#f9fbf9"; border.color: "#e1e9e2"
                    Flickable {
                        id: controlsFlick
                        anchors.fill: parent
                        contentWidth: width; contentHeight: settingsColumn.implicitHeight + 40
                        clip: true; boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        ColumnLayout {
                            id: settingsColumn
                            x: 20; y: 20; width: controlsFlick.width - 40; spacing: 14
                            ColumnLayout {
                                spacing: 0
                                Text { text: "生成设置"; color: "#172321"; font.pixelSize: 19; font.bold: true }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 7
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "背包总容量"; color: "#26392f"; font.pixelSize: 13; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "可用格数"; color: "#7a8a7f"; font.pixelSize: 11 }
                                }
                                TextField {
                                    id: capacityInput
                                    Layout.fillWidth: true; Layout.preferredHeight: 46
                                    text: "250"; selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 1; top: 5000 }
                                    color: "#173128"; font.pixelSize: 20; font.bold: true
                                    background: Rectangle {
                                        radius: 9; color: "white"
                                        border.color: capacityInput.activeFocus ? "#348e70" : "#cbd9cf"
                                    }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 7
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "初始免负重格数"; color: "#26392f"; font.pixelSize: 13; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "基础容量"; color: "#7a8a7f"; font.pixelSize: 11 }
                                }
                                TextField {
                                    id: freeInput
                                    Layout.fillWidth: true; Layout.preferredHeight: 46
                                    text: "125"; selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 0; top: 5000 }
                                    color: "#173128"; font.pixelSize: 20; font.bold: true
                                    background: Rectangle {
                                        radius: 9; color: "white"
                                        border.color: freeInput.activeFocus ? "#348e70" : "#cbd9cf"
                                    }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 9
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "驮骡技能加成"; color: "#26392f"; font.pixelSize: 13; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: "按当前等级取值"; color: "#718073"; font.pixelSize: 11 }
                                }
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 5
                                    Repeater {
                                        model: 5
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 49
                                            color: "#e7f2ea"; radius: 7
                                            Column {
                                                anchors.centerIn: parent; spacing: 2
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: (index + 1) + " 级"; color: "#6f8e77"; font.pixelSize: 10 }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: currentLayout.valid ? "+" + currentLayout.perk[index] : "—"; color: "#24684b"; font.pixelSize: 12; font.bold: true }
                                            }
                                        }
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: inputsValid ? statusMessage : "请输入 1～5000 的容量，且免负重格数不能超过总容量。"
                                visible: text.length > 0
                                color: inputsValid && saveSucceeded ? "#277957" : "#bd4747"
                                font.pixelSize: 11; wrapMode: Text.WrapAnywhere
                            }
                            Button {
                                id: generateButton
                                Layout.fillWidth: true; Layout.preferredHeight: 48
                                enabled: inputsValid; text: "生成并保存模组 ZIP"
                                font.pixelSize: 15; font.bold: true
                                contentItem: Text {
                                    text: generateButton.text; color: "white"; font: generateButton.font
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 10
                                    color: generateButton.enabled ? (generateButton.hovered ? "#1d6748" : "#277957") : "#a9b8ac"
                                }
                                onClicked: {
                                    saveDialog.currentFile = backpackGenerator.suggestedFileUrl(capacity, freeSlots)
                                    saveDialog.open()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
