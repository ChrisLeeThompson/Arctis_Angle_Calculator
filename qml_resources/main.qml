import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Window
import "."

// Main window: the angle controls on top, the stage and sample figures below.
// Sizes itself to the content, clamped to the screen work area.

ApplicationWindow {
    id: app_window

    // ---- Natural content size ----
    readonly property real idealWidth: mainColumnLayout.implicitWidth + (AppConfig.groupBoxMargins * 2)
    readonly property real idealHeight: mainColumnLayout.implicitHeight + (AppConfig.groupBoxMargins * 2)

    // ---- Screen work area (already excludes the taskbar / panels) ----
    readonly property real availableWidth: Screen.desktopAvailableWidth
    readonly property real availableHeight: Screen.desktopAvailableHeight

    // width/height below describe the CLIENT area only — the OS draws the
    // title bar and borders on top. Reserve a fixed pixel allowance for that
    // frame so the OUTER window still fits inside the work area on small
    // screens; the frame is a roughly fixed pixel size, so a fixed reserve
    // fits it better than a percentage would.
    readonly property real frameAllowance: 96

    // ---- Usability floor ----
    readonly property real minimumWindowWidth: 400
    readonly property real minimumWindowHeight: 300

    // ---- Target size: the content's natural size, clamped to what fits ----
    // idealWidth/idealHeight already include the figures at full scale plus
    // every internal margin, so this is the natural full-size window - never
    // larger than the work area (minus the window frame).
    readonly property real targetWidth: Math.max(minimumWindowWidth, Math.min(idealWidth, availableWidth - frameAllowance))
    readonly property real targetHeight: Math.max(minimumWindowHeight, Math.min(idealHeight, availableHeight - frameAllowance))

    // Open at the target size. The maximum is capped there too: on a large
    // monitor the window cannot be dragged wider or taller than its natural
    // size, so the layout never gains empty space. The user can still resize
    // down to the usability floor.
    width: targetWidth
    height: targetHeight
    minimumWidth: minimumWindowWidth
    minimumHeight: minimumWindowHeight
    maximumWidth: targetWidth
    maximumHeight: targetHeight

    // Center the whole frame inside the work area on first show, so a window
    // that is nearly as tall as the screen isn't placed with its bottom edge
    // (and title bar / resize grip) pushed off-screen. x/y are ASSIGNED, not
    // bound, so the user stays free to move the window afterward.
    Component.onCompleted: {
        x = Screen.virtualX + Math.max(0, (availableWidth - width) / 2)
        y = Screen.virtualY + Math.max(0, (availableHeight - height) / 2)
    }

    // ---- Figure auto-fit ----
    // On a small display the figures (AppConfig.stageDiagramWidth/Height),
    // plus the controls and margins, won't fit. Shrink them uniformly so the
    // whole UI fits without scrolling. Driven by the DISPLAY's work area, not
    // the live window size, so the natural content size — and therefore the
    // window's maximum — stays stable and there is no resize feedback loop.
    // 1.0 on a roomy display (figures at full size); never below
    // minFigureScale.
    readonly property real minFigureScale: 0.5

    // Non-figure vertical chrome: the controls panel plus the stacked margins
    // and group-box padding above and below the figure row. A slightly
    // generous estimate is fine — it only shrinks the figures a little
    // sooner, and the ScrollView absorbs anything left over.
    readonly property real figureVerticalChrome: angleInputsGroupBox.implicitHeight + 72

    readonly property real figureFitScale: Math.max(minFigureScale, Math.min(1.0,
        ((availableHeight - frameAllowance) - figureVerticalChrome) / AppConfig.stageDiagramHeight,
        (((availableWidth - frameAllowance) - 48) / 2) / AppConfig.stageDiagramWidth))

    visible: true
    title: qsTr("Arctis Angle Calculator") + " " + AppConfig.appVersion
    color: AppConfig.backgroundColor

    // Toggle for the alternative (back-of-grid, BOG) milling angle
    // calculation, applied when the alpha tilt is below the BOG threshold.
    property bool useAlternativeMillingAngleMode: false

    // ScrollView provides scrollbars when the content exceeds the window size.
    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.margins: AppConfig.groupBoxMargins

        // Only show scrollbars when needed.
        ScrollBar.horizontal.policy: contentWidth > width ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: contentHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

        // Content dimensions.
        contentWidth: mainColumnLayout.implicitWidth
        contentHeight: mainColumnLayout.implicitHeight

        // Clip content to the viewport.
        clip: true

        ColumnLayout {
            id: mainColumnLayout

            // Center the content when the window is larger than it.
            x: Math.max(0, (scrollView.width - implicitWidth) / 2)

            AngleControlsGB {
                id: angleInputsGroupBox
                Layout.margins: AppConfig.groupBoxMargins
                millingAngleRealValue: AppConfig.initialMillingAngle
                alphaTiltRealValue: AppConfig.initialAlphaTiltAngle
                useAlternativeMillingAngleMode: app_window.useAlternativeMillingAngleMode
            }

            RowLayout {

                Layout.fillWidth: true

                StageDiagramGB {
                    id: stageDiagramGroupBox
                    Layout.margins: AppConfig.groupBoxMargins
                    figureFitScale: app_window.figureFitScale
                    millingAngle: angleInputsGroupBox.millingAngleRealValue
                    alphaTiltAngle: angleInputsGroupBox.alphaTiltRealValue
                    onAlphaTiltClickedSignal: function(newAlphaTilt) {
                        angleInputsGroupBox.animateAlphaTiltTo(newAlphaTilt)
                    }
                    onAlphaTiltAdjusted: function(newAlphaTilt) {
                        // Wheel: set directly (no animation) so the figure
                        // tracks the wheel.
                        angleInputsGroupBox.alphaTiltRealValue = newAlphaTilt
                    }
                }

                SampleDiagramGB {
                    id: sampleDiagramGroupBox
                    Layout.margins: AppConfig.groupBoxMargins
                    figureFitScale: app_window.figureFitScale
                    alphaTiltAngle: angleInputsGroupBox.alphaTiltRealValue
                    onAlphaTiltChangeRequested: function(newAlphaTilt) {
                        angleInputsGroupBox.animateAlphaTiltTo(newAlphaTilt)
                    }
                    onAlphaTiltAdjusted: function(newAlphaTilt) {
                        // Wheel: set directly (no animation) so the figure
                        // tracks the wheel.
                        angleInputsGroupBox.alphaTiltRealValue = newAlphaTilt
                    }
                }
            }
        }
    }
}
