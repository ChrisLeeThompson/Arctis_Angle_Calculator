# Arctis Angle Calculator

<!-- Full documentation: https://<site>/scripts/arctis_angle_calculator/ (enable this link when the site is live) -->

A PySide6/QML desktop utility that calculates and visualizes milling angles and stage tilt angles for the Thermo Scientific Arctis cryo plasma FIB-SEM. It runs standalone for offline visualization, or connects to the microscope through the Thermo Scientific AutoScript SDK to read and set the stage alpha tilt.

## Features

- **Milling Angle and Alpha Tilt** spinboxes that convert between the two and tilt the graphics to match.
- **Connect To Microscope** switch with Get and Go To buttons to read the current stage tilt and drive the stage to the set angle.
- **Back Of Grid (BOG) Milling Angle** switch that changes the calculation for back-of-grid milling at alpha tilts below -128 degrees.
- **Stage Graphics** showing a cross-section of the grid and sample in an AutoGrid, with clickable SEM, FIB, GIS, and iFLM labels that tilt the diagram to each position.
- **Sample Graphics** showing a zoomed sample cartoon linked to the stage tilt.

## Requirements

- Python 3.11+
- PySide6 6.7.1+
- Thermo Scientific AutoScript 4.14+ (optional; only needed to connect to the microscope)

PySide6 6.7.1 is the version in the AutoScript 4.14 Python environment, where the script is developed and tested.

## Installation

1. Download the latest release ZIP from the [Releases page](https://github.com/ChrisLeeThompson/Arctis_Angle_Calculator/releases).
2. Extract it and copy the script folder to your desired location. To read or set the stage tilt, install on the Support PC (SPC) or Microscope PC (MPC); for offline visualization, any PC that meets the requirements will do.
3. If you run the script with the AutoScript Python environment, no packages need to be installed. Otherwise, install them with:

   ```
   pip install -r requirements.txt
   ```

## Running

Run the main module from the script folder:

```
python arctis_angle_calculator.py
```

The script also runs from the AutoScript Python interpreter or AutoScript Runner.

## Notes

- Without the AutoScript client installed, the script still runs for offline visualization; the Connect To Microscope switch reports a failed connection.
- The milling angle is `38 deg + alpha tilt`, because the FIB is 38 degrees from the stage plane at 0 degrees alpha tilt. With the BOG switch on and the alpha tilt below -128 degrees, the milling angle is instead `-180 deg - (38 deg + alpha tilt)`.
- The alpha tilt range is -190 to +10 degrees.

## License

MIT, see [LICENSE](LICENSE). Copyright (c) 2026 Christopher Thompson.

The Catbug artwork in `qml_resources/icons/` is not covered by the MIT license; see [LICENSE](LICENSE). PySide6 (Qt for Python) is licensed under the LGPLv3 and is used as an unmodified runtime dependency installed from PyPI; it is not distributed with this source.

## Contact

Developed by Chris Thompson with assistance from Anthropic's Claude. Questions and suggestions are welcome: [@ChrisLeeThompson](https://github.com/ChrisLeeThompson) on GitHub.
