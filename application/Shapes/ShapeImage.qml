import QtQuick
import QtQuick.Effects

Item {
    id: root
    property alias source: img.source
    property color color: "transparent"

    Image {
        id: img
        anchors.fill: parent
        sourceSize.width: root.width * 2
        sourceSize.height: root.height * 2
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        colorization: 1.0
        colorizationColor: root.color
    }
}
