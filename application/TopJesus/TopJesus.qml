pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    anchors.fill: parent
    z: 500

    property bool isOpen: false
    property bool closing: false
    property string queryText: ""

    signal requestFocusRestore

    property var sources: [
        {
            prefix: "font:",
            label: "Font family",
            width: 480,
            items: function () {
                return Config.availableFonts();
            },
            apply: function (name) {
                Config.setFont(name);
            },
            preview: function (item) {
                return item;
            }
        },
        {
            prefix: "theme:",
            label: "Theme",
            width: 420,
            items: function () {
                return Config.availableThemes();
            },
            apply: function (name) {
                Config.setTheme(name, Config.currentVariant);
            },
            preview: function (item) {
                return Config.currentFont;
            }
        },
        {
            prefix: "custom:",
            label: "Custom theme",
            width: 340,
            items: function () {
                return ["on", "off"];
            },
            apply: function (value) {
                Config.setCustomTheme(value === "on");
            },
            preview: function (item) {
                return Config.currentFont;
            }
        }
    ]

    readonly property int minWidth: 340
    readonly property string defaultPlaceholder: "search..."

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

    property real targetWidth: root.minWidth

    function open() {
        root.closing = false;
        root.queryText = "";
        input.text = "";
        rebuildResults();
        root.isOpen = true;
        root.targetWidth = root.minWidth;
        input.forceActiveFocus();
    }

    function close() {
        if (root.closing || !root.isOpen) {
            return;
        }
        root.closing = true;
        closeSequence.start();
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
                root.queryText = "";
                input.text = "";
                root.rebuildResults();
                root.targetWidth = root.minWidth;
                root.closing = false;
                root.requestFocusRestore();
            }
        }
    }

    property var results: []

    function rebuildResults() {
        const raw = root.queryText.trim ? root.queryText.trim() : root.queryText;
        if (raw.length === 0) {
            root.results = [];
            root.targetWidth = root.minWidth;
            listView.currentIndex = -1;
            return;
        }

        const lower = raw.toLowerCase();
        const explicit = root.sources.find(s => lower.startsWith(s.prefix));
        const candidates = explicit ? [explicit] : root.sources;

        let merged = [];
        for (const source of candidates) {
            const term = explicit ? raw.slice(source.prefix.length) : raw;
            const showAll = term.length === 0 || source.label.toLowerCase().startsWith(lower);

            const names = showAll ? source.items().slice().sort((a, b) => a.localeCompare(b)) : FuzzyFinder.search(term, source.items());

            merged = merged.concat(names.map(name => root.makeEntry(name, source)));
        }
        root.results = merged;
        root.targetWidth = root.computeTargetWidth();

        listView.currentIndex = root.results.length > 0 ? 0 : -1;
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
        height: root.isOpen ? contentCol.implicitHeight + 20 : 44
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

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            Item {
                id: inputRow
                width: parent.width
                height: 44

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.margins: 12
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 16
                    color: Theme.onSurface
                    focus: root.isOpen
                    enabled: root.isOpen && !root.closing

                    onTextChanged: {
                        root.queryText = input.text;
                        root.rebuildResults();
                    }

                    Keys.onEscapePressed: event => {
                        root.close();
                        event.accepted = true;
                    }
                    Keys.onDownPressed: event => {
                        if (listView.count > 0) {
                            listView.currentIndex = Math.min(listView.currentIndex + 1, listView.count - 1);
                        }
                        event.accepted = true;
                    }
                    Keys.onUpPressed: event => {
                        if (listView.count > 0) {
                            listView.currentIndex = Math.max(listView.currentIndex - 1, 0);
                        }
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: event => {
                        root.applySelected();
                        event.accepted = true;
                    }
                    Keys.onEnterPressed: event => {
                        root.applySelected();
                        event.accepted = true;
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    text: root.defaultPlaceholder
                    font.pixelSize: 16
                    color: Theme.onSurfaceVariant
                    opacity: 0.5
                }
            }

            ListView {
                id: listView
                width: parent.width
                implicitHeight: Math.min(contentHeight, 320)
                spacing: 2
                clip: true
                visible: root.results.length > 0
                model: root.results
                currentIndex: 0

                highlightFollowsCurrentItem: true
                highlightMoveDuration: 80
                highlightResizeDuration: 0

                highlight: Rectangle {
                    radius: 8
                    color: Theme.surfaceContainerHigh
                }

                delegate: Item {
                    id: resultRow
                    required property var modelData
                    required property int index
                    width: listView.width
                    height: 40

                    readonly property string previewFamily: resultRow.modelData.source.preview(resultRow.modelData.label)
                    readonly property bool showPalette: resultRow.modelData.source.label === "Theme"
                    readonly property var paletteColors: resultRow.showPalette ? Config.previewColors(resultRow.modelData.label, Config.currentVariant) : ({})

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: resultRow.modelData.categoryLabel
                            font.pixelSize: 13
                            font.family: resultRow.previewFamily
                            color: Theme.onSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: ">"
                            font.pixelSize: 13
                            font.family: resultRow.previewFamily
                            color: Theme.onSurfaceVariant
                            opacity: 0.6
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: resultLabel
                            text: resultRow.modelData.label
                            font.pixelSize: 14
                            font.family: resultRow.previewFamily
                            color: Theme.onSurface
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            visible: resultRow.showPalette
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 3
                                color: resultRow.paletteColors.primary ?? "transparent"
                                border.color: Theme.outlineVariant
                                border.width: 1
                            }
                            Rectangle {
                                width: 14
                                height: 14
                                radius: 3
                                color: resultRow.paletteColors.secondary ?? "transparent"
                                border.color: Theme.outlineVariant
                                border.width: 1
                            }
                            Rectangle {
                                width: 14
                                height: 14
                                radius: 3
                                color: resultRow.paletteColors.tertiary ?? "transparent"
                                border.color: Theme.outlineVariant
                                border.width: 1
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: mouse => {
                            if (mouse.x !== 0 || mouse.y !== 0) {
                                listView.currentIndex = resultRow.index;
                            }
                        }
                        onClicked: {
                            listView.currentIndex = resultRow.index;
                            root.applySelected();
                        }
                    }
                }
            }
        }
    }

    function applySelected() {
        if (listView.currentIndex < 0 || listView.currentIndex >= root.results.length) {
            return;
        }
        root.results[listView.currentIndex].action();
        root.close();
    }
}
