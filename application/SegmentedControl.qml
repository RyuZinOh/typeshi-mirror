pragma ComponentBehavior: Bound
import QtQuick

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
    radius: 10
    color: Theme.surfaceContainer
    border.color: Theme.outlineVariant
    border.width: 1
    opacity: root.enabled ? 1 : 0.4

    Behavior on width {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    Item {
        id: inner
        anchors.centerIn: parent
        width: row.width
        height: row.height

        property int selectedIndex: {
            const i = root.options.indexOf(root.selectedValue);
            return i >= 0 ? i : 0;
        }

        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        ShapeImage {
            id: selectionShape
            width: root.cellHeight
            height: root.cellHeight
            color: Theme.primaryColor
            source: ShapeCatalog.get(21)
            x: inner.selectedIndex * (root.cellWidth + root.cellSpacing) + (root.cellWidth - width) / 2
            y: 0
            z: 0

            Behavior on x {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.4
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
                        scale: cell.isSelected ? 1.08 : 1.0
                        color: cell.isSelected ? Theme.onPrimary : (cellArea.containsMouse ? Theme.onSurface : Theme.onSurfaceVariant)

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutBack
                                easing.overshoot: 2.0
                            }
                        }
                    }

                    MouseArea {
                        id: cellArea
                        anchors.fill: parent
                        enabled: root.enabled
                        hoverEnabled: true
                        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.selected(cell.modelData)
                    }
                }
            }
        }
    }
}
