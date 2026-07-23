pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: aftermath
    anchors.fill: parent

    readonly property int sidePadding: 160

    property string opponentUsername: "opponent"
    property double opponentWpm: 0
    property double opponentAccuracy: 0
    property double opponentConsistency: 0

    property bool isRoomCreator: false
    property bool rematchOfferPending: false
    property bool rematchRequestSent: false
    property string rematchDeclinedMessage: ""

    readonly property bool iWon: TypingEngine.wpm >= aftermath.opponentWpm

    signal restartRequested
    signal acceptRequested
    signal declineRequested

    Component.onCompleted: {
        Qt.callLater(function () {
            restartButtonRef.forceActiveFocus();
        });
        if (aftermath.iWon) {
            myConfetti.tryBurst();
        } else {
            opponentConfetti.tryBurst();
        }
    }

    Row {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: aftermath.sidePadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 60

        Item {
            id: myColumn
            width: (parent.width - contentRow.spacing) / 2
            height: myStats.height

            ConfettiRenderer {
                id: myConfetti
                anchors.fill: parent
                z: 100
                property bool hasBurst: false
                function tryBurst() {
                    if (myConfetti.hasBurst || myConfetti.width <= 0 || myConfetti.height <= 0) {
                        return;
                    }
                    myConfetti.hasBurst = true;
                    myConfetti.spawnBurst([Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor]);
                }
            }

            Column {
                id: myStats
                width: parent.width
                spacing: 20

                Row {
                    spacing: 8

                    Text {
                        text: Config.username
                        font.pixelSize: 20
                        font.bold: true
                        color: Theme.onSurface
                    }

                    Icon {
                        visible: aftermath.iWon
                        source: "assets/icons/crown.svg"
                        iconSize: 22
                        color: Theme.primaryColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    spacing: 0
                    Text {
                        text: "wpm"
                        font.pixelSize: 16
                        color: Theme.onSurfaceVariant
                    }
                    Text {
                        text: TypingEngine.wpm.toFixed(1)
                        font.pixelSize: 64
                        font.bold: true
                        color: aftermath.iWon ? Theme.primaryColor : Theme.onSurfaceVariant
                    }
                }

                Column {
                    spacing: 0
                    Text {
                        text: "accuracy"
                        font.pixelSize: 16
                        color: Theme.onSurfaceVariant
                    }
                    Text {
                        text: TypingEngine.accuracy.toFixed(1) + "%"
                        font.pixelSize: 40
                        font.bold: true
                        color: Theme.primaryColor
                    }
                }

                Row {
                    spacing: 40

                    Column {
                        spacing: 4
                        Text {
                            text: "raw wpm"
                            font.pixelSize: 13
                            color: Theme.onSurfaceVariant
                        }
                        Text {
                            text: TypingEngine.rawWpm.toFixed(1)
                            font.pixelSize: 20
                            font.bold: true
                            color: Theme.primaryColor
                        }
                    }

                    Column {
                        spacing: 4
                        Text {
                            text: "consistency"
                            font.pixelSize: 13
                            color: Theme.onSurfaceVariant
                        }
                        Text {
                            text: TypingEngine.consistency.toFixed(1) + "%"
                            font.pixelSize: 20
                            font.bold: true
                            color: Theme.primaryColor
                        }
                    }

                    Column {
                        spacing: 4
                        Text {
                            text: "characters"
                            font.pixelSize: 13
                            color: Theme.onSurfaceVariant
                        }
                        Text {
                            text: TypingEngine.correctCount + "/" + TypingEngine.incorrectCount + "/" + TypingEngine.extraCount + "/" + TypingEngine.missedCount
                            font.pixelSize: 20
                            font.bold: true
                            color: Theme.primaryColor
                        }
                    }
                }
            }
        }

        Rectangle {
            width: 1
            height: myStats.height
            color: Theme.outlineVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: opponentColumn
            width: (parent.width - contentRow.spacing) / 2
            height: myStats.height

            ConfettiRenderer {
                id: opponentConfetti
                anchors.fill: parent
                z: 100
                property bool hasBurst: false
                function tryBurst() {
                    if (opponentConfetti.hasBurst || opponentConfetti.width <= 0 || opponentConfetti.height <= 0) {
                        return;
                    }
                    opponentConfetti.hasBurst = true;
                    opponentConfetti.spawnBurst([Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor]);
                }
            }

            Column {
                width: parent.width
                spacing: 20

                Row {
                    spacing: 8

                    Text {
                        text: aftermath.opponentUsername
                        font.pixelSize: 20
                        font.bold: true
                        color: Theme.onSurface
                    }

                    Icon {
                        visible: !aftermath.iWon
                        source: "assets/icons/crown.svg"
                        iconSize: 22
                        color: Theme.secondaryColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    spacing: 0
                    Text {
                        text: "wpm"
                        font.pixelSize: 16
                        color: Theme.onSurfaceVariant
                    }
                    Text {
                        text: aftermath.opponentWpm.toFixed(1)
                        font.pixelSize: 64
                        font.bold: true
                        color: !aftermath.iWon ? Theme.secondaryColor : Theme.onSurfaceVariant
                    }
                }

                Column {
                    spacing: 0
                    Text {
                        text: "accuracy"
                        font.pixelSize: 16
                        color: Theme.onSurfaceVariant
                    }
                    Text {
                        text: aftermath.opponentAccuracy.toFixed(1) + "%"
                        font.pixelSize: 40
                        font.bold: true
                        color: Theme.secondaryColor
                    }
                }

                Column {
                    spacing: 4
                    Text {
                        text: "consistency"
                        font.pixelSize: 13
                        color: Theme.onSurfaceVariant
                    }
                    Text {
                        text: aftermath.opponentConsistency.toFixed(1) + "%"
                        font.pixelSize: 20
                        font.bold: true
                        color: Theme.secondaryColor
                    }
                }
            }
        }
    }

    Column {
        anchors.top: contentRow.bottom
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Text {
            visible: aftermath.rematchDeclinedMessage !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            text: aftermath.rematchDeclinedMessage
            font.pixelSize: 13
            color: Theme.errorColor
        }

        Item {
            visible: aftermath.isRoomCreator && !aftermath.rematchRequestSent
            anchors.horizontalCenter: parent.horizontalCenter
            width: 28
            height: 28

            RefreshButton {
                id: restartButtonRef
                anchors.centerIn: parent
                alwaysVisible: true
                hoverRotates: true
                iconSize: 26
                onActivated: aftermath.restartRequested()
            }
        }

        Text {
            visible: aftermath.isRoomCreator && aftermath.rematchRequestSent
            anchors.horizontalCenter: parent.horizontalCenter
            text: "waiting for opponent to accept rematch..."
            font.pixelSize: 13
            color: Theme.onSurfaceVariant
        }

        Text {
            visible: !aftermath.isRoomCreator && !aftermath.rematchOfferPending
            anchors.horizontalCenter: parent.horizontalCenter
            text: "waiting for " + aftermath.opponentUsername + " to request a rematch..."
            font.pixelSize: 13
            color: Theme.onSurfaceVariant
        }

        Row {
            visible: !aftermath.isRoomCreator && aftermath.rematchOfferPending
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            ToggleChip {
                label: "accept rematch"
                active: false
                chipHeight: 40
                onToggled: aftermath.acceptRequested()
            }
            ToggleChip {
                label: "decline"
                active: false
                chipHeight: 40
                onToggled: aftermath.declineRequested()
            }
        }
    }
}
