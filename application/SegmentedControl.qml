pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Rectangle {
    id: root

    property var options: []
    property var selectedValue: null
    property string suffix: ""
    property int cellWidth: 60
    property int cellHeight: 48
    property int cellSpacing: 6

    signal selected(var value)

    width: inner.width + 10
    height: inner.height + 10
    radius: 20
    color: Theme.surfaceContainer
    border.color: Theme.outlineVariant
    border.width: 1

    Item {
        id: inner
        anchors.centerIn: parent
        width: row.width
        height: row.height

        property int selectedIndex: {
            const i = root.options.indexOf(root.selectedValue);
            return i >= 0 ? i : 0;
        }

        ShapeCanvas {
            id: selectionShape
            width: root.cellHeight
            height: root.cellHeight
            color: Theme.primaryColor
            roundedPolygon: GetMShapes.get(22)
            x: inner.selectedIndex * (root.cellWidth + root.cellSpacing) + (root.cellWidth - width) / 2
            y: 0
            z: 0

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutBack
                }
            }
        }

        Row {
            id: row
            spacing: root.cellSpacing
            z: 1

            Repeater {
                model: root.options

                delegate: Item {
                    id: cell
                    required property int index
                    required property var modelData
                    width: root.cellWidth
                    height: root.cellHeight

                    property bool isSelected: inner.selectedIndex === cell.index

                    Text {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: cell.modelData.toString() + root.suffix
                        font.pixelSize: 13
                        font.bold: cell.isSelected
                        color: cell.isSelected ? Theme.onPrimary : (cellArea.containsMouse ? Theme.onSurface : Theme.onSurfaceVariant)

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    MouseArea {
                        id: cellArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selected(cell.modelData)
                    }
                }
            }
        }
    }
}
