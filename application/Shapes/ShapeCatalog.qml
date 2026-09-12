pragma Singleton
import QtQuick

QtObject {
    readonly property var files: ["circle.svg", "square.svg", "slanted.svg", "arch.svg", "fan.svg", "arrow.svg", "semi_circle.svg", "oval.svg", "pill.svg", "triangle.svg", "diamond.svg", "clam_shell.svg", "pentagon.svg", "gem.svg", "sunny.svg", "very_sunny.svg", "cookie4.svg", "cookie6.svg", "cookie7.svg", "cookie9.svg", "cookie12.svg", "ghostish.svg", "clover4.svg", "clover8.svg", "burst.svg", "soft_burst.svg", "boom.svg", "soft_boom.svg", "flower.svg", "puffy.svg", "puffy_diamond.svg", "pixel_circle.svg", "pixel_triangle.svg", "bun.svg", "heart.svg"]

    function get(idx) {
        return "qrc:/qt/qml/typeShitter/application/assets/shapes_svg/" + files[idx % files.length];
    }
}
