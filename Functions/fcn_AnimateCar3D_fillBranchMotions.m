function branchMotions = fcn_AnimateCar3D_fillBranchMotions(options)
% fcn_AnimateCar3D_fillBranchMotions

% Makes a simple set of decision branches for testing and demos: a
% parent vehicle drives straight, then at SplitTime splits into
% NumBranches branches, each turning with its own steady curvature (from
% hard left to hard right). Each branch starts exactly at the parent's
% pose at the split, and eases into its turn over RampTime seconds.
%
% The motions are kinematic (the rear axle follows the path, tires roll
% without slipping), with left and right steer angles from Ackermann
% steering. They stand in for the branches a planner would produce.
%
% FORMAT:
%
%       branchMotions = fcn_AnimateCar3D_fillBranchMotions(...
%           (NumBranches=N), (SplitTime=seconds), (Duration=seconds),...
%           (Speed=speed), (MaxCurvature=curvature), (RampTime=seconds),...
%           (SampleTime=seconds), (StartPose=[x y yaw]),...
%           (VehicleSpec=spec), (ParentName=name), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      NumBranches: how many branches. Default 10.
%
%      SplitTime: when the parent splits, in seconds. Default 2.
%
%      Duration: the end time, in seconds. Default 6.
%
%      Speed: the speed of the parent and every branch, m/s. Default 8.
%
%      MaxCurvature: the curvature of the hardest left (positive) and
%      right turns, 1/m. Branches are spread evenly from +MaxCurvature to
%      -MaxCurvature. Default 1/20.
%
%      RampTime: seconds for each branch to reach its curvature. Default
%      0.8.
%
%      SampleTime: seconds between samples. Default 1/20.
%
%      StartPose: the parent's starting [x y yaw]. Default [0 0 0].
%
%      VehicleSpec: a CarMesh3D vehicle specification, for the wheelbase,
%      front track, and tire diameter. Default: CarMesh3D's generic sedan.
%
%      ParentName: the parent's instance name. Branches are named
%      <ParentName>_branch<k>. Default 'ego'.
%
%      FigNum: a figure number to plot the paths from above. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      branchMotions: a structure with fields
%           Parent: the parent's motion, from time 0 to SplitTime
%           Branches: NumBranches x 1 structure array of branch motions,
%               from SplitTime to Duration
%      Each motion has fields Instance, BranchOf ('' for the parent),
%      BranchID (0 for the parent), SplitTime, Curvature (the branch's
%      final curvature), Time (K x 1), Pose (K x 3 [x y yaw]), WheelSpin
%      (K x 4, [FL FR RL RR], radians), and SteerAngle (K x 2 [left
%      right], radians).
%
% DEPENDENCIES:
%
%      CarMesh3D: fcn_CarMesh3D_fillVehicleSpec,
%      fcn_CarMesh3D_calcAckermannSteering
%
% EXAMPLES:
%
%       branchMotions = fcn_AnimateCar3D_fillBranchMotions(NumBranches=5, FigNum=1);
%
%       See the script: script_test_fcn_AnimateCar3D_fillBranchMotions.m
%       for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillBranchMotions
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillBranchMotions
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    options.NumBranches = 10      % how many branches
    options.SplitTime = 2         % seconds
    options.Duration = 6          % seconds
    options.Speed = 8             % m/s
    options.MaxCurvature = 1/20   % 1/m, hardest turn
    options.RampTime = 0.8        % seconds to reach each branch's curvature
    options.SampleTime = 1/20     % seconds
    options.StartPose = [0 0 0]   % [x y yaw]
    options.VehicleSpec = []      % [] for CarMesh3D's generic sedan
    options.ParentName = 'ego'    % the parent's instance name
    options.FigNum = []           % figure to plot the paths; -1 for fast mode
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


        % Check the scalar inputs
        positiveInputs = {'NumBranches','Duration','SampleTime'};
        for ith_input = 1:length(positiveInputs)
            thisValue = options.(positiveInputs{ith_input});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || thisValue<=0
                error('%s must be a positive number', positiveInputs{ith_input});
            end
        end
        if options.NumBranches ~= round(options.NumBranches)
            error('NumBranches must be a whole number');
        end
        if ~isnumeric(options.SplitTime) || ~isscalar(options.SplitTime) || options.SplitTime<0 || options.SplitTime>=options.Duration
            error('SplitTime must be from 0 up to (not including) Duration');
        end
        if ~isnumeric(options.Speed) || ~isscalar(options.Speed)
            error('Speed must be a number');
        end
        if ~isnumeric(options.MaxCurvature) || ~isscalar(options.MaxCurvature) || options.MaxCurvature<0
            error('MaxCurvature must be a non-negative number');
        end
        if ~isnumeric(options.RampTime) || ~isscalar(options.RampTime) || options.RampTime<0
            error('RampTime must be a non-negative number');
        end

        % Check the StartPose input
        if ~isnumeric(options.StartPose) || numel(options.StartPose)~=3
            error('StartPose must be [x y yaw]');
        end

        % Check the VehicleSpec input
        if ~isempty(options.VehicleSpec) && ~(isstruct(options.VehicleSpec) && all(isfield(options.VehicleSpec,{'Wheelbase','TrackFront','TireDiameter'})))
            error('VehicleSpec must be a CarMesh3D vehicle specification');
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


% Vehicle dimensions
vehicleSpec = options.VehicleSpec;
if isempty(vehicleSpec)
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
end
wheelbase = vehicleSpec.Wheelbase;
track = vehicleSpec.TrackFront;
tireRadius = vehicleSpec.TireDiameter/2;
dt = options.SampleTime;
speed = options.Speed;

% The parent: straight, from 0 to SplitTime
parentTime = (0:dt:options.SplitTime)';
if parentTime(end) < options.SplitTime - 1e-9
    parentTime(end+1) = options.SplitTime;
end
startPose = options.StartPose(:)';
parentDistance = speed*parentTime;
parent = fcn_INTERNAL_motion(options.ParentName, '', 0, options.SplitTime, 0, parentTime, ...
    [startPose(1) + parentDistance*cos(startPose(3)), startPose(2) + parentDistance*sin(startPose(3)), ...
    repmat(startPose(3), numel(parentTime), 1)], ...
    repmat(parentDistance/tireRadius, 1, 4), zeros(numel(parentTime),2));
splitPose = parent.Pose(end,:);
splitSpin = parent.WheelSpin(end,1);

% The branches: from SplitTime to Duration, each with its own curvature
branchTime = (options.SplitTime:dt:options.Duration)';
if branchTime(end) < options.Duration - 1e-9
    branchTime(end+1) = options.Duration;
end
Ksteps = numel(branchTime);
if options.NumBranches==1
    branchCurvatures = 0;
else
    branchCurvatures = linspace(options.MaxCurvature, -options.MaxCurvature, options.NumBranches);
end
timeSinceSplit = branchTime - options.SplitTime;
if options.RampTime>0
    rampFraction = min(1, timeSinceSplit/options.RampTime);
else
    rampFraction = ones(Ksteps,1);
end
branches = repmat(parent, options.NumBranches, 1);
for ith_branch = 1:options.NumBranches
    curvature = branchCurvatures(ith_branch)*rampFraction;    % K x 1

    % Integrate the path (trapezoid rule on yaw, then position)
    stepDistance = speed*[0; diff(branchTime)];
    yaw = splitPose(3) + cumsum(stepDistance .* [curvature(1); (curvature(2:end)+curvature(1:end-1))/2]);
    meanYaw = [yaw(1); (yaw(2:end)+yaw(1:end-1))/2];
    x = splitPose(1) + cumsum(stepDistance.*cos(meanYaw));
    y = splitPose(2) + cumsum(stepDistance.*sin(meanYaw));

    % Wheels: spin with distance; front tires steer (Ackermann)
    distance = cumsum(stepDistance);
    wheelSpin = splitSpin + repmat(distance/tireRadius, 1, 4);
    steerAngles = fcn_CarMesh3D_calcAckermannSteering(atan(wheelbase*curvature), wheelbase, track, FigNum=-1);

    branches(ith_branch) = fcn_INTERNAL_motion(sprintf('%s_branch%d', options.ParentName, ith_branch), ...
        options.ParentName, ith_branch, options.SplitTime, branchCurvatures(ith_branch), ...
        branchTime, [x y yaw], wheelSpin, steerAngles);
end

branchMotions = struct;
branchMotions.Parent = parent;
branchMotions.Branches = branches;

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
    plot(branchMotions.Parent.Pose(:,1), branchMotions.Parent.Pose(:,2), 'k-', 'LineWidth', 2.5);
    branchColors = fcn_INTERNAL_branchColors(numel(branchMotions.Branches));
    for ith_branch = 1:numel(branchMotions.Branches)
        thisPose = branchMotions.Branches(ith_branch).Pose;
        plot(thisPose(:,1), thisPose(:,2), '-', 'Color', branchColors(ith_branch,:), 'LineWidth', 1.5);
        text(thisPose(end,1), thisPose(end,2), sprintf('  %d', ith_branch), 'Color', branchColors(ith_branch,:));
    end
    plot(branchMotions.Parent.Pose(end,1), branchMotions.Parent.Pose(end,2), 'ko', 'MarkerFaceColor', 'k');
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    title(sprintf('%d branches splitting at t = %.1f s', numel(branchMotions.Branches), branchMotions.Parent.SplitTime));
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

%% fcn_INTERNAL_motion
function motion = fcn_INTERNAL_motion(instanceName, branchOf, branchID, splitTime, curvature, time, pose, wheelSpin, steerAngle)
% One motion structure, with every field
motion = struct('Instance',instanceName, 'BranchOf',branchOf, 'BranchID',branchID, ...
    'SplitTime',splitTime, 'Curvature',curvature, 'Time',time, 'Pose',pose, ...
    'WheelSpin',wheelSpin, 'SteerAngle',steerAngle);
end % Ends fcn_INTERNAL_motion

%% fcn_INTERNAL_branchColors
function branchColors = fcn_INTERNAL_branchColors(N)
% Blue (hard left) to red (hard right)
fraction = linspace(0,1,max(N,2))';
fraction = fraction(1:N);
branchColors = [0.15+0.75*fraction, 0.35*ones(N,1), 0.9-0.75*fraction];
end % Ends fcn_INTERNAL_branchColors
