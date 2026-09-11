import QtQuick

Item {
    id: root
    required property var appWindow
    anchors.fill: parent

    property alias streakCelebration: streakCelebration

    Avatar {
        id: avatarImg
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 20
        size: 48
        onClicked: avatarMenu.expanded = !avatarMenu.expanded
    }

    AvatarMenu {
        id: avatarMenu
        anchorItem: avatarImg
        onAccountSettingsRequested: root.appWindow.showAccountSettings = true
        onUserStatsRequested: root.appWindow.showUserStats = true
        onRequestFocusRestore: root.appWindow.restoreInputFocus()
    }
    StreakCelebration {
        id: streakCelebration
        anchors.bottom: parent.bottom
        anchors.right: avatarImg.left
        anchors.rightMargin: 12
    }

    ToggleChip {
        id: rainTrigger
        anchors.bottom: parent.bottom
        anchors.left: parent.left
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
        readonly property real restingX: rainTrigger.x + rainTrigger.width + 10 + streakTrigger.width + 10
        x: Math.max(shootoutTrigger.restingX, streakCalendar.panelRightEdge + 10)
        label: "shootout"
        active: root.appWindow.shootoutEnabled
        enabled: !root.appWindow.showUserStats && !root.appWindow.showAccountSettings
        onToggled: root.appWindow.shootoutEnabled = !root.appWindow.shootoutEnabled
    }

    StreakCalendar {
        id: streakCalendar
    }
}
