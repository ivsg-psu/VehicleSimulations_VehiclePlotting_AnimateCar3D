function [displayList, selectorState] = fcn_AnimateCar3D_selectObjects(catalog, sceneTime, criteria, options)
% fcn_AnimateCar3D_selectObjects

% The selector: decides, at one time step, which catalog objects are
% drawn and at which detail tier, and builds the display list for
% fcn_AnimateCar3D_playScene. It is the only part of AnimateCar3D that
% decides what to show.
%
% Each step:
%   1. Find the candidates: only the catalog grid cells near the region,
%      in the current time window, are looked at (static objects are
%      looked up again only when the region has moved), plus the
%      always-shown objects.
%   2. Keep those that exist now, in roles that may be shown. A parent is
%      hidden once its first branch splits off (HideParentAtSplit).
%   3. Region test: inside the camera's view, or the circle or box
%      around the center (always-shown objects skip this test).
%   4. Tiers, nearest first: near (up to NearCount within NearDistance),
%      then middle, then far (boxes). Objects already at a tier keep it
%      until they are beyond its distance times (1 + Hysteresis). Fixed
%      tiers (the ego is always near) come first; 'box' objects are
%      always far.
%   5. Read each drawn object's state at this time (full detail for near
%      objects, reading motion files only now and only once).
%   6. Style: an object's own color and alpha, or its role's default
%      (confederates tinted ConfederateColor; branches take their
%      parent's color and BranchAlpha).
%
% FORMAT:
%
%       [displayList, selectorState] = fcn_AnimateCar3D_selectObjects(...
%           catalog, sceneTime, criteria,...
%           (SelectorState=state), (Camera=camera), (FigNum=figNum))
%
% INPUTS:
%
%      catalog: from fcn_AnimateCar3D_buildCatalog.
%
%      sceneTime: the time, in the scene's clock (seconds).
%
%      criteria: from fcn_AnimateCar3D_fillDisplayCriteria (read fresh
%      every step: change it at any time).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      SelectorState: the state returned by the previous call (for
%      hysteresis, files already read, and the static lookup). Empty
%      (default) to start.
%
%      Camera: the camera, for Region='cameraView' or Center='camera':
%      an axes handle (its camera is read: position, target, up vector,
%      view angle, and shape), or a structure with fields Position,
%      Target, ViewAngle (degrees), and optionally UpVector and
%      AspectRatio (width/height). Set the camera for this step before
%      selecting. Without a camera, 'cameraView' falls back to a circle
%      of radius FarDistance around Center.
%
%      FigNum: a figure number to plot the selection from above: every
%      candidate, the region, and the drawn objects colored by tier.
%      Empty (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      displayList: for fcn_AnimateCar3D_playScene.
%
%      selectorState: pass back on the next call. Fields: Tiers (a map
%      from instance to its tier, 1 near, 2 middle, 3 far),
%      LoadedMotions, StaticCache, Entered and Left (instances that
%      started or stopped being drawn this step), and Stats
%      (NumCandidates, NumNear, NumMiddle, NumFar, RegionUsed,
%      SelectSeconds).
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_getObjectState, fcn_AnimateCar3D_fillDisplayList,
%      fcn_AnimateCar3D_fillSimpleShape
%
% EXAMPLES:
%
%       criteria = fcn_AnimateCar3D_fillDisplayCriteria();
%       [displayList, selectorState] = fcn_AnimateCar3D_selectObjects(catalog, t, criteria,...
%           SelectorState=selectorState, Camera=gca);
%
%       See the script: script_test_fcn_AnimateCar3D_selectObjects.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_selectObjects
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_selectObjects
%   % * Objects added while running (watched folder, step 3)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    catalog
    sceneTime
    criteria
    options.SelectorState = []   % the state from the previous call; [] to start
    options.Camera = []          % axes handle, or struct with Position, Target, ViewAngle
    options.FigNum = []          % figure to plot the selection; -1 for fast mode
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
        if ~(isstruct(catalog) && all(isfield(catalog,{'Objects','Grid','StaticGrid','Motions'})))
            error('catalog must come from fcn_AnimateCar3D_buildCatalog');
        end

        % Check the sceneTime input
        if ~isnumeric(sceneTime) || ~isscalar(sceneTime) || ~isfinite(sceneTime)
            error('sceneTime must be a finite number');
        end

        % Check the criteria input
        if ~(isstruct(criteria) && all(isfield(criteria,{'Region','Center','NearDistance','Hysteresis'})))
            error('criteria must come from fcn_AnimateCar3D_fillDisplayCriteria');
        end

        % Check the Camera input
        camera = options.Camera;
        if ~isempty(camera) && ~(isgraphics(camera,'axes') || (isstruct(camera) && all(isfield(camera,{'Position','Target','ViewAngle'}))))
            error('Camera must be an axes handle, or a structure with Position, Target, and ViewAngle');
        end

        % Check the SelectorState input
        if ~isempty(options.SelectorState) && ~(isstruct(options.SelectorState) && isfield(options.SelectorState,'Tiers'))
            error('SelectorState must be the state returned by fcn_AnimateCar3D_selectObjects');
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


selectTimer = tic;
objects = catalog.Objects;
objectNames = {objects.Instance};
hysteresis = criteria.Hysteresis;

% The selector's memory
selectorState = options.SelectorState;
if isempty(selectorState)
    selectorState = struct;
    selectorState.Tiers = containers.Map('KeyType','char','ValueType','double');
    selectorState.LoadedMotions = containers.Map('KeyType','char','ValueType','any');
    selectorState.StaticCache = struct('Box',[NaN NaN NaN NaN], 'Indices',zeros(1,0));
end
previousTiers = selectorState.Tiers;

% The camera, as a structure (or [])
camera = fcn_INTERNAL_readCamera(options.Camera);

%%%% 1. The region and the point distances are measured from
regionUsed = criteria.Region;
if strcmp(regionUsed,'cameraView') && isempty(camera)
    regionUsed = 'circle';      % no camera: a circle around the center
end
if strcmp(regionUsed,'cameraView')
    centerXY = camera.Target(1:2);
    centerYaw = 0;
else
    [centerXY, centerYaw] = fcn_INTERNAL_center(criteria.Center, catalog, sceneTime, camera, selectorState.LoadedMotions);
end
farDistance = criteria.FarDistance;
switch regionUsed
    case 'cameraView'
        referencePoint = camera.Position;
        lookupHalf = farDistance*(1+hysteresis);
        lookupCenter = camera.Position(1:2);
    case 'circle'
        regionRadius = criteria.Radius;
        if strcmp(criteria.Region,'cameraView')
            regionRadius = farDistance;
        end
        referencePoint = [centerXY 0];
        lookupHalf = regionRadius*(1+hysteresis);
        lookupCenter = centerXY;
    case 'box'
        referencePoint = [centerXY 0];
        lookupHalf = norm(criteria.BoxSize)/2*(1+hysteresis);
        lookupCenter = centerXY;
end
lookupBox = [lookupCenter - lookupHalf, lookupCenter + lookupHalf];   % [xmin ymin xmax ymax]

% Candidates: moving objects in the grid cells around the region, in
% this time window
cellSize = catalog.CellSize;
windowNumber = floor((sceneTime - catalog.TimeStart)/catalog.TimeWindow);
cellRange = floor(lookupBox/cellSize);
[cellX, cellY] = ndgrid(cellRange(1):cellRange(3), cellRange(2):cellRange(4));
candidates = fcn_INTERNAL_lookup(catalog.Grid, windowNumber*1e10 + (cellX(:)+5e4)*1e5 + (cellY(:)+5e4));

% Static objects: looked up again only when the region moved by more than
% half a cell
staticCache = selectorState.StaticCache;
if any(isnan(staticCache.Box)) || max(abs(staticCache.Box - lookupBox)) > cellSize/2
    staticCache.Box = lookupBox;
    staticCache.Indices = fcn_INTERNAL_lookup(catalog.StaticGrid, (cellX(:)+5e4)*1e5 + (cellY(:)+5e4));
end
selectorState.StaticCache = staticCache;
candidates = [candidates, staticCache.Indices];

% Always-shown objects
roles = {objects.Role};
flagBranch = ~cellfun(@isempty, {objects.BranchOf});
flagAlways = ismember(roles, criteria.AlwaysShown) | (criteria.AlwaysShowBranches & flagBranch);
candidates = unique([candidates, find(flagAlways)]);

%%%% 2. Who exists now, in a role that may be shown
candidateObjects = objects(candidates);
flagKeep = ismember(roles(candidates), criteria.RolesShown);
flagKeep = flagKeep & ([candidateObjects.IsStatic] | ...
    (sceneTime >= [candidateObjects.StartTime] - 1e-9 & sceneTime <= [candidateObjects.EndTime] + 1e-9));
if criteria.HideParentAtSplit
    flagKeep = flagKeep & ~([candidateObjects.HasBranches] & sceneTime >= [candidateObjects.BranchStart] - 1e-9);
end
candidates = candidates(flagKeep);
Ncandidates = numel(candidates);

% Poses (from the thinned path, or the full motion when in memory)
if Ncandidates>0
    poseStates = fcn_AnimateCar3D_getObjectState(catalog, candidates, sceneTime, Detail='pose', ...
        LoadedMotions=selectorState.LoadedMotions, FigNum=-1);
    poses = reshape([poseStates.Pose], 6, [])';
else
    poses = zeros(0,6);
end

% Each candidate's previous tier (0 if not drawn last step)
previousTier = zeros(1,Ncandidates);
for ith_candidate = 1:Ncandidates
    if isKey(previousTiers, objectNames{candidates(ith_candidate)})
        previousTier(ith_candidate) = previousTiers(objectNames{candidates(ith_candidate)});
    end
end
flagWasShown = previousTier > 0;
flagAlwaysCandidate = flagAlways(candidates);

%%%% 3. Region test, and distances
objectHalfLengths = zeros(1,Ncandidates);
for ith_candidate = 1:Ncandidates
    objectHalfLengths(ith_candidate) = fcn_INTERNAL_halfLength(objects(candidates(ith_candidate)));
end
switch regionUsed
    case 'cameraView'
        [flagInside, distances] = fcn_INTERNAL_inView(poses, objectHalfLengths, camera, criteria, flagWasShown);
    case 'circle'
        distances = hypot(poses(:,1)' - centerXY(1), poses(:,2)' - centerXY(2));
        flagInside = distances <= regionRadius*(1 + hysteresis*flagWasShown) + objectHalfLengths;
    case 'box'
        relativeX = poses(:,1)' - centerXY(1);
        relativeY = poses(:,2)' - centerXY(2);
        if strcmp(criteria.BoxAlign,'heading')
            [relativeX, relativeY] = deal(cos(centerYaw)*relativeX + sin(centerYaw)*relativeY, ...
                -sin(centerYaw)*relativeX + cos(centerYaw)*relativeY);
        end
        growth = 1 + hysteresis*flagWasShown;
        flagInside = abs(relativeX) <= criteria.BoxSize(1)/2*growth + objectHalfLengths & ...
            abs(relativeY) <= criteria.BoxSize(2)/2*growth + objectHalfLengths;
        distances = hypot(relativeX, relativeY);
end
flagInRegion = flagInside | flagAlwaysCandidate;

%%%% 4. Tiers
tier = zeros(1,Ncandidates);   % 0: not drawn
candidateRoles = roles(candidates);
[~, simpleIDs] = fcn_AnimateCar3D_fillSimpleShape('', FigNum=-1);
flagBox = ismember(lower({objects(candidates).MeshID}), simpleIDs);   % simple shapes: far tier only

% Fixed tiers first (not counted against the tier counts)
for ith_fixed = 1:size(criteria.FixedTiers,1)
    fixedTier = find(strcmp(criteria.FixedTiers{ith_fixed,2}, {'near','middle','far'}));
    tier(strcmp(candidateRoles, criteria.FixedTiers{ith_fixed,1}) & flagInRegion) = fixedTier;
end
tier(tier>0 & flagBox) = 3;

% Then by distance, nearest first, with hysteresis
tierDistances = [criteria.NearDistance criteria.MiddleDistance farDistance];
tierCounts = [criteria.NearCount criteria.MiddleCount criteria.FarCount];
for ith_tier = 1:3
    flagStillOpen = tier==0 & flagInRegion & (~flagBox | ith_tier==3);
    keepsTier = previousTier>0 & previousTier<=ith_tier;
    effectiveDistance = distances ./ (1 + hysteresis*keepsTier);
    flagQualifies = flagStillOpen & effectiveDistance <= tierDistances(ith_tier);
    qualifying = find(flagQualifies);
    [~, order] = sort(effectiveDistance(qualifying));
    chosen = qualifying(order(1:min(numel(order), tierCounts(ith_tier))));
    tier(chosen) = ith_tier;
end

% Always-shown objects that got no tier are drawn as far boxes
tier(tier==0 & flagAlwaysCandidate) = 3;

%%%% 5. States of the drawn objects, and 6. their styles
drawn = find(tier>0);
drawnIndices = candidates(drawn);
drawnTiers = {'near','middle','far'};
drawnTiers = drawnTiers(tier(drawn));
Ndrawn = numel(drawn);
fullStates = [];
nearRows = find(tier(drawn)==1);
if ~isempty(nearRows)
    fullStates = fcn_AnimateCar3D_getObjectState(catalog, drawnIndices(nearRows), sceneTime, Detail='full', ...
        LoadedMotions=selectorState.LoadedMotions, FigNum=-1);
end
drawnPoses = poses(drawn,:);
wheelSpin = zeros(Ndrawn,4);
steerAngle = zeros(Ndrawn,2);
wheelLift = zeros(Ndrawn,4);
bodyMotion = zeros(Ndrawn,3);
lightStates = repmat(struct('Headlights','off', 'TurnLeft',false, 'TurnRight',false, 'Running',false, ...
    'Tail','off', 'Backup',false), Ndrawn, 1);
flagAnyLights = false;
for ith_near = 1:numel(nearRows)
    row = nearRows(ith_near);
    drawnPoses(row,:) = fullStates(ith_near).Pose;
    wheelSpin(row,:) = fullStates(ith_near).WheelSpin;
    steerAngle(row,:) = fullStates(ith_near).SteerAngle;
    wheelLift(row,:) = fullStates(ith_near).WheelLift;
    bodyMotion(row,:) = [fullStates(ith_near).BodyRoll fullStates(ith_near).BodyPitch fullStates(ith_near).BodyHeave];
    if ~isempty(fullStates(ith_near).LightStates)
        lightStates = fcn_INTERNAL_setLights(lightStates, row, fullStates(ith_near).LightStates);
        flagAnyLights = true;
    end
end
[colors, alphas] = fcn_INTERNAL_styles(objects, drawnIndices, criteria);
sizes = reshape([objects(drawnIndices).Size], 3, [])';
if isempty(sizes)
    sizes = zeros(0,3);
end
if flagAnyLights
    lightInput = lightStates;
else
    lightInput = [];
end
displayList = fcn_AnimateCar3D_fillDisplayList(Time=sceneTime, Instance=objectNames(drawnIndices), ...
    MeshID={objects(drawnIndices).MeshID}, Pose=drawnPoses, Tier=drawnTiers, WheelSpin=wheelSpin, ...
    SteerAngle=steerAngle, WheelLift=wheelLift, BodyRoll=bodyMotion(:,1), BodyPitch=bodyMotion(:,2), ...
    BodyHeave=bodyMotion(:,3), LightStates=lightInput, Color=colors, Alpha=alphas, Size=sizes, FigNum=-1);

% Remember this step's tiers; who entered and who left
newTiers = containers.Map('KeyType','char','ValueType','double');
for ith_drawn = 1:Ndrawn
    newTiers(objectNames{drawnIndices(ith_drawn)}) = tier(drawn(ith_drawn));
end
selectorState.Entered = setdiff(newTiers.keys, previousTiers.keys);
selectorState.Left = setdiff(previousTiers.keys, newTiers.keys);
selectorState.Tiers = newTiers;
selectorState.Stats = struct('NumCandidates',Ncandidates, 'NumNear',sum(tier==1), 'NumMiddle',sum(tier==2), ...
    'NumFar',sum(tier==3), 'RegionUsed',regionUsed, 'SelectSeconds',toc(selectTimer));

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
    if Ncandidates>0
        plot(poses(:,1), poses(:,2), '.', 'Color', [0.7 0.7 0.7], 'DisplayName', 'candidates');
    end
    tierColors = [0.85 0.2 0.1; 0.95 0.6 0.1; 0.35 0.35 0.35];
    tierNames = {'near','middle','far'};
    for ith_tier = 1:3
        rows = tier==ith_tier;
        if any(rows)
            plot(poses(rows,1), poses(rows,2), 'o', 'Color', tierColors(ith_tier,:), 'MarkerFaceColor', tierColors(ith_tier,:), ...
                'MarkerSize', 7-ith_tier, 'DisplayName', sprintf('%s (%d)', tierNames{ith_tier}, sum(rows)));
        end
    end
    switch regionUsed
        case 'cameraView'
            viewDirection = camera.Target(1:2) - camera.Position(1:2);
            viewYaw = atan2(viewDirection(2), viewDirection(1));
            halfAngle = deg2rad(camera.HalfAngles(1) + criteria.ViewMargin);
            arcAngles = viewYaw + linspace(-halfAngle, halfAngle, 40);
            plot([camera.Position(1), camera.Position(1)+farDistance*cos(arcAngles), camera.Position(1)], ...
                [camera.Position(2), camera.Position(2)+farDistance*sin(arcAngles), camera.Position(2)], 'b-', 'DisplayName', 'camera view');
        case 'circle'
            angles = linspace(0,2*pi,100);
            plot(centerXY(1)+regionRadius*cos(angles), centerXY(2)+regionRadius*sin(angles), 'b-', 'DisplayName', 'region');
        case 'box'
            corners = [-1 -1; 1 -1; 1 1; -1 1; -1 -1].*criteria.BoxSize/2;
            if strcmp(criteria.BoxAlign,'heading')
                corners = corners*[cos(centerYaw) sin(centerYaw); -sin(centerYaw) cos(centerYaw)];
            end
            plot(centerXY(1)+corners(:,1), centerXY(2)+corners(:,2), 'b-', 'DisplayName', 'region');
    end
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    legend('Location','bestoutside');
    title(sprintf('Selection at t = %.2f s (%s): %d near, %d middle, %d far', sceneTime, regionUsed, ...
        selectorState.Stats.NumNear, selectorState.Stats.NumMiddle, selectorState.Stats.NumFar));
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

%% fcn_INTERNAL_readCamera
function camera = fcn_INTERNAL_readCamera(cameraInput)
% The camera as a structure with Position, Target, UpVector, and
% HalfAngles ([horizontal vertical] half view angles, degrees)
camera = [];
if isempty(cameraInput)
    return;
end
if isgraphics(cameraInput,'axes')
    axesPixels = getpixelposition(cameraInput);
    camera = struct('Position', get(cameraInput,'CameraPosition'), 'Target', get(cameraInput,'CameraTarget'), ...
        'UpVector', get(cameraInput,'CameraUpVector'), 'ViewAngle', get(cameraInput,'CameraViewAngle'), ...
        'AspectRatio', axesPixels(3)/max(axesPixels(4),1));
else
    camera = cameraInput;
    if ~isfield(camera,'UpVector') || isempty(camera.UpVector)
        camera.UpVector = [0 0 1];
    end
    if ~isfield(camera,'AspectRatio') || isempty(camera.AspectRatio)
        camera.AspectRatio = 16/9;
    end
end
camera.Position = camera.Position(:)';
camera.Target = camera.Target(:)';
camera.UpVector = camera.UpVector(:)';
% The view angle is taken as the narrower side's angle; the wider side's
% follows from the shape. (Overestimating the view only draws a little
% more.)
halfNarrow = camera.ViewAngle/2;
halfWide = atand(tand(halfNarrow)*max(camera.AspectRatio, 1/camera.AspectRatio));
if camera.AspectRatio >= 1
    camera.HalfAngles = [halfWide halfNarrow];
else
    camera.HalfAngles = [halfNarrow halfWide];
end
end % Ends fcn_INTERNAL_readCamera

%% fcn_INTERNAL_center
function [centerXY, centerYaw] = fcn_INTERNAL_center(centerSpec, catalog, sceneTime, camera, loadedMotions)
% The region's center (and heading) at this time
centerYaw = 0;
if isa(centerSpec,'function_handle')
    value = centerSpec(sceneTime);
    centerXY = value(1:2);
    if numel(value)>=3
        centerYaw = value(3);
    end
elseif isnumeric(centerSpec)
    centerXY = centerSpec(1:2);
elseif strcmp(centerSpec,'camera')
    if isempty(camera)
        error('Center=''camera'' needs the Camera input');
    end
    centerXY = camera.Target(1:2);
    viewDirection = camera.Target(1:2) - camera.Position(1:2);
    centerYaw = atan2(viewDirection(2), viewDirection(1));
else
    centerState = fcn_AnimateCar3D_getObjectState(catalog, centerSpec, sceneTime, Detail='pose', ...
        LoadedMotions=loadedMotions, FigNum=-1);
    centerXY = centerState.Pose(1:2);
    centerYaw = centerState.Pose(6);
end
centerXY = centerXY(:)';
end % Ends fcn_INTERNAL_center

%% fcn_INTERNAL_lookup
function indices = fcn_INTERNAL_lookup(gridMap, keys)
% The object indices in the given grid cells
indices = zeros(1,0);
if gridMap.Count==0
    return;
end
keyCells = num2cell(keys(:)');
present = isKey(gridMap, keyCells);
if any(present)
    found = values(gridMap, keyCells(present));
    indices = unique([found{:}]);
end
end % Ends fcn_INTERNAL_lookup

%% fcn_INTERNAL_halfLength
function halfLength = fcn_INTERNAL_halfLength(thisObject)
% Half the object's length (a typical car's if unknown)
halfLength = thisObject.Size(1)/2;
if isnan(halfLength)
    halfLength = 2.5;
end
end % Ends fcn_INTERNAL_halfLength

%% fcn_INTERNAL_inView
function [flagInside, distances] = fcn_INTERNAL_inView(poses, halfLengths, camera, criteria, flagWasShown)
% Inside the camera's view (with margins), and the distance from the
% camera, for each pose (a point 1 m above its origin)
N = size(poses,1);
if N==0
    flagInside = false(1,0);
    distances = zeros(1,0);
    return;
end
forward = camera.Target - camera.Position;
forward = forward/norm(forward);
right = cross(forward, camera.UpVector);
right = right/norm(right);
up = cross(right, forward);
relative = [poses(:,1:2), poses(:,3)+1] - camera.Position;
depth = (relative*forward')';
sideways = (relative*right')';
upward = (relative*up')';
distances = sqrt(sum(relative.^2,2))';
growth = 1 + criteria.Hysteresis*flagWasShown;
objectAngle = atand(halfLengths ./ max(depth, 0.1));   % how wide the object looks
halfH = (camera.HalfAngles(1) + criteria.ViewMargin).*growth + objectAngle;
halfV = (camera.HalfAngles(2) + criteria.ViewMargin).*growth + objectAngle;
flagInside = depth > 0 & abs(atand(sideways./depth)) <= halfH & abs(atand(upward./depth)) <= halfV ...
    & distances <= criteria.FarDistance.*growth;
% Objects just behind or beside a close camera can still show at the
% screen's edge: keep anything within its own length of the camera
flagInside = flagInside | distances <= 2*halfLengths;
end % Ends fcn_INTERNAL_inView

%% fcn_INTERNAL_styles
function [colors, alphas] = fcn_INTERNAL_styles(objects, drawnIndices, criteria)
% Each object's own color and alpha, or its role's default
N = numel(drawnIndices);
colors = nan(N,3);
alphas = ones(N,1);
objectNames = {objects.Instance};
for ith_drawn = 1:N
    thisObject = objects(drawnIndices(ith_drawn));
    color = thisObject.Color;
    alpha = thisObject.Alpha;
    if any(isnan(color))
        color = fcn_INTERNAL_roleColor(thisObject, objects, objectNames, criteria);
    end
    if isnan(alpha)
        if ~isempty(thisObject.BranchOf)
            alpha = criteria.BranchAlpha;
        else
            alpha = 1;
        end
    end
    colors(ith_drawn,:) = color;
    alphas(ith_drawn) = alpha;
end
end % Ends fcn_INTERNAL_styles

%% fcn_INTERNAL_roleColor
function color = fcn_INTERNAL_roleColor(thisObject, objects, objectNames, criteria)
% A branch takes its parent's color (or its parent's role's); a
% confederate takes ConfederateColor; others keep their mesh's colors
color = nan(1,3);
for ith_level = 1:20   % follow branch links up to the root
    if ~any(isnan(thisObject.Color))
        color = thisObject.Color;
        return;
    end
    if strcmp(thisObject.Role,'confederate')
        color = criteria.ConfederateColor;
        return;
    end
    if isempty(thisObject.BranchOf)
        return;
    end
    thisObject = objects(strcmp(objectNames, thisObject.BranchOf));
end
end % Ends fcn_INTERNAL_roleColor

%% fcn_INTERNAL_setLights
function lightStates = fcn_INTERNAL_setLights(lightStates, row, newState)
% Put one object's light state into the array (fields may differ)
fieldNames = fieldnames(newState);
for ith_field = 1:numel(fieldNames)
    lightStates(row).(fieldNames{ith_field}) = newState.(fieldNames{ith_field});
end
end % Ends fcn_INTERNAL_setLights
