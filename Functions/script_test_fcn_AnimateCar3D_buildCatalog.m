% script_test_fcn_AnimateCar3D_buildCatalog.m
% Tests fcn_AnimateCar3D_buildCatalog
% Builds the object catalog: what exists, when, and where.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_buildCatalog
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_buildCatalog
%   % * (fill in items here)


%% Set up the workspace
close all

% A small scene: an ego vehicle, a confederate that splits into three
% branches, two traffic cars (one from a motion file), and static boxes
branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=3, SplitTime=2, Duration=6, StartPose=[0 3.5 0], ...
    ParentName='conf1', FigNum=-1);
egoTime = (0:0.1:6)';
egoMotion = struct('Instance','ego', 'Time',egoTime, 'Pose',[10*egoTime, zeros(size(egoTime)), zeros(size(egoTime))]);
carTime = (0:0.5:6)';
carMotion = struct('Instance','car1', 'Time',carTime, 'Pose',[200-12*carTime, -3.5*ones(size(carTime)), pi*ones(size(carTime))]);
car2File = [tempname '.csv'];
car2Table = table((0:0.5:4)', 300+(0:0.5:4)'*15, 7*ones(9,1), zeros(9,1), 'VariableNames', {'time','X','Y','yaw'});
writetable(car2Table, car2File);
sceneRows = struct('instance', {'ego','conf1','conf1_branch1','conf1_branch2','conf1_branch3','car1','car2'}, ...
    'role', {'ego','confederate','confederate','confederate','confederate','traffic','traffic'}, ...
    'branchOf', {'','','conf1','conf1','conf1','',''}, 'branchID', {0,0,1,2,3,0,0}, ...
    'motionFile', {'','','','','','',car2File}, 'timeOffset', {0,0,0,0,0,0,1});
sceneList = fcn_AnimateCar3D_loadSceneList(sceneRows);
% (As a structure array, every motion needs the same fields; see the
% cell array test below for motions with different fields)
motions = [egoMotion; carMotion];
branchList = [branchMotions.Parent; branchMotions.Branches];
for ith_motion = 1:numel(branchList)
    motions(end+1,1) = struct('Instance',branchList(ith_motion).Instance, 'Time',branchList(ith_motion).Time, ...
        'Pose',branchList(ith_motion).Pose); %#ok<SAGROW>
end
staticScene = fcn_AnimateCar3D_loadStaticScene(struct('x',{30,60,400},'y',{20,-20,0}));

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

%% DEMO case: The catalog of a small scene
figNum = 10001;
titleString = sprintf('DEMO case: The catalog of a small scene');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions, StaticScene=staticScene, FigNum=figNum);

% Check variable types
assert(isstruct(catalog) && isstruct(catalog.Objects));
assert(isa(catalog.Grid,'containers.Map') && isa(catalog.StaticGrid,'containers.Map'));

% Check variable sizes
assert(numel(catalog.Objects)==10);   % 7 moving + 3 static
assert(size(catalog.Objects(1).ThinPose,2)==6);

% Check variable values
objectNames = {catalog.Objects.Instance};
conf1 = catalog.Objects(strcmp(objectNames,'conf1'));
assert(conf1.HasBranches && abs(conf1.BranchStart - 2) < 1e-9);
branch2 = catalog.Objects(strcmp(objectNames,'conf1_branch2'));
assert(abs(branch2.SplitTime - 2) < 1e-9 && branch2.MotionIndex>0);
car2 = catalog.Objects(strcmp(objectNames,'car2'));
assert(abs(car2.StartTime - 1) < 1e-9 && abs(car2.EndTime - 5) < 1e-9);   % time offset applied
assert(car2.MotionIndex==0);    % read from its file; not kept (a traffic role)
ego = catalog.Objects(strcmp(objectNames,'ego'));
assert(ego.MotionIndex>0);      % kept: the ego role
assert(abs(ego.ThinTime(2) - ego.ThinTime(1) - 0.5) < 1e-9);
assert(sum([catalog.Objects.IsStatic])==3);
assert(catalog.TimeStart==0 && catalog.TimeEnd==6);

% The grid: in window 0 (0 to 1 s), the ego (x from 0 to 10) is in cell
% (0, 0); car2 does not exist yet
cellKey = 0*1e10 + (0+5e4)*1e5 + (0+5e4);
assert(isKey(catalog.Grid, cellKey));
idsThere = catalog.Grid(cellKey);
assert(ismember(find(strcmp(objectNames,'ego')), idsThere));
assert(~ismember(find(strcmp(objectNames,'car2')), idsThere));

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
figNum = 20002;
titleString = sprintf('TEST case: Motions as a cell array, each with only its own fields');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% The ego with wheel spin and steering; car1 with poses only; the
% branches as fcn_AnimateCar3D_fillBranchMotions makes them (with its
% own extra fields, BranchOf and Curvature); car2 from its motion file,
% with an Instance added (and the file reader's extra fields)
egoFull = egoMotion;
egoFull.WheelSpin = repmat(10*egoTime/0.3, 1, 4);
egoFull.SteerAngle = zeros(numel(egoTime), 2);
car2Motion = fcn_CarMesh3D_loadMotionCSV(car2File, FigNum=-1);
car2Motion.Instance = 'car2';
motionCell = [{egoFull, carMotion, car2Motion}, num2cell(branchList(:)')];
catalogCell = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motionCell, StaticScene=staticScene);
catalogArray = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions, StaticScene=staticScene);

% The same objects as from the structure array (car2 is now kept in
% memory: it was given there), with each motion's own fields
objectNames = {catalogCell.Objects.Instance};
flagOthers = ~strcmp(objectNames,'car2');
cellObjects = rmfield(catalogCell.Objects(flagOthers), 'MotionIndex');
arrayObjects = rmfield(catalogArray.Objects(flagOthers), 'MotionIndex');
assert(isequaln(cellObjects, arrayObjects));
egoIndex = catalogCell.Objects(strcmp(objectNames,'ego')).MotionIndex;
assert(isequal(catalogCell.Motions(egoIndex).WheelSpin, egoFull.WheelSpin));
assert(isequal(size(catalogCell.Motions(egoIndex).Pose), [numel(egoTime) 6]));    % made K x 6
car1Index = catalogCell.Objects(strcmp(objectNames,'car1')).MotionIndex;
assert(isempty(catalogCell.Motions(car1Index).WheelSpin));
car2Object = catalogCell.Objects(strcmp(objectNames,'car2'));
assert(car2Object.MotionIndex>0 && abs(car2Object.StartTime - 1) < 1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: The motion template, from a call with no inputs
figNum = 20003;
titleString = sprintf('TEST case: The motion template, from a call with no inputs');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

motionTemplate = fcn_AnimateCar3D_buildCatalog();
assert(isequal(fieldnames(motionTemplate)', {'Instance','Time','Pose','WheelSpin','SteerAngle','WheelLift', ...
    'BodyRoll','BodyPitch','BodyHeave','LightStates'}));
assert(motionTemplate.Instance.Required && motionTemplate.Time.Required && motionTemplate.Pose.Required);
assert(~motionTemplate.WheelSpin.Required && motionTemplate.WheelSpin.Columns==4);
assert(isequal(motionTemplate.Pose.Columns, [3 6]) && strcmp(motionTemplate.LightStates.Class,'struct'));
assert(all(structfun(@(f) all(isfield(f,{'Required','Columns','Class','Units','Description'})), motionTemplate)));
printedText = evalc('fcn_AnimateCar3D_buildCatalog()');      % no output: printed
assert(contains(printedText,'Motion template') && contains(printedText,'SteerAngle') && contains(printedText,'K x 4'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: A misspelled field, a field of the wrong size, and a missing Pose are errors
figNum = 20004;
titleString = sprintf('TEST case: A misspelled field, a field of the wrong size, and a missing Pose are errors');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

goodOthers = [{egoMotion}, num2cell(branchList(:)')];
badMotions = {setfield(carMotion, 'Wheelspin', zeros(numel(carTime),4)), ...    % misspelled
    setfield(carMotion, 'wheel_spin', zeros(numel(carTime),4)), ...             % misspelled
    setfield(carMotion, 'WheelSpin', zeros(numel(carTime),3)), ...              % 3 columns, not 4
    setfield(carMotion, 'BodyRoll', zeros(numel(carTime)-1,1)), ...             % one row short
    rmfield(carMotion, 'Pose')};                                                % no Pose
expectedIDs = {'AnimateCar3D:motionField','AnimateCar3D:motionField','AnimateCar3D:motionSize', ...
    'AnimateCar3D:motionSize','AnimateCar3D:motionField'};
expectedTexts = {'did you mean WheelSpin','did you mean WheelSpin', sprintf('expected %d x 4', numel(carTime)), ...
    sprintf('expected %d x 1', numel(carTime)), 'no Pose'};
for ith_bad = 1:numel(badMotions)
    errorID = '';
    try
        fcn_AnimateCar3D_buildCatalog(sceneList, Motions=[goodOthers, badMotions(ith_bad)], StaticScene=staticScene);
    catch ME
        errorID = ME.identifier;
        errorText = ME.message;
    end
    assert(strcmp(errorID, expectedIDs{ith_bad}));
    assert(contains(errorText, expectedTexts{ith_bad}) && contains(errorText, 'car1'));   % names the object
end
% An entry that is not a structure, and a motion with no Instance
errorID = '';
try
    fcn_AnimateCar3D_buildCatalog(sceneList, Motions={egoMotion, 5});
catch ME
    errorID = ME.identifier;
end
assert(strcmp(errorID, 'AnimateCar3D:motionList'));
errorID = '';
try
    fcn_AnimateCar3D_buildCatalog(sceneList, Motions={rmfield(egoMotion,'Instance')});
catch ME
    errorID = ME.identifier;
end
assert(strcmp(errorID, 'AnimateCar3D:motionField'));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: The cache is used when nothing changed, and rebuilt when something did
figNum = 20001;
titleString = sprintf('TEST case: The cache is used when nothing changed, and rebuilt when something did');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

cacheFile = [tempname '.mat'];
catalog1 = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions, StaticScene=staticScene, CacheFile=cacheFile);
assert(~catalog1.FromCache && isfile(cacheFile));
catalog2 = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions, StaticScene=staticScene, CacheFile=cacheFile);
assert(catalog2.FromCache);
assert(isequal(catalog2.Grid.keys, catalog1.Grid.keys));
changedMotions = motions;
changedMotions(1).Pose(end,1) = changedMotions(1).Pose(end,1) + 1;
catalog3 = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=changedMotions, StaticScene=staticScene, CacheFile=cacheFile);
assert(~catalog3.FromCache);
changedList = sceneList;
changedList(2).Color = [1 0 0];          % a color change also rebuilds
catalog4 = fcn_AnimateCar3D_buildCatalog(changedList, Motions=motions, StaticScene=staticScene, CacheFile=cacheFile);
assert(~catalog4.FromCache && isequal(catalog4.Objects(2).Color, [1 0 0]));
delete(cacheFile);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Many vehicles (500, over 60 s) build quickly
Nvehicles = 500;
manyTime = (0:0.1:60)';
manyRows = struct('instance', cellstr(compose('v%d', 1:Nvehicles)), 'meshID', 'box');
manyMotions = repmat(struct('Instance','', 'Time',manyTime, 'Pose',[]), Nvehicles, 1);
for ith_vehicle = 1:Nvehicles
    manyMotions(ith_vehicle).Instance = sprintf('v%d', ith_vehicle);
    manyMotions(ith_vehicle).Pose = [mod(7*ith_vehicle,400) + 12*manyTime, 3.6*mod(ith_vehicle,10)*ones(size(manyTime)), zeros(size(manyTime))];
end
buildTimer = tic;
manyCatalog = fcn_AnimateCar3D_buildCatalog(fcn_AnimateCar3D_loadSceneList(manyRows), Motions=manyMotions);
fprintf(1,'   500 vehicles over 60 s: catalog built in %.1f s, %d grid entries\n', toc(buildTimer), manyCatalog.Grid.Count);
assert(numel(manyCatalog.Objects)==Nvehicles);

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions, FigNum=[]);
assert(numel(catalog.Objects)==7);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions, FigNum=-1);
assert(numel(catalog.Objects)==7);
delete(car2File);

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

%% FAIL case: An object with no motion
if 1==0
    fcn_AnimateCar3D_buildCatalog(fcn_AnimateCar3D_loadSceneList(struct('instance','lonely')));
end
