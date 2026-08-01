# This Python file uses the following encoding: utf-8
"""
Arctis Angle Calculator
'
Calculates and visualizes milling angles and stage tilt angles for a Thermo Scientific Arctis microscope.
It allows the user to draw lines at different milling angles to explore milling procedures and GIS deposition positions.
The UI can be used with or without connecting to a microscope with AutoScript. When connected to a microscope, the UI allows the user to get and set the stage's alpha tilt position.
'
The UI is compatible with AutoScript version 4.13 and above.
'
If you have any questions or comments, please contact me, Chris Thompson, on GitHub (ChrisLeeThompson).
'
Thank you,
Chris Thompson
'
Copyright 2026 Christopher Thompson
'
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
'
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
'
THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
    """Backend class callable from QML"""

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
    
    Slot()
    def start_thread(self):
        """Method creates a thread for background operations such as connecting to the microscope and moving the stage."""
        if self.worker_thread is not None and self.worker_thread.isRunning():
            logging.warning("Worker thread already running")
            return
        # Create worker and thread
        self.worker = ArctisAngleCalcWorker()
        self.worker_thread = QThread()
        self.worker.moveToThread(self.worker_thread)
        # Connect signals from worker to operator
        self.worker.worker_status_label_signal.connect(self.status_label_signal)
        self.worker.connected_to_microscope_signal.connect(self.connected_to_microscope_signal)
        self.worker.connect_switch_enable_signal.connect(self.connect_switch_enable_signal)
        self.worker.stage_move_signal.connect(self.stage_move_signal)
        self.worker.current_alpha_position_signal.connect(self.current_alpha_position_signal)
        # Connect signals from operator to worker
        self.request_connect_signal.connect(self.worker.connect_to_microscope)
        self.request_disconnect_signal.connect(self.worker.disconnect_from_microscope)
        self.request_tilt_signal.connect(self.worker.tilt_stage_to_alpha)
        self.request_get_alpha_signal.connect(self.worker.get_current_alpha_tilt)
        # Connect thread lifecycle
        self.worker_thread.started.connect(lambda: logging.info("Worker thread started"))
        self.worker_thread.finished.connect(lambda: logging.info("Worker thread finished"))
        # Start the thread
        self.worker_thread.start()
        logging.info("Worker thread initialized and started")
    
    @Slot()
    def connect_to_microscope(self):
        """Called from QML. Initiates creation of worker thread. Called when the user toggles the connect switch to on."""
        # Create thread on first connection attempt
        if self.worker_thread is None:
            logging.info("First connection attempt - creating worker thread")
            self.start_thread()
        # Verify thread is running
        if not self.worker_thread.isRunning():
            logging.error("Worker thread failed to start")
            self.connected_to_microscope_signal.emit(False)
            return
        # Request connection to microscope
        self.request_connect_signal.emit()
    
    @Slot()
    def disconnect_from_microscope(self):
        """Called from QML. Disconnects from AutoScript server."""
        self.request_disconnect_signal.emit()

    @Slot(float)
    def tilt_stage_to_alpha(self, alpha_tilt_degrees: float):
        """Called from QML. Initiates a stage tilt by set degrees."""
        if self.worker_thread is None or not self.worker_thread.isRunning():
            logging.error("Worker thread not running")
            return
        self.request_tilt_signal.emit(alpha_tilt_degrees)
    
    @Slot()
    def get_current_alpha_tilt(self):
        """Called from QML. Gets current alpha tilt angle of stage."""
        if self.worker_thread is None or not self.worker_thread.isRunning():
            logging.error("Worker thread not running")
        self.request_get_alpha_signal.emit()
    
    def cleanup_thread(self):
        """Method stops and cleans up worker thread."""
        if self.worker_thread is None:
            return
        logging.info("Cleaning up worker thread...")
        # Disconnect from microscope if connected
        if self.worker and self.worker.is_connected:
            try:
                self.request_disconnect_signal.emit()
                self.worker_thread.wait(3000)
            except Exception as e:
                logging.error(f"Error disconnecting from microscope: {e}", exc_info=True)
        # Request thread to quit and wait for it
        self.worker_thread.quit()
        # Wait up to 5 seconds for thread to finish
        if not self.worker_thread.wait(5000):
            logging.warning("Thread did not finish gracefully, terminating...")
            self.worker_thread.terminate()
            self.worker_thread.wait()
        # Cleanup references
        self.worker = None
        self.worker_thread = None
        logging.info("Worker thread cleanup complete.")

class ArctisAngleCalcWorker(QObject):
    """Worker class to handle background calls to the microscope."""

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
        """Method imports AutoScript and connects to the AutoScript server."""
        try:
            self.connect_switch_enable_signal.emit(False)           # disable switch while connecting
            self.worker_status_label_signal.emit("Connecting…")
            logging.info("Importing AutoScript...")
            from autoscript_sdb_microscope_client.sdb_microscope_client import SdbMicroscopeClient
            logging.info("AutoScript imported")
            # create microscope object
            self.microscope = SdbMicroscopeClient()
            # connect to AutoScript server
            logging.info("Connecting to AutoScript server...")
            self.microscope.connect()
            self.is_connected = True
            self.worker_status_label_signal.emit("")                 # clear status label
            self.connect_switch_enable_signal.emit(True)            # enable switch
            self.connected_to_microscope_signal.emit(True)          # signal to enable Get and Go To buttons
        except Exception as e:
            logging.error(f"Exception occurred: {e}", exc_info=True)
            self.worker_status_label_signal.emit("Connection failed.")
            self.connected_to_microscope_signal.emit(False)         # toggle switch off
            self.connect_switch_enable_signal.emit(True)
            self.is_connected = False
            # Clear error message after 10 seconds
            QTimer.singleShot(10000, lambda: self.worker_status_label_signal.emit(""))
            
    @Slot()
    def disconnect_from_microscope(self):
        """Method disconnects from microscope."""
        logging.info("Disconnecting from microscope...")
        self.microscope.disconnect()
        self.connect_switch_enable_signal.emit(True)
        self.connected_to_microscope_signal.emit(False)             # signal to disable Get and Go To buttons
        self.is_connected = False
    
    @Slot(float)
    def tilt_stage_to_alpha(self, alpha_tilt_degrees: float):
        """Method tilts the compustage."""
        from autoscript_sdb_microscope_client.structures import CompustagePosition
        from autoscript_sdb_microscope_client.enumerations import CoordinateSystem
        # set default coorindate system
        self.microscope.specimen.compustage.set_default_coordinate_system(coordinate_system=CoordinateSystem.SPECIMEN)
        # convert degrees to radians
        alpha_tilt_radians = math.radians(alpha_tilt_degrees)
        logging.info(f"alpha tilt (degrees): {alpha_tilt_degrees}")
        logging.info(f"alpha tilt (radians): {alpha_tilt_radians}")
        # disable Get and Go To buttons and microscope connect switch while stage is moving
        self.stage_move_signal.emit(True)
        # send status signal
        self.worker_status_label_signal.emit("Tilting stage…")
        # tilt stage
        position = CompustagePosition(a=alpha_tilt_radians)
        self.microscope.specimen.compustage.absolute_move(position)
        logging.info(f"Stage tilted to: {self.microscope.specimen.compustage.current_position.a}")
        # signal stage move complete
        self.stage_move_signal.emit(False)
        # clear status label
        self.worker_status_label_signal.emit("")
    
    @Slot()
    def get_current_alpha_tilt(self):
        """Method gets the current stage tilt and emits the value in degrees."""
        from autoscript_sdb_microscope_client.enumerations import CoordinateSystem
        # set default coordinate system
        self.microscope.specimen.compustage.set_default_coordinate_system(coordinate_system=CoordinateSystem.SPECIMEN)
        # get alpha tilt value
        alpha_tilt_radians = self.microscope.specimen.compustage.current_position.a
        logging.info(f"Current alpha tilt (radians): {alpha_tilt_radians}")
        # convert to degrees
        alpha_tilt_degrees = float(math.degrees(alpha_tilt_radians))
        logging.info(f"Current alpha tilt (degrees): {alpha_tilt_degrees}")
        self.current_alpha_position_signal.emit(alpha_tilt_degrees)


def setup_logging():
    """Configure logging for the application"""
    logging.basicConfig(format="%(asctime)s:\t%(levelname)s:\t%(funcName)s:\t%(message)s", level=logging.DEBUG)


def main():
    """Main function to run the application"""
    setup_logging()

    base_path = Path(__file__).parent
    qml_resources_path = base_path / "qml_resources"
    config_file_path = base_path / "qml_resources" / "qtquickcontrols2.conf"
    
    # set QT_QUICK_CONTROLS_CONF environment variable
    os.environ["QT_QUICK_CONTROLS_CONF"] = str(config_file_path)

    # Create application
    app = QGuiApplication(sys.argv)

    # set window icon
    window_icon_path = qml_resources_path / "icons" / "catbug_waiting_color.png"
    app.setWindowIcon(QIcon(str(window_icon_path)))

    # application engine
    engine = QQmlApplicationEngine()

    # instantiate backend class
    arctis_angle_calc_backend = ArctisAngleCalcOperator()

    # connection to QML
    engine.rootContext().setContextProperty("arctis_angle_calc_backend", arctis_angle_calc_backend)

    # Connect cleanup method to application exit
    app.aboutToQuit.connect(arctis_angle_calc_backend.cleanup_thread)

    # load qml file
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
    
