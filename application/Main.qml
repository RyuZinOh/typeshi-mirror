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
    readonly property int passageFontSize: Config.fontSize
    readonly property int sidePadding: 160
    property string testMode: "time"
    property bool rainEnabled: false
    property bool resettingProgress: false
    property bool showUserStats: false
    property bool showAccountSettings: false
    property bool aftermathLeaving: false
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
        appWindow.syncDiscord();
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
            Timer {
                id: leaveTimer
                interval: 220
                property var action: null
                onTriggered: {
                    if (action) {
                        action();
                    }
                    action = null;
                    appWindow.aftermathLeaving = false;
                }
            }

            Item {
                id: inputCatcher
                anchors.fill: parent
                focus: true
                activeFocusOnTab: true
                readonly property bool shown: !TypingEngine.finished && !appWindow.showUserStats && !appWindow.showAccountSettings
                enabled: shown
                opacity: shown ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
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
                        keyboardViz.keyDown(event.text === " " ? " " : event.text.toLowerCase());
                        event.accepted = true;
                    }
                }
                Keys.onReleased: event => {
                    keyboardViz.keyUP(event.text === " " ? " " : event.text.toLowerCase());
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
                        instant: appWindow.resettingProgress
                    }
                    Loader {
                        id: viewportLoader
                        anchors.top: parent.top
                        anchors.topMargin: 60
                        width: parent.width
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

                    KeyboardViz {
                        id: keyboardViz
                        anchors.top: viewportLoader.bottom
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: Config.keyboardVizModeEnabled
                    }
                    RefreshButton {
                        id: refreshButton
                        anchors.top: Config.keyboardVizModeEnabled ? keyboardViz.bottom : viewportLoader.bottom
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

            Component {
                id: soloAftermathComponent
                Aftermath {
                    ctx: appWindow.resultContext()
                    onRestartRequested: appWindow.leaveAftermathThen(appWindow.restartTest)
                    isRepeat: appWindow.testMode === "repeat"
                    onRepeatRequested: appWindow.leaveAftermathThen(appWindow.repeatTest)
                }
            }
            Loader {
                id: aftermathLoader
                anchors.fill: parent
                z: 70

                readonly property bool shouldShow: TypingEngine.finished && !appWindow.showUserStats && !appWindow.showAccountSettings && !appWindow.aftermathLeaving

                active: aftermathLoader.shouldShow || fadeOutTimer.running
                opacity: aftermathLoader.shouldShow ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    id: fadeOutTimer
                    interval: 200
                }

                onShouldShowChanged: {
                    if (!aftermathLoader.shouldShow) {
                        fadeOutTimer.restart();
                    }
                }
                onActiveChanged: {
                    if (active && aftermathLoader.shouldShow) {
                        appWindow.recordAndCelebrate();
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
                instant: appWindow.resettingProgress
            }
        }
        Item {
            id: uiOverlay
            anchors.fill: parent
            z: 400

            property bool mouseFollow: false
            property point mousePos: Qt.point(0, 0)

            HoverHandler {
                id: mouseHover
                onPointChanged: {
                    if (TypingEngine.started && !TypingEngine.finished) {
                        return;
                    }
                    uiOverlay.mousePos = mouseHover.point.scenePosition;
                    uiOverlay.mouseFollow = true;
                    mouseIdleTimer.restart();
                }
            }

            Timer {
                id: mouseIdleTimer
                interval: 2500
                onTriggered: uiOverlay.mouseFollow = false
            }

            Connections {
                target: TypingEngine
                function onTypedTextChanged() {
                    uiOverlay.mouseFollow = false;
                }
            }
            BottomTrayIcons {
                appWindow: appWindow
            }
            Loader {
                id: watcherLoader
                anchors.top: parent.top
                anchors.topMargin: 40
                anchors.horizontalCenter: parent.horizontalCenter
                active: Config.watcherEnabled && !appWindow.showUserStats && !appWindow.showAccountSettings
                sourceComponent: Watcher {
                    id: watcher
                    size: 110
                    bodyColor: Theme.backgroundColor
                    progress: appWindow.testProgress

                    readonly property var vp: viewportLoader.item
                    readonly property var target: {
                        const typing = TypingEngine.started && !TypingEngine.finished;
                        if (uiOverlay.mouseFollow && !typing && !TypingEngine.finished) {
                            return uiOverlay.mousePos;
                        }
                        if (TypingEngine.finished || !vp || vp.caretScenePos === undefined) {
                            return Qt.point(appWindow.width / 2, appWindow.height / 2);
                        }
                        return vp.caretScenePos;
                    }
                    onTargetChanged: watcher.lookAt(target.x, target.y)
                    Component.onCompleted: watcher.lookAt(target.x, target.y)
                }
            }

            TopJesus {
                id: topJesus
                onRequestFocusRestore: inputCatcher.forceActiveFocus()
            }
        }
    }

    function discordLabel() {
        const mode = appWindow.testMode;
        let label = "english " + TypingEngine.testDurationSeconds + "s";
        if (mode === "words") {
            label = "english " + TypingEngine.testWordCount + " words";
        } else if (mode === "quote") {
            label = "quote";
        } else if (mode === "repeat") {
            label = "repeating words";
        }
        if (TypingEngine.punctuationEnabled && mode !== "quote") {
            label += " + punctuation";
        }
        return label;
    }

    function syncDiscord() {
        Discord.setEnabled(Config.discordEnabled);
        if (!Config.discordEnabled) {
            return;
        }
        const label = appWindow.discordLabel();
        if (TypingEngine.finished) {
            Discord.setFinished(label, TypingEngine.wpm, TypingEngine.accuracy, TypingEngine.consistency);
        } else if (TypingEngine.started) {
            const timed = appWindow.testMode === "time";
            Discord.setTyping(Config.username, label, timed ? TypingEngine.testDurationSeconds : 0);
        } else {
            Discord.setIdle(label);
        }
    }

    Connections {
        target: TypingEngine
        function onStartedChanged() {
            appWindow.syncDiscord();
        }
        function onFinishedChanged() {
            appWindow.syncDiscord();
        }
    }
    Connections {
        target: Config
        function onConfigChanged() {
            appWindow.syncDiscord();
        }
    }

    function leaveAftermathThen(action) {
        appWindow.aftermathLeaving = true;
        leaveTimer.action = action;
        leaveTimer.restart();
    }
    function restartTest() {
        appWindow.resettingProgress = true;
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
        Qt.callLater(function () {
            appWindow.resettingProgress = false;
        });
    }
    function repeatTest() {
        appWindow.resettingProgress = true;
        appWindow.testMode = "repeat";
        TypingEngine.repeatTest();
        confetti.hasBurst = false;
        inputCatcher.forceActiveFocus();
        Qt.callLater(function () {
            appWindow.resettingProgress = false;
        });
    }
    function resultContext() {
        const mode = appWindow.testMode;
        if (mode === "quote") {
            return {
                mode: "quote",
                duration: 0,
                words: 0,
                punctuation: false
            };
        }
        if (mode === "words") {
            return {
                mode: "words",
                duration: 0,
                words: TypingEngine.testWordCount,
                punctuation: TypingEngine.punctuationEnabled
            };
        }
        return {
            mode: "english",
            duration: TypingEngine.testDurationSeconds,
            words: 0,
            punctuation: TypingEngine.punctuationEnabled
        };
    }
    function recordAndCelebrate() {
        if (appWindow.testMode === "repeat") {
            return;
        }
        const ctx = appWindow.resultContext();
        const wl = Config.currentWordList;
        const p = ctx.punctuation ? 1 : 0;

        const oldBest = History.bestWpmFor(ctx.mode, ctx.duration, p, ctx.words, wl);

        History.recordResult(TypingEngine.wpm, TypingEngine.rawWpm, TypingEngine.accuracy, TypingEngine.consistency, Math.round(TypingEngine.elapsedMs / 1000), TypingEngine.correctCount, TypingEngine.incorrectCount, TypingEngine.extraCount, TypingEngine.missedCount, ctx.mode, ctx.punctuation, ctx.words, wl);

        if (TypingEngine.wpm > 0 && TypingEngine.wpm > oldBest) {
            confetti.tryBurst();
        }
    }
}
