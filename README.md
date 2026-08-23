# Arctis Angle Calculator

A PySide6/QML desktop UI that calculates and visualizes milling angles and
stage tilt angles for a Thermo Scientific Arctis microscope. Draw chalk lines
at different milling angles to explore milling procedures and GIS deposition
positions. The UI runs standalone, or connects to a microscope via AutoScript
(>= 4.13) to get and set the stage's alpha tilt.

## Running

```
pip install -r requirements.txt
python arctis_angle_calculator.py
```

The proprietary AutoScript client is optional: without it the app still runs
for offline visualization, and the Connect To Microscope switch reports a
failed connection. See `requirements.txt` for details.

## Notes

- The milling angle relationship is `milling angle = 38° + alpha tilt`; the
  BOG Milling Angle switch changes the calculation for alpha tilts below
  −128° (back-of-grid milling).
- Questions or comments: contact Chris Thompson on GitHub (ChrisLeeThompson).
- The Catbug artwork in `qml_resources/icons/` is not covered by the MIT
  license. See `LICENSE`.
