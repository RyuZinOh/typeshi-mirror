pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: aftermath
    anchors.fill: parent

    readonly property int sidePadding: 160
    property string resultMode: "english"
    property int resultDuration: 0
    property bool resultPunctuation: false
    readonly property bool isNewBest: TypingEngine.wpm > 0 && TypingEngine.wpm >= (aftermath.resultMode === "words" ? History.bestWpmForWords(aftermath.resultDuration, aftermath.resultPunctuation ? 1 : 0) : History.bestWpmFor(aftermath.resultMode, aftermath.resultDuration, aftermath.resultPunctuation ? 1 : 0))

    signal restartRequested

    Component.onCompleted: Qt.callLater(function () {
        restartButtonRef.forceActiveFocus();
    })

    readonly property string modeLabel: {
        if (aftermath.resultMode === "quote") {
            return "quote";
        }
        if (aftermath.resultMode === "words") {
            let label = "english " + aftermath.resultDuration + " words";
            if (aftermath.resultPunctuation) {
                label += " - punctuation";
            }
            return label;
        }
        let label = "english " + aftermath.resultDuration + "s";
        if (aftermath.resultPunctuation) {
            label += " - punctuation";
        }
        return label;
    }

    property int reviewLength: {
        const minLen = Math.min(TypingEngine.typedText.length, TypingEngine.targetText.length);
        const words = TypingEngine.wordBoundaries;
        let cutoff = 0;
        for (let i = 0; i < words.length; i++) {
            if (words[i].end <= minLen) {
                cutoff = words[i].end;
            } else {
                break;
            }
        }
        return cutoff;
    }

    property var reviewWords: {
        const words = TypingEngine.wordBoundaries;
        const result = [];
        for (let i = 0; i < words.length; i++) {
            if (words[i].end <= aftermath.reviewLength) {
                result.push(words[i]);
            } else {
                break;
            }
        }
        return result;
    }

    function formatTime(ms) {
        const totalSeconds = Math.floor(ms / 1000);
        const mm = Math.floor(totalSeconds / 60);
        const ss = totalSeconds % 60;
        return (mm < 10 ? "0" : "") + mm + ":" + (ss < 10 ? "0" : "") + ss;
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: aftermath.sidePadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 32

        Row {
            width: parent.width
            spacing: 60

            Column {
                width: 220
                spacing: 20

                Column {
                    spacing: 0

                    Row {
                        spacing: 6

                        Text {
                            text: "wpm"
                            font.pixelSize: 16
                            color: Theme.onSurfaceVariant
                        }

                        Icon {
                            visible: aftermath.isNewBest
                            source: "assets/icons/crown.svg"
                            iconSize: 16
                            color: Theme.primaryColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: TypingEngine.wpm.toFixed(1)
                        font.pixelSize: 64
                        font.bold: true
                        color: Theme.primaryColor
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
                        font.pixelSize: 64
                        font.bold: true
                        color: Theme.primaryColor
                    }

                    Text {
                        text: aftermath.modeLabel
                        font.pixelSize: 13
                        color: Theme.onSurfaceVariant
                        topPadding: 4
                    }
                }
            }

            Column {
                id: graphColumn
                width: parent.width - 220 - 60
                spacing: 12

                PerformanceGraph {
                    width: parent.width
                    height: 200
                    history: TypingEngine.wpmHistory
                    totalSeconds: TypingEngine.testDurationSeconds
                }

                Item {
                    width: parent.width
                    height: 44

                    Column {
                        anchors.left: parent.left
                        spacing: 4

                        Text {
                            text: "raw wpm"
                            font.pixelSize: 13
                            color: Theme.onSurfaceVariant
                        }

                        Text {
                            text: TypingEngine.rawWpm.toFixed(1)
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.primaryColor
                        }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: -parent.width * 0.12
                        spacing: 4

                        Text {
                            text: "characters"
                            font.pixelSize: 13
                            color: Theme.onSurfaceVariant
                        }

                        Text {
                            text: TypingEngine.correctCount + "/" + TypingEngine.incorrectCount + "/" + TypingEngine.extraCount + "/" + TypingEngine.missedCount
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.primaryColor
                        }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.horizontalCenterOffset: parent.width * 0.12
                        spacing: 4

                        Text {
                            text: "consistency"
                            font.pixelSize: 13
                            color: Theme.onSurfaceVariant
                        }

                        Text {
                            text: TypingEngine.consistency.toFixed(1) + "%"
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.primaryColor
                        }
                    }

                    Column {
                        anchors.right: parent.right
                        spacing: 4

                        Text {
                            text: "time"
                            font.pixelSize: 13
                            color: Theme.onSurfaceVariant
                        }

                        Text {
                            text: aftermath.formatTime(TypingEngine.elapsedMs)
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.primaryColor
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 12

            Text {
                text: "input history"
                font.pixelSize: 20
                font.bold: true
                color: Theme.onSurface
            }

            Flow {
                id: reviewFlow
                width: parent.width
                spacing: 6

                Repeater {
                    model: aftermath.reviewWords

                    delegate: Row {
                        id: wordRow
                        required property var modelData

                        Repeater {
                            model: wordRow.modelData.end - wordRow.modelData.start

                            delegate: Text {
                                id: reviewChar
                                required property int index

                                property int globalIndex: wordRow.modelData.start + reviewChar.index
                                property bool wasError: TypingEngine.wasErrorAt(reviewChar.globalIndex)
                                property string targetCh: TypingEngine.targetText.charAt(reviewChar.globalIndex)
                                property string mistypeCh: TypingEngine.originalMistypeAt(reviewChar.globalIndex)
                                property string displayCh: reviewChar.wasError && reviewChar.mistypeCh !== "" ? reviewChar.mistypeCh : reviewChar.targetCh

                                text: reviewChar.displayCh === " " ? "\u00A0" : reviewChar.displayCh
                                font.pixelSize: 15
                                font.strikeout: reviewChar.wasError
                                color: reviewChar.wasError ? Theme.errorColor : Theme.onSurfaceVariant
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
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
    }
}
