pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

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

    function clearInput() {
        textInput.text = "";
    }

    function focusInput() {
        textInput.forceActiveFocus();
    }

    function applyCurrentSelection() {
        if (listView.currentIndex < 0 || listView.currentIndex >= root.results.length) {
            return;
        }
        root.entryActivated(root.results[listView.currentIndex]);
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
            currentIndex: root.results.length > 0 ? 0 : -1

            highlightFollowsCurrentItem: true
            highlightMoveDuration: 80
            highlightResizeDuration: 0

            highlight: Rectangle {
                radius: 8
                color: Theme.surfaceContainerHigh
            }

            delegate: ResultDelegate {
                width: listView.width
                onActivated: entry => {
                    listView.currentIndex = index;
                    root.entryActivated(entry);
                }
                onHovered: idx => listView.currentIndex = idx
            }
        }
    }
}
