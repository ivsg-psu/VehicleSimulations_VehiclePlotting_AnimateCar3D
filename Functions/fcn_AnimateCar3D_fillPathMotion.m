function motion = fcn_AnimateCar3D_fillPathMotion(pathXY, options)
% fcn_AnimateCar3D_fillPathMotion

% Makes a vehicle's motion from a path and a speed: the vehicle follows
% the path's XY points (for example, a lane centerline from
% fcn_AnimateCar3D_fillCenterlineOptions) at the given speed, and the
% motion has everything the animation uses: time, pose, wheel spin
% (tires rolling without slipping), front-tire steer angles (Ackermann,
% from the path's curvature), and brake lights while slowing.
%
% The pose is that of the vehicle's reference point, which follows the
% path exactly. The motion fits the motion template of
% fcn_AnimateCar3D_buildCatalog (Instance, Time, Pose, WheelSpin,
% SteerAngle, LightStates), with two more fields for the user: Speed and
% Distance.
%
% FORMAT:
%
%       motion = fcn_AnimateCar3D_fillPathMotion(pathXY, (Speed=speed),...
%           (TimeStep=seconds), (StartTime=seconds), (Instance=name),...
%           (VehicleSpec=spec), (FigNum=figNum))
%
% INPUTS:
%
%      pathXY: N x 2 points along the path, in order of travel (N >= 2).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Speed: m/s: one value (constant speed); N values, one per path
%      point; or a function of the distance along the path, @(s) ...
%      Default 10. (Speeds below 0.1 m/s are raised to 0.1.)
%
%      TimeStep: seconds between motion rows. Default 0.05.
%
%      StartTime: the time of the first row, seconds. Default 0.
%
%      Instance: the object's name. Default 'ego'.
%
%      VehicleSpec: from fcn_CarMesh3D_fillVehicleSpec, for the
%      wheelbase, front track, and tire size. Default: the
%      'genericSedan' preset.
%
%      FigNum: a figure to plot the path, speed, and steer angle. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      motion: a structure with Instance, Time (K x 1), Pose (K x 3, [x
%      y yaw]), WheelSpin (K x 4, rad), SteerAngle (K x 2, [left right]
%      front tires, rad), LightStates (K x 1; Tail 'brake' while slowing
%      by more than 0.3 m/s^2), Speed (K x 1), and Distance (K x 1, along
%      the path).
%
% DEPENDENCIES:
%
%      CarMesh3D: fcn_CarMesh3D_fillVehicleSpec,
%      fcn_CarMesh3D_calcAckermannSteering
%
% EXAMPLES:
%
%       [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset='curvy');
%       motion = fcn_AnimateCar3D_fillPathMotion(centerlineOptions{1}.XY, Speed=12);
%
%       See the script: script_test_fcn_AnimateCar3D_fillPathMotion.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillPathMotion
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillPathMotion
%   % * Turn signals from a lane change or turn (now set by the caller)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    pathXY
    options.Speed = 10            % m/s: a value, N values, or @(s)
    options.TimeStep = 0.05       % seconds between rows
    options.StartTime = 0         % seconds
    options.Instance = 'ego'      % the object's name
    options.VehicleSpec = []      % fcn_CarMesh3D_fillVehicleSpec; [] for 'genericSedan'
    options.FigNum = []           % figure to plot; -1 for fast mode
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


        % Check the path
        if ~(isnumeric(pathXY) && size(pathXY,2)==2 && size(pathXY,1) >= 2 && all(isfinite(pathXY(:))))
            error('pathXY must be N x 2 points, N >= 2');
        end

        % Check the speed
        speed = options.Speed;
        if ~(isa(speed,'function_handle') || (isnumeric(speed) && (isscalar(speed) || numel(speed)==size(pathXY,1))))
            error('Speed must be one value, one value per path point, or a function of distance @(s)');
        end

        % Check the numbers and names
        if ~(isnumeric(options.TimeStep) && isscalar(options.TimeStep) && options.TimeStep > 0)
            error('TimeStep must be a positive number of seconds');
        end
        if ~(isnumeric(options.StartTime) && isscalar(options.StartTime))
            error('StartTime must be a number of seconds');
        end
        if ~(ischar(options.Instance) || isstring(options.Instance))
            error('Instance must be text');
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


%%%% The path, by distance (repeated points removed)
pathXY = double(pathXY);
stepLengths = hypot(diff(pathXY(:,1)), diff(pathXY(:,2)));
keep = [true; stepLengths > 1e-9];
pathXY = pathXY(keep,:);
pathS = [0; cumsum(hypot(diff(pathXY(:,1)), diff(pathXY(:,2))))];
Npath = numel(pathS);
if Npath < 2
    error('The path has no length');
end

%%%% Speed at each path point
speed = options.Speed;
if isa(speed, 'function_handle')
    pathSpeed = speed(pathS);
elseif isscalar(speed)
    pathSpeed = speed*ones(Npath,1);
else
    pathSpeed = speed(:);
    pathSpeed = pathSpeed(keep);
end
pathSpeed = max(double(pathSpeed(:)), 0.1);

%%%% Time to reach each path point, then the motion on a time grid
pathTime = [0; cumsum(diff(pathS) ./ ((pathSpeed(1:end-1) + pathSpeed(2:end))/2))];
timeValues = (0:options.TimeStep:pathTime(end))';
if pathTime(end) - timeValues(end) > 1e-9
    timeValues(end+1,1) = pathTime(end);
end
distance = interp1(pathTime, pathS, timeValues);
pathHeading = unwrap(atan2(gradient(pathXY(:,2)), gradient(pathXY(:,1))));
pathCurvature = gradient(pathHeading) ./ gradient(pathS);
x = interp1(pathS, pathXY(:,1), distance);
y = interp1(pathS, pathXY(:,2), distance);
yaw = interp1(pathS, pathHeading, distance);
curvature = interp1(pathS, pathCurvature, distance);
motionSpeed = interp1(pathS, pathSpeed, distance);

%%%% Wheels: rolling, and steered by Ackermann from the curvature
vehicleSpec = options.VehicleSpec;
if isempty(vehicleSpec)
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
end
frontTrack = vehicleSpec.TrackFront;
if isempty(frontTrack)
    frontTrack = 0.85*vehicleSpec.OverallWidth;
end
wheelSpin = repmat(distance/(vehicleSpec.TireDiameter/2), 1, 4);
steerAngle = fcn_CarMesh3D_calcAckermannSteering(atan(vehicleSpec.Wheelbase*curvature), vehicleSpec.Wheelbase, frontTrack, FigNum=-1);

%%%% Lights: brake lights while slowing
if numel(timeValues) > 1
    acceleration = gradient(motionSpeed) ./ gradient(timeValues);
else
    acceleration = 0;
end
lightStates = repmat(struct('Headlights','low', 'TurnLeft',false, 'TurnRight',false, 'Running',false, ...
    'Tail','on', 'Backup',false), numel(timeValues), 1);
[lightStates(acceleration < -0.3).Tail] = deal('brake');

motion = struct('Instance',char(options.Instance), 'Time',timeValues + options.StartTime, 'Pose',[x y yaw], ...
    'WheelSpin',wheelSpin, 'SteerAngle',steerAngle, 'LightStates',lightStates, 'Speed',motionSpeed, 'Distance',distance);

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
    subplot(1,3,1);
    plot(pathXY(:,1), pathXY(:,2), '-', 'Color', [0.6 0.6 0.6], 'DisplayName', 'path');
    hold on;
    plot(x, y, '.', 'Color', [0.10 0.35 0.85], 'DisplayName', 'motion');
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    legend('Location','best');
    subplot(1,3,2);
    plot(motion.Time, motionSpeed, '-', 'Color', [0.10 0.35 0.85]);
    grid on;
    xlabel('Time [s]');
    ylabel('Speed [m/s]');
    subplot(1,3,3);
    plot(motion.Time, rad2deg(steerAngle), '-');
    grid on;
    xlabel('Time [s]');
    ylabel('Steer angle [deg]');
    legend({'left front','right front'}, 'Location','best');
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


