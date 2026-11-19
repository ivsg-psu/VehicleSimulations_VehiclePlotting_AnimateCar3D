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
%            objects use the low-detail mesh and only move. 'far' objects
%            are boxes, all in ONE patch whose vertices are updated each
%            step.
%   Style    Color tints the body (not glass, wheels, or lamps); Alpha
%            makes the whole vehicle see-through. Both are reapplied only
%            when they change.
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
%           BoxPatch: the patch of all far boxes
%           ScratchAxes: the hidden axes new vehicles are drawn in
%           Stats: counts for the last step: NumNear, NumMiddle, NumFar,
%               NumCreated, NumReused, NumHidden, NumDeleted, NumPooled,
%               and UpdateSeconds (time spent in this function, not
%               counting drawnow)
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
            missingIDs = neededIDs(~isfield(meshSet, matlab.lang.makeValidName(neededIDs)));
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
        if isgraphics(playerState.ScratchAxes)
            delete(ancestor(playerState.ScratchAxes,'figure'));
        end
        playerState.Pool = playerState.Pool([]);
        playerState.BoxPatch = gobjects(1);
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
    scratchFigure = figure('Visible','off', 'IntegerHandle','off', 'Name','fcn_AnimateCar3D_playScene scratch');
    playerState.ScratchAxes = axes('Parent',scratchFigure);
end
playerState.Step = playerState.Step + 1;
thisStep = playerState.Step;
pool = playerState.Pool;
stats = struct('NumNear',0, 'NumMiddle',0, 'NumFar',0, 'NumCreated',0, 'NumReused',0, ...
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

    % Its entry has a different mesh or tier? Then release it
    if ~isempty(entryIndex) && ~(strcmp(pool(entryIndex).MeshID, thisObject.MeshID) && strcmp(pool(entryIndex).Tier, thisObject.Tier))
        pool(entryIndex) = fcn_INTERNAL_hideEntry(pool(entryIndex), thisStep);
        poolInstances{entryIndex} = '';
        poolFree(entryIndex) = true;
        entryIndex = [];
    end

    % No entry? Reuse a free one with the same mesh and tier, or make one
    if isempty(entryIndex)
        entryIndex = find(poolFree & strcmp({pool.MeshID}, thisObject.MeshID) & strcmp({pool.Tier}, thisObject.Tier), 1);
        if ~isempty(entryIndex)
            stats.NumReused = stats.NumReused + 1;
        else
            newEntry = fcn_INTERNAL_createEntry(thisObject, meshSet, playerState.Axes, playerState.ScratchAxes, options.LightEffects);
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
        meshEntry = meshSet.(matlab.lang.makeValidName(thisObject.MeshID));
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

%%%% Far boxes, all in one patch
playerState.BoxPatch = fcn_INTERNAL_updateBoxes(playerState.BoxPatch, displayList.Boxes, meshSet, playerState.Axes);
stats.NumFar = numel(displayList.Boxes.Instance);

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
entry = struct('Instance','', 'MeshID','', 'Tier','', 'Handles',[], 'LastStepUsed',0, ...
    'StyleKey',[], 'TintPatches',{{}}, 'TintOriginal',{{}}, 'AllPatches',{{}}, 'AlphaOriginal',[]);
end % Ends fcn_INTERNAL_emptyEntry

%% fcn_INTERNAL_createEntry
function entry = fcn_INTERNAL_createEntry(thisObject, meshSet, axesHandle, scratchAxes, flagLightEffects)
% Draw a vehicle once with fcn_CarMesh3D_plotVehicle, in the scratch axes,
% move it into the player's axes, and remember which patches can be
% tinted. (Drawing straight into the scene's axes would let
% fcn_CarMesh3D_plotVehicle format that axes and add lights whenever the
% scene's own objects are hidden handles, as fcn_CarMesh3D_plotScene's
% are.)
meshEntry = meshSet.(matlab.lang.makeValidName(thisObject.MeshID));
if strcmp(thisObject.Tier,'near')
    thisMesh = meshEntry.Full;
    flagEffects = flagLightEffects;
else
    thisMesh = meshEntry.Low;
    flagEffects = false;
end
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
entry.Handles = handles;

% Every patch (for Alpha), and the opaque body patches that are not
% lamps (for Color)
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
tintPatches = gobjects(0);
for ith_patch = 1:numel(allPatches)
    thisPatch = allPatches(ith_patch);
    if isequal(get(thisPatch,'Parent'), handles.BodyTransform) && ~any(lampPatches==thisPatch) ...
            && get(thisPatch,'FaceAlpha') >= 0.999
        tintPatches(end+1) = thisPatch; %#ok<AGROW>
    end
end
entry.AllPatches = num2cell(allPatches);
entry.AlphaOriginal = arrayfun(@(p) get(p,'FaceAlpha'), allPatches);
entry.TintPatches = num2cell(tintPatches);
entry.TintOriginal = arrayfun(@(p) get(p,'FaceVertexCData'), tintPatches, 'UniformOutput', false);
entry.StyleKey = [nan(1,3), 1];   % the mesh's own colors, opaque
end % Ends fcn_INTERNAL_createEntry

%% fcn_INTERNAL_applyStyle
function entry = fcn_INTERNAL_applyStyle(entry, color, alpha, tintStrength)
% Tint the body toward color (NaN: the mesh's own colors), and scale
% every patch's opacity by alpha
for ith_patch = 1:numel(entry.TintPatches)
    originalColors = entry.TintOriginal{ith_patch};
    if any(isnan(color))
        newColors = originalColors;
    else
        newColors = (1-tintStrength)*originalColors + tintStrength*repmat(color(:)', size(originalColors,1), 1);
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

%% fcn_INTERNAL_updateBoxes
function boxPatch = fcn_INTERNAL_updateBoxes(boxPatch, boxes, meshSet, axesHandle)
% All far boxes in one patch: 8 corners and 5 faces (no bottom) per box
Nboxes = numel(boxes.Instance);
if Nboxes==0
    if isgraphics(boxPatch)
        set(boxPatch, 'Visible', 'off');
    end
    return;
end

% Sizes and rear overhangs (from the mesh where no size was given)
sizes = boxes.Size;
rearOverhangs = zeros(Nboxes,1);
[uniqueIDs, ~, idIndex] = unique(boxes.MeshID);
for ith_id = 1:numel(uniqueIDs)
    meshEntry = meshSet.(matlab.lang.makeValidName(uniqueIDs{ith_id}));
    rows = idIndex==ith_id;
    flagNoSize = rows & any(isnan(sizes),2);
    sizes(flagNoSize,:) = repmat(meshEntry.Size, sum(flagNoSize), 1);
    rearOverhangs(rows) = meshEntry.RearOverhang * sizes(rows,1) / meshEntry.Size(1);
end

% Corners in each box's own frame, then rotated by yaw and moved
cornerX = [0 1 1 0 0 1 1 0];
cornerY = [-0.5 -0.5 0.5 0.5 -0.5 -0.5 0.5 0.5];
cornerZ = [0 0 0 0 1 1 1 1];
localX = sizes(:,1)*cornerX - rearOverhangs;          % Nboxes x 8
localY = sizes(:,2)*cornerY;
localZ = sizes(:,3)*cornerZ;
yaw = boxes.Pose(:,6);
globalX = boxes.Pose(:,1) + cos(yaw).*localX - sin(yaw).*localY;
globalY = boxes.Pose(:,2) + sin(yaw).*localX + cos(yaw).*localY;
globalZ = boxes.Pose(:,3) + localZ;
vertices = [reshape(globalX',[],1), reshape(globalY',[],1), reshape(globalZ',[],1)];

% Faces (corners counted counterclockwise from outside) and colors
oneBoxFaces = [5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
offsets = kron((0:Nboxes-1)'*8, ones(5,1));
faces = repmat(oneBoxFaces, Nboxes, 1) + offsets;
colors = boxes.Color;
colors(any(isnan(colors),2),:) = repmat([0.55 0.55 0.58], sum(any(isnan(colors),2)), 1);
faceColors = kron(colors, ones(5,1));
faceColors(1:5:end,:) = min(1, faceColors(1:5:end,:)*1.15);   % lighter roofs

if ~isgraphics(boxPatch)
    boxPatch = patch('Parent',axesHandle, 'Faces',faces, 'Vertices',vertices, ...
        'FaceVertexCData',faceColors, 'FaceColor','flat', 'EdgeColor',[0.3 0.3 0.3], ...
        'LineWidth',0.25, 'FaceLighting','flat', 'BackFaceLighting','lit', ...
        'DisplayName','Far vehicles (boxes)');
else
    if size(get(boxPatch,'Faces'),1) ~= size(faces,1)
        set(boxPatch, 'Faces', []);
        set(boxPatch, 'Vertices',vertices, 'Faces',faces, 'FaceVertexCData',faceColors);
    else
        set(boxPatch, 'Vertices',vertices, 'FaceVertexCData',faceColors);
    end
    set(boxPatch, 'Visible','on');
end
end % Ends fcn_INTERNAL_updateBoxes
