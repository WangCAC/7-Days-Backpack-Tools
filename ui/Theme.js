.pragma library

// Blue web/desktop palette with Material motion and shared semantic roles.
// Control sizing follows conventional web components rather than full pills.
var primary = "#2563EB"
var primaryHover = "#1D4ED8"
var primaryPressed = "#1E40AF"
var onPrimary = "#FFFFFF"
var primaryContainer = "#DBEAFE"
var onPrimaryContainer = "#1E3A8A"
var secondaryContainer = "#E8F1FF"
var onSecondaryContainer = "#255AA5"
var surface = "#FFFFFF"
var surfaceContainerLowest = "#FFFFFF"
var surfaceContainerLow = "#F4F8FD"
var surfaceContainer = "#EEF4FC"
var surfaceContainerHigh = "#F3F7FF"
var surfaceContainerHighest = "#E4EDF9"
var onSurface = "#223247"
var onSurfaceVariant = "#52667F"
var outline = "#D6E1EF"
var outlineVariant = "#E2EAF4"
var hoverOutline = "#ADC6E8"
var focusOutline = "#5B8FD5"
var error = "#B3261E"
var errorContainer = "#F9DEDC"
var onErrorContainer = "#410E0B"
var darkSurface = "#1C2B3D"
var darkContainer = "#293D53"
var darkOnSurface = "#E5EFFB"
var darkOnSurfaceVariant = "#B9CDE3"
var darkPrimary = "#9BC6FF"
var darkOutline = "#617C98"
var darkOutlineVariant = "#3D536D"
var controlRadius = 6
var compactRadius = 4
var popupRadius = 8
var dialogRadius = 12
var panelRadius = 16
var shortDuration = 100
var stateDuration = 150
var mediumDuration = 250
var standardCurve = [0.2, 0, 0, 1, 1, 1]

function alpha(color, opacity) {
    const value = Qt.tint(color, "transparent")
    return Qt.rgba(value.r, value.g, value.b, opacity)
}
