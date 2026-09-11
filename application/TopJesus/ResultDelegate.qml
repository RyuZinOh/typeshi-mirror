pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: resultRow
    required property var modelData
    required property int index
    property bool isNav: false
    height: 44

    signal activated(var entry)
    signal hovered(int idx)

    readonly property string previewFamily: resultRow.modelData.source.preview(resultRow.modelData.label)
    readonly property bool showPalette: resultRow.modelData.source.label === "Theme"
    readonly property var paletteColors: resultRow.showPalette ? Config.previewColors(resultRow.modelData.label, Config.currentVariant) : ({})
    readonly property bool isCurrent: resultRow.modelData.source.currentValue ? ("" + resultRow.modelData.source.currentValue()) === resultRow.modelData.label : false

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.surfaceContainerHigh
        opacity: resultRow.isNav ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }
        }
    }

    Text {
        visible: resultRow.isCurrent
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "current"
        font.pixelSize: 11
        color: Theme.primaryColor
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        Text {
            text: resultRow.modelData.categoryLabel
            font.pixelSize: 13
            font.family: resultRow.previewFamily
            color: Theme.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: ">"
            font.pixelSize: 13
            font.family: resultRow.previewFamily
            color: Theme.onSurfaceVariant
            opacity: 0.6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: resultRow.modelData.label
            font.pixelSize: 14
            font.family: resultRow.previewFamily
            color: Theme.onSurface
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            visible: resultRow.showPalette
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: 14
                height: 14
                radius: 3
                color: resultRow.paletteColors.primary ?? "transparent"
                border.color: Theme.outlineVariant
                border.width: 1
            }
            Rectangle {
                width: 14
                height: 14
                radius: 3
                color: resultRow.paletteColors.secondary ?? "transparent"
                border.color: Theme.outlineVariant
                border.width: 1
            }
            Rectangle {
                width: 14
                height: 14
                radius: 3
                color: resultRow.paletteColors.tertiary ?? "transparent"
                border.color: Theme.outlineVariant
                border.width: 1
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: mouse => {
            if (mouse.x !== 0 || mouse.y !== 0) {
                resultRow.hovered(resultRow.index);
            }
        }
        onClicked: resultRow.activated(resultRow.modelData)
    }
}
