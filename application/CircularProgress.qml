import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property real value: 0
    property real trackWidth: 6
    property color trackColor: Theme.outlineVariant
    property color progressColor: Theme.primaryContainerColor
    property int startAngle: -90
    property real gapDeg: 20

    readonly property real clampedValue: Math.max(0, Math.min(1, root.value))
    readonly property bool isFull: root.clampedValue >= 1
    readonly property bool isEmpty: root.clampedValue <= 0

    readonly property real radius: Math.min(width, height) / 2 - root.trackWidth / 2
    readonly property real cx: width / 2
    readonly property real cy: height / 2

    readonly property real progressStartDeg: root.isFull ? 0 : root.gapDeg
    readonly property real progressSweepDeg: {
        if (root.isFull)
            return 360;
        if (root.isEmpty)
            return 0;
        return Math.max(0, (360 - (root.gapDeg * 2)) * root.clampedValue);
    }

    readonly property real trackStartDeg: root.progressStartDeg + root.progressSweepDeg + (root.isFull || root.isEmpty ? 0 : root.gapDeg)
    readonly property real trackSweepDeg: {
        if (root.isFull)
            return 0;
        if (root.isEmpty)
            return 360;
        return Math.max(0, 360 - root.progressSweepDeg - (root.gapDeg * 2));
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: root.trackWidth
            strokeColor: root.trackColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.cx
                centerY: root.cy
                radiusX: root.radius
                radiusY: root.radius
                startAngle: root.startAngle + root.trackStartDeg
                sweepAngle: root.trackSweepDeg

                Behavior on startAngle {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on sweepAngle {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        ShapePath {
            strokeWidth: root.trackWidth
            strokeColor: root.progressColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.cx
                centerY: root.cy
                radiusX: root.radius
                radiusY: root.radius
                startAngle: root.startAngle + root.progressStartDeg
                sweepAngle: root.progressSweepDeg

                Behavior on sweepAngle {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
