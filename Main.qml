import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import "ui" as UI
import "ui/Theme.js" as Theme

ApplicationWindow {
    id: window
    width: Math.min(1200, Math.max(760, Screen.width - 80))
    height: Math.min(700, Math.max(520, Screen.height - 100))
    minimumWidth: 760
    minimumHeight: 520
    visible: true
    title: window.t("appTitle")
    color: Theme.surfaceContainerLow
    font.family: uiFontFamily
    font.weight: Font.Normal
    background: Rectangle {
        z: -1
        color: Theme.surfaceContainerLow
    }

    property int capacity: Number(capacityInput.text)
    property int freeSlots: Number(freeInput.text)
    property int backpackCapacity: Number(backpackInput.text)
    readonly property int columns: Math.round(columnsSetting.value)
    readonly property int maxBackpackWidth: Math.round(widthSetting.value)
    readonly property int compactActionHeight: 34
    property var appliedAppearance: ({})
    property bool applyingEdgeFit: false
    function resetEdgeFit() {
        if (!applyingEdgeFit) appliedAppearance = ({})
    }
    onColumnsChanged: resetEdgeFit()
    onMaxBackpackWidthChanged: resetEdgeFit()
    property bool inputsValid: capacityInput.text.length > 0 && freeInput.text.length > 0
                               && Number.isInteger(Number(capacityInput.text))
                               && Number.isInteger(Number(freeInput.text))
                               && backpackInput.text.length > 0
                               && Number.isInteger(Number(backpackInput.text))
                               && capacity >= 1 && capacity <= 5000
                               && freeSlots >= 0 && freeSlots <= capacity
                               && backpackCapacity >= 0 && backpackCapacity <= 5000
    property var currentLayout: inputsValid ? backpackGenerator.layout(capacity, freeSlots, backpackCapacity,
                                                                       columns, maxBackpackWidth, appliedAppearance) : ({"valid": false})
    property bool scanNoticePending: false
    function applyEdgeFit(mode) {
        if (!inputsValid) return
        const result = backpackGenerator.autoLayout(capacity, freeSlots, backpackCapacity, columns,
            maxBackpackWidth, mode, currentLayout, previewStage.characterEnabled ? previewStage.totalSlots : capacity)
        if (!result.valid) return
        applyingEdgeFit = true
        widthSetting.value = result.maxWidth
        appliedAppearance = result.appearance
        applyingEdgeFit = false
    }

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
    function showNotice(message, isError, installedModPath, installedGamePath) {
        noticeDialog.messageText = message
        noticeDialog.isError = isError || false
        noticeDialog.installedModPath = installedModPath || ""
        noticeDialog.installedGamePath = installedGamePath || ""
        cleanupCheckBox.checked = true
        noticeDialog.open()
    }
    Connections {
        target: gameManager
        function onMessageChanged() {
            if (!window.scanNoticePending)
                return
            window.showNotice(gameManager.message, gameManager.messageIsError)
            if (!gameManager.scanning)
                window.scanNoticePending = false
        }
    }

    FileDialog {
        id: saveDialog
        title: window.t("saveDialogTitle")
        fileMode: FileDialog.SaveFile
        nameFilters: [window.t("zipFilter")]
        onAccepted: {
            const result = backpackGenerator.saveZip(window.capacity, window.freeSlots, window.backpackCapacity,
                                                       selectedFile, window.columns, window.maxBackpackWidth, window.appliedAppearance)
            window.showNotice(window.tf(result.ok ? "statusSaved" : "statusGenerateFailed",
                                        [result.ok ? result.path : window.tf(result.messageKey, result.messageArgs)]),
                              !result.ok)
        }
    }

    FileDialog {
        id: gameFileDialog
        title: window.t("gameDialogTitle")
        fileMode: FileDialog.OpenFile
        nameFilters: [window.t("gameExeFilter")]
        onAccepted: {
            window.scanNoticePending = false
            gameManager.addGame(selectedFile)
            window.showNotice(gameManager.message, gameManager.messageIsError)
        }
    }

    UI.MaterialDialog {
        id: noticeDialog
        objectName: "noticeDialog"
        property string messageText: ""
        property bool isError: false
        property string installedModPath: ""
        property string installedGamePath: ""
        readonly property bool installationNotice: installedModPath.length > 0 && !isError
        anchors.centerIn: Overlay.overlay
        width: Math.min(460, window.width - 40)
        height: Math.min(installationNotice ? 300 : 230, window.height - 40)
        modal: true
        padding: 0
        header: Rectangle {
            implicitHeight: 54
            radius: Theme.dialogRadius
            color: "transparent"
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: window.t(noticeDialog.isError ? "noticeErrorTitle" : "noticeTitle")
                color: noticeDialog.isError ? Theme.error : Theme.onSurface
                font.pixelSize: 17
                font.bold: true
            }
        }
        contentItem: Flickable {
            clip: true
            contentWidth: width
            contentHeight: noticeColumn.height + 32
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: UI.MaterialScrollBar {}
            Column {
                id: noticeColumn
                x: 20; y: 16
                width: parent.width - 40
                spacing: 16
                Text {
                    width: parent.width
                    text: noticeDialog.messageText
                    wrapMode: Text.WrapAnywhere
                    color: Theme.onSurfaceVariant
                    font.pixelSize: 13
                }
                UI.MaterialCheckBox {
                    id: cleanupCheckBox
                    objectName: "cleanupCheckBox"
                    width: parent.width
                    visible: noticeDialog.installationNotice
                    checked: true
                    text: window.t("cleanupOtherMods")
                    font.pixelSize: 13
                }
            }
        }
        footer: Rectangle {
            implicitHeight: 58
            radius: Theme.dialogRadius
            color: "transparent"
            UI.MaterialButton {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: 100; height: 36
                buttonStyle: "accent"
                objectName: "noticeConfirmButton"
                text: window.t(noticeDialog.installationNotice ? "confirm" : "aboutClose")
                onClicked: {
                    const shouldClean = noticeDialog.installationNotice && cleanupCheckBox.checked
                    const installedGamePath = noticeDialog.installedGamePath
                    const installedModPath = noticeDialog.installedModPath
                    noticeDialog.close()
                    if (shouldClean) {
                        const result = backpackGenerator.removeOtherGeneratedMods(installedGamePath, installedModPath)
                        if (!result.ok)
                            window.showNotice(window.tf(result.messageKey, result.messageArgs), true)
                    }
                }
            }
        }
    }

    UI.MaterialDialog {
        id: aboutDialog
        objectName: "aboutDialog"
        anchors.centerIn: Overlay.overlay
        width: Math.min(620, window.width - 36)
        height: Math.min(550, window.height - 36)
        modal: true
        padding: 0
        header: Rectangle {
            implicitHeight: 94
            radius: Theme.dialogRadius
            color: Theme.surfaceContainerHigh
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.outlineVariant }
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
                        color: Theme.onSurface; font.pixelSize: 20; font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: window.t("aboutAuthor") + "  ·  v" + appVersion
                        color: Theme.onSurfaceVariant; font.pixelSize: 12
                    }
                }
                UI.MaterialButton {
                    Layout.preferredWidth: 34; Layout.preferredHeight: 34
                    buttonStyle: "ghost"
                    contentItem: Item {
                        UI.SvgIcon { anchors.centerIn: parent; width: 20; height: 20; kind: "close" }
                    }
                    onClicked: aboutDialog.close()
                }
            }
        }
        contentItem: Flickable {
            clip: true
            contentWidth: width
            contentHeight: aboutColumn.implicitHeight + 40
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: UI.MaterialScrollBar {}
            ColumnLayout {
                id: aboutColumn
                x: 22; y: 20
                width: parent.width - 44
                spacing: 16
                Text {
                    Layout.fillWidth: true
                    text: window.t("aboutIntro")
                    wrapMode: Text.WordWrap
                    color: Theme.onSurfaceVariant; font.pixelSize: 14
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: freedomColumn.implicitHeight + 30
                    radius: 14; color: Theme.surfaceContainerLow; border.color: Theme.outlineVariant
                    ColumnLayout {
                        id: freedomColumn
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 7
                        Text { text: window.t("aboutFreedomTitle"); color: Theme.primary; font.pixelSize: 15; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: window.t("aboutFreedomBody")
                            wrapMode: Text.WordWrap
                            color: Theme.onSurfaceVariant; font.pixelSize: 13
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: installColumn.implicitHeight + 30
                    radius: 14; color: Theme.surfaceContainerLow; border.color: Theme.outlineVariant
                    ColumnLayout {
                        id: installColumn
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 7
                        Text { text: window.t("aboutInstallTitle"); color: Theme.primary; font.pixelSize: 15; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: window.t("aboutInstallBody")
                            wrapMode: Text.WordWrap
                            color: Theme.onSurfaceVariant; font.pixelSize: 13
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: repositoryColumn.implicitHeight + 28
                    radius: 14; color: Theme.primaryContainer; border.color: Theme.primaryContainer
                    ColumnLayout {
                        id: repositoryColumn
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 5
                        Text { text: window.t("aboutGithub"); color: Theme.onPrimaryContainer; font.pixelSize: 14; font.bold: true }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Text {
                                Layout.fillWidth: true
                                text: "<a href=\"https://github.com/WangCAC/7-Days-Backpack-Tools\">https://github.com/WangCAC/7-Days-Backpack-Tools</a>"
                                linkColor: Theme.primary
                                textFormat: Text.StyledText
                                wrapMode: Text.WrapAnywhere
                                font.pixelSize: 12
                                onLinkActivated: function(link) { Qt.openUrlExternally(link) }
                            }
                            UI.SvgIcon { Layout.preferredWidth: 14; Layout.preferredHeight: 14; kind: "external" }
                        }
                    }
                }
            }
        }
        footer: Item {
            implicitHeight: 64
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.outlineVariant }
            UI.MaterialButton {
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                width: 96; height: 40; buttonStyle: "primary"
                text: window.t("aboutClose")
                onClicked: aboutDialog.close()
            }
        }
    }

    EdgeFitDialog {
        id: edgeFitDialog
        objectName: "edgeFitDialog"
        anchors.centerIn: Overlay.overlay
        host: window
        onApplyRequested: function(mode) { window.applyEdgeFit(mode) }
    }

    DataDetailsDialog {
        id: detailsDialog
        objectName: "detailsDialog"
        anchors.centerIn: Overlay.overlay
        host: window
        layoutData: window.currentLayout
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
                    radius: Theme.panelRadius
                    color: Theme.surface
                    border.color: Theme.outlineVariant
                    layer.enabled: false
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
                            Text { Layout.fillWidth: true; text: window.t("previewTitle"); color: Theme.onSurface; font.pixelSize: 16; font.bold: true; elide: Text.ElideRight }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                Layout.preferredWidth: liveText.implicitWidth + 26
                                Layout.preferredHeight: 28
                                radius: 14
                                color: Theme.secondaryContainer
                                border.color: Theme.secondaryContainer
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle {
                                        id: modeStatusDot
                                        objectName: "modeStatusDot"
                                        width: 7; height: 7; radius: 4; color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                        SequentialAnimation on opacity {
                                            running: window.visible
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 1; to: 0.25; duration: 1400; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: 0.25; to: 1; duration: 1400; easing.type: Easing.InOutSine }
                                        }
                                    }
                                    Text {
                                        id: liveText
                                        objectName: "modeStatusLabel"
                                        text: window.t(previewStage.gameMode ? "gameMode" : "previewMode")
                                        color: Theme.onSecondaryContainer; font.pixelSize: 11
                                    }
                                }
                            }
                        }
                        BackpackPreview {
                            id: previewStage
                            objectName: "backpackPreview"
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Layout.leftMargin: 16; Layout.rightMargin: 16
                            host: window
                            layoutData: window.currentLayout
                        }
                        Flow {
                            Layout.fillWidth: true
                            Layout.preferredHeight: childrenRect.height
                            Layout.leftMargin: 18; Layout.rightMargin: 18
                            Layout.topMargin: 10; Layout.bottomMargin: 14
                            spacing: 12
                            Repeater {
                                model: [
                                    {"nameKey": "legendFree", "swatch": "#676a6b"},
                                    {"nameKey": "legendWeighted", "swatch": "#353738"},
                                    {"nameKey": "legendPadding", "swatch": "#222626"}
                                ].concat(previewStage.gameMode ? [] : [
                                    {"nameKey": "legendBackpackLocked", "swatch": "#c65651"},
                                    {"nameKey": "legendBackpackUnlocked", "swatch": "#44ae76"}
                                ])
                                Row {
                                    spacing: 5
                                    Rectangle { width: 10; height: 10; color: modelData.swatch; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: window.t(modelData.nameKey); color: Theme.onSurfaceVariant; font.pixelSize: 10 }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 350; Layout.minimumWidth: 330; Layout.fillHeight: true
                    id: settingsPanel
                    readonly property int contentInset: 22
                    readonly property int actionSpacing: 8
                    readonly property real actionWidth: (width - contentInset * 2 - actionSpacing) / 2
                    radius: Theme.panelRadius
                    color: Theme.surface; border.color: Theme.outlineVariant
                    layer.enabled: false
                    clip: true
                    Item {
                        id: settingsBackdrop
                        anchors.fill: parent
                        Rectangle { anchors.fill: parent; radius: Theme.panelRadius; color: Theme.surface }
                    }
                    Flickable {
                        id: controlsFlick
                        objectName: "controlsFlick"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: footerBar.top
                        anchors.bottomMargin: 8
                        contentWidth: width; contentHeight: settingsColumn.y + settingsColumn.implicitHeight + 4
                        clip: true; boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: UI.MaterialScrollBar {
                            objectName: "settingsScrollBar"
                        }
                        ColumnLayout {
                            id: settingsColumn
                            x: settingsPanel.contentInset; y: 18
                            width: controlsFlick.width - settingsPanel.contentInset * 2; spacing: 10
                            ColumnLayout {
                                spacing: 3
                                Text {
                                    text: window.t("settingsTitle")
                                    color: Theme.onSurface
                                    font.pixelSize: 16; font.bold: true
                                    lineHeight: 20; lineHeightMode: Text.FixedHeight
                                }
                                Rectangle { Layout.preferredWidth: 28; Layout.preferredHeight: 2; radius: 1; color: Theme.primary }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                UI.MaterialNumberSetting {
                                    id: capacityInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    label: window.t("capacityLabel")
                                    fieldName: "capacityInput"
                                    minimum: 1
                                    text: "48"
                                }
                                UI.MaterialNumberSetting {
                                    id: freeInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    label: window.t("initialFreeLabel")
                                    fieldName: "freeInput"
                                    text: "32"
                                }
                                UI.MaterialNumberSetting {
                                    id: backpackInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    label: window.t("physicalCapacityLabel")
                                    fieldName: "backpackInput"
                                    text: "48"
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    spacing: 8
                                    UI.MaterialSliderSetting {
                                        id: columnsSetting
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 52
                                        label: window.t("slotsPerRow")
                                        sliderName: "columnsSlider"
                                        from: 8; to: 20; value: 8
                                        minimumLabel: "8"; maximumLabel: "20"
                                        showValue: true
                                    }
                                    UI.MaterialSliderSetting {
                                        id: widthSetting
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 52
                                        label: window.t("backpackMaxWidth")
                                        sliderName: "widthSlider"
                                        from: 603; to: 1678; value: 603
                                        minimumLabel: window.t("vanillaWidth")
                                        maximumLabel: window.t("widestWidth")
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    spacing: 8
                                    UI.MaterialButton {
                                        objectName: "detailsButton"
                                        iconName: "details"
                                        Layout.preferredWidth: settingsPanel.actionWidth
                                        Layout.preferredHeight: window.compactActionHeight
                                        leftPadding: 8; rightPadding: 8
                                        text: window.t("viewDataDetails")
                                        enabled: window.inputsValid
                                        onClicked: detailsDialog.open()
                                    }
                                    UI.MaterialButton {
                                        objectName: "autoFitButton"
                                        iconName: "autoFit"
                                        Layout.preferredWidth: settingsPanel.actionWidth
                                        Layout.preferredHeight: window.compactActionHeight
                                        text: window.t("autoFit")
                                        buttonStyle: "accent"
                                        enabled: window.inputsValid
                                        onClicked: edgeFitDialog.open()
                                    }
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: window.t("supportedVersion")
                                    color: Theme.onSurfaceVariant
                                    font.pixelSize: 12
                                }
                                UI.MaterialComboBox {
                                    id: gameCombo
                                    objectName: "gameCombo"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    model: gameManager.gamePaths
                                    bindSelection: false
                                    selectedIndex: -1
                                    placeholderText: window.t("chooseGame")
                                    textElide: Text.ElideMiddle
                                    itemHeight: 38
                                    font.pixelSize: 11
                                    function syncSelection() {
                                        const index = gameManager.gamePaths.indexOf(gameManager.selectedGamePath)
                                        if (currentIndex !== index)
                                            currentIndex = index
                                    }
                                    Component.onCompleted: syncSelection()
                                    onActivated: gameManager.selectGame(currentText)
                                    Connections {
                                        target: gameManager
                                        function onGamePathsChanged() { Qt.callLater(gameCombo.syncSelection) }
                                        function onSelectedGamePathChanged() { gameCombo.syncSelection() }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    UI.MaterialButton {
                                        objectName: "browseGameButton"
                                        iconName: "browse"
                                        Layout.preferredWidth: settingsPanel.actionWidth
                                        Layout.preferredHeight: window.compactActionHeight
                                        text: window.t("chooseManually")
                                        onClicked: gameFileDialog.open()
                                    }
                                    UI.MaterialButton {
                                        objectName: "scanGameButton"
                                        iconName: "scan"
                                        Layout.preferredWidth: settingsPanel.actionWidth
                                        Layout.preferredHeight: window.compactActionHeight
                                        buttonStyle: "accent"
                                        enabled: !gameManager.scanning
                                        text: gameManager.scanning ? window.t("scanInProgress") : window.t("scanGame")
                                        onClicked: {
                                            window.scanNoticePending = true
                                            gameManager.scanGames()
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Item { Layout.fillWidth: true }
                                UI.MaterialButton {
                                    Layout.preferredWidth: settingsPanel.actionWidth
                                    Layout.preferredHeight: window.compactActionHeight
                                    objectName: "modsFolderButton"
                                    iconName: "folder"
                                    enabled: gameManager.selectedGamePath.length > 0
                                    text: window.t("modsFolder")
                                    onClicked: gameManager.openModsFolder()
                                }
                            }
                            UI.MaterialButton {
                                id: installButton
                                objectName: "installButton"
                                iconName: "install"; iconSize: 20
                                Layout.fillWidth: true; Layout.preferredHeight: 48
                                buttonStyle: "primary"
                                enabled: inputsValid && gameManager.selectedGamePath.length > 0
                                text: window.t("installMod")
                                font.pixelSize: 15
                                onClicked: {
                                    const result = backpackGenerator.installMod(
                                        window.capacity, window.freeSlots, window.backpackCapacity, gameManager.selectedGamePath,
                                        window.columns, window.maxBackpackWidth, window.appliedAppearance)
                                    window.showNotice(window.tf(result.ok ? "statusInstalled" : "statusInstallFailed",
                                                                [result.ok ? result.path : window.tf(result.messageKey, result.messageArgs)]),
                                                      !result.ok, result.ok ? result.path : "", gameManager.selectedGamePath)
                                }
                            }
                        }
                    }
                    RowLayout {
                        id: footerBar
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: settingsPanel.contentInset
                        anchors.rightMargin: settingsPanel.contentInset
                        anchors.bottomMargin: 14
                        height: 40
                        spacing: 8
                        UI.MaterialButton {
                            Layout.preferredWidth: 44
                            Layout.fillHeight: true
                            contentItem: Item {
                                UI.SvgIcon {
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    kind: "help"
                                }
                            }
                            buttonStyle: "ghost"
                            UI.MaterialToolTip {
                                visible: parent.hovered && !aboutDialog.visible
                                text: window.t("aboutTooltip")
                            }
                            objectName: "aboutButton"
                            onClicked: aboutDialog.open()
                        }
                        UI.MaterialButton {
                            id: languageButton
                            objectName: "languageButton"
                            Layout.preferredWidth: 44
                            Layout.fillHeight: true
                            contentItem: Item {
                                UI.SvgIcon {
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    kind: "language"
                                }
                            }
                            buttonStyle: "ghost"
                            UI.MaterialToolTip {
                                visible: parent.hovered && !languageMenu.visible
                                text: window.t("languageTooltip")
                            }
                            onClicked: languageMenu.open()
                            UI.MaterialPopup {
                                id: languageMenu
                                objectName: "languageMenu"
                                x: 0
                                y: -height - 8
                                width: 172
                                height: 102
                                padding: 6
                                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                                contentItem: Column {
                                    spacing: 4
                                    UI.MaterialMenuItem {
                                        width: parent.width
                                        height: 42
                                        selected: localization.language === "zh_CN"
                                        text: window.t("chineseName")
                                        onClicked: {
                                            localization.setLanguage("zh_CN")
                                            languageMenu.close()
                                        }
                                    }
                                    UI.MaterialMenuItem {
                                        width: parent.width
                                        height: 42
                                        selected: localization.language === "en_US"
                                        text: window.t("englishName")
                                        onClicked: {
                                            localization.setLanguage("en_US")
                                            languageMenu.close()
                                        }
                                    }
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        UI.MaterialButton {
                            id: exportButton
                            objectName: "exportButton"
                            iconName: "export"
                            Layout.preferredWidth: settingsPanel.actionWidth
                            Layout.preferredHeight: window.compactActionHeight
                            Layout.alignment: Qt.AlignVCenter
                            enabled: inputsValid
                            text: window.t("exportMod")
                            onClicked: {
                                saveDialog.currentFile = backpackGenerator.suggestedFileUrl(
                                    window.capacity, window.freeSlots, window.backpackCapacity,
                                    window.columns, window.maxBackpackWidth, window.appliedAppearance)
                                saveDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }
}
