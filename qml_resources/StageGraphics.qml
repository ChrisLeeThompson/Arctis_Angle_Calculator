// StageGraphics.qml
import QtQuick
import "."

Item {
    id: root

    // Properties that will control the stage orientation
    property real millingAngle: millingAngle
    property real alphaTiltAngle: alphaTiltAngle

    // Canvas for the alpha tilt indicator arc
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
                // For positive angles (0 to 15°), paint counter-clockwise from 0°
                startAngle = 0
                endAngle = -currentAngle * Math.PI / 180
                // Draw counter-clockwise
                ctx.beginPath()
                ctx.arc(centerX, centerY, circleRadius, startAngle, endAngle, true)
                ctx.stroke()
            } else {
                // For negative angles, paint clockwise from 0° to current angle
                var referenceStartAngle = 0 * Math.PI / 180
                var referenceEndAngle = 190 * Math.PI / 180

                startAngle = referenceStartAngle
                endAngle = -currentAngle * Math.PI / 180

                // Clamp to reference arc boundaries
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

    // SVG image of stage and grid
    Image {
        id: stageImage
        anchors.centerIn: parent
        anchors.verticalCenterOffset: AppConfig.stageImageVerticalOffset
        width: AppConfig.stageImageWidth
        height: AppConfig.stageImageHeight
        source: "../script_assets/stage_and_grid.svg"
        fillMode: Image.PreserveAspectFit

        // Rotate based on alpha tilt angle
        rotation: -alphaTiltAngle

        // Smooth rendering for better quality
        smooth: true
        antialiasing: true
    }
}
