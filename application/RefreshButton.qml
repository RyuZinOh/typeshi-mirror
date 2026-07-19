pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root

    property bool dimmedUnlessFocused: true
    property bool alwaysVisible: false
    property bool hoverRotates: false
    property int iconSize: 28
    property Item tabTarget: null

    signal activated

    width: iconSize + 12
    height: iconSize + 12
    activeFocusOnTab: !root.alwaysVisible

    opacity: (root.alwaysVisible || !root.dimmedUnlessFocused || root.activeFocus) ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    KeyNavigation.tab: root.tabTarget

    Icon {
        id: refreshIcon
        anchors.centerIn: parent
        property int turns: 0
        rotation: root.hoverRotates ? (refreshArea.containsMouse ? 180 : 0) : turns * 360
        source: "assets/icons/refresh.svg"
        iconSize: root.iconSize
        color: (root.activeFocus || refreshArea.containsMouse) ? Theme.primaryColor : Theme.onSurfaceVariant

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on rotation {
            NumberAnimation {
                duration: root.hoverRotates ? 300 : 1200
                easing.type: Easing.OutCubic
            }
        }
    }
    MouseArea {
        id: refreshArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.hoverRotates) {
                refreshIcon.turns++;
            }
            root.activated();
        }
    }
    Keys.onReturnPressed: {
        if (!root.hoverRotates) {
            refreshIcon.turns++;
        }
        root.activated();
    }
    Keys.onEnterPressed: {
        if (!root.hoverRotates) {
            refreshIcon.turns++;
        }
        root.activated();
    }
}
