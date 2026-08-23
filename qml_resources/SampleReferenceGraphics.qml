import QtQuick
import QtQuick.Controls
import "."
import "diagramFunctions.js" as Draw
import "millingAngleCalculations.js" as Calc

// Sample Reference Graphics (static overlay)
//
// Beam stubs and clickable SEM / FIB / GIS labels for the sample figure.
// All three labels sit on ONE shared arc (AppConfig.sampleBeamLabelRadius),
// and each beam line grows inward from the arc. The Arctis Compustage has no
// stage rotation, so the chip list for a beam is simply every achievable
// alpha tilt at which a chalk line is perpendicular or parallel to it.
//
// Label behavior:
//  * Clicking a label cycles the alpha tilt through that beam's achievable
//    positions, wrapping around.
//  * Numbered chips next to each label list every achievable position for
//    that beam, in ascending-tilt order. Each chip's border is tinted by its
//    relation — mint for perpendicular, pink for parallel — so the relation
//    reads at a glance. The border is dim at rest; when the stage is at the
//    chip's position (the chip's "active" state), the border brightens, the
//    chip gains a translucent relation-colored fill, and the number takes
//    the relation color. Hovering a chip shows a tooltip with the relation,
//    milling angle, and alpha tilt for that position. Clicking a chip
//    applies that position directly.
//
// The chip lists come from achievableTiltsForBeam() in
// millingAngleCalculations.js. Per-beam cycle indices reset whenever the
// chalk lines change.

Item {
    id: root

    // Canonical stage state and the chalk-line canvas angles drive everything.
    property real alphaTiltAngle: 0
    property var chalkCanvasAngles: []

    // Emitted when the user picks a position (label cycle or chip click).
    signal alphaTiltChangeRequested(real newAlphaTilt)

    readonly property real centerX: width / 2
    readonly property real centerY: height / 2

    readonly property color perpendicularHighlightColor: AppConfig.perpendicularHighlightColor
    readonly property color parallelHighlightColor: AppConfig.parallelHighlightColor

    // Per-beam achievable { alphaTilt, relation } entries, ascending by tilt.
    // Recomputed only when the chalk lines change.
    readonly property var _cycleLists: {
        var lists = {}
        var beams = ["SEM", "FIB", "GIS"]
        for (var i = 0; i < beams.length; i++) {
            lists[beams[i]] = Calc.achievableTiltsForBeam(
                chalkCanvasAngles, beams[i],
                AppConfig.minAlphaTilt, AppConfig.maxAlphaTilt)
        }
        return lists
    }

    // Per-beam cycle indices (view state), reset when the lists change.
    property var _cycleIndices: ({ SEM: 0, FIB: 0, GIS: 0 })
    on_CycleListsChanged: _cycleIndices = { SEM: 0, FIB: 0, GIS: 0 }

    // Apply a specific achievable position for a beam (used by the chips).
    function applyBeamEntry(beamName, entryIndex) {
        var list = _cycleLists[beamName]
        if (!list || entryIndex < 0 || entryIndex >= list.length)
            return
        root.alphaTiltChangeRequested(list[entryIndex].alphaTilt)
    }

    // Apply the next achievable position for a beam, wrapping around (used by
    // the label click).
    function cycleBeam(beamName) {
        var list = _cycleLists[beamName] || []
        if (list.length === 0)
            return
        var index = _cycleIndices[beamName] % list.length
        var updated = JSON.parse(JSON.stringify(_cycleIndices))
        updated[beamName] = (index + 1) % list.length
        _cycleIndices = updated
        root.alphaTiltChangeRequested(list[index].alphaTilt)
    }

    // ---- Static beam lines (do not rotate with the sample) ----
    Canvas {
        id: staticCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var lineOuter = AppConfig.sampleBeamLabelRadius
                            - AppConfig.sampleBeamLabelOffset
            var beamLen = AppConfig.sampleBeamLineLength
            var color = AppConfig.textPrimary
            var lineW = AppConfig.referenceLinesWidth

            var beams = ["SEM", "FIB", "GIS"]
            for (var i = 0; i < beams.length; i++) {
                var a = Calc.beamScreenAngleDeg(beams[i])
                if (beams[i] === "FIB") {
                    // FIB extends across the full diameter, reaching the arc
                    // on the far side too. Drawn as two center-out radials so
                    // it shares drawRadialLine's angle convention.
                    Draw.drawRadialLine(ctx, root.centerX, root.centerY,
                                        0, lineOuter, a, color, lineW)
                    Draw.drawRadialLine(ctx, root.centerX, root.centerY,
                                        0, lineOuter, a - 180, color, lineW)
                } else {
                    Draw.drawRadialLine(ctx, root.centerX, root.centerY,
                                        lineOuter - beamLen, beamLen,
                                        a, color, lineW)
                }
            }
        }
    }

    // ---- Labels on the shared arc, each with its chip row ----
    Repeater {
        model: [
            { name: "SEM", angle: Calc.beamScreenAngleDeg("SEM") },
            { name: "FIB", angle: Calc.beamScreenAngleDeg("FIB") },
            { name: "GIS", angle: Calc.beamScreenAngleDeg("GIS") }
        ]

        delegate: Label {
            id: beamLabel

            property string beamName: modelData.name
            property real beamAngle: modelData.angle

            // Chips sit on the outer side of the label: to the left for
            // beams at screen angle >= 90°, to the right otherwise. Keeps
            // the chip row off the center of the figure.
            readonly property bool _chipsOnLeft: beamAngle >= 90
            readonly property bool _canCycle: (root._cycleLists[beamName] || []).length > 0

            readonly property var _labelPos: Draw.getRadialLabelPosition(
                root.centerX, root.centerY,
                AppConfig.sampleBeamLabelRadius, 0, beamAngle, 0)

            x: _labelPos.x - width / 2
            y: _labelPos.y - height / 2

            text: beamName
            font.pixelSize: AppConfig.diagramLabelFontSize
            color: beamLabelMA.containsMouse ? AppConfig.accentColor
                                             : AppConfig.textPrimary

            background: Rectangle {
                anchors.centerIn: parent
                width: parent.width + AppConfig.labelBorderPadding
                height: parent.height + AppConfig.labelBorderPadding
                color: "transparent"
                border.color: (beamLabel._canCycle && beamLabelMA.containsMouse)
                              ? AppConfig.labelBorderBrightHighlight : "transparent"
                border.width: AppConfig.labelBorderWidth
                radius: AppConfig.buttonRadius
            }

            // Numbered position chips. Wraps to additional rows once the count
            // exceeds AppConfig.chipMaxPerRow, so a long list (e.g. FIB with
            // several chalk lines) stacks downward instead of running past the
            // group box. Rows fill from the label outward (right-to-left for
            // beams on the left side of the figure), and each new row stacks
            // below the one before it.
            Grid {
                id: chipRow
                columns: AppConfig.chipMaxPerRow
                flow: Grid.LeftToRight
                spacing: AppConfig.chipSpacing
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: beamLabel._chipsOnLeft ? undefined : parent.right
                anchors.leftMargin: beamLabel._chipsOnLeft ? 0 : AppConfig.chipRowMargin
                anchors.right: beamLabel._chipsOnLeft ? parent.left : undefined
                anchors.rightMargin: beamLabel._chipsOnLeft ? AppConfig.chipRowMargin : 0
                layoutDirection: beamLabel._chipsOnLeft ? Qt.RightToLeft
                                                        : Qt.LeftToRight

                Repeater {
                    model: root._cycleLists[beamLabel.beamName]

                    delegate: Rectangle {
                        id: chip

                        readonly property real _alphaTilt: modelData.alphaTilt
                        readonly property string _relation: modelData.relation

                        // Active when the stage is currently AT this position.
                        readonly property bool _active:
                            Math.abs(root.alphaTiltAngle - _alphaTilt)
                            <= Calc.RELATION_TOLERANCE_DEG

                        readonly property color _relationColor:
                            _relation === Calc.RELATION_PERPENDICULAR
                            ? root.perpendicularHighlightColor
                            : root.parallelHighlightColor

                        readonly property string _relationName:
                            _relation === Calc.RELATION_PERPENDICULAR
                            ? "Perpendicular" : "Parallel"

                        readonly property real _millingAngle:
                            Calc.calculateMillingAngle(_alphaTilt)

                        width: chipLabel.implicitWidth + AppConfig.chipHorizontalPadding
                        height: chipLabel.implicitHeight + AppConfig.chipVerticalPadding
                        radius: AppConfig.chipRadius
                        color: chip._active ? Qt.alpha(chip._relationColor, AppConfig.chipActiveFillOpacity)
                                            : "transparent"
                        border.width: AppConfig.labelBorderWidth
                        border.color: chipMA.containsMouse
                                      ? AppConfig.accentColor
                                      : Qt.alpha(chip._relationColor,
                                                 chip._active ? 1.0 : AppConfig.chipRestBorderOpacity)

                        ToolTip.text: chip._relationName + " to "
                                      + beamLabel.beamName + "\n"
                                      + "Milling angle: "
                                      + chip._millingAngle.toFixed(1) + "\u00B0\n"
                                      + "Alpha tilt: "
                                      + chip._alphaTilt.toFixed(1) + "\u00B0"
                        ToolTip.visible: chipMA.containsMouse
                        ToolTip.delay: AppConfig.toolTipDelay
                        ToolTip.timeout: AppConfig.toolTipTimeout

                        Label {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: index + 1
                            font.pixelSize: AppConfig.diagramLabelFontSize - AppConfig.chipFontSizeReduction
                            color: chip._active ? chip._relationColor
                                                : AppConfig.textPrimary
                        }

                        MouseArea {
                            id: chipMA
                            anchors.fill: parent
                            anchors.margins: -AppConfig.chipMouseAreaMargin
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyBeamEntry(beamLabel.beamName,
                                                           index)
                        }
                    }
                }
            }

            MouseArea {
                id: beamLabelMA
                anchors.fill: parent
                hoverEnabled: beamLabel._canCycle
                cursorShape: beamLabel._canCycle ? Qt.PointingHandCursor
                                                 : Qt.ArrowCursor
                onClicked: root.cycleBeam(beamLabel.beamName)
            }
        }
    }
}
