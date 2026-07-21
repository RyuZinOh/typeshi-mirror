pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import typeShitter
import QtCore

Item {
    id: root
    visible: false
    anchors.fill: parent
    z: 200

    function open() {
        root.visible = true;
        nameField.text = Config.username;
    }
    function close() {
        root.visible = false;
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrimColor
        opacity: root.visible ? 0.72 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 340
        height: contentCol.height + 48
        radius: 14
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1

        Column {
            id: contentCol
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 24
            width: parent.width - 48
            spacing: 18

            Avatar {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 88

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: avatarDialog.open()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "click avatar to change"
                font.pixelSize: 11
                color: Theme.onSurfaceVariant
            }

            Rectangle {
                width: parent.width
                height: 40
                radius: 10
                color: Theme.surfaceContainerHigh
                border.color: nameField.activeFocus ? Theme.primaryColor : Theme.outlineVariant
                border.width: 1

                TextInput {
                    id: nameField
                    anchors.fill: parent
                    anchors.margins: 10
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 15
                    color: Theme.onSurface
                    maximumLength: 24
                    onEditingFinished: Config.setUsername(nameField.text)
                }
            }

            ToggleChip {
                anchors.horizontalCenter: parent.horizontalCenter
                label: "done"
                active: true
                onToggled: {
                    Config.setUsername(nameField.text);
                    root.close();
                }
            }
        }
    }
    Keys.onEscapePressed: root.close()
    FileDialog {
        id: avatarDialog
        title: "choose a profile picture"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]
        currentFolder: {
            const pics = StandardPaths.writableLocation(StandardPaths.PicturesLocation);
            return pics.toString() !== "" ? pics : StandardPaths.writableLocation(StandardPaths.HomeLocation);
        }
        onAccepted: Config.importAvatar(avatarDialog.selectedFile)
    }
}
