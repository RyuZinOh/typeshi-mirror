pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    property var history: []
    property int totalSeconds: 0
    property real revealProgress: 0

    width: 400
    height: 220

    Component.onCompleted: revealAnim.start()

    NumberAnimation {
        id: revealAnim
        target: root
        property: "revealProgress"
        from: 0
        to: 1
        duration: 900
        easing.type: Easing.OutCubic
    }
    onRevealProgressChanged: graphCanvas.requestPaint()

    property real maxVal: {
        let m = 10;
        for (let i = 0; i < root.history.length; i++) {
            m = Math.max(m, root.history[i].wpm, root.history[i].rawWpm);
        }
        return m * 1.15;
    }

    property real effectiveMaxTime: {
        if (root.history.length === 0) {
            return root.totalSeconds > 0 ? root.totalSeconds : 1;
        }
        const lastRecorded = root.history[root.history.length - 1].time;
        if (root.totalSeconds > 0 && lastRecorded <= root.totalSeconds) {
            return root.totalSeconds;
        }
        return lastRecorded;
    }

    property var plotHistory: {
        const hist = root.history;
        if (hist.length === 0 || hist[0].time === 0) {
            return hist;
        }
        const zeroPoint = {
            time: 0,
            wpm: 0,
            rawWpm: 0,
            hasError: false
        };
        const out = [zeroPoint];
        for (let i = 0; i < hist.length; i++) {
            out.push(hist[i]);
        }
        return out;
    }

    property int hoveredIndex: -1
    property bool hovering: root.hoveredIndex >= 0 && root.hoveredIndex < root.plotHistory.length
    property var hoveredPoint: root.hovering ? root.plotHistory[root.hoveredIndex] : null
    function nearestIndexForX(px) {
        const hist = root.plotHistory;
        if (hist.length === 0) {
            return -1;
        }
        const maxTime = root.effectiveMaxTime;
        const targetTime = (px / plotArea.width) * maxTime;

        let bestIdx = 0;
        let bestDist = Math.abs(hist[0].time - targetTime);
        for (let i = 1; i < hist.length; i++) {
            const d = Math.abs(hist[i].time - targetTime);
            if (d < bestDist) {
                bestDist = d;
                bestIdx = i;
            }
        }
        return bestIdx;
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
        anchors.topMargin: legend.height + 12
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.right: parent.right
        anchors.rightMargin: 10
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

            function smoothPath(ctx, points) {
                if (points.length < 2) {
                    return;
                }
                ctx.moveTo(points[0].x, points[0].y);
                if (points.length === 2) {
                    ctx.lineTo(points[1].x, points[1].y);
                    return;
                }
                for (let i = 0; i < points.length - 1; i++) {
                    const p0 = points[i === 0 ? 0 : i - 1];
                    const p1 = points[i];
                    const p2 = points[i + 1];
                    const p3 = points[i + 2 < points.length ? i + 2 : i + 1];

                    const c1x = p1.x + (p2.x - p0.x) / 6;
                    const c1y = p1.y + (p2.y - p0.y) / 6;
                    const c2x = p2.x - (p3.x - p1.x) / 6;
                    const c2y = p2.y - (p3.y - p1.y) / 6;

                    ctx.bezierCurveTo(c1x, c1y, c2x, c2y, p2.x, p2.y);
                }
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                const hist = root.plotHistory;
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

                const maxTime = root.effectiveMaxTime;
                const maxVal = root.maxVal;
                ctx.save();
                ctx.beginPath();
                ctx.rect(0, 0, width * root.revealProgress, height);
                ctx.clip();

                function drawLine(key, color) {
                    const points = [];
                    for (let i = 0; i < hist.length; i++) {
                        points.push({
                            x: (hist[i].time / maxTime) * width,
                            y: height - (hist[i][key] / maxVal) * height
                        });
                    }

                    ctx.beginPath();
                    ctx.strokeStyle = color;
                    ctx.lineWidth = 2;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";
                    graphCanvas.smoothPath(ctx, points);
                    ctx.stroke();

                    for (const p of points) {
                        ctx.beginPath();
                        ctx.fillStyle = color;
                        ctx.arc(p.x, p.y, 1.6, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }

                drawLine("rawWpm", graphCanvas.rawColor);
                drawLine("wpm", graphCanvas.wpmColor);
                ctx.restore();
            }

            Connections {
                target: root
                function onHistoryChanged() {
                    graphCanvas.requestPaint();
                }
            }
        }

        Item {
            id: errorStrip
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            height: 16

            Repeater {
                model: root.plotHistory

                delegate: Text {
                    required property var modelData

                    readonly property real markerFraction: modelData.time / root.effectiveMaxTime

                    visible: modelData.hasError === true && markerFraction <= root.revealProgress
                    text: "\uf467"
                    font.pixelSize: 13
                    color: Theme.errorColor
                    x: Math.max(0, Math.min(markerFraction * errorStrip.width - width / 2, errorStrip.width - width))
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            id: hoverLine
            width: 1
            height: parent.height
            color: Theme.outlineVariant
            opacity: root.hovering ? 0.6 : 0
            x: root.hoveredPoint !== null ? (root.hoveredPoint.time / root.effectiveMaxTime) * plotArea.width : x

            Behavior on x {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        Rectangle {
            id: hoverDotWpm
            width: 8
            height: 8
            radius: 4
            color: Theme.primaryColor
            border.color: Theme.surfaceContainer
            border.width: 2
            opacity: root.hovering ? 1 : 0
            x: hoverLine.x - width / 2
            y: root.hoveredPoint !== null ? plotArea.height - (root.hoveredPoint.wpm / root.maxVal) * plotArea.height - height / 2 : y

            Behavior on x {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        Rectangle {
            id: hoverDotRaw
            width: 8
            height: 8
            radius: 4
            color: Theme.onSurfaceVariant
            border.color: Theme.surfaceContainer
            border.width: 2
            opacity: root.hovering ? 1 : 0
            x: hoverLine.x - width / 2
            y: root.hoveredPoint !== null ? plotArea.height - (root.hoveredPoint.rawWpm / root.maxVal) * plotArea.height - height / 2 : y

            Behavior on x {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        Rectangle {
            id: hoverTooltip
            width: tooltipCol.implicitWidth + 20
            height: tooltipCol.implicitHeight + 14
            radius: 8
            color: Theme.surfaceContainerHighest
            border.color: Theme.outlineVariant
            border.width: 1
            opacity: root.hovering ? 1 : 0
            z: 10

            property real targetX: Math.max(0, Math.min(hoverLine.x - width / 2, plotArea.width - width))
            property real targetY: {
                const preferredY = Math.min(hoverDotWpm.y, hoverDotRaw.y) - height - 12;
                return preferredY >= 0 ? preferredY : Math.max(hoverDotWpm.y, hoverDotRaw.y) + 20;
            }

            x: targetX
            y: targetY

            Behavior on x {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Column {
                id: tooltipCol
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: root.hoveredPoint !== null ? root.hoveredPoint.time + "s" : ""
                    font.pixelSize: 10
                    color: Theme.onSurfaceVariant
                }
                Text {
                    text: root.hoveredPoint !== null ? "wpm " + root.hoveredPoint.wpm.toFixed(1) : ""
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.primaryColor
                }
                Text {
                    text: root.hoveredPoint !== null ? "raw " + root.hoveredPoint.rawWpm.toFixed(1) : ""
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.onSurfaceVariant
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.plotHistory.length > 1
            onPositionChanged: mouse => {
                root.hoveredIndex = root.nearestIndexForX(mouse.x);
            }
            onEntered: {
                root.hoveredIndex = root.nearestIndexForX(mouseX);
            }
            onExited: {
                root.hoveredIndex = -1;
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
                property real maxTime: root.effectiveMaxTime
                text: Math.round((index / 4) * maxTime).toString()
                font.pixelSize: 11
                color: Theme.onSurfaceVariant
                width: xAxisLabels.width / 5
                horizontalAlignment: index === 0 ? Text.AlignLeft : (index === 4 ? Text.AlignRight : Text.AlignHCenter)
            }
        }
    }
}
