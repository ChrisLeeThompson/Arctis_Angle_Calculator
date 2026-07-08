import QtQuick
import QtQuick.Controls
import "."

Switch {
    id: control

    implicitWidth: 52
    implicitHeight: 28

    indicator: Rectangle {
        implicitWidth: 52
        implicitHeight: 22
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: height / 2

        color: {
            if (!control.enabled)
                return AppConfig.spinBoxBackgroundDisabled
            if (control.checked)
                return AppConfig.accentColor
            return AppConfig.groupBoxBorder
        }

        border.color: {
            if (!control.enabled)
                return AppConfig.spinBoxBorderDisabled
            if (control.hovered)
                return Qt.lighter(AppConfig.spinBoxHighlight, 1.3)
            if (control.checked)
                return AppConfig.accentColor
            return AppConfig.spinBoxBorder
        }

        border.width: 2
        opacity: control.enabled ? 1.0 : 0.5

        Behavior on color {
            ColorAnimation { duration: 0 }
        }

        Behavior on border.color {
            ColorAnimation { duration: 0 }
        }

        Rectangle {
            id: handle
            x: control.checked ? parent.width - width - 4 : 4
            y: (parent.height - height) / 2
            width: 14
            height: 14
            radius: width / 2
            color: control.enabled ? AppConfig.textPrimary : AppConfig.spinBoxTextDisabled

            Behavior on x {
                NumberAnimation { duration: 100; easing.type: Easing.InOutQuad }
            }
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.5
        color: AppConfig.textPrimary
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
