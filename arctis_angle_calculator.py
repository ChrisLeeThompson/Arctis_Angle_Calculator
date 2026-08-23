# This Python file uses the following encoding: utf-8
"""
Arctis Angle Calculator
.
A PySide6/QML desktop UI that calculates and visualizes milling angles and
stage tilt angles for a Thermo Scientific Arctis microscope. Draw chalk lines
at different milling angles to explore milling procedures and GIS deposition
positions. The UI runs standalone, or connects to a microscope via AutoScript
(>= 4.13) to get and set the stage's alpha tilt.
.
Authors: Chris Thompson (GitHub: ChrisLeeThompson) and Anthropic's Claude
.
Copyright (c) 2026 Christopher Thompson.
Released under the MIT License -- see the LICENSE file.
"""
import os
import sys
import logging
import math
from pathlib import Path
from PySide6.QtCore import (Signal, Slot, QObject,
                            QThread, QTimer)
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine


class ArctisAngleCalcOperator(QObject):
    """QML-facing backend; forwards UI requests to the worker thread."""

    status_label_signal: Signal = Signal(str)
    connected_to_microscope_signal: Signal = Signal(bool)
    connect_switch_enable_signal: Signal = Signal(bool)
    stage_move_signal: Signal = Signal(bool)
    current_alpha_position_signal: Signal = Signal(float)

    request_connect_signal: Signal = Signal()
    request_disconnect_signal: Signal = Signal()
    request_tilt_signal: Signal = Signal(float)
    request_get_alpha_signal: Signal = Signal()

    def __init__(self):
        super().__init__()
        self.worker = None
        self.worker_thread = None

    @Slot()
    def start_thread(self):
        """Create and start the worker thread for microscope operations."""
        if self.worker_thread is not None and self.worker_thread.isRunning():
            logging.warning("Worker thread already running")
            return
        # Create the worker and its thread.
        self.worker = ArctisAngleCalcWorker()
        self.worker_thread = QThread()
        self.worker.moveToThread(self.worker_thread)
        # Connect signals from the worker to the operator.
        self.worker.worker_status_label_signal.connect(self.status_label_signal)
        self.worker.connected_to_microscope_signal.connect(self.connected_to_microscope_signal)
        self.worker.connect_switch_enable_signal.connect(self.connect_switch_enable_signal)
        self.worker.stage_move_signal.connect(self.stage_move_signal)
        self.worker.current_alpha_position_signal.connect(self.current_alpha_position_signal)
        # Connect signals from the operator to the worker.
        self.request_connect_signal.connect(self.worker.connect_to_microscope)
        self.request_disconnect_signal.connect(self.worker.disconnect_from_microscope)
        self.request_tilt_signal.connect(self.worker.tilt_stage_to_alpha)
        self.request_get_alpha_signal.connect(self.worker.get_current_alpha_tilt)
        # Log the thread lifecycle.
        self.worker_thread.started.connect(lambda: logging.info("Worker thread started"))
        self.worker_thread.finished.connect(lambda: logging.info("Worker thread finished"))
        # Start the thread.
        self.worker_thread.start()
        logging.info("Worker thread initialized and started")

    @Slot()
    def connect_to_microscope(self):
        """Create the worker thread on first use and request a connection.

        Called from QML when the user switches Connect To Microscope on.
        """
        # Create the thread on the first connection attempt.
        if self.worker_thread is None:
            logging.info("First connection attempt — creating worker thread")
            self.start_thread()
        # Verify the thread is running.
        if not self.worker_thread.isRunning():
            logging.error("Worker thread failed to start")
            self.connected_to_microscope_signal.emit(False)
            return
        # Request a connection to the microscope.
        self.request_connect_signal.emit()

    @Slot()
    def disconnect_from_microscope(self):
        """Request disconnection from the AutoScript server. Called from QML."""
        self.request_disconnect_signal.emit()

    @Slot(float)
    def tilt_stage_to_alpha(self, alpha_tilt_degrees: float):
        """Request a stage tilt to the given alpha tilt angle (deg.). Called from QML."""
        if self.worker_thread is None or not self.worker_thread.isRunning():
            logging.error("Worker thread not running")
            return
        self.request_tilt_signal.emit(alpha_tilt_degrees)

    @Slot()
    def get_current_alpha_tilt(self):
        """Request the stage's current alpha tilt angle from the worker. Called from QML."""
        if self.worker_thread is None or not self.worker_thread.isRunning():
            logging.error("Worker thread not running")
            return
        self.request_get_alpha_signal.emit()

    def cleanup_thread(self):
        """Disconnect from the microscope and stop the worker thread.

        Called via app.aboutToQuit; force-terminates the thread if it has
        not finished after 5 s.
        """
        if self.worker_thread is None:
            return
        logging.info("Cleaning up worker thread...")
        # Disconnect from the microscope if connected.
        if self.worker and self.worker.is_connected:
            try:
                self.request_disconnect_signal.emit()
                self.worker_thread.wait(3000)
            except Exception as e:
                logging.error(f"Error disconnecting from microscope: {e}", exc_info=True)
        # Request the thread to quit and wait for it.
        self.worker_thread.quit()
        if not self.worker_thread.wait(5000):
            logging.warning("Thread did not finish gracefully, terminating...")
            self.worker_thread.terminate()
            self.worker_thread.wait()
        # Clean up references.
        self.worker = None
        self.worker_thread = None
        logging.info("Worker thread cleanup complete.")


class ArctisAngleCalcWorker(QObject):
    """Worker that performs microscope calls off the GUI thread."""

    worker_status_label_signal: Signal = Signal(str)
    connected_to_microscope_signal: Signal = Signal(bool)
    connect_switch_enable_signal: Signal = Signal(bool)
    stage_move_signal: Signal = Signal(bool)
    current_alpha_position_signal: Signal = Signal(float)

    def __init__(self):
        super().__init__()
        self.is_connected: bool = False

    @Slot()
    def connect_to_microscope(self):
        """Import AutoScript and connect to the AutoScript server."""
        try:
            self.connect_switch_enable_signal.emit(False)           # Disable the switch while connecting.
            self.worker_status_label_signal.emit("Connecting…")
            logging.info("Importing AutoScript...")
            from autoscript_sdb_microscope_client.sdb_microscope_client import SdbMicroscopeClient
            logging.info("AutoScript imported")
            # Create the microscope object and connect to the AutoScript server.
            self.microscope = SdbMicroscopeClient()
            logging.info("Connecting to AutoScript server...")
            self.microscope.connect()
            self.is_connected = True
            self.worker_status_label_signal.emit("")                # Clear the status label.
            self.connect_switch_enable_signal.emit(True)            # Enable the switch.
            self.connected_to_microscope_signal.emit(True)          # Enable the Get and Go To buttons.
        except Exception as e:
            logging.error(f"Exception occurred: {e}", exc_info=True)
            self.worker_status_label_signal.emit("Connection failed.")
            self.connected_to_microscope_signal.emit(False)         # Switch the toggle off.
            self.connect_switch_enable_signal.emit(True)
            self.is_connected = False
            # Clear the error message after 10 seconds.
            QTimer.singleShot(10000, lambda: self.worker_status_label_signal.emit(""))

    @Slot()
    def disconnect_from_microscope(self):
        """Disconnect from the microscope."""
        logging.info("Disconnecting from microscope...")
        self.microscope.disconnect()
        self.connect_switch_enable_signal.emit(True)
        self.connected_to_microscope_signal.emit(False)             # Disable the Get and Go To buttons.
        self.is_connected = False

    @Slot(float)
    def tilt_stage_to_alpha(self, alpha_tilt_degrees: float):
        """Tilt the Compustage to the given alpha tilt angle (deg.)."""
        from autoscript_sdb_microscope_client.structures import CompustagePosition
        from autoscript_sdb_microscope_client.enumerations import CoordinateSystem
        # Set the default coordinate system.
        self.microscope.specimen.compustage.set_default_coordinate_system(coordinate_system=CoordinateSystem.SPECIMEN)
        # Convert degrees to radians.
        alpha_tilt_radians = math.radians(alpha_tilt_degrees)
        logging.info(f"alpha tilt (degrees): {alpha_tilt_degrees}")
        logging.info(f"alpha tilt (radians): {alpha_tilt_radians}")
        # Disable the Get and Go To buttons and the connect switch while the stage moves.
        self.stage_move_signal.emit(True)
        self.worker_status_label_signal.emit("Tilting stage…")
        # Tilt the stage.
        position = CompustagePosition(a=alpha_tilt_radians)
        self.microscope.specimen.compustage.absolute_move(position)
        logging.info(f"Stage tilted to: {self.microscope.specimen.compustage.current_position.a}")
        # Signal that the stage move is complete.
        self.stage_move_signal.emit(False)
        # Clear the status label.
        self.worker_status_label_signal.emit("")

    @Slot()
    def get_current_alpha_tilt(self):
        """Read the stage's current alpha tilt and emit it in degrees."""
        from autoscript_sdb_microscope_client.enumerations import CoordinateSystem
        # Set the default coordinate system.
        self.microscope.specimen.compustage.set_default_coordinate_system(coordinate_system=CoordinateSystem.SPECIMEN)
        # Read the alpha tilt and convert it to degrees.
        alpha_tilt_radians = self.microscope.specimen.compustage.current_position.a
        logging.info(f"Current alpha tilt (radians): {alpha_tilt_radians}")
        alpha_tilt_degrees = float(math.degrees(alpha_tilt_radians))
        logging.info(f"Current alpha tilt (degrees): {alpha_tilt_degrees}")
        self.current_alpha_position_signal.emit(alpha_tilt_degrees)


def setup_logging():
    """Configure logging for the application."""
    logging.basicConfig(format="%(asctime)s:\t%(levelname)s:\t%(funcName)s:\t%(message)s", level=logging.DEBUG)


def main():
    """Build the Qt application, load the QML, and run the event loop."""
    setup_logging()

    base_path = Path(__file__).parent
    qml_resources_path = base_path / "qml_resources"
    config_file_path = base_path / "qml_resources" / "qtquickcontrols2.conf"

    # Point Qt Quick Controls at the style configuration.
    os.environ["QT_QUICK_CONTROLS_CONF"] = str(config_file_path)

    # Create the application.
    app = QGuiApplication(sys.argv)

    # Set the window icon.
    window_icon_path = qml_resources_path / "icons" / "catbug_waiting_color.png"
    app.setWindowIcon(QIcon(str(window_icon_path)))

    # Create the QML engine.
    engine = QQmlApplicationEngine()

    # Instantiate the backend and expose it to QML as a context property.
    arctis_angle_calc_backend = ArctisAngleCalcOperator()
    engine.rootContext().setContextProperty("arctis_angle_calc_backend", arctis_angle_calc_backend)

    # Connect the cleanup method to application exit.
    app.aboutToQuit.connect(arctis_angle_calc_backend.cleanup_thread)

    # Load the QML file.
    qml_file = qml_resources_path / "main.qml"
    if not qml_file.exists():
        logging.error(f"QML file not found: {qml_file}")
        sys.exit(-1)

    engine.load(str(qml_file))

    engine.quit.connect(app.quit)
    if not engine.rootObjects():
        logging.error("Failed to load QML file")
        sys.exit(-1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
