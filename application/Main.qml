pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import typeShitter

Window {
    id: appWindow
    visible: true
    width: 1920
    height: 1080
    title: "Typeshi"
    color: Theme.backgroundColor

    readonly property int linesVisible: 3
    readonly property int passageFontSize: 36
    readonly property int sidePadding: 160

    Component.onCompleted: {
        TypingEngine.startTest(Config.words);
        inputCatcher.forceActiveFocus();
        console.log(History);
        // History.recordResult(85.5, 90.2, 96.0, 88.0, 30, 40, 2, 1, 0);
        // const summary = History.dailySummary();
        // for (let i = 0; i < summary.length; i++) {
        //     console.log(summary[i].date, "-", summary[i].tests, "test, best: ", summary[i].bestWpm);
        // }
    }

    FontMetrics {
        id: fm
        font.pixelSize: appWindow.passageFontSize
    }

    ConfettiRenderer {
        id: confetti
        anchors.fill: parent
        z: 100

        property bool hasBurst: false

        function tryBurst() {
            if (confetti.hasBurst || confetti.width <= 0 || confetti.height <= 0) {
                return;
            }
            confetti.hasBurst = true;
            confetti.spawnBurst([Theme.primaryColor, Theme.secondaryColor, Theme.tertiaryColor]);
        }
    }

    Text {
        anchors {
            top: parent.top
            right: parent.right
            margins: 20
        }
        font.pixelSize: 20
        color: Theme.onSurfaceVariant
        text: {
            TypingEngine.elapsedMs;
            TypingEngine.wpm;
            return "wpm " + TypingEngine.wpm.toFixed(0) + "\nraw " + TypingEngine.rawWpm.toFixed(0) + "\naccuracy " + TypingEngine.accuracy.toFixed(0) + "\nconsistency " + TypingEngine.consistency.toFixed(0) + " %";
        }
    }

    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
        font.pixelSize: 16
        color: Theme.onSurfaceVariant
        text: "best wpm: " + History.bestWpm.toFixed(1) + "\ntests today: " + History.testsToday + "\nstreak: " + History.currentStreak + "\nlongest streak: " + History.longestStreak
    }

    Item {
        id: inputCatcher
        anchors.fill: parent
        focus: true
        activeFocusOnTab: true
        enabled: !TypingEngine.finished
        visible: !TypingEngine.finished

        KeyNavigation.tab: refreshButton

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Backspace) {
                TypingEngine.deleteBackward(event.modifiers & Qt.ControlModifier);
                event.accepted = true;
                return;
            }
            if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
                TypingEngine.typeCharacter(event.text);
                event.accepted = true;
            }
        }

        Item {
            id: testColumn
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: appWindow.sidePadding
                rightMargin: appWindow.sidePadding
            }
            height: viewport.height + 80

            Rectangle {
                id: durationContainer
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: viewport.top
                anchors.bottomMargin: 20
                width: durationInner.width + 24
                height: durationInner.height + 24
                radius: 20
                color: Theme.surfaceContainer
                border.color: Theme.outlineVariant
                border.width: 1

                opacity: TypingEngine.started ? 0 : 1
                enabled: !TypingEngine.started
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Item {
                    id: durationInner
                    anchors.centerIn: parent
                    width: durationRow.width
                    height: durationRow.height

                    property var options: [15, 30, 60, 120]
                    property int selectedIndex: {
                        const i = durationInner.options.indexOf(TypingEngine.testDurationSeconds);
                        return i >= 0 ? i : 2;
                    }
                    property int cellWidth: 60
                    property int cellHeight: 48
                    property int cellSpacing: 6

                    ShapeCanvas {
                        id: selectionShape
                        width: durationInner.cellHeight
                        height: durationInner.cellHeight
                        color: Theme.primaryColor
                        roundedPolygon: GetMShapes.get(22)
                        x: durationInner.selectedIndex * (durationInner.cellWidth + durationInner.cellSpacing) + (durationInner.cellWidth - width) / 2
                        y: 0
                        z: 0

                        Behavior on x {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    Row {
                        id: durationRow
                        spacing: durationInner.cellSpacing
                        z: 1

                        Repeater {
                            model: durationInner.options

                            delegate: Item {
                                id: durationCell
                                required property int index
                                required property int modelData
                                width: durationInner.cellWidth
                                height: durationInner.cellHeight

                                property bool isSelected: durationInner.selectedIndex === durationCell.index

                                Text {
                                    anchors.fill: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: durationCell.modelData + "s"
                                    font.pixelSize: 13
                                    font.bold: durationCell.isSelected
                                    color: durationCell.isSelected ? Theme.onPrimary : (durationArea.containsMouse ? Theme.onSurface : Theme.onSurfaceVariant)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }

                                MouseArea {
                                    id: durationArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        TypingEngine.setTestDurationSeconds(durationCell.modelData);
                                        appWindow.restartTest();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: viewport
                anchors.top: parent.top
                anchors.topMargin: 60
                width: parent.width
                opacity: refreshButton.activeFocus ? 0.35 : 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
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

                property real caretY: (TypingEngine.currentLineIndex - TypingEngine.windowStart) * viewport.lineHeight

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
                    viewport.suppressCaretMoveAnim = true;
                    Qt.callLater(function () {
                        viewport.suppressCaretMoveAnim = false;
                    });
                }
                //end of caret stuff

                clip: true
                height: fm.height * 1.3 * appWindow.linesVisible
                property real lineHeight: fm.height * 1.3

                function measureNewWords() {
                    const target = TypingEngine.targetText;
                    const typed = TypingEngine.typedText;
                    const words = TypingEngine.wordBoundaries;

                    for (let i = 0; i < words.length; i++) {
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
                    TypingEngine.setViewportWidth(viewport.width);
                }
                Connections {
                    target: TypingEngine
                    function onTargetTextChanged() {
                        viewport.measureNewWords();
                    }
                    function onTypedTextChanged() {
                        viewport.measureNewWords();
                    }
                }
                onWidthChanged: TypingEngine.setViewportWidth(viewport.width)
                Component.onCompleted: viewport.measureNewWords()

                Column {
                    id: linesColumn
                    width: viewport.width
                    y: -TypingEngine.windowStart * viewport.lineHeight
                    Behavior on y {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.InOutQuad
                        }
                    }
                    Repeater {
                        model: Math.min(TypingEngine.lines.length, TypingEngine.windowStart + appWindow.linesVisible + 2)
                        delegate: Row {
                            id: lineFlow
                            required property int index

                            property var modelData: lineFlow.index < TypingEngine.lines.length ? TypingEngine.lines[lineFlow.index] : null
                            width: viewport.width
                            height: viewport.lineHeight
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
                                    font.pixelSize: appWindow.passageFontSize
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
                    visible: viewport.caretReady
                    x: viewport.caretX
                    y: viewport.caretY + viewport.lineHeight - height - 10
                    width: viewport.caretW
                    height: 3
                    color: Theme.onSurface
                    z: 10

                    Behavior on x {
                        enabled: !viewport.suppressCaretMoveAnim
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on y {
                        enabled: !viewport.suppressCaretMoveAnim
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

            Item {
                id: refreshButton
                anchors.top: viewport.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: 40

                opacity: (!TypingEngine.started || refreshButton.activeFocus) ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
                Icon {
                    anchors.centerIn: parent
                    source: "assets/icons/refresh.svg"
                    iconSize: 28
                    color: refreshButton.activeFocus ? Theme.primaryColor : (refreshArea.containsMouse ? Theme.primaryColor : Theme.onSurfaceVariant)
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appWindow.restartTest()
                }
                Keys.onReturnPressed: appWindow.restartTest()
                Keys.onEnterPressed: appWindow.restartTest()

                KeyNavigation.tab: inputCatcher
            }
        }
    }

    Loader {
        id: aftermathLoader
        anchors.fill: parent
        active: TypingEngine.finished
        opacity: TypingEngine.finished ? 1 : 0
        scale: TypingEngine.finished ? 1 : 0

        onActiveChanged: {
            if (active) {
                const oldBest = History.bestWpm;
                History.recordResult(TypingEngine.wpm, TypingEngine.rawWpm, TypingEngine.accuracy, TypingEngine.consistency, Math.round(TypingEngine.elapsedMs / 1000), TypingEngine.correctCount, TypingEngine.incorrectCount, TypingEngine.extraCount, TypingEngine.missedCount);

                if (TypingEngine.wpm > 0 && TypingEngine.wpm > oldBest) {
                    confetti.tryBurst();
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }
        sourceComponent: Aftermath {
            onRestartRequested: appWindow.restartTest()
        }
    }

    function restartTest() {
        TypingEngine.startTest(Config.words);
        confetti.hasBurst = false;
        inputCatcher.forceActiveFocus();
    }
}
