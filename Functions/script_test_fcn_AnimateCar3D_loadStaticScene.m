% script_test_fcn_AnimateCar3D_loadStaticScene.m
% Tests fcn_AnimateCar3D_loadStaticScene
% Reads a static scene (objects that never move).
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_loadStaticScene
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_loadStaticScene
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

%% DEMO case: The cube grid scene in the Data folder
figNum = 10001;
titleString = sprintf('DEMO case: The cube grid scene in the Data folder');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

sceneFile = fullfile(fileparts(which('fcn_AnimateCar3D_loadStaticScene')), '..', 'Data', 'staticScene_cubeGrid.csv');
staticScene = fcn_AnimateCar3D_loadStaticScene(sceneFile, FigNum=figNum);

% Check variable types
assert(isstruct(staticScene));

% Check variable sizes
assert(numel(staticScene) > 100);
assert(isequal(size(staticScene(1).Pose),[1 6]));

% Check variable values: every object is a box off the road (|y| > 10 m)
assert(all(strcmp({staticScene.MeshID},'box')));
poses = reshape([staticScene.Pose],6,[])';
assert(all(abs(poses(:,2)) > 10));

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

%% TEST case: Defaults from a structure array with only x and y
figNum = 20001;
titleString = sprintf('TEST case: Defaults from a structure array with only x and y');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

staticScene = fcn_AnimateCar3D_loadStaticScene(struct('x',{1,5},'y',{2,6}));
assert(isequal({staticScene.Instance}, {'static1','static2'}));
assert(isequal(staticScene(2).Pose, [5 6 0 0 0 0]));
assert(isequal(staticScene(1).Size, [2 2 2]));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A parked vehicle and a rotated building, from a table
sceneTable = table({'parked1';'building1'}, {'2013_Toyota_Prius_Four';'box'}, [10;30], [-5;20], [0;pi/4], [NaN;12], ...
    'VariableNames', {'instance','meshID','x','y','yaw','length'});
staticScene = fcn_AnimateCar3D_loadStaticScene(sceneTable);
assert(strcmp(staticScene(1).MeshID,'2013_Toyota_Prius_Four'));
assert(staticScene(2).Size(1)==12 && staticScene(1).Size(1)==2);
assert(abs(staticScene(2).Pose(6) - pi/4) < 1e-12);

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
staticScene = fcn_AnimateCar3D_loadStaticScene(struct('x',1,'y',2), FigNum=[]);
assert(numel(staticScene)==1);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
staticScene = fcn_AnimateCar3D_loadStaticScene(struct('x',1,'y',2), FigNum=-1);
assert(numel(staticScene)==1);

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

%% FAIL case: No x column
if 1==0
    fcn_AnimateCar3D_loadStaticScene(struct('y',1));
end
