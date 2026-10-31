import QtQuick
import Ryu.Extraa
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
    MaterialSegmentedButton {
        id: primaryControl
        height: root.controlCellHeight + 10
        enabled: root.appWindow.testMode === "time" || root.appWindow.testMode === "words"

        readonly property var options: root.appWindow.testMode === "words" ? [10, 25, 50, 100] : [15, 30, 60, 120]
        readonly property var selectedValue: root.appWindow.testMode === "words" ? TypingEngine.testWordCount : TypingEngine.testDurationSeconds
        readonly property string suffix: root.appWindow.testMode === "words" ? "" : "s"

        labels: options.map(v => v + suffix)
        selectionMode: MaterialSegmentedButton.Single
        currentIndex: options.indexOf(selectedValue)

        color: Theme.surfaceContainer
        checkedColor: Theme.primaryColor
        textColor: Theme.onSurfaceVariant
        checkedTextColor: Theme.onPrimary
        borderWidth: 1
        borderColor: Theme.outlineVariant
        font.family: Config.currentFont
        showCheck: true
        checkIconSource: "assets/icons/check.svg"

        onClicked: index => {
            const value = options[index];
            if (root.appWindow.testMode === "words") {
                TypingEngine.setTestWordCount(value);
            } else {
                TypingEngine.setTestDurationSeconds(value);
            }
            Config.saveTestDefaults(root.appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
            root.appWindow.restartTest();
        }
    }
    MaterialButtonGroup {
        id: optionGroup
        height: root.controlCellHeight + 10
        spacing: 6
        sizeStyle: MaterialButtonGroup.Small
        labels: ["1k", "words", "punctuation", "quote"]
        selectionMode: MaterialButtonGroup.Multiple
        checkedIndices: {
            const list = [];
            if (Config.currentWordList === "english1k")
                list.push(0);
            if (root.appWindow.testMode === "words")
                list.push(1);
            if (TypingEngine.punctuationEnabled)
                list.push(2);
            if (root.appWindow.testMode === "quote")
                list.push(3);
            return list;
        }

        color: Theme.surfaceContainer
        checkedColor: Theme.primaryColor
        textColor: Theme.onSurfaceVariant
        checkedTextColor: Theme.onPrimary
        borderWidth: 1
        borderColor: Theme.outlineVariant
        font.family: Config.currentFont

        onToggled: (index, checked) => {
            const quote = root.appWindow.testMode === "quote";
            if (quote && index !== 3) {
                optionGroup.setChecked(index, !checked);
                return;
            }

            if (index === 0) {
                Config.setWordList(Config.currentWordList === "english1k" ? "english" : "english1k");
            } else if (index === 1) {
                root.appWindow.testMode = root.appWindow.testMode === "words" ? "time" : "words";
            } else if (index === 2) {
                TypingEngine.setPunctuationEnabled(!TypingEngine.punctuationEnabled);
            } else if (index === 3) {
                root.appWindow.testMode = quote ? "time" : "quote";
            }

            Config.saveTestDefaults(root.appWindow.testMode, TypingEngine.testDurationSeconds, TypingEngine.testWordCount, TypingEngine.punctuationEnabled);
            root.appWindow.restartTest();
        }
    }
}
