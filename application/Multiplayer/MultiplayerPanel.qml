pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    width: 340
    height: contentColumn.height

    signal readyToPlay

    property string mode: "choice"
    property string errorText: ""

    Connections {
        target: Multiplayer
        function onRoomCodeChanged() {
            root.mode = "waiting";
        }
        function onErrorReceived(message) {
            slideConfirm.showError(message);
        }
        function onPlayerJoined(username) {
            root.readyToPlay();
        }
        function onJoinedRoom() {
            root.readyToPlay();
        }
    }

    Column {
        id: contentColumn
        width: parent.width
        spacing: 20

        Row {
            visible: root.mode === "choice"
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            ToggleChip {
                label: "create room"
                active: false
                chipHeight: 44
                onToggled: {
                    root.mode = "creating";
                    Multiplayer.create(Config.username);
                }
            }

            ToggleChip {
                label: "join room"
                active: false
                chipHeight: 44
                onToggled: {
                    root.mode = "joining";
                }
            }
        }

        Column {
            visible: root.mode === "joining"
            spacing: 14
            width: parent.width

            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: Theme.surfaceContainerHigh
                border.color: codeInput.activeFocus ? Theme.primaryColor : Theme.outlineVariant
                border.width: 1

                TextInput {
                    id: codeInput
                    anchors.fill: parent
                    anchors.margins: 10
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.onSurface
                    maximumLength: 4
                    validator: RegularExpressionValidator {
                        regularExpression: /[0-9]*/
                    }
                }
            }

            SlideToConfirm {
                id: slideConfirm
                width: parent.width
                label: "slide to join"
                enabled: codeInput.text.length === 4
                onConfirmed: Multiplayer.join(codeInput.text, Config.username)
            }
        }

        Column {
            visible: root.mode === "waiting"
            spacing: 8
            width: parent.width

            Text {
                text: "share this code:"
                font.pixelSize: 14
                color: Theme.onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: Multiplayer.roomCode
                font.pixelSize: 48
                font.bold: true
                color: Theme.primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "waiting for opponent..."
                font.pixelSize: 13
                color: Theme.onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
