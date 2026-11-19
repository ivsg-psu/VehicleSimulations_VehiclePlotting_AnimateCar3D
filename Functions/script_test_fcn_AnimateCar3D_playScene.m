% script_test_fcn_AnimateCar3D_playScene.m
% Tests fcn_AnimateCar3D_playScene
% Draws display lists step by step, reusing graphics, with detail tiers.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_playScene
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_playScene
%   % * (fill in items here)


%% Set up the workspace
close all

meshSet = fcn_AnimateCar3D_loadMeshes('sample', LowFaces=200, FigNum=-1);

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

%% DEMO case: Three tiers, objects arriving and leaving
figNum = 10001;
titleString = sprintf('DEMO case: Three tiers, objects arriving and leaving');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;
fcn_CarMesh3D_plotScene(GroundExtent=[-20 120 -30 30], FigNum=figNum);
view(-30,25);

% Step 1: an ego vehicle (near), two cars (near and middle), 20 boxes
displayList = fcn_INTERNAL_exampleList(0, 20);
playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, FigNum=figNum);
drawnow;

% Check variable types
assert(isstruct(playerState));
assert(isgraphics(playerState.Axes));
assert(isgraphics(playerState.BoxPatch));

% Check variable sizes
assert(numel(playerState.Pool)==3);

% Check variable values: everything was created, nothing reused
stats = playerState.Stats;
assert(stats.NumNear==2 && stats.NumMiddle==1 && stats.NumFar==20);
assert(stats.NumCreated==3 && stats.NumReused==0 && stats.NumHidden==0);
assert(size(get(playerState.BoxPatch,'Faces'),1)==5*20);

% Step 2: car2 leaves, car3 arrives as middle: it reuses car2's graphics
displayList = fcn_INTERNAL_exampleList(1, 30, true);
playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState);
drawnow;
stats = playerState.Stats;
assert(stats.NumCreated==0 && stats.NumReused==1 && stats.NumHidden==1);
assert(numel(playerState.Pool)==3);
assert(size(get(playerState.BoxPatch,'Faces'),1)==5*30);

% The ego moved to x = 1 (its transform), and car3 is at x = 25
egoEntry = playerState.Pool(strcmp({playerState.Pool.Instance},'ego'));
egoMatrix = get(egoEntry.Handles.Transform,'Matrix');
assert(abs(egoMatrix(1,4) - 1) < 1e-9);
car3Entry = playerState.Pool(strcmp({playerState.Pool.Instance},'car3'));
car3Matrix = get(car3Entry.Handles.Transform,'Matrix');
assert(abs(car3Matrix(1,4) - 25) < 1e-9);

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

%% TEST case: Leaving objects are hidden, then deleted after IdleSteps
figNum = 20001;
titleString = sprintf('TEST case: Leaving objects are hidden, then deleted after IdleSteps');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

playerState = fcn_AnimateCar3D_playScene(fcn_INTERNAL_exampleList(0, 0), meshSet, FigNum=figNum);
onlyEgo = fcn_AnimateCar3D_fillDisplayList(Instance='ego', MeshID='sample', Pose=[2 0 0]);
playerState = fcn_AnimateCar3D_playScene(onlyEgo, meshSet, PlayerState=playerState, IdleSteps=2);
assert(playerState.Stats.NumHidden==2);
hiddenEntries = playerState.Pool(cellfun(@isempty,{playerState.Pool.Instance}));
assert(numel(hiddenEntries)==2);
assert(strcmp(get(hiddenEntries(1).Handles.Transform,'Visible'),'off'));
for ith_step = 1:3
    playerState = fcn_AnimateCar3D_playScene(onlyEgo, meshSet, PlayerState=playerState, IdleSteps=2);
end
assert(numel(playerState.Pool)==1);   % the two hidden entries were deleted

%% TEST case: Color and Alpha are applied, and changing them restyles
figNum = 20002;
titleString = sprintf('TEST case: Color and Alpha are applied, and changing them restyles');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

redGhost = fcn_AnimateCar3D_fillDisplayList(Instance='ghost', MeshID='sample', Pose=[0 0 0], Color=[1 0 0], Alpha=0.3);
playerState = fcn_AnimateCar3D_playScene(redGhost, meshSet, FigNum=figNum);
entry = playerState.Pool(1);
assert(all(cellfun(@(p) get(p,'FaceAlpha'), entry.AllPatches) <= 0.3+1e-9));
tintedColors = get(entry.TintPatches{1},'FaceVertexCData');
assert(all(tintedColors(:,1) >= 0.75 - 1e-9));   % at least 75% red
plain = fcn_AnimateCar3D_fillDisplayList(Instance='ghost', MeshID='sample', Pose=[0 0 0]);
playerState = fcn_AnimateCar3D_playScene(plain, meshSet, PlayerState=playerState);
entry = playerState.Pool(1);
assert(isequal(get(entry.TintPatches{1},'FaceVertexCData'), entry.TintOriginal{1}));
assert(max(cellfun(@(p) get(p,'FaceAlpha'), entry.AllPatches)) > 0.99);

%% TEST case: Clear deletes everything
playerState = fcn_AnimateCar3D_playScene([], meshSet, PlayerState=playerState, Action='clear');
assert(isempty(playerState.Pool));
assert(isempty(findobj(gca,'Type','hgtransform')));

%% Fast Mode Tests

%% Basic example - NO FIGURE given (draws in the current figure)
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); clf;
playerState = fcn_AnimateCar3D_playScene(fcn_INTERNAL_exampleList(0, 5), meshSet, FigNum=[]);
assert(numel(playerState.Pool)==3);

%% Basic fast mode - FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); clf;
playerState = fcn_AnimateCar3D_playScene(fcn_INTERNAL_exampleList(0, 5), meshSet, FigNum=-1);
assert(numel(playerState.Pool)==3);

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

%% FAIL case: A mesh that was not loaded
if 1==0
    badList = fcn_AnimateCar3D_fillDisplayList(Instance='a', MeshID='2013_Toyota_Prius_Four', Pose=[0 0 0]);
    fcn_AnimateCar3D_playScene(badList, meshSet);
end

%% Functions follow
%% fcn_INTERNAL_exampleList
function displayList = fcn_INTERNAL_exampleList(x0, Nboxes, flagSwap)
% An ego (near) at x0, car1 (near), car2 (middle; or car3 if flagSwap),
% and Nboxes far boxes
if nargin<3
    flagSwap = false;
end
if flagSwap
    middleName = 'car3';
    middleX = 25;
else
    middleName = 'car2';
    middleX = -10;
end
displayList = fcn_AnimateCar3D_fillDisplayList(Instance={'ego','car1',middleName}, MeshID='sample', ...
    Pose=[x0 0 0; 12 3.5 0; middleX -3.5 0], Tier={'near','near','middle'}, ...
    WheelSpin=[x0 x0 x0 x0; 0 0 0 0; 0 0 0 0]);
if Nboxes>0
    boxNames = compose('box%d', (1:Nboxes)');
    boxPoses = [40+4*(0:Nboxes-1)', 3.5*mod((0:Nboxes-1)',3)-3.5, zeros(Nboxes,1)];
    displayList = fcn_AnimateCar3D_fillDisplayList(Instance=boxNames, MeshID='sample', Pose=boxPoses, ...
        Tier='far', AppendTo=displayList);
end
end % Ends fcn_INTERNAL_exampleList
