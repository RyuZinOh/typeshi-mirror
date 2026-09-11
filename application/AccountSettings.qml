pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Dialogs
import QtCore

Item {
    id: root
    anchors.fill: parent

    signal backRequested

    property string pendingAvatarUrl: ""

    Keys.onEscapePressed: root.commitAndBack()
    focus: true

    Component.onCompleted: {
        nameField.text = Config.username;
        root.forceActiveFocus();
    }

    function commitAndBack() {
        const trimmed = nameField.text.trim ? nameField.text.trim() : nameField.text;
        if (trimmed.length > 0) {
            Config.setUsername(trimmed);
        }
        if (root.pendingAvatarUrl !== "") {
            Config.importAvatar(root.pendingAvatarUrl);
            root.pendingAvatarUrl = "";
        }
        root.backRequested();
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: 60
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 60
        spacing: 28

        Text {
            text: "account settings"
            font.pixelSize: 22
            font.bold: true
            color: Theme.onSurface
        }

        Row {
            spacing: 28

            Avatar {
                id: previewAvatar
                size: 96
                avatarPath: root.pendingAvatarUrl !== "" ? root.pendingAvatarUrl : Config.avatarPath

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: avatarDialogLoader.active = true
                }
            }

            Column {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "click avatar to change picture"
                    font.pixelSize: 12
                    color: Theme.onSurfaceVariant
                }

                Rectangle {
                    width: 260
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
                        Keys.onReturnPressed: root.commitAndBack()
                        Keys.onEnterPressed: root.commitAndBack()
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 28

            ToggleChip {
                anchors.left: parent.left
                label: "done"
                active: true
                onToggled: root.commitAndBack()
            }
        }
    }

    Loader {
        id: avatarDialogLoader
        active: false
        sourceComponent: FileDialog {
            title: "choose a profile picture"
            nameFilters: ["Images (*.png *.jpg *.jpeg *.webp)"]

            Component.onCompleted: {
                const pics = StandardPaths.writableLocation(StandardPaths.PicturesLocation);
                currentFolder = pics.toString() !== "" ? pics : StandardPaths.writableLocation(StandardPaths.HomeLocation);
                open();
            }

            onAccepted: {
                root.pendingAvatarUrl = selectedFile;
                avatarDialogLoader.active = false;
            }
            onRejected: {
                avatarDialogLoader.active = false;
            }
        }
    }
}
