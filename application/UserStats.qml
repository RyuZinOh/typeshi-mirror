pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    anchors.fill: parent

    readonly property string wordList: "english"

    signal backRequested

    Keys.onEscapePressed: root.backRequested()
    focus: true

    Component.onCompleted: root.forceActiveFocus()

    Column {
        anchors.top: parent.top
        anchors.topMargin: 60
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 60
        spacing: 20

        Row {
            width: parent.width
            spacing: 20

            Rectangle {
                id: timedRect
                width: (parent.width - 20) / 2
                height: pbTimeRow.implicitHeight + 40
                radius: 16
                color: Theme.surfaceContainer
                border.color: Theme.outlineVariant
                border.width: 1

                Row {
                    id: pbTimeRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 20

                    Repeater {
                        model: [15, 30, 60, 120]
                        delegate: Column {
                            id: timeCell
                            required property int modelData
                            spacing: 4
                            width: parent.width / 4

                            readonly property double bestWpm: History.statsSummary["english_" + timeCell.modelData + "_0_" + root.wordList] || 0
                            readonly property double bestAcc: History.statsSummary["english_" + timeCell.modelData + "_0_" + root.wordList + "_acc"] || 0

                            Text {
                                text: timeCell.modelData + " seconds"
                                font.pixelSize: 12
                                color: Theme.onSurfaceVariant
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: timeCell.bestWpm.toFixed(0)
                                font.pixelSize: 36
                                font.bold: true
                                color: Theme.onSurface
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: timeCell.bestAcc.toFixed(0) + "%"
                                font.pixelSize: 13
                                color: Theme.onSurfaceVariant
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: wordsRect
                width: (parent.width - 20) / 2
                height: pbWordsRow.implicitHeight + 40
                radius: 16
                color: Theme.surfaceContainer
                border.color: Theme.outlineVariant
                border.width: 1

                Row {
                    id: pbWordsRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 20

                    Repeater {
                        model: [10, 25, 50, 100]
                        delegate: Column {
                            id: wordCell
                            required property int modelData
                            spacing: 4
                            width: parent.width / 4

                            readonly property double bestWpm: History.statsSummary["words_" + wordCell.modelData + "_0_" + root.wordList] || 0
                            readonly property double bestAcc: History.statsSummary["words_" + wordCell.modelData + "_0_" + root.wordList + "_acc"] || 0

                            Text {
                                text: wordCell.modelData + " words"
                                font.pixelSize: 12
                                color: Theme.onSurfaceVariant
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: wordCell.bestWpm.toFixed(0)
                                font.pixelSize: 36
                                font.bold: true
                                color: Theme.onSurface
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: wordCell.bestAcc.toFixed(0) + "%"
                                font.pixelSize: 13
                                color: Theme.onSurfaceVariant
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: summaryRect
            width: parent.width
            height: summaryRow.implicitHeight + 40
            radius: 16
            color: Theme.surfaceContainer
            border.color: Theme.outlineVariant
            border.width: 1

            Row {
                id: summaryRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 20

                Repeater {
                    model: [
                        {
                            label: "best wpm",
                            value: History.bestWpm.toFixed(1)
                        },
                        {
                            label: "tests today",
                            value: History.testsToday
                        },
                        {
                            label: "current streak",
                            value: History.currentStreak
                        },
                        {
                            label: "longest streak",
                            value: History.longestStreak
                        }
                    ]
                    delegate: Column {
                        id: summaryCell
                        required property var modelData
                        spacing: 4
                        width: parent.width / 4

                        Text {
                            text: summaryCell.modelData.label
                            font.pixelSize: 12
                            color: Theme.onSurfaceVariant
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: summaryCell.modelData.value
                            font.pixelSize: 30
                            font.bold: true
                            color: Theme.primaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }
}
