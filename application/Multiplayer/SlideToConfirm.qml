pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    height: 48
    property string label: "slide to confirm"
    property string errorText: ""

    signal confirmed

    function reset() {
        handle.x = 4;
    }

    function showError(message) {
        root.errorText = message;
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
        NumberAnimation { target: track; property: "x"; to: -8; duration: 45 }
        NumberAnimation { target: track; property: "x"; to: 8; duration: 90 }
        NumberAnimation { target: track; property: "x"; to: -6; duration: 90 }
        NumberAnimation { target: track; property: "x"; to: 4; duration: 70 }
        NumberAnimation { target: track; property: "x"; to: 0; duration: 60 }
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
            ColorAnimation { duration: 150 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        Text {
            anchors.centerIn: parent
            text: root.errorText !== "" ? root.errorText : root.label
            font.pixelSize: 13
            color: root.errorText !== "" ? Theme.errorColor : Theme.onSurfaceVariant
            opacity: root.errorText !== "" ? 1 : (1 - (handle.x / (track.width - handle.width)))

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }

    Rectangle {
        id: handle
        x: 4
        y: 4
        width: root.height - 8
        height: root.height - 8
        radius: height / 2
        color: root.errorText !== "" ? Theme.errorColor : Theme.primaryColor

        Behavior on color {
            ColorAnimation { duration: 150 }
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
            enabled: root.enabled
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
