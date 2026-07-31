pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    anchors.fill: parent
    z: 200

    readonly property real paddingSize: 8
    readonly property real cardWidth: 120
    readonly property real cardHeight: 120
    readonly property real cardSpacing: 12

    readonly property real bubbleHeight: root.cardHeight + (root.paddingSize * 2)

    property bool isOpen: false

    visible: root.isOpen || bubble.opacity > 0.01

    function open() {
        root.isOpen = true;
        root.loadFonts();
        fontList.forceActiveFocus();
    }

    function close() {
        root.isOpen = false;
    }

    function loadFonts() {
        filteredModel.clear();
        const fonts = Config.availableFonts();
        for (let i = 0; i < fonts.length; i++) {
            filteredModel.append({
                fontName: fonts[i]
            });
        }
        if (filteredModel.count > 0) {
            fontList.currentIndex = 0;
            fontList.positionViewAtIndex(0, ListView.Center);
        }
    }

    Keys.onEscapePressed: root.close()

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    ListModel {
        id: filteredModel
    }

    readonly property real bubbleTargetHeight: root.isOpen ? root.bubbleHeight : 0
    readonly property real bubbleWidth: (root.cardWidth * 3) + (root.cardSpacing * 2) + (root.paddingSize * 2)

    PopOutShape {
        id: bubble
        alignment: 1
        radius: 16
        color: Theme.surfaceContainer
        x: (root.width - width) / 2
        y: root.height - height
        width: root.bubbleWidth
        height: root.bubbleTargetHeight

        borderColor: Theme.outlineVariant
        borderWidth: 1.5
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
            width: Math.max(0, parent.width - (root.paddingSize * 2))
            height: Math.max(0, parent.height - (root.paddingSize * 2))
            anchors.centerIn: parent
            color: "transparent"
            radius: 16
            clip: true

            Item {
                width: parent.width
                height: root.cardHeight
                anchors.verticalCenter: parent.verticalCenter
                opacity: root.isOpen ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Rectangle {
                    id: staticCenterTarget
                    width: root.cardWidth
                    height: parent.height
                    anchors.centerIn: parent
                    z: 1
                    radius: 16
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
                    model: filteredModel
                    z: 2
                    cacheBuffer: 360
                    reuseItems: true

                    MouseArea {
                        property real acc: 0
                        anchors.fill: parent
                        z: -1
                        acceptedButtons: Qt.NoButton
                        onWheel: wheel => {
                            if (wheel.pixelDelta.x === 0 && wheel.angleDelta.y === 0)
                                return;
                            acc -= (wheel.pixelDelta.x || wheel.angleDelta.y / 2);
                            if (Math.abs(acc) >= 30) {
                                acc > 0 ? fontList.incrementCurrentIndex() : fontList.decrementCurrentIndex();
                                acc = 0;
                            }
                            wheel.accepted = true;
                        }
                    }

                    delegate: Item {
                        id: fontCard
                        required property string fontName
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
                                spacing: 6
                                width: parent.width - 12

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Ts"
                                    font.family: fontCard.fontName
                                    font.pixelSize: 32
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
                                    text: fontCard.fontName
                                    elide: Text.ElideRight
                                    font.pixelSize: 12
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
                                onClicked: {
                                    Config.setFont(fontCard.fontName);
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
