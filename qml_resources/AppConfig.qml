pragma Singleton
import QtQuick

QtObject {

    // Application version (shown in the window title)
    readonly property string appVersion: "1.2.2"

    // Main window color palette
    readonly property color backgroundColor: "#1e2c36"
    readonly property color accentColor: "#2ea2ec"
    readonly property color textPrimary: "#ffffff"

    // Tooltip
    readonly property int toolTipDelay: 1500
    readonly property int toolTipTimeout: 10000

    // Tooltip strings
    readonly property string millingAngleToolTip: "Milling angle (deg.) calculated from the alpha tilt angle. Formula: 38° + alpha tilt."
    readonly property string alphaTiltAngleToolTip: "Alpha tilt angle (deg.) calculated from the milling angle. Formula: milling angle − 38°."
    readonly property string connectToMicroscopeToolTip: "Connect to the microscope's AutoScript server to enable the Get and Go To buttons (requires AutoScript).\n\nGet reads the current alpha tilt angle of the stage. Go To tilts the stage to the set alpha tilt angle."
    readonly property string bogMillingAngleToolTip: "Toggles the back-of-grid (BOG) milling angle calculation.\n\nWhen enabled and the alpha tilt is below −128°, the milling angle = −180° − (38° + alpha tilt)."
    readonly property string getButtonToolTip: "Read the current alpha tilt angle from the stage."
    readonly property string goToButtonToolTip: "Tilt the stage to the set alpha tilt angle."
    readonly property string addChalkLineButtonToolTip: "Add a chalk line along the FIB direction at the current alpha tilt."
    readonly property string removeLastButtonToolTip: "Remove the most recent chalk line."

    // Label
    readonly property int labelWidth: 170

    // GroupBox
    readonly property color groupBoxBackground: "#263640"
    readonly property color groupBoxBorder: "#354552"
    readonly property int groupBoxRadius: 4
    readonly property int groupBoxBorderWidth: 1
    readonly property int groupBoxMargins: 6
    readonly property int groupBoxSpacing: 10

    // Button
    readonly property int buttonRadius: 2
    readonly property color buttonColor: "#263741"
    readonly property color buttonBackgroundDisabled: "#1a2329"
    readonly property color buttonBorderDisabled: "#2a343d"
    readonly property color buttonTextDisabled: "#5a6670"

    // SpinBox
    readonly property color spinBoxBackground: "transparent"
    readonly property color spinBoxBorder: groupBoxBorder
    readonly property color spinBoxText: textPrimary
    readonly property color spinBoxHighlight: groupBoxBorder
    readonly property int spinBoxRadius: 2
    readonly property int spinBoxBorderWidth: 2
    readonly property int spinBoxLeftMargin: 20
    readonly property color spinBoxBackgroundDisabled: "#1a2329"
    readonly property color spinBoxBorderDisabled: "#2a343d"
    readonly property color spinBoxTextDisabled: "#5a6670"

    // ===================== Diagram interaction =====================
    readonly property real maxAlphaTilt: 10.0
    readonly property real minAlphaTilt: -190.0
    readonly property real initialMillingAngle: 38.0
    readonly property real initialAlphaTiltAngle: 0.0

    // Alpha tilt change per scroll-wheel notch over the stage/sample figures.
    readonly property real wheelTiltStepDeg: 1

    // ===================== Figure geometry =====================
    // One multiplier resizes BOTH figures uniformly. Every dimension below is
    // <base> * figureScale, so changing this single number grows the whole
    // diagram - canvas, protractor, sample/grid, beam arc, and shuttle -
    // together, and the surrounding layout reflows. Line weights, fonts, and
    // the relation chips keep a fixed size (see "Figure styling" below).
    readonly property real figureScale: 1.0

    // Shared figure canvas (both diagrams use this size).
    readonly property real stageDiagramWidth: 720 * figureScale
    readonly property real stageDiagramHeight: 720 * figureScale

    // Protractor / reference circle and its reference + tick line lengths.
    readonly property real referenceCircleRadius: 232.6655 * figureScale
    readonly property real referenceLineLengthLong: 100 * figureScale   // SEM / FIB / iFLM lines
    readonly property real referenceLineLengthShort: 50 * figureScale   // horizontals + radial ticks
    readonly property real referenceLabelOffset: 18 * figureScale       // gauge label gap beyond its line

    // Sample (chalk-line) figure: sample slab + grid rectangle.
    readonly property real sampleRectangleHeight: 50 * figureScale
    readonly property real gridRectangleHeight: 6 * figureScale
    readonly property real sampleRectangleWidthFactor: 1.9   // x referenceCircleRadius
    readonly property real gridRectangleWidthFactor: 2.05    // x referenceCircleRadius

    // Sample-figure beam labels (SEM / FIB / GIS) on one shared arc, with
    // numbered perpendicular/parallel chips (see SampleReferenceGraphics.qml).
    readonly property real sampleBeamLabelRadius: referenceCircleRadius + 100 * figureScale
    readonly property real sampleBeamLineLength: 60 * figureScale
    readonly property real sampleBeamLabelOffset: 18 * figureScale

    // Stage shuttle SVG (drawn in StageGraphics).
    readonly property real stageImageWidth: 465.331 * 0.8 * figureScale
    readonly property real stageImageHeight: 53.961 * 0.8 * figureScale
    readonly property real stageImageVerticalOffset: 10 * figureScale

    // ===================== Figure styling (fixed size) =====================
    readonly property int diagramLabelFontSize: 18
    readonly property real referenceLinesWidth: 0.5
    readonly property int gridRectangleLineWidth: 1
    readonly property int chalkLineWidth: 4
    readonly property real alphaTiltArcWidth: 3
    readonly property int labelBorderPadding: 6
    readonly property int labelBorderWidth: 1
    readonly property color labelBorderBrightHighlight: Qt.lighter(groupBoxBorder, 1.3)
    readonly property color referenceLines: "#ffffff"
    readonly property color alphaTiltColor: "#00a200" //"#33ff33"
    readonly property color waitingForUserInput: "#f6b436"
    readonly property color catBugOvenMit: "#eb70a9"

    // ===================== Beam relation chips =====================
    readonly property color perpendicularHighlightColor: "#70EBB2" // mint - perpendicular
    readonly property color parallelHighlightColor: "#eb70a9"      // pink - parallel
    readonly property int chipFontSizeReduction: 6   // chip number font = diagramLabelFontSize - this
    readonly property real chipHorizontalPadding: 8
    readonly property real chipVerticalPadding: 2
    readonly property real chipRadius: 3
    readonly property real chipSpacing: 3
    readonly property real chipRowMargin: 6
    readonly property real chipMouseAreaMargin: 2
    readonly property real chipActiveFillOpacity: 0.18
    readonly property real chipRestBorderOpacity: 0.45
    readonly property int chipMaxPerRow: 5            // chips wrap to a new row past this count

}

