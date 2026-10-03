import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "ui" as UI
import "ui/Theme.js" as Theme

UI.MaterialDialog {
    id: root
    property var host
    property var layoutData: ({valid: false})
    modal: true
    padding: 0
    width: Math.min(720, host.width - 40)
    height: Math.min(570, host.height - 40)
    header: Item {
        implicitHeight: 62
        Text {
            anchors.left: parent.left; anchors.leftMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            text: root.host.t("dataDetails")
            color: Theme.onSurface; font.pixelSize: 19; font.weight: Font.Medium
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.outlineVariant }
    }
    contentItem: Flickable {
        contentWidth: width
        contentHeight: detailsColumn.implicitHeight + 36
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: UI.MaterialScrollBar {}
        ColumnLayout {
            id: detailsColumn
            x: 20; y: 16
            width: parent.width - 40
            spacing: 14
            Text {
                Layout.fillWidth: true
                text: root.layoutData.valid ? root.host.tf("detailsSummary", [root.layoutData.capacity, root.layoutData.free, root.layoutData.backpackCapacity]) : ""
                color: Theme.onSurfaceVariant; font.pixelSize: 12; wrapMode: Text.WordWrap
            }
            Text { text: root.host.t("packMuleBonus"); color: Theme.primary; font.pixelSize: 15; font.bold: true }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: perkTable.implicitHeight + 16
                radius: 10; color: Theme.surfaceContainerLow; border.color: Theme.outlineVariant
                ColumnLayout {
                    id: perkTable
                    x: 8; y: 8; width: parent.width - 16
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: ["detailsLevel", "detailsCustom", "detailsPhysical", "detailsIncrement", "detailsCumulative"]
                            Text {
                                Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 38
                                text: root.host.t(modelData)
                                color: Theme.onSurfaceVariant; font.pixelSize: 11; font.bold: true
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                    Repeater {
                        model: 5
                        RowLayout {
                            required property int index
                            property int rank: index
                            Layout.fillWidth: true
                            spacing: 4
                            Repeater {
                                model: root.layoutData.valid ? [parent.rank + 1, root.layoutData.configuredPerk[parent.rank], root.layoutData.backpackPerk[parent.rank], root.layoutData.perkRank[parent.rank], root.layoutData.perk[parent.rank]] : []
                                Text {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 30
                                    text: modelData
                                    color: Theme.onSurface; font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: root.host.t("detailsPerkNote"); color: Theme.onSurfaceVariant; font.pixelSize: 11; wrapMode: Text.WordWrap }
            Text { text: root.host.t("detailsBackpacks"); color: Theme.primary; font.pixelSize: 15; font.bold: true }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: backpackTable.implicitHeight + 16
                radius: 10; color: Theme.surfaceContainerLow; border.color: Theme.outlineVariant
                ColumnLayout {
                    id: backpackTable
                    x: 8; y: 8; width: parent.width - 16
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { Layout.preferredWidth: 95; text: root.host.t("detailsType"); color: Theme.onSurfaceVariant; font.pixelSize: 11 }
                        Repeater {
                            model: 6
                            Text {
                                Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 34
                                text: root.host.tf("levelSuffix", [index + 1])
                                color: Theme.onSurfaceVariant; font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    Repeater {
                        model: ["smallBackpack", "mediumBackpack", "largeBackpack"]
                        RowLayout {
                            required property int index
                            required property string modelData
                            property int backpackIndex: index
                            Layout.fillWidth: true; spacing: 2
                            Text { Layout.preferredWidth: 95; text: root.host.t(parent.modelData); color: Theme.onSurface; font.pixelSize: 11; wrapMode: Text.WordWrap }
                            Repeater {
                                model: root.layoutData.valid ? root.layoutData.backpacks[parent.backpackIndex] : []
                                Text {
                                    Layout.fillWidth: true; Layout.preferredWidth: 1; Layout.preferredHeight: 36
                                    text: "+" + modelData
                                    color: Theme.onSurface; font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
            Text { Layout.fillWidth: true; text: root.host.t("detailsBackpackNote"); color: Theme.onSurfaceVariant; font.pixelSize: 11; wrapMode: Text.WordWrap }
            Text { Layout.fillWidth: true; text: root.host.t("detailsEquipmentNote"); color: Theme.onSurfaceVariant; font.pixelSize: 11; wrapMode: Text.WordWrap }
        }
    }
    footer: Item {
        implicitHeight: 60
        UI.MaterialButton {
            anchors.right: parent.right; anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 100; height: 36; buttonStyle: "primary"
            text: root.host.t("aboutClose")
            onClicked: root.close()
        }
    }
}
