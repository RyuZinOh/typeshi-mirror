pragma Singleton
import QtQuick
import typeShitter

QtObject {
    readonly property var t: Config.theme
    function c(key) {
        const value = t[key];
        if (value === undefined || value === "" || value.indexOf("{{") !== -1) {
            console.warn("Theme: bad/missing matugen color for key:", key, "value:", value);
            return "#ff0000";
        }
        return value;
    }
    readonly property color backgroundColor: c("background")
    readonly property color surfaceColor: c("surface")
    readonly property color surfaceBright: c("surface_bright")
    readonly property color surfaceContainer: c("surface_container")
    readonly property color surfaceContainerLow: c("surface_container_low")
    readonly property color surfaceContainerHigh: c("surface_container_high")
    readonly property color surfaceContainerHighest: c("surface_container_highest")
    readonly property color surfaceDim: c("surface_dim")

    readonly property color primaryColor: c("primary")
    readonly property color primaryContainerColor: c("primary_container")
    readonly property color primaryFixedColor: c("primary_fixed")
    readonly property color primaryFixedDim: c("primary_fixed_dim")

    readonly property color secondaryColor: c("secondary")
    readonly property color secondaryContainerColor: c("secondary_container")
    readonly property color secondaryFixedColor: c("secondary_fixed")
    readonly property color secondaryFixedDim: c("secondary_fixed_dim")

    readonly property color tertiaryColor: c("tertiary")
    readonly property color tertiaryContainerColor: c("tertiary_container")
    readonly property color tertiaryFixedColor: c("tertiary_fixed")
    readonly property color tertiaryFixedDim: c("tertiary_fixed_dim")

    readonly property color errorColor: c("error")
    readonly property color errorContainerColor: c("error_container")

    readonly property color onBackground: c("on_background")
    readonly property color onSurface: c("on_surface")
    readonly property color onSurfaceVariant: c("on_surface_variant")
    readonly property color onPrimary: c("on_primary")
    readonly property color onPrimaryContainer: c("on_primary_container")
    readonly property color onPrimaryFixed: c("on_primary_fixed")
    readonly property color onPrimaryFixedVariant: c("on_primary_fixed_variant")
    readonly property color onSecondary: c("on_secondary")
    readonly property color onSecondaryContainer: c("on_secondary_container")
    readonly property color onSecondaryFixed: c("on_secondary_fixed")
    readonly property color onSecondaryFixedVariant: c("on_secondary_fixed_variant")
    readonly property color onTertiary: c("on_tertiary")
    readonly property color onTertiaryContainer: c("on_tertiary_container")
    readonly property color onTertiaryFixed: c("on_tertiary_fixed")
    readonly property color onTertiaryFixedVariant: c("on_tertiary_fixed_variant")
    readonly property color onError: c("on_error")
    readonly property color onErrorContainer: c("on_error_container")

    readonly property color outline: c("outline")
    readonly property color outlineVariant: c("outline_variant")

    readonly property color inverseSurface: c("inverse_surface")
    readonly property color inverseOnSurface: c("inverse_on_surface")
    readonly property color inversePrimary: c("inverse_primary")

    readonly property color scrimColor: c("scrim")
    readonly property color shadowColor: c("shadow")
}
