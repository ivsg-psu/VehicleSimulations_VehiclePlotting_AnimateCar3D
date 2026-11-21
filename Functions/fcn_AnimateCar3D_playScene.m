function playerState = fcn_AnimateCar3D_playScene(displayList, meshSet, options)
% fcn_AnimateCar3D_playScene

% The scene player: draws one time step of a display list, keeping the
% graphics from the step before. It only draws; it never decides what to
% show (that is the selector's job, or for now the calling script's).
%
% Call it once per time step, passing back the state it returned:
%
%       playerState = [];
%       for k = 1:K
%           displayList = ... the objects to show at step k ...
%           playerState = fcn_AnimateCar3D_playScene(displayList, meshSet,...
%               PlayerState=playerState);
%           drawnow;
%       end
%       fcn_AnimateCar3D_playScene([], meshSet, PlayerState=playerState, Action='clear');
%
% How it keeps the drawing fast:
%
%   Reuse    Each near or middle object is drawn with
%            fcn_CarMesh3D_plotVehicle once, and then only moved. (It is
%            drawn in a hidden scratch axes and then moved into the
%            scene, so that the scene's axes, camera, and lights are never
%            changed.) When an
%            object leaves the list, its graphics are hidden, not deleted,
%            and given to the next object that arrives with the same mesh
%            and tier. Hidden graphics unused for IdleSteps steps are
%            deleted.
%   Tiers    'near' objects get everything fcn_CarMesh3D_plotVehicle
%            does (wheels, steering, body motion, lights). 'middle'
%            objects use one of their mesh's detail levels (see Levels
%            below) and only move. 'far' objects use a detail level too,
%            down to a box, and are all merged into ONE patch whose
%            vertices are updated each step (simple shapes and boxes in a
%            second patch, with edges).
%   Levels   A middle or far object's Level (from the selector) picks
%            its detail level; if it is NaN, the level made for its
%            ScreenSize (the coarsest whose MaxScreenSize is at least
%            ScreenSize); with neither, middle objects use the finest
%            level and far objects a box. Level 0 is the full mesh
%            (middle only). A middle object whose level changes gets the
%            graphics of its new level (reused if free).
%   Paths    displayList.Paths (from the selector, or added by a script)
%            are drawn on the ground as displayList.PathStyle says:
%            LineType 'line' (screen lines, LineWidth points), 'ribbon'
%            (strips RibbonWidth meters wide), or 'ribbonAndLine' (a
%            ribbon with a 1 pt line down its middle); previews half as
%            wide if Preview is 'thin'. A path has one color, or a color
%            at each point. Markers use PathStyle.MarkerStyles (a style
%            with no 'Color' takes its path's color there). The graphics
%            of each path (by instance and kind) are kept from step to
%            step and hidden when it is no longer listed.
%   Style    Color tints the body and trim, by part (not glass, wheels,
%            or lamps, whatever their opacity); Alpha makes the whole
%            vehicle see-through (middle and near; merged objects are
%            drawn opaque). Both are reapplied only when they change.
%
% FORMAT:
%
%       playerState = fcn_AnimateCar3D_playScene(displayList, meshSet,...
%           (PlayerState=state), (Action=action), (IdleSteps=steps),...
%           (TintStrength=weight), (LightEffects=flag), (FigNum=figNum))
%
% INPUTS:
%
%      displayList: from fcn_AnimateCar3D_fillDisplayList. Ignored for
%      Action='clear' (can be []).
%
%      meshSet: from fcn_AnimateCar3D_loadMeshes, holding every MeshID in
%      the display list.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      PlayerState: the state returned by the previous call. Empty
%      (default) starts a new player: it draws into figure FigNum (or
%      the current figure), in its current axes. Draw the scene (for
%      example with fcn_CarMesh3D_plotScene) first. If the axes has no
%      lights, the player adds CarMesh3D's two standard lights.
%
%      Action: 'update' (default) draws the display list; 'clear'
%      deletes everything the player drew.
%
%      IdleSteps: how many steps hidden graphics are kept for reuse
%      before they are deleted. Default 120.
%
%      TintStrength: how strongly Color tints the body, from 0 to 1.
%      Default 0.75.
%
%      LightEffects: true to draw glows and light pools on near objects
%      (as fcn_CarMesh3D_plotVehicle's LightEffects; for night scenes).
%      Default false.
%
%      FigNum: the figure to draw into, for a new player. -1 for fast
%      mode (no input checks).
%
% OUTPUTS:
%
%      playerState: a structure to pass back on the next call, with
%      fields
%           Axes: the axes drawn into
%           Step: how many steps have been drawn
%           Pool: the reusable vehicle graphics (one entry per drawn
%               vehicle, visible or hidden)
%           BoxPatch: the patch of far boxes and simple shapes
%           MergedPatch: the patch of far vehicles drawn with a detail
%               level's mesh
%           PathLines: the path graphics (a map from 'instance|kind' to
%               its line, ribbon, and markers)
%           MergedCache: each merged mesh, ready to place (by mesh and
%               level)
%           ScratchAxes: the hidden axes new vehicles are drawn in
%           Stats: counts for the last step: NumNear, NumMiddle, NumFar,
%               NumMergedFaces, NumPaths, NumCreated, NumReused, NumHidden,
%               NumDeleted, NumPooled, and UpdateSeconds (time spent in
%               this function, not counting drawnow)
%
% DEPENDENCIES:
%
%      CarMesh3D: fcn_CarMesh3D_plotVehicle
%
% EXAMPLES:
%
%       See the script: script_test_fcn_AnimateCar3D_playScene.m for a
%       full test suite, and script_demo_AnimateCar3D.m.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_playScene
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_playScene
%   % * Fixed the mesh check when no objects are in view
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_playScene
%   % * Detail levels: middle objects use a level's mesh (Level, or the level
%   %   % made for ScreenSize); far vehicles use a level's mesh too, merged into
%   %   % one patch (MergedPatch), with boxes and simple shapes in another;
%   %   % Color tints by part (not glass, wheels, or lamps), face by face;
%   %   % NumMergedFaces in Stats
%   % * Path lines (displayList.Paths, displayList.PathStyle): screen lines,
%   %   % ground ribbons, or both; one color or a color at each point;
%   %   % markers from MarkerStyles; kept from step to step and hidden;
%   %   % NumPaths in Stats

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_playScene
%   % * Path lines for branches (in the player, or as display list objects?)
%   %   % * Camera control, once the selector exists



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    displayList
    meshSet
    options.PlayerState = []     % the state from the previous call; [] to start
    options.Action = 'update'    % 'update' or 'clear'
    options.IdleSteps = 120      % steps to keep hidden graphics for reuse
    options.TintStrength = 0.75  % 0 to 1: how strongly Color tints the body
    options.LightEffects = false % glows and light pools on near objects
    options.FigNum = []          % figure for a new player; -1 for fast mode
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


        % Check the Action input
        if ~any(strcmp(options.Action, {'update','clear'}))
            error('Action must be ''update'' or ''clear''');
        end

        % Check the displayList input
        if strcmp(options.Action,'update')
            if ~(isstruct(displayList) && all(isfield(displayList,{'Time','Objects','Boxes'})))
                error('displayList must be a display list (see fcn_AnimateCar3D_fillDisplayList)');
            end

            % Check the meshSet input: every mesh in the list is loaded
            if ~(isstruct(meshSet) && isfield(meshSet,'IDs'))
                error('meshSet must come from fcn_AnimateCar3D_loadMeshes');
            end
            neededIDs = unique([{displayList.Objects.MeshID}, displayList.Boxes.MeshID(:)']);
            missingIDs = {};
            if ~isempty(neededIDs)            % (an empty list: no objects in view)
                missingIDs = neededIDs(~isfield(meshSet, matlab.lang.makeValidName(neededIDs)));
            end
            if ~isempty(missingIDs)
                error('These meshes are not in meshSet: %s', strjoin(missingIDs,', '));
            end
        end

        % Check the PlayerState input
        if ~isempty(options.PlayerState) && ~(isstruct(options.PlayerState) && isfield(options.PlayerState,'Pool'))
            error('PlayerState must be the state returned by fcn_AnimateCar3D_playScene');
        end

        % Check the IdleSteps and TintStrength inputs
        if ~isnumeric(options.IdleSteps) || ~isscalar(options.IdleSteps) || options.IdleSteps<0
            error('IdleSteps must be a non-negative number');
        end
        if ~isnumeric(options.TintStrength) || ~isscalar(options.TintStrength) || options.TintStrength<0 || options.TintStrength>1
            error('TintStrength must be from 0 to 1');
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


timerStart = tic;
playerState = options.PlayerState;

% Clear: delete everything and stop
if strcmp(options.Action,'clear')
    if ~isempty(playerState)
        for ith_entry = 1:numel(playerState.Pool)
            fcn_INTERNAL_deleteEntry(playerState.Pool(ith_entry));
        end
        if isgraphics(playerState.BoxPatch)
            delete(playerState.BoxPatch);
        end
        if isfield(playerState,'MergedPatch') && isgraphics(playerState.MergedPatch)
            delete(playerState.MergedPatch);
        end
        if isfield(playerState,'PathLines')
            pathGraphics = values(playerState.PathLines);
            for ith_path = 1:numel(pathGraphics)
                fcn_INTERNAL_deletePathGraphics(pathGraphics{ith_path});
            end
            playerState.PathLines = containers.Map('KeyType','char','ValueType','any');
        end
        if isgraphics(playerState.ScratchAxes)
            delete(ancestor(playerState.ScratchAxes,'figure'));
        end
        playerState.Pool = playerState.Pool([]);
        playerState.BoxPatch = gobjects(1);
        playerState.MergedPatch = gobjects(1);
        playerState.ScratchAxes = gobjects(1);
    end
    return;
end

% Start a new player?
if isempty(playerState)
    if isempty(options.FigNum) || isequal(options.FigNum,-1)
        figureHandle = gcf;
    else
        figureHandle = figure(options.FigNum);
    end
    axesHandle = get(figureHandle,'CurrentAxes');
    if isempty(axesHandle)
        axesHandle = axes('Parent',figureHandle);
    end
    playerState = struct;
    playerState.Axes = axesHandle;
    playerState.Step = 0;
    playerState.Pool = repmat(fcn_INTERNAL_emptyEntry, 0, 1);
    playerState.BoxPatch = gobjects(1);
    playerState.MergedPatch = gobjects(1);
    playerState.MergedCache = containers.Map('KeyType','char','ValueType','any');
    playerState.PathLines = containers.Map('KeyType','char','ValueType','any');
    playerState.ScratchAxes = gobjects(1);
    playerState.Stats = struct;
end
if playerState.Step==1 && isempty(findall(playerState.Axes,'Type','light'))
    % The scene has no lights: add the two CarMesh3D uses (a main light
    % from above and to the side, and a dimmer fill light)
    light('Parent',playerState.Axes,'Style','infinite','Position',[-1 -2 3]);
    light('Parent',playerState.Axes,'Style','infinite','Position',[2 1.5 1],'Color',[0.45 0.45 0.45]);
end
if ~isgraphics(playerState.ScratchAxes)
    % A hidden figure (with no number, so it never takes a user's figure
    % number) where new vehicles are drawn before moving into the scene
    % (Making a figure makes it the current one: give that back to the
    % scene's figure, so that commands after this call, such as title or
    % campos, still go to the scene)
    sceneFigure = ancestor(playerState.Axes,'figure');
    scratchFigure = figure('Visible','off', 'IntegerHandle','off', 'Name','fcn_AnimateCar3D_playScene scratch');
    playerState.ScratchAxes = axes('Parent',scratchFigure);
    set(groot, 'CurrentFigure', sceneFigure);
    set(sceneFigure, 'CurrentAxes', playerState.Axes);
end
playerState.Step = playerState.Step + 1;
thisStep = playerState.Step;
pool = playerState.Pool;
stats = struct('NumNear',0, 'NumMiddle',0, 'NumFar',0, 'NumMergedFaces',0, 'NumPaths',0, 'NumCreated',0, 'NumReused',0, ...
    'NumHidden',0, 'NumDeleted',0, 'NumPooled',0, 'UpdateSeconds',0);

% Index the pool: which entry each visible instance has, and which
% entries are free
objects = displayList.Objects;
poolInstances = {pool.Instance};
poolFree = cellfun(@isempty, poolInstances);

% First hide the entries whose objects have left the list, so that
% arriving objects can reuse them in this same step
flagLeft = ~poolFree & ~ismember(poolInstances, {objects.Instance});
for ith_entry = find(flagLeft)
    pool(ith_entry) = fcn_INTERNAL_hideEntry(pool(ith_entry), thisStep);
    poolInstances{ith_entry} = '';
    poolFree(ith_entry) = true;
    stats.NumHidden = stats.NumHidden + 1;
end

%%%% Near and middle objects
for ith_object = 1:numel(objects)
    thisObject = objects(ith_object);
    entryIndex = find(strcmp(poolInstances, thisObject.Instance), 1);

    % Its detail level: 0 (the full mesh) for near objects
    meshEntry = meshSet.(matlab.lang.makeValidName(thisObject.MeshID));
    if strcmp(thisObject.Tier,'near')
        thisLevel = 0;
    else
        thisLevel = fcn_INTERNAL_middleLevel(meshEntry, thisObject.Level, thisObject.ScreenSize);
    end

    % Its entry has a different mesh, tier, or level? Then release it
    if ~isempty(entryIndex) && ~(strcmp(pool(entryIndex).MeshID, thisObject.MeshID) && strcmp(pool(entryIndex).Tier, thisObject.Tier) ...
            && pool(entryIndex).Level==thisLevel)
        pool(entryIndex) = fcn_INTERNAL_hideEntry(pool(entryIndex), thisStep);
        poolInstances{entryIndex} = '';
        poolFree(entryIndex) = true;
        entryIndex = [];
        stats.NumHidden = stats.NumHidden + 1;
    end

    % No entry? Reuse a free one with the same mesh, tier, and level, or
    % make one
    if isempty(entryIndex)
        entryIndex = find(poolFree & strcmp({pool.MeshID}, thisObject.MeshID) & strcmp({pool.Tier}, thisObject.Tier) ...
            & [pool.Level]==thisLevel, 1);
        if ~isempty(entryIndex)
            stats.NumReused = stats.NumReused + 1;
        else
            newEntry = fcn_INTERNAL_createEntry(thisObject, thisLevel, meshEntry, playerState.Axes, playerState.ScratchAxes, options.LightEffects);
            pool = [pool; newEntry]; %#ok<AGROW>
            poolInstances{end+1} = ''; %#ok<AGROW>
            poolFree(end+1) = true; %#ok<AGROW>
            entryIndex = numel(pool);
            stats.NumCreated = stats.NumCreated + 1;
        end
        pool(entryIndex).Instance = thisObject.Instance;
        poolInstances{entryIndex} = thisObject.Instance;
        poolFree(entryIndex) = false;
        set(pool(entryIndex).Handles.Transform, 'Visible', 'on');
    end

    % Move it
    if strcmp(thisObject.Tier,'near')
        plotArguments = {'Pose',thisObject.Pose, 'WheelSpin',thisObject.WheelSpin, ...
            'SteerAngle',thisObject.SteerAngle, 'WheelLift',thisObject.WheelLift, ...
            'BodyRoll',thisObject.BodyRoll, 'BodyPitch',thisObject.BodyPitch, ...
            'BodyHeave',thisObject.BodyHeave, 'PlotHandles',pool(entryIndex).Handles, 'FigNum',-1};
        if ~isempty(thisObject.LightStates)
            plotArguments = [plotArguments, {'LightStates',thisObject.LightStates}]; %#ok<AGROW>
        end
        fcn_CarMesh3D_plotVehicle(meshEntry.Full, plotArguments{:});
        stats.NumNear = stats.NumNear + 1;
    else
        set(pool(entryIndex).Handles.Transform, 'Matrix', fcn_INTERNAL_poseToMatrix(thisObject.Pose));
        stats.NumMiddle = stats.NumMiddle + 1;
    end

    % Style it, if its style changed
    styleKey = [thisObject.Color(:)', thisObject.Alpha];
    if ~isequaln(styleKey, pool(entryIndex).StyleKey)
        pool(entryIndex) = fcn_INTERNAL_applyStyle(pool(entryIndex), thisObject.Color, thisObject.Alpha, options.TintStrength);
    end
    pool(entryIndex).LastStepUsed = thisStep;
end

% Delete hidden entries unused for too long
flagStale = poolFree(:) & (thisStep - [pool.LastStepUsed]') > options.IdleSteps;
for ith_entry = find(flagStale)'
    fcn_INTERNAL_deleteEntry(pool(ith_entry));
end
pool = pool(~flagStale);
stats.NumDeleted = sum(flagStale);

%%%% Far objects: merged meshes in one patch, boxes and simple shapes in
%%%% another
if ~isfield(playerState,'MergedPatch')
    playerState.MergedPatch = gobjects(1);
    playerState.MergedCache = containers.Map('KeyType','char','ValueType','any');
end
[playerState.BoxPatch, playerState.MergedPatch, playerState.MergedCache, stats.NumMergedFaces] = fcn_INTERNAL_updateFar( ...
    playerState.BoxPatch, playerState.MergedPatch, playerState.MergedCache, displayList.Boxes, meshSet, playerState.Axes, options.TintStrength);
stats.NumFar = numel(displayList.Boxes.Instance);

%%%% Path lines
if ~isfield(playerState,'PathLines')
    playerState.PathLines = containers.Map('KeyType','char','ValueType','any');
end
paths = struct('Instance',{}, 'Kind',{}, 'XYZ',{}, 'Color',{});
if isfield(displayList,'Paths')
    paths = displayList.Paths;
end
pathStyle = struct('LineType','line', 'LineWidth',2, 'RibbonWidth',0.6, 'Preview','thin', ...
    'MarkerStyles',{{{'Marker','o','MarkerSize',6}}});
if isfield(displayList,'PathStyle') && ~isempty(displayList.PathStyle)
    pathStyle = displayList.PathStyle;
end
playerState.PathLines = fcn_INTERNAL_updatePaths(playerState.PathLines, paths, pathStyle, playerState.Axes);
stats.NumPaths = numel(paths);

% Done
playerState.Pool = pool;
stats.NumPooled = numel(pool);
stats.UpdateSeconds = toc(timerStart);
playerState.Stats = stats;

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

    % (The player draws into its own axes; nothing more to plot)
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

%% fcn_INTERNAL_emptyEntry
function entry = fcn_INTERNAL_emptyEntry
% One pool entry: the graphics of one drawn vehicle
entry = struct('Instance','', 'MeshID','', 'Tier','', 'Level',0, 'Handles',[], 'LastStepUsed',0, ...
    'StyleKey',[], 'TintPatches',{{}}, 'TintOriginal',{{}}, 'TintMasks',{{}}, 'AllPatches',{{}}, 'AlphaOriginal',[]);
end % Ends fcn_INTERNAL_emptyEntry

%% fcn_INTERNAL_middleLevel
function thisLevel = fcn_INTERNAL_middleLevel(meshEntry, requestedLevel, screenSize)
% The detail level a middle object is drawn with: its Level, or the level
% made for its ScreenSize, or the finest; never the box (the coarsest
% mesh level instead); 0 is the full mesh
levels = meshEntry.Levels;
if isempty(levels)
    thisLevel = 0;
    return;
end
if ~isnan(requestedLevel)
    thisLevel = requestedLevel;
elseif ~isnan(screenSize)
    thisLevel = find([levels.MaxScreenSize] >= screenSize, 1, 'last');
    if isempty(thisLevel)
        thisLevel = 0;
    end
else
    thisLevel = 1;
end
thisLevel = min(max(round(thisLevel),0), numel(levels));
if thisLevel>0 && levels(thisLevel).IsBox
    thisLevel = find(~[levels.IsBox], 1, 'last');
    if isempty(thisLevel)
        thisLevel = 0;
    end
end
end % Ends fcn_INTERNAL_middleLevel

%% fcn_INTERNAL_createEntry
function entry = fcn_INTERNAL_createEntry(thisObject, thisLevel, meshEntry, axesHandle, scratchAxes, flagLightEffects)
% Draw a vehicle once with fcn_CarMesh3D_plotVehicle, in the scratch axes,
% move it into the player's axes, and remember which faces can be
% tinted. (Drawing straight into the scene's axes would let
% fcn_CarMesh3D_plotVehicle format that axes and add lights whenever the
% scene's own objects are hidden handles, as fcn_CarMesh3D_plotScene's
% are.)
if thisLevel==0
    thisMesh = meshEntry.Full;
else
    thisMesh = meshEntry.Levels(thisLevel).Mesh;
end
flagEffects = flagLightEffects && strcmp(thisObject.Tier,'near');
previousFigure = get(0,'CurrentFigure');
scratchFigure = ancestor(scratchAxes,'figure');
set(0,'CurrentFigure',scratchFigure);
set(scratchFigure,'CurrentAxes',scratchAxes);
handles = fcn_CarMesh3D_plotVehicle(thisMesh, Pose=thisObject.Pose, LightEffects=flagEffects, FigNum=-1);
set(handles.Transform, 'Parent', axesHandle);
handles.Axes = axesHandle;
if ~isempty(previousFigure) && isgraphics(previousFigure)
    set(0,'CurrentFigure',previousFigure);
end

entry = fcn_INTERNAL_emptyEntry;
entry.MeshID = thisObject.MeshID;
entry.Tier = thisObject.Tier;
entry.Level = thisLevel;
entry.Handles = handles;

% Every patch (for Alpha), and, for Color, the faces of every part but
% glass, wheels, and lamps (tint by part). A patch's faces are matched
% to the mesh's faces by their centers, which fcn_CarMesh3D_plotVehicle
% keeps in the vehicle's own frame.
allPatches = handles.Patches;
if iscell(allPatches)
    allPatches = [allPatches{:}];
end
allPatches = allPatches(isgraphics(allPatches));
lampPatches = gobjects(0);
if isfield(handles,'LightPatches') && isstruct(handles.LightPatches)
    lampNames = fieldnames(handles.LightPatches);
    for ith_name = 1:numel(lampNames)
        lampPatches = [lampPatches, handles.LightPatches.(lampNames{ith_name})]; %#ok<AGROW>
    end
end
flagTintFace = fcn_INTERNAL_tintableFaces(thisMesh);
meshCenters = fcn_INTERNAL_faceCenters(thisMesh.Vertices, thisMesh.Faces);
tintPatches = gobjects(0);
tintMasks = {};
for ith_patch = 1:numel(allPatches)
    thisPatch = allPatches(ith_patch);
    if any(lampPatches==thisPatch)
        continue;
    end
    patchFaces = get(thisPatch,'Faces');
    [flagFound, meshRows] = ismembertol(fcn_INTERNAL_faceCenters(get(thisPatch,'Vertices'), patchFaces), meshCenters, ...
        1e-9, 'ByRows', true, 'DataScale', 1);
    if any(flagFound)
        mask = false(size(patchFaces,1),1);
        mask(flagFound) = flagTintFace(meshRows(flagFound));
    else
        % (Faces not found: the old rule, opaque body patches)
        mask = repmat(isequal(get(thisPatch,'Parent'), handles.BodyTransform) && get(thisPatch,'FaceAlpha') >= 0.999, ...
            size(patchFaces,1), 1);
    end
    if any(mask)
        tintPatches(end+1) = thisPatch; %#ok<AGROW>
        tintMasks{end+1} = mask; %#ok<AGROW>
    end
end
entry.AllPatches = num2cell(allPatches);
entry.AlphaOriginal = arrayfun(@(p) get(p,'FaceAlpha'), allPatches);
entry.TintPatches = num2cell(tintPatches);
entry.TintOriginal = arrayfun(@(p) get(p,'FaceVertexCData'), tintPatches, 'UniformOutput', false);
entry.TintMasks = tintMasks;
entry.StyleKey = [nan(1,3), 1];   % the mesh's own colors, opaque
end % Ends fcn_INTERNAL_createEntry

%% fcn_INTERNAL_tintableFaces
function flagTint = fcn_INTERNAL_tintableFaces(thisMesh)
% The faces Color tints: every part but glass, wheels, and lamps
untinted = find(ismember(lower(thisMesh.PartNames), {'glass','wheel','light'}));
flagTint = ~ismember(thisMesh.FacePartIndex(:), untinted);
end % Ends fcn_INTERNAL_tintableFaces

%% fcn_INTERNAL_faceCenters
function centers = fcn_INTERNAL_faceCenters(vertices, faces)
% The mean of each face's corners (faces may be padded with NaN)
Ncorners = sum(~isnan(faces),2);
centers = zeros(size(faces,1),3);
for ith_corner = 1:size(faces,2)
    flagHas = ~isnan(faces(:,ith_corner));
    centers(flagHas,:) = centers(flagHas,:) + vertices(faces(flagHas,ith_corner),:);
end
centers = centers./Ncorners;
end % Ends fcn_INTERNAL_faceCenters

%% fcn_INTERNAL_applyStyle
function entry = fcn_INTERNAL_applyStyle(entry, color, alpha, tintStrength)
% Tint the body toward color (NaN: the mesh's own colors), and scale
% every patch's opacity by alpha
for ith_patch = 1:numel(entry.TintPatches)
    originalColors = entry.TintOriginal{ith_patch};
    newColors = originalColors;
    if ~any(isnan(color))
        mask = entry.TintMasks{ith_patch};
        newColors(mask,:) = (1-tintStrength)*originalColors(mask,:) + tintStrength*repmat(color(:)', sum(mask), 1);
    end
    set(entry.TintPatches{ith_patch}, 'FaceVertexCData', newColors);
end
for ith_patch = 1:numel(entry.AllPatches)
    set(entry.AllPatches{ith_patch}, 'FaceAlpha', entry.AlphaOriginal(ith_patch)*alpha);
end
entry.StyleKey = [color(:)', alpha];
end % Ends fcn_INTERNAL_applyStyle

%% fcn_INTERNAL_hideEntry
function entry = fcn_INTERNAL_hideEntry(entry, thisStep)
% Hide a vehicle's graphics and free its entry for reuse
if isgraphics(entry.Handles.Transform)
    set(entry.Handles.Transform, 'Visible', 'off');
end
entry.Instance = '';
entry.LastStepUsed = thisStep;
end % Ends fcn_INTERNAL_hideEntry

%% fcn_INTERNAL_deleteEntry
function fcn_INTERNAL_deleteEntry(entry)
% Delete a vehicle's graphics
if ~isempty(entry.Handles) && isgraphics(entry.Handles.Transform)
    delete(entry.Handles.Transform);
end
end % Ends fcn_INTERNAL_deleteEntry

%% fcn_INTERNAL_poseToMatrix
function poseMatrix = fcn_INTERNAL_poseToMatrix(pose)
% [x y z roll pitch yaw] to a 4 x 4 transform, as fcn_CarMesh3D_plotVehicle
% does it (translate, then yaw, pitch, roll)
cy = cos(pose(6)); sy = sin(pose(6));
cp = cos(pose(5)); sp = sin(pose(5));
cr = cos(pose(4)); sr = sin(pose(4));
rotation = [cy -sy 0; sy cy 0; 0 0 1] * [cp 0 sp; 0 1 0; -sp 0 cp] * [1 0 0; 0 cr -sr; 0 sr cr];
poseMatrix = [rotation, pose(1:3)'; 0 0 0 1];
end % Ends fcn_INTERNAL_poseToMatrix

%% fcn_INTERNAL_updatePaths
function pathGraphicsMap = fcn_INTERNAL_updatePaths(pathGraphicsMap, paths, pathStyle, axesHandle)
% Draw each path (by instance and kind): its line and/or ribbon, made
% once and then moved; its markers, remade each step. Paths not listed
% this step are hidden.
listedKeys = cell(numel(paths),1);
flagLine = any(strcmp(pathStyle.LineType, {'line','ribbonAndLine'}));
flagRibbon = any(strcmp(pathStyle.LineType, {'ribbon','ribbonAndLine'}));
for ith_path = 1:numel(paths)
    thisPath = paths(ith_path);
    pathKey = [thisPath.Instance '|' thisPath.Kind];
    listedKeys{ith_path} = pathKey;
    if isKey(pathGraphicsMap, pathKey)
        graphics = pathGraphicsMap(pathKey);
    else
        graphics = struct('Line',gobjects(1), 'Ribbon',gobjects(1), 'Markers',gobjects(0));
    end
    widthScale = 1;
    if strcmp(thisPath.Kind,'preview') && strcmp(pathStyle.Preview,'thin')
        widthScale = 0.5;
    end
    Npoints = size(thisPath.XYZ,1);
    pointColors = thisPath.Color;
    if size(pointColors,1)==1
        pointColors = repmat(pointColors, Npoints, 1);
    end

    % The line: an open patch (a NaN vertex ends it), so that it can have
    % a color at each point
    if flagLine && Npoints>=2
        if strcmp(pathStyle.LineType,'ribbonAndLine')
            lineWidth = 1*widthScale;
        else
            lineWidth = pathStyle.LineWidth*widthScale;
        end
        lineVertices = [thisPath.XYZ + [0 0 0.035]; NaN NaN NaN];
        lineArguments = {'Vertices',lineVertices, 'Faces',1:Npoints+1, 'FaceVertexCData',[pointColors; NaN NaN NaN], ...
            'LineWidth',lineWidth, 'Visible','on'};
        if ~isgraphics(graphics.Line)
            graphics.Line = patch(axesHandle, lineArguments{:}, 'FaceColor','none', 'EdgeColor','interp', ...
                'PickableParts','none', 'Tag','AnimateCar3D path line', 'DisplayName',pathKey);
        else
            set(graphics.Line, 'Faces', []);
            set(graphics.Line, lineArguments{:});
        end
    elseif isgraphics(graphics.Line)
        set(graphics.Line, 'Visible','off');
    end

    % The ribbon: a strip on the ground, RibbonWidth wide
    if flagRibbon && Npoints>=2
        halfWidth = pathStyle.RibbonWidth*widthScale/2;
        directions = gradient(thisPath.XYZ(:,1:2)')';
        directions = directions./max(vecnorm(directions,2,2), eps);
        normals = [-directions(:,2), directions(:,1)];
        ribbonVertices = [thisPath.XYZ(:,1:2) + halfWidth*normals, thisPath.XYZ(:,3) + 0.03; ...
                          thisPath.XYZ(:,1:2) - halfWidth*normals, thisPath.XYZ(:,3) + 0.03];
        ribbonFaces = [(1:Npoints-1)', (2:Npoints)', Npoints+(2:Npoints)', Npoints+(1:Npoints-1)'];
        ribbonArguments = {'Vertices',ribbonVertices, 'Faces',ribbonFaces, 'FaceVertexCData',[pointColors; pointColors], ...
            'Visible','on'};
        if ~isgraphics(graphics.Ribbon)
            graphics.Ribbon = patch(axesHandle, ribbonArguments{:}, 'FaceColor','interp', 'EdgeColor','none', ...
                'FaceLighting','none', 'PickableParts','none', 'Tag','AnimateCar3D path ribbon', 'DisplayName',pathKey);
        else
            set(graphics.Ribbon, 'Faces', []);
            set(graphics.Ribbon, ribbonArguments{:});
        end
    elseif isgraphics(graphics.Ribbon)
        set(graphics.Ribbon, 'Visible','off');
    end

    % The markers: one line object per style (per marker, if the style
    % takes its color from a path with a color at each point)
    delete(graphics.Markers(isgraphics(graphics.Markers)));
    graphics.Markers = gobjects(0);
    if isfield(thisPath,'MarkerXYZ') && ~isempty(thisPath.MarkerXYZ)
        for styleIndex = unique(thisPath.MarkerStyle(:))'
            thisStyle = pathStyle.MarkerStyles{styleIndex};
            rows = find(thisPath.MarkerStyle(:)==styleIndex);
            flagOwnColor = any(strcmpi(thisStyle(1:2:end), 'Color'));
            if flagOwnColor || size(thisPath.Color,1)==1
                groups = {rows};
            else
                groups = num2cell(rows);
            end
            for ith_group = 1:numel(groups)
                groupRows = groups{ith_group};
                markerColor = fcn_INTERNAL_colorNear(thisPath, thisPath.MarkerXYZ(groupRows(1),:));
                graphics.Markers(end+1) = line(axesHandle, thisPath.MarkerXYZ(groupRows,1), thisPath.MarkerXYZ(groupRows,2), ...
                    thisPath.MarkerXYZ(groupRows,3) + 0.05, 'LineStyle','none', 'Marker','o', 'Color',markerColor, ...
                    'MarkerFaceColor',markerColor, thisStyle{:}, 'PickableParts','none', 'Tag','AnimateCar3D path marker');
            end
        end
    end
    pathGraphicsMap(pathKey) = graphics;
end

% Hide the paths not listed
allKeys = keys(pathGraphicsMap);
for ith_key = find(~ismember(allKeys, listedKeys))
    graphics = pathGraphicsMap(allKeys{ith_key});
    shapeHandles = [graphics.Line, graphics.Ribbon];
    set(shapeHandles(isgraphics(shapeHandles)), 'Visible','off');
    delete(graphics.Markers(isgraphics(graphics.Markers)));
    graphics.Markers = gobjects(0);
    pathGraphicsMap(allKeys{ith_key}) = graphics;
end
end % Ends fcn_INTERNAL_updatePaths

%% fcn_INTERNAL_colorNear
function color = fcn_INTERNAL_colorNear(thisPath, point)
% The path's color at the point nearest a marker
if size(thisPath.Color,1)==1
    color = thisPath.Color;
else
    [~, nearest] = min(sum((thisPath.XYZ - point).^2, 2));
    color = thisPath.Color(nearest,:);
end
end % Ends fcn_INTERNAL_colorNear

%% fcn_INTERNAL_deletePathGraphics
function fcn_INTERNAL_deletePathGraphics(graphics)
% Delete one path's graphics
allHandles = [graphics.Line, graphics.Ribbon, graphics.Markers];
delete(allHandles(isgraphics(allHandles)));
end % Ends fcn_INTERNAL_deletePathGraphics

%% fcn_INTERNAL_updateFar
function [boxPatch, mergedPatch, mergedCache, numMergedFaces] = fcn_INTERNAL_updateFar(boxPatch, mergedPatch, mergedCache, ...
    boxes, meshSet, axesHandle, tintStrength)
% Far objects: those drawn with a detail level's mesh are merged into
% one patch (no edges); boxes and simple shapes go in another (with
% edges, as before)
Nfar = numel(boxes.Instance);
farLevels = zeros(Nfar,1);                  % 0: a box or a simple shape
for ith_far = 1:Nfar
    meshEntry = meshSet.(matlab.lang.makeValidName(boxes.MeshID{ith_far}));
    levels = meshEntry.Levels;
    if isempty(levels)
        continue;
    end
    thisLevel = boxes.Level(ith_far);
    if isnan(thisLevel)
        if isnan(boxes.ScreenSize(ith_far))
            thisLevel = numel(levels);                                       % a box, as before levels
        else
            thisLevel = find([levels.MaxScreenSize] >= boxes.ScreenSize(ith_far), 1, 'last');
            if isempty(thisLevel)
                thisLevel = 1;
            end
        end
    end
    thisLevel = min(max(round(thisLevel),1), numel(levels));
    if ~levels(thisLevel).IsBox
        farLevels(ith_far) = thisLevel;
    end
end
flagMerged = farLevels>0;
boxPatch = fcn_INTERNAL_updateBoxes(boxPatch, fcn_INTERNAL_subsetBoxes(boxes, ~flagMerged), meshSet, axesHandle);
[mergedPatch, mergedCache, numMergedFaces] = fcn_INTERNAL_updateMerged(mergedPatch, mergedCache, ...
    fcn_INTERNAL_subsetBoxes(boxes, flagMerged), farLevels(flagMerged), meshSet, axesHandle, tintStrength);
end % Ends fcn_INTERNAL_updateFar

%% fcn_INTERNAL_subsetBoxes
function subset = fcn_INTERNAL_subsetBoxes(boxes, rows)
% Some rows of the far objects
subset = struct('Instance',{boxes.Instance(rows)}, 'MeshID',{boxes.MeshID(rows)}, 'Pose',boxes.Pose(rows,:), ...
    'Size',boxes.Size(rows,:), 'Color',boxes.Color(rows,:));
end % Ends fcn_INTERNAL_subsetBoxes

%% fcn_INTERNAL_updateMerged
function [mergedPatch, mergedCache, numFaces] = fcn_INTERNAL_updateMerged(mergedPatch, mergedCache, ...
    rows, rowLevels, meshSet, axesHandle, tintStrength)
% Far vehicles, each with its detail level's mesh, all in one patch
Nrows = numel(rows.Instance);
numFaces = 0;
if Nrows==0
    if isgraphics(mergedPatch)
        set(mergedPatch, 'Visible', 'off');
    end
    return;
end
groupKeys = strcat(rows.MeshID(:), '|', compose('%d', rowLevels(:)));
[uniqueKeys, ~, keyIndex] = unique(groupKeys);
vertexBlocks = cell(numel(uniqueKeys),1);
faceBlocks = cell(numel(uniqueKeys),1);
colorBlocks = cell(numel(uniqueKeys),1);
vertexCount = 0;
for ith_key = 1:numel(uniqueKeys)
    members = find(keyIndex==ith_key);
    thisKey = uniqueKeys{ith_key};
    if isKey(mergedCache, thisKey)
        prepared = mergedCache(thisKey);
    else
        % Ready once: corners reversed (MATLAB's clockwise normals), the
        % mesh's colors, and which faces Color tints
        meshEntry = meshSet.(matlab.lang.makeValidName(rows.MeshID{members(1)}));
        levelMesh = meshEntry.Levels(rowLevels(members(1))).Mesh;
        prepared = struct('Vertices',levelMesh.Vertices, 'Faces',levelMesh.Faces(:,end:-1:1), ...
            'Colors',levelMesh.FaceColors, 'TintMask',fcn_INTERNAL_tintableFaces(levelMesh));
        mergedCache(thisKey) = prepared;
    end
    Nmembers = numel(members);
    Nverts = size(prepared.Vertices,1);
    Nfaces = size(prepared.Faces,1);
    localX = repmat(prepared.Vertices(:,1)', Nmembers, 1);
    localY = repmat(prepared.Vertices(:,2)', Nmembers, 1);
    localZ = repmat(prepared.Vertices(:,3)', Nmembers, 1);
    vertexBlocks{ith_key} = fcn_INTERNAL_placeVertices(localX, localY, localZ, rows.Pose(members,:));
    offsets = kron(vertexCount + (0:Nmembers-1)'*Nverts, ones(Nfaces,1));
    faceBlocks{ith_key} = repmat(prepared.Faces, Nmembers, 1) + offsets;
    vertexCount = vertexCount + Nmembers*Nverts;
    memberColors = repmat(prepared.Colors, Nmembers, 1);
    for ith_member = 1:Nmembers
        color = rows.Color(members(ith_member),:);
        if ~any(isnan(color))
            faceRows = (ith_member-1)*Nfaces + find(prepared.TintMask);
            memberColors(faceRows,:) = (1-tintStrength)*memberColors(faceRows,:) + tintStrength*color;
        end
    end
    colorBlocks{ith_key} = memberColors;
end
vertices = vertcat(vertexBlocks{:});
faces = vertcat(faceBlocks{:});
faceColors = vertcat(colorBlocks{:});
numFaces = size(faces,1);
if ~isgraphics(mergedPatch)
    mergedPatch = patch('Parent',axesHandle, 'Faces',faces, 'Vertices',vertices, ...
        'FaceVertexCData',faceColors, 'FaceColor','flat', 'EdgeColor','none', ...
        'FaceLighting','flat', 'BackFaceLighting','lit', 'AmbientStrength',0.55, ...
        'DiffuseStrength',0.65, 'SpecularStrength',0.25, 'DisplayName','Far vehicles (merged detail levels)');
else
    if ~isequal(size(get(mergedPatch,'Faces')), size(faces))
        set(mergedPatch, 'Faces', []);
    end
    set(mergedPatch, 'Vertices',vertices, 'Faces',faces, 'FaceVertexCData',faceColors, 'Visible','on');
end
end % Ends fcn_INTERNAL_updateMerged

%% fcn_INTERNAL_placeVertices
function vertices = fcn_INTERNAL_placeVertices(localX, localY, localZ, poses)
% Corners in each object's own frame (one row per object) turned by roll
% (x), then pitch (y), then yaw (z), as CarMesh3D does, and moved to each
% object's position; one row per corner, object by object
roll = poses(:,4);
pitch = poses(:,5);
yaw = poses(:,6);
y1 = cos(roll).*localY - sin(roll).*localZ;
z1 = sin(roll).*localY + cos(roll).*localZ;
x2 = cos(pitch).*localX + sin(pitch).*z1;
z2 = -sin(pitch).*localX + cos(pitch).*z1;
globalX = poses(:,1) + cos(yaw).*x2 - sin(yaw).*y1;
globalY = poses(:,2) + sin(yaw).*x2 + cos(yaw).*y1;
globalZ = poses(:,3) + z2;
vertices = [reshape(globalX',[],1), reshape(globalY',[],1), reshape(globalZ',[],1)];
end % Ends fcn_INTERNAL_placeVertices

%% fcn_INTERNAL_updateBoxes
function boxPatch = fcn_INTERNAL_updateBoxes(boxPatch, boxes, meshSet, axesHandle)
% All far objects in one patch: far vehicles as boxes (5 faces, no
% bottom), and simple shapes (pedestrians, bars, cylinders, boxes) each
% in its own shape. Every object is scaled by its size, then turned by
% its roll, pitch, and yaw, and moved to its position.
Nboxes = numel(boxes.Instance);
if Nboxes==0
    if isgraphics(boxPatch)
        set(boxPatch, 'Visible', 'off');
    end
    return;
end

% Sizes, rear overhangs (from the mesh where no size was given), and the
% shape each object is drawn as
sizes = boxes.Size;
rearOverhangs = zeros(Nboxes,1);
[uniqueIDs, ~, idIndex] = unique(boxes.MeshID);
shapes = cell(numel(uniqueIDs),1);
for ith_id = 1:numel(uniqueIDs)
    meshEntry = meshSet.(matlab.lang.makeValidName(uniqueIDs{ith_id}));
    rows = idIndex==ith_id;
    flagNoSize = rows & any(isnan(sizes),2);
    sizes(flagNoSize,:) = repmat(meshEntry.Size, sum(flagNoSize), 1);
    rearOverhangs(rows) = meshEntry.RearOverhang * sizes(rows,1) / meshEntry.Size(1);
    if isfield(meshEntry,'Shape') && ~isempty(meshEntry.Shape)
        shapes{ith_id} = meshEntry.Shape;
    else
        shapes{ith_id} = fcn_INTERNAL_vehicleBox;
    end
end
colors = boxes.Color;
colors(any(isnan(colors),2),:) = repmat([0.55 0.55 0.58], sum(any(isnan(colors),2)), 1);
poses = boxes.Pose;

% Each shape's objects at once
faceWidth = max(cellfun(@(shape) size(shape.Faces,2), shapes));
vertexBlocks = cell(numel(uniqueIDs),1);
faceBlocks = cell(numel(uniqueIDs),1);
colorBlocks = cell(numel(uniqueIDs),1);
vertexCount = 0;
for ith_id = 1:numel(uniqueIDs)
    shape = shapes{ith_id};
    rows = find(idIndex==ith_id);
    Nrows = numel(rows);
    Nverts = size(shape.Vertices,1);
    Nfaces = size(shape.Faces,1);

    % Corners in each object's own frame (Nrows x Nverts): the shape's x
    % runs from the rear, so x = length*(unit x + RearFraction) - overhang
    localX = sizes(rows,1)*(shape.Vertices(:,1)' + shape.RearFraction) - rearOverhangs(rows);
    localY = sizes(rows,2)*shape.Vertices(:,2)';
    localZ = sizes(rows,3)*shape.Vertices(:,3)';

    % Turn by roll (x), then pitch (y), then yaw (z), as CarMesh3D does
    vertexBlocks{ith_id} = fcn_INTERNAL_placeVertices(localX, localY, localZ, poses(rows,:));

    % Faces, with each object's vertex offset, padded to one width
    % (Each face's corners are reversed: MATLAB takes a patch face's
    % normal from its corners clockwise, and the shapes list them
    % counterclockwise seen from outside, so without this the lit side
    % of every face would be the inside)
    shapeFaces = [fcn_INTERNAL_reverseCorners(shape.Faces), nan(Nfaces, faceWidth-size(shape.Faces,2))];
    offsets = kron(vertexCount + (0:Nrows-1)'*Nverts, ones(Nfaces,1));
    faceBlocks{ith_id} = repmat(shapeFaces, Nrows, 1) + offsets;
    vertexCount = vertexCount + Nrows*Nverts;

    % Colors: the object's color, or the shape's fixed colors; tops
    % brighter
    objectColors = kron(colors(rows,:), ones(Nfaces,1));
    fixedColors = repmat(shape.FaceColor, Nrows, 1);
    flagFixed = ~any(isnan(fixedColors),2);
    objectColors(flagFixed,:) = fixedColors(flagFixed,:);
    colorBlocks{ith_id} = min(1, objectColors .* repmat(shape.FaceShade, Nrows, 1));
end
vertices = vertcat(vertexBlocks{:});
faces = vertcat(faceBlocks{:});
faceColors = vertcat(colorBlocks{:});

if ~isgraphics(boxPatch)
    boxPatch = patch('Parent',axesHandle, 'Faces',faces, 'Vertices',vertices, ...
        'FaceVertexCData',faceColors, 'FaceColor','flat', 'EdgeColor',[0.3 0.3 0.3], ...
        'LineWidth',0.25, 'FaceLighting','flat', 'BackFaceLighting','lit', ...
        'DisplayName','Far vehicles and simple shapes');
else
    if ~isequal(size(get(boxPatch,'Faces')), size(faces))
        set(boxPatch, 'Faces', []);
        set(boxPatch, 'Vertices',vertices, 'Faces',faces, 'FaceVertexCData',faceColors);
    else
        set(boxPatch, 'Vertices',vertices, 'Faces',faces, 'FaceVertexCData',faceColors);
    end
    set(boxPatch, 'Visible','on');
end
end % Ends fcn_INTERNAL_updateBoxes

%% fcn_INTERNAL_reverseCorners
function faces = fcn_INTERNAL_reverseCorners(faces)
% Reverse the order of each face's corners (NaN padding stays at the end)
for ith_face = 1:size(faces,1)
    corners = faces(ith_face, ~isnan(faces(ith_face,:)));
    faces(ith_face, 1:numel(corners)) = fliplr(corners);
end
end % Ends fcn_INTERNAL_reverseCorners

%% fcn_INTERNAL_vehicleBox
function shape = fcn_INTERNAL_vehicleBox
% The box a far vehicle is drawn as: x from 0 to 1 from the rear bumper
% (RearFraction 0: the vehicle's rear overhang places it), no bottom
shape = struct;
shape.Vertices = [0 -0.5 0; 1 -0.5 0; 1 0.5 0; 0 0.5 0; 0 -0.5 1; 1 -0.5 1; 1 0.5 1; 0 0.5 1];
shape.Faces = [5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
shape.FaceColor = nan(5,3);
shape.FaceShade = [1.15; 1; 1; 1; 1];   % a lighter roof
shape.RearFraction = 0;
end % Ends fcn_INTERNAL_vehicleBox
