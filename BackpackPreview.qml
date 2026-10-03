import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "ui" as UI
import "ui/Theme.js" as Theme

Rectangle {
    id: root
    property var host
    property var layoutData: ({valid: false})
    property bool characterEnabled: true
    property bool physicalEnabled: false
    property bool perkEnabled: false
    property int backpackType: 2
    property int backpackQuality: 5
    property int perkLevel: 0
    property bool gameMode: false
    property real pulse: 0.75
    readonly property int equippedSlots: layoutData.valid && physicalEnabled ? layoutData.backpacks[backpackType][backpackQuality] : 0
    readonly property int totalSlots: layoutData.valid ? layoutData.capacity + equippedSlots : 0
    // Pack Mule adds to one global carry allowance, with or without a backpack.
    // Equipping a backpack changes visible BagSize, not the skill's allowance.
    readonly property int carrySlots: layoutData.valid
        ? layoutData.free + (perkEnabled ? layoutData.perk[perkLevel] : 0) : 0
    readonly property int freeCount: Math.min(totalSlots, carrySlots)
    readonly property int characterFreeCount: layoutData.valid
        ? Math.min(layoutData.capacity, freeCount) : 0
    readonly property int physicalFreeCount: Math.max(0, freeCount - characterFreeCount)
    readonly property int rows: layoutData.valid ? Math.ceil(totalSlots / layoutData.cols) : 0
    readonly property int visibleRows: layoutData.valid ? Math.min(rows, layoutData.visibleRows) : 0
    readonly property int panelHeight: layoutData.valid ? visibleRows * layoutData.cell + 57 : 349
    radius: 16
    border.color: Theme.darkOutlineVariant
    color: Theme.darkSurface
    clip: true

    SequentialAnimation on pulse {
        running: root.visible && (!root.characterEnabled || (root.physicalEnabled && !root.gameMode))
        loops: Animation.Infinite
        NumberAnimation { to: 0.95; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.58; duration: 1400; easing.type: Easing.InOutSine }
    }
    function revealEquippedSlots() {
        if (!layoutData.valid || !previewGrid)
            return
        if (physicalEnabled && equippedSlots > 0)
            previewGrid.positionViewAtIndex(Math.max(0, layoutData.capacity - layoutData.cols * 2), GridView.Beginning)
        else
            previewGrid.positionViewAtBeginning()
    }
    onTotalSlotsChanged: Qt.callLater(revealEquippedSlots)
    onPhysicalEnabledChanged: Qt.callLater(revealEquippedSlots)
    function slotWeighted(index) {
        if (!layoutData.valid || index < 0 || index >= totalSlots)
            return false
        return index >= freeCount
    }
    UI.MaterialDialog {
        id: modeHelpDialog
        objectName: "modeHelpDialog"
        property bool gameDescription: false
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(480, root.host.width - 40)
        header: Item {
            implicitHeight: 58
            Text {
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: root.host.t(modeHelpDialog.gameDescription ? "gameMode" : "previewMode")
                color: Theme.onSurface; font.pixelSize: 18; font.weight: Font.Medium
            }
        }
        contentItem: Text {
            text: root.host.t(modeHelpDialog.gameDescription ? "gameModeDescription" : "previewModeDescription")
            color: Theme.onSurfaceVariant; font.pixelSize: 13
            wrapMode: Text.WordWrap
            leftPadding: 20; rightPadding: 20; topPadding: 4; bottomPadding: 18
        }
        footer: Item {
            implicitHeight: 56
            UI.MaterialButton {
                anchors.right: parent.right; anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: 36; text: root.host.t("aboutClose")
                onClicked: modeHelpDialog.close()
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        Item {
            id: previewHolder
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            property real previewScale: root.layoutData.valid
                ? Math.min((width - 12) / root.layoutData.width, (height - 12) / root.panelHeight, 0.90) : 0.5
            Rectangle {
                anchors.centerIn: parent
                width: root.layoutData.valid ? root.layoutData.width : 603
                height: root.panelHeight
                scale: previewHolder.previewScale
                transformOrigin: Item.Center
                visible: root.characterEnabled && root.layoutData.valid
                color: "#343637"
                border.width: 3; border.color: "#0b0d0d"
                clip: true
                Rectangle {
                    id: gameHeader
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                    anchors.margins: 3
                    height: 43; color: "#090b0b"
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 3; color: "#d9d5bf" }
                    Row {
                        anchors.left: parent.left; anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7
                        UI.SvgIcon { width: 23; height: 23; kind: "inventory"; tint: "#f3f3f0"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: root.host.t("inventoryTitle"); color: "#f3f3f0"; font.pixelSize: 25; font.bold: true }
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: "0 $"; color: "#f7de80"; font.pixelSize: 18
                    }
                }
                GridView {
                    id: previewGrid
                    objectName: "previewGrid"
                    anchors.top: gameHeader.bottom; anchors.left: parent.left
                    anchors.topMargin: 3; anchors.leftMargin: 3
                    width: root.layoutData.valid ? root.layoutData.cols * root.layoutData.cell + 13 : 0
                    height: root.layoutData.valid ? root.visibleRows * root.layoutData.cell : 0
                    cellWidth: root.layoutData.valid ? root.layoutData.cell : 66
                    cellHeight: cellWidth
                    model: root.layoutData.valid ? root.layoutData.cols * root.rows : 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        required property int index
                        width: previewGrid.cellWidth
                        height: previewGrid.cellHeight
                        readonly property bool padding: index >= root.totalSlots
                        readonly property bool physicalSlot: !padding && index >= root.layoutData.capacity
                        readonly property bool marked: physicalSlot && !root.gameMode
                        readonly property bool weighted: !padding && root.slotWeighted(index)
                        color: padding ? "#222626" : marked ? (weighted ? "#422b2c" : "#294238") : weighted ? "#353738" : "#676a6b"
                        border.width: 2
                        border.color: marked ? (weighted ? "#7d4847" : "#407658") : padding ? "#343838" : "#101211"
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 3
                            visible: parent.marked
                            color: parent.weighted ? "#cf5149" : "#4fc781"
                            opacity: root.pulse * 0.13
                        }
                        PixelIcon {
                            anchors.centerIn: parent
                            width: parent.width * 0.46; height: width
                            visible: parent.marked
                            tint: parent.weighted ? "#ff7970" : "#70e3a2"
                            opacity: root.pulse
                        }
                        UI.SvgIcon {
                            anchors.centerIn: parent
                            visible: parent.weighted && !parent.marked
                            width: parent.width * 0.24; height: width
                            kind: "weight"; tint: "#626665"
                        }
                    }
                    ScrollBar.vertical: UI.MaterialScrollBar {
                        dark: true
                        width: 10
                        policy: root.rows > root.visibleRows ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    }
                }
            }
            Column {
                anchors.centerIn: parent
                visible: !root.characterEnabled
                spacing: 16
                PixelIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 96; height: 96
                    forbidden: true; glow: true; tint: "#ee5b56"
                    opacity: root.pulse
                }
                Text { text: root.host.t("previewDisabled"); color: Theme.darkOnSurfaceVariant; font.pixelSize: 13 }
            }
            Text {
                anchors.centerIn: parent
                width: parent.width * 0.8
                visible: root.characterEnabled && !root.layoutData.valid
                text: root.host.t("invalidInputHint")
                color: Theme.darkOnSurface; font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.darkOutlineVariant }
        GridLayout {
            Layout.fillWidth: true
            columns: root.width >= 700 ? 2 : 1
            columnSpacing: 14; rowSpacing: 8
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
        Flow {
            objectName: "previewOptionsFlow"
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            spacing: 20
            Row {
                objectName: "characterOptionsRow"
                height: 32; spacing: 8
                Text { width: 40; height: 32; text: root.host.t("previewOptions"); color: Theme.darkOnSurfaceVariant; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
                UI.MaterialCheckBox {
                    dark: true
                    objectName: "characterCheck"
                    width: 80
                    text: root.host.t("characterBackpack")
                    checked: root.characterEnabled
                    onToggled: root.characterEnabled = checked
                }
            }
            Item {
                id: physicalOptions
                objectName: "physicalOptions"
                width: physicalOptionsRow.width; height: 32
                Rectangle {
                    x: -11; y: 5; width: 1; height: 22
                    color: Theme.darkOutlineVariant
                    opacity: physicalOptions.x > 0 ? 1 : 0
                }
                Row {
                id: physicalOptionsRow
                height: 32; spacing: 7
                UI.MaterialCheckBox {
                    dark: true
                    objectName: "physicalCheck"
                    width: 76
                    text: root.host.t("physicalBackpack")
                    checked: root.physicalEnabled
                    onToggled: root.physicalEnabled = checked
                }
                UI.MaterialComboBox {
                    objectName: "previewTypeCombo"
                    width: 86
                    dark: true
                    model: [root.host.t("smallBackpack"), root.host.t("mediumBackpack"), root.host.t("largeBackpack")]
                    selectedIndex: root.backpackType
                    onActivated: root.backpackType = currentIndex
                }
                UI.MaterialComboBox {
                    objectName: "previewQualityCombo"
                    width: 58; dark: true
                    model: [1,2,3,4,5,6].map(n => root.host.tf("previewRankLabel", [n]))
                    selectedIndex: root.backpackQuality
                    onActivated: root.backpackQuality = currentIndex
                }
            }
            }
            Item {
                id: perkOptions
                objectName: "perkOptions"
                width: perkOptionsRow.width; height: 32
                Rectangle {
                    x: -11; y: 5; width: 1; height: 22
                    color: Theme.darkOutlineVariant
                    opacity: perkOptions.x > 0 ? 1 : 0
                }
                Row {
                id: perkOptionsRow
                height: 32; spacing: 7
                UI.MaterialCheckBox {
                    dark: true
                    objectName: "perkCheck"
                    width: 86
                    text: root.host.t("packMulePreview")
                    checked: root.perkEnabled
                    onToggled: root.perkEnabled = checked
                }
                UI.MaterialComboBox {
                    objectName: "previewPerkCombo"
                    width: 58; dark: true
                    model: [1,2,3,4,5].map(n => root.host.tf("previewRankLabel", [n]))
                    selectedIndex: root.perkLevel
                    onActivated: root.perkLevel = currentIndex
                }
            }
            }
        }
        Text {
            Layout.fillWidth: true
            text: root.layoutData.valid && root.characterEnabled
                  ? root.host.tf("previewCounts", [root.totalSlots, root.freeCount, root.totalSlots - root.freeCount]) : ""
            color: Theme.darkOnSurfaceVariant; font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                spacing: 6
                UI.PreviewModeButton {
                    buttonName: "gameModeButton"; helpName: "gameModeHelpButton"
                    text: root.host.t("gameMode")
                    helpLabel: root.host.tf("modeHelp", [text])
                    selected: root.gameMode
                    onActivated: root.gameMode = true
                    onHelpRequested: { modeHelpDialog.gameDescription = true; modeHelpDialog.open() }
                }
                UI.PreviewModeButton {
                    buttonName: "previewModeButton"; helpName: "previewModeHelpButton"
                    text: root.host.t("previewMode")
                    helpLabel: root.host.tf("modeHelp", [text])
                    selected: !root.gameMode
                    onActivated: root.gameMode = false
                    onHelpRequested: { modeHelpDialog.gameDescription = false; modeHelpDialog.open() }
                }
            }
        }
    }
}
