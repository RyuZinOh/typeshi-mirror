pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    anchors.fill: parent
    z: 200

    readonly property real paddingSize: 10
    readonly property real cardWidth: 180
    readonly property real cardSpacing: 16
    readonly property real bubbleHeight: 180 + (root.paddingSize * 2)

    property bool isOpen: false

    visible: root.isOpen || bubble.opacity > 0.01

    function open() {
        root.isOpen = true;
        fontList.forceActiveFocus();
    }
    function close() {
        root.isOpen = false;
    }

    Keys.onEscapePressed: root.close()

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    readonly property real bubbleTargetHeight: root.isOpen ? root.bubbleHeight : 0
    readonly property real bubbleWidth: (root.cardWidth * 3) + (root.cardSpacing * 2) + (root.paddingSize * 2) + 32

    PopOutShape {
        id: bubble
        alignment: 1
        radius: 28
        color: Theme.surfaceContainer
        x: (root.width - width) / 2
        y: root.height - height
        width: root.bubbleWidth
        height: root.bubbleTargetHeight

        opacity: root.isOpen ? 1.0 : 0.0

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuint
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id: clipContainer
            anchors.fill: parent
            color: "transparent"
            anchors.margins: root.paddingSize
            radius: 24
            clip: true

            Item {
                id: contentRig
                width: parent.width
                height: root.bubbleHeight - (root.paddingSize * 2)
                anchors.bottom: parent.bottom

                Rectangle {
                    id: staticCenterTarget
                    width: root.cardWidth
                    height: parent.height
                    anchors.centerIn: parent
                    z: 1
                    radius: 20
                    color: "transparent"
                    border.color: Theme.primaryColor
                    border.width: 2
                }

                ListView {
                    id: fontList
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: root.cardSpacing
                    snapMode: ListView.SnapToItem
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: (width - root.cardWidth) / 2
                    preferredHighlightEnd: (width - root.cardWidth) / 2
                    model: Config.availableFonts()
                    z: 2

                    cacheBuffer: 360
                    reuseItems: true

                    delegate: Item {
                        id: fontCard
                        required property string modelData
                        required property int index

                        readonly property bool isCenterActive: fontList.currentIndex === fontCard.index

                        width: root.cardWidth
                        height: fontList.height

                        Item {
                            id: visualWrapper
                            anchors.fill: parent
                            scale: fontCard.isCenterActive ? 1.08 : 0.95

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                width: parent.width - 16

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Ts"
                                    font.family: fontCard.modelData
                                    font.pixelSize: 44
                                    color: fontCard.isCenterActive ? Theme.primaryColor : Theme.onSurface

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    text: fontCard.modelData
                                    elide: Text.ElideRight
                                    font.pixelSize: 14
                                    font.weight: fontCard.isCenterActive ? Font.Medium : Font.Normal
                                    color: fontCard.isCenterActive ? Theme.primaryColor : Theme.onSurfaceVariant

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: fontArea
                                anchors.fill: parent
                                hoverEnabled: fontCard.isCenterActive
                                acceptedButtons: fontCard.isCenterActive ? Qt.LeftButton : Qt.NoButton
                                cursorShape: fontCard.isCenterActive ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: Config.setFont(fontCard.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
