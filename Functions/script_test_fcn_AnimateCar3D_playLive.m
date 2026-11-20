% script_test_fcn_AnimateCar3D_playLive.m
% Tests fcn_AnimateCar3D_playLive
% Plays live data from a watched folder: the whole live loop in one call.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_playLive
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_playLive
%   % * (fill in items here)


%% Set up the workspace
close all

% A small live scene: the ego at 12 m/s and two cars, written into a
% temporary folder by the test helper as time goes on
meshSet = fcn_AnimateCar3D_loadMeshes('sample', FigNum=-1);
liveTime = (0:0.1:6)';
egoMotion = struct('Instance','ego', 'Time',liveTime, 'Pose',[12*liveTime, -1.8*ones(size(liveTime)), zeros(size(liveTime))]);
car1Motion = struct('Instance','car1', 'Time',liveTime, 'Pose',[60-10*liveTime, 1.8*ones(size(liveTime)), pi*ones(size(liveTime))]);
car2Motion = struct('Instance','car2', 'Time',liveTime(1:41), 'Pose',[20+15*liveTime(1:41), -5.4*ones(41,1), zeros(41,1)]);
liveRows = struct('instance',{'ego','car1','car2'}, 'role',{'ego','traffic','traffic'}, 'meshID','sample', ...
    'timeOffset',{0, 0, 1});
liveList = fcn_AnimateCar3D_loadSceneList(liveRows);
liveMotions = [egoMotion; car1Motion; car2Motion];
newFolder = @() fcn_INTERNAL_newFolder();

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

%% DEMO case: One step per call, with the data written in the same loop
figNum = 10001;
titleString = sprintf('DEMO case: One step per call, with the data written in the same loop');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveFolder = newFolder();
writerState = [];
liveState = [];
for writerTime = 0:0.1:5
    writerState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, writerTime, LiveState=writerState);
    liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=liveState, Steps=1, ForceCheck=true, ...
        ShowTime=writerTime-1, FigNum=figNum);
end

% Check variable types
assert(isstruct(liveState) && islogical(liveState.Done) && isstruct(liveState.Catalog));

% Check variable sizes
assert(isscalar(liveState.ShowTime) && isscalar(liveState.LatestTime));

% Check variable values: the last step showed 4 s, with all three
% objects (car2 started at 1 s); every step checked the folder; the
% camera follows the ego ('kite': behind and above it)
assert(abs(liveState.ShowTime - 4) < 1e-9 && abs(liveState.LatestTime - 5) < 1e-9);
assert(liveState.Stats.Steps==51 && liveState.Stats.Checks==51 && liveState.Stats.StepsDrawn==41);
assert(all(ismember({'ego','car1','car2'}, {liveState.Catalog.Objects.Instance})));
assert(liveState.Stats.NumObjects==3 && liveState.Stats.NumNear + liveState.Stats.NumMiddle + liveState.Stats.NumFar >= 2);
cameraPosition = campos(liveState.Axes);
assert(cameraPosition(1) < 48 && cameraPosition(3) > 5);           % behind the ego (at x = 48) and above it
caption = findall(liveState.Figure, 'Tag', 'AnimateCar3D live caption');
assert(numel(caption)==1 && contains(caption.String{1}, 'showing t = 4.0 s'));
assert(~liveState.Done);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));
rmdir(liveFolder, 's');

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

%% TEST case: Run until done: plays to the end, then stops with no new data
figNum = 20001;
titleString = sprintf('TEST case: Run until done: plays to the end, then stops with no new data');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% All the data is already there; play it 10 times faster than real time
liveFolder = newFolder();
fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, 6);
runTimer = tic;
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, PlaybackSpeed=10, StopAfter=0.5, MaxSeconds=30, FigNum=figNum);
assert(liveState.Done && contains(liveState.DoneReason, 'no new data') && toc(runTimer) < 30);
% (It starts DisplayDelay behind the newest data, 5 s, and has caught up)
assert(abs(liveState.ShowTime - 5) < 1e-9 && liveState.Stats.StepsDrawn >= 1);
rmdir(liveFolder, 's');

%% TEST case: Data written while it runs: the shown time follows the data
figNum = 20002;
titleString = sprintf('TEST case: Data written while it runs: the shown time follows the data');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveFolder = newFolder();
writerState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, 2);
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, Steps=1, FigNum=figNum);
assert(abs(liveState.ShowTime - 1) < 1e-9);                       % 1 s behind the newest data (2 s)
pause(0.3);
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=liveState, Steps=1);
assert(abs(liveState.ShowTime - 1) < 1e-9);                       % no newer data: it waits there
fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, 4, LiveState=writerState);
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=liveState, Steps=1, ForceCheck=true);
assert(liveState.ShowTime > 1 && liveState.ShowTime < 1.5);       % moves on with the clock, not a jump to 3 s
rmdir(liveFolder, 's');

%% TEST case: A criteria file in the folder changes the criteria
figNum = 20003;
titleString = sprintf('TEST case: A criteria file in the folder changes the criteria');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveFolder = newFolder();
fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, 3);
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, Steps=1, FigNum=figNum);
assert(liveState.Criteria.MaxDistance==500);
writelines(["% Look less far"; "MaxDistance = 40"], fullfile(liveFolder,'displayCriteria.txt'));
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=liveState, Steps=1, ForceCheck=true);
assert(liveState.Criteria.MaxDistance==40 && liveState.Stats.CriteriaChanges==1);
rmdir(liveFolder, 's');

%% TEST case: A GIF, a caption with extra text, and a closed figure
figNum = 20004;
titleString = sprintf('TEST case: A GIF, a caption with extra text, and a closed figure');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveFolder = newFolder();
gifFile = [tempname '.gif'];
writerState = [];
liveState = [];
for writerTime = 1:0.5:3
    writerState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, writerTime, LiveState=writerState);
    liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=liveState, Steps=1, ForceCheck=true, ...
        ShowTime=writerTime-1, GifFile=gifFile, Caption='a test run', FigNum=figNum);
end
gifInfo = imfinfo(gifFile);
assert(numel(gifInfo)==5 && liveState.GifFrames==5);
caption = findall(liveState.Figure, 'Tag', 'AnimateCar3D live caption');
assert(any(strcmp(caption.String, 'a test run')));
close(figNum);
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=liveState, Steps=1);
assert(liveState.Done && contains(liveState.DoneReason, 'closed'));
delete(gifFile);
rmdir(liveFolder, 's');

%% TEST case: Kept open with no data (StopAfter=Inf), and not redrawn while idle
figNum = 20006;
titleString = sprintf('TEST case: Kept open with no data (StopAfter=Inf), and not redrawn while idle');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveFolder = newFolder();
fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, 3);
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, StopAfter=Inf, MaxSeconds=1.5, FigNum=figNum);
assert(liveState.Done && contains(liveState.DoneReason, 'MaxSeconds'));
% (Caught up after its first step, it drew once, then waited)
assert(liveState.Stats.StepsDrawn==1 && liveState.Stats.Steps > 1);
rmdir(liveFolder, 's');

%% TEST case: A mesh that cannot be loaded is drawn as a box
figNum = 20007;
titleString = sprintf('TEST case: A mesh that cannot be loaded is drawn as a box');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveFolder = newFolder();
badRows = liveRows;
badRows(3).meshID = '1999_No_Such_Car';
fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, fcn_AnimateCar3D_loadSceneList(badRows), liveMotions, 3);
warning('off','AnimateCar3D:playLive:meshNotLoaded');
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, Steps=1, FigNum=figNum);
warning('on','AnimateCar3D:playLive:meshNotLoaded');
assert(isequal(liveState.FailedMeshIDs, {'1999_No_Such_Car'}));
car2Index = strcmp({liveState.Catalog.Objects.Instance}, 'car2');
assert(strcmp(liveState.Catalog.Objects(car2Index).MeshID, 'box') && any(strcmpi(liveState.MeshSet.IDs, 'box')));
assert(liveState.Stats.StepsDrawn==1);
rmdir(liveFolder, 's');

%% TEST case: Clear deletes the drawn graphics
figNum = 20005;
titleString = sprintf('TEST case: Clear deletes the drawn graphics');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

liveFolder = newFolder();
fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, 3);
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, Steps=1, FigNum=figNum);
assert(~isempty(findobj(liveState.Axes, 'Type','hgtransform')));
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=liveState, Action='clear');
assert(isempty(findobj(liveState.Axes, 'Type','hgtransform')) && isempty(findall(liveState.Figure, 'Tag', 'AnimateCar3D live caption')));
rmdir(liveFolder, 's');

%% Fast Mode Tests

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1 (draws in the current figure)\n',figNum);
liveFolder = newFolder();
fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, 3);
figure(figNum);
liveState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, Steps=1, FigNum=-1);
assert(isequal(liveState.Figure.Number, figNum));
close(figNum);
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
    fcn_AnimateCar3D_playLive('C:\no\such\folder', meshSet);
end

%% FAIL case: Steps that is not positive
if 1==0
    fcn_AnimateCar3D_playLive(tempdir, meshSet, Steps=0);
end

%% Functions follow
%% fcn_INTERNAL_newFolder
function liveFolder = fcn_INTERNAL_newFolder
% A new, empty temporary folder
liveFolder = tempname;
mkdir(liveFolder);
end % Ends fcn_INTERNAL_newFolder
