# AnimateCar3D

Fast 3D animation of scenes with many vehicles in MATLAB: decision branches, surrounding traffic, pedestrians, and moving items, with no extra toolboxes or immersive simulators (CARLA, RoadRunner, Simscape, etc.).

AnimateCar3D builds on [CarMesh3D](https://github.com/ivsg-psu/VehicleSimulations_VehiclePlotting_CarMesh3D), which makes, views, and checks the mesh of one vehicle at a time. AnimateCar3D uses CarMesh3D's vehicle meshes and plotting functions, and adds everything needed for many objects in one scene.

> **Status:** setting up (2026_11_19). The workflow below is the plan; functions will be added in the order given under [Development plan](#development-plan).

## Getting started

1. Put this folder somewhere whose path has **no minus signs**.
2. Open MATLAB (written for R2025b) and run `script_demo_AnimateCar3D.m` from this folder.
3. The first run, while online, installs its dependencies (DebugTools and CarMesh3D) into the `Utilities` folder, which git ignores.

### Which copy of CarMesh3D is used

Exactly one copy of CarMesh3D is kept on the MATLAB path; the demo script removes any others. If two copies were on the path, MATLAB would silently use whichever came first, and a test could pass against the wrong version.

| Setting in `script_demo_AnimateCar3D.m` | CarMesh3D used |
|---|---|
| `flag_useWorkingCarMesh3D = 0` (default) | The newest release installed in `Utilities` (`Utilities/CarMesh3D_<date>`) |
| `flag_useWorkingCarMesh3D = 1` | A working copy, for developing both libraries together: `workingCarMesh3DFolder` if set, otherwise the folder in the environment variable `ANIMATECAR3D_CARMESH3D_PATH`, otherwise a `CarMesh3D` folder next to this one |

Setting `ANIMATECAR3D_CARMESH3D_PATH` (for example `setenv('ANIMATECAR3D_CARMESH3D_PATH','C:\...\CarMesh3D')`) turns the working copy on without editing the script. The script prints which copy it uses, and stores its folder in the environment variable `MATLABFLAG_ANIMATECAR3D_CARMESH3D_ROOT`.

## Folders

| Folder | Contents |
|---|---|
| (root) | `script_demo_AnimateCar3D.m`, this README |
| `Functions` | Functions `fcn_AnimateCar3D_<name>.m`, each tested by `script_test_fcn_AnimateCar3D_<name>.m`; scripts that demonstrate the code more generally are named `script_AnimateCar3D_<name>.m` |
| `Data` | Scene lists, motion files, and static scenes for the demos |
| `Images` | Images and animations for this README |
| `Installer` | The DebugTools installer used by the demo script |
| `Utilities` | Installed dependencies (not in git) |

## The planned workflow

Every object in a scene (the ego vehicle, traffic, pedestrians, gates, buildings) goes through the same stages. All positions are in one global frame.

**At start**

1. **Inputs.**
   - Motion for each object: in memory, one CSV file per object (the CarMesh3D 30-column motion format), or files in a watched folder. Dense traffic may also use a narrow file with one row per vehicle per time step (`id, time, X, Y, yaw`, plus optional size).
   - A **scene list** with one row per object: `instance`, `role`, `meshID`, `motionFile`, `branchOf`, `branchID`, `splitTime`, `respondsTo`, `color`, `alpha`, `timeOffset`.
   - A **static scene**: fixed objects with a mesh, pose, and color.
2. **Object catalog.** Records what exists, when, and where, using a grid of cells per time window so that lookups stay fast with thousands of objects. Full motion is loaded only for objects drawn in detail. The catalog is saved as a cache and reused while the files are unchanged.

**Each time step**

3. **Display criteria.** A region (a radius around an object, a box, or the camera's view), enter and exit distances, roles to show and to always show, and distance and count limits for each detail tier. They can be changed while the animation runs.
4. **Selector.** Picks the objects to show at this time, gives each a detail tier, and builds the **display list**: the only input of the scene player.
5. **Scene player.** Draws, moves, and hides objects. It never decides what to show, and it treats static and moving objects alike.
   - Near tier: full CarMesh3D meshes, with wheels and lights.
   - Middle tier: low-face meshes.
   - Far tier: boxes, all drawn as one patch.

   Leaving objects are hidden and reused rather than deleted.
6. **Frame out.** To the screen, a GIF, or a video.
7. **Live update.** About once a second, new, grown, and deleted files in a watched folder update the catalog.

**At finish:** close output files and delete the reused graphics objects.

**Roles:** `ego`, `traffic`, `confederate` (traffic scripted to challenge the ego, which may branch), `pedestrian`, `movingItem` (gates, trains, garage doors), and `static`. A branch keeps its parent's role, names its parent in `branchOf`, and can split from it partway through the motion (`splitTime`); branches can split again. `respondsTo` links an ego branch to the confederate branch it answers.

## Development plan

0. **Repository setup:** template leftovers removed; one copy of CarMesh3D on the path; a test that checks every CarMesh3D function, option, mesh field, motion column, and folder rule that AnimateCar3D relies on.
1. **Display list and scene player**, fed from memory: pooling and the three detail tiers. Demo: ten ego branches splitting partway. Frame-rate test from 100 nearby vehicles up toward 1000.
2. **Scene list, object catalog, selector, and static scene.** Demos: a confederate with branches and the ego's responses; synthetic traffic passing through.
3. **Live use:** display criteria changed while running; the watched-folder source; a test helper that adds and removes files in a watched folder.
4. **Pedestrians and moving items**, as simple shapes first.

Later: a 2D (top-down) mode using the same detail tiers.

## License

AnimateCar3D is released under the [MIT License](LICENSE), Copyright (c) 2026 Intelligent Vehicles and Systems Group (Prof. Sean Brennan). Vehicle models used through CarMesh3D keep their own licenses; see the CarMesh3D README.
