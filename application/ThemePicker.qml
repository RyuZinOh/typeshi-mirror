pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    anchors.fill: parent
    visible: false
    z: 200

    function open() {
        root.visible = true;
    }
    function close() {
        root.visible = false;
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.visible ? 0.55 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: panel
        width: 460
        height: contentColumn.height + 48
        anchors.centerIn: parent
        radius: 16
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1

        scale: root.visible ? 1 : 0.94
        opacity: root.visible ? 1 : 0
        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: contentColumn
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 24
            width: panel.width - 48
            spacing: 20

            Row {
                width: parent.width
                Text {
                    text: "theme"
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                radius: 10
                color: Theme.surfaceContainerHigh
                border.color: Theme.outlineVariant
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Column {
                        width: parent.width - customCheck.width - 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: "use custom (matugen)"
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.onSurface
                        }
                        Text {
                            text: Config.currentTheme === "custom" ? "reading [theme] from your config.ini directly" : "add a [theme] section to ~/.config/typeShi/config.ini to use this"
                            font.pixelSize: 11
                            color: Theme.onSurfaceVariant
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleChip {
                        id: customCheck
                        label: Config.currentTheme === "custom" ? "on" : "off"
                        active: Config.currentTheme === "custom"
                        anchors.verticalCenter: parent.verticalCenter
                        onToggled: Config.setCustomTheme(Config.currentTheme !== "custom")
                    }
                }
            }

            Row {
                spacing: 12
                opacity: Config.currentTheme === "custom" ? 0.4 : 1
                enabled: Config.currentTheme !== "custom"
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    text: "variant"
                    font.pixelSize: 13
                    color: Theme.onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                ToggleChip {
                    label: "dark"
                    active: Config.currentVariant === "dark"
                    onToggled: Config.setTheme(Config.currentTheme, "dark")
                }
                ToggleChip {
                    label: "light"
                    active: Config.currentVariant === "light"
                    onToggled: Config.setTheme(Config.currentTheme, "light")
                }
            }

            Flow {
                width: parent.width
                spacing: 10
                opacity: Config.currentTheme === "custom" ? 0.4 : 1
                enabled: Config.currentTheme !== "custom"
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Repeater {
                    model: Config.availableThemes()

                    delegate: Rectangle {
                        id: swatch
                        required property string modelData
                        width: 96
                        height: 72
                        radius: 10
                        color: Theme.surfaceContainerHigh
                        border.width: Config.currentTheme === swatch.modelData ? 2 : 1
                        border.color: Config.currentTheme === swatch.modelData ? Theme.primaryColor : Theme.outlineVariant

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Row {
                                spacing: 4
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Theme.primaryColor
                                }
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Theme.secondaryColor
                                }
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: Theme.tertiaryColor
                                }
                            }

                            Text {
                                text: swatch.modelData.replace("_", " ")
                                font.pixelSize: 11
                                color: Theme.onSurfaceVariant
                                width: parent.width
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setTheme(swatch.modelData, Config.currentVariant)
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 8
            }
        }
    }
}
