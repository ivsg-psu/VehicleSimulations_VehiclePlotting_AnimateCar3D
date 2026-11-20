% script_test_fcn_AnimateCar3D_writeLiveTestFiles.m
% Tests fcn_AnimateCar3D_writeLiveTestFiles
% Stands in for a live data source: writes a watched folder as time goes on.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_writeLiveTestFiles
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_writeLiveTestFiles
%   % * (fill in items here)


%% Set up the workspace
close all

% Three objects: an ego vehicle (from the start), a car that starts at
% 1 s, and a truck that starts at 2 s and ends at 4 s
egoTime = (0:0.1:6)';
egoMotion = struct('Instance','ego', 'Time',egoTime, 'Pose',[10*egoTime, zeros(size(egoTime)), zeros(size(egoTime))]);
carTime = (0:0.5:5)';
carMotion = struct('Instance','car1', 'Time',carTime, 'Pose',[80-12*carTime, 3.5*ones(size(carTime)), pi*ones(size(carTime))]);
truckTime = (0:0.5:2)';
truckMotion = struct('Instance','truck1', 'Time',truckTime, 'Pose',[20+8*truckTime, -3.5*ones(size(truckTime)), zeros(size(truckTime))]);
motions = [egoMotion; carMotion; truckMotion];
sceneList = fcn_AnimateCar3D_loadSceneList(struct('instance',{'ego','car1','truck1'}, 'role',{'ego','traffic','traffic'}, ...
    'meshID',{'sample','sample','box'}, 'timeOffset',{0,1,2}, 'color',{[0.05 0.2 0.6],[0.8 0.1 0.1],[]}, ...
    'length',{NaN,NaN,12}, 'width',{NaN,NaN,2.5}, 'height',{NaN,NaN,3.8}));
liveFolder = fullfile(tempdir, 'AnimateCar3D_testLiveFolder');

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

%% DEMO case: Write the folder up to 3 s, in four steps
figNum = 10001;
titleString = sprintf('DEMO case: Write the folder up to 3 s, in four steps');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

liveState = [];
for sceneTime = [0 1 2 3]
    liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, sceneTime, LiveState=liveState, FigNum=figNum);
end

% Check variable types
assert(isstruct(liveState));

% Check variable sizes
assert(numel(liveState.LastWritten)==3);

% Check variable values
assert(isfile(fullfile(liveFolder,'sceneList.csv')));
assert(all(liveState.FileCreated) && ~any(liveState.FileDeleted));
assert(abs(liveState.LastWritten(1)-3) < 1e-9 && abs(liveState.LastWritten(2)-3) < 1e-9 && abs(liveState.LastWritten(3)-3) < 1e-9);
egoRead = fcn_CarMesh3D_loadMotionCSV(fullfile(liveFolder,'ego.csv'), FigNum=-1);
assert(numel(egoRead.Time)==31 && abs(egoRead.Pose(end,1)-30) < 1e-6);
carRead = fcn_CarMesh3D_loadMotionCSV(fullfile(liveFolder,'car1.csv'), FigNum=-1);
assert(abs(carRead.Time(1)-1) < 1e-9 && numel(carRead.Time)==5);   % scene times, from 1 s
readList = fcn_AnimateCar3D_loadSceneList(fullfile(liveFolder,'sceneList.csv'));
assert(isequal({readList.Instance}, {'ego','car1','truck1'}) && all([readList.TimeOffset]==0));
assert(readList(3).Size(1)==12 && all(abs(readList(2).Color - [0.8 0.1 0.1]) < 1e-9));

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

%% TEST case: Files are deleted after their motion ends
figNum = 20001;
titleString = sprintf('TEST case: Files are deleted after their motion ends');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveState = [];
for sceneTime = 0:0.5:6
    liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, sceneTime, LiveState=liveState, DeleteAfter=1);
    if abs(sceneTime-4.5) < 1e-9
        assert(isfile(fullfile(liveFolder,'truck1.csv')));     % ended at 4 s; kept 1 s more
    end
end
assert(~isfile(fullfile(liveFolder,'truck1.csv')) && liveState.FileDeleted(3));
assert(isfile(fullfile(liveFolder,'ego.csv')) && ~liveState.FileDeleted(1));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: One long-format traffic file
figNum = 20002;
titleString = sprintf('TEST case: One long-format traffic file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveState = [];
for sceneTime = [1 3]
    liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, sceneTime, LiveState=liveState, Format='traffic');
end
[trafficList, trafficMotions] = fcn_AnimateCar3D_loadTrafficFile(fullfile(liveFolder,'traffic.csv'), InstancePrefix='traffic_');
assert(isequal(sort({trafficList.Instance}), sort({'traffic_ego','traffic_car1','traffic_truck1'})));
truckIndex = strcmp({trafficList.Instance}, 'traffic_truck1');
assert(trafficList(truckIndex).Size(1)==12 && numel(trafficMotions(truckIndex).Time)==3);
readList = fcn_AnimateCar3D_loadSceneList(fullfile(liveFolder,'sceneList.csv'));
assert(strcmp(readList(1).Instance, 'traffic_ego'));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, 2, FigNum=[]);
assert(liveState.RowsWritten > 0);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, 2, FigNum=-1);
assert(liveState.RowsWritten > 0);
rmdir(liveFolder, 's');

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

%% FAIL case: A motion with no scene list row
if 1==0
    fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList(1), motions, 2);
end
