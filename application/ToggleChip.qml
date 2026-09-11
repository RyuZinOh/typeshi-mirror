pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root

    property string label: ""
    property bool active: false
    property int chipHeight: 48

    signal toggled

    width: labelText.width + 32
    height: root.chipHeight
    radius: root.active ? height / 2 : 10
    color: root.active ? Theme.primaryColor : Theme.surfaceContainer
    border.color: Theme.outlineVariant
    border.width: 1
    opacity: root.enabled ? 1 : 0.4

    scale: chipArea.pressed ? 0.94 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: chipArea.pressed ? 80 : 220
            easing.type: chipArea.pressed ? Easing.OutQuad : Easing.OutBack
        }
    }
    Behavior on radius {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        font.pixelSize: 13
        font.bold: root.active
        color: {
            if (root.active) {
                return Theme.onPrimary;
            }
            if (chipArea.containsMouse) {
                return Theme.onSurface;
            }
            return Theme.onSurfaceVariant;
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        id: chipArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled()
    }
}
