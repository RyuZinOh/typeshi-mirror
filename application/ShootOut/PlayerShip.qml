import QtQuick

Item {
    id: root
    property real shipCenterX: 0
    property real baseY: 0
    property real tilt: 0
    property real recoilOffset: 0

    x: root.shipCenterX - width / 2
    y: root.baseY - root.recoilOffset
    width: 100
    height: 100
    rotation: root.tilt
    transformOrigin: Item.Bottom

    function fire() {
        recoilAnim.restart();
        targetPulse.restart();
    }

    Behavior on x {
        NumberAnimation {
            duration: 90
            easing.type: Easing.OutQuad
        }
    }
    Behavior on rotation {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutBack
        }
    }

    SequentialAnimation {
        id: recoilAnim
        NumberAnimation {
            target: root
            property: "recoilOffset"
            to: 14
            duration: 45
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "recoilOffset"
            to: 0
            duration: 160
            easing.type: Easing.OutBack
        }
    }

    Item {
        id: targetedReticleLayer
        anchors.centerIn: parent
        width: 130
        height: 130
        z: -1

        Image {
            id: targetedReticleIdle
            source: "../assets/ships/player/SingleShotShipTargeted.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.55
                    duration: 800
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 0.1
                    duration: 800
                    easing.type: Easing.InOutSine
                }
            }
        }

        Image {
            id: targetedReticleFlash
            source: "../assets/ships/player/SingleShotShipTargeted.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            opacity: 0
        }
    }

    SequentialAnimation {
        id: targetPulse
        NumberAnimation {
            target: targetedReticleFlash
            property: "opacity"
            to: 0.9
            duration: 60
        }
        NumberAnimation {
            target: targetedReticleFlash
            property: "opacity"
            to: 0
            duration: 220
            easing.type: Easing.OutQuad
        }
    }

    Image {
        id: pBase
        source: "../assets/ships/player/SingleShotShip.png"
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit

        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation {
                to: 1.04
                duration: 700
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 1.0
                duration: 700
                easing.type: Easing.InOutSine
            }
        }
    }

    Image {
        source: "../assets/ships/player/single shot cockpit.png"
        anchors.centerIn: parent
        width: 32
        height: 32
        fillMode: Image.PreserveAspectFit
        y: -10
    }

    Item {
        anchors.top: pBase.bottom
        anchors.horizontalCenter: pBase.horizontalCenter
        anchors.topMargin: -12
        width: 32
        height: 32

        Image {
            source: "../assets/ships/player/single shot engine A.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0
                    duration: 100
                }
                NumberAnimation {
                    to: 1
                    duration: 100
                }
            }
        }
        Image {
            source: "../assets/ships/player/single shot engine B.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                    to: 1
                    duration: 100
                }
                NumberAnimation {
                    to: 0
                    duration: 100
                }
            }
        }
    }
}
