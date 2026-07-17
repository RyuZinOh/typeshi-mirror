import QtQuick
import QtQuick.Effects

Item {
    id: root
    property alias source: iconImage.source
    property color color: "white"
    property int iconSize: 20
    implicitWidth: root.iconSize
    implicitHeight: root.iconSize
    Image {
        id: iconImage
        anchors.fill: parent
        sourceSize.width: root.iconSize * 2
        sourceSize.height: root.iconSize * 2
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: iconImage
        colorization: 1.0
        colorizationColor: root.color
    }
}
