// StageDiagram.qml
import QtQuick
import QtQuick.Controls
import "."

Item {

    // properties to control the diagram
    property real millingAngle: millingAngle
    property real alphaTiltAngle: alphaTiltAngle

    signal alphaTiltClickedFromDiagram(real newAlphaTilt)

    id: root

    implicitWidth: AppConfig.stageDiagramWidth
    implicitHeight: AppConfig.stageDiagramHeight

    // ---- Scroll-wheel tilt adjustment ----
    // Wheel over the figure steps the alpha tilt directly (AppConfig
    // .wheelTiltStepDeg per notch, clamped to the stage limits) via
    // alphaTiltAdjusted - the page applies it WITHOUT animation so the figure
    // tracks the wheel snappily. angleDelta accumulates into standard 120-unit
    // notches, coalescing high-resolution trackpad event floods into clean
    // steps. This consumes plain wheel events over the figure, so the page
    // ScrollView only scrolls when the cursor is outside the figures.
    signal alphaTiltAdjusted(real newAlphaTilt)

    property real _wheelAccumulator: 0

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            root._wheelAccumulator += event.angleDelta.y
            var steps = Math.trunc(root._wheelAccumulator / 120)
            if (steps === 0)
                return
            root._wheelAccumulator -= steps * 120
            var target = Math.min(AppConfig.maxAlphaTilt,
                          Math.max(AppConfig.minAlphaTilt,
                                   root.alphaTiltAngle
                                   + steps * AppConfig.wheelTiltStepDeg))
            if (target !== root.alphaTiltAngle)
                root.alphaTiltAdjusted(target)
        }
    }

    // Static reference lines
    StageReferenceGraphics {
        id: stageReferenceGraphics
        anchors.fill: parent
        anchors.centerIn: parent
        millingAngle: root.millingAngle
        onAlphaTiltChanged: function(newAlphatilt) {
            root.alphaTiltClickedFromDiagram(newAlphatilt)
        }
    }

    // Dynamic stage graphics
    StageGraphics {
        id: stageGraphics
        anchors.fill: parent
        millingAngle: root.millingAngle
        alphaTiltAngle: root.alphaTiltAngle
    }
}
