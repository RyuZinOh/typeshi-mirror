pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    property int size: 250
    property string username: Config.username
    property string avatarPath: Config.avatarPath
    property int shapeIndex: 18

    implicitWidth: root.size
    implicitHeight: root.size

    readonly property color generatedColor: {
        let hash = 0;
        for (let i = 0; i < root.username.length; i++) {
            hash = root.username.charCodeAt(i) + ((hash << 5) - hash);
        }
        const hue = Math.abs(hash) % 360;
        return Qt.hsla(hue / 360, 0.55, 0.45, 1);
    }

    ShapeCanvas {
        id: shape
        anchors.fill: parent
        roundedPolygon: GetMShapes.get(root.shapeIndex)
        borderColor: hoverArea.containsMouse ? Theme.primaryColor : Theme.outlineVariant
        borderWidth: 2
        color: root.generatedColor
        imageSource: {
            if (root.avatarPath === "") {
                return "";
            }
            const p = root.avatarPath.toString();
            return p.startsWith("file://") ? p : "file://" + p;
        }

        Behavior on borderColor {
            ColorAnimation {
                duration: 150
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.avatarPath === ""
        text: root.username.length > 0 ? root.username.charAt(0).toUpperCase() : "?"
        font.pixelSize: root.size * 0.45
        font.bold: true
        color: "white"
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
