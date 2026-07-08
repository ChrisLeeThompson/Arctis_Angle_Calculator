.pragma library

// =============================================================================
// DIAGRAM FUNCTIONS
// Shared drawing utilities for Stage and Sample diagram components
// =============================================================================

// -----------------------------------------------------------------------------
// CORE DRAWING
// -----------------------------------------------------------------------------

// Generic line drawing function (used internally by other draw functions)
function drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth) {
    ctx.strokeStyle = strokeStyle;
    ctx.lineWidth = lineWidth;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();
}

// -----------------------------------------------------------------------------
// REFERENCE LINES - Fixed position lines for SEM, FIB, iFLM, etc.
// -----------------------------------------------------------------------------

// Draw SEM line (vertical, pointing up from center)
function drawSEMLine(ctx, centerX, centerY, referenceCircleRadius,
                     lineLength, strokeStyle, lineWidth) {
    var startX = centerX;
    var startY = centerY - referenceCircleRadius;
    var endX = centerX;
    var endY = centerY - (lineLength + referenceCircleRadius);
    drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth);
}

// Draw FIB line (52° to the left of vertical/SEM)
// In standard coordinates: 90° + 52° = 142° from positive x-axis
function drawFIBLine(ctx, centerX, centerY, referenceCircleRadius,
                     lineLength, strokeStyle, lineWidth) {
    var fibAngleStandard = (90 + 52) * Math.PI / 180;
    var startX = centerX;
    var startY = centerY;
    var endX = centerX + (referenceCircleRadius + lineLength) * Math.cos(fibAngleStandard);
    var endY = centerY - (referenceCircleRadius + lineLength) * Math.sin(fibAngleStandard);
    drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth);
}

// Draw iFLM line (vertical, pointing down from center, opposite of SEM)
function drawIFLMLine(ctx, centerX, centerY, referenceCircleRadius,
                      lineLength, strokeStyle, lineWidth) {
    var startX = centerX;
    var startY = centerY + referenceCircleRadius;
    var endX = centerX;
    var endY = centerY + (lineLength + referenceCircleRadius);
    drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth);
}

// Draw horizontal reference lines (left and right from center)
function drawHorizontalLines(ctx, centerX, centerY, referenceCircleRadius,
                             lineLength, strokeStyle, lineWidth) {
    // Left line
    drawLine(ctx,
        centerX - referenceCircleRadius - lineLength, centerY,
        centerX - referenceCircleRadius, centerY,
        strokeStyle, lineWidth);
    // Right line
    drawLine(ctx,
        centerX + referenceCircleRadius, centerY,
        centerX + referenceCircleRadius + lineLength, centerY,
        strokeStyle, lineWidth);
}

// -----------------------------------------------------------------------------
// RADIAL LINES - Lines at arbitrary angles from center
// -----------------------------------------------------------------------------

// Draw radial line at specified angle
// angleDeg: 0° = right (horizontal), positive = counter-clockwise
function drawRadialLine(ctx, centerX, centerY, referenceCircleRadius,
                        lineLength, angleDeg, strokeStyle, lineWidth) {
    var angleRad = angleDeg * Math.PI / 180;
    var startX = centerX + referenceCircleRadius * Math.cos(angleRad);
    var startY = centerY - referenceCircleRadius * Math.sin(angleRad);
    var endX = centerX + (referenceCircleRadius + lineLength) * Math.cos(angleRad);
    var endY = centerY - (referenceCircleRadius + lineLength) * Math.sin(angleRad);
    drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth);
}

// Draw a diameter line through the center at a specified angle
// angleDeg: 0 = right (horizontal), positive = counter-clockwise
function drawDiameterLine(ctx, centerX, centerY, referenceCircleRadius,
                          angleDeg, strokeStyle, lineWidth) {
    var angleRad = angleDeg * Math.PI / 180;
    // Start point (on one side of circle)
    var startX = centerX - referenceCircleRadius * Math.cos(angleRad);
    var startY = centerY - referenceCircleRadius * Math.sin(angleRad);
    // End point (on opposite side of circle)
    var endX = centerX + referenceCircleRadius * Math.cos(angleRad);
    var endY = centerY + referenceCircleRadius * Math.sin(angleRad);
    drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth);
}

// Draw asymmetric line from center
// Extends lineLength in the positive angle direction
// Extends only to referenceCircleRadius in the opposite direction
function drawAsymmetricCenterLine(ctx, centerX, centerY, referenceCircleRadius,
                                  lineLength, angleDeg, strokeStyle, lineWidth) {
    var angleRad = angleDeg * Math.PI / 180;
    // Start point (on opposite side, at edge of reference circle)
    var startX = centerX - referenceCircleRadius * Math.cos(angleRad);
    var startY = centerY + referenceCircleRadius * Math.sin(angleRad);
    // End point (extended in the angleDeg direction)
    var endX = centerX + lineLength * Math.cos(angleRad);
    var endY = centerY - lineLength * Math.sin(angleRad);
    drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth);
}

// -----------------------------------------------------------------------------
// ARC DRAWING
// -----------------------------------------------------------------------------

// Draw arc between two angles
// Note: Canvas arc uses 0° = right, positive = clockwise
// This function uses counter-clockwise convention (positive = CCW)
function drawArc(ctx, centerX, centerY, radius, startAngleDeg,
                 endAngleDeg, strokeStyle, lineWidth) {
    ctx.strokeStyle = strokeStyle;
    ctx.lineWidth = lineWidth;
    // Negate angles to convert from CCW to canvas CW convention
    var startAngle = -startAngleDeg * Math.PI / 180;
    var endAngle = -endAngleDeg * Math.PI / 180;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, startAngle, endAngle, true);
    ctx.stroke();
}

// -----------------------------------------------------------------------------
// LABEL POSITIONING HELPERS
// -----------------------------------------------------------------------------

// Calculate label position at end of radial line
// angleDeg: 0° = right, positive = counter-clockwise
// labelOffset: additional distance beyond line end (default = 0)
function getRadialLabelPosition(centerX, centerY, referenceCircleRadius,
                                lineLength, angleDeg, labelOffset) {
    var angleRad = angleDeg * Math.PI / 180;
    var lineEndX = centerX + (referenceCircleRadius + lineLength) * Math.cos(angleRad);
    var lineEndY = centerY - (referenceCircleRadius + lineLength) * Math.sin(angleRad);
    var offset = labelOffset || 0;
    return {
        x: lineEndX + offset * Math.cos(angleRad),
        y: lineEndY - offset * Math.sin(angleRad)
    };
}

// Calculate FIB line label position (fixed at 142°)
// labelOffset: additional distance beyond line end (default = 0)
function getFIBLabelPosition(centerX, centerY, referenceCircleRadius,
                             lineLength, labelOffset) {
    var fibAngleStandard = (90 + 52) * Math.PI / 180;  // 142°
    var lineEndX = centerX + (referenceCircleRadius + lineLength) * Math.cos(fibAngleStandard);
    var lineEndY = centerY - (referenceCircleRadius + lineLength) * Math.sin(fibAngleStandard);
    var offset = labelOffset || 0;
    return {
        x: lineEndX + offset * Math.cos(fibAngleStandard),
        y: lineEndY - offset * Math.sin(fibAngleStandard)
    };
}

// -----------------------------------------------------------------------------
// INTERSECTION CALCULATIONS - For chalk line feature
// -----------------------------------------------------------------------------

// Calculate intersection between a ray and a rotated rectangle
// Returns array of intersection points [{x, y}, ...]
function lineRotatedRectangleIntersection(lineCenterX, lineCenterY, lineAngleDeg,
                                          rectCenterX, rectCenterY,
                                          rectWidth, rectHeight, rectRotationDeg) {
    var intersections = [];
    var rectRotRad = -rectRotationDeg * Math.PI / 180;  // Negative for QML clockwise rotation

    // Rectangle corners in local coordinates (before rotation)
    var corners = [
        {x: -rectWidth/2, y: -rectHeight/2},  // top-left
        {x: rectWidth/2, y: -rectHeight/2},   // top-right
        {x: rectWidth/2, y: rectHeight/2},    // bottom-right
        {x: -rectWidth/2, y: rectHeight/2}    // bottom-left
    ];

    // Transform corners to global coordinates
    var rotatedCorners = corners.map(function(corner) {
        return {
            x: rectCenterX + corner.x * Math.cos(rectRotRad) - corner.y * Math.sin(rectRotRad),
            y: rectCenterY + corner.x * Math.sin(rectRotRad) + corner.y * Math.cos(rectRotRad)
        };
    });

    // Check intersection with each edge
    for (var i = 0; i < 4; i++) {
        var p1 = rotatedCorners[i];
        var p2 = rotatedCorners[(i + 1) % 4];

        var intersection = lineLineIntersection(
            lineCenterX, lineCenterY, lineAngleDeg,
            p1.x, p1.y, p2.x, p2.y
        );

        if (intersection) {
            // Avoid duplicate points at corners
            var isDuplicate = intersections.some(function(existing) {
                var dx = existing.x - intersection.x;
                var dy = existing.y - intersection.y;
                return Math.sqrt(dx*dx + dy*dy) < 0.1;
            });
            if (!isDuplicate) {
                intersections.push(intersection);
            }
        }
    }

    return intersections;
}

// Calculate intersection between a ray (from point at angle) and a line segment
// Returns intersection point {x, y} or null if no intersection
function lineLineIntersection(rayCenterX, rayCenterY, rayAngleDeg,
                              segX1, segY1, segX2, segY2) {
    var rayAngleRad = rayAngleDeg * Math.PI / 180;

    // Ray direction vector (negative Y because canvas Y is inverted)
    var rayDx = Math.cos(rayAngleRad);
    var rayDy = -Math.sin(rayAngleRad);

    // Segment direction vector
    var segDx = segX2 - segX1;
    var segDy = segY2 - segY1;

    // Solve using parametric equations
    var denominator = rayDx * segDy - rayDy * segDx;
    if (Math.abs(denominator) < 0.0001) {
        return null;  // Parallel or collinear
    }

    var t = ((segX1 - rayCenterX) * segDy - (segY1 - rayCenterY) * segDx) / denominator;
    var u = ((segX1 - rayCenterX) * rayDy - (segY1 - rayCenterY) * rayDx) / denominator;

    // Check if intersection is on the segment (0 <= u <= 1)
    if (u >= 0 && u <= 1) {
        return {
            x: rayCenterX + t * rayDx,
            y: rayCenterY + t * rayDy
        };
    }

    return null;
}
