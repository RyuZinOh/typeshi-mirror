pragma ComponentBehavior: Bound
import QtQuick
import typeShitter
import Ryu.Shapes

Item {
    id: root
    property int size: 250
    property string username: Config.username
    property string avatarPath: Config.avatarPath
    property int shapeIndex: MaterialShape.Cookie7Sided

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

    Item {
        id: shape
        anchors.top: parent.top
        anchors.right: parent.right
        width: root.size
        height: root.size

        MaterialShape {
            id: avatarShape
            anchors.fill: parent
            shape: root.shapeIndex
            animated: false
            color: root.avatarPath === "" ? root.generatedColor : "transparent"
            source: root.avatarPath
            fillMode: MaterialShape.Crop
            border.width: shapeArea.containsMouse ? 3 : 2
            border.color: shapeArea.containsMouse ? Theme.primaryColor : Theme.outlineVariant

            Behavior on border.width {
                NumberAnimation {
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
