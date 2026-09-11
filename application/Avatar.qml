pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property int size: 250
    property string username: Config.username
    property string avatarPath: Config.avatarPath
    property int shapeIndex: 18

    signal clicked

    readonly property int labelHeight: 18
    readonly property int labelSpacing: 4

    implicitWidth: root.size
    implicitHeight: root.size + root.labelSpacing + root.labelHeight

    readonly property color generatedColor: {
        let hash = 0;
        for (let i = 0; i < root.username.length; i++) {
            hash = root.username.charCodeAt(i) + ((hash << 5) - hash);
        }
        return Qt.hsla(Math.abs(hash) % 360 / 360, 0.55, 0.45, 1);
    }

    ShapeCanvas {
        id: shape
        anchors.top: parent.top
        anchors.right: parent.right
        width: root.size
        height: root.size
        clip: true

        roundedPolygon: GetMShapes.get(root.shapeIndex)
        borderColor: shapeArea.containsMouse ? Theme.primaryColor : Theme.outlineVariant
        borderWidth: 2
        color: root.generatedColor
        imageSource: root.avatarPath !== "" ? (root.avatarPath.startsWith("file://") ? root.avatarPath : "file://" + root.avatarPath) : ""

        Behavior on borderColor {
            ColorAnimation {
                duration: 150
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
            id: shapeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }

    Text {
        id: nameLabel
        anchors.top: shape.bottom
        anchors.topMargin: root.labelSpacing
        anchors.right: parent.right
        width: shape.width
        height: root.labelHeight
        text: root.username
        font.pixelSize: 13
        color: Theme.onSurfaceVariant
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
