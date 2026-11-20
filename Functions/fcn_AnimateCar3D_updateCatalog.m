function [catalog, updateInfo, selectorState] = fcn_AnimateCar3D_updateCatalog(catalog, options)
% fcn_AnimateCar3D_updateCatalog

% Changes an object catalog while an animation runs: adds new moving
% objects, replaces objects whose motion has grown or changed, and removes
% objects. Only the changed objects' grid entries are touched, so an
% update is fast even in a large catalog. This is how live data (see
% fcn_AnimateCar3D_watchFolder) reaches the selector.
%
% Building a catalog all at once (fcn_AnimateCar3D_buildCatalog) and
% building it up with updates give the same objects and the same grid.
%
% FORMAT:
%
%       [catalog, updateInfo, selectorState] = fcn_AnimateCar3D_updateCatalog(catalog,...
%           (Add=sceneRows), (Motions=motions), (Remove=instances),...
%           (SelectorState=selectorState), (CellSize=meters),...
%           (TimeWindow=seconds), (ThinStep=seconds), (KeepRoles=roles),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      catalog: from fcn_AnimateCar3D_buildCatalog or from an earlier
%      call to this function; or [] to start an empty catalog (with the
%      CellSize, TimeWindow, and ThinStep options).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Add: scene list rows (from fcn_AnimateCar3D_loadSceneList) of
%      moving objects to add. A row whose instance is already in the
%      catalog replaces that object. Each row needs a motion: an entry in
%      Motions, or a MotionFile; a row that replaces an object and has
%      neither keeps the object's motion (to change only its role, mesh,
%      color, and so on).
%
%      Motions: motions in memory for the added rows, matched by their
%      Instance field (as for fcn_AnimateCar3D_buildCatalog).
%
%      Remove: a cell array of instances to remove. Instances not in the
%      catalog are ignored.
%
%      SelectorState: the selector's state. Motions it has read from
%      files for changed or removed objects are dropped, so that it does
%      not draw an old motion. Returned as the third output.
%
%      CellSize, TimeWindow, ThinStep: grid settings for a new (empty)
%      catalog. Defaults 25 m, 1 s, and 0.5 s. Ignored for an existing
%      catalog, which keeps its own.
%
%      KeepRoles: roles whose full motions are kept in memory when read
%      from a file. Default {'ego','confederate'}. Motions given in
%      Motions are always kept.
%
%      FigNum: a figure number to plot the catalog's paths from above.
%      Empty (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      catalog: the changed catalog. Removed objects stay as empty slots
%      (they never exist, so the selector never finds them), so object
%      numbers do not change; an instance added again reuses its slot.
%      A new field, ObjectKeys, keeps each object's grid keys, so the
%      next update need not work them out again.
%
%      updateInfo: a structure with fields Added, Replaced, and Removed
%      (cell arrays of instances), NumGridChanges (grid entries added and
%      removed), and UpdateSeconds.
%
%      selectorState: the SelectorState input, with the changed objects'
%      motions dropped ([] if none was given).
%
% DEPENDENCIES:
%
%      CarMesh3D: fcn_CarMesh3D_loadMotionCSV (rows with a MotionFile)
%
% EXAMPLES:
%
%       catalog = fcn_AnimateCar3D_updateCatalog([], Add=sceneRows, Motions=motions);
%       [catalog, info, selectorState] = fcn_AnimateCar3D_updateCatalog(catalog, ...
%           Remove={'car7'}, SelectorState=selectorState);
%
%       See the script: script_test_fcn_AnimateCar3D_updateCatalog.m for
%       a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_updateCatalog
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_updateCatalog
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    catalog
    options.Add = []                        % scene list rows to add or replace
    options.Motions = []                    % motions in memory, matched by Instance
    options.Remove = {}                     % instances to remove
    options.SelectorState = []              % the selector's state
    options.CellSize = 25                   % meters (new catalog only)
    options.TimeWindow = 1                  % seconds (new catalog only)
    options.ThinStep = 0.5                  % seconds (new catalog only)
    options.KeepRoles = {'ego','confederate'}   % full motions kept in memory
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


        % Check the catalog input
        if ~isempty(catalog) && ~(isstruct(catalog) && all(isfield(catalog,{'Objects','Grid','StaticGrid','TimeStart'})))
            error('catalog must be [] or come from fcn_AnimateCar3D_buildCatalog');
        end

        % Check the Add and Motions inputs
        if ~isempty(options.Add) && ~(isstruct(options.Add) && all(isfield(options.Add,{'Instance','Role','MeshID','MotionFile'})))
            error('Add must be scene list rows (see fcn_AnimateCar3D_loadSceneList)');
        end
        if ~isempty(options.Motions) && ~(isstruct(options.Motions) && all(isfield(options.Motions,{'Instance','Time','Pose'})))
            error('Motions must be a structure array with fields Instance, Time, and Pose');
        end

        % Check the Remove input
        if ~(iscellstr(options.Remove) || ischar(options.Remove) || isstring(options.Remove))
            error('Remove must be a cell array of instance names');
        end

        % Check the grid settings
        gridSettings = [options.CellSize options.TimeWindow options.ThinStep];
        if ~(isnumeric(gridSettings) && numel(gridSettings)==3 && all(gridSettings>0))
            error('CellSize, TimeWindow, and ThinStep must be positive numbers');
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


updateTimer = tic;
keepRoles = cellstr(options.KeepRoles);
removeNames = cellstr(options.Remove);
addRows = options.Add;
if isempty(addRows)
    addRows = repmat(fcn_INTERNAL_emptyObject, 0, 1);
end
addRows = addRows(:);
selectorState = options.SelectorState;

% Start an empty catalog?
if isempty(catalog)
    catalog = struct;
    catalog.Motions = repmat(fcn_INTERNAL_emptyMotion, 0, 1);
    catalog.Grid = containers.Map('KeyType','double','ValueType','any');
    catalog.StaticGrid = containers.Map('KeyType','double','ValueType','any');
    catalog.Objects = repmat(fcn_INTERNAL_emptyObject, 0, 1);
    catalog.CellSize = options.CellSize;
    catalog.TimeWindow = options.TimeWindow;
    catalog.TimeStart = 0;
    catalog.TimeEnd = 0;
    catalog.ThinStep = options.ThinStep;
    catalog.Signature = struct('Live',true);
    catalog.FromCache = false;
end
objects = catalog.Objects;
gridMap = catalog.Grid;
numGridChanges = 0;

% Each object's grid keys, kept from earlier updates (worked out when
% missing, as for a catalog from fcn_AnimateCar3D_buildCatalog)
if ~isfield(catalog,'ObjectKeys') || numel(catalog.ObjectKeys)~=numel(objects)
    objectKeys = cell(numel(objects),1);
else
    objectKeys = catalog.ObjectKeys(:);
end

% Where each instance is now
nameToIndex = containers.Map('KeyType','char','ValueType','double');
for ith_object = 1:numel(objects)
    if ~isempty(objects(ith_object).Instance)
        nameToIndex(objects(ith_object).Instance) = ith_object;
    end
end
motionNames = {};
if ~isempty(options.Motions)
    motionNames = {options.Motions.Instance};
end

updateInfo = struct('Added',{cell(1,0)}, 'Replaced',{cell(1,0)}, 'Removed',{cell(1,0)}, ...
    'NumGridChanges',0, 'UpdateSeconds',0);
touchedParents = {};

%%%% Removals
for ith_name = 1:numel(removeNames)
    thisName = removeNames{ith_name};
    if ~isKey(nameToIndex, thisName)
        continue;
    end
    objectIndex = nameToIndex(thisName);
    if objects(objectIndex).IsStatic
        error('The static object %s cannot be removed by an update', thisName);
    end
    if fcn_INTERNAL_isEmptySlot(objects(objectIndex))
        continue;   % already removed
    end
    oldKeys = objectKeys{objectIndex};
    if isempty(oldKeys)
        oldKeys = fcn_INTERNAL_gridKeys(objects(objectIndex), catalog);
    end
    [gridMap, changes] = fcn_INTERNAL_changeGrid(gridMap, oldKeys, zeros(0,1), objectIndex);
    objectKeys{objectIndex} = zeros(0,1);
    numGridChanges = numGridChanges + changes;
    touchedParents{end+1} = objects(objectIndex).BranchOf; %#ok<AGROW>
    if objects(objectIndex).MotionIndex > 0
        catalog.Motions(objects(objectIndex).MotionIndex) = fcn_INTERNAL_emptyMotion;
    end
    objects(objectIndex) = fcn_INTERNAL_emptySlot(thisName);
    updateInfo.Removed{end+1} = thisName;
    selectorState = fcn_INTERNAL_forget(selectorState, thisName);
end

%%%% Additions and replacements
for ith_row = 1:numel(addRows)
    row = addRows(ith_row);
    thisName = row.Instance;
    flagExisting = isKey(nameToIndex, thisName);
    if flagExisting
        objectIndex = nameToIndex(thisName);
        oldObject = objects(objectIndex);
        if oldObject.IsStatic
            error('The static object %s cannot be replaced by an update', thisName);
        end
        flagWasEmpty = fcn_INTERNAL_isEmptySlot(oldObject);
    else
        objectIndex = numel(objects) + 1;
        oldObject = fcn_INTERNAL_emptySlot(thisName);
        flagWasEmpty = true;
        nameToIndex(thisName) = objectIndex;
    end

    thisObject = fcn_INTERNAL_emptyObject;
    for fieldName = {'Instance','Role','MeshID','MotionFile','BranchOf','BranchID','SplitTime','RespondsTo','Color','Alpha','TimeOffset','Size'}
        thisObject.(fieldName{1}) = row.(fieldName{1});
    end

    % Its motion: from memory, from its file, or the one it had
    memoryIndex = find(strcmp(motionNames, thisName), 1, 'last');
    flagKeep = false;
    if ~isempty(memoryIndex)
        motion = fcn_INTERNAL_normalizeMotion(options.Motions(memoryIndex));
        flagKeep = true;
    elseif ~isempty(row.MotionFile)
        if ~isfile(row.MotionFile)
            error('Motion file not found for %s: %s', thisName, row.MotionFile);
        end
        motion = fcn_INTERNAL_normalizeMotion(fcn_CarMesh3D_loadMotionCSV(row.MotionFile, FigNum=-1));
        flagKeep = any(strcmp(row.Role, keepRoles)) || ~isempty(row.BranchOf);
    elseif ~flagWasEmpty && oldObject.MotionIndex > 0
        motion = catalog.Motions(oldObject.MotionIndex);
        flagKeep = true;
    elseif ~flagWasEmpty && ~isempty(oldObject.MotionFile)
        motion = fcn_INTERNAL_normalizeMotion(fcn_CarMesh3D_loadMotionCSV(oldObject.MotionFile, FigNum=-1));
        thisObject.MotionFile = oldObject.MotionFile;
    else
        error('The object %s has no motion: give it a motionFile, or a motion in Motions', thisName);
    end
    if numel(motion.Time) < 1
        error('The motion of %s is empty', thisName);
    end

    % Times in the scene's clock, and the thinned path
    sceneTime = motion.Time + thisObject.TimeOffset;
    thisObject.StartTime = sceneTime(1);
    thisObject.EndTime = sceneTime(end);
    thinTime = (thisObject.StartTime:catalog.ThinStep:thisObject.EndTime)';
    if isempty(thinTime) || thinTime(end) < thisObject.EndTime - 1e-9
        thinTime(end+1,1) = thisObject.EndTime; %#ok<AGROW>
    end
    thisObject.ThinTime = thinTime;
    thisObject.ThinPose = fcn_INTERNAL_interpolatePose(sceneTime, motion.Pose, thinTime);

    % Keep the full motion in memory? Reuse the object's slot if it had one
    if flagKeep
        if ~flagWasEmpty && oldObject.MotionIndex > 0
            motionIndex = oldObject.MotionIndex;
        elseif oldObject.MotionIndex > 0
            motionIndex = oldObject.MotionIndex;
        else
            motionIndex = numel(catalog.Motions) + 1;
        end
        catalog.Motions(motionIndex,1) = motion;
        thisObject.MotionIndex = motionIndex;
    elseif oldObject.MotionIndex > 0
        catalog.Motions(oldObject.MotionIndex) = fcn_INTERNAL_emptyMotion;
    end

    % The grid: remove the keys it no longer has, add the new ones
    if flagWasEmpty
        oldKeys = zeros(0,1);
    elseif objectIndex <= numel(objectKeys) && ~isempty(objectKeys{objectIndex})
        oldKeys = objectKeys{objectIndex};
    else
        oldKeys = fcn_INTERNAL_gridKeys(oldObject, catalog);
    end
    newKeys = fcn_INTERNAL_gridKeys(thisObject, catalog);
    [gridMap, changes] = fcn_INTERNAL_changeGrid(gridMap, oldKeys, newKeys, objectIndex);
    objectKeys{objectIndex,1} = newKeys;
    numGridChanges = numGridChanges + changes;

    objects(objectIndex,1) = thisObject;
    catalog.TimeEnd = max(catalog.TimeEnd, thisObject.EndTime);
    touchedParents = [touchedParents, {thisObject.BranchOf, oldObject.BranchOf, thisName}]; %#ok<AGROW>
    if flagWasEmpty
        updateInfo.Added{end+1} = thisName;
    else
        updateInfo.Replaced{end+1} = thisName;
    end
    selectorState = fcn_INTERNAL_forget(selectorState, thisName);
end

%%%% Branch links of the parents that may have changed
touchedParents = unique(touchedParents(~cellfun(@isempty, touchedParents)));
branchParents = {objects.BranchOf};
for ith_parent = 1:numel(touchedParents)
    if ~isKey(nameToIndex, touchedParents{ith_parent})
        continue;
    end
    parentIndex = nameToIndex(touchedParents{ith_parent});
    childRows = find(strcmp(branchParents, touchedParents{ith_parent}));
    childRows = childRows(arrayfun(@(k) ~fcn_INTERNAL_isEmptySlot(objects(k)), childRows));
    if isempty(childRows)
        objects(parentIndex).HasBranches = false;
        objects(parentIndex).BranchStart = Inf;
    else
        objects(parentIndex).HasBranches = true;
        splitTimes = [objects(childRows).SplitTime];
        childStarts = [objects(childRows).StartTime];
        splitTimes(isnan(splitTimes)) = childStarts(isnan(splitTimes));
        objects(parentIndex).BranchStart = min(splitTimes);
    end
end
for ith_name = 1:numel(updateInfo.Added)+numel(updateInfo.Replaced)
    allChanged = [updateInfo.Added, updateInfo.Replaced];
    objectIndex = nameToIndex(allChanged{ith_name});
    if ~isempty(objects(objectIndex).BranchOf) && isnan(objects(objectIndex).SplitTime)
        objects(objectIndex).SplitTime = objects(objectIndex).StartTime;
    end
end

catalog.Objects = objects;
catalog.Grid = gridMap;
catalog.ObjectKeys = objectKeys;
catalog.FromCache = false;
updateInfo.NumGridChanges = numGridChanges;
updateInfo.UpdateSeconds = toc(updateTimer);

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
    for ith_object = 1:numel(catalog.Objects)
        thisObject = catalog.Objects(ith_object);
        if thisObject.IsStatic
            plot(thisObject.ThinPose(1), thisObject.ThinPose(2), 's', 'Color', [0.4 0.4 0.4]);
        elseif ~fcn_INTERNAL_isEmptySlot(thisObject)
            plot(thisObject.ThinPose(:,1), thisObject.ThinPose(:,2), '.-');
        end
    end
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('Catalog after the update: %d added, %d replaced, %d removed', ...
        numel(updateInfo.Added), numel(updateInfo.Replaced), numel(updateInfo.Removed)));
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
% One catalog object, with every field (as in fcn_AnimateCar3D_buildCatalog)
thisObject = struct('Instance','', 'Role','', 'MeshID','', 'MotionFile','', 'BranchOf','', ...
    'BranchID',0, 'SplitTime',NaN, 'RespondsTo','', 'Color',nan(1,3), 'Alpha',NaN, ...
    'TimeOffset',0, 'Size',nan(1,3), 'IsStatic',false, 'StartTime',0, 'EndTime',0, ...
    'ThinTime',zeros(0,1), 'ThinPose',zeros(0,6), 'MotionIndex',0, 'HasBranches',false, 'BranchStart',Inf);
end % Ends fcn_INTERNAL_emptyObject

%% fcn_INTERNAL_emptySlot
function thisObject = fcn_INTERNAL_emptySlot(instanceName)
% A removed object: it keeps its name (so it can be added again in the
% same place) but never exists
thisObject = fcn_INTERNAL_emptyObject;
thisObject.Instance = instanceName;
thisObject.Role = '';
thisObject.StartTime = Inf;
thisObject.EndTime = -Inf;
end % Ends fcn_INTERNAL_emptySlot

%% fcn_INTERNAL_isEmptySlot
function flagEmpty = fcn_INTERNAL_isEmptySlot(thisObject)
% True for a removed object
flagEmpty = ~thisObject.IsStatic && isempty(thisObject.ThinTime);
end % Ends fcn_INTERNAL_isEmptySlot

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

%% fcn_INTERNAL_gridKeys
function keys = fcn_INTERNAL_gridKeys(thisObject, catalog)
% The grid keys of one moving object, by the same rule as
% fcn_AnimateCar3D_buildCatalog (each time window's cells, with a margin
% of the object's length), but with one interpolation for all windows
keys = zeros(0,1);
if isempty(thisObject.ThinTime)
    return;
end
objectLength = thisObject.Size(1);
if isnan(objectLength)
    objectLength = 5;
end
margin = max(5, objectLength);
timeStart = catalog.TimeStart;
timeWindow = catalog.TimeWindow;
cellSize = catalog.CellSize;
firstWindow = floor((thisObject.StartTime - timeStart)/timeWindow);
lastWindow = floor((thisObject.EndTime - timeStart)/timeWindow);
Nwindows = lastWindow - firstWindow + 1;

% The window edges (clipped to the object's life), and the thinned poses
% inside each window
edgeTimes = min(max(timeStart + (firstWindow:lastWindow+1)'*timeWindow, thisObject.StartTime), thisObject.EndTime);
thinTime = thisObject.ThinTime;
if numel(thinTime)==1
    edgeXY = repmat(thisObject.ThinPose(1,1:2), Nwindows+1, 1);
else
    edgeXY = interp1(thinTime, thisObject.ThinPose(:,1:2), edgeTimes, 'linear');
    edgeXY = reshape(edgeXY, Nwindows+1, 2);
end
thinWindow = floor((thinTime - timeStart)/timeWindow) - firstWindow + 1;
flagInside = thinWindow>=1 & thinWindow<=Nwindows & thinTime > edgeTimes(min(max(thinWindow,1),Nwindows)) ...
    & thinTime < edgeTimes(min(max(thinWindow,1),Nwindows)+1);
pointWindow = [(1:Nwindows)'; (1:Nwindows)'; thinWindow(flagInside)];
pointXY = [edgeXY(1:Nwindows,:); edgeXY(2:Nwindows+1,:); thisObject.ThinPose(flagInside,1:2)];
lowXY = [accumarray(pointWindow, pointXY(:,1), [Nwindows 1], @min), accumarray(pointWindow, pointXY(:,2), [Nwindows 1], @min)];
highXY = [accumarray(pointWindow, pointXY(:,1), [Nwindows 1], @max), accumarray(pointWindow, pointXY(:,2), [Nwindows 1], @max)];
lowCell = floor((lowXY - margin)/cellSize);
highCell = floor((highXY + margin)/cellSize);

% Every cell of every window
keyCells = cell(Nwindows,1);
for ith_window = 1:Nwindows
    [cellX, cellY] = ndgrid(lowCell(ith_window,1):highCell(ith_window,1), lowCell(ith_window,2):highCell(ith_window,2));
    keyCells{ith_window} = (firstWindow+ith_window-1)*1e10 + (cellX(:)+5e4)*1e5 + (cellY(:)+5e4);
end
keys = unique(vertcat(keyCells{:}));
end % Ends fcn_INTERNAL_gridKeys

%% fcn_INTERNAL_changeGrid
function [gridMap, numChanges] = fcn_INTERNAL_changeGrid(gridMap, oldKeys, newKeys, objectIndex)
% Take the object out of the keys it left, and put it into the new ones
leftKeys = setdiff(oldKeys, newKeys);
enteredKeys = setdiff(newKeys, oldKeys);
for ith_key = 1:numel(leftKeys)
    thisKey = leftKeys(ith_key);
    if isKey(gridMap, thisKey)
        remaining = gridMap(thisKey);
        remaining = remaining(remaining~=objectIndex);
        if isempty(remaining)
            remove(gridMap, thisKey);
        else
            gridMap(thisKey) = remaining;
        end
    end
end
for ith_key = 1:numel(enteredKeys)
    thisKey = enteredKeys(ith_key);
    if isKey(gridMap, thisKey)
        gridMap(thisKey) = unique([gridMap(thisKey), objectIndex]);
    else
        gridMap(thisKey) = objectIndex;
    end
end
numChanges = numel(leftKeys) + numel(enteredKeys);
end % Ends fcn_INTERNAL_changeGrid

%% fcn_INTERNAL_forget
function selectorState = fcn_INTERNAL_forget(selectorState, instanceName)
% Drop a motion the selector read from a file, so it is read again
if ~isempty(selectorState) && isfield(selectorState,'LoadedMotions') && isKey(selectorState.LoadedMotions, instanceName)
    remove(selectorState.LoadedMotions, instanceName);
end
end % Ends fcn_INTERNAL_forget
