% script_test_fcn_AnimateCar3D_getRoadPoints.m
% Tests fcn_AnimateCar3D_getRoadPoints
% Finds world points on a road from road coordinates (s along, t across).
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_getRoadPoints
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_getRoadPoints
%   % * (fill in items here)


%% Set up the workspace
close all

straightRoad = fcn_AnimateCar3D_fillRoad(Preset='twoLane', FigNum=-1);
curvyRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy', FigNum=-1);

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

%% DEMO case: The right lane's center along a curvy road
figNum = 10001;
titleString = sprintf('DEMO case: The right lane''s center along a curvy road');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

sValues = (0:2:curvyRoad.Length)';
[points, tValues] = fcn_AnimateCar3D_getRoadPoints(curvyRoad, sValues, LaneID=-1, FigNum=figNum);

% Check variable types
assert(isnumeric(points) && isnumeric(tValues));

% Check variable sizes
assert(isequal(size(points), [numel(sValues) 3]) && isequal(size(tValues), [numel(sValues) 1]));

% Check variable values: half a lane to the right, all along
assert(all(abs(tValues + curvyRoad.LaneSections(1).Right(1).Width(1)/2) < 1e-12));

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

%% TEST case: A straight road: s along x, t along y
figNum = 20001;
titleString = sprintf('TEST case: A straight road: s along x, t along y');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

points = fcn_AnimateCar3D_getRoadPoints(straightRoad, [0; 50; 100], T=[0; 2; -3]);
assert(max(abs(points - [0 0 0; 50 2 0; 100 -3 0]), [], 'all') < 1e-12);
% Lane edges: the right lane is 3.6 m wide
inner = fcn_AnimateCar3D_getRoadPoints(straightRoad, 10, LaneID=-1, LaneEdge='inner');
outer = fcn_AnimateCar3D_getRoadPoints(straightRoad, 10, LaneID=-1, LaneEdge='outer');
assert(abs(inner(2)) < 1e-12 && abs(outer(2) + 3.6) < 1e-12);
% (A point past the end is moved to the end)
points = fcn_AnimateCar3D_getRoadPoints(straightRoad, straightRoad.Length + 50);
assert(abs(points(1) - straightRoad.Length) < 1e-9);

%% TEST case: Driving lanes: counted among driving lanes only
figNum = 20004;
titleString = sprintf('TEST case: Driving lanes: counted among driving lanes only');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

interstate = fcn_AnimateCar3D_fillRoad(Preset='interstate', FigNum=-1);
[~, tFirst] = fcn_AnimateCar3D_getRoadPoints(interstate, 10, DrivingLane=-1);
[~, tLane3] = fcn_AnimateCar3D_getRoadPoints(interstate, 10, LaneID=-3);
assert(abs(tFirst - tLane3) < 1e-12 && abs(tFirst + (0.6 + 1.2 + 1.8)) < 1e-12);   % (past the median and shoulder)
[~, tFourth] = fcn_AnimateCar3D_getRoadPoints(interstate, 10, DrivingLane=4);
assert(abs(tFourth - (0.6 + 1.2 + 3*3.6 + 1.8)) < 1e-12);
[~, tTwoLane] = fcn_AnimateCar3D_getRoadPoints(straightRoad, 10, DrivingLane=-1);
assert(abs(tTwoLane + 1.8) < 1e-12);                                 % (the same as LaneID -1 here)

%% TEST case: Heights: elevation along s, superelevation across
figNum = 20005;
titleString = sprintf('TEST case: Heights: elevation along s, superelevation across');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

slopedRoad = straightRoad;
slopedRoad.ElevationProfile = struct('S',{0, 100}, 'A',{0, 5}, 'B',{0.05, 0}, 'C',{0, 0}, 'D',{0, 0});
slopedRoad.LateralProfile = struct('Superelevation', struct('S',0, 'A',0.04, 'B',0, 'C',0, 'D',0));
[~, tValues, zValues, surfaceAngles] = fcn_AnimateCar3D_getRoadPoints(slopedRoad, [50; 150], T=[0; -2]);
assert(abs(zValues(1) - 2.5) < 1e-12 && abs(zValues(2) - (5 - 2*tan(0.04))) < 1e-12);
assert(abs(surfaceAngles(1,1) - atan(0.05)) < 1e-12 && abs(surfaceAngles(2,1)) < 1e-12 && all(abs(surfaceAngles(:,2) - 0.04) < 1e-12));
[~, ~, flatZ] = fcn_AnimateCar3D_getRoadPoints(straightRoad, [10; 20], T=3);
assert(all(flatZ==0) && isequal(tValues, [0; -2]));

%% TEST case: An arc: a quarter circle of radius 20 m
figNum = 20002;
titleString = sprintf('TEST case: An arc: a quarter circle of radius 20 m');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

arcRoad = struct('PlanView', struct('S',0, 'X',0, 'Y',0, 'Hdg',0, 'Length',10*pi, 'Type','arc', 'Curvature',1/20, ...
    'CurvStart',[], 'CurvEnd',[]));
points = fcn_AnimateCar3D_getRoadPoints(arcRoad, 10*pi);
assert(max(abs(points - [20 20 pi/2])) < 1e-9);

%% TEST case: The curvy road's geometry elements join without gaps or kinks
figNum = 20003;
titleString = sprintf('TEST case: The curvy road''s geometry elements join without gaps or kinks');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

planView = curvyRoad.PlanView;
assert(any(strcmp({planView.Type}, 'spiral')) && any(strcmp({planView.Type}, 'arc')));
for ith_geometry = 2:numel(planView)
    before = fcn_AnimateCar3D_getRoadPoints(curvyRoad, planView(ith_geometry).S - 1e-6);
    startPoint = [planView(ith_geometry).X planView(ith_geometry).Y planView(ith_geometry).Hdg];
    assert(max(abs(before - startPoint)) < 1e-4);
end

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
points = fcn_AnimateCar3D_getRoadPoints(curvyRoad, (0:10:100)', LaneID=1, FigNum=[]);
assert(size(points,1)==11);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
points = fcn_AnimateCar3D_getRoadPoints(curvyRoad, (0:10:100)', LaneID=1, FigNum=-1);
assert(size(points,1)==11);

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 50;
tic;
for ith_test = 1:Niterations
    fcn_AnimateCar3D_getRoadPoints(curvyRoad, (0:1:300)', LaneID=-1, FigNum=[]);
end
slowTime = toc;
tic;
for ith_test = 1:Niterations
    fcn_AnimateCar3D_getRoadPoints(curvyRoad, (0:1:300)', LaneID=-1, FigNum=-1);
end
fastTime = toc;
fprintf(1,'Calls: %.3f ms (checked), %.3f ms (fast)\n', 1000*slowTime/Niterations, 1000*fastTime/Niterations);

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

%% FAIL case: A driving lane the road does not have
if 1==0
    fcn_AnimateCar3D_getRoadPoints(straightRoad, 10, DrivingLane=-2);
end

%% FAIL case: A lane the road does not have
if 1==0
    fcn_AnimateCar3D_getRoadPoints(straightRoad, 10, LaneID=-5);
end
