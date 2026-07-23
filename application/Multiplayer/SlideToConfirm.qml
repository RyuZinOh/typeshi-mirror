pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    height: 48
    property string label: "slide to confirm"
    property string errorText: ""
    property bool pending: false

    signal confirmed

    readonly property var pendingShapeSequence: [0, 7, 12, 22, 8, 2, 1]

    readonly property real dragProgress: Math.max(0, Math.min(1, (handle.x - 4) / (track.width - handle.width - 4)))
    readonly property int dragShapeIndex: pendingShapeSequence[Math.floor(dragProgress * (pendingShapeSequence.length - 1))]

    function reset() {
        handle.x = 4;
        root.pending = false;
        root.errorText = "";
    }

    function showError(message) {
        root.errorText = message;
        root.pending = false;
        handle.x = 4;
        shakeAnim.restart();
        errorClearTimer.restart();
    }

    Timer {
        id: errorClearTimer
        interval: 2200
        onTriggered: root.errorText = ""
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation {
            target: track
            property: "x"
            to: -8
            duration: 45
        }
        NumberAnimation {
            target: track
            property: "x"
            to: 8
            duration: 90
        }
        NumberAnimation {
            target: track
            property: "x"
            to: -6
            duration: 90
        }
        NumberAnimation {
            target: track
            property: "x"
            to: 4
            duration: 70
        }
        NumberAnimation {
            target: track
            property: "x"
            to: 0
            duration: 60
        }
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.errorText !== "" ? Qt.tint(Theme.surfaceContainer, Qt.rgba(1, 0, 0, 0.08)) : Theme.surfaceContainer
        border.color: root.errorText !== "" ? Theme.errorColor : Theme.outlineVariant
        border.width: 1
        opacity: root.enabled ? 1 : 0.4

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.errorText !== "" ? root.errorText : (root.pending ? "connecting..." : root.label)
            font.pixelSize: 13
            color: root.errorText !== "" ? Theme.errorColor : Theme.onSurfaceVariant
            opacity: (root.errorText !== "" || root.pending) ? 1 : (1 - (handle.x / (track.width - handle.width)))

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }

    Item {
        id: handle
        x: 4
        y: 4
        width: root.height - 8
        height: root.height - 8

        readonly property int idleShapeIndex: 0

        ShapeCanvas {
            id: handleShape
            anchors.fill: parent
            color: root.errorText !== "" ? Theme.errorColor : (root.pending ? Theme.secondaryColor : Theme.primaryColor)
            roundedPolygon: handleArea.pressed ? GetMShapes.get(root.dragShapeIndex) : GetMShapes.get(handle.idleShapeIndex)

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        SequentialAnimation on opacity {
            running: root.pending
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.45
                duration: 500
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 1.0
                duration: 500
                easing.type: Easing.InOutSine
            }
        }

        Behavior on x {
            enabled: !handleArea.pressed
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            id: handleArea
            anchors.fill: parent
            enabled: root.enabled && !root.pending
            drag.target: handle
            drag.axis: Drag.XAxis
            drag.minimumX: 4
            drag.maximumX: track.width - handle.width - 4

            onPressed: root.errorText = ""

            onReleased: {
                if (handle.x >= drag.maximumX - 6) {
                    root.confirmed();
                } else {
                    handle.x = 4;
                }
            }
        }
    }
}
