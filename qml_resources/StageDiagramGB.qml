import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

GroupBox {

    property real millingAngle: millingAngle
    property real alphaTiltAngle: alphaTiltAngle

    // 1.0 = full size; < 1.0 shrinks the figure uniformly to fit a small display.
    // Only the figure is scaled - the GroupBox border and padding stay full size.
    property real figureFitScale: 1.0

    signal alphaTiltClickedSignal(real newAlphaTilt)

    // Emitted when the user adjusts alpha tilt with the scroll wheel
    // (applied without animation by the page).
    signal alphaTiltAdjusted(real newAlphaTilt)

    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: contentItem.implicitHeight + topPadding + bottomPadding
    background: Rectangle {
        color: AppConfig.backgroundColor
        border.color: AppConfig.groupBoxBorder
        radius: AppConfig.groupBoxRadius
    }

    focusPolicy: Qt.StrongFocus

    // The figure is drawn at its natural design size and scaled uniformly by
    // figureFitScale. The slot's implicit size shrinks by the same factor, so the
    // GroupBox - and the layout around it - reclaim the freed space. The scale is
    // applied only to the figure, so the border and padding keep their size.
    contentItem: Item {
        id: figureSlot
        implicitWidth: AppConfig.stageDiagramWidth * root.figureFitScale
        implicitHeight: AppConfig.stageDiagramHeight * root.figureFitScale

        StageDiagram {
            id: stageDiagram
            width: AppConfig.stageDiagramWidth
            height: AppConfig.stageDiagramHeight

            // Scale about the top-centre: the figure stays centred horizontally
            // and fills the shrunk slot vertically (top-aligned, height 720*scale).
            transformOrigin: Item.Top
            scale: root.figureFitScale
            x: (figureSlot.width - width) / 2

            millingAngle: root.millingAngle
            alphaTiltAngle: root.alphaTiltAngle
            onAlphaTiltClickedFromDiagram: function(newAlphaTilt) {
                root.alphaTiltClickedSignal(newAlphaTilt)
            }

            onAlphaTiltAdjusted: function(newAlphaTilt) {
                root.alphaTiltAdjusted(newAlphaTilt)
            }
        }
    }

}
