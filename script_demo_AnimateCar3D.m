
%% Introduction to and Purpose of the Code
% This is the explanation of the code that can be found by running
%       script_demo_AnimateCar3D.m
% This is a script to demonstrate the functions within the AnimateCar3D code
% library. This code repo is typically located at:
%   https://github.com/ivsg-psu/VehicleSimulations_VehiclePlotting_AnimateCar3D
%
% If you have questions or comments, please contact Sean Brennan at
% sbrennan@psu.edu
%
% The purpose of the code is animate mesh representations of vehicles in 3D
% scenes, quickly, without needing to install extra toolboxes or use 3D
% immersive visualization toolsets (CARLA, RoadRunner, Simscape, etc.).
%
% AnimateCar3D uses the CarMesh3D library for its vehicle meshes and its
% single-vehicle plotting functions. By default, the released CarMesh3D
% installed in the Utilities folder is used. To develop both libraries at
% the same time, set flag_useWorkingCarMesh3D = 1 below (or set the
% environment variable ANIMATECAR3D_CARMESH3D_PATH to a CarMesh3D folder)
% to use a working copy of CarMesh3D instead. Either way, exactly one copy
% of CarMesh3D is left on the MATLAB path.

% REVISION HISTORY:
% 
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_AnimateCar3D
%   % * First prototype of the library (drafted with Claude)
%   % * Core include repos are: {'CarMesh3D'}
%   % * Naming: each function fcn_AnimateCar3D_<name> is tested by
%   %   % script_test_fcn_AnimateCar3D_<name> in the Functions folder;
%   %   % scripts that demonstrate the code more generally are named
%   %   % script_AnimateCar3D_<name>
%   % * Removed the BreakDataIntoLaps template leftovers
%   % * Exactly one copy of CarMesh3D is kept on the path: the installed
%   %   % release (default), or a working copy (flag_useWorkingCarMesh3D)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_demo_AnimateCar3D
%   % * Detail levels set by size on screen (CarMesh3D 2026_11_20): the
%   %   % meshes load with their levels, the selector gets the mesh set,
%   %   % and the display criteria use sizes on screen, not distances
%   % * Motions given as cell arrays where they have different fields
%   %   % (steps 6 and 8), with no empty fields added
%   % * Path lines drawn by the selector and player (step 5 no longer
%   %   % draws its own); step 9, path line options


% TO-DO:
% - 2026_11_19 by Sean Brennan, sbrennan@psu.edu
%   % * Need to add to-do items here


%% Make sure we are running out of root directory
st = dbstack; 
thisFile = which(st(1).file);
[filepath,name,ext] = fileparts(thisFile);
cd(filepath);

%% Choose which copy of CarMesh3D to use
% 0: the released CarMesh3D installed in Utilities (default)
% 1: a working copy, for developing CarMesh3D and AnimateCar3D together.
%    The working copy is workingCarMesh3DFolder below, or, if that is
%    empty, the folder in the environment variable
%    ANIMATECAR3D_CARMESH3D_PATH, or, if that is empty too, a CarMesh3D
%    folder next to this one.
flag_useWorkingCarMesh3D = 0;
workingCarMesh3DFolder = '';
if ~isempty(getenv('ANIMATECAR3D_CARMESH3D_PATH'))
	flag_useWorkingCarMesh3D = 1;
end

%% START OF STANDARD INSTALLER CODE %%%%%%%%%

%%% Clear paths and folders, if needed
if 1==1
	clear flag_AnimateCar3D_Folders_Initialized
end

if 1==0
	fcn_INTERNAL_clearUtilitiesFromPathAndFolders;
end

if 1==0
	% Resets all paths to factory default
	restoredefaultpath;
end


% Do we need to set up the work space?
if ~exist('flag_AnimateCar3D_Folders_Initialized','var') || 0==flag_AnimateCar3D_Folders_Initialized
	fcn_INTERNAL_setupWorkspace;
	flag_AnimateCar3D_Folders_Initialized = 1;
else
	fprintf(1,'Skipping installs as it appears this was completed previously in this session.\n');
end

%%%% END OF STANDARD INSTALLER CODE %%%%%%%%%

%% Keep exactly one copy of CarMesh3D on the path
% Done on every run (it is fast), since other work in the same MATLAB
% session may have added another copy of CarMesh3D to the path
carMesh3DRoot = fcn_INTERNAL_selectCarMesh3DCopy(flag_useWorkingCarMesh3D, workingCarMesh3DFolder);


%% Check if repo is ready for release
if 1==0
	figNum = 999999;
	repoShortName = '_ANIMATECAR3D_';
	fcn_DebugTools_testRepoForRelease(repoShortName, (figNum));
end

%% Start of Demo Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____ _             _            __   _____                          _____          _
%  / ____| |           | |          / _| |  __ \                        / ____|        | |
% | (___ | |_ __ _ _ __| |_    ___ | |_  | |  | | ___ _ __ ___   ___   | |     ___   __| | ___
%  \___ \| __/ _` | '__| __|  / _ \|  _| | |  | |/ _ \ '_ ` _ \ / _ \  | |    / _ \ / _` |/ _ \
%  ____) | || (_| | |  | |_  | (_) | |   | |__| |  __/ | | | | | (_) | | |___| (_) | (_| |  __/
% |_____/ \__\__,_|_|   \__|  \___/|_|   |_____/ \___|_| |_| |_|\___/   \_____\___/ \__,_|\___|
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Start%20of%20Demo%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Welcome to the demo code for the AnimateCar3D library!')
fprintf(1,'Using CarMesh3D from: %s\n', carMesh3DRoot);

% Save the demo animations as GIFs in the Images folder? (1 = yes)
flag_saveGifs = 1;


%% Step 1. Check that CarMesh3D provides what AnimateCar3D needs
% Stops with a clear error if a new CarMesh3D release changed something
% AnimateCar3D relies on (see the README, "Checking CarMesh3D").
checkReport = fcn_AnimateCar3D_checkCarMesh3D(FigNum=-1);


%% Step 2. Load the vehicle meshes, with their detail levels
% Each vehicle is kept as its finished CarMesh3D mesh (drawn when it is
% large on screen) and its ladder of detail levels from CarMesh3D (each
% made for a largest size on screen, down to a box). Figure 2 shows them.
% ('box' is a plain box: for static objects, and for vehicles known only
% by their size)
meshSet = fcn_AnimateCar3D_loadMeshes({'2013_Toyota_Prius_Four','2014_Ford_TransitConnect_XLTCargoLWB','box'}, FigNum=2);


%% Step 3. One vehicle splitting into ten decision branches
% The ego vehicle drives straight for 2 s, then splits into ten possible
% paths, from a hard left to a hard right. Each branch is drawn
% see-through in its own color, except the chosen one (solid); a line on
% the ground traces each path. The scene player draws whatever the
% display list holds at each step: here the list is built directly from
% the motions (later, the selector will build it).
priusID = '2013_Toyota_Prius_Four';
priusSpec = meshSet.(matlab.lang.makeValidName(priusID)).Full.VehicleSpec;
branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=10, SplitTime=2, Duration=6, ...
    Speed=8, MaxCurvature=1/16, VehicleSpec=priusSpec, FigNum=3);
chosenBranch = 4;
Nbranches = numel(branchMotions.Branches);
fraction = linspace(0,1,Nbranches)';
branchColors = [0.15+0.75*fraction, 0.35*ones(Nbranches,1), 0.9-0.75*fraction];   % blue (left) to red (right)
branchAlpha = 0.35*ones(Nbranches,1);
branchAlpha(chosenBranch) = 1;

% The scene and camera
figNum = 4;
figure(figNum); clf;
set(gcf, 'Position', [100 100 800 450], 'Color', 'w');
fcn_CarMesh3D_plotScene(GroundExtent=[-10 70 -40 40], GridSpacing=5, FigNum=figNum);
axis off;
campos([-4 -34 24]); camtarget([30 0 0]); camva(25);
set(gca, 'Projection', 'perspective');

% The animation loop: one display list per step, drawn by the player
timeSteps = (0:0.05:6)';
pathLines = gobjects(Nbranches,1);
playerState = [];
gifFile = fullfile(pwd,'Images','branching_tenChoices.gif');
gifFrame = 0;
totalCreated = 0;
totalReused = 0;
for ith_step = 1:numel(timeSteps)
    t = timeSteps(ith_step);
    if t < branchMotions.Parent.SplitTime - 1e-9
        % Before the split: only the ego vehicle
        parent = branchMotions.Parent;
        row = find(parent.Time <= t + 1e-9, 1, 'last');
        displayList = fcn_AnimateCar3D_fillDisplayList(Time=t, Instance=parent.Instance, MeshID=priusID, ...
            Pose=parent.Pose(row,:), WheelSpin=parent.WheelSpin(row,:), SteerAngle=parent.SteerAngle(row,:));
    else
        % After the split: every branch, at the same time
        branches = branchMotions.Branches;
        row = find(branches(1).Time <= t + 1e-9, 1, 'last');
        poses = cell2mat(arrayfun(@(b) b.Pose(row,:), branches, 'UniformOutput', false));
        spins = cell2mat(arrayfun(@(b) b.WheelSpin(row,:), branches, 'UniformOutput', false));
        steers = cell2mat(arrayfun(@(b) b.SteerAngle(row,:), branches, 'UniformOutput', false));
        displayList = fcn_AnimateCar3D_fillDisplayList(Time=t, Instance={branches.Instance}, MeshID=priusID, ...
            Pose=poses, WheelSpin=spins, SteerAngle=steers, Color=branchColors, Alpha=branchAlpha);

        % Path lines on the ground (drawn by this script for now)
        for ith_branch = 1:Nbranches
            pathXY = branches(ith_branch).Pose(1:row,1:2);
            if ~isgraphics(pathLines(ith_branch))
                pathLines(ith_branch) = line(pathXY(:,1), pathXY(:,2), 0.02*ones(row,1), ...
                    'Color', branchColors(ith_branch,:), 'LineWidth', 1.5 + 1.5*(ith_branch==chosenBranch));
            else
                set(pathLines(ith_branch), 'XData', pathXY(:,1), 'YData', pathXY(:,2), 'ZData', 0.02*ones(row,1));
            end
        end
    end
    playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState, FigNum=figNum);
    totalCreated = totalCreated + playerState.Stats.NumCreated;
    totalReused = totalReused + playerState.Stats.NumReused;
    fcn_INTERNAL_setCaption(gcf, sprintf('t = %.2f s', t));
    drawnow;
    if flag_saveGifs && mod(ith_step-1,2)==0
        % A GIF has only 256 colors. A fixed set (the first frame's 30
        % main colors, an even spread of 216, and the branch colors) keeps
        % the thin colored paths from turning gray.
        gifFrame = gifFrame + 1;
        if gifFrame==1
            firstImage = getframe(gcf);
            [~, firstColors] = rgb2ind(firstImage.cdata, 30, 'nodither');
            [cubeR, cubeG, cubeB] = ndgrid(linspace(0,1,6));
            gifColorMap = [firstColors; cubeR(:) cubeG(:) cubeB(:); branchColors];
        end
        fcn_INTERNAL_saveGifFrameFixedColors(gcf, gifFile, gifFrame, gifColorMap, 0.1);
    end
end
fprintf(1,'Branching demo: %d steps; %d vehicles drawn new, %d reused (the ego''s graphics become a branch).\n', ...
    numel(timeSteps), totalCreated, totalReused);


%% Step 4. How fast can the player draw dense traffic?
% See script_AnimateCar3D_frameRateTest.m, which times the player with
% 100 to 1000 vehicles around the ego vehicle, using the detail tiers.


%% Step 5. A confederate with branches, and the ego vehicle's responses
% The full pipeline: scene list and motions -> object catalog ->
% selector (with display criteria) -> scene player.
%
% A confederate van comes up a side street toward the ego's road. At
% 2.5 s it splits into three possible maneuvers: (1) it stops, (2) it
% crosses the road, (3) it turns right onto the road, ahead of the ego.
% At 3 s the ego splits into three responses, each linked (respondsTo) to
% the confederate branch it answers: (1) carry on, (2) brake hard,
% (3) slow and change lanes to the left. Each confederate branch and the
% ego response to it share a color. Brake lights come on when slowing.
vanID = '2014_Ford_TransitConnect_XLTCargoLWB';
vanSpec = meshSet.(matlab.lang.makeValidName(vanID)).Full.VehicleSpec;
dt = 0.05;

% The motions (simple kinematics: speed and curvature over time)
egoMotion  = fcn_INTERNAL_integrateMotion('ego', (0:dt:3)', [0 0 0], 0, @(t) 10+0*t, @(t) 0*t, priusSpec);
egoEnd = [egoMotion.Pose(end,:), egoMotion.WheelSpin(end,1)];
responseTime = (3:dt:9)';
laneChange = @(t) (t>=3.3 & t<=5.3) .* (2*pi*3.6/(9*2)^2) .* sin(2*pi*(t-3.3)/2);
egoResponses = [ ...
    fcn_INTERNAL_integrateMotion('ego_carryOn', responseTime, egoEnd(1:3), egoEnd(4), @(t) 10+0*t, @(t) 0*t, priusSpec); ...
    fcn_INTERNAL_integrateMotion('ego_brake',   responseTime, egoEnd(1:3), egoEnd(4), @(t) max(0, 10-6*(t-3)), @(t) 0*t, priusSpec); ...
    fcn_INTERNAL_integrateMotion('ego_swerve',  responseTime, egoEnd(1:3), egoEnd(4), @(t) max(8, 10-1.5*(t-3)), laneChange, priusSpec)];
vanMotion = fcn_INTERNAL_integrateMotion('van', (0:dt:2.5)', [70 -45 pi/2], 0, @(t) 8+0*t, @(t) 0*t, vanSpec);
vanEnd = [vanMotion.Pose(end,:), vanMotion.WheelSpin(end,1)];
maneuverTime = (2.5:dt:9)';
rightTurn = @(t) -(1/10) * (t >= 2.5+15/8 & t < 2.5+15/8+(pi*10/2)/8);
vanManeuvers = [ ...
    fcn_INTERNAL_integrateMotion('van_stops',   maneuverTime, vanEnd(1:3), vanEnd(4), @(t) max(0, 8-5*(t-2.5)), @(t) 0*t, vanSpec); ...
    fcn_INTERNAL_integrateMotion('van_crosses', maneuverTime, vanEnd(1:3), vanEnd(4), @(t) 8+0*t, @(t) 0*t, vanSpec); ...
    fcn_INTERNAL_integrateMotion('van_turns',   maneuverTime, vanEnd(1:3), vanEnd(4), @(t) 8+0*t, rightTurn, vanSpec)];

% The scene list (in memory here; it could equally be a CSV file read
% with fcn_AnimateCar3D_loadSceneList)
pairColors = [0.20 0.65 0.25; 0.95 0.55 0.10; 0.55 0.30 0.80];
sceneRows = struct('instance', {'ego','ego_carryOn','ego_brake','ego_swerve','van','van_stops','van_crosses','van_turns'}, ...
    'role', {'ego','ego','ego','ego','confederate','confederate','confederate','confederate'}, ...
    'meshID', {priusID, priusID, priusID, priusID, vanID, vanID, vanID, vanID}, ...
    'branchOf', {'','ego','ego','ego','','van','van','van'}, 'branchID', {0,1,2,3,0,1,2,3}, ...
    'respondsTo', {'','van_stops','van_crosses','van_turns','','','',''}, ...
    'color', {[],pairColors(1,:),pairColors(2,:),pairColors(3,:),[],pairColors(1,:),pairColors(2,:),pairColors(3,:)});
sceneList = fcn_AnimateCar3D_loadSceneList(sceneRows);

% The catalog, with the cube grid as the static scene
staticScene = fcn_AnimateCar3D_loadStaticScene(fullfile(pwd,'Data','staticScene_cubeGrid.csv'));
catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=[egoMotion; egoResponses; vanMotion; vanManeuvers], ...
    StaticScene=staticScene, FigNum=5);

% Display criteria: the camera's view (the default), out to 250 m; each
% object's detail is set by its size on screen. Confederates are drawn
% in full, like the ego. Path lines are on by default: each branch's
% trail, in its color, from the split point (and each parent's, up to it).
criteria = fcn_AnimateCar3D_fillDisplayCriteria(MaxDistance=250, ...
    FixedTiers={'ego','near'; 'confederate','near'}, BranchAlpha=0.55);

% The scene, camera, and loop
figNum = 6;
figure(figNum); clf;
set(gcf, 'Position', [100 100 800 450], 'Color', 'w');
fcn_CarMesh3D_plotScene(GroundExtent=[-60 200 -80 80], GridSpacing=10, FigNum=figNum);
axis off;
line([-60 200], [-1.8 -1.8], [0.02 0.02], 'Color', [0.95 0.95 0.95], 'LineWidth', 1.5);   % road edges
line([-60 200], [5.4 5.4], [0.02 0.02], 'Color', [0.95 0.95 0.95], 'LineWidth', 1.5);
campos([42 34 21]); camtarget([70 -10 0]); camva(44);
set(gca, 'Projection', 'perspective');
timeSteps = (0:dt:9)';
playerState = [];
selectorState = [];
gifFile = fullfile(pwd,'Images','confederate_branchesAndResponses.gif');
gifFrame = 0;
for ith_step = 1:numel(timeSteps)
    t = timeSteps(ith_step);
    [displayList, selectorState] = fcn_AnimateCar3D_selectObjects(catalog, t, criteria, ...
        SelectorState=selectorState, Camera=gca, MeshSet=meshSet);
    playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState, FigNum=figNum);

    fcn_INTERNAL_setCaption(gcf, sprintf('t = %.2f s', t));
    drawnow;
    if flag_saveGifs && mod(ith_step-1,2)==0
        gifFrame = gifFrame + 1;
        if gifFrame==1
            firstImage = getframe(gcf);
            [~, firstColors] = rgb2ind(firstImage.cdata, 30, 'nodither');
            [cubeR, cubeG, cubeB] = ndgrid(linspace(0,1,6));
            gifColorMap = [firstColors; cubeR(:) cubeG(:) cubeB(:); pairColors; criteria.ConfederateColor];
        end
        fcn_INTERNAL_saveGifFrameFixedColors(gcf, gifFile, gifFrame, gifColorMap, 0.1);
    end
end
fcn_AnimateCar3D_playScene([], meshSet, PlayerState=playerState, Action='clear');


%% Step 6. Dense traffic from one file, with a panning camera
% 300 vehicles on a four-lane road, read from ONE long-format traffic file
% (id, time, X, Y, yaw, plus a size: a few are trucks drawn as boxes).
% The camera pans slowly along the road while the ego vehicle drives
% faster, so the ego enters the view and then leaves it. The selector
% follows the camera's view: only what the camera sees is drawn, with
% detail set by distance from the camera.
trafficFile = fullfile(pwd,'Data','traffic_fourLaneRoad.csv');
if ~isfile(trafficFile)
    fcn_INTERNAL_writeDemoTraffic(trafficFile, 300);
end
[trafficList, trafficMotions] = fcn_AnimateCar3D_loadTrafficFile(trafficFile, MeshID=priusID);
carColors = [0.92 0.92 0.92; 0.70 0.71 0.74; 0.12 0.12 0.14; 0.75 0.12 0.10; 0.18 0.30 0.60; 0.45 0.47 0.50];
for ith_vehicle = 1:numel(trafficList)
    if ~isnan(trafficList(ith_vehicle).Size(1))
        trafficList(ith_vehicle).MeshID = 'box';          % trucks: boxes of their own size
        trafficList(ith_vehicle).Color = [0.85 0.85 0.80];
    else
        if mod(ith_vehicle,4)==0
            trafficList(ith_vehicle).MeshID = vanID;      % every fourth vehicle a van
        end
        trafficList(ith_vehicle).Color = carColors(mod(7*ith_vehicle, size(carColors,1))+1,:);
    end
end
egoTime = (0:0.05:15)';
egoDrive = fcn_INTERNAL_integrateMotion('ego', egoTime, [-10 -1.8 0], 0, @(t) 13+0*t, @(t) 0*t, priusSpec);
egoRow = fcn_AnimateCar3D_loadSceneList(struct('instance','ego','role','ego','meshID',priusID,'color',[0.05 0.2 0.6]));
sceneList = [egoRow; trafficList];
% (Motions as a cell array: the ego's has wheels and lights, the
% traffic's only poses)
catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=[{egoDrive}; num2cell(trafficMotions)], StaticScene=staticScene, ...
    CacheFile=fullfile(tempdir,'AnimateCar3D_demoTrafficCatalog.mat'));
criteria = fcn_AnimateCar3D_fillDisplayCriteria(MaxDistance=250);

figNum = 7;
figure(figNum); clf;
set(gcf, 'Position', [100 100 800 450], 'Color', 'w');
fcn_CarMesh3D_plotScene(GroundExtent=[-150 450 -90 90], GridSpacing=10, FigNum=figNum);
axis off;
for laneLineY = [-7.2 -3.6 0 3.6 7.2]
    line([-150 450], [laneLineY laneLineY], [0.02 0.02], 'Color', [0.95 0.95 0.95], 'LineWidth', 1.5);
end
set(gca, 'Projection', 'perspective');
cameraX = @(t) 20 + 6*t;          % the camera pans at 6 m/s; the ego drives at 13 m/s
playerState = [];
selectorState = [];
gifFile = fullfile(pwd,'Images','traffic_cameraPan.gif');
gifFrame = 0;
for ith_step = 1:numel(egoTime)
    t = egoTime(ith_step);
    campos([cameraX(t)-30 -42 24]); camtarget([cameraX(t)+25 0 0]); camva(42);
    [displayList, selectorState] = fcn_AnimateCar3D_selectObjects(catalog, t, criteria, ...
        SelectorState=selectorState, Camera=gca, MeshSet=meshSet);
    playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState, FigNum=figNum);
    stats = selectorState.Stats;
    fcn_INTERNAL_setCaption(gcf, sprintf('t = %.1f s: %d candidates; drawn %d near, %d middle, %d far (merged)', t, ...
        stats.NumCandidates, stats.NumNear, stats.NumMiddle, stats.NumFar));
    drawnow;
    if flag_saveGifs && mod(ith_step-1,3)==0
        gifFrame = gifFrame + 1;
        if gifFrame==1
            firstImage = getframe(gcf);
            [~, firstColors] = rgb2ind(firstImage.cdata, 40, 'nodither');
            [cubeR, cubeG, cubeB] = ndgrid(linspace(0,1,6));
            gifColorMap = [firstColors; cubeR(:) cubeG(:) cubeB(:)];
        end
        fcn_INTERNAL_saveGifFrameFixedColors(gcf, gifFile, gifFrame, gifColorMap, 0.15);
    end
end
fcn_AnimateCar3D_playScene([], meshSet, PlayerState=playerState, Action='clear');
fprintf(1,'Traffic demo: %d vehicles in the file; at the end, %d candidates near the camera\n', ...
    numel(trafficList), selectorState.Stats.NumCandidates);



%% Step 7. Live data from a watched folder, with criteria changed while running
% A live source (here the test helper fcn_AnimateCar3D_writeLiveTestFiles,
% standing in for a simulator) writes one motion file per vehicle into a
% folder: each file appears when its vehicle starts, grows as time goes
% on, and is deleted a second after its vehicle is gone. The animation
% loop watches the folder (fcn_AnimateCar3D_watchFolder), updates the
% catalog (fcn_AnimateCar3D_updateCatalog), and draws 1 s behind the
% newest data. Partway through, a person "edits" displayCriteria.txt in
% the folder: first all traffic is merged (each vehicle at its detail
% level, in one patch), then back to the defaults
% (fcn_AnimateCar3D_changeDisplayCriteria). The camera follows the ego.
liveFolder = fullfile(tempdir, 'AnimateCar3D_liveDemo');
if isfolder(liveFolder)
    rmdir(liveFolder, 's');
end
mkdir(liveFolder);

% The vehicles: the ego on the middle lane at 12 m/s; oncoming cars on
% the left lane; faster cars overtaking on the right lane. Each traffic
% vehicle starts at its own time (its time offset), so its file appears
% then. An overtaking car starts 35 m behind the ego (behind the camera)
% and drives long enough to pass the ego and pull far ahead, so it goes
% from near detail, to the low-detail mesh, to a box, and then out of
% the drawn region, by its distance from the camera.
dt = 0.1;
liveDuration = 22;
egoLive = fcn_INTERNAL_integrateMotion('ego', (0:dt:liveDuration)', [0 -1.8 0], 0, @(t) 12+0*t, @(t) 0*t, priusSpec);
randomStream = RandStream('mt19937ar', 'Seed', 7);
liveRows = struct('instance','ego', 'role','ego', 'meshID',priusID, 'color',[0.05 0.2 0.6], 'timeOffset',0);
liveMotions = egoLive;
for ith_car = 1:22
    flagOncoming = mod(ith_car,2)==1;
    startTime = 0.6*ith_car - 0.5;
    if flagOncoming
        lifeTime = (0:0.2:8)';                  % from 110 m ahead to well behind the camera
        speed = 11 + 3*rand(randomStream);
        startPose = [12*startTime + 110, 1.8, pi];
    else
        lifeTime = (0:0.2:20)';                 % from 35 m behind to 80 m or more ahead
        speed = 18 + 2*rand(randomStream);
        startPose = [12*startTime - 35, -5.4, 0];
    end
    pose = [startPose(1) + cos(startPose(3))*speed*lifeTime, startPose(2)*ones(size(lifeTime)), startPose(3)*ones(size(lifeTime))];
    carName = sprintf('car%02d', ith_car);
    if mod(ith_car,4)==0
        carMesh = vanID;
    else
        carMesh = priusID;
    end
    liveRows(end+1) = struct('instance',carName, 'role','traffic', 'meshID',carMesh, ...
        'color',carColors(mod(5*ith_car, size(carColors,1))+1,:), 'timeOffset',startTime); %#ok<SAGROW>
    liveMotions(end+1,1) = struct('Instance',carName, 'Time',lifeTime, 'Pose',pose, 'WheelSpin',[], ...
        'SteerAngle',[], 'LightStates',[]); %#ok<SAGROW>
end
liveList = fcn_AnimateCar3D_loadSceneList(liveRows);

% The display criteria at the start, and the "edits" made while running
% (Sizes on screen, in pixels: at 4 s every vehicle but the ego is
% merged, at its detail level; at 7 s back to the defaults.)
criteria = fcn_AnimateCar3D_fillDisplayCriteria(MaxDistance=150);
criteriaFile = fullfile(liveFolder, 'displayCriteria.txt');
criteriaEdits = {4, ["% All traffic merged"; "TopScreenSize = 10000"; "MergeBelowSize = 10000"], 'edited: all traffic merged'; ...
                 7, ["% Back to the defaults"; "TopScreenSize = 105"; "MergeBelowSize = 37"], 'edited: defaults again'};
criteriaNote = 'criteria: as started';

figNum = 8;
figure(figNum); clf;
set(gcf, 'Position', [100 100 800 450], 'Color', 'w');
fcn_CarMesh3D_plotScene(GroundExtent=[-60 420 -40 40], GridSpacing=10, FigNum=figNum);
axis off;
for laneLineY = [-7.2 -3.6 0 3.6]
    line([-60 420], [laneLineY laneLineY], [0.02 0.02], 'Color', [0.95 0.95 0.95], 'LineWidth', 1.5);
end

% The live loop is one function, fcn_AnimateCar3D_playLive: it watches
% the folder, updates the catalog and the criteria, points the camera
% (a CarMesh3D 'kite' camera, moved back and to the side), selects,
% draws, and saves GIF frames. Here the data is written in the same loop,
% so it takes one step per call (Steps=1) and is told the time to show (1
% s behind the newest data). A program writing the folder on its own
% needs only one call, which runs until no new data comes:
%       fcn_AnimateCar3D_playLive(liveFolder, meshSet, Criteria=criteria);
cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='kite', Position=[-22 -16 10], Target=[18 1 0], FieldOfView=40);
gifFile = '';
if flag_saveGifs
    gifFile = fullfile(pwd,'Images','live_watchedFolder.gif');
    if isfile(gifFile)
        delete(gifFile);
    end
end
writerState = [];
playState = [];
writerTimes = (0:dt:liveDuration)';
for ith_step = 1:numel(writerTimes)
    writerTime = writerTimes(ith_step);

    % The live source writes up to now, and a person edits the criteria
    writerState = fcn_AnimateCar3D_writeLiveTestFiles(liveFolder, liveList, liveMotions, writerTime, ...
        LiveState=writerState, DeleteAfter=1);
    for ith_edit = 1:size(criteriaEdits,1)
        if abs(writerTime - criteriaEdits{ith_edit,1}) < dt/2
            writelines(criteriaEdits{ith_edit,2}, criteriaFile);
            criteriaNote = criteriaEdits{ith_edit,3};
        end
    end

    % One step: check the folder every 0.5 s of scene time (a live run
    % would use CheckInterval, in clock time), show 1 s behind the data
    playState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=playState, Steps=1, ...
        Criteria=criteria, DefaultMeshID=priusID, CheckInterval=Inf, ForceCheck=mod(ith_step-1, round(0.5/dt))==0, ...
        ShowTime=writerTime-1, CameraSettings=cameraSettings, Caption=criteriaNote, ...
        GifFile=gifFile, GifEvery=2, GifDelay=0.2, FigNum=figNum);
end
playState = fcn_AnimateCar3D_playLive(liveFolder, meshSet, LiveState=playState, Action='clear');
fprintf(1,'Live demo: %d steps (%d drawn), %d folder checks, %d criteria changes; %.0f ms per step on average\n', ...
    playState.Stats.Steps, playState.Stats.StepsDrawn, playState.Stats.Checks, playState.Stats.CriteriaChanges, ...
    1000*playState.Stats.StepSeconds);
rmdir(liveFolder, 's');



%% Step 8. Pedestrians and a moving item: a crosswalk and a parking gate
% Simple shapes (fcn_AnimateCar3D_fillSimpleShape) for objects that have
% no vehicle mesh. Seven pedestrians (role 'pedestrian', shape
% 'pedestrian') cross the road; the ego stops for them, then drives on to
% a parking gate (role 'movingItem', shape 'bar'), whose arm rises as the
% ego comes near: its pitch changes over time. Posts along the sidewalks
% are static cylinders. Simple shapes are drawn with the far boxes and
% shapes, all in one patch, so a crowd costs little.
dt = 0.1;
egoSpeed = @(t) 10*(t<1.5) + max(0, 10-(10/3)*(t-1.5)).*(t>=1.5 & t<4.5) + ...
    min(10, 2.5*max(0,t-6.5)).*(t>=6.5);
egoGate = fcn_INTERNAL_integrateMotion('ego', (0:dt:16)', [0 -1.8 0], 0, egoSpeed, @(t) 0*t, priusSpec);

% The pedestrians: from the south sidewalk to the north one (and one the
% other way), each starting at its own time
walkerColors = [0.80 0.20 0.20; 0.20 0.55 0.25; 0.95 0.75 0.10; 0.45 0.25 0.65; 0.10 0.45 0.75; 0.90 0.45 0.15; 0.30 0.30 0.30];
walkerStarts = [0 0.4 0.9 1.3 1.6 2.0 0.2];
walkerX = [36.4 37.6 36.9 38.2 37.2 36.6 38.0];
gateRows = struct('instance','ego', 'role','ego', 'meshID',priusID, 'color',[0.05 0.2 0.6], 'timeOffset',0, 'height',NaN);
gateMotions = {struct('Instance','ego', 'Time',egoGate.Time, 'Pose',egoGate.Pose, 'WheelSpin',egoGate.WheelSpin, ...
    'SteerAngle',egoGate.SteerAngle, 'LightStates',egoGate.LightStates)};      % a cell array: each motion has only its own fields
for ith_walker = 1:numel(walkerStarts)
    walkTime = (0:0.2:8.5)';
    if ith_walker < numel(walkerStarts)
        walkY = -6.3 + 1.5*walkTime;   heading = pi/2;     % south to north
    else
        walkY = 6.3 - 1.4*walkTime;    heading = -pi/2;    % north to south
    end
    walkerName = sprintf('walker%d', ith_walker);
    gateRows(end+1) = struct('instance',walkerName, 'role','pedestrian', 'meshID','pedestrian', ...
        'color',walkerColors(ith_walker,:), 'timeOffset',walkerStarts(ith_walker), 'height',1.6+0.1*mod(ith_walker,3)); %#ok<SAGROW>
    gateMotions{end+1,1} = struct('Instance',walkerName, 'Time',walkTime, ...
        'Pose',[walkerX(ith_walker)*ones(size(walkTime)), walkY, heading*ones(size(walkTime))]); %#ok<SAGROW>
end

% The gate arm: on a post at the south edge of the ego's lane, pointing
% across it (yaw pi/2), 1 m up; its pitch goes from 0 to -1.45 rad (up)
% between 11.2 and 12.6 s
gateTime = (0:0.2:16)';
gatePitch = -1.45*min(1, max(0, (gateTime-11.2)/1.4));
gateRows(end+1) = struct('instance','gate', 'role','movingItem', 'meshID','bar', 'color',[0.95 0.85 0.10], ...
    'timeOffset',0, 'height',NaN);
gateMotions{end+1,1} = struct('Instance','gate', 'Time',gateTime, ...
    'Pose',[85*ones(size(gateTime)), -4.0*ones(size(gateTime)), ones(size(gateTime)), zeros(size(gateTime)), gatePitch, (pi/2)*ones(size(gateTime))]);
gateList = fcn_AnimateCar3D_loadSceneList(gateRows);

% Static: posts along both sidewalks, the gate's post, and two buildings
postX = [0:6:30, 46:6:80];
staticRows = struct('x', num2cell([postX, postX, 85, 20, 70]), ...
    'y', num2cell([-4.4*ones(size(postX)), 4.4*ones(size(postX)), -4.0, 16, 17]), ...
    'meshID', [repmat({'cylinder'}, 1, 2*numel(postX)+1), {'box','box'}], ...
    'length', num2cell([0.25*ones(1,2*numel(postX)), 0.3, 24, 30]), ...
    'width', num2cell([0.25*ones(1,2*numel(postX)), 0.3, 12, 14]), ...
    'height', num2cell([0.9*ones(1,2*numel(postX)), 1.1, 9, 6]), ...
    'color', [repmat({'0.35 0.35 0.38'}, 1, 2*numel(postX)+1), {'0.75 0.70 0.62','0.62 0.66 0.72'}]);
gateStatic = fcn_AnimateCar3D_loadStaticScene(staticRows);
meshSet = fcn_AnimateCar3D_loadMeshes({'pedestrian','bar','cylinder'}, MeshSet=meshSet);
catalog = fcn_AnimateCar3D_buildCatalog(gateList, Motions=gateMotions, StaticScene=gateStatic);
criteria = fcn_AnimateCar3D_fillDisplayCriteria(MaxDistance=200);

figNum = 9;
figure(figNum); clf;
set(gcf, 'Position', [100 100 800 450], 'Color', 'w');
fcn_CarMesh3D_plotScene(GroundExtent=[-20 120 -30 30], GridSpacing=10, FigNum=figNum);
axis off;
patch([-20 120 120 -20], [-3.6 -3.6 3.6 3.6], 0.01*[1 1 1 1], [0.35 0.36 0.38], 'EdgeColor','none');   % the road
line([-20 120], [0 0], [0.02 0.02], 'Color', [0.95 0.85 0.3], 'LineWidth', 1.5);
for stripeY = -3.2:0.8:3.2
    patch([35.5 39 39 35.5], stripeY + [-0.2 -0.2 0.2 0.2], 0.02*[1 1 1 1], [0.95 0.95 0.95], 'EdgeColor','none');
end
set(gca, 'Projection', 'perspective');
camva(40);
egoIndex = find(strcmp({catalog.Objects.Instance}, 'ego'), 1);
timeSteps = (0:dt:16)';
playerState = [];
selectorState = [];
gifFile = fullfile(pwd,'Images','pedestrians_crosswalkGate.gif');
gifFrame = 0;
for ith_step = 1:numel(timeSteps)
    t = timeSteps(ith_step);
    egoState = fcn_AnimateCar3D_getObjectState(catalog, egoIndex, t, Detail='pose', FigNum=-1);
    campos([egoState.Pose(1)-6, -21, 8]); camtarget([egoState.Pose(1)+13, 1, 0.5]);   % follow the ego
    [displayList, selectorState] = fcn_AnimateCar3D_selectObjects(catalog, t, criteria, ...
        SelectorState=selectorState, Camera=gca, MeshSet=meshSet);
    playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=playerState, FigNum=figNum);
    numWalkers = sum(strcmp(displayList.Boxes.MeshID, 'pedestrian'));
    fcn_INTERNAL_setCaption(gcf, sprintf('t = %.1f s: %d pedestrians; ego speed %.1f m/s; gate arm at %.0f deg', ...
        t, numWalkers, egoSpeed(t), -rad2deg(interp1(gateTime, gatePitch, min(t, gateTime(end))))));
    drawnow;
    if flag_saveGifs && mod(ith_step-1,2)==0
        gifFrame = gifFrame + 1;
        if gifFrame==1
            firstImage = getframe(gcf);
            [~, firstColors] = rgb2ind(firstImage.cdata, 30, 'nodither');
            [cubeR, cubeG, cubeB] = ndgrid(linspace(0,1,6));
            gifColorMap = [firstColors; cubeR(:) cubeG(:) cubeB(:); walkerColors];   % at most 256 colors
        end
        fcn_INTERNAL_saveGifFrameFixedColors(gcf, gifFile, gifFrame, gifColorMap, 0.2);
    end
end
fcn_AnimateCar3D_playScene([], meshSet, PlayerState=playerState, Action='clear');


%% Step 9. Path lines: the defaults, and some options
% The selector lists path lines (displayList.Paths) and the player draws
% them. The same scenario twice, side by side:
%   (a) the defaults: trails only, each in its object's tint; the ego's
%       path (PathRoles) colored by its own speed (its motion's
%       PathColor, a value at each instant, through PathColormap)
%   (b) thin previews (where each will go), ribbons with a center line,
%       branch colors from a palette, and markers on both (the ego's
%       motion's PathMarker: style 1 at 2 s, style 2 at 5 s)
% The ego speeds up from 8 to 14 m/s; a van ahead in the left lane has
% three maneuvers from 3 s: keep its lane, move left, or cut in.
pathTime = (0:0.1:8)';
pathSpeed = 8 + 6*min(pathTime/6, 1);
pathX = cumtrapz(pathTime, pathSpeed);
egoMarker = zeros(size(pathTime));
egoMarker(abs(pathTime-2) < 1e-9) = 1;
egoMarker(abs(pathTime-5) < 1e-9) = 2;
egoPath = struct('Instance','ego', 'Time',pathTime, 'Pose',[pathX, -1.8*ones(size(pathTime)), zeros(size(pathTime))], ...
    'WheelSpin',repmat(pathX/0.317,1,4), 'PathColor',pathSpeed, 'PathMarker',egoMarker);
smoothStep = @(u) min(1,max(0,u)).^2.*(3 - 2*min(1,max(0,u)));
parentTime = (0:0.1:3)';
vanPath = struct('Instance','van', 'Time',parentTime, 'Pose',[22+10*parentTime, 1.8*ones(size(parentTime)), zeros(size(parentTime))]);
branchTime = (3:0.1:8)';
branchY = {1.8*ones(size(branchTime)), 1.8 + 3.6*smoothStep((branchTime-3)/2.5), 1.8 - 3.6*smoothStep((branchTime-3)/2)};
pathMotions = {egoPath, vanPath};
for ith_branch = 1:3
    pathMotions{end+1} = struct('Instance',sprintf('van_branch%d',ith_branch), 'Time',branchTime, ...
        'Pose',[22+10*branchTime, branchY{ith_branch}, atan2(gradient(branchY{ith_branch}, branchTime), 10*ones(size(branchTime)))]); %#ok<SAGROW>
end
pathRows = struct('instance',{'ego','van','van_branch1','van_branch2','van_branch3'}, ...
    'role',{'ego','confederate','confederate','confederate','confederate'}, 'meshID',{priusID,vanID,vanID,vanID,vanID}, ...
    'branchOf',{'','','van','van','van'}, 'branchID',{0,0,1,2,3});
catalog = fcn_AnimateCar3D_buildCatalog(fcn_AnimateCar3D_loadSceneList(pathRows), Motions=pathMotions);
markerStyles = {{'Marker','o','MarkerSize',8}, {'Marker','s','MarkerSize',12,'Color',[0.8 0 0.8],'MarkerFaceColor',[0.8 0 0.8]}};
pathCriteria = {fcn_AnimateCar3D_fillDisplayCriteria(PathRoles={'ego'}, MarkerStyles=markerStyles), ...
    fcn_AnimateCar3D_fillDisplayCriteria(PathRoles={'ego'}, MarkerStyles=markerStyles, PathPreview='thin', ...
    PathLineType='ribbonAndLine', PathColorPolicy='branch', MarkerOn='both')};
pathCaptions = {'(a) defaults: trails, object tints; the ego colored by its speed', ...
    '(b) thin previews, ribbons with a center line, branch palette, markers on both'};
pathStates = cell(2,2);          % {player, selector} for each side
for ith_side = 1:2
    figure(8+ith_side); clf;
    set(gcf, 'Position', [100+660*(ith_side-1) 100 640 360], 'Color', 'w');
    fcn_CarMesh3D_plotScene(GroundExtent=[-20 200 -25 25], GridSpacing=10, FigNum=8+ith_side);
    axis off;
    set(gca, 'Projection', 'perspective');
    fcn_INTERNAL_setCaption(gcf, pathCaptions{ith_side});
end
gifFile = fullfile(pwd,'Images','pathLines_options.gif');
gifColorMap = [];
for ith_step = 1:2:numel(pathTime)
    sideImages = cell(1,2);
    cameraPosition = [pathX(ith_step)-18 -12 12];
    cameraTarget = [pathX(ith_step)+30 0 0];
    for ith_side = 1:2
        figure(8+ith_side);
        campos(cameraPosition); camtarget(cameraTarget); camva(40);
        [displayList, pathStates{ith_side,2}] = fcn_AnimateCar3D_selectObjects(catalog, pathTime(ith_step), pathCriteria{ith_side}, ...
            SelectorState=pathStates{ith_side,2}, Camera=gca, MeshSet=meshSet);
        pathStates{ith_side,1} = fcn_AnimateCar3D_playScene(displayList, meshSet, PlayerState=pathStates{ith_side,1}, FigNum=8+ith_side);
        campos(cameraPosition); camtarget(cameraTarget); camva(40);
        drawnow;
        frame = getframe(gcf);
        sideImages{ith_side} = frame.cdata;
    end
    if flag_saveGifs
        rows = min(size(sideImages{1},1), size(sideImages{2},1));
        bothSides = [sideImages{1}(1:rows,:,:), sideImages{2}(1:rows,:,:)];
        if isempty(gifColorMap)
            [frameIndexed, gifColorMap] = rgb2ind(bothSides, 255, 'nodither');
            imwrite(frameIndexed, gifColorMap, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', 0.15);
        else
            imwrite(rgb2ind(bothSides, gifColorMap, 'nodither'), gifColorMap, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', 0.15);
        end
    end
end
for ith_side = 1:2
    fcn_AnimateCar3D_playScene([], meshSet, PlayerState=pathStates{ith_side,1}, Action='clear');
end



%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%§

%% fcn_INTERNAL_integrateMotion
function motion = fcn_INTERNAL_integrateMotion(instanceName, timeSteps, startPose, startSpin, speedFunction, curvatureFunction, vehicleSpec)
% A simple kinematic motion: the rear axle follows speed(t) and
% curvature(t) from startPose; tires roll without slipping; the front
% tires steer by Ackermann; brake lights are on while slowing
timeSteps = timeSteps(:);
speed = speedFunction(timeSteps);
curvature = curvatureFunction(timeSteps);
stepDistance = [0; (speed(2:end)+speed(1:end-1))/2 .* diff(timeSteps)];
yaw = startPose(3) + cumsum(stepDistance .* [curvature(1); (curvature(2:end)+curvature(1:end-1))/2]);
meanYaw = [yaw(1); (yaw(2:end)+yaw(1:end-1))/2];
x = startPose(1) + cumsum(stepDistance.*cos(meanYaw));
y = startPose(2) + cumsum(stepDistance.*sin(meanYaw));
wheelSpin = startSpin + repmat(cumsum(stepDistance)/(vehicleSpec.TireDiameter/2), 1, 4);
steerAngle = fcn_CarMesh3D_calcAckermannSteering(atan(vehicleSpec.Wheelbase*curvature), vehicleSpec.Wheelbase, ...
    vehicleSpec.TrackFront, FigNum=-1);
flagBraking = [diff(speed); 0] < -1e-6;
lightStates = repmat(struct('Headlights','low', 'TurnLeft',false, 'TurnRight',false, 'Running',false, ...
    'Tail','on', 'Backup',false), numel(timeSteps), 1);
[lightStates(flagBraking).Tail] = deal('brake');
motion = struct('Instance',instanceName, 'Time',timeSteps, 'Pose',[x y yaw], 'WheelSpin',wheelSpin, ...
    'SteerAngle',steerAngle, 'LightStates',lightStates);
end % Ends fcn_INTERNAL_integrateMotion

%% fcn_INTERNAL_writeDemoTraffic
function fcn_INTERNAL_writeDemoTraffic(fileName, Nvehicles)
% Writes the demo traffic file: Nvehicles on three lanes of a four-lane
% road (the ego's lane, y = -1.8, is left free), 15 s at 2 Hz, in long
% format; about one in eight is a truck (with a size)
randomStream = RandStream('mt19937ar', 'Seed', 2026);
laneY = [-5.4 1.8 5.4];
direction = [1 -1 -1];
timeSteps = (0:0.5:15)';
rows = cell(Nvehicles,1);
for ith_vehicle = 1:Nvehicles
    lane = randi(randomStream, 3);
    startX = -150 + 600*rand(randomStream);
    speed = 8 + 7*rand(randomStream);
    x = startX + direction(lane)*speed*timeSteps;
    yaw = (direction(lane)<0)*pi*ones(size(timeSteps));
    if rand(randomStream) < 0.125
        vehicleSize = repmat([12 2.5 3.8], numel(timeSteps), 1);
    else
        vehicleSize = nan(numel(timeSteps), 3);
    end
    rows{ith_vehicle} = [ith_vehicle*ones(size(timeSteps)), timeSteps, x, laneY(lane)*ones(size(timeSteps)), yaw, vehicleSize];
end
allRows = vertcat(rows{:});
trafficTable = array2table(allRows, 'VariableNames', {'id','time','X','Y','yaw','length','width','height'});
writetable(trafficTable, fileName);
end % Ends fcn_INTERNAL_writeDemoTraffic

%% fcn_INTERNAL_setCaption
function fcn_INTERNAL_setCaption(figureHandle, captionText)
% A caption at the top of the figure. (An axes title can fall outside the
% figure when the camera is placed by hand, as in these animations.)
caption = findall(figureHandle, 'Type','textboxshape', 'Tag','AnimateCar3D caption');
if isempty(caption)
    annotation(figureHandle, 'textbox', [0 0.88 1 0.12], 'String', captionText, 'Tag', 'AnimateCar3D caption', ...
        'EdgeColor','none', 'HorizontalAlignment','center', 'VerticalAlignment','middle', 'FontSize', 11, ...
        'Interpreter','none');
else
    set(caption(1), 'String', captionText);
end
end % Ends fcn_INTERNAL_setCaption

%% fcn_INTERNAL_saveGifFrameFixedColors
function fcn_INTERNAL_saveGifFrameFixedColors(figureHandle, fileName, frameNumber, colorMap, delayTime)
% Like fcn_CarMesh3D_saveGifFrame, but with one fixed color map for every
% frame, so that small colored details keep their colors
frame = getframe(figureHandle);
indexedImage = rgb2ind(frame.cdata, colorMap, 'nodither');
if frameNumber==1
    imwrite(indexedImage, colorMap, fileName, 'gif', 'LoopCount', Inf, 'DelayTime', delayTime);
else
    imwrite(indexedImage, colorMap, fileName, 'gif', 'WriteMode', 'append', 'DelayTime', delayTime);
end
end % Ends fcn_INTERNAL_saveGifFrameFixedColors

%% function fcn_INTERNAL_clearUtilitiesFromPathAndFolders
function fcn_INTERNAL_clearUtilitiesFromPathAndFolders
% Clear out the variables
clear global flag* FLAG*
clear flag*
clear path

% Clear out any path directories under Utilities
path_dirs = regexp(path,'[;]','split');
utilities_dir = fullfile(pwd,filesep,'Utilities');
for ith_dir = 1:length(path_dirs)
    utility_flag = strfind(path_dirs{ith_dir},utilities_dir);
    if ~isempty(utility_flag)
        rmpath(path_dirs{ith_dir});
    end
end

% Delete the Utilities folder, to be extra clean!
if  exist(utilities_dir,'dir')
    [status,message,message_ID] = rmdir(utilities_dir,'s');
    if 0==status
        error('Unable remove directory: %s \nReason message: %s \nand message_ID: %s\n',utilities_dir, message,message_ID);
    end
end

end % Ends fcn_INTERNAL_clearUtilitiesFromPathAndFolders

%% function fcn_INTERNAL_checkForPriorDebugInstall
function [flag_previousInstallFound, func_handle_addSubdirectoriesToPath, func_handle_autoInstallRepos, func_handle_isThisComputerOnline] = fcn_INTERNAL_checkForPriorDebugInstall

% Initialize default outputs
flag_previousInstallFound = false;
func_handle_addSubdirectoriesToPath = [];
func_handle_autoInstallRepos  = [];
func_handle_isThisComputerOnline  = [];

% Navigate to the Utilities directory
utilitiesFolderSearch = fullfile(pwd,'Utilities');
if exist(utilitiesFolderSearch,'dir')
	dirCommand = fullfile(utilitiesFolderSearch,'DebugTools*.');
	debugsInstalled = dir(dirCommand);

	% Were any DebugTools installs found?
	if ~isempty(debugsInstalled)
		flag_previousInstallFound = true; % Mark flag that it was found
		mostRecentDebugInstall = fullfile(debugsInstalled(end).folder,debugsInstalled(end).name,'Functions');

		currentFolder = pwd; % Save the current folder

		cd(mostRecentDebugInstall); % Move into the utilities folder

		% Create a function handles
		func_handle_addSubdirectoriesToPath = @fcn_DebugTools_addSubdirectoriesToPath;
		func_handle_autoInstallRepos = @fcn_DebugTools_autoInstallRepos;
		func_handle_isThisComputerOnline = @fcn_DebugTools_isThisComputerOnline;

		% Return to the root directory
		cd(currentFolder);
	end
end
end % Ends fcn_INTERNAL_checkForPriorDebugInstall


%% function fcn_INTERNAL_checkForAutoinstall
function [flag_previousInstallFound, func_handle_autoInstallRepos] = fcn_INTERNAL_checkForAutoinstall

flag_previousInstallFound = false;

% Navigate to the Utilities directory
autoinstallFolderSearch = fullfile(pwd,'Installer');
if exist(autoinstallFolderSearch,'dir')
	flag_previousInstallFound = true;% Set flag to indicate it was found
	currentFolder = pwd; % Save the current folder
	cd(autoinstallFolderSearch); % Move into the Installer folder
	func_handle_autoInstallRepos = @fcn_DebugTools_autoInstallRepos; % Create function handle
	cd(currentFolder); % Return to the root directory
end
end % fcn_INTERNAL_checkForAutoinstall


%% fcn_INTERNAL_selectCarMesh3DCopy
function carMesh3DRoot = fcn_INTERNAL_selectCarMesh3DCopy(flag_useWorkingCopy, workingFolder)
% Removes every CarMesh3D folder from the MATLAB path, then adds back only
% the chosen copy: the newest release in Utilities (CarMesh3D_<date>), or
% a working copy. Checks that MATLAB then finds exactly one copy of the
% CarMesh3D functions, and returns the root folder of that copy.
%
% A path entry belongs to a CarMesh3D copy if one of its folder names is
% CarMesh3D or starts with CarMesh3D_ (as releases in Utilities do).

% Which copy?
if flag_useWorkingCopy
	if isempty(workingFolder)
		workingFolder = getenv('ANIMATECAR3D_CARMESH3D_PATH');
	end
	if isempty(workingFolder)
		workingFolder = fullfile(fileparts(pwd),'CarMesh3D');
	end
	carMesh3DRoot = char(workingFolder);
	sourceDescription = 'working copy';
else
	releases = dir(fullfile(pwd,'Utilities','CarMesh3D_*'));
	releases = releases([releases.isdir]);
	if isempty(releases)
		error('No CarMesh3D release was found in %s. Run this script while online so that it can be installed.', fullfile(pwd,'Utilities'));
	end
	releaseNames = sort({releases.name});   % Dated names, so the last is the newest
	carMesh3DRoot = fullfile(pwd,'Utilities',releaseNames{end});
	sourceDescription = sprintf('release %s', releaseNames{end});
end
if ~isfolder(fullfile(carMesh3DRoot,'Functions'))
	error('The CarMesh3D folder %s has no Functions folder. Check the folder name.', carMesh3DRoot);
end

% Remove every CarMesh3D folder from the path
pathEntries = strsplit(path, pathsep);
flagCarMesh3D = false(size(pathEntries));
for ith_entry = 1:length(pathEntries)
	folderNames = regexp(pathEntries{ith_entry}, '[\\/]', 'split');
	flagCarMesh3D(ith_entry) = any(strcmp(folderNames,'CarMesh3D') | startsWith(folderNames,'CarMesh3D_'));
end
if any(flagCarMesh3D)
	rmpath(pathEntries{flagCarMesh3D});
end

% Add back only the chosen copy
addpath(genpath(fullfile(carMesh3DRoot,'Functions')));
if isfolder(fullfile(carMesh3DRoot,'Data'))
	addpath(genpath(fullfile(carMesh3DRoot,'Data')));
end

% Check that exactly one copy is found
foundCopies = which('fcn_CarMesh3D_plotVehicle','-all');
if length(foundCopies)~=1 || ~startsWith(foundCopies{1}, carMesh3DRoot)
	error('Expected exactly one copy of CarMesh3D, from %s, but found:\n%s', carMesh3DRoot, strjoin(foundCopies, newline));
end
fprintf(1,'CarMesh3D: using the %s (%s)\n', sourceDescription, carMesh3DRoot);

% Let AnimateCar3D functions and tests know which copy is in use
setenv('MATLABFLAG_ANIMATECAR3D_CARMESH3D_ROOT', carMesh3DRoot);
end % Ends fcn_INTERNAL_selectCarMesh3DCopy


%% fcn_INTERNAL_setupWorkspace
function fcn_INTERNAL_setupWorkspace 

%% Install dependencies
% Define a universal resource locator (URL) pointing to the repos of
% dependencies to install. Note that DebugTools is always installed
% automatically, first, even if not listed:
ith_repo = 0;



ith_repo = ith_repo+1;
dependencyURLs{ith_repo} = 'https://github.com/ivsg-psu/VehicleSimulations_VehiclePlotting_CarMesh3D';
dependencySubfolders{ith_repo} = {'Functions','Data'};
dependencyInstallRootName{ith_repo} = 'CarMesh3D';
dependencySubdependencyRootNames{ith_repo} = {}; %#ok<NASGU>

% Check if prior installs exist
[flag_previousDebugFound, func_handle_addSubdirectoriesToPath, func_handle_autoInstallReposDebug, func_handle_isThisComputerOnline] = fcn_INTERNAL_checkForPriorDebugInstall;
[flag_previousAutoinstallFound, func_handle_autoInstallReposAutoinstall] = fcn_INTERNAL_checkForAutoinstall;

if ~flag_previousDebugFound && ~flag_previousAutoinstallFound
	error('Installers are missing. Irrecoverable error!');
else
	% Decide which autoInstaller to use, defaulting to the most recent
	% one
	if flag_previousDebugFound
		func_handle_autoInstallRepos = func_handle_autoInstallReposDebug;
	else
		func_handle_autoInstallRepos = func_handle_autoInstallReposAutoinstall;
	end
end

% Check if online?
if flag_previousDebugFound
	flag_isOnline = func_handle_isThisComputerOnline();
else
	flag_isOnline = true; % Default to assuming online
end

% If computer is onffline, install folders manually
if ~flag_isOnline
	fprintf(1,'This computer appears to be offline. The code will be run with libraries that are already installed. However, any updates to these libraries including bug fixes may be missed. Use code with caution!\n');
	fprintf(1,'Press any key to continue.\n');
	% pause;

	if ~flag_previousDebugFound
		error('Computer appears offline and no prior installs found of debug folders. A prior install of this folder is needed to proceed. Quitting.');
	end
	pathToSearch = fullfile(pwd,'Utilities');
	subfolders = dir(pathToSearch);
	subfolders = subfolders([subfolders.isdir]);
	namedSubfolders = subfolders(~ismember({subfolders.name},{'.','..'}));
	existingFolderNameList = {namedSubfolders.name}';

	dependencyInstallRootName = [{'DebugTools'},dependencyInstallRootName(:)']';
	dependencySubfolders      = [{{'Functions','Data'}},dependencySubfolders(:)']';
	% Add each locally available dependency to the MATLAB path
	for ith_repo = 1:length(dependencyInstallRootName)
		thisRootName = dependencyInstallRootName{ith_repo};

		if ~contains(existingFolderNameList,thisRootName)
			error('A required dependency, named %.s, was not found among the packages already installed in the Utilities folder. A prior install of this folder is needed to proceed. Quitting.',thisRootName);
		else
			folderIndexToAdd = find(contains(existingFolderNameList,thisRootName),1);
		end

		fprintf(1,'\tAdding already installed library to the path: %s\n',namedSubfolders(folderIndexToAdd).name);
		thisFolderRoot = fullfile(namedSubfolders(folderIndexToAdd).folder,namedSubfolders(folderIndexToAdd).name);
		func_handle_addSubdirectoriesToPath(thisFolderRoot,dependencySubfolders{ith_repo});
	end

else
	% Clear prior global variable flags
	clear global FLAG_*

	% Call the function to do the install
	func_handle_autoInstallRepos(dependencyURLs, dependencySubfolders, (0), (-1));
end

% Add this function's folders to the path
this_project_folders = {...
	'Functions','Data'};
fprintf(1,'\tAdding this project folders to the path: \n');
for ith_folder = 1:length(this_project_folders)
	thisFolder = this_project_folders{ith_folder};
	fprintf(1,'\t\tAdding subfolder: %s\n',thisFolder);
end
fcn_DebugTools_addSubdirectoriesToPath(pwd,this_project_folders)


%% Set environment flags for input checking in AnimateCar3D library
% These are values to set if we want to check inputs or do debugging
setenv('MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS','1');
setenv('MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG','0');

%% Set up warnings
thisVersion = version('-release');
thisVersionYear = str2double(thisVersion(1:4));

% Confirm that this is 2025b
if ~strcmpi(thisVersion,'2025b')

	% Save current backtrace state, turn it off, issue the warning, then restore
	saved = warning("query","backtrace");
	warning("off","backtrace");
	if thisVersionYear<2025
		warning('Expected release versions 2025a or 2025b, but found older release %s instead.',thisVersion);
		fcn_DebugTools_cprintf('*red','Many errors may be introduced by using an older MATLAB version.\n Students using out-of-date versions are far more likely to face additional challenges in completing assignments.\n');
    elseif thisVersionYear>2025
		warning('Expected release versions 2025a or 2025b, but found newer release %s instead.',thisVersion);
		fcn_DebugTools_cprintf('*red','Newer versions have not been tested yet but should work.\nStudents are asked to report any code discrepancies so that the code can remain up-to-date!.\n');
	end
	warning(saved);
	fprintf(1,'Press any key to continue.\n');
	pause;
end

thisPath = pwd;

% Confirm that path contains no spaces
if contains(thisPath,' ')
	warning('A space character was found in the working path: %s. Spaces in file names and paths can cause evaluation errors in some of the functions within this code set.',thisPath);
	fcn_DebugTools_cprintf('*red','Please consider installing the code into a folder that has no spaces.');
	fprintf(1,'Press any key to continue.\n');
	pause;
end

% Confirm that path contains no minus signs
if contains(thisPath,'-')
	warning('A minus character was found in the working path: %s. Minus signs in file names and paths will cause evaluation errors in some of the functions within this code set.',thisPath);
	fcn_DebugTools_cprintf('*red','Please re-install the code into a folder that has no minus signs in the path name.');
	fprintf(1,'Press any key to continue.\n');
	pause;
end


% %% Create Submissions folder
% if ~exist(fullfile(pwd,'Submissions'),'dir')
% 	mkdir('Submissions');
% end
% 
% %% Create StudentWork folder
% if ~exist(fullfile(pwd,'StudentWork'),'dir')
% 	mkdir('StudentWork');
% end

end % Ends fcn_INTERNAL_setupWorkspace

