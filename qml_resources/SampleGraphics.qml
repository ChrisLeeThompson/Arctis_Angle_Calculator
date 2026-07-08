import QtQuick
import QtQuick.Shapes
import "."
import "diagramFunctions.js" as Draw
import "millingAngleCalculations.js" as Calc

// Sample Graphics (rotating layer)
//
// Cartoon cross-section of the sample/grid plus the FIB "chalk lines". The
// sample, grid, and chalk lines rotate with the stage (canvas rotation
// -alphaTiltAngle). Chalk lines are created along the FIB and stored by their
// canvas-frame angle; coloring (perpendicular = mint, parallel = pink) comes
// from millingAngleCalculations.js. This component owns the chalk-line list
// and exposes the chalk canvas angles for the reference overlay's chips.

Item {
    id: root

    property real alphaTiltAngle: 0

    // Chalk lines stored in canvas-local coordinates (relative to unrotated sample)
    // Each line: {startX, startY, endX, endY, canvasAngle}
    property var chalkLines: []

    // Expose line count for button state binding.
    readonly property int chalkLineCount: chalkLines.length

    // Canvas angles of the current chalk lines (consumed by the reference
    // overlay to build the per-beam chip lists).
    readonly property var chalkCanvasAngles: {
        var arr = []
        for (var i = 0; i < chalkLines.length; i++)
            arr.push(chalkLines[i].canvasAngle)
        return arr
    }

    // Highlight colors (used for the chalk-line coloring below).
    readonly property color perpendicularHighlightColor: AppConfig.perpendicularHighlightColor
    readonly property color parallelHighlightColor: AppConfig.parallelHighlightColor

    function addChalkLine() {
        var centerX = canvas.width / 2
        var centerY = canvas.height / 2

        // FIB is fixed at 142 deg in the reference frame; the canvas rotates
        // by -alphaTiltAngle, so the FIB appears at (142 - alphaTiltAngle) in
        // canvas-local coordinates.
        var fibAngleInCanvasCoords = Calc.chalkLineCanvasAngleDeg(alphaTiltAngle)

        var sampleWidth = AppConfig.referenceCircleRadius * AppConfig.sampleRectangleWidthFactor
        var sampleHeight = AppConfig.sampleRectangleHeight
        var gridWidth = AppConfig.referenceCircleRadius * AppConfig.gridRectangleWidthFactor
        var gridHeight = AppConfig.gridRectangleHeight

        var allIntersections = []

        var sampleIntersections = Draw.lineRotatedRectangleIntersection(
            centerX, centerY, fibAngleInCanvasCoords,
            centerX, centerY,
            sampleWidth, sampleHeight, 0
        )
        allIntersections = allIntersections.concat(sampleIntersections)

        var gridCenterY = centerY + (sampleHeight / 2) + (gridHeight / 2)
        var gridIntersections = Draw.lineRotatedRectangleIntersection(
            centerX, centerY, fibAngleInCanvasCoords,
            centerX, gridCenterY,
            gridWidth, gridHeight, 0
        )
        allIntersections = allIntersections.concat(gridIntersections)

        if (allIntersections.length >= 2) {
            // Find the two most distant intersection points.
            var maxDist = 0
            var startIdx = 0
            var endIdx = 1

            for (var i = 0; i < allIntersections.length; i++) {
                for (var j = i + 1; j < allIntersections.length; j++) {
                    var dx = allIntersections[j].x - allIntersections[i].x
                    var dy = allIntersections[j].y - allIntersections[i].y
                    var dist = Math.sqrt(dx * dx + dy * dy)
                    if (dist > maxDist) {
                        maxDist = dist
                        startIdx = i
                        endIdx = j
                    }
                }
            }

            var newLine = {
                startX: allIntersections[startIdx].x,
                startY: allIntersections[startIdx].y,
                endX: allIntersections[endIdx].x,
                endY: allIntersections[endIdx].y,
                canvasAngle: fibAngleInCanvasCoords
            }

            var updatedLines = chalkLines.slice()
            updatedLines.push(newLine)
            chalkLines = updatedLines

            canvas.requestPaint()
        }
    }

    function removeLastChalkLine() {
        if (chalkLines.length > 0) {
            var updatedLines = chalkLines.slice()
            updatedLines.pop()
            chalkLines = updatedLines
            canvas.requestPaint()
        }
    }

    function clearAllChalkLines() {
        if (chalkLines.length > 0) {
            chalkLines = []
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.centerIn: parent
        width: parent.width
        height: parent.height

        rotation: -alphaTiltAngle

        smooth: true
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var centerX = width / 2
            var centerY = height / 2

            // Sample rectangle
            var sampleWidth = AppConfig.referenceCircleRadius * AppConfig.sampleRectangleWidthFactor
            var sampleHeight = AppConfig.sampleRectangleHeight
            ctx.fillStyle = AppConfig.accentColor
            ctx.fillRect(
                centerX - sampleWidth / 2,
                centerY - sampleHeight / 2,
                sampleWidth,
                sampleHeight
            )

            // Grid rectangle
            var gridWidth = AppConfig.referenceCircleRadius * AppConfig.gridRectangleWidthFactor
            var gridHeight = AppConfig.gridRectangleHeight
            var gridTop = centerY + sampleHeight / 2

            ctx.strokeStyle = AppConfig.textPrimary
            ctx.lineWidth = 1
            ctx.strokeRect(
                centerX - gridWidth / 2,
                gridTop,
                gridWidth,
                gridHeight
            )

            // Chalk lines, colored by relation. Priority: perpendicular >
            // parallel > default.
            ctx.lineWidth = AppConfig.chalkLineWidth

            for (var i = 0; i < chalkLines.length; i++) {
                var line = chalkLines[i]

                var relFIB = Calc.chalkLineRelation(line.canvasAngle, alphaTiltAngle, "FIB")
                var relSEM = Calc.chalkLineRelation(line.canvasAngle, alphaTiltAngle, "SEM")
                var relGIS = Calc.chalkLineRelation(line.canvasAngle, alphaTiltAngle, "GIS")

                var anyPerp = relFIB === Calc.RELATION_PERPENDICULAR
                           || relSEM === Calc.RELATION_PERPENDICULAR
                           || relGIS === Calc.RELATION_PERPENDICULAR
                var anyParallel = relFIB === Calc.RELATION_PARALLEL
                               || relSEM === Calc.RELATION_PARALLEL
                               || relGIS === Calc.RELATION_PARALLEL

                if (anyPerp) {
                    ctx.strokeStyle = root.perpendicularHighlightColor
                } else if (anyParallel) {
                    ctx.strokeStyle = root.parallelHighlightColor
                } else {
                    ctx.strokeStyle = AppConfig.waitingForUserInput
                }

                ctx.beginPath()
                ctx.moveTo(line.startX, line.startY)
                ctx.lineTo(line.endX, line.endY)
                ctx.stroke()
            }
        }
    }

    Connections {
        target: root
        function onAlphaTiltAngleChanged() {
            canvas.requestPaint()
        }
    }
}
