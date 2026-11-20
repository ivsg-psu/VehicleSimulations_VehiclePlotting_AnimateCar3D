% script_test_fcn_AnimateCar3D_playScene.m
% Tests fcn_AnimateCar3D_playScene
% Draws display lists step by step, reusing graphics, with detail tiers and levels.
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

meshSet = fcn_AnimateCar3D_loadMeshes('sample', FigNum=-1);

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
assert(all(tintedColors(entry.TintMasks{1},1) >= 0.75 - 1e-9));   % at least 75% red
plain = fcn_AnimateCar3D_fillDisplayList(Instance='ghost', MeshID='sample', Pose=[0 0 0]);
playerState = fcn_AnimateCar3D_playScene(plain, meshSet, PlayerState=playerState);
entry = playerState.Pool(1);
assert(isequal(get(entry.TintPatches{1},'FaceVertexCData'), entry.TintOriginal{1}));
assert(max(cellfun(@(p) get(p,'FaceAlpha'), entry.AllPatches)) > 0.99);

%% TEST case: Tint by part: opaque glass is not tinted
figNum = 20003;
titleString = sprintf('TEST case: Tint by part: opaque glass is not tinted');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% The sample car with opaque glass (as some downloaded models have): its
% windows join the opaque body patch, and must still not be tinted
opaqueSet = meshSet;
glassPart = find(strcmp(opaqueSet.sample.Full.PartNames,'glass'));
flagGlass = opaqueSet.sample.Full.FacePartIndex==glassPart;
assert(any(flagGlass));
opaqueSet.sample.Full.FaceAlpha(flagGlass) = 1;
redCar = fcn_AnimateCar3D_fillDisplayList(Instance='red', MeshID='sample', Pose=[0 0 0], Color=[1 0 0]);
playerState = fcn_AnimateCar3D_playScene(redCar, opaqueSet, FigNum=figNum);
entry = playerState.Pool(1);
allMasks = vertcat(entry.TintMasks{:});
assert(any(~allMasks) && any(allMasks));        % some faces in the tinted patches are left alone
for ith_patch = 1:numel(entry.TintPatches)
    colorsNow = get(entry.TintPatches{ith_patch},'FaceVertexCData');
    mask = entry.TintMasks{ith_patch};
    assert(isequal(colorsNow(~mask,:), entry.TintOriginal{ith_patch}(~mask,:)));
end
fcn_AnimateCar3D_playScene([], opaqueSet, PlayerState=playerState, Action='clear');

%% TEST case: Detail levels: separate objects switch levels; far objects merge
figNum = 20004;
titleString = sprintf('TEST case: Detail levels: separate objects switch levels; far objects merge');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;
fcn_CarMesh3D_plotScene(GroundExtent=[-20 120 -30 30], FigNum=figNum);
view(-30,25);
sampleLevels = meshSet.sample.Levels;
Nlevels = numel(sampleLevels);

% A middle car at level 2, then 3, then 2 again (reused)
levelList = @(level) fcn_AnimateCar3D_fillDisplayList(Instance='mid', MeshID='sample', Pose=[10 0 0], Tier='middle', Level=level);
playerState = fcn_AnimateCar3D_playScene(levelList(2), meshSet, FigNum=figNum);
entry = playerState.Pool(strcmp({playerState.Pool.Instance},'mid'));
assert(entry.Level==2);
drawnFaces = sum(cellfun(@(p) size(get(p,'Faces'),1), entry.AllPatches));
assert(drawnFaces == sampleLevels(2).Faces);
playerState = fcn_AnimateCar3D_playScene(levelList(3), meshSet, PlayerState=playerState);
assert(playerState.Stats.NumCreated==1 && playerState.Stats.NumHidden==1);
playerState = fcn_AnimateCar3D_playScene(levelList(2), meshSet, PlayerState=playerState);
assert(playerState.Stats.NumCreated==0 && playerState.Stats.NumReused==1);
% With no Level, its ScreenSize picks the level
sizeList = fcn_AnimateCar3D_fillDisplayList(Instance='mid', MeshID='sample', Pose=[10 0 0], Tier='middle', ...
    ScreenSize=sampleLevels(3).MaxScreenSize - 1);
playerState = fcn_AnimateCar3D_playScene(sizeList, meshSet, PlayerState=playerState);
assert(playerState.Pool(strcmp({playerState.Pool.Instance},'mid')).Level == 3);

% Far cars at three levels (and one box, and one tinted): the meshes are
% merged into one patch, the box goes with the boxes
farList = fcn_AnimateCar3D_fillDisplayList(Instance={'f1','f2','f3','f4','f5'}, MeshID='sample', ...
    Pose=[40 0 0; 50 4 0; 60 -4 0; 70 0 0; 80 4 0], Tier='far', Level=[1; 2; NaN; Nlevels; 2], ...
    ScreenSize=[NaN; NaN; sampleLevels(4).MaxScreenSize; NaN; NaN], Color=[NaN NaN NaN; NaN NaN NaN; NaN NaN NaN; NaN NaN NaN; 0 0 1]);
playerState = fcn_AnimateCar3D_playScene(farList, meshSet, PlayerState=playerState);
expectedFaces = sampleLevels(1).Faces + 2*sampleLevels(2).Faces + sampleLevels(4).Faces;
assert(playerState.Stats.NumMergedFaces == expectedFaces);
assert(size(get(playerState.MergedPatch,'Faces'),1) == expectedFaces);
assert(size(get(playerState.BoxPatch,'Faces'),1) == 5);
% The tinted car (f5, the last of the level-2 group): its glass is not
% blue, its body is
mergedColors = get(playerState.MergedPatch,'FaceVertexCData');
level2Mesh = sampleLevels(2).Mesh;
f5Rows = sampleLevels(1).Faces + sampleLevels(2).Faces + (1:sampleLevels(2).Faces);   % groups sorted: level 1, level 2 (f2, f5), level 4
flagGlass2 = level2Mesh.FacePartIndex == find(strcmp(level2Mesh.PartNames,'glass'));
flagBody2 = level2Mesh.FacePartIndex == find(strcmp(level2Mesh.PartNames,'body'));
assert(isequal(mergedColors(f5Rows(flagGlass2),:), level2Mesh.FaceColors(flagGlass2,:)));
assert(all(mergedColors(f5Rows(flagBody2),3) >= 0.75 - 1e-9));
% Each merged car is placed at its pose (f1 at x = 40: its vertices span
% the car from its rear overhang)
mergedVertices = get(playerState.MergedPatch,'Vertices');
f1Vertices = mergedVertices(1:size(sampleLevels(1).Mesh.Vertices,1),:);
assert(abs(min(f1Vertices(:,1)) - (40 + min(sampleLevels(1).Mesh.Vertices(:,1)))) < 1e-9);
% Every merged face is lit from outside: its corners run clockwise seen
% from outside (MATLAB's way), so its right-hand normal points inward
f1Faces = get(playerState.MergedPatch,'Faces');
f1Faces = f1Faces(1:sampleLevels(1).Faces,:);
rightHandNormals = cross(mergedVertices(f1Faces(:,2),:)-mergedVertices(f1Faces(:,1),:), mergedVertices(f1Faces(:,3),:)-mergedVertices(f1Faces(:,1),:), 2);
assert(mean(sum(rightHandNormals.*sampleLevels(1).Mesh.FaceNormals,2) < 0) > 0.99);   % (f1 is not turned: yaw 0)
% Nothing far: both patches hidden
playerState = fcn_AnimateCar3D_playScene(levelList(2), meshSet, PlayerState=playerState);
assert(strcmp(get(playerState.MergedPatch,'Visible'),'off') && strcmp(get(playerState.BoxPatch,'Visible'),'off'));

%% TEST case: Clear deletes everything
playerState = fcn_AnimateCar3D_playScene([], meshSet, PlayerState=playerState, Action='clear');
assert(isempty(playerState.Pool));
assert(isempty(findobj(gca,'Type','hgtransform')));

%% TEST case: Simple shapes: pedestrians, a raised gate arm, posts, and a far car
figNum = 20005;
titleString = sprintf('TEST case: Simple shapes: pedestrians, a raised gate arm, posts, and a far car');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;
shapeSet = fcn_AnimateCar3D_loadMeshes({'sample','pedestrian','bar','cylinder'}, FigNum=-1);
shapeList = fcn_AnimateCar3D_fillDisplayList(Instance={'walker1','walker2','gate','post','farCar'}, ...
    MeshID={'pedestrian','pedestrian','bar','cylinder','sample'}, Tier='far', ...
    Pose=[0 0 0 0 0 pi/2; 2 1 0 0 0 0; 5 -3 1 0 -pi/2 pi/2; 5 -3.4 0 0 0 0; 15 5 0 0 0 0], ...
    Size=[NaN NaN NaN; NaN NaN 1.6; NaN NaN NaN; 0.3 0.3 1.1; NaN NaN NaN], ...
    Color=[0.8 0.2 0.2; 0.2 0.6 0.2; 0.9 0.9 0.1; 0.3 0.3 0.3; NaN NaN NaN]);
playerState = fcn_AnimateCar3D_playScene(shapeList, shapeSet, FigNum=figNum);
currentFigure = get(groot,'CurrentFigure');
assert(isequal(currentFigure.Number, figNum) && isequal(currentFigure.CurrentAxes, playerState.Axes));   % the scene stays current
axis equal; view(-30,25);
shapePatch = playerState.BoxPatch;
vertices = get(shapePatch,'Vertices');
pedestrianShape = fcn_AnimateCar3D_fillSimpleShape('pedestrian');
barShape = fcn_AnimateCar3D_fillSimpleShape('bar');
cylinderShape = fcn_AnimateCar3D_fillSimpleShape('cylinder');
assert(size(vertices,1) == 2*size(pedestrianShape.Vertices,1) + size(barShape.Vertices,1) + size(cylinderShape.Vertices,1) + 8);
assert(size(get(shapePatch,'Faces'),1) == 2*size(pedestrianShape.Faces,1) + 6 + 13 + 5);
assert(abs(max(vertices(:,3)) - 5) < 1e-6);   % the raised arm: 1 m up, then its 4 m length straight up
shapeFaces = get(shapePatch,'Faces');           % corners clockwise seen from outside (MATLAB's way)
postCenter = [5 -3.4 0.55];
postFaces = find(all(ismember(shapeFaces(:,1:4), find(abs(vertices(:,1)-5)<0.2 & abs(vertices(:,2)+3.4)<0.2 & vertices(:,3)<1.2)),2));
assert(numel(postFaces)==13);
for ith_face = postFaces'
    corners = shapeFaces(ith_face, ~isnan(shapeFaces(ith_face,:)));
    rightHandNormal = cross(vertices(corners(2),:)-vertices(corners(1),:), vertices(corners(3),:)-vertices(corners(1),:));
    assert(dot(rightHandNormal, mean(vertices(corners,:),1) - postCenter) < 0);
end

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
