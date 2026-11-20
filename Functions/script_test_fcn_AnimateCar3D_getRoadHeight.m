% script_test_fcn_AnimateCar3D_getRoadHeight.m
% Tests fcn_AnimateCar3D_getRoadHeight
% Finds the road surface's height under XY points.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_getRoadHeight
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_getRoadHeight
%   % * (fill in items here)


%% Set up the workspace
close all

hillyRoad = fcn_AnimateCar3D_fillRoad(Preset='curvy', Elevation='hilly', CrossSlope='banked', FigNum=-1);

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

%% DEMO case: Heights along a lane of a hilly, banked road
figNum = 10001;
titleString = sprintf('DEMO case: Heights along a lane of a hilly, banked road');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

sKnown = (5:5:400)';
[lanePoints, tKnown, zKnown] = fcn_AnimateCar3D_getRoadPoints(hillyRoad, sKnown, LaneID=-1);
[zValues, sValues, tValues, roadIndex] = fcn_AnimateCar3D_getRoadHeight(hillyRoad, lanePoints(:,1:2), FigNum=figNum);

% Check variable types
assert(isnumeric(zValues) && isnumeric(sValues) && isnumeric(tValues) && isnumeric(roadIndex));

% Check variable sizes
assert(isequal(size(zValues), [numel(sKnown) 1]));

% Check variable values: the same s, t, and height as where the points came from
assert(max(abs(sValues - sKnown)) < 0.01 && max(abs(tValues - tKnown)) < 0.01 && max(abs(zValues - zKnown)) < 0.001);
assert(all(roadIndex==1));

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

%% TEST case: A road network: the nearest road; a flat road: zero
figNum = 20001;
titleString = sprintf('TEST case: A road network: the nearest road; a flat road: zero');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

network = fcn_AnimateCar3D_fillRoad(Preset='intersection', FigNum=-1);
[zValues, ~, ~, roadIndex] = fcn_AnimateCar3D_getRoadHeight(network, [40 -1.8; 0 40; -40 1.8; 0 -40]);
assert(isequal(roadIndex', [1 2 3 4]) && all(zValues==0));

%% Fast Mode Tests

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
zValues = fcn_AnimateCar3D_getRoadHeight(hillyRoad, [0 -1.8], FigNum=-1);
assert(abs(zValues - 1.8*tan(0)) < 1e-9);

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

%% FAIL case: Points that are not N x 2
if 1==0
    fcn_AnimateCar3D_getRoadHeight(hillyRoad, [1 2 3]);
end
