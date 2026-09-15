pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var activeKeys: ({})
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    function keyDown(text) {
        if (!text) {
            return;
        }
        const updated = Object.assign({}, root.activeKeys);
        updated[text] = true;
        root.activeKeys = updated;
    }
    function keyUP(text) {
        if (!text) {
            return;
        }
        const updated = Object.assign({}, root.activeKeys);
        delete updated[text];
        root.activeKeys = updated;
    }

    component KeyCap: Rectangle {
        required property string keyLabel
        property string keyValue: keyLabel
        property real keyWidth: 40
        readonly property bool pressed: root.activeKeys[keyValue] === true

        implicitWidth: keyWidth
        implicitHeight: 40
        border.width: 2
        border.color: Theme.outlineVariant
        radius: 10
        color: pressed ? Theme.primaryColor : Theme.surfaceContainer
        Behavior on color {
            ColorAnimation {
                duration: 50
            }
        }

        Text {
            anchors.centerIn: parent
            text: parent.keyLabel
            font.family: Config.currentFont
            font.pixelSize: 15
            color: parent.pressed ? Theme.onPrimary : Theme.onSurfaceVariant
            Behavior on color {
                ColorAnimation {
                    duration: 50
                }
            }
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
                keyValue: " "
                keyWidth: 270
            }
        }
    }
}
