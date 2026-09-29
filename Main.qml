import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Effects

ApplicationWindow {
    id: window
    width: Math.min(1200, Math.max(760, Screen.width - 80))
    height: Math.min(700, Math.max(520, Screen.height - 100))
    minimumWidth: 760
    minimumHeight: 520
    visible: true
    title: window.t("appTitle")
    color: "#edf3f9"
    font.family: uiFontFamily
    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0; color: "#e2edf7" }
            GradientStop { position: 1; color: "#f4f7fb" }
        }
    }

    property int capacity: Number(capacityInput.text)
    property int freeSlots: Number(freeInput.text)
    property bool inputsValid: capacityInput.text.length > 0 && freeInput.text.length > 0
                               && Number.isInteger(Number(capacityInput.text))
                               && Number.isInteger(Number(freeInput.text))
                               && capacity >= 1 && capacity <= 5000
                               && freeSlots >= 0 && freeSlots <= capacity
    property var currentLayout: inputsValid ? backpackGenerator.layout(capacity, freeSlots) : ({"valid": false})
    property string statusKey: ""
    property var statusArgs: []
    property bool statusIsError: false
    property string statusMessage: statusKey.length > 0 ? window.tf(statusKey, statusArgs) : ""
    property bool saveSucceeded: false

    function t(key) {
        const value = localization.strings[key]
        return value === undefined ? key : value
    }
    function tf(key, args) {
        return window.t(key).replace(/%([1-9][0-9]*)/g, function(match, number) {
            const index = Number(number) - 1
            return args && index < args.length ? String(args[index]) : match
        })
    }
    function setStatus(key, args, isError) {
        statusKey = key
        statusArgs = args || []
        statusIsError = isError || false
    }
    Connections {
        target: localization
        function onLanguageChanged() { window.setStatus("", [], false) }
    }

    onCurrentLayoutChanged: { if (previewGrid) previewGrid.positionViewAtBeginning() }

    FileDialog {
        id: saveDialog
        title: window.t("saveDialogTitle")
        fileMode: FileDialog.SaveFile
        nameFilters: [window.t("zipFilter")]
        onAccepted: {
            const result = backpackGenerator.saveZip(window.capacity, window.freeSlots, selectedFile)
            window.saveSucceeded = result.ok
            window.setStatus(result.ok ? "statusSaved" : "statusGenerateFailed",
                             [result.ok ? result.path : window.tf(result.messageKey, result.messageArgs)],
                             !result.ok)
        }
    }

    FileDialog {
        id: gameFileDialog
        title: window.t("gameDialogTitle")
        fileMode: FileDialog.OpenFile
        nameFilters: [window.t("gameExeFilter")]
        onAccepted: {
            window.setStatus("", [], false)
            gameManager.addGame(selectedFile)
        }
    }

    Dialog {
        id: aboutDialog
        anchors.centerIn: Overlay.overlay
        width: Math.min(620, window.width - 36)
        height: Math.min(550, window.height - 36)
        modal: true
        padding: 0
        background: Rectangle {
            radius: 20
            gradient: Gradient {
                GradientStop { position: 0; color: "#eef6fd" }
                GradientStop { position: 0.55; color: "#fbfdff" }
                GradientStop { position: 1; color: "#f5f0eb" }
            }
            border.color: "#cdd9e5"
            border.width: 1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#500c243b"
                shadowBlur: 0.5
                shadowVerticalOffset: 7
            }
        }
        header: Rectangle {
            implicitHeight: 94
            radius: 20
            color: "#f0f5fb"
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#dce5ee" }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 22; anchors.rightMargin: 18
                spacing: 16
                Image {
                    source: "qrc:/assets/backpack-logo.svg"
                    Layout.preferredWidth: 58; Layout.preferredHeight: 58
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: window.t("aboutTitle")
                        color: "#1c2b3b"; font.pixelSize: 20; font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: window.t("aboutAuthor") + "  ·  v" + appVersion
                        color: "#667b91"; font.pixelSize: 12
                    }
                }
                FluentButton {
                    Layout.preferredWidth: 34; Layout.preferredHeight: 34
                    buttonStyle: "ghost"
                    backdropSource: aboutDialog.background
                    text: "×"
                    font.pixelSize: 22
                    onClicked: aboutDialog.close()
                }
            }
        }
        contentItem: Flickable {
            clip: true
            contentWidth: width
            contentHeight: aboutColumn.implicitHeight + 40
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ColumnLayout {
                id: aboutColumn
                x: 22; y: 20
                width: parent.width - 44
                spacing: 16
                Text {
                    Layout.fillWidth: true
                    text: window.t("aboutIntro")
                    wrapMode: Text.WordWrap
                    color: "#40546a"; font.pixelSize: 14
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: freedomColumn.implicitHeight + 30
                    radius: 14; color: "#f2f7fc"; border.color: "#dce8f3"
                    ColumnLayout {
                        id: freedomColumn
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 7
                        Text { text: window.t("aboutFreedomTitle"); color: "#225d98"; font.pixelSize: 15; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: window.t("aboutFreedomBody")
                            wrapMode: Text.WordWrap
                            color: "#45596f"; font.pixelSize: 13
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: installColumn.implicitHeight + 30
                    radius: 14; color: "#f2f7fc"; border.color: "#dce8f3"
                    ColumnLayout {
                        id: installColumn
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 7
                        Text { text: window.t("aboutInstallTitle"); color: "#225d98"; font.pixelSize: 15; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: window.t("aboutInstallBody")
                            wrapMode: Text.WordWrap
                            color: "#45596f"; font.pixelSize: 13
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: repositoryColumn.implicitHeight + 28
                    radius: 14; color: "#fff9ef"; border.color: "#eadfc4"
                    ColumnLayout {
                        id: repositoryColumn
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 5
                        Text { text: window.t("aboutGithub"); color: "#694a20"; font.pixelSize: 14; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: "<a href=\"https://github.com/WangCAC/7-Days-Backpack-Tools\">https://github.com/WangCAC/7-Days-Backpack-Tools ↗</a>"
                            textFormat: Text.RichText
                            wrapMode: Text.WrapAnywhere
                            font.pixelSize: 12
                            onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                        }
                    }
                }
            }
        }
        footer: Item {
            implicitHeight: 64
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#dce5ee" }
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                width: 96
                height: 40
                radius: 10
                color: aboutCloseMouse.pressed ? "#15517f"
                       : aboutCloseMouse.containsMouse ? "#1c689f" : "#287fb8"
                border.width: 1
                border.color: "#155f93"
                Text {
                    anchors.centerIn: parent
                    text: window.t("aboutClose")
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.bold: true
                }
                MouseArea {
                    id: aboutCloseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: aboutDialog.close()
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 20
                    color: "#fbfdff"
                    border.color: "#d8e3ed"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#260e2c45"
                        shadowBlur: 0.35
                        shadowVerticalOffset: 3
                    }
                    clip: true
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18; Layout.rightMargin: 18
                            Layout.topMargin: 14; Layout.bottomMargin: 12
                            spacing: 10
                            Image {
                                source: "qrc:/assets/backpack-logo.svg"
                                Layout.preferredWidth: 34; Layout.preferredHeight: 34
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            Text { text: window.t("previewTitle"); color: "#1f3043"; font.pixelSize: 16; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: liveText.implicitWidth + 26
                                Layout.preferredHeight: 28
                                radius: 14
                                color: "#eaf4fc"
                                border.color: "#d5e7f4"
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle { width: 7; height: 7; radius: 4; color: "#3b90c2"; anchors.verticalCenter: parent.verticalCenter }
                                    Text { id: liveText; text: window.t("previewLive"); color: "#2c668e"; font.pixelSize: 11 }
                                }
                            }
                        }
                        Rectangle {
                            id: previewStage
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Layout.leftMargin: 16; Layout.rightMargin: 16
                            radius: 16; border.color: "#293a48"; clip: true
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#22313c" }
                                GradientStop { position: 1; color: "#101a23" }
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
                                            text: window.t("inventoryTitle"); color: "#f3f3f0"; font.pixelSize: 25; font.bold: true
                                        }
                                        Text {
                                            anchors.right: parent.right; anchors.rightMargin: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "◧  ☷   0 $"; color: "#f7de80"; font.pixelSize: 18
                                        }
                                    }
                                    GridView {
                                        id: previewGrid
                                        anchors.top: gameHeader.bottom; anchors.left: parent.left
                                        anchors.topMargin: 3; anchors.leftMargin: 3
                                        width: currentLayout.valid ? currentLayout.cols * currentLayout.cell + 13 : 0
                                        height: currentLayout.valid ? currentLayout.visibleRows * currentLayout.cell : 0
                                        cellWidth: currentLayout.valid ? currentLayout.cell : 66
                                        cellHeight: cellWidth
                                        model: currentLayout.valid ? currentLayout.cols * currentLayout.rows : 0
                                        clip: true
                                        boundsBehavior: Flickable.StopAtBounds
                                        delegate: Rectangle {
                                            required property int index
                                            width: previewGrid.cellWidth
                                            height: previewGrid.cellHeight
                                            property bool padding: index >= currentLayout.capacity
                                            property bool weighted: index >= currentLayout.free && !padding
                                            color: padding ? "#222626" : weighted ? "#353738" : "#676a6b"
                                            border.width: 2
                                            border.color: padding ? "#343838" : "#101211"
                                            Text {
                                                anchors.centerIn: parent
                                                visible: parent.weighted
                                                text: "♟"
                                                color: "#626665"
                                                font.pixelSize: 27
                                            }
                                        }
                                        ScrollBar.vertical: ScrollBar {
                                            width: 10
                                            policy: currentLayout.valid && currentLayout.rows > currentLayout.visibleRows
                                                    ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18; Layout.rightMargin: 18
                            Layout.topMargin: 10; Layout.bottomMargin: 14
                            spacing: 14
                            Repeater {
                                model: [
                                    {"nameKey": "legendFree", "swatch": "#676a6b"},
                                    {"nameKey": "legendWeighted", "swatch": "#353738"},
                                    {"nameKey": "legendPadding", "swatch": "#222626"}
                                ]
                                RowLayout {
                                    spacing: 5
                                    Rectangle { Layout.preferredWidth: 11; Layout.preferredHeight: 11; color: modelData.swatch; border.color: "#858d87" }
                                    Text { text: window.t(modelData.nameKey); color: "#617286"; font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 350; Layout.minimumWidth: 330; Layout.fillHeight: true
                    radius: 20
                    color: "#fbfdff"; border.color: "#d8e3ed"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#260e2c45"
                        shadowBlur: 0.35
                        shadowVerticalOffset: 3
                    }
                    clip: true
                    Item {
                        id: settingsBackdrop
                        anchors.fill: parent
                        clip: true
                        Rectangle {
                            anchors.fill: parent
                            radius: 20
                            color: "#f9fcff"
                        }
                        Rectangle {
                            x: -35; y: 70
                            width: 230; height: 235; radius: 118
                            color: "#c7e2f5"; opacity: 0.12
                        }
                        Rectangle {
                            x: 200; y: 290
                            width: 180; height: 230; radius: 92
                            color: "#f6dfe0"; opacity: 0.13
                        }
                        Rectangle {
                            x: -45; y: parent.height - 170
                            width: 250; height: 180; radius: 90
                            color: "#dbeafa"; opacity: 0.13
                        }
                    }
                    Flickable {
                        id: controlsFlick
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: footerBar.top
                        anchors.bottomMargin: 8
                        contentWidth: width; contentHeight: settingsColumn.implicitHeight + 40
                        clip: true; boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 6
                            contentItem: Rectangle { radius: 3; color: "#b9c9d9" }
                        }
                        ColumnLayout {
                            id: settingsColumn
                            x: 22; y: 22; width: controlsFlick.width - 44; spacing: 12
                            ColumnLayout {
                                spacing: 5
                                Text { text: window.t("settingsTitle"); color: "#1d3045"; font.pixelSize: 20; font.bold: true }
                                Rectangle { Layout.preferredWidth: 34; Layout.preferredHeight: 3; radius: 2; color: "#bc2b2e" }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: localization.language === "zh_CN" ? 110 : 120
                                    radius: 12
                                    color: "#eff7fd"
                                    border.width: 1
                                    border.color: "#c9dceb"
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        anchors.topMargin: 8
                                        anchors.bottomMargin: 12
                                        spacing: 3
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: localization.language === "zh_CN" ? 20 : 30
                                        text: window.t("capacityLabel")
                                        color: "#2b4055"; font.pixelSize: 13; font.bold: true
                                        wrapMode: Text.WordWrap
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text { text: window.t("availableSlots"); color: "#7b8b9e"; font.pixelSize: 11 }
                                    TextField {
                                        id: capacityInput
                                        objectName: "capacityInput"
                                        Layout.fillWidth: true; Layout.preferredHeight: 48
                                        text: "250"; selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                                        validator: IntValidator { bottom: 1; top: 5000 }
                                        leftPadding: 4; rightPadding: 4
                                        topPadding: 0; bottomPadding: 0
                                        horizontalAlignment: TextInput.AlignHCenter
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: "#1e354b"; font.pixelSize: 19; font.bold: true
                                        background: Rectangle {
                                            radius: 10; color: "#ffffff"
                                            border.width: capacityInput.activeFocus ? 2 : 1
                                            border.color: capacityInput.activeFocus ? "#347dbd" : "#ccd9e5"
                                        }
                                    }
                                }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    Layout.preferredHeight: localization.language === "zh_CN" ? 110 : 120
                                    radius: 12
                                    color: "#eff7fd"
                                    border.width: 1
                                    border.color: "#c9dceb"
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        anchors.topMargin: 8
                                        anchors.bottomMargin: 12
                                        spacing: 3
                                    Text {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: localization.language === "zh_CN" ? 20 : 30
                                        text: window.t("initialFreeLabel")
                                        color: "#2b4055"; font.pixelSize: 13; font.bold: true
                                        wrapMode: Text.WordWrap
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text { text: window.t("baseCapacity"); color: "#7b8b9e"; font.pixelSize: 11 }
                                    TextField {
                                        id: freeInput
                                        objectName: "freeInput"
                                        Layout.fillWidth: true; Layout.preferredHeight: 48
                                        text: "125"; selectByMouse: true; inputMethodHints: Qt.ImhDigitsOnly
                                        validator: IntValidator { bottom: 0; top: 5000 }
                                        leftPadding: 4; rightPadding: 4
                                        topPadding: 0; bottomPadding: 0
                                        horizontalAlignment: TextInput.AlignHCenter
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: "#1e354b"; font.pixelSize: 19; font.bold: true
                                        background: Rectangle {
                                            radius: 10; color: "#ffffff"
                                            border.width: freeInput.activeFocus ? 2 : 1
                                            border.color: freeInput.activeFocus ? "#347dbd" : "#ccd9e5"
                                        }
                                    }
                                }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 9
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: window.t("packMuleBonus"); color: "#2b4055"; font.pixelSize: 13; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Text { text: window.t("currentLevelValue"); color: "#7b8b9e"; font.pixelSize: 11 }
                                }
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 5
                                    Repeater {
                                        model: 5
                                        Rectangle {
                                            Layout.fillWidth: true; Layout.preferredHeight: 49
                                            color: "#edf5fc"; radius: 9
                                            border.color: "#dceaf6"
                                            Column {
                                                anchors.centerIn: parent; spacing: 2
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: window.tf("levelSuffix", [index + 1]); color: "#718ca7"; font.pixelSize: 10 }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: currentLayout.valid ? "+" + currentLayout.perk[index] : "—"; color: "#2a6da7"; font.pixelSize: 12; font.bold: true }
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: "#e2eaf2"
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: window.t("supportedVersion")
                                    color: "#61768b"
                                    font.pixelSize: 12
                                }
                                ComboBox {
                                    id: gameCombo
                                    objectName: "gameCombo"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    model: gameManager.gamePaths
                                    background: Rectangle {
                                        radius: 10
                                        color: "#ffffff"
                                        border.width: gameCombo.activeFocus ? 2 : 1
                                        border.color: gameCombo.activeFocus ? "#347dbd" : "#ccd9e5"
                                    }
                                    indicator: Image {
                                        x: gameCombo.width - width - 14
                                        y: (gameCombo.height - height) / 2
                                        width: 18; height: 18
                                        source: "qrc:/assets/chevron-down.svg"
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                    delegate: ItemDelegate {
                                        width: gameCombo.width - 10
                                        height: 38
                                        text: modelData
                                        highlighted: gameCombo.highlightedIndex === index
                                        font.pixelSize: 11
                                        contentItem: Text {
                                            text: parent.text
                                            color: "#30485f"
                                            font: parent.font
                                            elide: Text.ElideMiddle
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            radius: 6
                                            color: parent.highlighted ? "#e8f3fc" : "#ffffff"
                                        }
                                    }
                                    popup: Popup {
                                        y: gameCombo.height + 4
                                        width: gameCombo.width
                                        height: Math.min(250, Math.max(46, gameCombo.count * 38 + 10))
                                        padding: 5
                                        contentItem: ListView {
                                            clip: true
                                            model: gameCombo.popup.visible ? gameCombo.delegateModel : null
                                            currentIndex: gameCombo.highlightedIndex
                                            boundsBehavior: Flickable.StopAtBounds
                                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                        }
                                        background: Rectangle {
                                            radius: 11
                                            color: "#ffffff"
                                            border.color: "#cbd8e5"
                                        }
                                    }
                                    function syncSelection() {
                                        const paths = gameManager.gamePaths
                                        const index = paths.indexOf(gameManager.selectedGamePath)
                                        if (currentIndex !== index)
                                            currentIndex = index
                                    }
                                    Component.onCompleted: syncSelection()
                                    onActivated: {
                                        window.setStatus("", [], false)
                                        gameManager.selectGame(currentText)
                                    }
                                    contentItem: Text {
                                        leftPadding: 10
                                        rightPadding: 24
                                        text: gameCombo.currentIndex < 0
                                              ? window.t("chooseGame") : gameCombo.currentText
                                        color: "#2b4055"
                                        font.pixelSize: 11
                                        elide: Text.ElideMiddle
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Connections {
                                        target: gameManager
                                        function onGamePathsChanged() {
                                            Qt.callLater(function() { gameCombo.syncSelection() })
                                        }
                                        function onSelectedGamePathChanged() {
                                            Qt.callLater(function() { gameCombo.syncSelection() })
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    FluentButton {
                                        Layout.preferredWidth: 130
                                        Layout.minimumWidth: 120
                                        Layout.preferredHeight: 38
                                        backdropSource: settingsBackdrop
                                        backdropScrollOffset: controlsFlick.contentY
                                        text: window.t("chooseManually")
                                        onClicked: gameFileDialog.open()
                                    }
                                    FluentButton {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        backdropSource: settingsBackdrop
                                        backdropScrollOffset: controlsFlick.contentY
                                        buttonStyle: "accent"
                                        enabled: !gameManager.scanning
                                        text: gameManager.scanning ? window.t("scanInProgress") : window.t("scanGame")
                                        onClicked: {
                                            window.setStatus("", [], false)
                                            gameManager.scanGames()
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    Layout.fillWidth: true
                                    text: !inputsValid
                                          ? window.t("invalidInputHint")
                                          : window.statusMessage.length > 0
                                            ? window.statusMessage : gameManager.message
                                    color: !inputsValid || window.statusIsError
                                           || (window.statusMessage.length === 0 && gameManager.messageIsError)
                                           ? "#b23339" : "#2a6d9e"
                                    font.pixelSize: 11
                                    wrapMode: Text.WrapAnywhere
                                }
                                FluentButton {
                                    Layout.preferredWidth: 112
                                    Layout.preferredHeight: 32
                                    backdropSource: settingsBackdrop
                                    backdropScrollOffset: controlsFlick.contentY
                                    enabled: gameManager.selectedGamePath.length > 0
                                    text: window.t("modsFolder")
                                    onClicked: {
                                        const result = gameManager.openModsFolder()
                                        window.setStatus(result.ok ? "statusModsOpened" : "statusOpenFailed",
                                                         result.ok ? [] : [window.tf(result.messageKey, result.messageArgs)],
                                                         !result.ok)
                                    }
                                }
                            }
                            Rectangle {
                                id: installButton
                                Layout.fillWidth: true; Layout.preferredHeight: 48
                                enabled: inputsValid && gameManager.selectedGamePath.length > 0
                                radius: 11
                                color: !enabled ? "#d7e2ec"
                                       : installMouse.pressed ? "#15517f"
                                       : installMouse.containsMouse ? "#1c689f" : "#287fb8"
                                border.width: 1
                                border.color: !enabled ? "#c4d1dc" : "#155f93"
                                Text {
                                    anchors.centerIn: parent
                                    text: window.t("installMod")
                                    color: installButton.enabled ? "#ffffff" : "#657b8e"
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                MouseArea {
                                    id: installMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const result = backpackGenerator.installMod(
                                            window.capacity, window.freeSlots, gameManager.selectedGamePath)
                                        window.saveSucceeded = result.ok
                                        window.setStatus(result.ok ? "statusInstalled" : "statusInstallFailed",
                                                         [result.ok ? result.path : window.tf(result.messageKey, result.messageArgs)],
                                                         !result.ok)
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        id: footerBar
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 20
                        anchors.rightMargin: 16
                        anchors.bottomMargin: 14
                        height: 40
                        spacing: 8
                        FluentButton {
                            Layout.preferredWidth: 44
                            Layout.fillHeight: true
                            backdropSource: settingsBackdrop
                            contentItem: Item {
                                Image {
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    source: "qrc:/assets/help-circle.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }
                            ToolTip.visible: hovered
                            ToolTip.text: window.t("aboutTooltip")
                            onClicked: aboutDialog.open()
                        }
                        FluentButton {
                            id: languageButton
                            Layout.preferredWidth: 44
                            Layout.fillHeight: true
                            backdropSource: settingsBackdrop
                            contentItem: Item {
                                Image {
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    source: "qrc:/assets/language-globe.svg"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }
                            ToolTip.visible: hovered
                            ToolTip.text: window.t("languageTooltip")
                            onClicked: languageMenu.open()
                            Popup {
                                id: languageMenu
                                x: 0
                                y: -height - 8
                                width: 172
                                height: 102
                                padding: 6
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                background: Rectangle {
                                    radius: 12
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: "#e9f5fd" }
                                        GradientStop { position: 1; color: "#fff8f3" }
                                    }
                                    border.color: "#91b7d2"
                                }
                                contentItem: Column {
                                    spacing: 4
                                    FluentButton {
                                        width: parent.width
                                        height: 42
                                        backdropSource: languageMenu.background
                                        text: window.t("chineseName") + (localization.language === "zh_CN" ? "  ✓" : "")
                                        onClicked: {
                                            localization.setLanguage("zh_CN")
                                            languageMenu.close()
                                        }
                                    }
                                    FluentButton {
                                        width: parent.width
                                        height: 42
                                        backdropSource: languageMenu.background
                                        text: window.t("englishName") + (localization.language === "en_US" ? "  ✓" : "")
                                        onClicked: {
                                            localization.setLanguage("en_US")
                                            languageMenu.close()
                                        }
                                    }
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        FluentButton {
                            id: exportButton
                            Layout.preferredWidth: 140
                            Layout.fillHeight: true
                            backdropSource: settingsBackdrop
                            enabled: inputsValid
                            text: window.t("exportMod")
                            onClicked: {
                                saveDialog.currentFile = backpackGenerator.suggestedFileUrl(
                                    window.capacity, window.freeSlots)
                                saveDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }
}
