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
%           (VehicleSpec=spec), (Road=road), (PitchPerG=degrees),...
%           (RollPerG=degrees), (BodyMotionScale=scale), (FigNum=figNum))
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
%      Stops: rows of [s seconds]: at distance s along the path, the
%      object waits that many seconds (stopped, brake lights on), then
%      goes on. Give a Speed that slows to (near) zero there. Default
%      zeros(0,2) (no stops).
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
%      Road: a road (or road network) from fcn_AnimateCar3D_fillRoad, to
%      put the vehicle on its surface: the height under the vehicle, the
%      pitch from the heights 1.4 m ahead and behind (nose down is
%      positive, so climbing pitches negative), and the roll from the
%      heights 0.8 m to each side (right side down is positive). The pose
%      is then [x y z roll pitch yaw]. Default [] (flat: [x y yaw]).
%      This is the pose of the wheels (the unsprung mass) on the road;
%      the body moves on them (below).
%
%      PitchPerG: the body's pitch on its wheels, in degrees per g of
%      speeding up or braking (nose down when braking, up when speeding
%      up). Default 1.5 (a typical sedan: 1 to 2).
%
%      RollPerG: the body's roll on its wheels, in degrees per g of
%      sideways acceleration (leaning to the outside of the turn).
%      Default 4 (a typical sedan: 3 to 6).
%
%      BodyMotionScale: multiplies both, to make the body's motion easier
%      to see (for example 3); 0 for a rigid body. Default 1.
%
%      FigNum: a figure to plot the path, speed, and steer angle. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      motion: a structure with Instance, Time (K x 1), Pose (K x 3, [x
%      y yaw]; with Road, K x 6, [x y z roll pitch yaw]), WheelSpin (K x 4, rad), SteerAngle (K x 2, [left right]
%      front tires, rad), BodyRoll, BodyPitch, BodyHeave (K x 1: the
%      body on its wheels, rad and m; heave 0), LightStates (K x 1; Tail 'brake' while slowing
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
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillPathMotion
%   % * Added the Road option: the vehicle on the road's surface (z, roll, pitch)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillPathMotion
%   % * Added the Stops option: wait at given distances (brake lights on)

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
    options.Stops = zeros(0,2)    % rows of [s seconds]: wait at s
    options.TimeStep = 0.05       % seconds between rows
    options.StartTime = 0         % seconds
    options.Instance = 'ego'      % the object's name
    options.VehicleSpec = []      % fcn_CarMesh3D_fillVehicleSpec; [] for 'genericSedan'
    options.Road = []             % a road from fcn_AnimateCar3D_fillRoad: on its surface (z, roll, pitch)
    options.PitchPerG = 1.5       % degrees of body pitch per g, speeding up or braking
    options.RollPerG = 4          % degrees of body roll per g sideways
    options.BodyMotionScale = 1   % multiplies both (3 to exaggerate; 0 for a rigid body)
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
        bodyNames = {'PitchPerG','RollPerG','BodyMotionScale'};
        for ith_name = 1:numel(bodyNames)
            if ~(isnumeric(options.(bodyNames{ith_name})) && isscalar(options.(bodyNames{ith_name})) && options.(bodyNames{ith_name}) >= 0)
                error('%s must be a number, 0 or more', bodyNames{ith_name});
            end
        end
        if ~isempty(options.Road) && ~(isstruct(options.Road) && (isfield(options.Road,'PlanView') || isfield(options.Road,'Roads')))
            error('Road must come from fcn_AnimateCar3D_fillRoad, or be []');
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
% (stops: at each stop's distance, wait; later points come that much later)
knotTime = pathTime; knotS = pathS;
stopWindows = zeros(0,2);
stops = sortrows(options.Stops, 1);
for ith_stop = 1:size(stops,1)
    stopS = min(max(stops(ith_stop,1), knotS(1)), knotS(end));
    stopTime = interp1(knotS, knotTime, stopS);
    later = knotS > stopS;
    knotTime(later) = knotTime(later) + stops(ith_stop,2);
    knotTime = [knotTime(~later); stopTime; stopTime + stops(ith_stop,2); knotTime(later)];
    knotS = [knotS(~later); stopS; stopS; knotS(later)];
    [knotTime, order] = sort(knotTime); knotS = knotS(order);
    [knotTime, unique1] = unique(knotTime, 'stable'); knotS = knotS(unique1);
    stopWindows(end+1,:) = [stopTime, stopTime + stops(ith_stop,2)]; %#ok<AGROW>
end
timeValues = (0:options.TimeStep:knotTime(end))';
if knotTime(end) - timeValues(end) > 1e-9
    timeValues(end+1,1) = knotTime(end);
end
distance = interp1(knotTime, knotS, timeValues);
pathHeading = unwrap(atan2(gradient(pathXY(:,2)), gradient(pathXY(:,1))));
pathCurvature = gradient(pathHeading) ./ gradient(pathS);
x = interp1(pathS, pathXY(:,1), distance);
y = interp1(pathS, pathXY(:,2), distance);
yaw = interp1(pathS, pathHeading, distance);
curvature = interp1(pathS, pathCurvature, distance);
motionSpeed = interp1(pathS, pathSpeed, distance);
flagStopped = false(size(timeValues));
for ith_stop = 1:size(stopWindows,1)
    flagStopped = flagStopped | (timeValues >= stopWindows(ith_stop,1) & timeValues <= stopWindows(ith_stop,2));
end
motionSpeed(flagStopped) = 0;

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
[lightStates(acceleration < -0.3 | flagStopped).Tail] = deal('brake');

%%%% The body on its wheels (the sprung mass): pitch from speeding up and
%%%% braking, roll from turning (accelerations smoothed over about 0.5 s)
smoothRows = max(1, round(0.5/options.TimeStep));
if numel(timeValues) > 1
    yawRate = gradient(unwrap(yaw(:)))./gradient(timeValues(:));
else
    yawRate = 0;
end
forwardAccel = movmean(acceleration(:), smoothRows);
sidewaysAccel = movmean(motionSpeed(:).*yawRate, smoothRows);
bodyPitch = -options.BodyMotionScale*deg2rad(options.PitchPerG)*forwardAccel/9.81;   % (+ nose down: braking)
bodyRoll = options.BodyMotionScale*deg2rad(options.RollPerG)*sidewaysAccel/9.81;    % (+ right side down: a left turn)
bodyPitch = bodyPitch.*ones(numel(timeValues),1);
bodyRoll = bodyRoll.*ones(numel(timeValues),1);

%%%% On the road's surface: height, pitch (from ahead and behind), roll
%%%% (from left and right)
pose = [x(:) y(:) yaw(:)];
if ~isempty(options.Road)
    heading = [cos(yaw(:)) sin(yaw(:))];
    leftward = [-sin(yaw(:)) cos(yaw(:))];
    probeXY = repmat([x(:) y(:)], 5, 1) + kron([0; 1.4; -1.4; 0; 0], ones(numel(x),1)).*repmat(heading, 5, 1) ...
        + kron([0; 0; 0; 0.8; -0.8], ones(numel(x),1)).*repmat(leftward, 5, 1);
    probeZ = reshape(fcn_AnimateCar3D_getRoadHeight(options.Road, probeXY, FigNum=-1), numel(x), 5);
    pitch = -atan((probeZ(:,2) - probeZ(:,3))/2.8);
    roll = atan((probeZ(:,4) - probeZ(:,5))/1.6);
    pose = [x(:) y(:) probeZ(:,1) roll pitch yaw(:)];
end

motion = struct('Instance',char(options.Instance), 'Time',timeValues + options.StartTime, 'Pose',pose, ...
    'WheelSpin',wheelSpin, 'SteerAngle',steerAngle, 'BodyRoll',bodyRoll, 'BodyPitch',bodyPitch, 'BodyHeave',zeros(numel(timeValues),1), ...
    'LightStates',lightStates, 'Speed',motionSpeed, 'Distance',distance);

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


