pragma ComponentBehavior: Bound
import QtQuick

Row {
    id: root
    spacing: 28

    property bool instant: false
    readonly property int valueSize: Math.max(16, Config.fontSize - 14)
    readonly property int labelSize: Math.max(10, Config.fontSize - 24)
    readonly property int ringSize: valueSize * 2.6

    property real displayWpm: 0
    property real displayRawWpm: 0
    property real displayAccuracy: 0
    property real displayConsistency: 0

    Behavior on displayWpm {
        enabled: !root.instant
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on displayRawWpm {
        enabled: !root.instant
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on displayAccuracy {
        enabled: !root.instant
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on displayConsistency {
        enabled: !root.instant
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    function sampleStats() {
        root.displayWpm = TypingEngine.wpm;
        root.displayRawWpm = TypingEngine.rawWpm;
        root.displayAccuracy = TypingEngine.accuracy;
        root.displayConsistency = TypingEngine.consistency;
    }

    Timer {
        interval: 250
        running: TypingEngine.started && !TypingEngine.finished
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sampleStats()
    }

    Connections {
        target: TypingEngine
        function onTargetTextChanged() {
            if (!TypingEngine.started) {
                root.displayWpm = 0;
                root.displayRawWpm = 0;
                root.displayAccuracy = 0;
                root.displayConsistency = 0;
            }
        }
    }
    opacity: TypingEngine.started ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity {
        enabled: !root.instant
        NumberAnimation {
            duration: 150
        }
    }

    Column {
        spacing: 0
        Text {
            text: "wpm"
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
        }
        Text {
            text: Config.precisionModeEnabled ? root.displayWpm.toFixed(1) : root.displayWpm.toFixed(0)
            font.pixelSize: root.valueSize
            font.bold: true
            color: Theme.primaryColor
        }
    }

    Column {
        spacing: 0
        Text {
            text: "raw"
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
        }
        Text {
            text: Config.precisionModeEnabled ? root.displayRawWpm.toFixed(1) : root.displayRawWpm.toFixed(0)
            font.pixelSize: root.valueSize
            font.bold: true
            color: Theme.onSurface
        }
    }

    Column {
        spacing: 2
        Text {
            text: "accuracy"
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Item {
            width: root.ringSize
            height: root.ringSize
            anchors.horizontalCenter: parent.horizontalCenter

            CircularProgress {
                anchors.fill: parent
                trackWidth: 3
                value: root.displayAccuracy / 100
                progressColor: Theme.primaryColor
                animated: false
            }
            Text {
                anchors.centerIn: parent
                text: Config.precisionModeEnabled ? root.displayAccuracy.toFixed(1) : root.displayAccuracy.toFixed(0)
                font.pixelSize: root.valueSize * 0.65
                font.bold: true
                color: Theme.onSurface
            }
        }
    }

    Column {
        spacing: 2
        Text {
            text: "consistency"
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Item {
            width: root.ringSize
            height: root.ringSize
            anchors.horizontalCenter: parent.horizontalCenter

            CircularProgress {
                anchors.fill: parent
                trackWidth: 3
                value: root.displayConsistency / 100
                animated: false
                progressColor: Theme.onSurface
            }
            Text {
                anchors.centerIn: parent
                text: Config.precisionModeEnabled ? root.displayConsistency.toFixed(1) : root.displayConsistency.toFixed(0)
                font.pixelSize: root.valueSize * 0.65
                font.bold: true
                color: Theme.onSurface
            }
        }
    }
}
