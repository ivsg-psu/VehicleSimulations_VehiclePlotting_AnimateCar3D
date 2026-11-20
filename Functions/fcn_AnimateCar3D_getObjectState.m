function [objectStates, loadedMotions] = fcn_AnimateCar3D_getObjectState(catalog, instances, sceneTime, options)
% fcn_AnimateCar3D_getObjectState

% The state of one or more catalog objects at a time: pose, wheels,
% body motion, and lights, interpolated from their motions. Used by the
% selector for the objects it draws in detail, and by animation scripts
% (for example, to point the camera at the ego vehicle before selecting).
%
% Where the state comes from, for each object:
%   1. its full motion, if the catalog keeps it in memory;
%   2. else its full motion read from its motion file (and remembered in
%      loadedMotions, so the file is read only once), if Detail is
%      'full';
%   3. else its thinned path (pose only), if Detail is 'pose'.
%
% FORMAT:
%
%       [objectStates, loadedMotions] = fcn_AnimateCar3D_getObjectState(...
%           catalog, instances, sceneTime,...
%           (Detail=detail), (LoadedMotions=map), (FigNum=figNum))
%
% INPUTS:
%
%      catalog: from fcn_AnimateCar3D_buildCatalog.
%
%      instances: an instance name, a cell array of names, or a vector of
%      object indices into catalog.Objects.
%
%      sceneTime: the time, in the scene's clock (seconds).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Detail: 'full' (default): everything, reading motion files when
%      needed; or 'pose': the pose only, from the thinned path when the
%      full motion is not in memory (fast; for far boxes).
%
%      LoadedMotions: a containers.Map of motions already read from files
%      (instance name to motion), from an earlier call. Default: a new,
%      empty map.
%
%      FigNum: a figure number to plot the objects' poses from above.
%      Empty (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      objectStates: N x 1 structure array with fields Instance, Exists
%      (true if sceneTime is within the object's motion; otherwise the
%      state is held at the nearest end), Pose (1 x 6), WheelSpin
%      (1 x 4), SteerAngle (1 x 2), WheelLift (1 x 4), BodyRoll,
%      BodyPitch, BodyHeave, LightStates (a structure, or []).
%
%      loadedMotions: the map, with any newly read motions added (a
%      handle object: the same map as the input, if one was given).
%
% DEPENDENCIES:
%
%      CarMesh3D: fcn_CarMesh3D_loadMotionCSV (motions read from files)
%
% EXAMPLES:
%
%       egoState = fcn_AnimateCar3D_getObjectState(catalog, 'ego', 2.5);
%       fcn_CarMesh3D_updateCamera(cameraSettings, egoState.Pose, AxesHandle=gca);
%
%       See the script: script_test_fcn_AnimateCar3D_getObjectState.m for
%       a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_getObjectState
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_getObjectState
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    catalog
    instances
    sceneTime
    options.Detail = 'full'          % 'full' or 'pose'
    options.LoadedMotions = []       % containers.Map of motions read from files
    options.FigNum = []              % figure to plot the poses; -1 for fast mode
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
        if ~(isstruct(catalog) && isfield(catalog,'Objects') && isfield(catalog,'Motions'))
            error('catalog must come from fcn_AnimateCar3D_buildCatalog');
        end

        % Check the instances input
        if isnumeric(instances)
            if any(instances<1 | instances>numel(catalog.Objects) | instances~=round(instances))
                error('instances given as numbers must be indices into catalog.Objects');
            end
        elseif ~(ischar(instances) || isstring(instances) || iscellstr(instances))
            error('instances must be names or indices');
        end

        % Check the sceneTime input
        if ~isnumeric(sceneTime) || ~isscalar(sceneTime) || ~isfinite(sceneTime)
            error('sceneTime must be a finite number');
        end

        % Check the Detail and LoadedMotions inputs
        if ~any(strcmp(options.Detail, {'full','pose'}))
            error('Detail must be ''full'' or ''pose''');
        end
        if ~isempty(options.LoadedMotions) && ~isa(options.LoadedMotions,'containers.Map')
            error('LoadedMotions must be a containers.Map');
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


% Which objects
if isnumeric(instances)
    objectIndices = instances(:)';
else
    names = cellstr(instances);
    [found, objectIndices] = ismember(names, {catalog.Objects.Instance});
    if ~all(found)
        error('Not in the catalog: %s', strjoin(names(~found), ', '));
    end
end
loadedMotions = options.LoadedMotions;
if isempty(loadedMotions)
    loadedMotions = containers.Map('KeyType','char','ValueType','any');
end
flagFull = strcmp(options.Detail,'full');

Nobjects = numel(objectIndices);
objectStates = repmat(struct('Instance','', 'Exists',false, 'Pose',zeros(1,6), 'WheelSpin',zeros(1,4), ...
    'SteerAngle',zeros(1,2), 'WheelLift',zeros(1,4), 'BodyRoll',0, 'BodyPitch',0, 'BodyHeave',0, ...
    'LightStates',[]), Nobjects, 1);
for ith_object = 1:Nobjects
    thisObject = catalog.Objects(objectIndices(ith_object));
    objectStates(ith_object).Instance = thisObject.Instance;
    objectStates(ith_object).Exists = sceneTime >= thisObject.StartTime - 1e-9 && sceneTime <= thisObject.EndTime + 1e-9;

    % Static: its fixed pose
    if thisObject.IsStatic
        objectStates(ith_object).Pose = thisObject.ThinPose;
        continue;
    end

    % The full motion, if in memory or (for full detail) from its file
    motion = [];
    if thisObject.MotionIndex > 0
        motion = catalog.Motions(thisObject.MotionIndex);
    elseif flagFull && ~isempty(thisObject.MotionFile)
        if isKey(loadedMotions, thisObject.Instance)
            motion = loadedMotions(thisObject.Instance);
        else
            readMotion = fcn_CarMesh3D_loadMotionCSV(thisObject.MotionFile, FigNum=-1);
            motion = struct('Time',readMotion.Time(:), 'Pose',readMotion.Pose, 'WheelSpin',readMotion.WheelSpin, ...
                'SteerAngle',readMotion.SteerAngle, 'WheelLift',readMotion.WheelLift, 'BodyRoll',readMotion.BodyRoll, ...
                'BodyPitch',readMotion.BodyPitch, 'BodyHeave',readMotion.BodyHeave, 'LightStates',readMotion.LightStates);
            loadedMotions(thisObject.Instance) = motion;
        end
    end

    if isempty(motion)
        % The thinned path: pose only
        objectStates(ith_object).Pose = fcn_INTERNAL_interpolate(thisObject.ThinTime, thisObject.ThinPose, sceneTime, true);
        continue;
    end

    % Interpolate the full motion at this object's own time
    localTime = sceneTime - thisObject.TimeOffset;
    pose = motion.Pose;
    if size(pose,2)==3
        pose = [pose(:,1:2), zeros(size(pose,1),3), pose(:,3)];
    end
    objectStates(ith_object).Pose = fcn_INTERNAL_interpolate(motion.Time, pose, localTime, true);
    if ~flagFull
        continue;
    end
    objectStates(ith_object).WheelSpin  = fcn_INTERNAL_field(motion, 'WheelSpin', localTime, [1 4]);
    objectStates(ith_object).SteerAngle = fcn_INTERNAL_field(motion, 'SteerAngle', localTime, [1 2]);
    objectStates(ith_object).WheelLift  = fcn_INTERNAL_field(motion, 'WheelLift', localTime, [1 4]);
    objectStates(ith_object).BodyRoll   = fcn_INTERNAL_field(motion, 'BodyRoll', localTime, [1 1]);
    objectStates(ith_object).BodyPitch  = fcn_INTERNAL_field(motion, 'BodyPitch', localTime, [1 1]);
    objectStates(ith_object).BodyHeave  = fcn_INTERNAL_field(motion, 'BodyHeave', localTime, [1 1]);
    if isfield(motion,'LightStates') && ~isempty(motion.LightStates)
        row = find(motion.Time <= localTime + 1e-9, 1, 'last');
        if isempty(row)
            row = 1;
        end
        objectStates(ith_object).LightStates = motion.LightStates(row);
    end
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
    poses = reshape([objectStates.Pose], 6, [])';
    plot(poses(:,1), poses(:,2), 'o', 'MarkerFaceColor', [0.2 0.4 0.8]);
    quiver(poses(:,1), poses(:,2), 3*cos(poses(:,6)), 3*sin(poses(:,6)), 0);
    for ith_object = 1:numel(objectStates)
        text(poses(ith_object,1), poses(ith_object,2), ['  ' objectStates(ith_object).Instance], 'Interpreter', 'none');
    end
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('Object states at t = %.2f s', sceneTime));
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

%% fcn_INTERNAL_interpolate
function values = fcn_INTERNAL_interpolate(times, table, queryTime, flagPose)
% Linear interpolation of one row at queryTime (held at the ends); for
% poses, the angles (columns 4 to 6) go the shorter way round
if numel(times)==1
    values = table(1,:);
    return;
end
queryTime = min(max(queryTime, times(1)), times(end));
row = find(times <= queryTime, 1, 'last');
row = min(row, numel(times)-1);
fraction = (queryTime - times(row)) / max(times(row+1) - times(row), eps);
first = table(row,:);
second = table(row+1,:);
if flagPose
    angleChange = mod(second(4:6) - first(4:6) + pi, 2*pi) - pi;
    second(4:6) = first(4:6) + angleChange;
end
values = first + fraction*(second - first);
end % Ends fcn_INTERNAL_interpolate

%% fcn_INTERNAL_field
function value = fcn_INTERNAL_field(motion, fieldName, localTime, valueSize)
% One field of a motion at a time, or zeros if the motion has no such field
if ~isfield(motion, fieldName) || isempty(motion.(fieldName))
    value = zeros(valueSize);
    return;
end
value = fcn_INTERNAL_interpolate(motion.Time, double(motion.(fieldName)), localTime, false);
end % Ends fcn_INTERNAL_field
