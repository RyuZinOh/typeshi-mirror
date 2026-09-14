import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    component KeyCap: Rectangle {
        required property string keyLabel
        property real keyWidth: 40

        implicitWidth: keyWidth
        implicitHeight: 40
        border.width: 2
        border.color: Theme.outlineVariant
        radius: 10
        color: Theme.surfaceContainer

        Text {
            anchors.centerIn: parent
            text: parent.keyLabel
            font.family: Config.currentFont
            font.pixelSize: 15
            color: Theme.onSurfaceVariant
        }
    }
    ColumnLayout {
        id: layout
        spacing: 10
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter
            Repeater {
                model: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"]
                delegate: KeyCap {
                    required property string modelData
                    keyLabel: modelData
                }
            }
        }
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter
            Repeater {
                model: ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"]
                delegate: KeyCap {
                    required property string modelData
                    keyLabel: modelData
                }
            }
        }
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter
            Repeater {
                model: ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"]
                delegate: KeyCap {
                    required property string modelData
                    keyLabel: modelData
                }
            }
        }
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter
            KeyCap {
                keyLabel: "default"
                keyWidth: 270
            }
        }
    }
}
