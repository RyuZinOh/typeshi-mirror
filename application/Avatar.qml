pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property int size: 250
    property string username: Config.username
    property string avatarPath: Config.avatarPath
    property int shapeIndex: 18

    property bool expanded: false
    property int squareShapeIndex: 1

    signal accountSettingsRequested
    signal userStatsRequested

    readonly property int labelHeight: 18
    readonly property int labelSpacing: 4
    readonly property int menuPadding: 16

    readonly property int expandedContentWidth: menuContent.contentWidth + root.menuPadding * 2
    readonly property int expandedContentHeight: menuContent.contentHeight + root.menuPadding * 2
    readonly property int expandedBoxSize: Math.max(root.size, expandedContentWidth, expandedContentHeight)

    readonly property real morphProgress: (shape.width - root.size) / Math.max(1, root.expandedBoxSize - root.size)

    implicitWidth: root.expanded ? root.expandedBoxSize : root.size
    implicitHeight: root.labelHeight + root.labelSpacing + (root.expanded ? root.expandedBoxSize : root.size)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    readonly property color generatedColor: {
        let hash = 0;
        for (let i = 0; i < root.username.length; i++) {
            hash = root.username.charCodeAt(i) + ((hash << 5) - hash);
        }
        return Qt.hsla(Math.abs(hash) % 360 / 360, 0.55, 0.45, 1);
    }

    Text {
        id: nameLabel
        anchors.top: parent.top
        anchors.right: parent.right
        height: root.labelHeight
        width: shape.width
        text: root.username
        font.pixelSize: 13
        color: Theme.onSurfaceVariant
        horizontalAlignment: root.expanded ? Text.AlignHCenter : Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }

    ShapeCanvas {
        id: shape
        anchors.top: nameLabel.bottom
        anchors.topMargin: root.labelSpacing
        anchors.right: parent.right
        width: root.expanded ? root.expandedBoxSize : root.size
        height: root.expanded ? root.expandedBoxSize : root.size
        clip: true

        Behavior on width {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }

        roundedPolygon: root.expanded ? GetMShapes.get(root.squareShapeIndex) : GetMShapes.get(root.shapeIndex)
        borderColor: shapeArea.containsMouse ? Theme.primaryColor : Theme.outlineVariant
        borderWidth: 2
        color: root.expanded ? Theme.surfaceContainer : root.generatedColor
        imageSource: (!root.expanded && root.avatarPath !== "") ? (root.avatarPath.startsWith("file://") ? root.avatarPath : "file://" + root.avatarPath) : ""

        Behavior on borderColor {
            ColorAnimation {
                duration: 150
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !root.expanded && root.avatarPath === ""
            text: root.username.length > 0 ? root.username.charAt(0).toUpperCase() : "?"
            font.pixelSize: root.size * 0.45
            font.bold: true
            color: "white"
        }

        Item {
            id: menuContent
            anchors.centerIn: parent

            readonly property int rowHeight: 38
            readonly property int rowSpacing: 4
            readonly property real rowWidth: Math.max(accountLabel.implicitWidth, statsLabel.implicitWidth) + 24
            readonly property real contentWidth: rowWidth
            readonly property real contentHeight: menuColumn.implicitHeight

            width: menuContent.rowWidth
            height: menuContent.contentHeight

            visible: opacity > 0.01
            opacity: root.expanded ? Math.max(0, Math.min(1, (root.morphProgress - 0.6) / 0.4)) : 0
            scale: 0.9 + 0.1 * opacity

            Rectangle {
                id: hoverHighlight
                width: menuContent.rowWidth
                height: menuContent.rowHeight
                radius: 8
                color: Theme.surfaceContainerHigh
                y: shapeArea.hoveredRow === 1 ? (menuContent.rowHeight + menuContent.rowSpacing) : 0
                opacity: shapeArea.hoveredRow >= 0 ? 1 : 0

                Behavior on y {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Column {
                id: menuColumn
                width: menuContent.rowWidth
                spacing: menuContent.rowSpacing

                Item {
                    id: accountRow
                    width: menuContent.rowWidth
                    height: menuContent.rowHeight

                    Text {
                        id: accountLabel
                        anchors.centerIn: parent
                        text: "account settings"
                        font.pixelSize: 14
                        color: shapeArea.hoveredRow === 0 ? Theme.primaryColor : Theme.onSurface
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                }

                Item {
                    id: statsRow
                    width: menuContent.rowWidth
                    height: menuContent.rowHeight

                    Text {
                        id: statsLabel
                        anchors.centerIn: parent
                        text: "user stats"
                        font.pixelSize: 14
                        color: shapeArea.hoveredRow === 1 ? Theme.primaryColor : Theme.onSurface
                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }
                }
            }
        }
        MouseArea {
            id: shapeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.expanded ? (shapeArea.hoveredRow >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor) : Qt.PointingHandCursor

            property int hoveredRow: -1

            onPositionChanged: mouse => {
                if (!root.expanded || menuContent.opacity < 0.5) {
                    shapeArea.hoveredRow = -1;
                    return;
                }

                let localMouse = shapeArea.mapToItem(menuContent, mouse.x, mouse.y);

                if (localMouse.x >= 0 && localMouse.x <= menuContent.width) {
                    if (localMouse.y >= 0 && localMouse.y <= 38) {
                        shapeArea.hoveredRow = 0;
                        return;
                    } else if (localMouse.y >= 42 && localMouse.y <= 80) {
                        shapeArea.hoveredRow = 1;
                        return;
                    }
                }
                shapeArea.hoveredRow = -1;
            }
            onExited: shapeArea.hoveredRow = -1

            onClicked: {
                if (!root.expanded) {
                    root.expanded = true;
                    return;
                }
                if (shapeArea.hoveredRow === 0) {
                    root.accountSettingsRequested();
                    root.expanded = false;
                } else if (shapeArea.hoveredRow === 1) {
                    root.userStatsRequested();
                    root.expanded = false;
                }
            }
        }
    }
}
