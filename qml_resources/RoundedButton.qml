import QtQuick
import QtQuick.Controls
import "."

RoundButton {
    id: control

    implicitWidth: 80
    implicitHeight: 40

    background: Rectangle {
        color: {
            if (!control.enabled)
                return AppConfig.buttonBackgroundDisabled
            if (control.down)
                return Qt.darker(AppConfig.groupBoxBorder, 1.1)
            if (control.hovered)
                return Qt.lighter(AppConfig.groupBoxBorder, 1.3)
            return AppConfig.groupBoxBorder
        }
        border.color: {
            if (!control.enabled)
                return AppConfig.buttonBorderDisabled
            // if (control.hovered)
                // return AppConfig.accentColor
            if (control.activeFocus)
                return AppConfig.groupBoxBorder
            return AppConfig.groupBoxBorder
        }
        border.width: 1
        radius: AppConfig.buttonRadius
        opacity: control.enabled ? 1.0 : 0.8
    }

    contentItem: Text {
        text: control.text
        color: control.enabled ? AppConfig.textPrimary : AppConfig.buttonTextDisabled
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font: control.font
    }
}
