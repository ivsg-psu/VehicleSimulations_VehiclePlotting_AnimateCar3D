% script_test_fcn_AnimateCar3D_loadSceneList.m
% Tests fcn_AnimateCar3D_loadSceneList
% Reads a scene list from a CSV file, a table, or a structure array.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_loadSceneList
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_loadSceneList
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

%% DEMO case: A scene list from a CSV file
figNum = 10001;
titleString = sprintf('DEMO case: A scene list from a CSV file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

csvFile = [tempname '.csv'];
fileID = fopen(csvFile,'w');
fprintf(fileID,'instance,role,meshID,motionFile,branchOf,branchID,splitTime,respondsTo,color,alpha\n');
fprintf(fileID,'ego,ego,2013_Toyota_Prius_Four,ego.csv,,0,,,,\n');
fprintf(fileID,'conf1,confederate,sample,conf1.csv,,0,,,0.9 0.1 0.1,\n');
fprintf(fileID,'conf1_b1,confederate,sample,conf1_b1.csv,conf1,1,2.5,,,0.4\n');
fprintf(fileID,'ego_b1,ego,2013_Toyota_Prius_Four,ego_b1.csv,ego,1,2.5,conf1_b1,,\n');
fprintf(fileID,'car7,traffic,box,,,0,,,,\n');
fclose(fileID);
sceneList = fcn_AnimateCar3D_loadSceneList(csvFile, FigNum=figNum);

% Check variable types
assert(isstruct(sceneList));

% Check variable sizes
assert(numel(sceneList)==5);
assert(isequal(size(sceneList(1).Color),[1 3]) && isequal(size(sceneList(1).Size),[1 3]));

% Check variable values
assert(isequal({sceneList.Instance}, {'ego','conf1','conf1_b1','ego_b1','car7'}));
assert(isequal(sceneList(2).Color, [0.9 0.1 0.1]));
assert(all(isnan(sceneList(1).Color)));
assert(strcmp(sceneList(3).BranchOf,'conf1') && sceneList(3).BranchID==1 && sceneList(3).SplitTime==2.5);
assert(strcmp(sceneList(4).RespondsTo,'conf1_b1'));
assert(sceneList(3).Alpha==0.4 && isnan(sceneList(1).Alpha));
[csvFolder,~] = fileparts(csvFile);
assert(strcmp(sceneList(1).MotionFile, fullfile(csvFolder,'ego.csv')));   % made absolute
assert(isempty(sceneList(5).MotionFile));
delete(csvFile);

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

%% TEST case: A structure array with only some fields (defaults fill the rest)
figNum = 20001;
titleString = sprintf('TEST case: A structure array with only some fields');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

rows = struct('instance', {'a','b'}, 'role', {'ego','traffic'});
sceneList = fcn_AnimateCar3D_loadSceneList(rows);
assert(strcmp(sceneList(2).MeshID,'sample') && sceneList(2).TimeOffset==0 && sceneList(2).BranchID==0);
assert(strcmp(sceneList(1).Role,'ego'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A table with sizes and numeric colors
sceneTable = table({'x';'y'}, [4 5]', [1.8 2]', [1.5 1.9]', [1 0 0; 0 0 1], 'VariableNames', {'instance','length','width','height','color'});
sceneList = fcn_AnimateCar3D_loadSceneList(sceneTable);
assert(isequal(sceneList(2).Size, [5 2 1.9]));
assert(isequal(sceneList(2).Color, [0 0 1]));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
sceneList = fcn_AnimateCar3D_loadSceneList(struct('instance','a'), FigNum=[]);
assert(numel(sceneList)==1);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
sceneList = fcn_AnimateCar3D_loadSceneList(struct('instance','a'), FigNum=-1);
assert(numel(sceneList)==1);

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

%% FAIL case: An unknown role
if 1==0
    fcn_AnimateCar3D_loadSceneList(struct('instance','a','role','bicycle'));
end

%% FAIL case: A branch of an instance that does not exist
if 1==0
    fcn_AnimateCar3D_loadSceneList(struct('instance','a','branchOf','nobody'));
end
