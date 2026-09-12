pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    property int passageFontSize: 36
    property bool dimmed: false
    readonly property real anchorX: width * 0.32
    readonly property real fadeWidth: 60

    width: parent.width
    height: fm.height * 1.6
    clip: true
    opacity: root.dimmed ? 0.35 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    FontMetrics {
        id: fm
        font.family: Config.currentFont
        font.pixelSize: root.passageFontSize
    }

    Component.onCompleted: TypingEngine.setWrapDisabled(true)
    Component.onDestruction: TypingEngine.setWrapDisabled(false)

    readonly property real caretOffsetX: {
        const idx = TypingEngine.typedText.length;
        const item = charRepeater.itemAt(idx);
        return item ? item.x : (charRow.width > 0 ? charRow.width : 0);
    }

    property real lastKeyTimeMs: 0
    property real avgKeyIntervalMs: 160

    onCaretOffsetXChanged: {
        const now = Date.now();
        if (root.lastKeyTimeMs > 0) {
            const delta = now - root.lastKeyTimeMs;
            if (delta > 0 && delta < 2000) {
                root.avgKeyIntervalMs = root.avgKeyIntervalMs * 0.7 + delta * 0.3;
            }
        }
        root.lastKeyTimeMs = now;
    }

    Item {
        id: tapeContent
        x: root.anchorX - root.caretOffsetX
        y: 0
        height: parent.height

        Behavior on x {
            NumberAnimation {
                duration: Math.max(70, Math.min(220, root.avgKeyIntervalMs * 1.05))
                easing.type: Easing.Linear
            }
        }
    }

    Row {
        id: charRow
        x: tapeContent.x
        y: parent.height / 2 - fm.height / 2

        Repeater {
            id: charRepeater
            model: TypingEngine.targetText.length
            delegate: Text {
                id: charDelegate
                required property int index

                property int charState: {
                    TypingEngine.typedText.length;
                    return TypingEngine.characterStateAt(charDelegate.index);
                }
                property string displayCh: {
                    TypingEngine.typedText.length;
                    if ((charState === TypingEngine.Extra || charState === TypingEngine.Incorrect) && charDelegate.index < TypingEngine.typedText.length) {
                        const typedAt = TypingEngine.typedText.charAt(charDelegate.index);
                        if (typedAt === "\u2064")
                            return TypingEngine.characterAt(charDelegate.index);
                        return typedAt;
                    }
                    return TypingEngine.characterAt(charDelegate.index);
                }
                text: displayCh === " " ? "\u00A0" : displayCh
                font.family: Config.currentFont
                font.pixelSize: root.passageFontSize
                renderType: Text.NativeRendering
                antialiasing: true
                color: {
                    if (charState === TypingEngine.Correct)
                        return Theme.primaryColor;
                    if (charState === TypingEngine.Incorrect)
                        return Theme.errorColor;
                    if (charState === TypingEngine.Current)
                        return Theme.onSurface;
                    return Theme.onSurfaceVariant;
                }
            }
        }
    }

    Caret {
        x: root.anchorX
        y: charRow.y + fm.height - height
        width: fm.averageCharacterWidth
        height: 3
        color: Theme.onSurface
        z: 10
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.fadeWidth
        z: 20
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Theme.backgroundColor
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(Theme.backgroundColor.r, Theme.backgroundColor.g, Theme.backgroundColor.b, 0)
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.fadeWidth
        z: 20
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Qt.rgba(Theme.backgroundColor.r, Theme.backgroundColor.g, Theme.backgroundColor.b, 0)
            }
            GradientStop {
                position: 1.0
                color: Theme.backgroundColor
            }
        }
    }
}
