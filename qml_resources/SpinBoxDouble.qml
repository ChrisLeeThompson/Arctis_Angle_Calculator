import QtQuick
import QtQuick.Controls

SpinBox {

    id: root

    // Public properties for double precision
    property real realValue: 0.0
    property real realFrom: 0.0
    property real realTo: 100.0
    property real realStepSize: 1.0
    property int decimals: 2

    // Internal scale factor based on decimals
    readonly property int scaleFactor: Math.pow(10, decimals)

    // Configure SpinBox based on real values
    from: Math.round(realFrom * scaleFactor)
    to: Math.round(realTo * scaleFactor)
    stepSize: Math.round(realStepSize * scaleFactor)
    value: Math.round(realValue * scaleFactor)
    editable: true
    wheelEnabled: true
    hoverEnabled: true

    validator: DoubleValidator {
        bottom: root.realFrom
        top: root.realTo
        decimals: root.decimals
        notation: DoubleValidator.StandardNotation
    }

    // Hide the up/down buttons
    up.indicator: Item {}
    down.indicator: Item {}

    // Custom background styling
    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 32
        color: {
                    if (!root.enabled) return AppConfig.spinBoxBackgroundDisabled
                    if (root.hovered) return Qt.lighter(AppConfig.spinBoxBackground, 1.3)
                    return AppConfig.spinBoxBackground
                }
        border.color: {
            if (!root.enabled) return AppConfig.spinBoxBorderDisabled
            if (root.activeFocus) return AppConfig.accentColor
            if (root.hovered) return Qt.lighter(AppConfig.groupBoxBorder, 1.3)
            return AppConfig.spinBoxBorder
        }
        border.width: root.activeFocus ? AppConfig.spinBoxBorderWidth : 2
        radius: AppConfig.spinBoxRadius

    }

    // Custom text input styling
    contentItem: TextInput {
        z: 2
        text: root.textFromValue(root.value, root.locale)
        font: root.font
        color: root.enabled ? AppConfig.textPrimary : AppConfig.spinBoxTextDisabled
        selectionColor: AppConfig.accentColor
        selectedTextColor: "black"
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !root.editable
        validator: root.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }

    // Sync internal value changes back to realValue
    onValueChanged: {
        var newRealValue = value / scaleFactor
        if (Math.abs(newRealValue - realValue) > Number.EPSILON) {
            realValue = newRealValue
        }
    }

    // Sync external realValue changes to internal value
    onRealValueChanged: {
        var newValue = Math.round(realValue * scaleFactor)
        if (newValue !== value) {
            value = newValue
        }
    }

    // Convert displayed text to internal integer value
    valueFromText: function(text, locale) {
        return Math.round(Number.fromLocaleString(locale, text) * scaleFactor)
    }

    // Convert internal integer value to displayed text
    textFromValue: function(value, locale) {
        return Number(value / scaleFactor).toLocaleString(locale, 'f', decimals)
    }

}
