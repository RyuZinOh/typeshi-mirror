import QtQuick
import typeShitter

QtObject {
    id: root
    property string themeName: ""
    property string variant: "dark"

    property var _colors: themeName !== "" ? Config.previewColors(themeName, variant) : ({})

    property color primary: _colors["primary"]
    property color secondary: _colors["secondary"]
    property color tertiary: _colors["tertiary"]
    property color onPrimary: _colors["on_primary"]
    property color onSecondary: _colors["on_secondary"]
    property color onTertiary: _colors["on_tertiary"]
}
