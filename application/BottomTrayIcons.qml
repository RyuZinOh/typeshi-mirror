import QtQuick
import Ryu.Extraa
import Ryu.Shapes
import typeShitter

Item {
    id: root
    required property var appWindow
    anchors.fill: parent

    MaterialButton {
        id: rainTrigger
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 20

        label: "rain mode"
        type: MaterialButton.Outlined
        sizeStyle: MaterialButton.Small
        shape: MaterialButton.Square
        checkable: true
        checked: root.appWindow.rainEnabled
        onToggled: root.appWindow.rainEnabled = checked

        color: Theme.surfaceContainer
        checkedColor: Theme.primaryColor
        contentColor: Theme.onSurfaceVariant
        checkedContentColor: Theme.onPrimary
        borderColor: Theme.outlineVariant
        borderWidth: 1
    }

    Rectangle {
        id: streakTrigger
        anchors.bottom: parent.bottom
        anchors.left: rainTrigger.right
        anchors.leftMargin: 10
        anchors.margins: 20
        width: rainTrigger.width
        height: rainTrigger.height
        radius: 12
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

    StreakCalendar {
        id: streakCalendar
    }

    MaterialShape {
        id: avatarShape
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 20
        width: 48
        height: 48

        shape: MaterialShape.Cookie7Sided
        animated: false
        color: Config.avatarPath === "" ? Theme.primaryContainerColor : "transparent"
        source: Config.avatarPath
        fillMode: MaterialShape.Crop

        glyph: Config.avatarPath === "" && Config.username.length > 0 ? Config.username.charAt(0).toUpperCase() : ""
        glyphColor: Theme.onPrimaryContainer
        glyphFont.family: Config.currentFont
        glyphFont.bold: true
        glyphSize: width * 0.45

        border.width: avatarArea.containsMouse ? 3 : 2
        border.color: avatarArea.containsMouse ? Theme.primaryColor : Theme.outlineVariant

        Behavior on border.width {
            NumberAnimation {
                duration: 150
            }
        }

        MouseArea {
            id: avatarArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (avatarMenu.open) {
                    avatarMenu.close();
                    return;
                }
                avatarMenu.popup(avatarShape.x + avatarShape.width - avatarMenu.width, avatarShape.y - avatarMenu.height - 8);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 1
        visible: avatarMenu.open
        onClicked: avatarMenu.close()
    }

    MaterialMenu {
        id: avatarMenu
        z: 2
        minimumWidth: 160
        model: ["account settings", "user stats"]

        color: Theme.surfaceContainer
        textColor: Theme.onSurface
        separatorColor: Theme.outlineVariant
        borderWidth: 1
        borderColor: Theme.outlineVariant
        font.family: Config.currentFont

        onTriggered: index => {
            if (index === 0)
                root.appWindow.showAccountSettings = true;
            else if (index === 1)
                root.appWindow.showUserStats = true;
        }
        onClosed: root.appWindow.restoreInputFocus()
    }
}
