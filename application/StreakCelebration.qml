pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root
    z: 350

    readonly property var frames: ["assets/sailorGirl/00000+00673+1620.png", "assets/sailorGirl/00000+00674+1621.png", "assets/sailorGirl/00000+00675+1622.png", "assets/sailorGirl/00000+00676+1623.png", "assets/sailorGirl/00000+00677+1624.png", "assets/sailorGirl/00000+00678+1625.png", "assets/sailorGirl/00000+00679+1626.png", "assets/sailorGirl/00000+00680+1627.png", "assets/sailorGirl/00000+00681+1628.png", "assets/sailorGirl/00000+00682+1629.png"]

    property int currentIndex: 0
    property int holdMs: 500
    property int fadeMs: 350
    property int streakValue: 0
    property bool active: false
    property bool initialImageReady: false
    property int loopsCompleted: 0
    property int maxLoops: 1

    signal finished

    function start(streak) {
        root.streakValue = streak;
        root.currentIndex = 0;
        root.loopsCompleted = 0;
        root.initialImageReady = false;
        congratsText.visibleChars = 0;
        bgImage.source = "" + root.frames[0];
        root.active = true;
    }
    function stop() {
        root.active = false;
        root.finished();
    }

    width: 340
    height: 340
    visible: opacity > 0.01

    opacity: root.active ? 1 : 0
    anchors.bottomMargin: root.active ? 0 : -(height + 20)

    Behavior on anchors.bottomMargin {
        NumberAnimation {
            duration: 320
            easing.type: root.active ? Easing.OutBack : Easing.InCubic
            easing.overshoot: root.active ? 1.1 : 0
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: root.active ? 200 : 280
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.stop()
    }
    Text {
        id: congratsText
        anchors.bottom: bgImage.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -175
        anchors.bottomMargin: -100
        font.pixelSize: 25
        color: Theme.primaryColor
        style: Text.Outline
        styleColor: Theme.backgroundColor

        readonly property string fullText: "おめでとう for day " + root.streakValue + " ! :3"
        property int visibleChars: 0
        text: congratsText.fullText.substring(0, congratsText.visibleChars)
    }

    Timer {
        id: typeTimer
        interval: 120
        repeat: true
        running: root.active
        onTriggered: {
            if (congratsText.visibleChars < congratsText.fullText.length) {
                congratsText.visibleChars += 1;
            } else {
                typeTimer.stop();
            }
        }
    }
    Image {
        id: bgImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        onStatusChanged: {
            if (status === Image.Ready && !root.initialImageReady) {
                root.initialImageReady = true;
            }
        }
    }

    Image {
        id: fgImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        opacity: 0

        onStatusChanged: {
            if (status === Image.Ready && fadeAnimation.pendingStart) {
                fadeAnimation.pendingStart = false;
                fadeAnimation.start();
            }
        }
    }

    NumberAnimation {
        id: fadeAnimation
        property bool pendingStart: false
        target: fgImage
        property: "opacity"
        from: 0
        to: 1
        duration: root.fadeMs
        easing.type: Easing.InOutQuad
        onFinished: {
            bgImage.source = fgImage.source;
            fgImage.opacity = 0;
        }
    }

    Timer {
        id: advanceTimer
        interval: root.holdMs + root.fadeMs
        running: root.active && root.initialImageReady
        repeat: true
        onTriggered: {
            const nextIndex = root.currentIndex + 1;
            if (nextIndex >= root.frames.length) {
                root.loopsCompleted += 1;
                if (root.loopsCompleted >= root.maxLoops) {
                    root.stop();
                    return;
                }
                root.currentIndex = 0;
            } else {
                root.currentIndex = nextIndex;
            }
            fgImage.opacity = 0;
            fadeAnimation.pendingStart = true;
            fgImage.source = "" + root.frames[root.currentIndex];
            if (fgImage.status === Image.Ready) {
                fadeAnimation.pendingStart = false;
                fadeAnimation.start();
            }
        }
    }
}
