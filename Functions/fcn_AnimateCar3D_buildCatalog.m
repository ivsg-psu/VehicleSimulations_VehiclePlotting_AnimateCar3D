function catalog = fcn_AnimateCar3D_buildCatalog(sceneList, options)
% fcn_AnimateCar3D_buildCatalog

% Builds the object catalog: a record of every object in a scene, saying
% what it is, when it exists, and where it is, organized so that the
% selector can find the objects near any place at any time quickly, even
% with thousands of objects.
%
% For each moving object the catalog keeps a thinned path (one pose every
% ThinStep seconds) rather than its full motion. Full motions are kept in
% memory only when given in memory, or for the roles in KeepRoles (and
% for branches), which the selector always shows; other objects' motion
% files are read by the selector only when it draws them in detail.
%
% The grid: time is cut into windows of TimeWindow seconds, and the
% ground into square cells of CellSize meters. For each window, each cell
% lists the objects whose path passes through it (with a margin of the
% object's length). Static objects have their own grid, without time.
%
% FORMAT:
%
%       catalog = fcn_AnimateCar3D_buildCatalog(sceneList,...
%           (Motions=motions), (StaticScene=staticScene),...
%           (CellSize=meters), (TimeWindow=seconds), (ThinStep=seconds),...
%           (KeepRoles=roles), (CacheFile=fileName), (FigNum=figNum))
%
% INPUTS:
%
%      sceneList: from fcn_AnimateCar3D_loadSceneList (or
%      fcn_AnimateCar3D_loadTrafficFile). Every object needs a motion:
%      a MotionFile, or an entry in Motions.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Motions: a structure array of motions in memory, matched to the
%      scene list by their Instance field. Each needs Time (K x 1) and
%      Pose (K x 3 [x y yaw] or K x 6); it may also have WheelSpin
%      (K x 4, [FL FR RL RR]), SteerAngle (K x 2), WheelLift (K x 4),
%      BodyRoll, BodyPitch, BodyHeave (K x 1), and LightStates (K x 1
%      structure array), as from fcn_CarMesh3D_loadMotionCSV or
%      fcn_AnimateCar3D_fillBranchMotions.
%
%      StaticScene: from fcn_AnimateCar3D_loadStaticScene.
%
%      CellSize: grid cell size, meters. Default 25.
%
%      TimeWindow: grid time window, seconds. Default 1.
%
%      ThinStep: seconds between the thinned path's poses. Default 0.5.
%
%      KeepRoles: roles whose full motions are kept in memory. Default
%      {'ego','confederate'}. Branches are always kept.
%
%      CacheFile: a .mat file to save the catalog in. If it exists and
%      was built from the same inputs (same objects, motions, files and
%      their dates, and settings), it is loaded instead of rebuilt.
%      Default '' (no cache).
%
%      FigNum: a figure number to plot the paths, static objects, and the
%      grid from above. Empty (default) for no figure; -1 for fast mode
%      (no input checks).
%
% OUTPUTS:
%
%      catalog: a structure with fields
%           Objects: one entry per object (moving, then static), with the
%               scene list fields plus IsStatic, StartTime, EndTime (scene
%               time), ThinTime, ThinPose (K x 6), MotionIndex (into
%               Motions; 0 if not in memory), HasBranches, BranchStart
%               (when its first branch splits; Inf if none)
%           Motions: the full motions kept in memory (Pose made K x 6)
%           Grid, StaticGrid: the grids (containers.Map from a cell key to
%               object indices; see fcn_INTERNAL_cellKey)
%           CellSize, TimeWindow, TimeStart, TimeEnd, ThinStep
%           Signature: what the catalog was built from (for the cache)
%           FromCache: true if it was loaded from CacheFile
%
% DEPENDENCIES:
%
%      CarMesh3D: fcn_CarMesh3D_loadMotionCSV (objects with a MotionFile)
%
% EXAMPLES:
%
%       catalog = fcn_AnimateCar3D_buildCatalog(sceneList, Motions=motions, StaticScene=staticScene, FigNum=1);
%
%       See the script: script_test_fcn_AnimateCar3D_buildCatalog.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_buildCatalog
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_buildCatalog
%   % * Grow the catalog while running (watched-folder updates, step 3)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    sceneList
    options.Motions = []                    % motions in memory, matched by Instance
    options.StaticScene = []                % from fcn_AnimateCar3D_loadStaticScene
    options.CellSize = 25                   % meters
    options.TimeWindow = 1                  % seconds
    options.ThinStep = 0.5                  % seconds between thinned poses
    options.KeepRoles = {'ego','confederate'}   % full motions kept in memory
    options.CacheFile = ''                  % .mat file; '' for no cache
    options.FigNum = []                     % figure to plot from above; -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_ANIMATECAR3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above


        % Check the sceneList input
        if ~isstruct(sceneList) || ~all(isfield(sceneList, {'Instance','Role','MeshID','MotionFile'}))
            error('sceneList must come from fcn_AnimateCar3D_loadSceneList');
        end

        % Check the Motions input
        if ~isempty(options.Motions) && (~isstruct(options.Motions) || ~all(isfield(options.Motions, {'Instance','Time','Pose'})))
            error('Motions must be a structure array with Instance, Time, and Pose fields');
        end

        % Check the StaticScene input
        if ~isempty(options.StaticScene) && (~isstruct(options.StaticScene) || ~all(isfield(options.StaticScene, {'Instance','MeshID','Pose','Size','Color'})))
            error('StaticScene must come from fcn_AnimateCar3D_loadStaticScene');
        end

        % Check the numeric settings
        settingNames = {'CellSize','TimeWindow','ThinStep'};
        for ith_setting = 1:numel(settingNames)
            thisValue = options.(settingNames{ith_setting});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || thisValue<=0
                error('%s must be a positive number', settingNames{ith_setting});
            end
        end

        % Check the KeepRoles and CacheFile inputs
        if ~(iscellstr(options.KeepRoles) || ischar(options.KeepRoles) || isstring(options.KeepRoles))
            error('KeepRoles must be a cell array of role names');
        end
        if ~(ischar(options.CacheFile) || isstring(options.CacheFile))
            error('CacheFile must be a file name');
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
        flag_do_plots = 1;
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


sceneList = sceneList(:);
keepRoles = cellstr(options.KeepRoles);
cacheFile = char(options.CacheFile);

% What the catalog is built from (for the cache)
signature = fcn_INTERNAL_signature(sceneList, options.Motions, options.StaticScene, ...
    [options.CellSize options.TimeWindow options.ThinStep], keepRoles);
if ~isempty(cacheFile) && isfile(cacheFile)
    cached = load(cacheFile, 'catalog');
    if isfield(cached,'catalog') && isequaln(cached.catalog.Signature, signature)
        catalog = cached.catalog;
        catalog.FromCache = true;
        return;
    end
end

% Match the motions in memory to the scene list
motionNames = {};
if ~isempty(options.Motions)
    motionNames = {options.Motions.Instance};
end
Nmoving = numel(sceneList);
staticScene = options.StaticScene(:);
Nstatic = numel(staticScene);

% Which objects have branches, and when the first branch splits
branchParents = {sceneList.BranchOf};

catalog = struct;
catalog.Motions = repmat(fcn_INTERNAL_emptyMotion, 0, 1);
objects = repmat(fcn_INTERNAL_emptyObject, Nmoving + Nstatic, 1);

%%%% Moving objects
for ith_object = 1:Nmoving
    row = sceneList(ith_object);
    thisObject = fcn_INTERNAL_emptyObject;
    for fieldName = {'Instance','Role','MeshID','MotionFile','BranchOf','BranchID','SplitTime','RespondsTo','Color','Alpha','TimeOffset','Size'}
        thisObject.(fieldName{1}) = row.(fieldName{1});
    end

    % Its full motion: from memory, or read from its file
    memoryIndex = find(strcmp(motionNames, row.Instance), 1);
    if ~isempty(memoryIndex)
        motion = fcn_INTERNAL_normalizeMotion(options.Motions(memoryIndex));
    elseif ~isempty(row.MotionFile)
        if ~isfile(row.MotionFile)
            error('Motion file not found for %s: %s', row.Instance, row.MotionFile);
        end
        motion = fcn_INTERNAL_normalizeMotion(fcn_CarMesh3D_loadMotionCSV(row.MotionFile, FigNum=-1));
    else
        error('The object %s has no motion: give it a motionFile, or a motion in Motions', row.Instance);
    end
    if numel(motion.Time) < 1
        error('The motion of %s is empty', row.Instance);
    end

    % Times in the scene's clock
    sceneTime = motion.Time + row.TimeOffset;
    thisObject.StartTime = sceneTime(1);
    thisObject.EndTime = sceneTime(end);

    % The thinned path
    thinTime = (thisObject.StartTime:options.ThinStep:thisObject.EndTime)';
    if isempty(thinTime) || thinTime(end) < thisObject.EndTime - 1e-9
        thinTime(end+1,1) = thisObject.EndTime; %#ok<AGROW>
    end
    thisObject.ThinTime = thinTime;
    thisObject.ThinPose = fcn_INTERNAL_interpolatePose(sceneTime, motion.Pose, thinTime);

    % Keep the full motion in memory?
    flagKeep = ~isempty(memoryIndex) || any(strcmp(row.Role, keepRoles)) || ~isempty(row.BranchOf) ...
        || any(strcmp(branchParents, row.Instance));
    if flagKeep
        catalog.Motions(end+1,1) = motion;
        thisObject.MotionIndex = numel(catalog.Motions);
    end
    objects(ith_object) = thisObject;
end

% Branch links: each parent's first split
for ith_object = 1:Nmoving
    childRows = find(strcmp(branchParents, objects(ith_object).Instance));
    if ~isempty(childRows)
        objects(ith_object).HasBranches = true;
        splitTimes = [objects(childRows).SplitTime];
        childStarts = [objects(childRows).StartTime];
        splitTimes(isnan(splitTimes)) = childStarts(isnan(splitTimes));
        objects(ith_object).BranchStart = min(splitTimes);
    end
end
for ith_object = 1:Nmoving
    if ~isempty(objects(ith_object).BranchOf) && isnan(objects(ith_object).SplitTime)
        objects(ith_object).SplitTime = objects(ith_object).StartTime;
    end
end

%%%% Static objects
for ith_static = 1:Nstatic
    thisStatic = staticScene(ith_static);
    thisObject = fcn_INTERNAL_emptyObject;
    thisObject.Instance = thisStatic.Instance;
    thisObject.Role = 'static';
    thisObject.MeshID = thisStatic.MeshID;
    thisObject.Color = thisStatic.Color;
    thisObject.Size = thisStatic.Size;
    thisObject.IsStatic = true;
    thisObject.StartTime = -Inf;
    thisObject.EndTime = Inf;
    thisObject.ThinTime = 0;
    thisObject.ThinPose = thisStatic.Pose;
    objects(Nmoving + ith_static) = thisObject;
end
allNames = {objects.Instance};
if numel(unique(allNames)) ~= numel(allNames)
    error('Instance names must be unique across the scene list and the static scene');
end

%%%% The grids
cellSize = options.CellSize;
timeWindow = options.TimeWindow;
if Nmoving>0
    timeStart = min([objects(1:Nmoving).StartTime]);
    timeEnd = max([objects(1:Nmoving).EndTime]);
else
    timeStart = 0;
    timeEnd = 0;
end
gridKeys = zeros(0,1);
gridIndices = zeros(0,1);
for ith_object = 1:Nmoving
    thisObject = objects(ith_object);
    margin = max(5, fcn_INTERNAL_objectLength(thisObject));
    firstWindow = floor((thisObject.StartTime - timeStart)/timeWindow);
    lastWindow = floor((thisObject.EndTime - timeStart)/timeWindow);
    for windowNumber = firstWindow:lastWindow
        windowStart = max(thisObject.StartTime, timeStart + windowNumber*timeWindow);
        windowEnd = min(thisObject.EndTime, timeStart + (windowNumber+1)*timeWindow);
        inside = thisObject.ThinTime > windowStart & thisObject.ThinTime < windowEnd;
        edgePoses = fcn_INTERNAL_interpolatePose(thisObject.ThinTime, thisObject.ThinPose, [windowStart; windowEnd]);
        windowXY = [edgePoses(:,1:2); thisObject.ThinPose(inside,1:2)];
        cellRange = floor([min(windowXY,[],1)-margin; max(windowXY,[],1)+margin]/cellSize);
        [cellX, cellY] = ndgrid(cellRange(1,1):cellRange(2,1), cellRange(1,2):cellRange(2,2));
        newKeys = fcn_INTERNAL_cellKey(windowNumber*ones(numel(cellX),1), cellX(:), cellY(:));
        gridKeys = [gridKeys; newKeys]; %#ok<AGROW>
        gridIndices = [gridIndices; ith_object*ones(numel(newKeys),1)]; %#ok<AGROW>
    end
end
catalog.Grid = fcn_INTERNAL_makeMap(gridKeys, gridIndices);

staticKeys = zeros(0,1);
staticIndices = zeros(0,1);
for ith_object = Nmoving+1:Nmoving+Nstatic
    thisObject = objects(ith_object);
    halfSize = norm(thisObject.Size(1:2))/2;
    cellRange = floor([thisObject.ThinPose(1:2)-halfSize; thisObject.ThinPose(1:2)+halfSize]/cellSize);
    [cellX, cellY] = ndgrid(cellRange(1,1):cellRange(2,1), cellRange(1,2):cellRange(2,2));
    newKeys = fcn_INTERNAL_cellKey(zeros(numel(cellX),1), cellX(:), cellY(:));
    staticKeys = [staticKeys; newKeys]; %#ok<AGROW>
    staticIndices = [staticIndices; ith_object*ones(numel(newKeys),1)]; %#ok<AGROW>
end
catalog.StaticGrid = fcn_INTERNAL_makeMap(staticKeys, staticIndices);

catalog.Objects = objects;
catalog.CellSize = cellSize;
catalog.TimeWindow = timeWindow;
catalog.TimeStart = timeStart;
catalog.TimeEnd = timeEnd;
catalog.ThinStep = options.ThinStep;
catalog.Signature = signature;
catalog.FromCache = false;

if ~isempty(cacheFile)
    save(cacheFile, 'catalog');
end

%% Plot the results (for debugging)?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots

    figure(figNum);
    clf;
    hold on;
    roleNames = {'ego','traffic','confederate','pedestrian','movingItem'};
    roleColors = [0.05 0.2 0.6; 0.5 0.5 0.5; 0.85 0.15 0.1; 0.1 0.6 0.2; 0.6 0.3 0.7];
    legendHandles = gobjects(0);
    legendNames = {};
    for ith_role = 1:numel(roleNames)
        rows = find(strcmp({catalog.Objects.Role}, roleNames{ith_role}));
        firstHandle = gobjects(0);
        for thisRow = rows
            lineHandle = plot(catalog.Objects(thisRow).ThinPose(:,1), catalog.Objects(thisRow).ThinPose(:,2), '-', ...
                'Color', roleColors(ith_role,:), 'LineWidth', 1 + strcmp(roleNames{ith_role},'ego'));
            if isempty(firstHandle)
                firstHandle = lineHandle;
            end
        end
        if ~isempty(firstHandle)
            legendHandles(end+1) = firstHandle; %#ok<AGROW>
            legendNames{end+1} = sprintf('%s (%d)', roleNames{ith_role}, numel(rows)); %#ok<AGROW>
        end
    end
    staticRows = find([catalog.Objects.IsStatic]);
    if ~isempty(staticRows)
        staticPoses = reshape([catalog.Objects(staticRows).ThinPose],6,[])';
        legendHandles(end+1) = plot(staticPoses(:,1), staticPoses(:,2), 's', 'Color', [0.4 0.4 0.4], 'MarkerSize', 4);
        legendNames{end+1} = sprintf('static (%d)', numel(staticRows));
    end
    axis equal;
    grid on;
    set(gca, 'XTick', catalog.CellSize*ceil(min(xlim)/catalog.CellSize):catalog.CellSize*2:max(xlim));
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('Object catalog: %d objects, %d grid entries, %.1f to %.1f s', numel(catalog.Objects), ...
        catalog.Grid.Count, catalog.TimeStart, catalog.TimeEnd));
    if ~isempty(legendHandles)
        legend(legendHandles, legendNames, 'Location', 'bestoutside');
    end
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_emptyObject
function thisObject = fcn_INTERNAL_emptyObject
% One catalog object, with every field
thisObject = struct('Instance','', 'Role','', 'MeshID','', 'MotionFile','', 'BranchOf','', ...
    'BranchID',0, 'SplitTime',NaN, 'RespondsTo','', 'Color',nan(1,3), 'Alpha',NaN, ...
    'TimeOffset',0, 'Size',nan(1,3), 'IsStatic',false, 'StartTime',0, 'EndTime',0, ...
    'ThinTime',zeros(0,1), 'ThinPose',zeros(0,6), 'MotionIndex',0, 'HasBranches',false, 'BranchStart',Inf);
end % Ends fcn_INTERNAL_emptyObject

%% fcn_INTERNAL_emptyMotion
function motion = fcn_INTERNAL_emptyMotion
% One full motion, with every field the selector reads
motion = struct('Time',zeros(0,1), 'Pose',zeros(0,6), 'WheelSpin',[], 'SteerAngle',[], ...
    'WheelLift',[], 'BodyRoll',[], 'BodyPitch',[], 'BodyHeave',[], 'LightStates',[]);
end % Ends fcn_INTERNAL_emptyMotion

%% fcn_INTERNAL_normalizeMotion
function motion = fcn_INTERNAL_normalizeMotion(inputMotion)
% Copy the fields the selector reads; make Pose K x 6 and Time K x 1
motion = fcn_INTERNAL_emptyMotion;
motion.Time = double(inputMotion.Time(:));
pose = double(inputMotion.Pose);
if size(pose,2)==3
    pose = [pose(:,1:2), zeros(size(pose,1),3), pose(:,3)];
end
motion.Pose = pose;
for fieldName = {'WheelSpin','SteerAngle','WheelLift','BodyRoll','BodyPitch','BodyHeave','LightStates'}
    if isfield(inputMotion, fieldName{1})
        motion.(fieldName{1}) = inputMotion.(fieldName{1});
    end
end
end % Ends fcn_INTERNAL_normalizeMotion

%% fcn_INTERNAL_interpolatePose
function poses = fcn_INTERNAL_interpolatePose(times, posesIn, queryTimes)
% Linear interpolation of K x 6 poses (yaw, roll, pitch along the
% shorter way round), held at the ends
queryTimes = min(max(queryTimes(:), times(1)), times(end));
if numel(times)==1
    poses = repmat(posesIn, numel(queryTimes), 1);
    return;
end
angles = unwrap(posesIn(:,4:6));
poses = [interp1(times, posesIn(:,1:3), queryTimes, 'linear'), interp1(times, angles, queryTimes, 'linear')];
poses = reshape(poses, numel(queryTimes), 6);
end % Ends fcn_INTERNAL_interpolatePose

%% fcn_INTERNAL_objectLength
function objectLength = fcn_INTERNAL_objectLength(thisObject)
% The object's length if known, otherwise a typical car's
objectLength = thisObject.Size(1);
if isnan(objectLength)
    objectLength = 5;
end
end % Ends fcn_INTERNAL_objectLength

%% fcn_INTERNAL_cellKey
function keys = fcn_INTERNAL_cellKey(windowNumbers, cellX, cellY)
% One number per (time window, cell x, cell y): exact in a double for up
% to 900000 windows and cells within 1250 km (at 25 m) of the origin
keys = windowNumbers(:)*1e10 + (cellX(:)+5e4)*1e5 + (cellY(:)+5e4);
end % Ends fcn_INTERNAL_cellKey

%% fcn_INTERNAL_makeMap
function gridMap = fcn_INTERNAL_makeMap(keys, indices)
% A map from each key to the (unique, sorted) object indices with it
if isempty(keys)
    gridMap = containers.Map('KeyType','double','ValueType','any');
    return;
end
[uniqueKeys, ~, group] = unique(keys);
groupedIndices = accumarray(group, indices, [numel(uniqueKeys) 1], @(v) {unique(v)'});
gridMap = containers.Map(uniqueKeys', groupedIndices', 'UniformValues', false);
end % Ends fcn_INTERNAL_makeMap

%% fcn_INTERNAL_signature
function signature = fcn_INTERNAL_signature(sceneList, motions, staticScene, settings, keepRoles)
% A summary of the inputs: same summary, same catalog
signature = struct;
signature.Instances = {sceneList.Instance};
signature.SceneFields = {{sceneList.Role}, {sceneList.MeshID}, {sceneList.BranchOf}, [sceneList.BranchID], ...
    {sceneList.RespondsTo}, [sceneList.TimeOffset], [sceneList.SplitTime], [sceneList.Color], [sceneList.Alpha], [sceneList.Size]};
fileDates = zeros(numel(sceneList),2);
for ith_row = 1:numel(sceneList)
    if ~isempty(sceneList(ith_row).MotionFile) && isfile(sceneList(ith_row).MotionFile)
        fileInfo = dir(sceneList(ith_row).MotionFile);
        fileDates(ith_row,:) = [fileInfo.datenum fileInfo.bytes];
    end
end
signature.Files = {{sceneList.MotionFile}, fileDates};
if isempty(motions)
    signature.Motions = 0;
else
    signature.Motions = [numel(motions), sum(arrayfun(@(m) sum(m.Time(:)) + sum(m.Pose(:)), motions))];
end
if isempty(staticScene)
    signature.Static = 0;
else
    signature.Static = [numel(staticScene), sum([staticScene.Pose]), sum([staticScene.Size])];
end
signature.Settings = settings;
signature.KeepRoles = keepRoles;
end % Ends fcn_INTERNAL_signature
