pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    property bool dimmedUnlessFocused: true
    property bool alwaysVisible: false
    property bool hoverRotates: false
    property int iconSize: 28
    property Item tabTarget: null
    property Item typingCatcher: null

    signal activated

    width: iconSize + 12
    height: iconSize + 12
    activeFocusOnTab: true
    focus: true

    KeyNavigation.tab: root.tabTarget

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            return;
        }
        if (!root.typingCatcher) {
            return;
        }
        if (event.key === Qt.Key_Backspace) {
            root.typingCatcher.forceActiveFocus();
            TypingEngine.deleteBackward(event.modifiers & Qt.ControlModifier);
            event.accepted = true;
            return;
        }
        if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            root.typingCatcher.forceActiveFocus();
            TypingEngine.typeCharacter(event.text);
            event.accepted = true;
        }
    }

    opacity: (root.alwaysVisible || !root.dimmedUnlessFocused || root.activeFocus) ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }

    property bool keyRotatePulse: false

    Icon {
        id: refreshIcon
        anchors.centerIn: parent
        property int turns: 0
        rotation: root.hoverRotates ? ((refreshArea.containsMouse || root.keyRotatePulse) ? 180 : 0) : turns * 360
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
    Keys.onReturnPressed: root.triggerViaKeyboard()
    Keys.onEnterPressed: root.triggerViaKeyboard()

    function triggerViaKeyboard() {
        if (root.hoverRotates) {
            root.keyRotatePulse = true;
            keyPulseDelayTimer.restart();
        } else {
            refreshIcon.turns++;
            root.activated();
        }
    }

    Timer {
        id: keyPulseDelayTimer
        interval: 220
        onTriggered: root.activated()
    }
}
