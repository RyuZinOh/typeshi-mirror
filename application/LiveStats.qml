pragma ComponentBehavior: Bound
import QtQuick
import typeShitter
import Ryu.Extraa

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

    TextMetrics {
        id: valueMetrics
        font.family: Config.currentFont
        font.pixelSize: root.valueSize
        font.bold: true
        text: Config.precisionModeEnabled ? "888.8" : "888"
    }
    TextMetrics {
        id: wpmLabelMetrics
        font.family: Config.currentFont
        font.pixelSize: root.labelSize
        text: "wpm"
    }
    TextMetrics {
        id: rawLabelMetrics
        font.family: Config.currentFont
        font.pixelSize: root.labelSize
        text: "raw"
    }
    TextMetrics {
        id: accuracyLabelMetrics
        font.family: Config.currentFont
        font.pixelSize: root.labelSize
        text: "accuracy"
    }
    TextMetrics {
        id: consistencyLabelMetrics
        font.family: Config.currentFont
        font.pixelSize: root.labelSize
        text: "consistency"
    }

    readonly property real wpmCellWidth: Math.ceil(Math.max(valueMetrics.width, wpmLabelMetrics.width))
    readonly property real rawCellWidth: Math.ceil(Math.max(valueMetrics.width, rawLabelMetrics.width))
    readonly property real accuracyCellWidth: Math.ceil(Math.max(root.ringSize, accuracyLabelMetrics.width))
    readonly property real consistencyCellWidth: Math.ceil(Math.max(root.ringSize, consistencyLabelMetrics.width))

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

    function format(value) {
        return Config.precisionModeEnabled ? value.toFixed(1) : value.toFixed(0);
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
        width: root.wpmCellWidth
        spacing: 0
        Text {
            width: parent.width
            text: "wpm"
            font.family: Config.currentFont
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
        }
        Text {
            width: parent.width
            text: root.format(root.displayWpm)
            font.family: Config.currentFont
            font.pixelSize: root.valueSize
            font.bold: true
            color: Theme.primaryColor
        }
    }

    Column {
        width: root.rawCellWidth
        spacing: 0
        Text {
            width: parent.width
            text: "raw"
            font.family: Config.currentFont
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
        }
        Text {
            width: parent.width
            text: root.format(root.displayRawWpm)
            font.family: Config.currentFont
            font.pixelSize: root.valueSize
            font.bold: true
            color: Theme.onSurface
        }
    }

    Column {
        width: root.accuracyCellWidth
        spacing: 2
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "accuracy"
            font.family: Config.currentFont
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
        }
        Item {
            width: root.ringSize
            height: root.ringSize
            anchors.horizontalCenter: parent.horizontalCenter

            WavyProgress {
                anchors.fill: parent
                style: WavyProgress.Circular
                indeterminate: false
                progress: root.displayAccuracy / 100
                color: Theme.primaryColor
                trackColor: Theme.outlineVariant
                strokeWidth: 3
                amplitude: 1.5
                wavelength: 20
                waveSpeed: 0.5
                gap: 10
            }

            Text {
                anchors.centerIn: parent
                text: root.format(root.displayAccuracy)
                font.family: Config.currentFont
                font.pixelSize: root.valueSize * 0.65
                font.bold: true
                color: Theme.onSurface
            }
        }
    }

    Column {
        width: root.consistencyCellWidth
        spacing: 2
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "consistency"
            font.family: Config.currentFont
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
        }
        Item {
            width: root.ringSize
            height: root.ringSize
            anchors.horizontalCenter: parent.horizontalCenter

            WavyProgress {
                anchors.fill: parent
                style: WavyProgress.Circular
                indeterminate: false
                progress: root.displayConsistency / 100
                color: Theme.onSurface
                trackColor: Theme.outlineVariant
                strokeWidth: 3
                amplitude: 1.5
                wavelength: 20
                waveSpeed: 0.5
                gap: 10
            }

            Text {
                anchors.centerIn: parent
                text: root.format(root.displayConsistency)
                font.family: Config.currentFont
                font.pixelSize: root.valueSize * 0.65
                font.bold: true
                color: Theme.onSurface
            }
        }
    }
}
