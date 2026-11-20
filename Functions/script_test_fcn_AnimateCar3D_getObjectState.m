% script_test_fcn_AnimateCar3D_getObjectState.m
% Tests fcn_AnimateCar3D_getObjectState
% Reads catalog objects' states at a time.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_getObjectState
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_getObjectState
%   % * (fill in items here)


%% Set up the workspace
close all

branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=2, SplitTime=2, Duration=5, FigNum=-1);
trafficTime = (0:1:5)';
trafficFile = [tempname '.csv'];
writetable(table(trafficTime, 100-10*trafficTime, 3.5*ones(6,1), pi*ones(6,1), 'VariableNames', {'time','X','Y','yaw'}), trafficFile);
sceneRows = struct('instance', {'ego','ego_branch1','ego_branch2','car1'}, 'role', {'ego','ego','ego','traffic'}, ...
    'branchOf', {'','ego','ego',''}, 'motionFile', {'','','',trafficFile}, 'timeOffset', {0,0,0,0.5});
motions = [branchMotions.Parent; branchMotions.Branches];
motions = arrayfun(@(m) struct('Instance',m.Instance,'Time',m.Time,'Pose',m.Pose,'WheelSpin',m.WheelSpin,'SteerAngle',m.SteerAngle), motions, 'UniformOutput', false);
motions = [motions{:}]';
catalog = fcn_AnimateCar3D_buildCatalog(fcn_AnimateCar3D_loadSceneList(sceneRows), Motions=motions, ...
    StaticScene=fcn_AnimateCar3D_loadStaticScene(struct('x',50,'y',10)));

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

%% DEMO case: Every object at 3 s
figNum = 10001;
titleString = sprintf('DEMO case: Every object at 3 s');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

[objectStates, loadedMotions] = fcn_AnimateCar3D_getObjectState(catalog, {'ego','ego_branch1','ego_branch2','car1','static1'}, 3, FigNum=figNum);

% Check variable types
assert(isstruct(objectStates) && isa(loadedMotions,'containers.Map'));

% Check variable sizes
assert(numel(objectStates)==5 && isequal(size(objectStates(1).Pose),[1 6]));

% Check variable values
assert(~objectStates(1).Exists);                        % the parent ends at 2 s
assert(objectStates(2).Exists && objectStates(4).Exists && objectStates(5).Exists);
branch1 = branchMotions.Branches(1);
row = find(abs(branch1.Time - 3) < 1e-9);
assert(norm(objectStates(2).Pose([1 2 6]) - branch1.Pose(row,:)) < 1e-9);
assert(abs(objectStates(2).WheelSpin(1) - branch1.WheelSpin(row,1)) < 1e-9);
assert(abs(objectStates(4).Pose(1) - (100 - 10*2.5)) < 1e-6);   % car1: offset 0.5 s
assert(isKey(loadedMotions,'car1'));                    % read from its file once
assert(isequal(objectStates(5).Pose, [50 10 0 0 0 0]));

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

%% TEST case: Pose-only detail does not read files; yaw interpolates the short way
figNum = 20001;
titleString = sprintf('TEST case: Pose-only detail does not read files');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[objectStates, loadedMotions] = fcn_AnimateCar3D_getObjectState(catalog, 'car1', 3, Detail='pose');
assert(loadedMotions.Count==0);
assert(abs(objectStates.Pose(1) - 75) < 1e-6);

wrapRows = struct('instance','spinner');
wrapMotion = struct('Instance','spinner', 'Time',[0;1], 'Pose',[0 0 3.1; 1 0 -3.1]);
wrapCatalog = fcn_AnimateCar3D_buildCatalog(fcn_AnimateCar3D_loadSceneList(wrapRows), Motions=wrapMotion);
wrapState = fcn_AnimateCar3D_getObjectState(wrapCatalog, 'spinner', 0.5);
assert(abs(abs(wrapState.Pose(6)) - pi) < 0.01);        % through pi, not through 0

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
objectStates = fcn_AnimateCar3D_getObjectState(catalog, 1, 1, FigNum=[]);
assert(objectStates.Exists);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
objectStates = fcn_AnimateCar3D_getObjectState(catalog, 1, 1, FigNum=-1);
assert(objectStates.Exists);
delete(trafficFile);

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

%% FAIL case: A name not in the catalog
if 1==0
    fcn_AnimateCar3D_getObjectState(catalog, 'nobody', 1);
end
