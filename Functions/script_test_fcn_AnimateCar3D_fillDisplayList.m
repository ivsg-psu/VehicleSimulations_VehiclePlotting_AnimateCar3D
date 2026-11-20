% script_test_fcn_AnimateCar3D_fillDisplayList.m
% Tests fcn_AnimateCar3D_fillDisplayList
% Builds the display list the scene player draws at one time step.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillDisplayList
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillDisplayList
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

%% DEMO case: An ego vehicle, two nearby cars, and 50 boxes far away
figNum = 10001;
titleString = sprintf('DEMO case: An ego vehicle, two nearby cars, and 50 boxes far away');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

displayList = fcn_AnimateCar3D_fillDisplayList(Instance='ego', MeshID='sample', Pose=[0 0 0], ...
    WheelSpin=[1 1 1 1], SteerAngle=[0.1 0.08], LightStates=struct('Headlights','low'), Time=1.5);
displayList = fcn_AnimateCar3D_fillDisplayList(Instance={'car1','car2'}, MeshID='sample', ...
    Pose=[12 3.5 0; -10 -3.5 pi], Tier={'near','middle'}, Color=[0.9 0.1 0.1], AppendTo=displayList);
farNames = compose('far%d', (1:50)');
farPoses = [60+20*(0:49)', 3.5*mod((0:49)',3)-3.5, zeros(50,1)];
displayList = fcn_AnimateCar3D_fillDisplayList(Instance=farNames, MeshID='sample', Pose=farPoses, ...
    Tier='far', Size=repmat([4.5 1.8 1.5],50,1), AppendTo=displayList, FigNum=figNum);

% Check variable types
assert(isstruct(displayList));
assert(isstruct(displayList.Objects));
assert(iscell(displayList.Boxes.Instance));

% Check variable sizes
assert(numel(displayList.Objects)==3);
assert(isequal(size(displayList.Boxes.Pose),[50 6]));
assert(isequal(size(displayList.Boxes.Size),[50 3]));

% Check variable values
assert(displayList.Time==1.5);
assert(isequal({displayList.Objects.Instance}, {'ego','car1','car2'}));
assert(isequal({displayList.Objects.Tier}, {'near','near','middle'}));
assert(isequal(displayList.Objects(1).Pose, [0 0 0 0 0 0]));
assert(isequal(displayList.Objects(3).Pose, [-10 -3.5 0 0 0 pi]));
assert(isequal(displayList.Objects(2).Color, [0.9 0.1 0.1]));
assert(all(isnan(displayList.Objects(1).Color)));
assert(strcmp(displayList.Objects(1).LightStates.Headlights,'low'));

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

%% TEST case: Full 6-element poses and per-object alpha
figNum = 20001;
titleString = sprintf('TEST case: Full 6-element poses and per-object alpha');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

displayList = fcn_AnimateCar3D_fillDisplayList(Instance={'a','b'}, MeshID={'sample','sample'}, ...
    Pose=[1 2 0.1 0.01 0.02 0.5; 3 4 0 0 0 1], Alpha=[1; 0.4], BodyRoll=[0.05; 0]);
assert(isequal(displayList.Objects(1).Pose, [1 2 0.1 0.01 0.02 0.5]));
assert(displayList.Objects(2).Alpha==0.4);
assert(displayList.Objects(1).BodyRoll==0.05);
assert(isempty(displayList.Boxes.Instance));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Levels and sizes on screen
displayList = fcn_AnimateCar3D_fillDisplayList(Instance={'a','b','c'}, MeshID='sample', Pose=zeros(3,3), ...
    Tier={'near','middle','far'}, Level=[0; 2; NaN], ScreenSize=[150; 60; 12]);
assert(isequal([displayList.Objects.Level], [0 2]) && isequal([displayList.Objects.ScreenSize], [150 60]));
assert(isnan(displayList.Boxes.Level) && displayList.Boxes.ScreenSize==12);
displayList = fcn_AnimateCar3D_fillDisplayList(Instance='d', MeshID='sample', Pose=[0 0 0], Tier='middle');
assert(isnan(displayList.Objects.Level) && isnan(displayList.Objects.ScreenSize));

%% TEST case: Simple shapes are always far
displayList = fcn_AnimateCar3D_fillDisplayList(Instance={'b','v','p'}, MeshID={'box','sample','Pedestrian'}, ...
    Pose=zeros(3,3), Size=[10 5 3; NaN NaN NaN; NaN NaN NaN]);
assert(isequal(displayList.Boxes.Instance, {'b';'p'}) && numel(displayList.Objects)==1);
assert(isequal(displayList.Boxes.MeshID, {'box';'pedestrian'}));     % shape names in lower case
assert(isequal(displayList.Boxes.Size(1,:), [10 5 3]));

%% TEST case: An empty list (nothing to draw)
displayList = fcn_AnimateCar3D_fillDisplayList();
assert(isempty(displayList.Objects) && isempty(displayList.Boxes.Instance));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
displayList = fcn_AnimateCar3D_fillDisplayList(Instance='a', MeshID='sample', Pose=[0 0 0], FigNum=[]);
assert(numel(displayList.Objects)==1);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
displayList = fcn_AnimateCar3D_fillDisplayList(Instance='a', MeshID='sample', Pose=[0 0 0], FigNum=-1);
assert(numel(displayList.Objects)==1);

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

%% FAIL case: Two objects with the same name
if 1==0
    fcn_AnimateCar3D_fillDisplayList(Instance={'a','a'}, MeshID='sample', Pose=zeros(2,3));
end

%% FAIL case: An unknown tier
if 1==0
    fcn_AnimateCar3D_fillDisplayList(Instance='a', MeshID='sample', Pose=[0 0 0], Tier='close');
end
