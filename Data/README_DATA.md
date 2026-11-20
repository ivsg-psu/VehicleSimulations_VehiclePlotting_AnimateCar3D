# Data

Inputs for the AnimateCar3D demos and tests:

- `staticScene_cubeGrid.csv`: the static scene used in the demos (210 colored 2 m cubes on a 20 m grid, off the road, and five buildings); read with `fcn_AnimateCar3D_loadStaticScene`
- `traffic_fourLaneRoad.csv`: 300 vehicles on a four-lane road, 15 s at 2 Hz, in the long traffic format (`id, time, X, Y, yaw, length, width, height`); read with `fcn_AnimateCar3D_loadTrafficFile`. Written by `script_demo_AnimateCar3D.m` if missing.
- `frameRate_results.csv`: the timing results written by `script_AnimateCar3D_frameRateTest.m` (see "Frame rate" in the main README)

The formats are described under "Input files" in the main README; the files of a watched folder for live use (`<instance>.csv`, traffic files, `sceneList.csv`, `displayCriteria.txt`) under "Live use". The live demo writes its watched folder in the system's temporary folder, not here. Vehicle meshes are not kept here: they come from the CarMesh3D library's `Data` folder (see the main README for which copy of CarMesh3D is used).
