// SampleDiagram.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

// Composes the rotating sample/chalk layer (SampleGraphics) with the static
// beam-label + chip overlay (SampleReferenceGraphics). The overlay computes
// its own per-beam chip lists from the chalk canvas angles, so this wrapper
// only forwards the canonical stage state and the chalk angles.

Item {
    id: root

    property real alphaTiltAngle: AppConfig.initialAlphaTiltAngle

    // Emitted when the user picks a position via a beam label or chip.
    signal alphaTiltChangeRequested(real newAlphaTilt)

    // ---- Scroll-wheel tilt adjustment ----
    // Wheel over the figure steps the alpha tilt directly by
    // AppConfig.wheelTiltStepDeg per notch, clamped to the stage limits, via
    // alphaTiltAdjusted — the page applies it WITHOUT animation so the figure
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

    // Exposed for chalk-line button state binding.
    readonly property int chalkLineCount: sampleGraphics.chalkLineCount

    implicitWidth: AppConfig.stageDiagramWidth
    implicitHeight: AppConfig.stageDiagramHeight

    function addChalkLine() {
        sampleGraphics.addChalkLine()
    }

    function removeLastChalkLine() {
        sampleGraphics.removeLastChalkLine()
    }

    function clearAllChalkLines() {
        sampleGraphics.clearAllChalkLines()
    }

    SampleGraphics {
        id: sampleGraphics
        anchors.fill: parent
        alphaTiltAngle: root.alphaTiltAngle
    }

    SampleReferenceGraphics {
        id: sampleReferenceGraphics
        anchors.fill: parent
        alphaTiltAngle: root.alphaTiltAngle
        chalkCanvasAngles: sampleGraphics.chalkCanvasAngles

        onAlphaTiltChangeRequested: function(newAlphaTilt) {
            root.alphaTiltChangeRequested(newAlphaTilt)
        }
    }
}
