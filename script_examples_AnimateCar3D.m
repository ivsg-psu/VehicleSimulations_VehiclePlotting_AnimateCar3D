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
