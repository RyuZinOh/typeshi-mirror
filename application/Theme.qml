pragma Singleton
import QtQuick

QtObject {
    readonly property color backgroundColor: {
        Config.theme;
        return Config.themeColor("background");
    }
    readonly property color surfaceColor: {
        Config.theme;
        return Config.themeColor("surface");
    }
    readonly property color surfaceBright: {
        Config.theme;
        return Config.themeColor("surface_bright");
    }
    readonly property color surfaceContainer: {
        Config.theme;
        return Config.themeColor("surface_container");
    }
    readonly property color surfaceContainerLow: {
        Config.theme;
        return Config.themeColor("surface_container_low");
    }
    readonly property color surfaceContainerHigh: {
        Config.theme;
        return Config.themeColor("surface_container_high");
    }
    readonly property color surfaceContainerHighest: {
        Config.theme;
        return Config.themeColor("surface_container_highest");
    }
    readonly property color surfaceDim: {
        Config.theme;
        return Config.themeColor("surface_dim");
    }

    readonly property color primaryColor: {
        Config.theme;
        return Config.themeColor("primary");
    }
    readonly property color primaryContainerColor: {
        Config.theme;
        return Config.themeColor("primary_container");
    }
    readonly property color primaryFixedColor: {
        Config.theme;
        return Config.themeColor("primary_fixed");
    }
    readonly property color primaryFixedDim: {
        Config.theme;
        return Config.themeColor("primary_fixed_dim");
    }

    readonly property color secondaryColor: {
        Config.theme;
        return Config.themeColor("secondary");
    }
    readonly property color secondaryContainerColor: {
        Config.theme;
        return Config.themeColor("secondary_container");
    }
    readonly property color secondaryFixedColor: {
        Config.theme;
        return Config.themeColor("secondary_fixed");
    }
    readonly property color secondaryFixedDim: {
        Config.theme;
        return Config.themeColor("secondary_fixed_dim");
    }

    readonly property color tertiaryColor: {
        Config.theme;
        return Config.themeColor("tertiary");
    }
    readonly property color tertiaryContainerColor: {
        Config.theme;
        return Config.themeColor("tertiary_container");
    }
    readonly property color tertiaryFixedColor: {
        Config.theme;
        return Config.themeColor("tertiary_fixed");
    }
    readonly property color tertiaryFixedDim: {
        Config.theme;
        return Config.themeColor("tertiary_fixed_dim");
    }

    readonly property color errorColor: {
        Config.theme;
        return Config.themeColor("error");
    }
    readonly property color errorContainerColor: {
        Config.theme;
        return Config.themeColor("error_container");
    }

    readonly property color onBackground: {
        Config.theme;
        return Config.themeColor("on_background");
    }
    readonly property color onSurface: {
        Config.theme;
        return Config.themeColor("on_surface");
    }
    readonly property color onSurfaceVariant: {
        Config.theme;
        return Config.themeColor("on_surface_variant");
    }
    readonly property color onPrimary: {
        Config.theme;
        return Config.themeColor("on_primary");
    }
    readonly property color onPrimaryContainer: {
        Config.theme;
        return Config.themeColor("on_primary_container");
    }
    readonly property color onPrimaryFixed: {
        Config.theme;
        return Config.themeColor("on_primary_fixed");
    }
    readonly property color onPrimaryFixedVariant: {
        Config.theme;
        return Config.themeColor("on_primary_fixed_variant");
    }
    readonly property color onSecondary: {
        Config.theme;
        return Config.themeColor("on_secondary");
    }
    readonly property color onSecondaryContainer: {
        Config.theme;
        return Config.themeColor("on_secondary_container");
    }
    readonly property color onSecondaryFixed: {
        Config.theme;
        return Config.themeColor("on_secondary_fixed");
    }
    readonly property color onSecondaryFixedVariant: {
        Config.theme;
        return Config.themeColor("on_secondary_fixed_variant");
    }
    readonly property color onTertiary: {
        Config.theme;
        return Config.themeColor("on_tertiary");
    }
    readonly property color onTertiaryContainer: {
        Config.theme;
        return Config.themeColor("on_tertiary_container");
    }
    readonly property color onTertiaryFixed: {
        Config.theme;
        return Config.themeColor("on_tertiary_fixed");
    }
    readonly property color onTertiaryFixedVariant: {
        Config.theme;
        return Config.themeColor("on_tertiary_fixed_variant");
    }
    readonly property color onError: {
        Config.theme;
        return Config.themeColor("on_error");
    }
    readonly property color onErrorContainer: {
        Config.theme;
        return Config.themeColor("on_error_container");
    }

    readonly property color outline: {
        Config.theme;
        return Config.themeColor("outline");
    }
    readonly property color outlineVariant: {
        Config.theme;
        return Config.themeColor("outline_variant");
    }

    readonly property color inverseSurface: {
        Config.theme;
        return Config.themeColor("inverse_surface");
    }
    readonly property color inverseOnSurface: {
        Config.theme;
        return Config.themeColor("inverse_on_surface");
    }
    readonly property color inversePrimary: {
        Config.theme;
        return Config.themeColor("inverse_primary");
    }

    readonly property color scrimColor: {
        Config.theme;
        return Config.themeColor("scrim");
    }
    readonly property color shadowColor: {
        Config.theme;
        return Config.themeColor("shadow");
    }
}
