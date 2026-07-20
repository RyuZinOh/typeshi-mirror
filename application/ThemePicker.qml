pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    anchors.fill: parent
    visible: false
    z: 200

    function open() {
        root.visible = true;
    }
    function close() {
        root.visible = false;
    }

    Keys.onEscapePressed: root.close()

    Rectangle {
        anchors.fill: parent
        color: Theme.scrimColor
        opacity: root.visible ? 0.72 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    RopeBoard {
        id: board
        anchors.fill: parent
        active: root.visible
    }

    PaletteField {
        id: palette
        anchors.fill: parent
        active: root.visible
        obstacleX: board.boxX
        obstacleY: board.boxY
        obstacleWidth: board.boxWidth
        obstacleHeight: board.boxHeight
    }
}
