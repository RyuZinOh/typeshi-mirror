pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property int alignment: 0
    property real radius: 50
    property color color: "lightgray"
    property real borderWidth: 0
    property color borderColor: "transparent"
    default property alias content: contentWrapper.data

    readonly property real off: root.borderWidth / 2
    readonly property real w: root.width - root.borderWidth
    readonly property real h: root.height - root.borderWidth

    Loader {
        anchors.fill: parent
        asynchronous: true
        sourceComponent: {
            const shapes = [attachedTop, attachedBottom];
            return root.alignment >= 0 && root.alignment < 2 ? shapes[root.alignment] : null;
        }
    }

    Item {
        id: contentWrapper

        anchors {
            fill: parent
            leftMargin: root.radius
            rightMargin: root.radius
        }
    }

    Component {
        id: attachedTop

        BubbleShape {
            shapePath.startX: root.off
            shapePath.startY: root.off

            PathArc {
                x: root.radius + root.off
                y: Math.min(root.radius, root.h / 2) + root.off
                radiusX: root.radius
                radiusY: Math.min(root.radius, root.h / 2)
            }

            PathLine {
                x: root.radius + root.off
                y: Math.max(root.h - root.radius, root.h / 2) + root.off
            }

            PathArc {
                x: 2 * root.radius + root.off
                y: root.h + root.off
                radiusX: root.radius
                radiusY: Math.min(root.radius, root.h / 2)
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: root.w - 2 * root.radius + root.off
                y: root.h + root.off
            }

            PathArc {
                x: root.w - root.radius + root.off
                y: Math.max(root.h - root.radius, root.h / 2) + root.off
                radiusX: root.radius
                radiusY: Math.min(root.radius, root.h / 2)
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: root.w - root.radius + root.off
                y: Math.min(root.radius, root.h / 2) + root.off
            }

            PathArc {
                x: root.w + root.off
                y: root.off
                radiusX: root.radius
                radiusY: Math.min(root.radius, root.h / 2)
            }

            PathLine {
                x: root.off
                y: root.off
            }
        }
    }

    Component {
        id: attachedBottom

        BubbleShape {
            shapePath.startX: root.off
            shapePath.startY: root.h + root.off

            PathArc {
                x: root.radius + root.off
                y: Math.max(root.h - root.radius, root.h / 2) + root.off
                radiusX: root.radius
                radiusY: Math.min(root.radius, root.h / 2)
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: root.radius + root.off
                y: Math.min(root.radius, root.h / 2) + root.off
            }

            PathArc {
                x: 2 * root.radius + root.off
                y: root.off
                radiusX: root.radius
                radiusY: Math.min(root.radius, root.h / 2)
            }

            PathLine {
                x: root.w - 2 * root.radius + root.off
                y: root.off
            }

            PathArc {
                x: root.w - root.radius + root.off
                y: Math.min(root.radius, root.h / 2) + root.off
                radiusX: root.radius
                radiusY: Math.min(root.radius, root.h / 2)
            }

            PathLine {
                x: root.w - root.radius + root.off
                y: Math.max(root.h - root.radius, root.h / 2) + root.off
            }

            PathArc {
                x: root.w + root.off
                y: root.h + root.off
                radiusX: root.radius
                radiusY: Math.min(root.radius, root.h / 2)
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: root.off
                y: root.h + root.off
            }
        }
    }

    component BubbleShape: Shape {
        default property alias pathElements: shapePath.pathElements
        property alias shapePath: shapePath

        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.smooth: true

        ShapePath {
            id: shapePath
            pathHints: ShapePath.PathSolid | ShapePath.PathNonIntersecting
            fillColor: root.color
            strokeWidth: root.borderWidth
            strokeColor: root.borderColor
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
        }
    }
}
