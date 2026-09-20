import QtQuick

Item {
    id: root
    property int size: 96
    property color bodyColor: Theme.surfaceContainerHigh
    property color eyeColor: Theme.primaryColor
    property color outlineColor: Theme.outlineVariant
    property real outlineWidth: 0.03

    property real lookX: 0
    property real lookY: 0
    property real blinkValue: 1
    property real winkL: 1
    property real winkR: 1

    property real squintV: 0
    property real lidV: 0
    property real wideV: 1
    property real tallV: 1
    property real browV: 0
    property real heartV: 0
    property real dizzyV: 0

    property real t: 0
    property real wobble: 0
    property real tilt: lookX * 14

    // bounce stuff
    property real gravity: 2600
    property real hopStrength: 500
    property real restitution: 0.3
    property string lastPick: ""
    property real minBounceSpeed: 120
    property real hopY: 0
    property real hopV: 0
    property real deform: 0
    property real deformV: 0
    property real deformStiffness: 600
    property real deformDamping: 24
    property bool airborne: false
    property bool halfwayHopped: false
    property real progress: 0
    // end of bounce stuff

    property bool worried: false
    property bool angry: false
    property bool dizzy: false
    property bool surprised: false
    property bool sleepy: false
    property string forced: ""
    property int streak: 0
    property int lastLen: 0
    property var mistakeTimes: []

    readonly property var presets: ({
            neutral: {
                squint: 0,
                lid: 0,
                wide: 1,
                tall: 1,
                brow: 0,
                heart: 0,
                dizzy: 0
            },
            focused: {
                squint: 0,
                lid: 0.18,
                wide: 1,
                tall: 0.95,
                brow: 0,
                heart: 0,
                dizzy: 0
            },
            happy: {
                squint: 1,
                lid: 0,
                wide: 1,
                tall: 1,
                brow: 0,
                heart: 0,
                dizzy: 0
            },
            worried: {
                squint: 0,
                lid: 0,
                wide: 1.12,
                tall: 1.15,
                brow: -0.8,
                heart: 0,
                dizzy: 0
            },
            sleepy: {
                squint: 0,
                lid: 0.55,
                wide: 1,
                tall: 1,
                brow: 0,
                heart: 0,
                dizzy: 0
            },
            excited: {
                squint: 0,
                lid: 0,
                wide: 1.2,
                tall: 1.3,
                brow: 0,
                heart: 0,
                dizzy: 0
            },
            surprised: {
                squint: 0,
                lid: 0,
                wide: 1.25,
                tall: 1.5,
                brow: 0,
                heart: 0,
                dizzy: 0
            },
            angry: {
                squint: 0,
                lid: 0.15,
                wide: 1,
                tall: 0.85,
                brow: 1.0,
                heart: 0,
                dizzy: 0
            },
            sad: {
                squint: 0,
                lid: 0.25,
                wide: 1,
                tall: 0.9,
                brow: -1.2,
                heart: 0,
                dizzy: 0
            },
            dizzy: {
                squint: 0,
                lid: 0,
                wide: 1.1,
                tall: 1,
                brow: 0,
                heart: 0,
                dizzy: 1
            },
            love: {
                squint: 0,
                lid: 0,
                wide: 1,
                tall: 1,
                brow: 0,
                heart: 1,
                dizzy: 0
            }
        })

    property string mood: {
        if (root.forced !== "") {
            return root.forced;
        }
        if (TypingEngine.finished) {
            return TypingEngine.accuracy < 80 ? "sad" : "love";
        }
        if (root.dizzy) {
            return "dizzy";
        }
        if (root.angry) {
            return "angry";
        }
        if (root.worried) {
            return "worried";
        }
        if (root.surprised) {
            return "surprised";
        }
        if (root.streak >= 40) {
            return "excited";
        }
        if (root.streak >= 10) {
            return "happy";
        }
        if (root.sleepy && !TypingEngine.started) {
            return "sleepy";
        }
        if (TypingEngine.started) {
            return "focused";
        }
        return "neutral";
    }

    width: size
    height: size
    rotation: root.wobble + root.tilt

    // bounce stuff
    transform: [
        Translate {
            x: root.lookX * 5
            y: -root.hopY + root.lookY * 6
        },
        Scale {
            origin.x: root.width / 2
            origin.y: root.height
            xScale: 1 - root.deform * 0.5
            yScale: 1 + root.deform
        }
    ]

    function hop(strength) {
        root.hopV = strength !== undefined ? strength : root.hopStrength;
        root.airborne = true;
    }
    onProgressChanged: {
        if (!root.halfwayHopped && root.progress >= 0.5 && root.progress < 1) {
            root.halfwayHopped = true;
            root.hop();
        }
    }
    FrameAnimation {
        running: root.airborne || Math.abs(root.deform) > 0.001 || Math.abs(root.deformV) > 0.001
        onTriggered: {
            const dt = Math.min(frameTime, 0.033);

            if (root.airborne) {
                root.hopV -= root.gravity * dt;
                root.hopY += root.hopV * dt;

                if (root.hopY <= 0) {
                    const impact = Math.abs(root.hopV);
                    root.hopY = 0;
                    root.hopV = impact * root.restitution;
                    root.deform = -Math.min(0.45, impact / 1400);
                    root.deformV = 0;

                    if (root.hopV < root.minBounceSpeed) {
                        root.hopV = 0;
                        root.airborne = false;
                    }
                }
            }

            const stretchTarget = root.airborne ? Math.min(0.3, Math.abs(root.hopV) / 2200) : 0;
            root.deformV += ((stretchTarget - root.deform) * root.deformStiffness - root.deformV * root.deformDamping) * dt;
            root.deform += root.deformV * dt;
        }
    }

    // end of bounce stuff

    function applyMood() {
        const m = root.presets[root.mood] || root.presets.neutral;
        root.squintV = m.squint;
        root.lidV = m.lid;
        root.wideV = m.wide;
        root.tallV = m.tall;
        root.browV = m.brow;
        root.heartV = m.heart;
        root.dizzyV = m.dizzy;
    }

    onMoodChanged: root.applyMood()
    Component.onCompleted: root.applyMood()

    Behavior on lookX {
        SmoothedAnimation {
            velocity: 6
        }
    }
    Behavior on lookY {
        SmoothedAnimation {
            velocity: 6
        }
    }
    Behavior on squintV {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }
    Behavior on lidV {
        NumberAnimation {
            duration: 350
            easing.type: Easing.OutCubic
        }
    }
    Behavior on wideV {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutBack
        }
    }
    Behavior on tallV {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutBack
        }
    }
    Behavior on browV {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    function lookAt(sceneX, sceneY) {
        const pos = root.mapFromItem(null, sceneX, sceneY);
        const dx = pos.x - root.width / 2;
        const dy = pos.y - root.height / 2;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 0.001) {
            root.lookX = 0;
            root.lookY = 0;
            return;
        }
        const k = Math.min(1, dist / 600) / dist;
        root.lookX = dx * k;
        root.lookY = dy * k;
    }

    function winkLeft() {
        winkLeftAnim.restart();
    }

    function winkRight() {
        winkRightAnim.restart();
    }

    function mistake() {
        const now = Date.now();
        root.streak = 0;
        root.mistakeTimes = root.mistakeTimes.concat([now]).filter(x => now - x < 5000);
        root.worried = true;
        worryTimer.restart();
        if (root.mistakeTimes.filter(x => now - x < 2500).length >= 2) {
            root.angry = true;
            angryTimer.restart();
        }
        if (root.mistakeTimes.length >= 4) {
            root.dizzy = true;
            dizzyTimer.restart();
            root.mistakeTimes = [];
        }
    }
    function react() {
        if (root.airborne) {
            return;
        }
        const options = ["happy", "excited", "focused", "bounce"];
        let pick = options[Math.floor(Math.random() * options.length)];
        while (pick === root.lastPick) {
            pick = options[Math.floor(Math.random() * options.length)];
        }
        root.lastPick = pick;
        if (pick === "bounce") {
            root.hop(260);
            return;
        }
        root.forced = pick;
        forceTimer.restart();
    }
    onStreakChanged: {
        if (root.streak === 25) {
            root.winkRight();
        }
    }

    Timer {
        id: worryTimer
        interval: 900
        onTriggered: root.worried = false
    }
    Timer {
        id: angryTimer
        interval: 1500
        onTriggered: root.angry = false
    }
    Timer {
        id: dizzyTimer
        interval: 2400
        onTriggered: root.dizzy = false
    }
    Timer {
        id: surpriseTimer
        interval: 700
        onTriggered: root.surprised = false
    }
    Timer {
        id: forceTimer
        interval: 1300
        onTriggered: root.forced = ""
    }
    Timer {
        id: idleTimer
        interval: 8000
        running: !TypingEngine.started
        onTriggered: root.sleepy = true
    }
    Timer {
        id: randomWinkTimer
        interval: 9000
        running: true
        repeat: true
        onTriggered: {
            randomWinkTimer.interval = 5000 + Math.random() * 10000;
            const calm = root.mood === "neutral" || root.mood === "happy" || root.mood === "focused";
            if (root.forced === "" && calm) {
                if (Math.random() < 0.5) {
                    root.winkLeft();
                } else {
                    root.winkRight();
                }
            }
        }
    }

    Connections {
        target: TypingEngine
        function onTypedTextChanged() {
            root.sleepy = false;
            idleTimer.restart();
            const len = TypingEngine.typedText.length;
            if (len > root.lastLen) {
                if (TypingEngine.characterStateAt(len - 1) === TypingEngine.Correct) {
                    root.streak++;
                } else {
                    root.mistake();
                }
            }
            root.lastLen = len;
        }
        function onStartedChanged() {
            if (TypingEngine.started) {
                root.surprised = true;
                surpriseTimer.restart();
            }
        }
        function onTargetTextChanged() {
            if (!TypingEngine.started) {
                root.streak = 0;
                root.lastLen = 0;
                root.worried = false;
                root.angry = false;
                root.dizzy = false;
                root.mistakeTimes = [];
                root.halfwayHopped = false;
            }
        }
    }

    NumberAnimation on t {
        running: root.mood === "dizzy" || root.mood === "love"
        loops: Animation.Infinite
        from: 0
        to: 1000
        duration: 1000000
    }

    SequentialAnimation {
        running: root.mood === "dizzy"
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation {
            target: root
            property: "wobble"
            to: 8
            duration: 260
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "wobble"
            to: -8
            duration: 260
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "wobble"
            to: 0
            duration: 130
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.mood !== "sleepy" && root.mood !== "love" && root.mood !== "dizzy"
        loops: Animation.Infinite
        alwaysRunToEnd: true
        PauseAnimation {
            duration: 2600
        }
        NumberAnimation {
            target: root
            property: "blinkValue"
            to: 0
            duration: 70
        }
        NumberAnimation {
            target: root
            property: "blinkValue"
            to: 1
            duration: 110
        }
    }

    SequentialAnimation {
        id: winkLeftAnim
        NumberAnimation {
            target: root
            property: "winkL"
            to: 0
            duration: 90
        }
        PauseAnimation {
            duration: 350
        }
        NumberAnimation {
            target: root
            property: "winkL"
            to: 1
            duration: 140
        }
    }

    SequentialAnimation {
        id: winkRightAnim
        NumberAnimation {
            target: root
            property: "winkR"
            to: 0
            duration: 90
        }
        PauseAnimation {
            duration: 350
        }
        NumberAnimation {
            target: root
            property: "winkR"
            to: 1
            duration: 140
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.react()
    }

    ShaderEffect {
        anchors.fill: parent
        property vector2d look: Qt.vector2d(root.lookX, root.lookY)
        property color bodyColor: root.bodyColor
        property color eyeColor: root.eyeColor
        property real blinkL: Math.min(root.blinkValue, root.winkL)
        property real blinkR: Math.min(root.blinkValue, root.winkR)
        property real squint: root.squintV
        property real lid: root.lidV
        property real wide: root.wideV
        property real tall: root.tallV
        property real brow: root.browV
        property real dizzy: root.dizzyV
        property real heart: root.heartV
        property real time: root.t
        property color outlineColor: root.outlineColor
        property real outlineWidth: root.outlineWidth

        vertexShader: "assets/shaders/watcher.vert.qsb"
        fragmentShader: "assets/shaders/watcher.frag.qsb"
    }
}
