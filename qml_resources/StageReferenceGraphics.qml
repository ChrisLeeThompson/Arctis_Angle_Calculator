// StageReferenceGraphics.qml
import QtQuick
import QtQuick.Controls
import "."
import "diagramFunctions.js" as Draw

// Static protractor for the stage (alpha-tilt) figure.
//
// Everything on the gauge is data-driven by the two lists below, so adding or
// removing a reference point is a one-line edit - no copy-pasted Text/MouseArea
// blocks. On this gauge the alpha tilt IS the screen angle (0 deg = right,
// CCW), so a tick value is both where it's drawn and the tilt it applies when
// clicked.
//
//   * beamLabels - the beam-direction labels (SEM / FIB / GIS / iFLM). All sit
//     on ONE shared outer arc (radius + long reference line), matching the
//     sample figure. Each carries the tilt to apply when clicked.
//   * tickValues - the clickable gauge ticks. Each is drawn as a short radial
//     mark on the arc, labeled "<value>deg", and jumps the stage there.

Item {

	id: root

	property real referenceCircleRadius: AppConfig.referenceCircleRadius
	property real millingAngle: AppConfig.initialMillingAngle
	signal alphaTiltChanged(real newAlphaTilt)

	readonly property real centerX: width / 2
	readonly property real centerY: height / 2

	// ---- Reference points: edit these lists to add/remove gauge marks ----

	// Beam-direction labels on the shared outer arc. screenAngle = direction
	// the beam points (deg, 0 = right, CCW); alphaOnClick = tilt applied on click.
	readonly property var beamLabels: [
		{ text: "SEM",  screenAngle: 90,    alphaOnClick: 0    },
		{ text: "FIB",  screenAngle: 142,   alphaOnClick: -128 },
		{ text: "GIS",  screenAngle: 123.5, alphaOnClick: 10   },
		{ text: "iFLM", screenAngle: 270,   alphaOnClick: -180 }
	]

	// Clickable gauge ticks (alpha tilt, deg). Drawn at that angle on the arc,
	// labeled, and clicking jumps the stage there.
	readonly property var tickValues: [10, 0, -23, -38, -61.5, -128, -180, -190]

	// ---- Static gauge: arc + beam reference lines + tick marks ----
	Canvas {
		id: canvas
		anchors.fill: parent

		onPaint: {
			var ctx = getContext("2d")
			ctx.clearRect(0, 0, width, height)

			var cx = root.centerX
			var cy = root.centerY
			var r = root.referenceCircleRadius
			var stroke = AppConfig.textPrimary
			var lw = AppConfig.referenceLinesWidth
			var longLen = AppConfig.referenceLineLengthLong
			var shortLen = AppConfig.referenceLineLengthShort

			// Gauge arc over the reachable alpha-tilt range.
			Draw.drawArc(ctx, cx, cy, r,
						 AppConfig.minAlphaTilt, AppConfig.maxAlphaTilt,
						 stroke, lw)

			// Beam reference lines, one per beam label. FIB is special: it
			// extends inward to the stage graphic at the center (start radius
			// 0), matching the previous UI; the rest start at the circle edge.
			for (var b = 0; b < root.beamLabels.length; b++) {
				var beamAngle = root.beamLabels[b].screenAngle
				if (root.beamLabels[b].text === "FIB") {
					Draw.drawRadialLine(ctx, cx, cy, 0, r + longLen,
										beamAngle, stroke, lw)
				} else {
					Draw.drawRadialLine(ctx, cx, cy, r, longLen,
										beamAngle, stroke, lw)
				}
			}

			// Gauge tick marks (short), one per tick value.
			for (var t = 0; t < root.tickValues.length; t++) {
				Draw.drawRadialLine(ctx, cx, cy, r, shortLen,
									root.tickValues[t], stroke, lw)
			}
		}
	}

	// ---- Beam-direction labels (all on one outer arc) ----
	Repeater {
		model: root.beamLabels

		delegate: Label {
			id: beamLabel

			readonly property real _angle: modelData.screenAngle
			readonly property real _alpha: modelData.alphaOnClick
			readonly property var _pos: Draw.getRadialLabelPosition(
				root.centerX, root.centerY, root.referenceCircleRadius,
				AppConfig.referenceLineLengthLong, _angle,
				AppConfig.referenceLabelOffset)

			x: _pos.x - width / 2
			y: _pos.y - height / 2
			text: modelData.text
			font.pixelSize: AppConfig.diagramLabelFontSize
			color: beamMA.containsMouse ? AppConfig.accentColor
										: AppConfig.textPrimary

			background: Rectangle {
				anchors.centerIn: parent
				width: parent.width + AppConfig.labelBorderPadding
				height: parent.height + AppConfig.labelBorderPadding
				color: "transparent"
				border.color: beamMA.containsMouse
							  ? AppConfig.labelBorderBrightHighlight : "transparent"
				border.width: AppConfig.labelBorderWidth
				radius: AppConfig.buttonRadius
			}

			MouseArea {
				id: beamMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: root.alphaTiltChanged(beamLabel._alpha)
			}
		}
	}

	// ---- Clickable gauge tick labels ----
	Repeater {
		model: root.tickValues

		delegate: Label {
			id: tickLabel

			readonly property real _value: modelData
			readonly property var _pos: Draw.getRadialLabelPosition(
				root.centerX, root.centerY, root.referenceCircleRadius,
				AppConfig.referenceLineLengthShort, _value,
				AppConfig.referenceLabelOffset)

			x: _pos.x - width / 2
			y: _pos.y - height / 2
			text: _value + "\u00B0"
			font.pixelSize: AppConfig.diagramLabelFontSize
			color: tickMA.containsMouse ? AppConfig.accentColor
										: AppConfig.textPrimary

			background: Rectangle {
				anchors.centerIn: parent
				width: parent.width + AppConfig.labelBorderPadding
				height: parent.height + AppConfig.labelBorderPadding
				color: "transparent"
				border.color: tickMA.containsMouse
							  ? AppConfig.labelBorderBrightHighlight : "transparent"
				border.width: AppConfig.labelBorderWidth
				radius: AppConfig.buttonRadius
			}

			MouseArea {
				id: tickMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				onClicked: root.alphaTiltChanged(tickLabel._value)
			}
		}
	}

	// ---- Live milling-angle readout (not clickable) ----
	Text {
		id: millingAngleLabel
		text: root.millingAngle.toFixed(1) + "\u00B0"
		color: AppConfig.catBugOvenMit
		font.pixelSize: AppConfig.diagramLabelFontSize

		readonly property var _pos: Draw.getRadialLabelPosition(
			root.centerX, root.centerY, root.referenceCircleRadius,
			25, -210, 0)
		x: _pos.x - width / 2
		y: _pos.y - height / 2
	}
}
