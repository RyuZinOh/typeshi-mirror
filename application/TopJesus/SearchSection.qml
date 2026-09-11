pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    required property var controller
    property bool active: false
    property string queryText: ""
    property var results: []
    property string placeholder: "search..."

    signal queryEdited(string text)
    signal closeRequested
    signal entryActivated(var entry)

    height: contentCol.implicitHeight

    property int navIndex: results.length > 0 ? 0 : -1

    onResultsChanged: {
        root.navIndex = root.results.length > 0 ? 0 : -1;
    }

    function clearInput() {
        textInput.text = "";
    }

    function focusInput() {
        textInput.forceActiveFocus();
    }

    function applyCurrentSelection() {
        if (root.navIndex < 0 || root.navIndex >= root.results.length) {
            return;
        }
        root.entryActivated(root.results[root.navIndex]);
    }

    Column {
        id: contentCol
        width: parent.width
        spacing: 8

        Item {
            id: inputRow
            width: parent.width
            height: 44

            TextInput {
                id: textInput
                anchors.fill: parent
                anchors.margins: 12
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: 16
                color: Theme.onSurface
                focus: root.active
                enabled: root.active

                onTextChanged: root.queryEdited(textInput.text)

                Keys.onEscapePressed: event => {
                    root.closeRequested();
                    event.accepted = true;
                }
                Keys.onDownPressed: event => {
                    if (root.results.length > 0) {
                        root.navIndex = Math.min(root.navIndex + 1, root.results.length - 1);
                    }
                    event.accepted = true;
                }
                Keys.onUpPressed: event => {
                    if (root.results.length > 0) {
                        root.navIndex = Math.max(root.navIndex - 1, 0);
                    }
                    event.accepted = true;
                }
                Keys.onReturnPressed: event => {
                    root.applyCurrentSelection();
                    event.accepted = true;
                }
                Keys.onEnterPressed: event => {
                    root.applyCurrentSelection();
                    event.accepted = true;
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: textInput.text.length === 0
                text: root.placeholder
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
            currentIndex: -1
            highlight: null

            delegate: ResultDelegate {
                width: listView.width
                isNav: index === root.navIndex
                onActivated: entry => {
                    root.navIndex = index;
                    root.entryActivated(entry);
                }
                onHovered: idx => {
                    root.navIndex = idx;
                }
            }
        }
    }
}
