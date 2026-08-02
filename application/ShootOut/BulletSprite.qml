import QtQuick

Image {
    id: root
    required property var modelData

    x: root.modelData.x - width / 2
    y: root.modelData.y - height / 2
    width: 16
    height: 20
    source: "../assets/ships/player/charger bullet.png"
    fillMode: Image.PreserveAspectFit
}
