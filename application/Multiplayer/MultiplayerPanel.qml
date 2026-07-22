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
    property bool opponentJoined: false
    property int countdownSecondsLeft: 0 

    function reset() {
        root.mode = "choice";
        root.errorText = "";
        root.opponentJoined = false;
        slideConfirm.reset();
    }

    Connections {
        target: Multiplayer
        function onRoomCodeChanged() {
            if (Multiplayer.roomCode !== "") {
                root.mode = "waiting";
            }
        }
        function onErrorReceived(message) {
            slideConfirm.showError(message);
        }
        function onPlayerJoined(username) {
            root.opponentJoined = true;
            root.readyToPlay();
        }
        function onJoinedRoom() {
            slideConfirm.pending = false;
            root.mode = "connected";
            root.readyToPlay();
        }
    }

    Column {
        id: contentColumn
        width: parent.width
        spacing: 20

        Column {
            visible: root.countdownSecondsLeft > 0
            spacing: 4
            width: parent.width

            Text {
                text: "race starting in"
                font.pixelSize: 14
                color: Theme.onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: root.countdownSecondsLeft
                font.pixelSize: 56
                font.bold: true
                color: Theme.primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Row {
            visible: root.mode === "choice" && root.countdownSecondsLeft === 0
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
            visible: root.mode === "joining" && root.countdownSecondsLeft === 0
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
                onConfirmed: {
                    slideConfirm.pending = true;
                    Multiplayer.join(codeInput.text, Config.username);
                }
            }
        }

        Column {
            visible: root.mode === "waiting" && root.countdownSecondsLeft === 0
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
                text: root.opponentJoined ? "opponent found, get ready..." : "waiting for opponent..."
                font.pixelSize: 13
                color: Theme.onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Column {
            visible: root.mode === "connected" && root.countdownSecondsLeft === 0
            spacing: 8
            width: parent.width

            Text {
                text: "connected! waiting for race to start..."
                font.pixelSize: 14
                color: Theme.onSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
