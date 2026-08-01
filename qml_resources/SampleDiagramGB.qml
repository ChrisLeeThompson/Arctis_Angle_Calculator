import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

GroupBox {
    id: root

    property real alphaTiltAngle: AppConfig.initialAlphaTiltAngle

    // 1.0 = full size; < 1.0 shrinks the figure uniformly to fit a small display.
    // Only the figure is scaled - the GroupBox chrome and the buttons stay full size.
    property real figureFitScale: 1.0

    // Signal emitted when user clicks a label to change alpha tilt
    signal alphaTiltChangeRequested(real newAlphaTilt)

    // Signal emitted when the user adjusts alpha tilt with the scroll wheel
    // (applied without animation by the page).
    signal alphaTiltAdjusted(real newAlphaTilt)

    Layout.fillWidth: true
    Layout.preferredHeight: contentItem.implicitHeight + topPadding + bottomPadding

    background: Rectangle {
        color: AppConfig.backgroundColor
        border.color: AppConfig.groupBoxBorder
        radius: AppConfig.groupBoxRadius
    }

    focusPolicy: Qt.StrongFocus

    // The figure is drawn at its natural design size and scaled uniformly by
    // figureFitScale; the slot's implicit size shrinks by the same factor so the
    // GroupBox reclaims the freed space. The Add Chalk Line / Remove Last buttons
    // are NOT scaled - they stay full size, anchored to the bottom of the
    // (shrunk) slot.
    contentItem: Item {
        id: figureSlot
        implicitWidth: AppConfig.stageDiagramWidth * root.figureFitScale
        implicitHeight: AppConfig.stageDiagramHeight * root.figureFitScale

        SampleDiagram {
            id: sampleDiagram
            width: AppConfig.stageDiagramWidth
            height: AppConfig.stageDiagramHeight

            // Scale about the top-centre: stays centred horizontally and fills
            // the shrunk slot vertically (top-aligned, height 720*scale).
            transformOrigin: Item.Top
            scale: root.figureFitScale
            x: (figureSlot.width - width) / 2

            alphaTiltAngle: root.alphaTiltAngle

            onAlphaTiltChangeRequested: function(newAlphaTilt) {
                root.alphaTiltChangeRequested(newAlphaTilt)
            }

            onAlphaTiltAdjusted: function(newAlphaTilt) {
                root.alphaTiltAdjusted(newAlphaTilt)
            }
        }

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: AppConfig.groupBoxMargins

            RoundedButton {
                id: chalkLineButton
                text: qsTr("Add Chalk Line")
                implicitWidth: 120
                radius: AppConfig.buttonRadius
                ToolTip.text: AppConfig.addChalkLineButtonToolTip
                ToolTip.delay: AppConfig.toolTipDelay
                ToolTip.timeout: AppConfig.toolTipTimeout
                ToolTip.visible: hovered

                onClicked: {
                    sampleDiagram.addChalkLine()
                }
            }

            Item {
                Layout.preferredWidth: AppConfig.groupBoxSpacing
            }

            RoundedButton {
                id: eraseLineButton
                text: qsTr("Remove Last")
                implicitWidth: 110
                radius: AppConfig.buttonRadius
                enabled: sampleDiagram.chalkLineCount > 0
                ToolTip.text: AppConfig.removeLastButtonToolTip
                ToolTip.delay: AppConfig.toolTipDelay
                ToolTip.timeout: AppConfig.toolTipTimeout
                ToolTip.visible: hovered

                onClicked: {
                    sampleDiagram.removeLastChalkLine()
                }
            }
        }
    }
}
