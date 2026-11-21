% script_examples_AnimateCar3D.m
% The simplest AnimateCar3D examples first: each is one call to fill a
% scenario (a scene, its centerline options, and the objects' motions)
% and one call to play it. Start here; script_demo_AnimateCar3D.m shows
% the parts underneath (the catalog, the selector, the player, live
% data, detail levels, and path lines).
%
% Run script_demo_AnimateCar3D.m once first (its first steps install
% CarMesh3D and put it on the path).
%
% To list the examples:
%       fcn_AnimateCar3D_fillExampleScenario()
%
% Each example's scene, paths, and motions can be looked at, changed,
% and played again:
%       scenario = fcn_AnimateCar3D_fillExampleScenario('laneChange');
%       scenario.CenterlineOptions{2}.XY       % the left lane's center, in XY
%       scenario.Motions{1}.Pose               % the ego's [x y yaw] over time
%                                              % (on hills: [x y z roll pitch yaw])
%
% This script was written on 2026_11_20 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_examples_AnimateCar3D
%   % * Wrote the code originally (drafted with Claude): examples 1 to 3,
%   %   one vehicle, one maneuver each
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_examples_AnimateCar3D
%   % * Added examples 4 and 5, on hills: the curvy road with hills and
%   %   banking, and the mountain road
%   % * Added example 6: example 3 at night (every example has a night
%   %   version: TimeOfDay='night')
%   % * Added example 7: one lap of the race course
%   % * Added example 8: the race course with hills and banked curves

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_examples_AnimateCar3D
%   % * Examples with several objects: passing, following, stopping for
%   %   a pedestrian at a crosswalk

% Save each example's animation as a GIF in the Images folder? (1 = yes)
flag_saveGifs = 1;
fcn_AnimateCar3D_fillExampleScenario();


%% Example 1. One vehicle: a lane change at constant speed (two-lane road)
% The ego starts in the right lane and changes to the left lane at 15
% m/s, signaling first. The colored lines on the road are the scene's
% centerline options from the ego's start: staying in lane, and the
% oncoming lane.
scenario = fcn_AnimateCar3D_fillExampleScenario('laneChange');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example1_laneChange.gif');
end
fcn_AnimateCar3D_playScenario(scenario, GifFile=gifFile, FigNum=1);


%% Example 2. One vehicle: following a curvy road at constant speed
% The ego follows the right lane's center at 12 m/s; the front tires
% steer with the curves.
scenario = fcn_AnimateCar3D_fillExampleScenario('curvyConstantSpeed');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example2_curvyConstantSpeed.gif');
end
fcn_AnimateCar3D_playScenario(scenario, GifFile=gifFile, FigNum=2);


%% Example 3. One vehicle: following a curvy road with changing speed
% The same path, but the ego slows for each curve (no more than 2 m/s^2
% sideways), braking with its brake lights on, and speeds up again on the
% straights.
scenario = fcn_AnimateCar3D_fillExampleScenario('curvyVaryingSpeed');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example3_curvyVaryingSpeed.gif');
end
fcn_AnimateCar3D_playScenario(scenario, GifFile=gifFile, FigNum=3);


%% Example 4. One vehicle on hills: the curvy road with hills and banked curves
% The same curvy road, now rising and falling (grades up to 6%) and
% banked down to the inside of each curve. The ego follows its lane at
% 12 m/s; its pose comes from the road's surface (height, pitch, roll),
% and its body leans on its wheels in the curves. The ground is drawn
% around the road (fcn_AnimateCar3D_fillTerrain), and the camera rises
% and falls with the ego.
scenario = fcn_AnimateCar3D_fillExampleScenario('curvyHills');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example4_curvyHills.gif');
end
fcn_AnimateCar3D_playScenario(scenario, GifFile=gifFile, FigNum=4);


%% Example 5. One vehicle on a mountain road
% About 2 km of winding road with hairpins, climbing all the way to a
% summit and descending all the way down (grades up to 12%, easing on
% the tight curves), banked, through a mountain. The ego slows for each
% curve (about 6 m/s in the tightest). Its body's pitch and roll on its
% wheels are exaggerated 6 times so they show, and the camera tilts with
% the road's grade where the camera is (CameraPitch 'road'). The GIF
% takes a frame every 0.5 s (the drive is about 2.5 minutes).
scenario = fcn_AnimateCar3D_fillExampleScenario('mountainRoad');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example5_mountainRoad.gif');
end
fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.5, GifDelay=0.1, GifFile=gifFile, FigNum=5);


%% Example 6. At night: example 3 after dark
% Every example has a night version: fcn_AnimateCar3D_fillExampleScenario
% with TimeOfDay='night'. The sky is dark, the road and ground are in
% night colors (the lane marks stay faintly visible), lit windows show on
% the buildings of the urban and neighborhood scenes, and the vehicle's
% headlights and taillights glow and cast pools of light: watch the brake
% lights as it slows for each curve. (fcn_AnimateCar3D_playScenario also
% takes TimeOfDay='night' directly, for any scenario.)
scenario = fcn_AnimateCar3D_fillExampleScenario('curvyVaryingSpeed', TimeOfDay='night');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example6_curvyVaryingSpeedNight.gif');
end
fcn_AnimateCar3D_playScenario(scenario, GifFile=gifFile, FigNum=6);


%% Example 7. One lap of the race course
% A race course traced from an overhead photo of a real track (see
% Data/README_raceCourse.md), scaled so its straights are two 12 ft lanes:
% about 452 m of winding track with banked red and white curbs, 1.35 m
% walls, a pit lane beside the bottom straight, and a start line. The ego
% drives one lap along the track's center, up to 22 m/s on the straights
% and braking for the corners (no more than 6 m/s^2 sideways).
scenario = fcn_AnimateCar3D_fillExampleScenario('raceCourse');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example7_raceCourse.gif');
end
fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.5, GifDelay=0.1, GifFile=gifFile, FigNum=7);


%% Example 8. The race course with hills and banked curves
% The race course's variants: Elevation='hilly' (about 4 m from lowest to
% highest, grades up to 6%, the straights level) and CrossSlope='banked'
% (down to the inside of each curve; the bottom-rightmost curve the other
% way), here together. The ego rides the surface (height, pitch, roll),
% and the ground is drawn around the track.
scenario = fcn_AnimateCar3D_fillExampleScenario('raceCourseHills');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example8_raceCourseHills.gif');
end
fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.5, GifDelay=0.1, GifFile=gifFile, FigNum=8);

%% Example 9. Following a lead car
% Several objects in one scenario: a lead car (red) speeds up and brakes
% on the two-lane road, and the ego follows it 1.5 s behind (a 30 m gap at
% 14 m/s), its brake lights on as it slows. Every object in
% scenario.Motions is drawn; the camera follows the ego.
scenario = fcn_AnimateCar3D_fillExampleScenario('following');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example9_following.gif');
end
fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.25, GifDelay=0.1, GifFile=gifFile, FigNum=9);

%% Example 10. Passing a slow car
% The ego (15 m/s) signals left, moves into the oncoming lane, passes a
% slow car (gray, 8 m/s), signals right, and moves back. Its path is made
% with fcn_AnimateCar3D_getRoadPoints and a smooth offset T(s) across the
% road.
scenario = fcn_AnimateCar3D_fillExampleScenario('passing');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example10_passing.gif');
end
fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.25, GifDelay=0.1, GifFile=gifFile, FigNum=10);

%% Example 11. Stopping for a pedestrian at a crosswalk
% On the urban street, the ego brakes to a stop 2 m before the crosswalk
% (fcn_AnimateCar3D_fillPathMotion's Stops option: rows of [s seconds])
% while a pedestrian crosses, waits until the pedestrian is past the
% center line, and drives on.
scenario = fcn_AnimateCar3D_fillExampleScenario('pedestrianCrossing');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example11_pedestrianCrossing.gif');
end
fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.25, GifDelay=0.1, GifFile=gifFile, FigNum=11);

%% Example 12. Through an urban grid
% The urban grid: a main street with three cross streets, a junction at
% each (Preset='urbanGrid'). fcn_AnimateCar3D_fillCenterlineOptions lists
% every path through the junctions (7 from the start); this one goes
% straight through the first, changes to the left-turn lane mid-block,
% and turns left at the second. A second car drives the main street the
% other way (its own start: Start=struct('Road', ..., 'LaneID',2, ...)).
scenario = fcn_AnimateCar3D_fillExampleScenario('urbanGrid');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example12_urbanGrid.gif');
end
fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.25, GifDelay=0.1, GifFile=gifFile, FigNum=12);

%% Example 13. A swinging kite camera
% The camera's bearing around the followed vehicle (CameraSwing, degrees
% from its heading: 180 behind, -90 to its right, 0 ahead): here swinging
% steadily from ahead and to the right (-10) around to behind and to the
% right (-170), on the curvy road with hills, tilting with the road's
% grade where the camera is (CameraPitch='road'). CameraSwing can also be
% one value, a function of time @(t) ..., or 'random' (smooth, within
% SwingRange, from SwingSeed).
scenario = fcn_AnimateCar3D_fillExampleScenario('curvyHills');
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd, 'Images', 'example13_swingingCamera.gif');
end
fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.25, GifDelay=0.1, CameraSwing=[-10 -170], CameraPitch='road', GifFile=gifFile, FigNum=13);
