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
    property bool crtEnabled: false
    property bool inLobby: true

    Component.onCompleted: {
        appWindow.testMode = Config.lastMode;
        TypingEngine.setTestDurationSeconds(Config.lastDuration);
        TypingEngine.setTestWordCount(Config.lastWordCount);
        TypingEngine.setPunctuationEnabled(Config.lastPunctuation);
        appWindow.restartTest();
        inputCatcher.forceActiveFocus();
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

    Item {
        id: sceneLayer
        anchors.fill: parent

        layer.enabled: appWindow.crtEnabled
        layer.smooth: true
        layer.effect: ShaderEffect {
            property variant source
            property vector2d resolution: Qt.vector2d(width, height)
            property real scanlineIntensity: 1.1
            property real vignetteStrength: 0.18
            property real glowThreshold: 0.1
            property real glowIntensity: 1.0

            vertexShader: "assets/shaders/crt.vert.qsb"
            fragmentShader: "assets/shaders/crt.frag.qsb"
        }
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
                enabled: !TypingEngine.finished || appWindow.showCountdownOverlay
                visible: !TypingEngine.finished || appWindow.showCountdownOverlay

                KeyNavigation.tab: refreshButton

                Keys.onEscapePressed: {
                    if (appWindow.testMode === "multiplayer") {
                        appWindow.leaveMultiplayer();
                    }
                }

                Keys.onPressed: event => {
                    if (themePicker.visible) {
                        return;
                    }
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

                        readonly property int controlCellHeight: 36

                        opacity: TypingEngine.started ? 0 : 1
                        enabled: !TypingEngine.started
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                        SegmentedControl {
                            id: primaryControl
                            enabled: appWindow.testMode === "time" || appWindow.testMode === "words"
                            options: appWindow.testMode === "words" ? [10, 25, 50, 100] : [15, 30, 60, 120]
                            selectedValue: appWindow.testMode === "words" ? TypingEngine.testWordCount : TypingEngine.testDurationSeconds
                            suffix: appWindow.testMode === "words" ? "" : "s"
                            cellHeight: modeRow.controlCellHeight
                            onSelected: value => {
                                if (appWindow.testMode === "words") {
                                    TypingEngine.setTestWordCount(value);
                                } else {
                                    TypingEngine.setTestDurationSeconds(value);
                                }
                                Config.saveTestDefaults(appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
                                appWindow.restartTest();
                            }
                        }
                        ToggleChip {
                            id: wordList1kChip
                            label: "1k"
                            chipHeight: modeRow.controlCellHeight + 10
                            enabled: appWindow.testMode !== "quote" && appWindow.testMode !== "multiplayer"
                            active: Config.currentWordList === "english1k"
                            onToggled: {
                                Config.setWordList(Config.currentWordList === "english1k" ? "english" : "english1k");
                                appWindow.restartTest();
                            }
                        }
                        ToggleChip {
                            id: wordsChip
                            label: "words"
                            chipHeight: modeRow.controlCellHeight + 10
                            enabled: appWindow.testMode !== "quote" && appWindow.testMode !== "multiplayer"
                            active: appWindow.testMode === "words"
                            onToggled: {
                                appWindow.testMode = appWindow.testMode === "words" ? "time" : "words";
                                Config.saveTestDefaults(appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
                                appWindow.restartTest();
                            }
                        }

                        ToggleChip {
                            id: punctuationChip
                            label: "punctuation"
                            chipHeight: modeRow.controlCellHeight + 10
                            enabled: appWindow.testMode !== "quote" && appWindow.testMode !== "multiplayer"
                            active: TypingEngine.punctuationEnabled
                            onToggled: {
                                TypingEngine.setPunctuationEnabled(!TypingEngine.punctuationEnabled);
                                Config.saveTestDefaults(appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
                                appWindow.restartTest();
                            }
                        }

                        ToggleChip {
                            id: quoteChip
                            label: "quote"
                            enabled: appWindow.testMode !== "multiplayer"
                            chipHeight: modeRow.controlCellHeight + 10
                            active: appWindow.testMode === "quote"
                            onToggled: {
                                appWindow.testMode = appWindow.testMode === "quote" ? "time" : "quote";
                                Config.saveTestDefaults(appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
                                appWindow.restartTest();
                            }
                        }
                        ToggleChip {
                            id: multiplayerChip
                            label: "multiplayer"
                            chipHeight: modeRow.controlCellHeight + 10
                            active: appWindow.testMode === "multiplayer"
                            onToggled: {
                                const enteringMultiplayer = appWindow.testMode !== "multiplayer";
                                if (enteringMultiplayer) {
                                    appWindow.testMode = "multiplayer";
                                    if (!Multiplayer.connected) {
                                        // Multiplayer.connectToServer("ws://localhost:8080/ws");
                                        Multiplayer.connectToServer("wss://typeshi-relay.onrender.com/ws");
                                    }
                                } else {
                                    appWindow.leaveMultiplayer();
                                }
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
                        visible: appWindow.testMode !== "multiplayer" || appWindow.racingMultiplayer
                        opponentCharIndex: appWindow.racingMultiplayer ? appWindow.opponentCharIndex : -1
                        opponentWordExtraCount: appWindow.racingMultiplayer ? appWindow.opponentWordExtraCount : 0
                        opponentUsername: appWindow.opponentUsername
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
                        anchors.top: viewport.bottom
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: !themePicker.visible && appWindow.testMode !== "multiplayer"
                        dimmedUnlessFocused: TypingEngine.started
                        tabTarget: inputCatcher
                        onActivated: appWindow.restartTest()
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
                active: TypingEngine.finished && !appWindow.showCountdownOverlay
                opacity: (TypingEngine.finished && !appWindow.showCountdownOverlay) ? 1 : 0
                scale: (TypingEngine.finished && !appWindow.showCountdownOverlay) ? 1 : 0
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

                        if (appWindow.testMode !== "multiplayer") {
                            const oldBest = appWindow.testMode === "words" ? History.bestWpmForWords(words, punct ? 1 : 0, Config.currentWordList) : History.bestWpmFor(mode, dur, punct ? 1 : 0, -1, Config.currentWordList);

                            History.recordResult(TypingEngine.wpm, TypingEngine.rawWpm, TypingEngine.accuracy, TypingEngine.consistency, Math.round(TypingEngine.elapsedMs / 1000), TypingEngine.correctCount, TypingEngine.incorrectCount, TypingEngine.extraCount, TypingEngine.missedCount, mode, punct, words, Config.currentWordList);

                            if (TypingEngine.wpm > 0 && TypingEngine.wpm > oldBest) {
                                confetti.tryBurst();
                            }
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
                sourceComponent: appWindow.testMode === "multiplayer" ? multiplayerAftermathComponent : soloAftermathComponent
            }
        }

        Item {
            id: uiOverlay
            anchors.fill: parent
            z: 400

            Item {
                id: profileTrigger
                anchors.bottom: parent.bottom
                anchors.right: themeTrigger.left
                anchors.rightMargin: 16
                anchors.margins: 20
                width: nameLabel.width + avatarImg.width + 8
                height: 28

                Row {
                    anchors.fill: parent
                    spacing: 8

                    Avatar {
                        id: avatarImg
                        anchors.verticalCenter: parent.verticalCenter
                        size: 48
                    }

                    Text {
                        id: nameLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.username
                        font.pixelSize: 13
                        color: profileTriggerArea.containsMouse ? Theme.primaryColor : Theme.onSurfaceVariant

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }
                }

                MouseArea {
                    id: profileTriggerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: profileEditor.open()
                }
            }
            Item {
                id: themeTrigger
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 20
                width: 28
                height: 28

                Icon {
                    anchors.centerIn: parent
                    source: "assets/icons/palette.svg"
                    iconSize: 20
                    color: themeTriggerArea.containsMouse ? Theme.primaryColor : Theme.onSurfaceVariant

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                MouseArea {
                    id: themeTriggerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: themePicker.open()
                }
            }

            ToggleChip {
                id: crtTrigger
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 20
                label: "CRT mode"
                active: appWindow.crtEnabled
                onToggled: {
                    appWindow.crtEnabled = !appWindow.crtEnabled;
                }
            }

            ThemePicker {
                id: themePicker
            }
            ProfileEditor {
                id: profileEditor
            }
        }
    }

    function restartTest() {
        if (appWindow.testMode === "multiplayer") {
            return;
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
}
