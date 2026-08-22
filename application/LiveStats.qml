pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Row {
    id: root
    spacing: 28

    readonly property int valueSize: Math.max(16, Config.fontSize - 14)
    readonly property int labelSize: Math.max(10, Config.fontSize - 24)

    opacity: TypingEngine.started ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity {
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
            text: TypingEngine.wpm.toFixed(0)
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
            text: TypingEngine.rawWpm.toFixed(0)
            font.pixelSize: root.valueSize
            font.bold: true
            color: Theme.onSurface
        }
    }

    Column {
        spacing: 0
        Text {
            text: "accuracy"
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
        }
        Text {
            text: TypingEngine.accuracy.toFixed(0) + "%"
            font.pixelSize: root.valueSize
            font.bold: true
            color: Theme.onSurface
        }
    }

    Column {
        spacing: 0
        Text {
            text: "consistency"
            font.pixelSize: root.labelSize
            color: Theme.onSurfaceVariant
        }
        Text {
            text: TypingEngine.consistency.toFixed(0) + "%"
            font.pixelSize: root.valueSize
            font.bold: true
            color: Theme.onSurface
        }
    }
}
