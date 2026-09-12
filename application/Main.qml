pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window

Window {
    id: appWindow
    visible: true
    width: 1920
    height: 1080
    title: "Typeshi"
    color: Theme.backgroundColor

    readonly property int linesVisible: 3
    readonly property int passageFontSize: Config.fontSize
    readonly property int sidePadding: 160
    property string testMode: "time"
    property bool rainEnabled: false
    property bool inLobby: true
    property bool shootoutEnabled: false
    property bool showUserStats: false
    property bool showAccountSettings: false
    function restoreInputFocus() {
        inputCatcher.forceActiveFocus();
    }
    readonly property real testProgress: {
        if (!TypingEngine.started) {
            return 0;
        }
        if (TypingEngine.finished) {
            return 1;
        }
        if (appWindow.testMode === "words" || appWindow.testMode === "quote" || appWindow.testMode === "repeat") {
            const target = TypingEngine.targetText.length;
            if (target <= 0) {
                return 0;
            }
            return Math.max(0, Math.min(1, TypingEngine.typedText.length / target));
        }
        const totalMs = TypingEngine.testDurationSeconds * 1000;
        if (totalMs <= 0) {
            return 0;
        }
        return Math.max(0, Math.min(1, TypingEngine.elapsedMs / totalMs));
    }
    onShootoutEnabledChanged: TypingEngine.setOverflowInsertionEnabled(!appWindow.shootoutEnabled)
    onShowUserStatsChanged: if (showUserStats) {
        appWindow.showAccountSettings = false;
    }
    onShowAccountSettingsChanged: if (showAccountSettings) {
        appWindow.showUserStats = false;
    }

    Component.onCompleted: {
        appWindow.testMode = Config.lastMode;
        TypingEngine.setTestDurationSeconds(Config.lastDuration);
        TypingEngine.setTestWordCount(Config.lastWordCount);
        TypingEngine.setPunctuationEnabled(Config.lastPunctuation);
        appWindow.restartTest();
        inputCatcher.forceActiveFocus();
    }
    Connections {
        target: Shootout
        function onWordMissed(wordStart) {
            if (appWindow.shootoutEnabled && !TypingEngine.finished) {
                appWindow.shootoutEnabled = false;
                appWindow.restartTest();
            }
        }
    }

    ShaderScene {
        id: sceneLayer
        anchors.fill: parent
        rainEnabled: appWindow.rainEnabled

        Item {
            id: sceneRoot
            anchors.fill: parent

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

            Item {
                id: inputCatcher
                anchors.fill: parent
                focus: true
                activeFocusOnTab: true
                enabled: !TypingEngine.finished && !appWindow.showUserStats && !appWindow.showAccountSettings
                visible: !TypingEngine.finished && !appWindow.showUserStats && !appWindow.showAccountSettings

                KeyNavigation.tab: refreshButton

                Keys.onEscapePressed: {
                    if (!TypingEngine.started) {
                        topJesus.open();
                    }
                }

                Keys.onPressed: event => {
                    if (topJesus.isOpen) {
                        return;
                    }
                    if (event.key === Qt.Key_Backspace) {
                        if (!inputCatcher.activeFocus) {
                            inputCatcher.forceActiveFocus();
                        }
                        TypingEngine.deleteBackward(event.modifiers & Qt.ControlModifier);
                        event.accepted = true;
                        return;
                    }
                    if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
                        if (!inputCatcher.activeFocus) {
                            inputCatcher.forceActiveFocus();
                        }
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

                    height: viewportLoader.height + 80

                    opacity: appWindow.shootoutEnabled ? 0 : 1
                    scale: appWindow.shootoutEnabled ? 0.96 : 1
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }

                    ModeControls {
                        id: modeRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: viewportLoader.top
                        anchors.bottomMargin: 50
                        appWindow: appWindow
                    }
                    LiveStats {
                        id: liveStats
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: viewportLoader.top
                        anchors.bottomMargin: 50
                    }

                    Loader {
                        id: viewportLoader
                        anchors.top: parent.top
                        anchors.topMargin: 60
                        width: parent.width
                        active: !appWindow.shootoutEnabled
                        sourceComponent: Config.tapeModeEnabled ? tapeViewportComponent : normalViewportComponent
                    }

                    Component {
                        id: normalViewportComponent
                        TypingViewport {
                            passageFontSize: appWindow.passageFontSize
                            linesVisible: appWindow.linesVisible
                            dimmed: refreshButton.activeFocus
                        }
                    }
                    Component {
                        id: tapeViewportComponent
                        TapeViewport {
                            passageFontSize: appWindow.passageFontSize
                            dimmed: refreshButton.activeFocus
                        }
                    }

                    RefreshButton {
                        id: refreshButton
                        anchors.top: viewportLoader.bottom
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: !topJesus.isOpen
                        dimmedUnlessFocused: TypingEngine.started
                        tabTarget: inputCatcher
                        typingCatcher: inputCatcher
                        onActivated: appWindow.restartTest()
                    }
                }
            }

            Loader {
                id: shootoutFullscreenLoader
                anchors.fill: parent
                z: 55
                active: appWindow.shootoutEnabled && !TypingEngine.finished

                opacity: appWindow.shootoutEnabled ? 1 : 0
                scale: appWindow.shootoutEnabled ? 1 : 0.96

                Behavior on opacity {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }

                sourceComponent: Component {
                    ShootoutViewport {
                        passageFontSize: appWindow.passageFontSize
                    }
                }
            }

            Component {
                id: soloAftermathComponent
                Aftermath {
                    resultMode: appWindow.testMode === "quote" ? "quote" : (appWindow.testMode === "words" ? "words" : "english")
                    resultDuration: appWindow.testMode === "quote" ? 0 : (appWindow.testMode === "words" ? TypingEngine.testWordCount : TypingEngine.testDurationSeconds)
                    resultPunctuation: appWindow.testMode === "quote" ? false : TypingEngine.punctuationEnabled
                    onRestartRequested: appWindow.restartTest()
                    isRepeat: appWindow.testMode === "repeat"
                    onRepeatRequested: appWindow.repeatTest()
                }
            }

            Loader {
                id: aftermathLoader
                anchors.fill: parent
                z: 70
                active: TypingEngine.finished && !appWindow.showUserStats && !appWindow.showAccountSettings
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

                        if (appWindow.testMode !== "repeat") {
                            const oldBest = appWindow.testMode === "words" ? History.bestWpmForWords(words, punct ? 1 : 0, Config.currentWordList) : History.bestWpmFor(mode, dur, punct ? 1 : 0, -1, Config.currentWordList);
                            const wasFirstToday = History.testsToday === 0;

                            History.recordResult(TypingEngine.wpm, TypingEngine.rawWpm, TypingEngine.accuracy, TypingEngine.consistency, Math.round(TypingEngine.elapsedMs / 1000), TypingEngine.correctCount, TypingEngine.incorrectCount, TypingEngine.extraCount, TypingEngine.missedCount, mode, punct, words, Config.currentWordList);

                            if (TypingEngine.wpm > 0 && TypingEngine.wpm > oldBest) {
                                confetti.tryBurst();
                            }

                            if (wasFirstToday && TypingEngine.wpm > 0) {
                                bottomTray.streakCelebration.start(History.currentStreak);
                            }
                        }
                    }
                }
                sourceComponent: soloAftermathComponent
            }
            Loader {
                id: userStatsLoader
                anchors.fill: parent
                z: 70
                active: appWindow.showUserStats
                sourceComponent: Component {
                    UserStats {
                        onBackRequested: appWindow.showUserStats = false
                    }
                }
            }
            Loader {
                id: accountSettingsLoader
                anchors.fill: parent
                z: 70
                active: appWindow.showAccountSettings
                sourceComponent: Component {
                    AccountSettings {
                        onBackRequested: appWindow.showAccountSettings = false
                    }
                }
            }
        }
        Loader {
            id: borderProgressLoader
            anchors.fill: parent
            active: Config.borderProgressEnabled
            sourceComponent: BorderProgress {
                progress: appWindow.testProgress
            }
        }
        Item {
            id: uiOverlay
            anchors.fill: parent
            z: 400

            BottomTrayIcons {
                id: bottomTray
                appWindow: appWindow
            }

            TopJesus {
                id: topJesus
                onRequestFocusRestore: inputCatcher.forceActiveFocus()
            }
        }
    }

    function restartTest() {
        if (appWindow.testMode === "repeat") {
            appWindow.testMode = Config.lastMode;
        }
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
    function repeatTest() {
        appWindow.testMode = "repeat";
        TypingEngine.repeatTest();
        confetti.hasBurst = false;
        inputCatcher.forceActiveFocus();
    }
}
