pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia
import typeShitter

Item {
    id: root
    property int passageFontSize: 34

    property real lastFireTargetX: 0
    property var shatteringWords: ({})
    signal wordImpact(int wordStart)

    readonly property real shipTilt: {
        const dx = root.lastFireTargetX - Shootout.shipX;
        const clamped = Math.max(-120, Math.min(120, dx));
        return (clamped / 120) * 18;
    }

    SoundEffect {
        id: fireSfx
        source: "../assets/sfx/fire.wav"
    }

    SoundEffect {
        id: destroySfx
        source: "../assets/sfx/destroy.wav"
    }
    SoundEffect {
        id: missedSfx
        source: "../assets/sfx/missed.wav"
    }

    anchors.fill: parent
    clip: true

    onWidthChanged: Shootout.setViewportSize(width, height)
    onHeightChanged: Shootout.setViewportSize(width, height)
    Component.onCompleted: {
        Shootout.laneCount = 5;
        Shootout.start(width, height);
        Qt.callLater(root.trySpawnMore);
    }
    Component.onDestruction: Shootout.stop()

    readonly property var wordBoundaries: TypingEngine.wordBoundaries
    property int lastSpawnedBoundary: -1
    property int lastTypedLength: 0

    function wordHasCurrentError(wordStart, wordEnd) {
        const upTo = Math.min(wordEnd, TypingEngine.typedText.length);
        for (let i = wordStart; i < upTo; i++) {
            if (TypingEngine.characterStateAt(i) === TypingEngine.Incorrect) {
                return true;
            }
        }
        return false;
    }

    function trySpawnMore() {
        const words = root.wordBoundaries;
        let idx = root.lastSpawnedBoundary + 1;
        while (Shootout.words.length < Shootout.laneCount && idx < words.length) {
            Shootout.spawnWord(words[idx].start, words[idx].end);
            root.lastSpawnedBoundary = idx;
            idx++;
        }
    }

    function findWordDelegate(wordStart) {
        for (let i = 0; i < wordsRepeater.count; i++) {
            const del = wordsRepeater.itemAt(i) as FallingWordDelegate;
            if (del && del.wordStart === wordStart) {
                return del;
            }
        }
        return null;
    }

    function laneYFor(wordStart) {
        const del = root.findWordDelegate(wordStart);
        if (!del) {
            return root.height - 90;
        }
        return del.y + del.height / 2;
    }

    function letterTargetX(wordStart, globalIndex) {
        const del = root.findWordDelegate(wordStart);
        if (!del) {
            return Shootout.shipX;
        }
        const letterItem = del.letterRepeater.itemAt(globalIndex - wordStart);
        if (!letterItem) {
            return del.x + del.width / 2;
        }
        return del.x + letterItem.x + letterItem.width / 2;
    }

    function spawnShatter(x, y, w, h, color, count) {
        const n = count || 10;
        for (let i = 0; i < n; i++) {
            shardComponent.createObject(root, {
                x: x + Math.random() * w,
                y: y + Math.random() * h,
                width: 3 + Math.random() * 5,
                height: 3 + Math.random() * 5,
                color: color,
                vx: (Math.random() - 0.5) * 260,
                vy: -Math.random() * 220 - 60,
                va: (Math.random() - 0.5) * 360
            });
        }
    }

    function spawnBoxBreak(x, y, w, h, color) {
        const cols = 4;
        const rows = 2;
        const chunkW = w / cols;
        const chunkH = h / rows;
        for (let r = 0; r < rows; r++) {
            for (let c = 0; c < cols; c++) {
                const cx = x + c * chunkW;
                const cy = y + r * chunkH;
                slabComponent.createObject(root, {
                    x: cx,
                    y: cy,
                    width: chunkW - 1,
                    height: chunkH - 1,
                    color: color,
                    vx: (c - (cols - 1) / 2) * 90 + (Math.random() - 0.5) * 60,
                    vy: -120 - Math.random() * 100,
                    va: (Math.random() - 0.5) * 260
                });
            }
        }
        root.spawnShatter(x, y, w, h, color, 14);
    }

    function spawnPhysicsLetter(ch, startX, startY) {
        const angle = (Math.random() * 30 - 15) * Math.PI / 180;
        const speed = Math.random() * 3 + 5;
        const forceX = Math.sin(angle) * speed + (Math.random() * 4 - 2);
        const forceY = -Math.cos(angle) * speed - 4;
        const rotSpeed = Math.random() * 20 - 10;

        physicsLetterComponent.createObject(root, {
            text: ch,
            x: startX,
            y: startY,
            color: Theme.primaryColor,
            font: {
                pixelSize: root.passageFontSize
            },
            vx: forceX * 60,
            vy: forceY * 60,
            va: rotSpeed * 60
        });
    }

    Component {
        id: shatterTimerComponent
        Timer {
            interval: 160
            running: true
            repeat: false
        }
    }

    function scheduleShatter(wordStart) {
        const t = shatterTimerComponent.createObject(root);
        t.triggered.connect(function () {
            root.finishShatter(wordStart);
            t.destroy();
        });
    }

    function finishShatter(wordStart) {
        const del = root.findWordDelegate(wordStart);
        if (del) {
            const shatterColor = root.wordHasCurrentError(del.wordStart, del.wordEnd) ? Theme.errorColor : Theme.primaryColor;
            root.spawnBoxBreak(del.x - 6, del.y - 6, del.width + 12, del.height + 12, shatterColor);
            destroySfx.play();
        }
        Shootout.markWordDying(wordStart);
        delete root.shatteringWords[wordStart];
    }

    function wordStartFor(globalIndex) {
        const words = root.wordBoundaries;
        for (let i = 0; i < words.length; i++) {
            if (globalIndex >= words[i].start && globalIndex < words[i].end) {
                return words[i].start;
            }
        }
        return globalIndex;
    }

    Component {
        id: shardComponent
        ShatterShard {}
    }

    Component {
        id: slabComponent
        ShatterSlab {}
    }

    Component {
        id: physicsLetterComponent
        PhysicsLetter {}
    }

    Connections {
        target: Shootout
        function onLetterImpact(ch, x, y) {
            root.spawnShatter(x - 10, y - 16, 20, 24, Theme.primaryColor, 6);
            root.spawnPhysicsLetter(ch, x - 10, y - 20);
        }
    }

    Connections {
        target: TypingEngine
        function onTargetTextChanged() {
            root.trySpawnMore();
        }
        function onTypedTextChanged() {
            const newLen = TypingEngine.typedText.length;

            if (newLen > root.lastTypedLength) {
                const hitIndex = newLen - 1;
                const ch = TypingEngine.characterAt(hitIndex);
                if (ch !== " ") {
                    const wordStart = root.wordStartFor(hitIndex);
                    const laneX = root.letterTargetX(wordStart, hitIndex);
                    const laneY = root.laneYFor(wordStart);
                    Shootout.fireBullet(hitIndex, laneX, laneY, ch, Shootout.shipX, root.height - 90);
                    root.lastFireTargetX = laneX;
                    playerShip.fire();

                    const state = TypingEngine.characterStateAt(hitIndex);
                    if (state === TypingEngine.Incorrect) {
                        missedSfx.play();
                    } else {
                        fireSfx.play();
                    }
                }
            }

            const words = root.wordBoundaries;
            for (let i = 0; i < words.length; i++) {
                if (words[i].end <= newLen && !root.shatteringWords[words[i].start]) {
                    root.shatteringWords[words[i].start] = true;
                    root.wordImpact(words[i].start);
                    root.scheduleShatter(words[i].start);
                }
            }
            root.trySpawnMore();
            root.lastTypedLength = newLen;
        }
    }

    Repeater {
        id: wordsRepeater
        model: Shootout.words
        delegate: FallingWordDelegate {
            controller: root
        }
    }

    Repeater {
        model: Shootout.bullets
        delegate: BulletSprite {}
    }

    PlayerShip {
        id: playerShip
        shipCenterX: Shootout.shipX
        baseY: root.height - 170
        tilt: root.shipTilt
    }
}
