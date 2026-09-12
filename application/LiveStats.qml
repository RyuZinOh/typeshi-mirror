pragma ComponentBehavior: Bound
import QtQuick

Row {
    id: root
    spacing: 28

    property bool instant: false
    readonly property int valueSize: Math.max(16, Config.fontSize - 14)
    readonly property int labelSize: Math.max(10, Config.fontSize - 24)
    readonly property int ringSize: valueSize * 2.6

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
            text: TypingEngine.wpm.toFixed(1)
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
            text: TypingEngine.rawWpm.toFixed(1)
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
                value: TypingEngine.accuracy / 100
                progressColor: Theme.primaryColor
            }
            Text {
                anchors.centerIn: parent
                text: TypingEngine.accuracy.toFixed(1)
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
                value: TypingEngine.consistency / 100
                progressColor: Theme.onSurface
            }
            Text {
                anchors.centerIn: parent
                text: TypingEngine.consistency.toFixed(1)
                font.pixelSize: root.valueSize * 0.65
                font.bold: true
                color: Theme.onSurface
            }
        }
    }
}
