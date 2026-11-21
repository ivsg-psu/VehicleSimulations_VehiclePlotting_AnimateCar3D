# Race course data (traced from a photo)

The `'raceCourse'` preset of `fcn_AnimateCar3D_fillRoad` reads three files in this folder. They are plain numbers: no toolbox is needed to use them.

| File | Contents |
|---|---|
| `raceCourse_trace.csv` | The track every 0.25 m from the start line: `s_m, x_m, y_m` (the centerline), `widthLeft_m, widthRight_m` (to each edge, left and right of the driving direction), `curbWidthLeft_m, curbWidthRight_m` (0 where there is no curb) |
| `raceCourse_planView.csv` | The reference line as OpenDRIVE-style geometry, every 2 m: `s_m, x_m, y_m, heading_rad, length_m, curvature_per_m` (a line where the curvature is 0, otherwise an arc) |
| `raceCourse_features.csv` | Walls and pit stripes as world polylines: `id, type, x_m, y_m` (type `wall` or `stripe`; rows of the same id and type are one polyline, in order) |

Layout: north up, as in the photo; the start line is at the origin, on the bottom straight, and the course is driven west there (east on the top straight). One loop is about 452 m.

## How it was traced

From an overhead photo of a race track (`RaceTrack.jpg`, 2576 x 1449 pixels), with the scripts in `raceCourse_tracing/` (Python 3 with numpy, scipy, scikit-image, and Pillow; run in order from a folder holding the photo):

1. `step1_masks.py`: color masks for the asphalt, the white lines, and the red curbs.
2. `step2_firstTrace.py`: the route through about 120 hand-placed waypoints in driving order, smoothed and re-centered between the edges.
3. `step3_centerAndEdges.py`: the straights made exactly straight; the start moved to the start line; widths measured outward to the real lines, with gaps in the dashed walls closed, chalk marks ignored, and the hand-placed walls and the field's border as limits.
4. `step4_curbs.py`: curbs found beside each edge and each fitted as a circular arc (two where one does not fit); the track edge follows the curb's inner arc; curbs 1.2 m wide, narrowed at tight tips so they never fold.
5. `step5_export.py`: the files above (the walls and pit stripes were placed by hand from the photo), and a check picture with stations every 25 m.
6. `step6_planView.py`: curvature from the trace's headings, corrected a little on each winding half so the straights are exactly straight and the loop closes (within 0.3 m of the trace).

Scale: the top straight's two lanes are 198 pixels across, taken as two 12 ft lanes (7.3152 m): 27.07 pixels per meter.

## Changes from the photo

- **The pit lane is one 12 ft lane (3.66 m) wide.** In the photo (and in practice) it is only about 2 m wide; it was made wider so that normal cars fit.
- The walls (red and white dashed lines in the photo, about 1.35 m high) and the pit stripes were placed by hand.
- Known small differences: one faint curb under the center island (near station 300) is not included; the track over the bottom-right peninsula tip (stations 425 to 428) is about 0.7 m narrower than the photo; some curb ends have small jumps.
