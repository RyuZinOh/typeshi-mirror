pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    anchors.fill: parent
    z: 250

    property real progress: 0
    property color traceColor: Theme.primaryColor
    property real lineWidth: 4

    visible: root.progress > 0.001 && root.progress < 1.0

    Behavior on progress {
        NumberAnimation {
            duration: 150
            easing.type: Easing.Linear
        }
    }

    onProgressChanged: canvas.requestPaint()
    onTraceColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (root.progress <= 0) {
                return;
            }

            const w = width;
            const h = height;
            const lw = root.lineWidth;
            const inset = lw / 2;
            const rightH = h - inset * 2;
            const bottomW = w - inset * 2;
            const leftH = h - inset * 2;
            const topW = w - inset * 2;
            const perimeter = rightH + bottomW + leftH + topW;

            const target = Math.max(0, Math.min(1, root.progress)) * perimeter;

            ctx.strokeStyle = root.traceColor;
            ctx.lineWidth = lw;
            ctx.lineCap = "round";
            ctx.beginPath();

            let remaining = target;
            let x = w - inset;
            let y = inset;
            ctx.moveTo(x, y);

            if (remaining > 0) {
                const seg = Math.min(remaining, rightH);
                y += seg;
                ctx.lineTo(x, y);
                remaining -= seg;
            }
            if (remaining > 0) {
                const seg = Math.min(remaining, bottomW);
                x -= seg;
                ctx.lineTo(x, y);
                remaining -= seg;
            }
            if (remaining > 0) {
                const seg = Math.min(remaining, leftH);
                y -= seg;
                ctx.lineTo(x, y);
                remaining -= seg;
            }
            if (remaining > 0) {
                const seg = Math.min(remaining, topW);
                x += seg;
                ctx.lineTo(x, y);
                remaining -= seg;
            }

            ctx.stroke();
        }
    }
}
