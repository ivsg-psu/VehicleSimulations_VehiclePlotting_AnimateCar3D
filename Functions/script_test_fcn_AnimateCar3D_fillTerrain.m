% script_test_fcn_AnimateCar3D_fillTerrain.m
% Tests fcn_AnimateCar3D_fillTerrain
% Fills the ground around a road so that it rises and falls with the road.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillTerrain
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillTerrain
%   % * (fill in items here)


%% Set up the workspace
close all

mountainRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='mountain', FigNum=-1);

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: The ground around a mountain profile on the curvy road
figNum = 10001;
titleString = sprintf('DEMO case: The ground around a mountain profile on the curvy road');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

terrain = fcn_AnimateCar3D_fillTerrain(mountainRoad, FigNum=figNum);

% Check variable types
assert(isstruct(terrain) && isstruct(terrain.Trees));

% Check variable sizes
assert(isequal(size(terrain.Z), [numel(terrain.Y) numel(terrain.X)]) && isequal(size(terrain.Shade), size(terrain.Z) - 1));
assert(isequal(size(terrain.Distance), size(terrain.Z)) && strcmp(terrain.Shape, 'fitted') && isempty(terrain.Peak));

% Check variable values: under the road, the ground is just below the
% road surface; far away it is between the road's lowest and highest
sAlong = (0:20:mountainRoad.Length)';
[centerPoints, ~, centerZ] = fcn_AnimateCar3D_getRoadPoints(mountainRoad, sAlong);
groundZ = interp2(terrain.X, terrain.Y, terrain.Z, centerPoints(:,1), centerPoints(:,2));
assert(all(groundZ < centerZ) && all(groundZ > centerZ - 1.5));
assert(min(terrain.Z(:)) >= min(centerZ) - 1 && max(terrain.Z(:)) <= max(centerZ) + 1e-6);
% Trees: none near the road
treeXY = reshape([terrain.Trees.XYZ], 3, [])';
[~, ~, treeT] = fcn_AnimateCar3D_getRoadHeight(mountainRoad, treeXY(:,1:2));
assert(numel(terrain.Trees) > 20 && all(abs(treeT) > 7.2 + 8 - 1e-6));
% Shading: smooth and gentle
assert(all(abs(terrain.Shade(:) - 1) <= 0.03 + 1e-9) && max(max(abs(diff(terrain.Shade)))) < 0.01);
% Distance: small under the road, large at the grid's corners
assert(all(interp2(terrain.X, terrain.Y, terrain.Distance, centerPoints(:,1), centerPoints(:,2)) < 10) && terrain.Distance(1,1) > 100);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: The mountain road: the ground is a mountain, cut and filled for the road
figNum = 20002;
titleString = sprintf('TEST case: The mountain road: the ground is a mountain, cut and filled for the road');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

mountainPreset = fcn_AnimateCar3D_fillRoad(Preset='mountain', FigNum=-1);
terrain = fcn_AnimateCar3D_fillTerrain(mountainPreset, GridSpacing=10, FigNum=figNum);
sAlong = (0:20:mountainPreset.Length)';
[centerPoints, ~, centerZ] = fcn_AnimateCar3D_getRoadPoints(mountainPreset, sAlong);
groundZ = interp2(terrain.X, terrain.Y, terrain.Z, centerPoints(:,1), centerPoints(:,2));
assert(strcmp(terrain.Shape, 'mountain') && numel(terrain.Peak)==3);
assert(all(groundZ < centerZ) && all(groundZ > centerZ - 1.5));   % (the road sits on its cut)
assert(terrain.Peak(3) > max(centerZ) + 0.8*250);                   % (the peak rises well above the road)
lower = fcn_AnimateCar3D_fillTerrain(mountainPreset, GridSpacing=10, PeakHeight=60, TreesPerHectare=0);
assert(lower.Peak(3) > max(centerZ) + 0.8*60 && lower.Peak(3) < terrain.Peak(3) - 100);
assert(min(hypot(centerPoints(:,1) - terrain.Peak(1), centerPoints(:,2) - terrain.Peak(2))) > 50);
% Asked for fitted ground instead: it stays below the road's top
fitted = fcn_AnimateCar3D_fillTerrain(mountainPreset, GridSpacing=10, Shape='fitted', TreesPerHectare=0);
assert(max(fitted.Z(:)) <= max(centerZ) + 1e-6 && isempty(fitted.Peak));

%% TEST case: A flat road: flat ground; no trees when asked
figNum = 20001;
titleString = sprintf('TEST case: A flat road: flat ground; no trees when asked');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

flatRoad = fcn_AnimateCar3D_fillRoad(Preset='twoLane', FigNum=-1);
terrain = fcn_AnimateCar3D_fillTerrain(flatRoad, TreesPerHectare=0, Margin=50, GridSpacing=10);
assert(all(abs(terrain.Z(:) + 0.25) < 1e-9) && isempty(terrain.Trees));
assert(terrain.X(1) <= -50 && terrain.X(end) >= 350);
again = fcn_AnimateCar3D_fillTerrain(flatRoad, Margin=50, GridSpacing=10);
other = fcn_AnimateCar3D_fillTerrain(flatRoad, Margin=50, GridSpacing=10, Seed=2);
assert(isequal(again, fcn_AnimateCar3D_fillTerrain(flatRoad, Margin=50, GridSpacing=10)) && ~isequal(again.Trees, other.Trees));

%% Fast Mode Tests

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
terrain = fcn_AnimateCar3D_fillTerrain(mountainRoad, GridSpacing=20, FigNum=-1);
assert(~isempty(terrain.Z));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: A grid spacing of zero
if 1==0
    fcn_AnimateCar3D_fillTerrain(mountainRoad, GridSpacing=0);
end

%% FAIL case: An unknown shape
if 1==0
    fcn_AnimateCar3D_fillTerrain(mountainRoad, Shape='volcano');
end
