% script_test_fcn_AnimateCar3D_fillCenterlineOptions.m
% Tests fcn_AnimateCar3D_fillCenterlineOptions
% Lists the paths a vehicle can take from a starting point in a scene, as lane centerlines in XY.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillCenterlineOptions
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillCenterlineOptions
%   % * (fill in items here)


%% Set up the workspace
close all

headingError = @(a, b) abs(atan2(sin(a - b), cos(a - b)));

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

%% DEMO case: The intersection: left, straight, and right from the west arm
figNum = 10001;
titleString = sprintf('DEMO case: The intersection: left, straight, and right from the west arm');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

network = fcn_AnimateCar3D_fillRoad(Preset='intersection', FigNum=-1);
centerlineOptions = fcn_AnimateCar3D_fillCenterlineOptions(network, FigNum=figNum);

% Check variable types
assert(iscell(centerlineOptions) && all(cellfun(@isstruct, centerlineOptions)));

% Check variable sizes: lane 2 (through and right): straight and right;
% lane 1: left
assert(numel(centerlineOptions)==3);
assert(isequal(cellfun(@(o) o.Name, centerlineOptions, 'UniformOutput', false), {'straight','right turn','lane 1, left turn'}));

% Check variable values: each path starts at the west arm's far end,
% heading east, has no gaps, and ends at the far end of its arm, heading
% away
for ith_option = 1:3
    thisOption = centerlineOptions{ith_option};
    assert(norm(thisOption.XY(1,:) - [-(7.2 + 80), -5.4 + 3.6*(ith_option==3)]) < 1e-9);
    assert(headingError(thisOption.Heading(1), 0) < 1e-9);
    assert(max(hypot(diff(thisOption.XY(:,1)), diff(thisOption.XY(:,2)))) <= 1 + 1e-6);
    assert(max(headingError(thisOption.Heading(2:end), thisOption.Heading(1:end-1))) < 0.6);   % (no flips)
    assert(abs(thisOption.S(end) - sum(hypot(diff(thisOption.XY(:,1)), diff(thisOption.XY(:,2))))) < 1e-9);
end
assert(norm(centerlineOptions{1}.XY(end,:) - [7.2 + 80, -5.4]) < 1e-6);         % straight: the east arm, lane -2
assert(norm(centerlineOptions{2}.XY(end,:) - [-5.4, -(7.2 + 80)]) < 1e-6);      % right: the south arm, lane -2
assert(norm(centerlineOptions{3}.XY(end,:) - [1.8, 7.2 + 80]) < 1e-6);          % left: the north arm, lane -1
assert(numel(centerlineOptions{1}.Route)==3 && strcmp(centerlineOptions{1}.Route(3).Road,'1'));

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

%% TEST case: Roads: stay, change lanes, pass in the oncoming lane where allowed
figNum = 20001;
titleString = sprintf('TEST case: Roads: stay, change lanes, pass in the oncoming lane where allowed');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[~, twoLaneOptions] = fcn_AnimateCar3D_fillRoad(Preset='twoLane');
assert(numel(twoLaneOptions)==2 && strcmp(twoLaneOptions{1}.Name,'stay in lane') && strcmp(twoLaneOptions{2}.Name,'oncoming lane 1'));
assert(all(abs(twoLaneOptions{1}.XY(:,2) + 1.8) < 1e-9) && all(abs(twoLaneOptions{2}.XY(:,2) - 1.8) < 1e-9));
assert(all(abs(twoLaneOptions{2}.Heading) < 1e-9));                      % (passing: still heading along s)
[~, interstateOptions] = fcn_AnimateCar3D_fillRoad(Preset='interstate');
assert(numel(interstateOptions)==4 && isequal(cellfun(@(o) o.Route.LaneID, interstateOptions), [-3 -4 -5 -6]));
[~, urbanOptions] = fcn_AnimateCar3D_fillRoad(Preset='urbanStreet');
assert(numel(urbanOptions)==1);                                          % (a double yellow line)
[~, neighborhoodOptions] = fcn_AnimateCar3D_fillRoad(Preset='neighborhood');
assert(numel(neighborhoodOptions)==2);                                   % (no center line)

%% TEST case: A curvy road: the path stays on the lane center
figNum = 20002;
titleString = sprintf('TEST case: A curvy road: the path stays on the lane center');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[curvyRoad, curvyOptions] = fcn_AnimateCar3D_fillRoad(Preset='curvy');
path = curvyOptions{1};
referencePoints = fcn_AnimateCar3D_getRoadPoints(curvyRoad, (0:0.1:curvyRoad.Length)');
distances = min(hypot(path.XY(:,1) - referencePoints(:,1)', path.XY(:,2) - referencePoints(:,2)'), [], 2);
assert(all(abs(distances - 1.8) < 0.01));
assert(abs(path.S(end) - curvyRoad.Length) < 15);                        % (the lane's length differs a little on curves)

%% TEST case: Another start; the version with a right-turn lane
figNum = 20003;
titleString = sprintf('TEST case: Another start; the version with a right-turn lane');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

twoLaneRoad = fcn_AnimateCar3D_fillRoad(Preset='twoLane');
fromMiddle = fcn_AnimateCar3D_fillCenterlineOptions(twoLaneRoad, Start=struct('Road','1', 'LaneID',1, 'S',200, 'Direction',-1), Spacing=5);
assert(norm(fromMiddle{1}.XY(1,:) - [200 1.8]) < 1e-9 && norm(fromMiddle{1}.XY(end,:) - [0 1.8]) < 1e-9);
assert(headingError(fromMiddle{1}.Heading(1), pi) < 1e-9 && numel(fromMiddle{1}.S)==41);
networkB = fcn_AnimateCar3D_fillRoad(Preset='intersection', RightTurnLane=true);
optionsB = fcn_AnimateCar3D_fillCenterlineOptions(networkB);
assert(isequal(sort(cellfun(@(o) o.Name, optionsB, 'UniformOutput', false)), sort({'straight','lane 1, left turn','lane 3, right turn'})));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
centerlineOptions = fcn_AnimateCar3D_fillCenterlineOptions(twoLaneRoad, FigNum=[]);
assert(numel(centerlineOptions)==2);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
centerlineOptions = fcn_AnimateCar3D_fillCenterlineOptions(twoLaneRoad, FigNum=-1);
assert(numel(centerlineOptions)==2);

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

%% FAIL case: A start road that is not in the scene
if 1==0
    fcn_AnimateCar3D_fillCenterlineOptions(twoLaneRoad, Start=struct('Road','9', 'LaneID',-1, 'S',0, 'Direction',1));
end
