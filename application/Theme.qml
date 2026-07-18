pragma Singleton
import QtQuick
import typeShitter

QtObject {
    readonly property color backgroundColor: Config.themeColor("background")
    readonly property color surfaceColor: Config.themeColor("surface")
    readonly property color surfaceBright: Config.themeColor("surface_bright")
    readonly property color surfaceContainer: Config.themeColor("surface_container")
    readonly property color surfaceContainerLow: Config.themeColor("surface_container_low")
    readonly property color surfaceContainerHigh: Config.themeColor("surface_container_high")
    readonly property color surfaceContainerHighest: Config.themeColor("surface_container_highest")
    readonly property color surfaceDim: Config.themeColor("surface_dim")

    readonly property color primaryColor: Config.themeColor("primary")
    readonly property color primaryContainerColor: Config.themeColor("primary_container")
    readonly property color primaryFixedColor: Config.themeColor("primary_fixed")
    readonly property color primaryFixedDim: Config.themeColor("primary_fixed_dim")

    readonly property color secondaryColor: Config.themeColor("secondary")
    readonly property color secondaryContainerColor: Config.themeColor("secondary_container")
    readonly property color secondaryFixedColor: Config.themeColor("secondary_fixed")
    readonly property color secondaryFixedDim: Config.themeColor("secondary_fixed_dim")

    readonly property color tertiaryColor: Config.themeColor("tertiary")
    readonly property color tertiaryContainerColor: Config.themeColor("tertiary_container")
    readonly property color tertiaryFixedColor: Config.themeColor("tertiary_fixed")
    readonly property color tertiaryFixedDim: Config.themeColor("tertiary_fixed_dim")

    readonly property color errorColor: Config.themeColor("error")
    readonly property color errorContainerColor: Config.themeColor("error_container")

    readonly property color onBackground: Config.themeColor("on_background")
    readonly property color onSurface: Config.themeColor("on_surface")
    readonly property color onSurfaceVariant: Config.themeColor("on_surface_variant")
    readonly property color onPrimary: Config.themeColor("on_primary")
    readonly property color onPrimaryContainer: Config.themeColor("on_primary_container")
    readonly property color onPrimaryFixed: Config.themeColor("on_primary_fixed")
    readonly property color onPrimaryFixedVariant: Config.themeColor("on_primary_fixed_variant")
    readonly property color onSecondary: Config.themeColor("on_secondary")
    readonly property color onSecondaryContainer: Config.themeColor("on_secondary_container")
    readonly property color onSecondaryFixed: Config.themeColor("on_secondary_fixed")
    readonly property color onSecondaryFixedVariant: Config.themeColor("on_secondary_fixed_variant")
    readonly property color onTertiary: Config.themeColor("on_tertiary")
    readonly property color onTertiaryContainer: Config.themeColor("on_tertiary_container")
    readonly property color onTertiaryFixed: Config.themeColor("on_tertiary_fixed")
    readonly property color onTertiaryFixedVariant: Config.themeColor("on_tertiary_fixed_variant")
    readonly property color onError: Config.themeColor("on_error")
    readonly property color onErrorContainer: Config.themeColor("on_error_container")

    readonly property color outline: Config.themeColor("outline")
    readonly property color outlineVariant: Config.themeColor("outline_variant")

    readonly property color inverseSurface: Config.themeColor("inverse_surface")
    readonly property color inverseOnSurface: Config.themeColor("inverse_on_surface")
    readonly property color inversePrimary: Config.themeColor("inverse_primary")

    readonly property color scrimColor: Config.themeColor("scrim")
    readonly property color shadowColor: Config.themeColor("shadow")
}
