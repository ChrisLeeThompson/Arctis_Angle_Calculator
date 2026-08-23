.pragma library

// =============================================================================
// DIAGRAM FUNCTIONS
// Shared drawing utilities for the stage and sample diagram components.
// =============================================================================

// -----------------------------------------------------------------------------
// CORE DRAWING
// -----------------------------------------------------------------------------

// Generic line segment between two points (used by the other draw helpers).
function drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth) {
    ctx.strokeStyle = strokeStyle;
    ctx.lineWidth = lineWidth;
    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.lineTo(endX, endY);
    ctx.stroke();
}

// -----------------------------------------------------------------------------
// RADIAL LINES
// -----------------------------------------------------------------------------

// Draw a radial line at the specified angle, starting at
// referenceCircleRadius from the center and extending lineLength outward.
// angleDeg: 0° = right (horizontal), positive = counter-clockwise.
function drawRadialLine(ctx, centerX, centerY, referenceCircleRadius,
                        lineLength, angleDeg, strokeStyle, lineWidth) {
    var angleRad = angleDeg * Math.PI / 180;
    var startX = centerX + referenceCircleRadius * Math.cos(angleRad);
    var startY = centerY - referenceCircleRadius * Math.sin(angleRad);
    var endX = centerX + (referenceCircleRadius + lineLength) * Math.cos(angleRad);
    var endY = centerY - (referenceCircleRadius + lineLength) * Math.sin(angleRad);
    drawLine(ctx, startX, startY, endX, endY, strokeStyle, lineWidth);
}

// -----------------------------------------------------------------------------
// ARC DRAWING
// -----------------------------------------------------------------------------

// Draw an arc between two angles. Canvas arcs use 0° = right with positive =
// clockwise; this function takes counter-clockwise angles and negates them
// for the canvas.
function drawArc(ctx, centerX, centerY, radius, startAngleDeg,
                 endAngleDeg, strokeStyle, lineWidth) {
    ctx.strokeStyle = strokeStyle;
    ctx.lineWidth = lineWidth;
    var startAngle = -startAngleDeg * Math.PI / 180;
    var endAngle = -endAngleDeg * Math.PI / 180;
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, startAngle, endAngle, true);
    ctx.stroke();
}

// -----------------------------------------------------------------------------
// LABEL POSITIONING HELPERS
// -----------------------------------------------------------------------------

// Calculate the label position at the end of a radial line.
// angleDeg: 0° = right, positive = counter-clockwise.
// labelOffset: additional distance beyond the line end (treated as 0 when
// omitted).
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

// -----------------------------------------------------------------------------
// INTERSECTION CALCULATIONS — for the chalk-line feature
// -----------------------------------------------------------------------------

// Calculate the intersections between an infinite line (through a point at
// an angle) and a rotated rectangle. Returns an array of intersection points
// [{x, y}, ...].
function lineRotatedRectangleIntersection(lineCenterX, lineCenterY, lineAngleDeg,
                                          rectCenterX, rectCenterY,
                                          rectWidth, rectHeight, rectRotationDeg) {
    var intersections = [];
    var rectRotRad = -rectRotationDeg * Math.PI / 180;  // Negative for QML clockwise rotation.

    // Rectangle corners in local coordinates (before rotation).
    var corners = [
        {x: -rectWidth/2, y: -rectHeight/2},  // top-left
        {x: rectWidth/2, y: -rectHeight/2},   // top-right
        {x: rectWidth/2, y: rectHeight/2},    // bottom-right
        {x: -rectWidth/2, y: rectHeight/2}    // bottom-left
    ];

    // Transform the corners to global coordinates.
    var rotatedCorners = corners.map(function(corner) {
        return {
            x: rectCenterX + corner.x * Math.cos(rectRotRad) - corner.y * Math.sin(rectRotRad),
            y: rectCenterY + corner.x * Math.sin(rectRotRad) + corner.y * Math.cos(rectRotRad)
        };
    });

    // Check the intersection with each edge.
    for (var i = 0; i < 4; i++) {
        var p1 = rotatedCorners[i];
        var p2 = rotatedCorners[(i + 1) % 4];

        var intersection = lineLineIntersection(
            lineCenterX, lineCenterY, lineAngleDeg,
            p1.x, p1.y, p2.x, p2.y
        );

        if (intersection) {
            // Avoid duplicate points at corners.
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

// Calculate the intersection between an infinite line (through a point at an
// angle) and a line segment. Returns the intersection point {x, y}, or null
// when there is none.
function lineLineIntersection(rayCenterX, rayCenterY, rayAngleDeg,
                              segX1, segY1, segX2, segY2) {
    var rayAngleRad = rayAngleDeg * Math.PI / 180;

    // Line direction vector (negative Y because canvas Y is inverted).
    var rayDx = Math.cos(rayAngleRad);
    var rayDy = -Math.sin(rayAngleRad);

    // Segment direction vector.
    var segDx = segX2 - segX1;
    var segDy = segY2 - segY1;

    // Solve using parametric equations.
    var denominator = rayDx * segDy - rayDy * segDx;
    if (Math.abs(denominator) < 0.0001) {
        return null;  // Parallel or collinear.
    }

    var t = ((segX1 - rayCenterX) * segDy - (segY1 - rayCenterY) * segDx) / denominator;
    var u = ((segX1 - rayCenterX) * rayDy - (segY1 - rayCenterY) * rayDx) / denominator;

    // Check that the intersection is on the segment (0 <= u <= 1).
    if (u >= 0 && u <= 1) {
        return {
            x: rayCenterX + t * rayDx,
            y: rayCenterY + t * rayDy
        };
    }

    return null;
}
