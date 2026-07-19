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
    property string testMode: "time"

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

    Records {
        id: records
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
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

            Row {
                id: modeRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: viewport.top
                anchors.bottomMargin: 20
                spacing: 12

                opacity: TypingEngine.started ? 0 : 1
                enabled: !TypingEngine.started
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }

                SegmentedControl {
                    id: durationControl
                    visible: appWindow.testMode === "time"
                    options: [15, 30, 60, 120]
                    selectedValue: TypingEngine.testDurationSeconds
                    suffix: "s"
                    onSelected: value => {
                        TypingEngine.setTestDurationSeconds(value);
                        appWindow.restartTest();
                    }
                }

                SegmentedControl {
                    id: wordCountControl
                    visible: appWindow.testMode === "words"
                    options: [10, 25, 50, 100]
                    selectedValue: TypingEngine.testWordCount
                    onSelected: value => {
                        TypingEngine.setTestWordCount(value);
                        appWindow.restartTest();
                    }
                }

                ToggleChip {
                    id: wordsChip
                    label: "words"
                    active: appWindow.testMode === "words"
                    onToggled: {
                        appWindow.testMode = appWindow.testMode === "words" ? "time" : "words";
                        appWindow.restartTest();
                    }
                }

                ToggleChip {
                    id: punctuationChip
                    label: "punctuation"
                    visible: appWindow.testMode !== "quote"
                    active: TypingEngine.punctuationEnabled
                    onToggled: {
                        TypingEngine.setPunctuationEnabled(!TypingEngine.punctuationEnabled);
                        appWindow.restartTest();
                    }
                }

                ToggleChip {
                    id: quoteChip
                    label: "quote"
                    active: appWindow.testMode === "quote"
                    onToggled: {
                        appWindow.testMode = appWindow.testMode === "quote" ? "time" : "quote";
                        appWindow.restartTest();
                    }
                }
            }

            TypingViewport {
                id: viewport
                anchors.top: parent.top
                anchors.topMargin: 60
                passageFontSize: appWindow.passageFontSize
                linesVisible: appWindow.linesVisible
                dimmed: refreshButton.activeFocus
            }

            RefreshButton {
                id: refreshButton
                anchors.top: viewport.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                dimmedUnlessFocused: !TypingEngine.started
                tabTarget: inputCatcher
                onActivated: appWindow.restartTest()
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
                let mode = "english";
                let dur = TypingEngine.testDurationSeconds;
                let punct = TypingEngine.punctuationEnabled;
                let words = 0;
                if (appWindow.testMode === "quote") {
                    mode = "quote";
                    dur = 0;
                    punct = false;
                } else if (appWindow.testMode === "words") {
                    mode = "words";
                    dur = 0;
                    words = TypingEngine.testWordCount;
                }
                const oldBest = appWindow.testMode === "words" ? History.bestWpmForWords(words, punct ? 1 : 0) : History.bestWpmFor(mode, dur, punct ? 1 : 0);

                History.recordResult(TypingEngine.wpm, TypingEngine.rawWpm, TypingEngine.accuracy, TypingEngine.consistency, Math.round(TypingEngine.elapsedMs / 1000), TypingEngine.correctCount, TypingEngine.incorrectCount, TypingEngine.extraCount, TypingEngine.missedCount, mode, punct, words);

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
            resultMode: appWindow.testMode === "quote" ? "quote" : (appWindow.testMode === "words" ? "words" : "english")
            resultDuration: appWindow.testMode === "quote" ? 0 : (appWindow.testMode === "words" ? TypingEngine.testWordCount : TypingEngine.testDurationSeconds)
            resultPunctuation: appWindow.testMode === "quote" ? false : TypingEngine.punctuationEnabled
            onRestartRequested: appWindow.restartTest()
        }
    }

    function restartTest() {
        if (appWindow.testMode === "quote") {
            const q = Quotes.randomQuote();
            TypingEngine.startQuoteTest(q.text);
        } else if (appWindow.testMode === "words") {
            TypingEngine.startWordCountTest(Config.words, TypingEngine.testWordCount);
        } else {
            TypingEngine.startTest(Config.words);
        }

        confetti.hasBurst = false;
        inputCatcher.forceActiveFocus();
    }
}
