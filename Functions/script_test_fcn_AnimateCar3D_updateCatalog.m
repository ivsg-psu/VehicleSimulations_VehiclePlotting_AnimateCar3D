% script_test_fcn_AnimateCar3D_updateCatalog.m
% Tests fcn_AnimateCar3D_updateCatalog
% Adds, replaces, and removes objects in a catalog while it is in use.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_updateCatalog
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_updateCatalog
%   % * (fill in items here)


%% Set up the workspace
close all

% A small scene: an ego vehicle, two traffic cars, and a confederate with
% two branches, all as motions in memory
egoTime = (0:0.1:8)';
egoMotion = struct('Instance','ego', 'Time',egoTime, 'Pose',[10*egoTime, zeros(size(egoTime)), zeros(size(egoTime))]);
carTime = (0:0.5:8)';
car1Motion = struct('Instance','car1', 'Time',carTime, 'Pose',[150-12*carTime, -3.5*ones(size(carTime)), pi*ones(size(carTime))]);
car2Motion = struct('Instance','car2', 'Time',carTime+2, 'Pose',[20+8*carTime, 3.5*ones(size(carTime)), zeros(size(carTime))]);
branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=2, SplitTime=3, Duration=8, StartPose=[30 7 0], ...
    ParentName='conf1', FigNum=-1);
branchList = [branchMotions.Parent; branchMotions.Branches];
motions = [egoMotion; car1Motion; car2Motion];
for ith_motion = 1:numel(branchList)
    motions(end+1,1) = struct('Instance',branchList(ith_motion).Instance, 'Time',branchList(ith_motion).Time, ...
        'Pose',branchList(ith_motion).Pose); %#ok<SAGROW>
end
sceneRows = struct('instance', {'ego','car1','car2','conf1','conf1_branch1','conf1_branch2'}, ...
    'role', {'ego','traffic','traffic','confederate','confederate','confederate'}, ...
    'branchOf', {'','','','','conf1','conf1'}, 'branchID', {0,0,0,0,1,2});
sceneList = fcn_AnimateCar3D_loadSceneList(sceneRows);

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

%% DEMO case: Build a catalog up from nothing, one update at a time
figNum = 10001;
titleString = sprintf('DEMO case: Build a catalog up from nothing, one update at a time');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

catalog = fcn_AnimateCar3D_updateCatalog([], Add=sceneList(1:3), Motions=motions);
[catalog, updateInfo] = fcn_AnimateCar3D_updateCatalog(catalog, Add=sceneList(4:6), Motions=motions, FigNum=figNum);

% Check variable types
assert(isstruct(catalog) && isstruct(updateInfo));
assert(isa(catalog.Grid,'containers.Map'));

% Check variable sizes
assert(numel(catalog.Objects)==6);
assert(numel(updateInfo.Added)==3 && isempty(updateInfo.Replaced) && isempty(updateInfo.Removed));

% Check variable values: the same objects and grid as building at once
fullCatalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions);
assert(isequal(sort(cell2mat(catalog.Grid.keys)), sort(cell2mat(fullCatalog.Grid.keys))));
gridKeys = fullCatalog.Grid.keys;
for ith_key = 1:numel(gridKeys)
    assert(isequal(sort(catalog.Grid(gridKeys{ith_key})), sort(fullCatalog.Grid(gridKeys{ith_key}))));
end
conf1 = catalog.Objects(strcmp({catalog.Objects.Instance},'conf1'));
assert(conf1.HasBranches && abs(conf1.BranchStart - 3) < 1e-9);

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

%% TEST case: Motions as a cell array, each with only its own fields
% The branches as fcn_AnimateCar3D_fillBranchMotions makes them (with its
% extra fields), and an ego with wheel spin: the same catalog as from the
% structure array
egoFull = egoMotion;
egoFull.WheelSpin = repmat(10*egoTime/0.3, 1, 4);
motionCell = [{egoFull, car1Motion, car2Motion}, num2cell(branchList(:)')];
cellCatalog = fcn_AnimateCar3D_updateCatalog([], Add=sceneList, Motions=motionCell);
arrayCatalog = fcn_AnimateCar3D_updateCatalog([], Add=sceneList, Motions=motions);
assert(isequaln(cellCatalog.Objects, arrayCatalog.Objects));
egoIndex = cellCatalog.Objects(strcmp({cellCatalog.Objects.Instance},'ego')).MotionIndex;
assert(isequal(cellCatalog.Motions(egoIndex).WheelSpin, egoFull.WheelSpin));
% A misspelled field is an error here too
errorID = '';
try
    fcn_AnimateCar3D_updateCatalog(cellCatalog, Add=sceneList(2), Motions={setfield(car1Motion,'bodyroll',zeros(size(carTime)))});
catch ME
    errorID = ME.identifier;
    errorText = ME.message;
end
assert(strcmp(errorID,'AnimateCar3D:motionField') && contains(errorText,'did you mean BodyRoll'));

%% TEST case: A grown motion replaces the object; the selector sees the new part
figNum = 20001;
titleString = sprintf('TEST case: A grown motion replaces the object; the selector sees the new part');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

shortCar = car1Motion;
shortCar.Time = shortCar.Time(1:5);
shortCar.Pose = shortCar.Pose(1:5,:);
catalog = fcn_AnimateCar3D_updateCatalog([], Add=sceneList(1:2), Motions=[egoMotion; shortCar]);
car1 = catalog.Objects(2);
assert(car1.EndTime==2);
[catalog, updateInfo] = fcn_AnimateCar3D_updateCatalog(catalog, Add=sceneList(2), Motions=car1Motion);
assert(isequal(updateInfo.Replaced, {'car1'}) && numel(catalog.Objects)==2);
assert(catalog.Objects(2).EndTime==8 && catalog.TimeEnd==8);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Radius=500);
displayList = fcn_AnimateCar3D_selectObjects(catalog, 6, criteria);
assert(ismember('car1', [{displayList.Objects.Instance}, displayList.Boxes.Instance(:)']));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Removing objects, then adding one back
figNum = 20002;
titleString = sprintf('TEST case: Removing objects, then adding one back');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(Region='circle', Radius=500);
[~, selectorState] = fcn_AnimateCar3D_selectObjects(catalog, 4, criteria);
[catalog, updateInfo, selectorState] = fcn_AnimateCar3D_updateCatalog(catalog, ...
    Remove={'car2','conf1_branch1','conf1_branch2','notThere'}, SelectorState=selectorState);
assert(numel(updateInfo.Removed)==3);
assert(numel(catalog.Objects)==6);              % slots stay
conf1 = catalog.Objects(strcmp({catalog.Objects.Instance},'conf1'));
assert(~conf1.HasBranches && isinf(conf1.BranchStart));   % no branches left
displayList = fcn_AnimateCar3D_selectObjects(catalog, 4, criteria, SelectorState=selectorState);
shownNames = [{displayList.Objects.Instance}, displayList.Boxes.Instance(:)'];
assert(~any(ismember({'car2','conf1_branch1'}, shownNames)));
displayList = fcn_AnimateCar3D_selectObjects(catalog, 2, criteria);
assert(ismember('conf1', [{displayList.Objects.Instance}, displayList.Boxes.Instance(:)']));  % before its split
for ith_key = catalog.Grid.keys
    assert(~any(catalog.Grid(ith_key{1})==3));  % car2 is in no grid cell
end
[catalog, updateInfo] = fcn_AnimateCar3D_updateCatalog(catalog, Add=sceneList(3), Motions=motions);
assert(isequal(updateInfo.Added, {'car2'}) && numel(catalog.Objects)==6);
assert(strcmp(catalog.Objects(3).Instance,'car2') && catalog.Objects(3).EndTime==10);

%% TEST case: A changed scene row, with no motion, keeps the motion
figNum = 20003;
titleString = sprintf('TEST case: A changed scene row, with no motion, keeps the motion');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions);
redRow = sceneList(2);
redRow.Color = [1 0 0];
redRow.MeshID = 'box';
[catalog, updateInfo] = fcn_AnimateCar3D_updateCatalog(catalog, Add=redRow);
assert(isequal(updateInfo.Replaced, {'car1'}) && updateInfo.NumGridChanges==0);
assert(isequal(catalog.Objects(2).Color, [1 0 0]) && strcmp(catalog.Objects(2).MeshID,'box'));
assert(catalog.Objects(2).EndTime==8);

%% TEST case: A motion file that grows (read from its file each time)
figNum = 20004;
titleString = sprintf('TEST case: A motion file that grows (read from its file each time)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

growFile = [tempname '.csv'];
writetable(table((0:0.5:2)', 10*(0:0.5:2)', zeros(5,1), zeros(5,1), 'VariableNames',{'time','X','Y','yaw'}), growFile);
growRow = fcn_AnimateCar3D_loadSceneList(struct('instance','grower','motionFile',growFile));
[catalog, ~, selectorState] = fcn_AnimateCar3D_updateCatalog([], Add=growRow, SelectorState=[]);
assert(catalog.Objects(1).EndTime==2 && catalog.Objects(1).MotionIndex==0);
writetable(table((0:0.5:5)', 10*(0:0.5:5)', zeros(11,1), zeros(11,1), 'VariableNames',{'time','X','Y','yaw'}), growFile);
catalog = fcn_AnimateCar3D_updateCatalog(catalog, Add=growRow, SelectorState=selectorState);
assert(catalog.Objects(1).EndTime==5);
delete(growFile);

%% TEST case: 200 cars grow by one second each: the update is quick
Nvehicles = 200;
manyRows = fcn_AnimateCar3D_loadSceneList(struct('instance', cellstr(compose('v%d', 1:Nvehicles)), 'meshID', 'box'));
catalog = fcn_AnimateCar3D_updateCatalog([], Add=manyRows, Motions=fcn_INTERNAL_makeMotions(Nvehicles, 30));
growTimer = tic;
[catalog, updateInfo] = fcn_AnimateCar3D_updateCatalog(catalog, Add=manyRows, Motions=fcn_INTERNAL_makeMotions(Nvehicles, 31));
fprintf(1,'   200 cars grown by 1 s: updated in %.2f s, %d grid changes\n', toc(growTimer), updateInfo.NumGridChanges);
assert(numel(updateInfo.Replaced)==Nvehicles && catalog.TimeEnd==31);

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
catalog = fcn_AnimateCar3D_updateCatalog([], Add=sceneList, Motions=motions, FigNum=[]);
assert(numel(catalog.Objects)==6);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
catalog = fcn_AnimateCar3D_updateCatalog([], Add=sceneList, Motions=motions, FigNum=-1);
assert(numel(catalog.Objects)==6);

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

%% FAIL case: An added object with no motion
if 1==0
    fcn_AnimateCar3D_updateCatalog([], Add=fcn_AnimateCar3D_loadSceneList(struct('instance','lonely')));
end

%% FAIL case: Removing a static object
if 1==0
    staticCatalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions, ...
        StaticScene=fcn_AnimateCar3D_loadStaticScene(struct('x',10,'y',10)));
    fcn_AnimateCar3D_updateCatalog(staticCatalog, Remove={staticCatalog.Objects(end).Instance});
end

%% Functions follow
%% fcn_INTERNAL_makeMotions
function motions = fcn_INTERNAL_makeMotions(Nvehicles, endTime)
% Nvehicles cars on ten lanes, from time 0 to endTime
timeSteps = (0:0.1:endTime)';
motions = repmat(struct('Instance','', 'Time',timeSteps, 'Pose',[]), Nvehicles, 1);
for ith_vehicle = 1:Nvehicles
    motions(ith_vehicle).Instance = sprintf('v%d', ith_vehicle);
    motions(ith_vehicle).Pose = [mod(7*ith_vehicle,400) + 12*timeSteps, 3.6*mod(ith_vehicle,10)*ones(size(timeSteps)), zeros(size(timeSteps))];
end
end % Ends fcn_INTERNAL_makeMotions
