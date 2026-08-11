pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    anchors.fill: parent
    z: 250

    property bool open: false
    readonly property real menuWidth: 200
    readonly property real menuHeight: 160
    required property var appWindow

    readonly property alias menuX: contextMenu.x
    readonly property alias menuY: contextMenu.y
    readonly property alias menuW: contextMenu.width
    readonly property alias menuH: contextMenu.height

    property real originX: 0
    property real originY: 0

    function openFrom(x, y) {
        root.originX = x;
        root.originY = y;
        contextMenu.x = Math.min(x, root.width - root.menuWidth - 10);
        contextMenu.y = Math.min(y, root.height - root.menuHeight - 10);
        root.open = true;
    }
    function close() {
        root.open = false;
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => root.openFrom(eventPoint.position.x, eventPoint.position.y)
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        enabled: root.open
        onTapped: root.close()
    }

    Rectangle {
        id: contextMenu
        width: root.menuWidth
        height: root.menuHeight
        radius: 14
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        clip: true

        visible: root.open

        Text {
            anchors.centerIn: parent
            text: "test"
            color: Theme.onSurface
            font.pixelSize: 13
        }
    }
}
