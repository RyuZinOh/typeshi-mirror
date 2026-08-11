import QtQuick
import typeShitter

Item {
    id: root
    required property var appWindow
    anchors.fill: parent

    readonly property alias themePickerVisible: themePicker.visible

    Item {
        id: profileTrigger
        anchors.bottom: parent.bottom
        anchors.right: fontTrigger.left
        anchors.rightMargin: 16
        anchors.margins: 20
        width: nameLabel.width + avatarImg.width + 8
        height: 28

        Row {
            anchors.fill: parent
            spacing: 8

            Avatar {
                id: avatarImg
                anchors.verticalCenter: parent.verticalCenter
                size: 48
            }

            Text {
                id: nameLabel
                anchors.verticalCenter: parent.verticalCenter
                text: Config.username
                font.pixelSize: 13
                color: profileTriggerArea.containsMouse ? Theme.primaryColor : Theme.onSurfaceVariant

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }

        MouseArea {
            id: profileTriggerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: profileEditor.open()
        }
    }

    Item {
        id: themeTrigger
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 20
        width: 28
        height: 28

        Icon {
            anchors.centerIn: parent
            source: "assets/icons/palette.svg"
            iconSize: 20
            color: themeTriggerArea.containsMouse ? Theme.primaryColor : Theme.onSurfaceVariant

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            id: themeTriggerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: themePicker.open()
        }
    }

    Item {
        id: fontTrigger
        anchors.bottom: parent.bottom
        anchors.right: themeTrigger.left
        anchors.rightMargin: 16
        anchors.margins: 20
        width: 28
        height: 28

        Icon {
            anchors.centerIn: parent
            source: "assets/icons/font.svg"
            iconSize: 20
            color: fontTriggerArea.containsMouse ? Theme.primaryColor : Theme.onSurfaceVariant
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            id: fontTriggerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fontPicker.open()
        }
    }

    ToggleChip {
        id: crtTrigger
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20
        label: "CRT mode"
        active: root.appWindow.crtEnabled
        onToggled: root.appWindow.crtEnabled = !root.appWindow.crtEnabled
    }

    ToggleChip {
        id: rainTrigger
        anchors.bottom: parent.bottom
        anchors.left: crtTrigger.right
        anchors.leftMargin: 10
        anchors.margins: 20
        label: "rain mode"
        active: root.appWindow.rainEnabled
        onToggled: root.appWindow.rainEnabled = !root.appWindow.rainEnabled
    }

    Rectangle {
        id: streakTrigger
        anchors.bottom: parent.bottom
        anchors.left: rainTrigger.right
        anchors.leftMargin: 10
        anchors.margins: 20
        width: streakLabel.width + 32
        height: 48
        radius: 10
        color: streakArea.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1

        opacity: 1 - Math.min(1, streakCalendar.progress / 0.3)
        visible: opacity > 0.01
        enabled: opacity > 0.5

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Text {
            id: streakLabel
            anchors.centerIn: parent
            text: "streaks"
            font.pixelSize: 13
            color: Theme.onSurfaceVariant
        }

        MouseArea {
            id: streakArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const pos = streakTrigger.mapToItem(root, 0, 0);
                streakCalendar.openFrom(pos.x, pos.y, streakTrigger.width, streakTrigger.height);
            }
        }
    }

    ToggleChip {
        id: shootoutTrigger
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        readonly property real restingX: crtTrigger.x + crtTrigger.width + 10 + rainTrigger.width + 10 + streakTrigger.width + 10
        x: Math.max(shootoutTrigger.restingX, streakCalendar.panelRightEdge + 10)
        label: "shootout"
        active: root.appWindow.shootoutEnabled
        enabled: root.appWindow.testMode !== "multiplayer"
        onToggled: root.appWindow.shootoutEnabled = !root.appWindow.shootoutEnabled
    }

    StreakCalendar {
        id: streakCalendar
    }

    ThemePicker {
        id: themePicker
    }
    ProfileEditor {
        id: profileEditor
    }
    FontPicker {
        id: fontPicker
    }
}
