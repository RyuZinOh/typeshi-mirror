pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: wordItem
    required property FallingWordItem modelData
    required property QtObject controller
    readonly property ShootoutViewport typedController: wordItem.controller as ShootoutViewport
    property alias letterRepeater: letterRepeaterInner
    readonly property int wordStart: wordItem.modelData ? wordItem.modelData.wordStart : -1
    readonly property int wordEnd: wordItem.modelData ? wordItem.modelData.wordEnd : -1
    transformOrigin: Item.Center

    x: wordItem.modelData ? wordItem.modelData.x : 0
    y: wordItem.modelData ? wordItem.modelData.y : 0
    width: letterRow.width
    height: letterRow.height
    opacity: (wordItem.modelData && wordItem.modelData.dying) ? 0 : 1

    readonly property bool isActiveWord: {
        TypingEngine.typedText.length;
        if (!wordItem.modelData) {
            return false;
        }
        return TypingEngine.typedText.length >= wordItem.modelData.wordStart && TypingEngine.typedText.length <= wordItem.modelData.wordEnd;
    }

    readonly property bool hasCurrentError: {
        TypingEngine.typedText.length;
        if (!wordItem.modelData) {
            return false;
        }
        return wordItem.typedController.wordHasCurrentError(wordItem.wordStart, wordItem.wordEnd);
    }

    Behavior on opacity {
        NumberAnimation {
            duration: (wordItem.modelData && wordItem.modelData.dying) ? 0 : 200
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: 16
            easing.type: Easing.Linear
        }
    }

    Connections {
        target: wordItem.controller
        function onWordImpact(wordStart) {
            if (wordItem.modelData && wordItem.modelData.wordStart === wordStart) {
                if (wordItem.hasCurrentError) {
                    errorFlashAnim.restart();
                }
                shakeAnim.restart();
            }
        }
    }

    SequentialAnimation {
        id: errorFlashAnim
        NumberAnimation {
            target: crackFlash
            property: "opacity"
            to: 0.9
            duration: 40
        }
        NumberAnimation {
            target: crackFlash
            property: "opacity"
            to: 0
            duration: 100
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation {
            target: wordItem
            property: "rotation"
            to: -4
            duration: 35
        }
        NumberAnimation {
            target: wordItem
            property: "rotation"
            to: 4
            duration: 60
        }
        NumberAnimation {
            target: wordItem
            property: "rotation"
            to: -3
            duration: 50
        }
        NumberAnimation {
            target: wordItem
            property: "rotation"
            to: 0
            duration: 40
        }
    }

    Rectangle {
        visible: wordItem.isActiveWord
        anchors.fill: letterRow
        anchors.margins: -6
        radius: 6
        color: "transparent"
        border.color: wordItem.hasCurrentError ? Theme.errorColor : Theme.primaryColor
        border.width: 2

        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Rectangle {
        id: crackFlash
        anchors.fill: letterRow
        anchors.margins: -6
        radius: 6
        color: "transparent"
        border.color: Theme.errorColor
        border.width: 2
        opacity: 0
    }

    Row {
        id: letterRow
        Repeater {
            id: letterRepeaterInner
            model: wordItem.modelData ? (wordItem.modelData.wordEnd - wordItem.modelData.wordStart) : 0
            delegate: Text {
                id: letterDelegate
                required property int index
                readonly property int globalIndex: wordItem.modelData ? (wordItem.modelData.wordStart + letterDelegate.index) : 0
                readonly property int charState: {
                    TypingEngine.typedText.length;
                    if (!wordItem.modelData) {
                        return TypingEngine.Pending;
                    }
                    return TypingEngine.characterStateAt(letterDelegate.globalIndex);
                }
                text: {
                    if (!wordItem.modelData) {
                        return "";
                    }
                    const ch = TypingEngine.characterAt(letterDelegate.globalIndex);
                    return ch === " " ? "\u00A0" : ch;
                }
                font.family: Config.currentFont
                font.pixelSize: wordItem.typedController.passageFontSize
                font.bold: true
                color: charState === TypingEngine.Correct ? Theme.primaryColor : (charState === TypingEngine.Incorrect ? Theme.errorColor : Theme.onSurfaceVariant)
                opacity: charState === TypingEngine.Correct ? 0 : 1
            }
        }
    }
}
