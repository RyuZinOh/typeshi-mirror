pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    property bool rainEnabled: false
    default property alias content: contentItem.data

    Item {
        id: rainWrapper
        anchors.fill: parent

        layer.enabled: root.rainEnabled
        layer.smooth: true
        layer.effect: ShaderEffect {
            property variant source
            property vector2d resolution: Qt.vector2d(width, height)
            property real time: 0.0
            property real intensity: 0.4
            property real dropSize: 0.070
            property real speed: 0.6

            vertexShader: "assets/shaders/rain.vert.qsb"
            fragmentShader: "assets/shaders/rain.frag.qsb"

            NumberAnimation on time {
                running: root.rainEnabled
                loops: Animation.Infinite
                from: 0
                to: 10000
                duration: 10000000
            }
        }

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }
}
