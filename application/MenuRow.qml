pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root
    property string label: ""
    property alias containsMouse: mouse.containsMouse
    signal clicked

    width: parent.width
    height: 34
    color: mouse.containsMouse ? Theme.surfaceBright : "transparent"
    radius: 6

    Text {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: Text.AlignVCenter
        text: root.label
        font.pixelSize: 14
        color: mouse.containsMouse ? Theme.primaryColor : Theme.onSurface
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
