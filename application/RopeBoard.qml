pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    property bool active: false

    readonly property real boxX: hangBox.x
    readonly property real boxY: hangBox.y
    readonly property real boxWidth: hangBox.width
    readonly property real boxHeight: hangBox.height
    readonly property real boxRot: hangBox.rotation

    readonly property real restY: 64
    readonly property real hiddenY: -400

    Item {
        id: pinLeft
        x: hangBox.x + 22
        y: 0
        width: 8
        height: 8
        visible: false
    }
    Item {
        id: pinRight
        x: hangBox.x + hangBox.width - 22 - width
        y: 0
        width: 8
        height: 8
        visible: false
    }

    Canvas {
        id: ropes
        anchors.fill: parent
        z: 1

        property real boxX: hangBox.x
        property real boxY: hangBox.y
        property real boxRot: hangBox.rotation

        onBoxXChanged: requestPaint()
        onBoxYChanged: requestPaint()
        onBoxRotChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (hangBox.y < -hangBox.height) {
                return;
            }
            ctx.strokeStyle = Theme.outline;
            ctx.lineWidth = 2;
            ctx.globalAlpha = 0.75;

            const rad = ropes.boxRot * Math.PI / 180;
            const cx = hangBox.x + hangBox.width / 2;
            const cy = hangBox.y + hangBox.height / 2;

            function corner(dx, dy) {
                const rx = dx * Math.cos(rad) - dy * Math.sin(rad);
                const ry = dx * Math.sin(rad) + dy * Math.cos(rad);
                return {
                    x: cx + rx,
                    y: cy + ry
                };
            }

            const topLeft = corner(-hangBox.width / 2 + 22, -hangBox.height / 2);
            const topRight = corner(hangBox.width / 2 - 22, -hangBox.height / 2);

            function drawRope(anchorX, anchorY, targetX, targetY) {
                const sag = Math.max(0, targetY - anchorY) * 0.15;
                const midX = (anchorX + targetX) / 2;
                const midY = (anchorY + targetY) / 2 + sag;
                ctx.beginPath();
                ctx.moveTo(anchorX, anchorY);
                ctx.quadraticCurveTo(midX, midY, targetX, targetY);
                ctx.stroke();
            }

            drawRope(pinLeft.x + pinLeft.width / 2, 0, topLeft.x, topLeft.y);
            drawRope(pinRight.x + pinRight.width / 2, 0, topRight.x, topRight.y);
        }
    }

    Rectangle {
        id: hangBox
        width: 300
        height: variantRow.y + variantRow.height + 32
        x: parent.width / 2 - width / 2
        y: root.hiddenY
        radius: 14
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        z: 2
        transformOrigin: Item.Top

        state: root.active ? "dropped" : "hidden"

        states: [
            State {
                name: "hidden"
                PropertyChanges {
                    hangBox.y: root.hiddenY
                }
            },
            State {
                name: "dropped"
                PropertyChanges {
                    hangBox.y: root.restY
                }
            }
        ]

        transitions: [
            Transition {
                to: "dropped"
                SpringAnimation {
                    property: "y"
                    spring: 1.4
                    damping: 0.28
                    mass: 1.0
                }
            },
            Transition {
                to: "hidden"
                NumberAnimation {
                    property: "y"
                    duration: 160
                    easing.type: Easing.InQuad
                }
            }
        ]

        SequentialAnimation on rotation {
            running: root.active
            loops: Animation.Infinite
            NumberAnimation {
                to: 1.6
                duration: 2600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: -1.6
                duration: 2600
                easing.type: Easing.InOutSine
            }
        }

        Column {
            id: hangContent
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 18
            width: parent.width - 36
            spacing: 14

            Row {
                width: parent.width
                spacing: 12

                Column {
                    width: parent.width - customChip.width - 12
                    spacing: 2

                    Text {
                        text: "custom"
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.onSurface
                    }
                    Text {
                        text: Config.currentTheme === "custom" ? "reading from your config.ini" : "hand off theming to matugen"
                        font.pixelSize: 10
                        color: Theme.onSurfaceVariant
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }
                }

                ToggleChip {
                    id: customChip
                    label: Config.currentTheme === "custom" ? "on" : "off"
                    active: Config.currentTheme === "custom"
                    onToggled: Config.setCustomTheme(Config.currentTheme !== "custom")
                }
            }

            Row {
                id: variantRow
                spacing: 10
                opacity: Config.currentTheme === "custom" ? 0.35 : 1
                enabled: Config.currentTheme !== "custom"
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                ToggleChip {
                    label: "dark"
                    chipHeight: 36
                    active: Config.currentVariant === "dark"
                    onToggled: Config.setTheme(Config.currentTheme, "dark")
                }
                ToggleChip {
                    label: "light"
                    chipHeight: 36
                    active: Config.currentVariant === "light"
                    onToggled: Config.setTheme(Config.currentTheme, "light")
                }
            }
        }
    }
}
