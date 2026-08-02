import QtQuick

Rectangle {
    id: root
    radius: 1
    antialiasing: true
    property real vx: 0
    property real vy: 0
    property real va: 0

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            root.x += root.vx * 0.016;
            root.y += root.vy * 0.016;
            root.vy += 900 * 0.016;
            root.rotation += root.va * 0.016;
            root.opacity -= 0.025;
            if (root.opacity <= 0 || root.y > root.parent.height + 60) {
                root.destroy();
                stop();
            }
        }
    }
}
