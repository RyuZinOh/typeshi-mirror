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
    readonly property bool isNewBest: TypingEngine.wpm > 0 && TypingEngine.wpm >= History.bestWpmFor(aftermath.resultMode, aftermath.resultDuration, aftermath.resultPunctuation ? 1 : 0)

    signal restartRequested
    readonly property string modeLabel: {
        if (aftermath.resultMode === "quote") {
            return "quote";
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

                Item {
                    id: graphArea
                    width: parent.width
                    height: 200

                    property var history: TypingEngine.wpmHistory
                    property real maxVal: {
                        let m = 10;
                        for (let i = 0; i < graphArea.history.length; i++) {
                            m = Math.max(m, graphArea.history[i].wpm, graphArea.history[i].rawWpm);
                        }
                        return m * 1.15;
                    }
                    property int totalSeconds: TypingEngine.testDurationSeconds

                    Column {
                        id: legend
                        anchors.top: parent.top
                        anchors.right: parent.right
                        spacing: 6

                        Row {
                            spacing: 8
                            anchors.right: parent.right

                            Rectangle {
                                width: 14
                                height: 3
                                radius: 1.5
                                color: Theme.primaryColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "wpm"
                                color: Theme.onSurfaceVariant
                                font.pixelSize: 12
                            }
                        }

                        Row {
                            spacing: 8
                            anchors.right: parent.right

                            Rectangle {
                                width: 14
                                height: 3
                                radius: 1.5
                                color: Theme.onSurfaceVariant
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "raw wpm"
                                color: Theme.onSurfaceVariant
                                font.pixelSize: 12
                            }
                        }
                    }

                    Item {
                        id: plotArea
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.left: parent.left
                        anchors.leftMargin: 40
                        anchors.right: parent.right
                        anchors.bottom: xAxisLabels.top
                        anchors.bottomMargin: 6

                        Repeater {
                            model: 5

                            delegate: Text {
                                required property int index
                                text: Math.round((index / 4) * graphArea.maxVal).toString()
                                font.pixelSize: 11
                                color: Theme.onSurfaceVariant
                                x: -width - 8
                                y: plotArea.height - (index / 4) * plotArea.height - height / 2
                            }
                        }

                        Canvas {
                            id: graphCanvas
                            anchors.fill: parent

                            property color rawColor: Theme.onSurfaceVariant
                            property color wpmColor: Theme.primaryColor
                            property color gridColor: Theme.outlineVariant

                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                const hist = graphArea.history;
                                ctx.strokeStyle = graphCanvas.gridColor;
                                ctx.lineWidth = 1;
                                ctx.globalAlpha = 0.35;
                                for (let g = 0; g <= 4; g++) {
                                    const gy = height - (g / 4) * height;
                                    ctx.beginPath();
                                    ctx.moveTo(0, gy);
                                    ctx.lineTo(width, gy);
                                    ctx.stroke();
                                }
                                ctx.globalAlpha = 1.0;

                                if (hist.length < 2) {
                                    return;
                                }

                                const maxTime = Math.max(graphArea.totalSeconds, hist[hist.length - 1].time);
                                const maxVal = graphArea.maxVal;

                                function drawLine(key, color) {
                                    ctx.beginPath();
                                    ctx.strokeStyle = color;
                                    ctx.lineWidth = 2;
                                    for (let i = 0; i < hist.length; i++) {
                                        const px = (hist[i].time / maxTime) * width;
                                        const py = height - (hist[i][key] / maxVal) * height;
                                        if (i === 0) {
                                            ctx.moveTo(px, py);
                                        } else {
                                            ctx.lineTo(px, py);
                                        }
                                    }
                                    ctx.stroke();

                                    for (let i = 0; i < hist.length; i++) {
                                        const px = (hist[i].time / maxTime) * width;
                                        const py = height - (hist[i][key] / maxVal) * height;
                                        ctx.beginPath();
                                        ctx.fillStyle = color;
                                        ctx.arc(px, py, 3, 0, Math.PI * 2);
                                        ctx.fill();
                                    }
                                }

                                drawLine("rawWpm", graphCanvas.rawColor);
                                drawLine("wpm", graphCanvas.wpmColor);
                            }

                            Connections {
                                target: graphArea
                                function onHistoryChanged() {
                                    graphCanvas.requestPaint();
                                }
                            }
                        }
                    }

                    Row {
                        id: xAxisLabels
                        anchors.bottom: parent.bottom
                        anchors.left: plotArea.left
                        anchors.right: plotArea.right
                        height: 16

                        Repeater {
                            model: 5

                            delegate: Text {
                                required property int index
                                property int totalSeconds: graphArea.totalSeconds
                                text: Math.round((index / 4) * totalSeconds).toString()
                                font.pixelSize: 11
                                color: Theme.onSurfaceVariant
                                width: xAxisLabels.width / 5
                                horizontalAlignment: index === 0 ? Text.AlignLeft : (index === 4 ? Text.AlignRight : Text.AlignHCenter)
                            }
                        }
                    }
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

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                source: "assets/icons/refresh.svg"
                iconSize: 26
                color: restartArea.containsMouse ? Theme.primaryColor : Theme.onSurfaceVariant

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            MouseArea {
                id: restartArea
                anchors.centerIn: parent
                width: 28
                height: 28
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: aftermath.restartRequested()
            }
        }
    }
}
