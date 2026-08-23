// StageGraphics.qml
import QtQuick
import "."

// Rotating layer of the stage figure: the alpha-tilt indicator arc and the
// stage/grid SVG, both driven by alphaTiltAngle.

Item {
    id: root

    // Properties that control the stage orientation.
    property real millingAngle: millingAngle
    property real alphaTiltAngle: alphaTiltAngle

    // Canvas for the alpha-tilt indicator arc.
    Canvas {

        property real currentAngle: root.alphaTiltAngle

        id: alphaTiltArc
        anchors.fill: parent

        onCurrentAngleChanged: {
            requestPaint()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var centerX = width / 2
            var centerY = height / 2
            var circleRadius = AppConfig.referenceCircleRadius
            ctx.strokeStyle = AppConfig.alphaTiltColor
            ctx.lineWidth = AppConfig.alphaTiltArcWidth

            var startAngle
            var endAngle

            if (currentAngle > 0) {
                // For positive angles, paint counter-clockwise from 0° to the
                // current angle.
                startAngle = 0
                endAngle = -currentAngle * Math.PI / 180
                ctx.beginPath()
                ctx.arc(centerX, centerY, circleRadius, startAngle, endAngle, true)
                ctx.stroke()
            } else {
                // For negative angles, paint clockwise from 0° to the current
                // angle.
                var referenceStartAngle = 0 * Math.PI / 180
                var referenceEndAngle = 190 * Math.PI / 180

                startAngle = referenceStartAngle
                endAngle = -currentAngle * Math.PI / 180

                // Clamp to the reference arc's range.
                if (endAngle < referenceStartAngle) {
                    endAngle = referenceStartAngle
                }
                if (endAngle > referenceEndAngle) {
                    endAngle = referenceEndAngle
                }

                ctx.beginPath()
                ctx.arc(centerX, centerY, circleRadius, startAngle, endAngle, false)
                ctx.stroke()
            }
        }
    }

    // SVG image of the stage and grid.
    Image {
        id: stageImage
        anchors.centerIn: parent
        anchors.verticalCenterOffset: AppConfig.stageImageVerticalOffset
        width: AppConfig.stageImageWidth
        height: AppConfig.stageImageHeight
        source: "../script_assets/stage_and_grid.svg"
        fillMode: Image.PreserveAspectFit

        // Rotate with the alpha tilt angle.
        rotation: -alphaTiltAngle

        smooth: true
        antialiasing: true
    }
}
