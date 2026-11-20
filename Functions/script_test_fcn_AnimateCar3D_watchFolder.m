% script_test_fcn_AnimateCar3D_watchFolder.m
% Tests fcn_AnimateCar3D_watchFolder
% Watches a folder of live data and reports what is new, grown, changed, or deleted.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_watchFolder
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_watchFolder
%   % * (fill in items here)


%% Set up the workspace
close all

% Three objects: an ego vehicle (from the start), a car that starts at
% 1 s, and a truck (a box) that starts at 2 s and ends at 4 s. The test
% helper fcn_AnimateCar3D_writeLiveTestFiles writes them into the folder
% as time goes on.
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
liveFolder = fullfile(tempdir, 'AnimateCar3D_testWatchFolder');
if isfolder(liveFolder)
    rmdir(liveFolder, 's');
end
mkdir(liveFolder);

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

%% DEMO case: Watch the folder while the test helper fills it
figNum = 10001;
titleString = sprintf('DEMO case: Watch the folder while the test helper fills it');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% Nothing yet
[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder);
assert(update.Checked && isempty(update.Add) && update.NumInstances==0 && isinf(update.LatestTime));

% At 1.5 s: the ego (16 rows) and the car (2 rows) exist
liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, 1.5);
[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, Force=true, FigNum=figNum);

% Check variable types
assert(isstruct(update) && isstruct(watchState));
assert(isstruct(update.Add) && isstruct(update.Motions));

% Check variable sizes
assert(numel(update.Add)==2 && numel(update.Motions)==2);

% Check variable values
assert(isequal(sort({update.Add.Instance}), {'car1','ego'}));
carRow = update.Add(strcmp({update.Add.Instance},'car1'));
assert(all(abs(carRow.Color - [0.8 0.1 0.1]) < 1e-9) && strcmp(carRow.Role,'traffic'));   % from the scene list
assert(abs(update.LatestTime - 1.5) < 1e-9 && update.NumInstances==2);
assert(ismember('sceneList.csv', update.AddedFiles));

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

%% TEST case: Grown and new files, then a deleted file
figNum = 20001;
titleString = sprintf('TEST case: Grown and new files, then a deleted file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

pause(0.05);    % so that file dates can differ
liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, 3, LiveState=liveState);
[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, Force=true);
assert(isequal(sort({update.Add.Instance}), {'car1','ego','truck1'}));
assert(isequal(update.AddedFiles, {'truck1.csv'}) && numel(update.ChangedFiles)==2);
truckRow = update.Add(strcmp({update.Add.Instance},'truck1'));
assert(strcmp(truckRow.MeshID,'box') && truckRow.Size(1)==12);
liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, 5, LiveState=liveState, DeleteAfter=0.5);
[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, Force=true);
assert(isequal(update.Remove, {'truck1'}) && isequal(update.DeletedFiles, {'truck1.csv'}));
assert(update.NumInstances==2 && abs(update.LatestTime-5) < 1e-9);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Not checked again before MinInterval; nothing changed means nothing to do
figNum = 20002;
titleString = sprintf('TEST case: Not checked again before MinInterval; nothing changed means nothing to do');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, MinInterval=60);
assert(~update.Checked && abs(update.LatestTime-5) < 1e-9);
[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, Force=true);
assert(update.Checked && isempty(update.Add) && isempty(update.Remove));

%% TEST case: A file whose last row is not complete is read later
figNum = 20003;
titleString = sprintf('TEST case: A file whose last row is not complete is read later');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

partialFile = fullfile(liveFolder, 'walker.csv');
fileID = fopen(partialFile, 'w');
fprintf(fileID, 'time,X,Y,yaw\n0,0,10,0\n0.5,0.6,10,0\n1.0,1.2');   % cut off partway
fclose(fileID);
[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, Force=true);
% (the 2 complete rows are read now; the last one later)
assert(isequal({update.Add.Instance}, {'walker'}) && numel(update.Motions.Time)==2);
assert(strcmp(update.Skipped(1).File, 'walker.csv') && contains(update.Skipped(1).Reason, 'not complete'));
fileID = fopen(partialFile, 'a');
fprintf(fileID, ',10,0\n');
fclose(fileID);
[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, Force=true);
assert(isequal({update.Add.Instance}, {'walker'}) && numel(update.Motions.Time)==3);
assert(isequal(update.AppendedFiles, {'walker.csv'}) && isempty(update.Skipped));
assert(max(abs(update.Motions.Pose(:,1) - [0; 0.6; 1.2])) < 1e-9);
assert(strcmp(update.Add.Role,'traffic') && strcmp(update.Add.MeshID,'sample'));   % not in the scene list: defaults

%% TEST case: A changed scene list changes rows without reading motions; a criteria file
figNum = 20004;
titleString = sprintf('TEST case: A changed scene list changes rows without reading motions; a criteria file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

newList = fcn_AnimateCar3D_loadSceneList(struct('instance',{'ego','car1','walker'}, 'role',{'ego','traffic','pedestrian'}, ...
    'color',{[0.05 0.2 0.6],[0.1 0.7 0.1],[]}));
writetable(struct2table(struct('instance',{'ego';'car1';'walker'}, 'role',{'ego';'traffic';'pedestrian'}, ...
    'color',{'0.05 0.2 0.6';'0.1 0.7 0.1';''})), fullfile(liveFolder,'sceneList.csv'));
writelines("MaxDistance = 150", fullfile(liveFolder,'displayCriteria.txt'));
[update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, Force=true);
assert(isempty(update.Motions) && numel(update.Add)==3);
carRow = update.Add(strcmp({update.Add.Instance},'car1'));
assert(all(abs(carRow.Color - [0.1 0.7 0.1]) < 1e-9) && isempty(carRow.MotionFile));
walkerRow = update.Add(strcmp({update.Add.Instance},'walker'));
assert(strcmp(walkerRow.Role,'pedestrian'));
assert(endsWith(update.CriteriaFile, 'displayCriteria.txt'));
assert(numel(newList)==3);

%% TEST case: Only new rows are read, and the joined motion equals reading the whole file
figNum = 20006;
titleString = sprintf('TEST case: Only new rows are read, and the joined motion equals reading the whole file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

growFolder = [tempname '_grow'];
mkdir(growFolder);
growFile = fullfile(growFolder, 'spinner.csv');
growTime = (0:0.1:20)';
growYaw = 0.4*growTime;                                % turns past pi: yaw wraps in some readers
growLines = compose('%.1f,%.4f,%.4f,%.6f', [growTime, 30*cos(growYaw), 30*sin(growYaw), growYaw]);
writelines(["time,X,Y,yaw"; string(growLines(1:100))], growFile);
[update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, Force=true);
firstBytes = update.BytesRead;
for ith_chunk = 1:4
    pause(0.02);
    writelines(string(growLines(100+(ith_chunk-1)*25+1 : 100+ith_chunk*25)), growFile, WriteMode='append');
    [update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, WatchState=growState, Force=true);
    assert(isequal(update.AppendedFiles, {'spinner.csv'}) && isempty(update.ReplacedFiles));
    assert(update.BytesRead < firstBytes/2);           % only the new rows (and one row before)
end
wholeMotion = fcn_CarMesh3D_loadMotionCSV(growFile, FigNum=-1);
assert(numel(update.Motions.Time)==numel(wholeMotion.Time) && max(abs(update.Motions.Time - wholeMotion.Time(:))) < 1e-9);
assert(max(abs(update.Motions.Pose - wholeMotion.Pose), [], 'all') < 1e-9);
assert(max(abs(update.Motions.WheelSpin - wholeMotion.WheelSpin), [], 'all') < 0.05);   % (radians; summed speeds meet at the joins)

%% TEST case: Replaced files are read again whole; deleted and re-made files; traffic files grow by object
figNum = 20007;
titleString = sprintf('TEST case: Replaced files are read again whole; deleted and re-made files; traffic files grow by object');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% A replaced motion file (shorter, other numbers): read whole
writelines(["time,X,Y,yaw"; "0,5,5,0"; "1,6,5,0"], growFile);
[update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, WatchState=growState, Force=true);
assert(isequal(update.ReplacedFiles, {'spinner.csv'}) && numel(update.Motions.Time)==2 && update.Motions.Pose(1,1)==5);
assert(isempty(update.Remove));

% The same size, but other numbers (a new date): read whole
pause(1.1);                                             % (so the date differs)
writelines(["time,X,Y,yaw"; "0,7,5,0"; "1,8,5,0"], growFile);
[update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, WatchState=growState, Force=true);
assert(isequal(update.ReplacedFiles, {'spinner.csv'}) && update.Motions.Pose(1,1)==7);

% Deleted and made again between checks: read whole, not removed
delete(growFile);
writelines(["time,X,Y,yaw"; "0,9,5,0"; "1,10,5,0"; "2,11,5,0"], growFile);
[update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, WatchState=growState, Force=true);
assert(isempty(update.Remove) && numel(update.Motions.Time)==3 && update.Motions.Pose(1,1)==9);

% A traffic file grows by object (one new row for car 2), then is
% replaced without car 1: car 1 is removed
trafficFile = fullfile(growFolder, 'road.csv');
writelines(["id,time,X,Y,yaw"; "1,0,0,0,0"; "2,0,50,4,3.1"; "1,1,10,0,0"; "2,1,40,4,3.1"], trafficFile);
[update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, WatchState=growState, Force=true);
assert(isequal(sort({update.Add.Instance}), {'road_1','road_2'}));
writelines("2,2,30,4,3.1", trafficFile, WriteMode='append');
[update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, WatchState=growState, Force=true);
assert(isequal(update.AppendedFiles, {'road.csv'}) && isequal({update.Motions.Instance}, {'road_2'}));
assert(isequal(update.Motions.Time(:)', [0 1 2]) && update.Motions.Pose(3,1)==30);
writelines(["id,time,X,Y,yaw"; "2,0,50,4,3.1"; "2,1,40,4,3.1"; "2,2,30,4,3.1"; "2,3,20,4,3.1"], trafficFile);
[update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, WatchState=growState, Force=true);
assert(isequal(update.ReplacedFiles, {'road.csv'}) && isequal(update.Remove, {'road_1'}) && update.NumInstances==2);

% A deleted file removes its object
delete(trafficFile);
[update, growState] = fcn_AnimateCar3D_watchFolder(growFolder, WatchState=growState, Force=true);
assert(isequal(update.Remove, {'road_2'}) && update.NumInstances==1 && ~isKey(growState.Motions, 'road_2'));
rmdir(growFolder, 's');

%% TEST case: The watcher and updateCatalog together give the same catalog as building it at once
figNum = 20005;
titleString = sprintf('TEST case: The watcher and updateCatalog together give the same catalog as building it at once');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

rmdir(liveFolder, 's');
mkdir(liveFolder);
liveState = [];
watchState = [];
catalog = [];
for sceneTime = 0:0.5:6
    liveState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, sceneTime, LiveState=liveState);
    [update, watchState] = fcn_AnimateCar3D_watchFolder(liveFolder, WatchState=watchState, Force=true);
    catalog = fcn_AnimateCar3D_updateCatalog(catalog, Add=update.Add, Motions=update.Motions, Remove=update.Remove);
end
fullCatalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions);
for ith_object = 1:numel(fullCatalog.Objects)
    liveObject = catalog.Objects(strcmp({catalog.Objects.Instance}, fullCatalog.Objects(ith_object).Instance));
    assert(abs(liveObject.StartTime - fullCatalog.Objects(ith_object).StartTime) < 1e-6);
    assert(abs(liveObject.EndTime - fullCatalog.Objects(ith_object).EndTime) < 1e-6);
    assert(max(abs(liveObject.ThinPose(:,1) - fullCatalog.Objects(ith_object).ThinPose(:,1))) < 1e-3);
end
rmdir(liveFolder, 's');

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
mkdir(liveFolder);
fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, sceneList, motions, 3);   % the truck needs 2 rows
update = fcn_AnimateCar3D_watchFolder(liveFolder, FigNum=[]);
assert(numel(update.Add)==3);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
update = fcn_AnimateCar3D_watchFolder(liveFolder, FigNum=-1);
assert(numel(update.Add)==3);
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

%% FAIL case: A folder that does not exist
if 1==0
    fcn_AnimateCar3D_watchFolder(fullfile(tempdir,'noSuchFolder_AnimateCar3D'));
end
