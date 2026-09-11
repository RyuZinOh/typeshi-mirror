pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    anchors.fill: parent

    property Item anchorItem: null
    property bool expanded: false

    signal accountSettingsRequested
    signal userStatsRequested
    signal requestFocusRestore

    function close() {
        if (!root.expanded) {
            return;
        }
        root.expanded = false;
        root.requestFocusRestore();
    }

    Rectangle {
        id: contextMenu
        width: 160
        height: menuColumn.implicitHeight + 12
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        radius: 8
        visible: root.expanded
        z: 1000

        x: root.anchorItem ? (root.anchorItem.x + root.anchorItem.width - width) : 0
        y: root.anchorItem ? (root.anchorItem.y - height - 8) : 0

        Column {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            MenuRow {
                label: "account settings"
                onClicked: {
                    root.expanded = false;
                    root.accountSettingsRequested();
                }
            }

            MenuRow {
                label: "user stats"
                onClicked: {
                    root.expanded = false;
                    root.userStatsRequested();
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.expanded
        enabled: root.expanded
        onClicked: root.close()
    }
}
