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
    property bool inLobby: true
    property bool shootoutEnabled: false
    property bool showUserStats: false
    property bool showAccountSettings: false
    readonly property real testProgress: {
        if (!TypingEngine.started || TypingEngine.finished || appWindow.testMode === "multiplayer") {
            return 0;
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

    property int countdownSecondsLeft: 0

    property double multiplayerStartAtMs: 0
    property double multiplayerSeed: 0
    property int multiplayerDuration: 60
    property bool racingMultiplayer: false
    property string opponentDisconnectedMessage: ""
    property double opponentWpm: 0
    property int opponentCharIndex: 0
    property double opponentAccuracy: 0
    property double opponentConsistency: 0
    property int opponentWordExtraCount: 0
    property string opponentUsername: ""

    property bool rematchOfferPending: false
    property bool rematchRequestSent: false
    property string rematchDeclinedMessage: ""
    readonly property bool showCountdownOverlay: appWindow.testMode === "multiplayer" && appWindow.multiplayerStartAtMs > 0 && !appWindow.racingMultiplayer

    Connections {
        target: Multiplayer
        function onRaceStarting(seed, startAtMs, duration) {
            appWindow.testMode = "multiplayer";
            appWindow.racingMultiplayer = false;
            appWindow.multiplayerStartAtMs = startAtMs;
            appWindow.multiplayerSeed = seed;
            appWindow.multiplayerDuration = duration;
            appWindow.countdownToRaceStart();
        }
        function onOpponentLeft(username) {
            appWindow.opponentDisconnectedMessage = username + " has been disconnected";
        }
        function onOpponentProgress(username, wpm, charIndex, accuracy, consistency, wordExtraCount) {
            appWindow.opponentUsername = username;
            appWindow.opponentWpm = wpm;
            appWindow.opponentCharIndex = charIndex;
            appWindow.opponentAccuracy = accuracy;
            appWindow.opponentConsistency = consistency;
            appWindow.opponentWordExtraCount = wordExtraCount;
        }
        function onRematchOffered() {
            appWindow.rematchOfferPending = true;
        }
        function onRematchDeclined() {
            appWindow.rematchRequestSent = false;
            appWindow.rematchDeclinedMessage = "opponent declined the rematch";
            rematchDeclinedTimer.restart();
        }
    }

    Timer {
        id: rematchDeclinedTimer
        interval: 2500
        onTriggered: appWindow.rematchDeclinedMessage = ""
    }

    function countdownToRaceStart() {
        const waitMs = appWindow.multiplayerStartAtMs - Date.now();
        countdownTimer.interval = Math.max(0, waitMs);
        countdownTimer.start();
    }

    Timer {
        id: countdownTimer
        repeat: false
        onTriggered: {
            TypingEngine.startMultiplayerTest(Config.words, appWindow.multiplayerSeed, appWindow.multiplayerDuration);
            appWindow.racingMultiplayer = true;
            appWindow.rematchRequestSent = false;
            appWindow.rematchOfferPending = false;
            Multiplayer.notifyRaceStarted();
            inputCatcher.forceActiveFocus();
        }
    }
    Timer {
        id: countdownTickTimer
        interval: 100
        repeat: true
        running: appWindow.multiplayerStartAtMs > 0 && !appWindow.racingMultiplayer
        onTriggered: {
            const remaining = Math.ceil((appWindow.multiplayerStartAtMs - Date.now()) / 1000);
            appWindow.countdownSecondsLeft = Math.max(0, remaining);
        }
    }
    function leaveMultiplayer() {
        appWindow.testMode = "time";
        appWindow.racingMultiplayer = false;
        appWindow.multiplayerStartAtMs = 0;
        appWindow.countdownSecondsLeft = 0;
        appWindow.opponentDisconnectedMessage = "";
        appWindow.opponentWpm = 0;
        appWindow.opponentCharIndex = 0;
        appWindow.opponentAccuracy = 0;
        appWindow.opponentConsistency = 0;
        appWindow.opponentUsername = "";
        appWindow.rematchOfferPending = false;
        appWindow.rematchRequestSent = false;
        appWindow.rematchDeclinedMessage = "";
        Multiplayer.disconnectFromServer();
        multiplayerPanel.reset();
        Config.saveTestDefaults(appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
        appWindow.restartTest();
    }

    function requestRematch() {
        if (!Multiplayer.isRoomCreator) {
            return;
        }
        appWindow.opponentWpm = 0;
        appWindow.opponentCharIndex = 0;
        appWindow.opponentAccuracy = 0;
        appWindow.opponentConsistency = 0;
        appWindow.rematchRequestSent = true;
        Multiplayer.requestRematch();
    }

    function acceptRematch() {
        appWindow.opponentWpm = 0;
        appWindow.opponentCharIndex = 0;
        appWindow.opponentAccuracy = 0;
        appWindow.opponentConsistency = 0;
        appWindow.rematchOfferPending = false;
        Multiplayer.acceptRematch();
    }

    function declineRematch() {
        appWindow.rematchOfferPending = false;
        Multiplayer.declineRematch();
    }
    Timer {
        id: progressBroadcastTimer
        interval: 400
        repeat: true
        running: appWindow.racingMultiplayer && !TypingEngine.finished
        onTriggered: Multiplayer.sendProgress(TypingEngine.wpm, TypingEngine.canonicalCursorIndex(), TypingEngine.accuracy, TypingEngine.consistency, TypingEngine.currentWordExtraCount)
    }
    Connections {
        target: TypingEngine
        function onStartedChanged() {
            if (appWindow.testMode === "multiplayer" && TypingEngine.started) {
                Multiplayer.notifyRaceStarted();
            }
        }
        function onFinishedChanged() {
            if (appWindow.testMode === "multiplayer" && TypingEngine.finished && appWindow.racingMultiplayer) {
                Multiplayer.sendProgress(TypingEngine.wpm, TypingEngine.canonicalCursorIndex(), TypingEngine.accuracy, TypingEngine.consistency, TypingEngine.currentWordExtraCount);
            }
        }
    }

    ShaderScene {
        id: sceneLayer
        anchors.fill: parent
        rainEnabled: appWindow.rainEnabled

        Rectangle {
            id: opponentLeftBanner
            visible: appWindow.opponentDisconnectedMessage !== "" && appWindow.testMode === "multiplayer"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 20
            width: bannerText.width + 32
            height: 40
            radius: 10
            color: Theme.surfaceContainer
            border.color: Theme.errorColor
            border.width: 1
            z: 300

            Row {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    id: bannerText
                    text: appWindow.opponentDisconnectedMessage + " — press esc to leave"
                    font.pixelSize: 13
                    color: Theme.onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

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
                enabled: (!TypingEngine.finished || appWindow.showCountdownOverlay) && !appWindow.showUserStats && !appWindow.showAccountSettings
                visible: (!TypingEngine.finished || appWindow.showCountdownOverlay) && !appWindow.showUserStats && !appWindow.showAccountSettings

                KeyNavigation.tab: refreshButton

                Keys.onEscapePressed: {
                    if (appWindow.testMode === "multiplayer") {
                        appWindow.leaveMultiplayer();
                        return;
                    }
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
                        active: (appWindow.testMode !== "multiplayer" || appWindow.racingMultiplayer) && !appWindow.shootoutEnabled
                        sourceComponent: normalViewportComponent
                    }

                    Component {
                        id: normalViewportComponent
                        TypingViewport {
                            passageFontSize: appWindow.passageFontSize
                            linesVisible: appWindow.linesVisible
                            dimmed: refreshButton.activeFocus
                            opponentCharIndex: appWindow.racingMultiplayer ? appWindow.opponentCharIndex : -1
                            opponentWordExtraCount: appWindow.racingMultiplayer ? appWindow.opponentWordExtraCount : 0
                            opponentUsername: appWindow.opponentUsername
                        }
                    }

                    MultiplayerPanel {
                        id: multiplayerPanel
                        anchors.top: parent.top
                        anchors.topMargin: 60
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: appWindow.testMode === "multiplayer" && !appWindow.racingMultiplayer
                        countdownSecondsLeft: appWindow.countdownSecondsLeft
                        onReadyToPlay: {}
                    }

                    RefreshButton {
                        id: refreshButton
                        anchors.top: viewportLoader.bottom
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: !topJesus.isOpen && appWindow.testMode !== "multiplayer"
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
                active: appWindow.shootoutEnabled && appWindow.testMode !== "multiplayer" && !TypingEngine.finished

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

            Component {
                id: multiplayerAftermathComponent
                MultiplayerAftermath {
                    opponentUsername: appWindow.opponentUsername
                    opponentWpm: appWindow.opponentWpm
                    opponentAccuracy: appWindow.opponentAccuracy
                    opponentConsistency: appWindow.opponentConsistency
                    isRoomCreator: Multiplayer.isRoomCreator
                    rematchOfferPending: appWindow.rematchOfferPending
                    rematchRequestSent: appWindow.rematchRequestSent
                    rematchDeclinedMessage: appWindow.rematchDeclinedMessage
                    onRestartRequested: appWindow.requestRematch()
                    onAcceptRequested: appWindow.acceptRematch()
                    onDeclineRequested: appWindow.declineRematch()
                }
            }

            Loader {
                id: aftermathLoader
                anchors.fill: parent
                z: 70
                active: TypingEngine.finished && !appWindow.showCountdownOverlay && !appWindow.showUserStats && !appWindow.showAccountSettings
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

                        if (appWindow.testMode !== "multiplayer" && appWindow.testMode !== "repeat") {
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
                sourceComponent: appWindow.testMode === "multiplayer" ? multiplayerAftermathComponent : soloAftermathComponent
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
        if (appWindow.testMode === "multiplayer") {
            return;
        }
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
