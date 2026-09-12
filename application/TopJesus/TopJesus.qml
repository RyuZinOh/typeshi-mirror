pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    anchors.fill: parent
    z: 500

    property bool isOpen: false
    property bool closing: false
    property bool inputMode: false
    property string queryText: ""
    property string inputText: ""
    property var inputSource: null
    property var results: []
    property real targetWidth: root.minWidth

    signal requestFocusRestore

    readonly property int minWidth: 340
    readonly property string defaultPlaceholder: "search..."

    property var sources: [
        {
            prefix: "font:",
            label: "Font family",
            width: 520,
            items: function () {
                return Config.availableFonts();
            },
            currentValue: function () {
                return Config.currentFont;
            },
            apply: function (name) {
                Config.setFont(name);
            },
            preview: function (item) {
                return item;
            }
        },
        {
            label: "Font size",
            width: 340,
            numeric: true,
            apply: function (value) {
                Config.setFontSize(value);
            },
            currentValue: function () {
                return Config.fontSize;
            },
            preview: function (item) {
                return Config.currentFont;
            }
        },
        {
            prefix: "theme:",
            label: "Theme",
            width: 460,
            items: function () {
                return Config.availableThemes();
            },
            currentValue: function () {
                return Config.currentTheme;
            },
            apply: function (name) {
                Config.setTheme(name, Config.currentVariant);
            },
            preview: function (item) {
                return Config.currentFont;
            }
        },
        {
            prefix: "variant:",
            label: "Light/Dark",
            width: 340,
            items: function () {
                return ["dark", "light"];
            },
            currentValue: function () {
                return Config.currentVariant;
            },
            apply: function (value) {
                Config.setTheme(Config.currentTheme, value);
            },
            preview: function (item) {
                return Config.currentFont;
            }
        },
        {
            prefix: "custom:",
            label: "Custom theme",
            width: 380,
            items: function () {
                return ["on", "off"];
            },
            currentValue: function () {
                return Config.currentTheme === "custom" ? "on" : "off";
            },
            apply: function (value) {
                Config.setCustomTheme(value === "on");
            },
            preview: function (item) {
                return Config.currentFont;
            }
        },
        {
            prefix: "progressbar:",
            label: "Border progress",
            width: 380,
            items: function () {
                return ["on", "off"];
            },
            currentValue: function () {
                return Config.borderProgressEnabled ? "on" : "off";
            },
            apply: function (value) {
                Config.setBorderProgressEnabled(value === "on");
            },
            preview: function (item) {
                return Config.currentFont;
            }
        },
        {
            prefix: "tape:",
            label: "Tape mode",
            width: 380,
            items: function () {
                return ["on", "off"];
            },
            currentValue: function () {
                return Config.tapeModeEnabled ? "on" : "off";
            },
            apply: function (value) {
                Config.setTapeModeEnabled(value === "on");
            },
            preview: function (item) {
                return Config.currentFont;
            }
        }
    ]
    function computeTargetWidth() {
        if (root.results.length === 0) {
            return root.minWidth;
        }
        let widest = root.minWidth;
        for (const source of root.sources) {
            const hasResultsFromSource = root.results.some(entry => entry.source === source);
            if (hasResultsFromSource) {
                widest = Math.max(widest, source.width);
            }
        }
        return widest;
    }

    function makeEntry(name, source) {
        return {
            label: name,
            categoryLabel: source.label,
            source: source,
            action: function () {
                source.apply(name);
            }
        };
    }

    function rebuildResults() {
        const raw = root.queryText.trim ? root.queryText.trim() : root.queryText;
        if (raw.length === 0) {
            root.results = [];
            root.targetWidth = root.minWidth;
            return;
        }

        const lower = raw.toLowerCase();
        const explicit = root.sources.find(s => s.prefix && lower.startsWith(s.prefix));
        const candidates = explicit ? [explicit] : root.sources;

        let merged = [];
        for (const source of candidates) {
            if (source.numeric) {
                const term = explicit ? raw.slice(source.prefix ? source.prefix.length : 0) : raw;
                const matches = FuzzyFinder.search(term, [source.label]);
                if (matches.length > 0) {
                    merged.push({
                        label: "size " + source.currentValue(),
                        categoryLabel: source.label,
                        source: source,
                        action: function () {
                            root.enterInputMode(source);
                        }
                    });
                }
                continue;
            }

            const term = explicit ? raw.slice(source.prefix.length) : raw;
            const showAll = term.length === 0 || source.label.toLowerCase().startsWith(lower);
            const names = showAll ? source.items().slice().sort((a, b) => a.localeCompare(b)) : FuzzyFinder.search(term, source.items());

            merged = merged.concat(names.map(name => root.makeEntry(name, source)));
        }
        root.results = merged;
        root.targetWidth = root.computeTargetWidth();
    }

    function open() {
        root.closing = false;
        root.inputMode = false;
        root.queryText = "";
        searchSection.clearInput();
        rebuildResults();
        root.isOpen = true;
        root.targetWidth = root.minWidth;
        searchSection.focusInput();
    }

    function close() {
        if (root.closing || !root.isOpen) {
            return;
        }
        root.closing = true;
        closeSequence.start();
    }

    function enterInputMode(source) {
        root.inputSource = source;
        root.inputText = "" + source.currentValue();
        root.inputMode = true;
        root.targetWidth = source.width;
        Qt.callLater(function () {
            inputSection.focusInput();
        });
    }

    function exitInputMode() {
        root.inputMode = false;
        root.inputSource = null;
        root.rebuildResults();
        Qt.callLater(function () {
            searchSection.focusInput();
        });
    }

    function applyInputValue() {
        if (!root.inputSource) {
            return;
        }
        const n = parseInt(root.inputText, 10);
        if (!isNaN(n)) {
            root.inputSource.apply(n);
        }
        root.close();
    }

    function applySelected() {
        searchSection.applyCurrentSelection();
    }

    SequentialAnimation {
        id: closeSequence
        ScriptAction {
            script: root.isOpen = false
        }
        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: {
                root.inputMode = false;
                root.inputSource = null;
                root.queryText = "";
                searchSection.clearInput();
                root.rebuildResults();
                root.targetWidth = root.minWidth;
                root.closing = false;
                root.requestFocusRestore();
            }
        }
    }

    visible: isOpen || bg.opacity > 0.01

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.scrimColor
        opacity: root.isOpen ? 0.55 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.isOpen ? 90 : 70
        opacity: root.isOpen ? 1 : 0
        width: root.isOpen ? root.targetWidth : root.minWidth
        height: root.isOpen ? (root.inputMode ? inputSection.height + 20 : searchSection.height + 20) : 44
        radius: 22
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        clip: true

        Behavior on y {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuart
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuart
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuart
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        SearchSection {
            id: searchSection
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            controller: root
            active: root.isOpen && !root.closing && !root.inputMode
            queryText: root.queryText
            results: root.results
            placeholder: root.defaultPlaceholder
            opacity: root.inputMode ? 0 : 1
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }

            onQueryEdited: text => {
                root.queryText = text;
                root.rebuildResults();
            }
            onCloseRequested: root.close()
            onEntryActivated: entry => {
                entry.action();
                if (!root.inputMode) {
                    root.close();
                }
            }
        }

        InputSection {
            id: inputSection
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            value: root.inputText
            opacity: root.inputMode ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }

            onValueEdited: text => root.inputText = text
            onCancelled: root.exitInputMode()
            onSubmitted: root.applyInputValue()
        }
    }
}
