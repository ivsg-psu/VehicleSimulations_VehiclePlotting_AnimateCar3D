% script_test_fcn_AnimateCar3D_loadTrafficFile.m
% Tests fcn_AnimateCar3D_loadTrafficFile
% Reads many vehicles from one long-format traffic file.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_loadTrafficFile
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_loadTrafficFile
%   % * (fill in items here)


%% Set up the workspace
close all


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

%% DEMO case: Three vehicles in one file, rows mixed up
figNum = 10001;
titleString = sprintf('DEMO case: Three vehicles in one file, rows mixed up');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

t = (0:0.5:5)';
longTable = [table(repmat(1,numel(t),1), t, 10*t, zeros(size(t)), zeros(size(t)), 'VariableNames',{'id','time','X','Y','yaw'}); ...
             table(repmat(2,numel(t),1), t, 50-8*t, 3.5*ones(size(t)), pi*ones(size(t)), 'VariableNames',{'id','time','X','Y','yaw'}); ...
             table(repmat(3,numel(t),1), t, 5*t, -3.5+0.2*t, 0.04*ones(size(t)), 'VariableNames',{'id','time','X','Y','yaw'})];
longTable = longTable(randperm(height(longTable)),:);   % rows in any order
csvFile = [tempname '.csv'];
writetable(longTable, csvFile);
[sceneList, motions] = fcn_AnimateCar3D_loadTrafficFile(csvFile, MeshID='box', FigNum=figNum);
delete(csvFile);

% Check variable types
assert(isstruct(sceneList) && isstruct(motions));

% Check variable sizes
assert(numel(sceneList)==3 && numel(motions)==3);
assert(isequal(size(motions(1).Pose),[numel(t) 3]));

% Check variable values: sorted by time, names from the ids
[~, order] = sort({motions.Instance});
motions = motions(order);
assert(isequal({motions.Instance}, {'traffic_1','traffic_2','traffic_3'}));
assert(issorted(motions(2).Time));
assert(abs(motions(2).Pose(end,1) - 10) < 1e-9);
assert(all(strcmp({sceneList.MeshID},'box')) && all(strcmp({sceneList.Role},'traffic')));

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

%% TEST case: Sizes, text ids, and a different prefix
figNum = 20001;
titleString = sprintf('TEST case: Sizes, text ids, and a different prefix');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

longTable = table({'truckA';'truckA'}, [0;1], [0;20], [0;0], [0;0], [12;12], [2.5;2.5], [3.8;3.8], ...
    'VariableNames',{'id','time','X','Y','yaw','length','width','height'});
[sceneList, motions] = fcn_AnimateCar3D_loadTrafficFile(longTable, InstancePrefix='');
assert(strcmp(motions(1).Instance,'truckA'));
assert(isequal(sceneList(1).Size, [12 2.5 3.8]));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
oneRow = table(1, 0, 0, 0, 0, 'VariableNames',{'id','time','X','Y','yaw'});
[sceneList, motions] = fcn_AnimateCar3D_loadTrafficFile(oneRow, FigNum=[]);
assert(numel(motions)==1);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
[sceneList, motions] = fcn_AnimateCar3D_loadTrafficFile(oneRow, FigNum=-1);
assert(numel(motions)==1);

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

%% FAIL case: A missing yaw column
if 1==0
    fcn_AnimateCar3D_loadTrafficFile(table(1,0,0,0,'VariableNames',{'id','time','X','Y'}));
end
