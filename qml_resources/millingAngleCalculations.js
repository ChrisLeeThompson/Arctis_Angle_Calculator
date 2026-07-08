.pragma library

// =============================================================================
// MILLING ANGLE CALCULATIONS  (Arctis Angle Calculator)
//
// Pure geometry library for the Arctis milling-angle figures. This file is
// the single source of truth for the Arctis side-view geometry. It is a
// QML `.pragma library` (stateless, shared) and reads NO QML singletons:
// anything environment-specific (the stage tilt limits) is passed in as an
// argument so AppConfig stays the single source of truth for UI limits.
//
// Instrument geometry (side view, screen angles measured CCW from
// horizontal-right, matching diagramFunctions.js):
//
//   * SEM column is vertical, pointing up      ->  90 deg
//   * FIB column is 52 deg LEFT of the SEM     -> 142 deg   (90 + 52)
//   * GIS needle                               -> 123.5 deg
//   * iFLM column is vertical, pointing down   -> 270 deg   (reference line
//       only; the current detection set is SEM / FIB / GIS, so iFLM is
//       provided as a constant for the drawing layer but is not part of
//       chalkLineRelation / achievableTiltsForBeam.)
//
// Stage model:
//   The Arctis Compustage tilts on a SINGLE axis (alpha). There is no stage
//   rotation regime (unlike the Hydra AutoGrid calculator), so none of the
//   functions here take a regime argument. The alpha tilt range
//   (AppConfig.minAlphaTilt / maxAlphaTilt, currently -190 .. +10) is passed
//   into the achievable-tilt functions as (tiltMinDeg, tiltMaxDeg).
//
// Milling angle relationship:
//   millingAngle = FIB_MILLING_OFFSET_DEG + alphaTilt        (= 38 + alpha)
//   Back-of-grid (BOG) milling angle, used only when the BOG toggle is on
//   AND alpha < BOG_ALPHA_THRESHOLD_DEG:
//       millingAngle = BOG_BASE_DEG - (FIB_MILLING_OFFSET_DEG + alphaTilt)
//                    = -180 - (38 + alpha)
//   When BOG mode is on, milling -> alpha is also BOG-aware: a milling angle
//   whose back-of-grid tilt lands in the BOG range inverts to that tilt (see
//   alphaTiltForDisplay). Such a milling angle also has a front-of-grid
//   solution; BOG mode resolves the ambiguity toward the back-of-grid tilt.
//
// Chalk lines (FIB cuts on the sample):
//   A chalk line is always created along the FIB direction and is stored by
//   its angle in the ROTATING canvas frame ("canvasAngle"). The canvas
//   rotates by -alphaTilt relative to the fixed reference frame, so:
//       globalAngle = canvasAngle + alphaTilt
//   and a line created at alpha = a has canvasAngle = FIB(142) - a, i.e. its
//   global angle equals the FIB angle at the moment of creation.
//
//   "Parallel" and "perpendicular" are properties of undirected lines, so
//   every angle comparison is made modulo 180 deg (lineAngleDifferenceDeg).
//
// Equivalence:
//   This library reproduces, over the real input domain, the behavior of the
//   previous per-beam helpers (isLinePerpTo* / isLineParallelTo*) and the
//   six achievable-angle properties that lived inline in SampleGraphics.qml.
//   See tests/test_millingAngleCalculations.mjs (run with node) for the
//   anchor-point checks and the equivalence sweep against the old logic.
// =============================================================================

// -----------------------------------------------------------------------------
// GEOMETRY CONSTANTS (screen angles, degrees, CCW from horizontal-right)
// -----------------------------------------------------------------------------

var SEM_SCREEN_ANGLE_DEG = 90.0
var FIB_SCREEN_ANGLE_DEG = 142.0
var GIS_SCREEN_ANGLE_DEG = 123.5
var IFLM_SCREEN_ANGLE_DEG = 270.0   // reference line only (see header)

// Milling-angle offset between alpha tilt and milling angle.
var FIB_MILLING_OFFSET_DEG = 38.0

// Back-of-grid (BOG) milling-angle parameters.
var BOG_ALPHA_THRESHOLD_DEG = -128.0
var BOG_BASE_DEG = -180.0

// -----------------------------------------------------------------------------
// RELATION TOLERANCES / NAMES
// -----------------------------------------------------------------------------

// Single tolerance for both relations (the old code used 0.1 for each).
var RELATION_TOLERANCE_DEG = 0.1

// De-duplication tolerance for achievable-tilt lists (old code used 0.01).
var ACHIEVABLE_DEDUP_TOLERANCE_DEG = 0.01

var RELATION_PARALLEL = "parallel"
var RELATION_PERPENDICULAR = "perpendicular"
var RELATION_NONE = "none"

// -----------------------------------------------------------------------------
// MILLING ANGLE <-> ALPHA TILT CONVERSIONS
// -----------------------------------------------------------------------------

// Milling angle (deg) for a given alpha tilt (deg).
function calculateMillingAngle(alphaTiltDeg) {
    return FIB_MILLING_OFFSET_DEG + alphaTiltDeg
}

// Alpha tilt (deg) for a given milling angle (deg). Exact inverse of
// calculateMillingAngle().
function calculateAlphaTilt(millingAngleDeg) {
    return millingAngleDeg - FIB_MILLING_OFFSET_DEG
}

// Back-of-grid milling angle (deg) for a given alpha tilt (deg).
function calculateBogMillingAngle(alphaTiltDeg) {
    return BOG_BASE_DEG - (FIB_MILLING_OFFSET_DEG + alphaTiltDeg)
}

// Milling angle to DISPLAY for a given alpha tilt, applying the BOG branch
// only when BOG mode is enabled AND alpha is below the BOG threshold. This
// encapsulates the threshold logic that previously appeared (twice) inline
// in AngleControlsGB.qml.
function millingAngleForDisplay(alphaTiltDeg, useBogMode) {
    if (useBogMode && alphaTiltDeg < BOG_ALPHA_THRESHOLD_DEG)
        return calculateBogMillingAngle(alphaTiltDeg)
    return calculateMillingAngle(alphaTiltDeg)
}

// Back-of-grid alpha tilt (deg) for a given milling angle (deg): the direct
// inverse of calculateBogMillingAngle. Solving
//   milling = BOG_BASE_DEG - (FIB_MILLING_OFFSET_DEG + alpha)
// for alpha gives alpha = BOG_BASE_DEG - FIB_MILLING_OFFSET_DEG - milling.
function calculateBogAlphaTilt(millingAngleDeg) {
    return BOG_BASE_DEG - FIB_MILLING_OFFSET_DEG - millingAngleDeg
}

// Alpha tilt to DISPLAY for a typed milling angle - the inverse companion of
// millingAngleForDisplay. In BOG mode, a milling angle whose back-of-grid tilt
// lands in the BOG range (below the threshold and within the tilt limit)
// inverts to that BOG tilt; everything else uses the plain inverse. This
// mirrors the conditional structure of millingAngleForDisplay, so BOG tilts and
// clearly front-of-grid milling angles both round-trip. NOTE: a milling angle
// in the BOG range also has a front-of-grid solution - BOG mode resolves the
// ambiguity toward the back-of-grid tilt.
function alphaTiltForDisplay(millingAngleDeg, useBogMode, tiltMinDeg) {
    if (useBogMode) {
        var bogAlpha = calculateBogAlphaTilt(millingAngleDeg)
        if (bogAlpha < BOG_ALPHA_THRESHOLD_DEG && bogAlpha >= tiltMinDeg)
            return bogAlpha
    }
    return calculateAlphaTilt(millingAngleDeg)
}

// -----------------------------------------------------------------------------
// CHALK-LINE GEOMETRY
// -----------------------------------------------------------------------------

// Canvas-frame angle of a chalk line created (along the FIB) at the given
// alpha tilt. The canvas rotates by -alpha, so the fixed FIB direction
// appears at FIB - alpha in canvas coordinates.
function chalkLineCanvasAngleDeg(alphaTiltDeg) {
    return FIB_SCREEN_ANGLE_DEG - alphaTiltDeg
}

// Fixed-frame (global) angle of a chalk line, given its stored canvas angle
// and the current alpha tilt.
function chalkLineGlobalAngleDeg(canvasAngleDeg, alphaTiltDeg) {
    return canvasAngleDeg + alphaTiltDeg
}

// Screen angle of a beam by name ("SEM" / "FIB" / "GIS").
function beamScreenAngleDeg(beamName) {
    if (beamName === "SEM")
        return SEM_SCREEN_ANGLE_DEG
    if (beamName === "FIB")
        return FIB_SCREEN_ANGLE_DEG
    if (beamName === "GIS")
        return GIS_SCREEN_ANGLE_DEG
    throw new Error("Unknown beam: " + beamName)
}

// Minimal angular difference between two undirected lines, in [0, 90].
function lineAngleDifferenceDeg(angleADeg, angleBDeg) {
    var d = (angleADeg - angleBDeg) % 180
    if (d < 0)
        d += 180
    return Math.min(d, 180 - d)
}

// Relation of a chalk line (by its canvas angle) to a beam at the given
// alpha tilt: RELATION_PERPENDICULAR, RELATION_PARALLEL, or RELATION_NONE.
// Perpendicular and parallel are 90 deg apart, so a line can hold at most
// one relation to a given beam; perpendicular is reported first for safety.
function chalkLineRelation(canvasAngleDeg, alphaTiltDeg, beamName) {
    var g = chalkLineGlobalAngleDeg(canvasAngleDeg, alphaTiltDeg)
    var d = lineAngleDifferenceDeg(g, beamScreenAngleDeg(beamName))
    if (Math.abs(d - 90) <= RELATION_TOLERANCE_DEG)
        return RELATION_PERPENDICULAR
    if (d <= RELATION_TOLERANCE_DEG)
        return RELATION_PARALLEL
    return RELATION_NONE
}

// -----------------------------------------------------------------------------
// ACHIEVABLE ALPHA TILTS
// -----------------------------------------------------------------------------
//
// A chalk line at canvas angle C has global angle C + alpha. It is in the
// requested relation to beam B (screen angle beta) when
//     C + alpha  ==  beta + offset   (mod 180)
// with offset = 0 for parallel and 90 for perpendicular. Solving for alpha:
//     alpha == (beta + offset - C)   (mod 180)
// i.e. alpha = base + 180*n for integer n, base = beta + offset - C. The
// stage tilt range spans < 360 deg, so this yields one or two solutions.

// All alpha tilts within [tiltMinDeg, tiltMaxDeg] at which the chalk line
// (by its canvas angle) attains the given relation to the beam. Returns a
// plain array of alpha values (unsorted).
function achievableTiltsForRelation(canvasAngleDeg, beamName, relation,
                                    tiltMinDeg, tiltMaxDeg) {
    var offset
    if (relation === RELATION_PARALLEL)
        offset = 0
    else if (relation === RELATION_PERPENDICULAR)
        offset = 90
    else
        throw new Error("Unknown relation: " + relation)

    var base = beamScreenAngleDeg(beamName) + offset - canvasAngleDeg
    var tilts = []
    // Iterate n over a padded window and filter on the inclusive bounds, so
    // the range check (and any floating-point boundary case) matches the old
    // isValidAngle(): keep when tiltMin <= alpha <= tiltMax.
    var nLow = Math.floor((tiltMinDeg - base) / 180) - 1
    var nHigh = Math.ceil((tiltMaxDeg - base) / 180) + 1
    for (var n = nLow; n <= nHigh; n++) {
        var alpha = base + 180 * n
        if (alpha >= tiltMinDeg && alpha <= tiltMaxDeg)
            tilts.push(alpha)
    }
    return tilts
}

// All achievable alpha tilts for one beam and ONE relation over a set of
// chalk lines (array of canvas angles), de-duplicated WITHIN the relation
// and sorted ascending. Returns a plain array of alpha values. Reproduces
// the old per-relation achievable<Beam><Relation>Angles properties (whose
// de-duplication was within a single relation, not across both).
function achievableTiltsForBeamRelation(canvasAnglesDeg, beamName, relation,
                                        tiltMinDeg, tiltMaxDeg) {
    var alphas = []
    for (var i = 0; i < canvasAnglesDeg.length; i++) {
        var tilts = achievableTiltsForRelation(
            canvasAnglesDeg[i], beamName, relation, tiltMinDeg, tiltMaxDeg)
        for (var j = 0; j < tilts.length; j++) {
            var duplicate = false
            for (var e = 0; e < alphas.length; e++) {
                if (Math.abs(alphas[e] - tilts[j])
                        < ACHIEVABLE_DEDUP_TOLERANCE_DEG) {
                    duplicate = true
                    break
                }
            }
            if (!duplicate)
                alphas.push(tilts[j])
        }
    }
    alphas.sort(function(a, b) { return a - b })
    return alphas
}

// Combined, de-duplicated, ascending list of every achievable
// { alphaTilt, relation } for one beam over a set of chalk lines (array of
// canvas angles), within the alpha tilt limits. This is the list a beam's
// chip row is built from, and the alpha values match the old combined
// achievable<Beam>Angles array (now each tagged with its relation).
// Perpendicular is processed before parallel so that, on the (degenerate)
// chance of a tie within the dedup tolerance, perpendicular wins.
function achievableTiltsForBeam(canvasAnglesDeg, beamName,
                                tiltMinDeg, tiltMaxDeg) {
    var entries = []
    var relations = [RELATION_PERPENDICULAR, RELATION_PARALLEL]
    for (var i = 0; i < canvasAnglesDeg.length; i++) {
        for (var r = 0; r < relations.length; r++) {
            var tilts = achievableTiltsForRelation(
                canvasAnglesDeg[i], beamName, relations[r],
                tiltMinDeg, tiltMaxDeg)
            for (var j = 0; j < tilts.length; j++) {
                var duplicate = false
                for (var e = 0; e < entries.length; e++) {
                    if (Math.abs(entries[e].alphaTilt - tilts[j])
                            < ACHIEVABLE_DEDUP_TOLERANCE_DEG) {
                        duplicate = true
                        break
                    }
                }
                if (!duplicate)
                    entries.push({ alphaTilt: tilts[j],
                                   relation: relations[r] })
            }
        }
    }
    entries.sort(function(a, b) { return a.alphaTilt - b.alphaTilt })
    return entries
}
