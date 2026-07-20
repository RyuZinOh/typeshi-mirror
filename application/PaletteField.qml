pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import typeShitter

Item {
    id: root
    property bool active: false

    property real obstacleX: 0
    property real obstacleY: 0
    property real obstacleWidth: 0
    property real obstacleHeight: 0

    readonly property bool visiblePalette: root.active && Config.currentTheme !== "custom"
    readonly property real pillHeight: 48

    opacity: root.visiblePalette ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 180
        }
    }

    property var themeNames: Config.availableThemes()
    property var bubbles: []
    property real lastTick: 0
    property int hoveredIndex: -1

    signal bubblesTicked

    function initBubbles() {
        const names = root.themeNames;
        const arr = [];
        for (let i = 0; i < names.length; i++) {
            const size = 150 + (i % 3) * 22;
            const speed = 40 + Math.random() * 35;
            const angle = Math.random() * Math.PI * 2;
            arr.push({
                name: names[i],
                size: size,
                x: 40 + Math.random() * Math.max(1, root.width - size - 80),
                y: 40 + Math.random() * Math.max(1, root.height - size - 80),
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed
            });
        }
        root.bubbles = arr;
    }

    Component.onCompleted: root.initBubbles()
    onWidthChanged: if (root.bubbles.length === 0)
        root.initBubbles()
    onActiveChanged: root.lastTick = 0

    Timer {
        interval: 16
        running: root.visiblePalette
        repeat: true
        onTriggered: {
            const now = Date.now();
            let dt = (root.lastTick > 0) ? (now - root.lastTick) / 1000 : 0.016;
            root.lastTick = now;
            dt = Math.min(dt, 0.05);

            const arr = root.bubbles;
            const w = root.width;
            const h = root.height;
            const ox = root.obstacleX;
            const oy = root.obstacleY;
            const ow = root.obstacleWidth;
            const oh = root.obstacleHeight;

            for (let i = 0; i < arr.length; i++) {
                if (i === root.hoveredIndex) {
                    continue;
                }
                const b = arr[i];
                b.x += b.vx * dt;
                b.y += b.vy * dt;

                if (b.x < 0) {
                    b.x = 0;
                    b.vx = Math.abs(b.vx);
                } else if (b.x + b.size > w) {
                    b.x = w - b.size;
                    b.vx = -Math.abs(b.vx);
                }
                if (b.y < 0) {
                    b.y = 0;
                    b.vy = Math.abs(b.vy);
                } else if (b.y + root.pillHeight > h) {
                    b.y = h - root.pillHeight;
                    b.vy = -Math.abs(b.vy);
                }

                if (ow > 0 && oh > 0 && b.x + b.size > ox && b.x < ox + ow && b.y + root.pillHeight > oy && b.y < oy + oh) {
                    const overlapLeft = (b.x + b.size) - ox;
                    const overlapRight = (ox + ow) - b.x;
                    const overlapTop = (b.y + root.pillHeight) - oy;
                    const overlapBottom = (oy + oh) - b.y;
                    const minX = Math.min(overlapLeft, overlapRight);
                    const minY = Math.min(overlapTop, overlapBottom);

                    if (minX < minY) {
                        b.vx = overlapLeft < overlapRight ? -Math.abs(b.vx) : Math.abs(b.vx);
                        b.x += overlapLeft < overlapRight ? -overlapLeft : overlapRight;
                    } else {
                        b.vy = overlapTop < overlapBottom ? -Math.abs(b.vy) : Math.abs(b.vy);
                        b.y += overlapTop < overlapBottom ? -overlapTop : overlapBottom;
                    }
                }
            }

            for (let i = 0; i < arr.length; i++) {
                if (i === root.hoveredIndex) {
                    continue;
                }
                for (let j = i + 1; j < arr.length; j++) {
                    if (j === root.hoveredIndex) {
                        continue;
                    }
                    const a = arr[i];
                    const c = arr[j];
                    const aHalfW = a.size / 2;
                    const aHalfH = root.pillHeight / 2;
                    const cHalfW = c.size / 2;
                    const cHalfH = root.pillHeight / 2;

                    const acx = a.x + aHalfW;
                    const acy = a.y + aHalfH;
                    const ccx = c.x + cHalfW;
                    const ccy = c.y + cHalfH;

                    const dx = ccx - acx;
                    const dy = ccy - acy;

                    const overlapX = (aHalfW + cHalfW) - Math.abs(dx);
                    const overlapY = (aHalfH + cHalfH) - Math.abs(dy);

                    if (overlapX > 0 && overlapY > 0) {
                        if (overlapX < overlapY) {
                            const nx = dx < 0 ? -1 : 1;
                            a.x -= nx * overlapX * 0.5;
                            c.x += nx * overlapX * 0.5;
                            const avx = a.vx;
                            const cvx = c.vx;
                            a.vx = cvx;
                            c.vx = avx;
                        } else {
                            const ny = dy < 0 ? -1 : 1;
                            a.y -= ny * overlapY * 0.5;
                            c.y += ny * overlapY * 0.5;
                            const avy = a.vy;
                            const cvy = c.vy;
                            a.vy = cvy;
                            c.vy = avy;
                        }
                    }
                }
            }

            root.bubblesTicked();
        }
    }

    Repeater {
        id: bubbleField
        model: root.visiblePalette ? root.bubbles.length : 0

        delegate: Item {
            id: bubble
            required property int index

            readonly property var info: root.bubbles[bubble.index]
            readonly property bool isSelected: Config.currentTheme === bubble.info.name
            readonly property int highlightSlot: Math.floor(Math.random() * 4)

            width: bubble.info.size
            height: root.pillHeight
            z: 3

            Connections {
                target: root
                function onBubblesTicked() {
                    bubble.x = bubble.info.x;
                    bubble.y = bubble.info.y;
                }
            }

            PreviewSwatch {
                id: preview
                themeName: bubble.info.name
                variant: Config.currentVariant
            }

            Rectangle {
                id: pill
                anchors.fill: parent
                radius: 12
                clip: true
                color: "transparent"
                antialiasing: true
                border.width: bubble.isSelected ? 3 : 1
                border.color: bubble.isSelected ? Theme.onBackground : Theme.outlineVariant
                z: 1

                Item {
                    id: contentSource
                    anchors.fill: parent
                    opacity: 0
                    layer.enabled: true
                    layer.smooth: true

                    Row {
                        id: segmentsRow
                        anchors.fill: parent
                        spacing: 0
                        opacity: pillArea.containsMouse ? 0 : 1

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        Repeater {
                            model: [preview.primary, preview.secondary, preview.tertiary, preview.onPrimary]

                            delegate: Rectangle {
                                required property color modelData
                                width: pill.width / 4
                                height: pill.height
                                color: modelData
                                antialiasing: true
                            }
                        }
                    }

                    Rectangle {
                        id: highlightFill
                        anchors.fill: parent
                        opacity: pillArea.containsMouse ? 1 : 0
                        color: [preview.primary, preview.secondary, preview.tertiary, preview.onPrimary][bubble.highlightSlot]
                        antialiasing: true

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: bubble.info.name.replace("_", " ")
                            font.pixelSize: 14
                            font.bold: true
                            color: [preview.onPrimary, preview.onSecondary, preview.onTertiary, preview.primary][bubble.highlightSlot]
                            antialiasing: true
                            opacity: highlightFill.opacity

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: pillMask
                    anchors.fill: parent
                    radius: pill.radius
                    visible: false
                    layer.enabled: true
                    layer.smooth: true
                    antialiasing: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: contentSource
                    maskEnabled: true
                    maskSource: pillMask
                    antialiasing: true
                }

                MouseArea {
                    id: pillArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoveredIndex = bubble.index
                    onExited: if (root.hoveredIndex === bubble.index)
                        root.hoveredIndex = -1
                    onClicked: Config.setTheme(bubble.info.name, Config.currentVariant)
                }
            }
        }
    }
}
