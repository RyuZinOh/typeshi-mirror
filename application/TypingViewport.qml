pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    property int passageFontSize: 36
    property int linesVisible: 3
    property bool dimmed: false

    property int lastMeasuredCursor: 0
    readonly property point caretScenePos: root.mapToItem(null, root.caretX + root.caretW / 2, root.caretY + root.lineHeight / 2)
    readonly property real caretBottomGap: root.lineHeight * 0.12

    readonly property int visibleLineCount: Math.max(1, Math.min(root.linesVisible, TypingEngine.lines.length))

    width: parent.width
    height: root.lineHeight * root.visibleLineCount
    Behavior on height {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
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

    //caret stuffs
    property bool caretReady: TypingEngine.lines.length > 0
    property int caretLineIndex: TypingEngine.currentLineIndex

    property real caretX: {
        const lines = TypingEngine.lines;
        const li = TypingEngine.currentLineIndex;
        if (li < 0 || li >= lines.length) {
            return 0;
        }

        const line = lines[li];
        const cursor = TypingEngine.typedText.length;
        const end = Math.min(cursor, line.end);
        if (end <= line.start) {
            return 0;
        }

        const target = TypingEngine.targetText;
        const typed = TypingEngine.typedText;
        let width = 0;
        for (let i = line.start; i < end; i++) {
            let ch = (i < typed.length) ? typed.charAt(i) : target.charAt(i);
            if (ch === "\u2064") {
                ch = target.charAt(i);
            }
            width += fm.advanceWidth(ch === " " ? "\u00A0" : ch);
        }
        return width;
    }

    property real caretY: (TypingEngine.currentLineIndex - TypingEngine.windowStart) * root.lineHeight

    property real caretW: {
        const cursor = TypingEngine.typedText.length;
        const target = TypingEngine.targetText;
        if (cursor >= target.length) {
            return fm.averageCharacterWidth;
        }
        return fm.advanceWidth(target.charAt(cursor));
    }

    property bool suppressCaretMoveAnim: false
    onCaretLineIndexChanged: {
        root.suppressCaretMoveAnim = true;
        Qt.callLater(function () {
            root.suppressCaretMoveAnim = false;
        });
    }
    //end of caret stuff

    property real lineHeight: fm.height * 1.3

    function measureNewWords() {
        const target = TypingEngine.targetText;
        const typed = TypingEngine.typedText;
        const words = TypingEngine.wordBoundaries;

        const newCursor = typed.length;
        const lowCursor = Math.min(root.lastMeasuredCursor, newCursor);

        let lo = 0, hi = words.length;
        while (lo < hi) {
            const mid = (lo + hi) >> 1;
            if (words[mid].end <= lowCursor) {
                lo = mid + 1;
            } else {
                hi = mid;
            }
        }

        for (let i = lo; i < words.length; i++) {
            const w = words[i];
            let chunkWidth = 0;
            for (let c = w.start; c < w.end; c++) {
                let ch = (c < typed.length) ? typed.charAt(c) : target.charAt(c);
                if (ch === "\u2064") {
                    ch = target.charAt(c);
                }
                chunkWidth += fm.advanceWidth(ch === " " ? "\u00A0" : ch);
            }
            TypingEngine.setWordWidth(w.start, w.end, chunkWidth);
        }
        root.lastMeasuredCursor = newCursor;
        TypingEngine.setViewportWidth(root.width);
    }
    Connections {
        target: TypingEngine
        function onTargetTextChanged() {
            if (!TypingEngine.started) {
                linesContainer.suppressScrollAnim = true;
                Qt.callLater(function () {
                    linesContainer.suppressScrollAnim = false;
                });
            }
            root.measureNewWords();
        }
        function onTypedTextChanged() {
            root.measureNewWords();
        }
        function onWordWidthCacheInvalidated() {
            root.lastMeasuredCursor = 0;
        }
    }
    Connections {
        target: Config
        function onConfigChanged() {
            root.lastMeasuredCursor = 0;
            root.measureNewWords();
        }
    }
    onWidthChanged: TypingEngine.setViewportWidth(root.width)
    Component.onCompleted: root.measureNewWords()

    Item {
        id: linesContainer
        width: root.width
        y: -TypingEngine.windowStart * root.lineHeight

        property bool suppressScrollAnim: false
        Behavior on y {
            enabled: !linesContainer.suppressScrollAnim
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }

        readonly property int bufferAbove: 2
        readonly property int bufferBelow: 2
        readonly property int loIndex: Math.max(0, TypingEngine.windowStart - linesContainer.bufferAbove)
        readonly property int hiIndex: Math.min(TypingEngine.lines.length, TypingEngine.windowStart + root.linesVisible + linesContainer.bufferBelow)

        Repeater {
            model: Math.max(0, linesContainer.hiIndex - linesContainer.loIndex)
            delegate: Row {
                id: lineFlow
                required property int index

                readonly property int lineIndex: linesContainer.loIndex + lineFlow.index
                property var modelData: lineFlow.lineIndex < TypingEngine.lines.length ? TypingEngine.lines[lineFlow.lineIndex] : null
                width: root.width
                height: root.lineHeight
                y: lineFlow.lineIndex * root.lineHeight
                spacing: 0
                visible: lineFlow.modelData !== null

                Repeater {
                    model: lineFlow.modelData ? lineFlow.modelData.end - lineFlow.modelData.start : 0
                    delegate: Text {
                        id: charDelegate
                        required property int index

                        property int globalIndex: lineFlow.modelData.start + charDelegate.index

                        property int charState: {
                            TypingEngine.typedText.length;
                            return TypingEngine.characterStateAt(charDelegate.globalIndex);
                        }
                        property string displayCh: {
                            TypingEngine.typedText.length;
                            return TypingEngine.displayCharAt(charDelegate.globalIndex);
                        }
                        text: displayCh === " " ? "\u00A0" : displayCh
                        font.family: Config.currentFont
                        font.pixelSize: root.passageFontSize

                        width: fm.advanceWidth(displayCh === " " ? "\u00A0" : displayCh)
                        clip: true
                        color: {
                            if (charState === TypingEngine.Correct) {
                                return Theme.primaryColor;
                            }
                            if (charState === TypingEngine.Incorrect) {
                                return Theme.errorColor;
                            }
                            if (charState === TypingEngine.Current) {
                                return Theme.onSurface;
                            }
                            return Theme.onSurfaceVariant;
                        }
                    }
                }
            }
        }
    }
    Caret {
        id: caret
        visible: root.caretReady
        x: root.caretX

        y: root.caretY + root.lineHeight - height - root.caretBottomGap
        width: root.caretW
        height: 3
        color: Theme.onSurface
        z: 10

        Behavior on x {
            enabled: !root.suppressCaretMoveAnim
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            enabled: !root.suppressCaretMoveAnim
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }
    }
}
