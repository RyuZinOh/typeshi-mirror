import QtQuick
import typeShitter

Row {
    id: root
    required property var appWindow
    readonly property int controlCellHeight: 36
    spacing: 12

    opacity: TypingEngine.started ? 0 : 1
    enabled: !TypingEngine.started
    Behavior on opacity {
        NumberAnimation {
            duration: 150
        }
    }

    SegmentedControl {
        id: primaryControl
        enabled: root.appWindow.testMode === "time" || root.appWindow.testMode === "words"
        options: root.appWindow.testMode === "words" ? [10, 25, 50, 100] : [15, 30, 60, 120]
        selectedValue: root.appWindow.testMode === "words" ? TypingEngine.testWordCount : TypingEngine.testDurationSeconds
        suffix: root.appWindow.testMode === "words" ? "" : "s"
        cellHeight: root.controlCellHeight
        onSelected: value => {
            if (root.appWindow.testMode === "words") {
                TypingEngine.setTestWordCount(value);
            } else {
                TypingEngine.setTestDurationSeconds(value);
            }
            Config.saveTestDefaults(root.appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
            root.appWindow.restartTest();
        }
    }

    ToggleChip {
        id: wordList1kChip
        label: "1k"
        chipHeight: root.controlCellHeight + 10
        enabled: root.appWindow.testMode !== "quote" && root.appWindow.testMode !== "multiplayer"
        active: Config.currentWordList === "english1k"
        onToggled: {
            Config.setWordList(Config.currentWordList === "english1k" ? "english" : "english1k");
            root.appWindow.restartTest();
        }
    }

    ToggleChip {
        id: wordsChip
        label: "words"
        chipHeight: root.controlCellHeight + 10
        enabled: root.appWindow.testMode !== "quote" && root.appWindow.testMode !== "multiplayer"
        active: root.appWindow.testMode === "words"
        onToggled: {
            root.appWindow.testMode = root.appWindow.testMode === "words" ? "time" : "words";
            Config.saveTestDefaults(root.appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
            root.appWindow.restartTest();
        }
    }

    ToggleChip {
        id: punctuationChip
        label: "punctuation"
        chipHeight: root.controlCellHeight + 10
        enabled: root.appWindow.testMode !== "quote" && root.appWindow.testMode !== "multiplayer"
        active: TypingEngine.punctuationEnabled
        onToggled: {
            TypingEngine.setPunctuationEnabled(!TypingEngine.punctuationEnabled);
            Config.saveTestDefaults(root.appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
            root.appWindow.restartTest();
        }
    }

    ToggleChip {
        id: quoteChip
        label: "quote"
        enabled: root.appWindow.testMode !== "multiplayer"
        chipHeight: root.controlCellHeight + 10
        active: root.appWindow.testMode === "quote"
        onToggled: {
            root.appWindow.testMode = root.appWindow.testMode === "quote" ? "time" : "quote";
            if (root.appWindow.testMode === "quote") {
                root.appWindow.shootoutEnabled = false;
            }
            Config.saveTestDefaults(root.appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
            root.appWindow.restartTest();
        }
    }

    ToggleChip {
        id: multiplayerChip
        label: "multiplayer"
        chipHeight: root.controlCellHeight + 10
        active: root.appWindow.testMode === "multiplayer"
        onToggled: {
            const enteringMultiplayer = root.appWindow.testMode !== "multiplayer";
            if (enteringMultiplayer) {
                root.appWindow.testMode = "multiplayer";
                if (!Multiplayer.connected) {
                    Multiplayer.connectToServer("wss://typeshi-relay.onrender.com/ws");
                }
            } else {
                root.appWindow.leaveMultiplayer();
            }
        }
    }
}
