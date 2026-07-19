pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root

    property var history: []
    property int totalSeconds: 0

    width: 400
    height: 200

    property real maxVal: {
        let m = 10;
        for (let i = 0; i < root.history.length; i++) {
            m = Math.max(m, root.history[i].wpm, root.history[i].rawWpm);
        }
        return m * 1.15;
    }

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
                text: Math.round((index / 4) * root.maxVal).toString()
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

                const hist = root.history;
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

                const maxTime = Math.max(root.totalSeconds, hist[hist.length - 1].time);
                const maxVal = root.maxVal;

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
                target: root
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
                property int totalSeconds: root.totalSeconds
                text: Math.round((index / 4) * totalSeconds).toString()
                font.pixelSize: 11
                color: Theme.onSurfaceVariant
                width: xAxisLabels.width / 5
                horizontalAlignment: index === 0 ? Text.AlignLeft : (index === 4 ? Text.AlignRight : Text.AlignHCenter)
            }
        }
    }
}
