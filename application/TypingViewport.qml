pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root

    property int passageFontSize: 36
    property int linesVisible: 3
    property bool dimmed: false

    property int opponentCharIndex: -1
    property string opponentUsername: ""
    property int opponentWordExtraCount: 0
    property int lastMeasuredCursor: 0

    readonly property real caretBottomGap: root.lineHeight * 0.12

    width: parent.width
    height: fm.height * 1.3 * root.linesVisible
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

    property int clampedOpponentCharIndex: {
        if (root.opponentCharIndex < 0) {
            return -1;
        }
        const rawIndex = TypingEngine.rawIndexForCanonical(root.opponentCharIndex);
        const len = TypingEngine.targetText.length;
        return Math.max(0, Math.min(len, rawIndex));
    }

    property int opponentLineIndex: {
        if (root.clampedOpponentCharIndex < 0) {
            return -1;
        }
        const lines = TypingEngine.lines;
        for (let i = 0; i < lines.length; i++) {
            if (root.clampedOpponentCharIndex >= lines[i].start && root.clampedOpponentCharIndex <= lines[i].end) {
                return i;
            }
        }
        if (lines.length > 0) {
            return lines.length - 1;
        }
        return -1;
    }
    property real opponentCaretW: {
        const cursor = root.clampedOpponentCharIndex;
        const target = TypingEngine.targetText;
        if (cursor < 0 || cursor >= target.length) {
            return fm.averageCharacterWidth;
        }
        return fm.advanceWidth(target.charAt(cursor));
    }
    property real opponentCaretX: {
        if (root.opponentLineIndex < 0) {
            return 0;
        }
        const line = TypingEngine.lines[root.opponentLineIndex];
        const target = TypingEngine.targetText;
        const end = Math.min(root.clampedOpponentCharIndex, line.end);
        if (end <= line.start) {
            return root.opponentWordExtraCount * fm.averageCharacterWidth;
        }
        let width = 0;
        for (let i = line.start; i < end; i++) {
            const ch = target.charAt(i);
            width += fm.advanceWidth(ch === " " ? "\u00A0" : ch);
        }
        return width + root.opponentWordExtraCount * fm.averageCharacterWidth;
    }
    property real opponentCaretY: (root.opponentLineIndex - TypingEngine.windowStart) * root.lineHeight

    property bool opponentCaretVisible: {
        if (root.opponentCharIndex < 0) {
            return false;
        }
        if (root.opponentLineIndex < 0) {
            return false;
        }
        if (root.opponentLineIndex < TypingEngine.windowStart) {
            return false;
        }
        if (root.opponentLineIndex >= TypingEngine.windowStart + root.linesVisible) {
            return false;
        }
        return true;
    }

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
            // const chunkWidth = fm.advanceWidth(target.substring(w.start, w.end));
            // const chunkWidth = fm.advanceWidth(chunkText);
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
                            if ((charState === TypingEngine.Extra || charState === TypingEngine.Incorrect) && charDelegate.globalIndex < TypingEngine.typedText.length) {
                                const typedAt = TypingEngine.typedText.charAt(charDelegate.globalIndex);
                                if (typedAt === "\u2064") {
                                    return TypingEngine.characterAt(charDelegate.globalIndex);
                                }
                                return typedAt;
                            }
                            return TypingEngine.characterAt(charDelegate.globalIndex);
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
    Caret {
        id: opponentCaret
        visible: root.opponentCaretVisible
        x: root.opponentCaretX
        y: root.opponentCaretY + root.lineHeight - height - root.caretBottomGap
        width: root.opponentCaretW
        height: 3
        color: Theme.secondaryColor
        opacity: 0.85
        z: 9

        Behavior on x {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.bottom: parent.top
            anchors.bottomMargin: 3
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.opponentUsername
            font.pixelSize: 10
            font.bold: true
            color: Theme.secondaryColor
        }
    }
}
