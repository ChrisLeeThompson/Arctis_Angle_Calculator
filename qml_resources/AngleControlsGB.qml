import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "millingAngleCalculations.js" as Calc
import "."

GroupBox {

    property alias alphaTiltRealValue: alphaTiltSB.realValue
    property alias millingAngleRealValue: millingAngleSB.realValue
    property bool useAlternativeMillingAngleMode: false
    property bool connectedToMicroscope: false

    // Flag to prevent recursive updates
    property bool updatingValues: false

    function animateAlphaTiltTo(targetValue) {
        alphaTiltAnimation.to = targetValue
        alphaTiltAnimation.restart()
    }

    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: contentItem.implicitHeight + topPadding + bottomPadding
    padding: 12
    background: Rectangle {
        color: AppConfig.backgroundColor
        border.color: AppConfig.groupBoxBorder
        radius: AppConfig.groupBoxRadius
    }

    focusPolicy: Qt.StrongFocus

    NumberAnimation {
        id: alphaTiltAnimation
        target: alphaTiltSB
        property: "realValue"
        duration: 500
        easing.type: Easing.InOutQuad
    }

    contentItem: Item {

        implicitWidth: mainGridLayout.implicitWidth
        implicitHeight: mainGridLayout.implicitHeight

        GridLayout {
            id: mainGridLayout
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 3
            rowSpacing: AppConfig.groupBoxSpacing
            columnSpacing: AppConfig.groupBoxSpacing

            // Row 0: Milling Angle
            Label {
                property string _toolTipText: AppConfig.millingAngleToolTip

                id: millingAngleLabel
                Layout.row: 0
                Layout.column: 0
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: AppConfig.labelWidth
                text: qsTr("Milling Angle (deg.)")
                ToolTip.text: _toolTipText
                ToolTip.delay: AppConfig.toolTipDelay
                ToolTip.timeout: AppConfig.toolTipTimeout
                ToolTip.visible: _toolTipText ? millingAngleLabelMA.containsMouse : false
                MouseArea {
                    id: millingAngleLabelMA
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            SpinBoxDouble {
                id: millingAngleSB
                Layout.row: 0
                Layout.column: 1
                Layout.alignment: Qt.AlignCenter
                decimals: 1
                realFrom: -152.0
                realTo: 53.0
                realValue: 15.0
                realStepSize: 0.1
                onRealValueChanged: {
                    if (root.updatingValues) return
                    root.updatingValues = true

                    var alphaTiltDegrees = Calc.alphaTiltForDisplay(
                        realValue, root.useAlternativeMillingAngleMode,
                        AppConfig.minAlphaTilt)
                    alphaTiltSB.realValue = alphaTiltDegrees

                    root.updatingValues = false
                }
            }

            RoundedButton {
                id: getButton
                Layout.row: 0
                Layout.column: 2
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 10
                implicitWidth: 80
                implicitHeight: millingAngleSB.implicitHeight
                text: qsTr("Get")
                radius: AppConfig.buttonRadius
                enabled: false
                ToolTip.text: AppConfig.getButtonToolTip
                ToolTip.delay: AppConfig.toolTipDelay
                ToolTip.timeout: AppConfig.toolTipTimeout
                ToolTip.visible: hovered
                onClicked: {
                    arctis_angle_calc_backend.get_current_alpha_tilt()
                }
            }

            // Row 1: Alpha Tilt
            Label {
                property string _toolTipText: AppConfig.alphaTiltAngleToolTip

                id: alphaTiltLabel
                Layout.row: 1
                Layout.column: 0
                Layout.preferredWidth: AppConfig.labelWidth
                text: qsTr("Alpha Tilt (deg.)")
                ToolTip.text: _toolTipText
                ToolTip.delay: AppConfig.toolTipDelay
                ToolTip.timeout: AppConfig.toolTipTimeout
                ToolTip.visible: _toolTipText ? alphaTiltLabelMA.containsMouse : false
                MouseArea {
                    id: alphaTiltLabelMA
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            SpinBoxDouble {
                id: alphaTiltSB
                Layout.row: 1
                Layout.column: 1
                Layout.alignment: Qt.AlignCenter
                decimals: 1
                realFrom: AppConfig.minAlphaTilt
                realTo: AppConfig.maxAlphaTilt
                realValue: -23.0
                realStepSize: 0.1
                onRealValueChanged: {
                    if (root.updatingValues) return
                    root.updatingValues = true

                    millingAngleSB.realValue = Calc.millingAngleForDisplay(
                        realValue, root.useAlternativeMillingAngleMode)

                    root.updatingValues = false
                }
            }

            RoundedButton {
                id: goToButton
                Layout.row: 1
                Layout.column: 2
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 10
                implicitWidth: 80
                implicitHeight: alphaTiltSB.implicitHeight
                text: qsTr("Go To")
                radius: AppConfig.buttonRadius
                enabled: false
                ToolTip.text: AppConfig.goToButtonToolTip
                ToolTip.delay: AppConfig.toolTipDelay
                ToolTip.timeout: AppConfig.toolTipTimeout
                ToolTip.visible: hovered
                onClicked: {
                    arctis_angle_calc_backend.tilt_stage_to_alpha(alphaTiltSB.realValue)
                }
            }

            // Row 2: Spacer
            Item {
                Layout.row: 2
                Layout.column: 0
                Layout.columnSpan: 3
                Layout.preferredHeight: AppConfig.groupBoxSpacing
            }

            // Row 3: Connect To Microscope
            Label {
                property string _toolTipText: AppConfig.connectToMicroscopeToolTip

                id: connectSwitchLabel
                Layout.row: 3
                Layout.column: 0
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: AppConfig.labelWidth
                text: qsTr("Connect To Microscope")
                ToolTip.text: _toolTipText
                ToolTip.delay: AppConfig.toolTipDelay
                ToolTip.timeout: AppConfig.toolTipTimeout
                ToolTip.visible: _toolTipText ? connectSwitchLabelMA.containsMouse : false
                MouseArea {
                    id: connectSwitchLabelMA
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            StyledSwitch {
                id: connectSwitch
                Layout.row: 3
                Layout.column: 1
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: connectSwitchLabel.implicitHeight
                onCheckedChanged: {
                    if (checked) {
                        arctis_angle_calc_backend.connect_to_microscope()
                    } else {
                        if (connectedToMicroscope) {
                            arctis_angle_calc_backend.disconnect_from_microscope()
                        }
                    }
                }
            }

            Label {
                id: statusLabel
                Layout.row: 3
                Layout.column: 2
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 10
                Layout.preferredWidth: AppConfig.labelWidth
                text: ""
                elide: Text.ElideRight
            }

            // Row 4: alternative (BOG) Milling Angle
            Label {
                property string _toolTipText: AppConfig.bogMillingAngleToolTip

                id: alternativeMillingAngleLabel
                Layout.row: 4
                Layout.column: 0
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: AppConfig.labelWidth
                text: qsTr("BOG Milling Angle")
                ToolTip.text: _toolTipText
                ToolTip.delay: AppConfig.toolTipDelay
                ToolTip.timeout: AppConfig.toolTipTimeout
                ToolTip.visible: _toolTipText ? alternativeMillingAngleLabelMA.containsMouse : false
                MouseArea {
                    id: alternativeMillingAngleLabelMA
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            StyledSwitch {
                id: alternativeMillingAngleSwitch
                Layout.row: 4
                Layout.column: 1
                Layout.alignment: Qt.AlignCenter
                onCheckedChanged: {
                    useAlternativeMillingAngleMode = checked

                    // Recalculate milling angle with new mode
                    if (!root.updatingValues) {
                        root.updatingValues = true

                        millingAngleSB.realValue = Calc.millingAngleForDisplay(
                            alphaTiltSB.realValue, useAlternativeMillingAngleMode)

                        root.updatingValues = false
                    }
                }
            }
        }
    }

    Connections {
        target: arctis_angle_calc_backend
        function onStatus_label_signal(str) {
            statusLabel.text = str
        }
        function onConnect_switch_enable_signal(bool) {
            if (bool === true) {
                connectSwitch.enabled = true
            } else {
                connectSwitch.enabled = false
            }
        }
        function onConnected_to_microscope_signal(bool) {
            if (bool === true) {
                connectedToMicroscope = true
                connectSwitch.checked = true
                getButton.enabled = true
                goToButton.enabled = true
            } else {
                connectedToMicroscope = false
                connectSwitch.checked = false
                getButton.enabled = false
                goToButton.enabled = false
            }
        }
        function onStage_move_signal(bool) {
            if (bool === true) {
                connectSwitch.enabled = false
                getButton.enabled = false
                goToButton.enabled = false
            } else {
                connectSwitch.enabled = true
                getButton.enabled = true
                goToButton.enabled = true
            }
        }
        function onCurrent_alpha_position_signal(alpha_tilt_degrees) {
            alphaTiltSB.realValue = alpha_tilt_degrees
        }
    }
}
