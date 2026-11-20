% script_test_fcn_AnimateCar3D_selectObjects.m
% Tests fcn_AnimateCar3D_selectObjects
% Decides which objects to draw at each step, and at which tier and detail level.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_selectObjects
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_selectObjects
%   % * (fill in items here)


%% Set up the workspace
close all

% A test scene: an ego driving along x at 10 m/s, traffic on a grid of
% lanes (right-hand traffic: lanes on the right of +x, y < 0, drive
% toward +x; lanes on the left toward -x), a confederate splitting into
% two branches, and static boxes
egoTime = (0:0.1:20)';
egoMotion = struct('Instance','ego', 'Time',egoTime, 'Pose',[10*egoTime, zeros(size(egoTime)), zeros(size(egoTime))]);
Ntraffic = 200;
trafficRows = struct('instance', cellstr(compose('car%d', 1:Ntraffic)), 'role', 'traffic', 'meshID', 'sample');
trafficMotions = repmat(struct('Instance','', 'Time',egoTime, 'Pose',[]), Ntraffic, 1);
for ith_car = 1:Ntraffic
    lane = mod(ith_car,8) - 3.5;
    trafficMotions(ith_car).Instance = sprintf('car%d', ith_car);
    direction = -sign(lane);                     % y < 0: +x; y > 0: -x
    trafficMotions(ith_car).Pose = [-200 + 4*ith_car + direction*8*egoTime, 3.6*lane*ones(size(egoTime)), ...
        (direction<0)*pi*ones(size(egoTime))];
end
branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=2, SplitTime=3, Duration=8, StartPose=[60 -10 pi/2], ...
    ParentName='conf1', FigNum=-1);
confRows = struct('instance', {'conf1','conf1_branch1','conf1_branch2'}, 'role', 'confederate', ...
    'branchOf', {'','conf1','conf1'}, 'branchID', {0,1,2});
confMotions = arrayfun(@(m) struct('Instance',m.Instance,'Time',m.Time,'Pose',m.Pose), ...
    [branchMotions.Parent; branchMotions.Branches], 'UniformOutput', false);
sceneList = fcn_AnimateCar3D_loadSceneList([struct('instance','ego','role','ego','meshID','sample','branchOf','','branchID',0); ...
    fcn_INTERNAL_addFields(trafficRows(:)); fcn_INTERNAL_addFields(confRows(:), 'sample')]);
catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=[egoMotion; trafficMotions; [confMotions{:}]'], ...
    StaticScene=fcn_AnimateCar3D_loadStaticScene(struct('x',{40,500},'y',{20,20})));

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

%% DEMO case: A circle around the ego, at 5 s
figNum = 10001;
titleString = sprintf('DEMO case: A circle around the ego, at 5 s');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Radius=100);
[displayList, selectorState] = fcn_AnimateCar3D_selectObjects(catalog, 5, criteria, FigNum=figNum);

% Check variable types
assert(isstruct(displayList) && isstruct(selectorState));
assert(isa(selectorState.Tiers,'containers.Map'));

% Check variable values: the ego is near; at most 10 near (plus the fixed
% ego), 40 middle; everything drawn is within 100 m (110% with margins)
% or always shown; without a camera, sizes on screen use NominalScale
stats = selectorState.Stats;
assert(strcmp(stats.RegionUsed,'circle'));
assert(selectorState.Tiers('ego')==1);
assert(stats.NumNear <= 11 && stats.NumMiddle <= 40);
nearNames = {displayList.Objects(strcmp({displayList.Objects.Tier},'near')).Instance};
assert(ismember('ego', nearNames));
egoX = 50;
allPoses = [reshape([displayList.Objects.Pose],6,[])'; displayList.Boxes.Pose];
allNames = [{displayList.Objects.Instance}, displayList.Boxes.Instance(:)'];
flagConfederate = startsWith(allNames,'conf');
assert(all(hypot(allPoses(~flagConfederate,1)-egoX, allPoses(~flagConfederate,2)) <= 100 + 3));
% The confederate split at 3 s: its parent is hidden, both branches shown
% (see-through, tinted the confederate color)
assert(~ismember('conf1', allNames) && all(ismember({'conf1_branch1','conf1_branch2'}, allNames)));
branchRow = find(strcmp({displayList.Objects.Instance},'conf1_branch1'));
if ~isempty(branchRow)
    assert(abs(displayList.Objects(branchRow).Alpha - 0.35) < 1e-12);
    assert(isequal(displayList.Objects(branchRow).Color, criteria.ConfederateColor));
end
% The near objects are the largest on screen: none of the middle ones is
% larger than the smallest near one (except the fixed ego), and each tier
% is within its sizes
objectSizes = [displayList.Objects.ScreenSize];
flagNear = strcmp({displayList.Objects.Tier},'near') & ~strcmp({displayList.Objects.Instance},'ego');
flagMiddle = strcmp({displayList.Objects.Tier},'middle') & ~startsWith({displayList.Objects.Instance},'conf');
assert(min(objectSizes(flagNear)) >= max(objectSizes(flagMiddle)) - 1e-9);
assert(all(objectSizes(flagNear) >= criteria.TopScreenSize) && all(objectSizes(flagMiddle) >= criteria.MergeBelowSize));
flagFarCar = startsWith(displayList.Boxes.Instance,'car');
assert(all(displayList.Boxes.ScreenSize(flagFarCar) < criteria.MergeBelowSize));
assert(all(isnan([displayList.Objects(flagMiddle).Level])));   % no MeshSet: the player chooses levels

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

%% TEST case: Hysteresis keeps a tier just past its boundary
figNum = 20001;
titleString = sprintf('TEST case: Hysteresis keeps a tier just past its boundary');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% One car pulling away from a fixed center, 1 m per step, from 20 to 40 m
% (near ends at about 105 px: D x 618 / 105 = 29 m for a typical car)
pullTime = (0:20)';
pullMotion = struct('Instance','leaver', 'Time',pullTime, 'Pose',[20+pullTime, zeros(21,1), zeros(21,1)]);
pullCatalog = fcn_AnimateCar3D_buildCatalog(fcn_AnimateCar3D_loadSceneList(struct('instance','leaver')), Motions=pullMotion);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Center=[0 0]);
for hysteresis = [0.1 0]
    criteria.Hysteresis = hysteresis;
    state = [];
    tiers = zeros(1,21);
    sizes = zeros(1,21);
    for ith_step = 1:21
        [displayList, state] = fcn_AnimateCar3D_selectObjects(pullCatalog, pullTime(ith_step), criteria, SelectorState=state);
        tiers(ith_step) = state.Tiers('leaver');
        sizes(ith_step) = displayList.Objects.ScreenSize;
    end
    % Near until its size falls below 105/(1 + hysteresis), then middle for good
    lastNear = find(tiers==1, 1, 'last');
    assert(all(tiers(1:lastNear)==1) && all(tiers(lastNear+1:end)==2));
    assert(sizes(lastNear)*(1+hysteresis) >= 105 && sizes(lastNear+1)*(1+hysteresis) < 105);
    if hysteresis>0
        assert(sizes(lastNear) < 105);       % kept past the boundary
    end
end

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: The camera's view: only what the camera sees
figNum = 20002;
titleString = sprintf('TEST case: The camera''s view: only what the camera sees');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% A camera behind the ego (at x = 50 at 5 s), looking forward along +x
camera = struct('Position',[35 0 8], 'Target',[80 0 0], 'ViewAngle',40, 'AspectRatio',16/9);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(MaxDistance=100);
[displayList, state] = fcn_AnimateCar3D_selectObjects(catalog, 5, criteria, Camera=camera, FigNum=figNum);
assert(strcmp(state.Stats.RegionUsed,'cameraView'));
allPoses = [reshape([displayList.Objects.Pose],6,[])'; displayList.Boxes.Pose];
allNames = [{displayList.Objects.Instance}, displayList.Boxes.Instance(:)'];
flagNotAlways = ~startsWith(allNames,'conf') & ~strcmp(allNames,'ego');
assert(all(allPoses(flagNotAlways,1) > 35 - 6));            % nothing far behind the camera
assert(all(hypot(allPoses(flagNotAlways,1)-35, allPoses(flagNotAlways,2)) <= 110 + 6));
% Sizes on screen are measured from the camera (450 px, 40 degrees)
objectPoses = reshape([displayList.Objects.Pose],6,[])';
egoRow = strcmp({displayList.Objects.Instance},'ego');
egoCenter = objectPoses(egoRow,1:3) + [0.3*4.5 0 0.75];
% (without MeshSet: a typical car, 4.5 x 1.8 x 1.5 m, its box center 0.3
% of its length ahead of the origin)
assert(abs(displayList.Objects(egoRow).ScreenSize - norm([4.5 1.8 1.5])*450/(2*tand(20))/norm(egoCenter - camera.Position)) < 1e-6);
% A camera twice as many pixels across sees everything twice as large
cameraBig = camera;
cameraBig.Pixels = 900;
[displayListBig, ~] = fcn_AnimateCar3D_selectObjects(catalog, 5, criteria, Camera=cameraBig);
assert(abs(displayListBig.Objects(strcmp({displayListBig.Objects.Instance},'ego')).ScreenSize ...
    - 2*displayList.Objects(egoRow).ScreenSize) < 1e-9);

% Turning the camera around shows a different set
cameraBack = struct('Position',[65 0 8], 'Target',[20 0 0], 'ViewAngle',40, 'AspectRatio',16/9);
[displayListBack, ~] = fcn_AnimateCar3D_selectObjects(catalog, 5, criteria, Camera=cameraBack);
backNames = [{displayListBack.Objects.Instance}, displayListBack.Boxes.Instance(:)'];
assert(~isequal(sort(allNames), sort(backNames)));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: A box that moves with time, and the camera's target as center
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='box', Center=@(t) [100*t 0], BoxSize=[60 30]);
[displayList, state] = fcn_AnimateCar3D_selectObjects(catalog, 2, criteria);
allPoses = [reshape([displayList.Objects.Pose],6,[])'; displayList.Boxes.Pose];
allNames = [{displayList.Objects.Instance}, displayList.Boxes.Instance(:)'];
flagNotAlways = ~startsWith(allNames,'conf') & ~strcmp(allNames,'ego');
assert(all(abs(allPoses(flagNotAlways,1)-200) <= 30*1.1 + 3));
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Center='camera', Radius=40);
[~, state] = fcn_AnimateCar3D_selectObjects(catalog, 2, criteria, Camera=camera);
assert(state.Stats.NumNear + state.Stats.NumMiddle + state.Stats.NumFar > 0);

%% TEST case: Detail levels from the mesh set, and their hysteresis
figNum = 20003;
titleString = sprintf('TEST case: Detail levels from the mesh set, and their hysteresis');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

meshSet = fcn_AnimateCar3D_loadMeshes({'sample','box'}, FigNum=-1);
sampleLevels = meshSet.sample.Levels;
maxSizes = [sampleLevels.MaxScreenSize];
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Radius=100);
[displayList, ~] = fcn_AnimateCar3D_selectObjects(catalog, 5, criteria, MeshSet=meshSet);
% Each middle and far car has the coarsest level made for its size (with
% no previous state); near objects have level 0; merged ones at least 1
flagMiddle = strcmp({displayList.Objects.Tier},'middle');
middleLevels = [displayList.Objects(flagMiddle).Level];
middleSizes = [displayList.Objects(flagMiddle).ScreenSize];
for ith_object = 1:numel(middleLevels)
    expectedLevel = find(maxSizes >= middleSizes(ith_object), 1, 'last');
    if isempty(expectedLevel)
        expectedLevel = 0;
    end
    assert(middleLevels(ith_object)==expectedLevel);
end
assert(all([displayList.Objects(strcmp({displayList.Objects.Tier},'near')).Level]==0));
flagFarCar = startsWith(displayList.Boxes.Instance,'car');
assert(all(displayList.Boxes.Level(flagFarCar) >= 1));

% Past the middle count, large far cars are capped at the level made for
% MergeBelowSize (37 px)
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Radius=100, MiddleCount=0);
[displayList, ~] = fcn_AnimateCar3D_selectObjects(catalog, 5, criteria, MeshSet=meshSet);
mergeLevel = find(maxSizes >= criteria.MergeBelowSize, 1, 'last');
flagFarCar = startsWith(displayList.Boxes.Instance,'car');
farSizes = displayList.Boxes.ScreenSize(flagFarCar);
farLevels = displayList.Boxes.Level(flagFarCar);
assert(any(farSizes >= criteria.MergeBelowSize));                     % some are large
assert(all(farLevels(farSizes >= criteria.MergeBelowSize) == mergeLevel));
assert(all(farLevels >= mergeLevel | farSizes < criteria.MergeBelowSize));

% A car pulling away: its level is never coarser than its size needs, and
% hysteresis keeps a finer level a little longer at least once
pullTime = (0:0.5:120)';
pullMotion = struct('Instance','leaver', 'Time',pullTime, 'Pose',[20+pullTime, zeros(size(pullTime)), zeros(size(pullTime))]);
pullCatalog = fcn_AnimateCar3D_buildCatalog(fcn_AnimateCar3D_loadSceneList(struct('instance','leaver','meshID','sample')), Motions=pullMotion);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Center=[0 0], Radius=200, MaxDistance=200);
state = [];
flagKeptLonger = false;
for ith_step = 1:numel(pullTime)
    [displayList, state] = fcn_AnimateCar3D_selectObjects(pullCatalog, pullTime(ith_step), criteria, SelectorState=state, MeshSet=meshSet);
    if isempty(displayList.Objects) && isempty(displayList.Boxes.Instance)
        continue;
    end
    if ~isempty(displayList.Objects)
        thisLevel = displayList.Objects.Level;
        thisSize = displayList.Objects.ScreenSize;
    else
        thisLevel = displayList.Boxes.Level;
        thisSize = displayList.Boxes.ScreenSize;
    end
    ruleLevel = find(maxSizes >= thisSize, 1, 'last');
    if isempty(ruleLevel)
        ruleLevel = 0;
    end
    assert(thisLevel <= max(ruleLevel, 1));             % never coarser than its size needs
    flagKeptLonger = flagKeptLonger || thisLevel < ruleLevel;
end
assert(flagKeptLonger);

%% TEST case: Static boxes are always far, and only nearby ones are drawn
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Radius=100);
[displayList, ~] = fcn_AnimateCar3D_selectObjects(catalog, 5, criteria);
assert(ismember('static1', displayList.Boxes.Instance) && ~ismember('static2', displayList.Boxes.Instance));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle');
[displayList, ~] = fcn_AnimateCar3D_selectObjects(catalog, 1, criteria, FigNum=[]);
assert(~isempty(displayList.Objects));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
[displayList, ~] = fcn_AnimateCar3D_selectObjects(catalog, 1, criteria, FigNum=-1);
assert(~isempty(displayList.Objects));

%% Speed: 200 cars, 40 steps
timer = tic;
state = [];
for ith_step = 1:40
    [~, state] = fcn_AnimateCar3D_selectObjects(catalog, ith_step*0.25, criteria, SelectorState=state, FigNum=-1);
end
fprintf(1,'   Selection of 200 cars: %.1f ms per step\n', 1000*toc(timer)/40);

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

%% FAIL case: Center='camera' without a camera
if 1==0
    fcn_AnimateCar3D_selectObjects(catalog, 1, fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Center='camera'));
end

%% Functions follow
%% fcn_INTERNAL_addFields
function rows = fcn_INTERNAL_addFields(rows, meshID)
% Give scene list rows the same fields, so they can be joined
if nargin>1
    [rows.meshID] = deal(meshID);
end
for fieldName = {'instance','role','meshID','branchOf','branchID'}
    if ~isfield(rows, fieldName{1})
        if strcmp(fieldName{1},'branchID')
            [rows.(fieldName{1})] = deal(0);
        else
            [rows.(fieldName{1})] = deal('');
        end
    end
end
rows = orderfields(rows, {'instance','role','meshID','branchOf','branchID'});
end % Ends fcn_INTERNAL_addFields
