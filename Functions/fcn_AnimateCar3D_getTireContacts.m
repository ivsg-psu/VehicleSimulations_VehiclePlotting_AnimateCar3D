function contacts = fcn_AnimateCar3D_getTireContacts(road, poses, options)
% fcn_AnimateCar3D_getTireContacts

% Finds the road surface under a vehicle and under each of its tires, for
% simulating suspensions on roads with grades and banking: for each pose
% (vectorized over any number of poses, for example a whole motion), the
% height, surface normal, grade, and cross slope at each tire's contact
% point and under the vehicle's center, and the pose a rigid vehicle
% would have resting on its four contact points.
%
% The vehicle's reference point is the center of its rear axle, on the
% ground (as in CarMesh3D): the rear tires are at x = 0, the front tires
% at x = Wheelbase, each pair Track/2 to either side. The tires are in
% the IVSG and CarMesh3D order: front left, rear left, rear right, front
% right (FL, RL, RR, FR).
%
% Heights are the road's (elevation plus superelevation, from
% fcn_AnimateCar3D_getRoadHeight) plus, with LaneHeights true, the
% height of the lane each point is on (OpenDRIVE lane <height>: curbs,
% sidewalks, the race course's banked curbs), from its inner to its outer
% edge. Grades and cross slopes are measured along the vehicle's heading
% and across it, over ProbeDistance either way.
%
% FORMAT:
%
%       contacts = fcn_AnimateCar3D_getTireContacts(road, poses,...
%           (VehicleSpec=spec), (Wheelbase=meters), (TrackFront=meters),...
%           (TrackRear=meters), (LaneHeights=flag), (ProbeDistance=meters),...
%           (Spacing=meters), (FigNum=figNum))
%
% INPUTS:
%
%      road: a road or a road network, from fcn_AnimateCar3D_fillRoad.
%
%      poses: N x 3 [x y yaw], or N x 6 [x y z roll pitch yaw] (z, roll,
%      and pitch are not used), meters and radians: the reference point
%      (the rear axle's center) and heading, one row per time. A motion's
%      Pose (fcn_AnimateCar3D_fillPathMotion) can be given as it is.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      VehicleSpec: a vehicle specification (fcn_CarMesh3D_fillVehicleSpec)
%      for the wheelbase and tracks. Default []: a midsize sedan's (2.8 m
%      wheelbase, 1.6 m tracks).
%
%      Wheelbase, TrackFront, TrackRear: meters, each overriding the
%      VehicleSpec's. Default []. TrackRear, if not given anywhere, is
%      TrackFront.
%
%      LaneHeights: add the heights of the lanes (curbs, sidewalks, banked
%      curbs). Default true. (A junction's raised surfaces are not
%      included.)
%
%      ProbeDistance: meters along and across the heading, either way,
%      over which each grade and cross slope (and so each normal) is
%      measured. Default 0.25.
%
%      Spacing: meters between the reference-line samples searched for the
%      nearest road point (fcn_AnimateCar3D_getRoadHeight). Default 0.5.
%
%      FigNum: a figure to plot the tire heights, grades, and cross slopes
%      against the pose number. Empty (default) for no figure; -1 for fast
%      mode (no input checks).
%
% OUTPUTS:
%
%      contacts: a structure with
%           TireNames: {'FL','RL','RR','FR'}
%           TireXY: N x 4 x 2, the contact points (x, y)
%           TireZ: N x 4, the road's height at each contact point
%           TireNormal: N x 4 x 3, the surface's unit normal (up)
%           TireGrade: N x 4, rise over run along the heading (positive:
%               uphill going forward)
%           TireCrossSlope: N x 4, rise over run across the heading,
%               toward the vehicle's left (positive: the left side higher)
%           TireS, TireT, TireRoad: N x 4, each contact point's road
%               coordinates and road (index into the network's Roads; 1
%               for a single road)
%           CenterXY, CenterZ, CenterNormal (N x 3), CenterGrade,
%               CenterCrossSlope: the same, under the vehicle's center
%               (midway between the axles)
%           Pose: N x 6 [x y z roll pitch yaw], the pose of a rigid
%               vehicle resting on its contact points (the plane through
%               them, fitted by least squares): z the plane's height at
%               the reference point; roll positive with the right side
%               down; pitch positive with the nose down (CarMesh3D's
%               convention)
%           Wheelbase, TrackFront, TrackRear: the geometry used
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_getRoadHeight, fcn_AnimateCar3D_getRoadPoints
%
% EXAMPLES:
%
%       scenario = fcn_AnimateCar3D_fillExampleScenario('curvyHills');
%       spec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan');
%       contacts = fcn_AnimateCar3D_getTireContacts(scenario.Road, ...
%           scenario.Motions{1}.Pose, VehicleSpec=spec);
%       plot(scenario.Motions{1}.Time, contacts.TireZ);
%
%       See the script: script_test_fcn_AnimateCar3D_getTireContacts.m
%       for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_getTireContacts
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_getTireContacts
%   % * A tire's contact patch (an area, averaged) in place of a point; a junction's raised surfaces; a separate library, if wanted



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    road
    poses
    options.VehicleSpec = []        % fcn_CarMesh3D_fillVehicleSpec; [] for a midsize sedan
    options.Wheelbase = []          % meters; [] for the VehicleSpec's
    options.TrackFront = []         % meters; [] for the VehicleSpec's
    options.TrackRear = []          % meters; [] for the VehicleSpec's (or TrackFront)
    options.LaneHeights = true      % add lane heights (curbs, sidewalks)
    options.ProbeDistance = 0.25    % meters, for grades and cross slopes
    options.Spacing = 0.5           % meters, reference-line search spacing
    options.FigNum = []             % figure for the plot; -1 for fast mode
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


        if ~(isstruct(road) && (isfield(road,'PlanView') || isfield(road,'Roads')))
            error('road must come from fcn_AnimateCar3D_fillRoad');
        end
        if ~(isnumeric(poses) && ismatrix(poses) && any(size(poses,2)==[3 6]) && size(poses,1) >= 1 && all(isfinite(poses(:))))
            error('poses must be N x 3 [x y yaw] or N x 6 [x y z roll pitch yaw]');
        end
        if ~isempty(options.VehicleSpec) && ~(isstruct(options.VehicleSpec) && all(isfield(options.VehicleSpec, {'Wheelbase','TrackFront','TrackRear'})))
            error('VehicleSpec must come from fcn_CarMesh3D_fillVehicleSpec');
        end
        for fieldName = {'Wheelbase','TrackFront','TrackRear','ProbeDistance','Spacing'}
            thisValue = options.(fieldName{1});
            if ~isempty(thisValue) && ~(isnumeric(thisValue) && isscalar(thisValue) && thisValue > 0)
                error('%s must be a positive number of meters', fieldName{1});
            end
        end
        if ~(islogical(options.LaneHeights) || isnumeric(options.LaneHeights)) || ~isscalar(options.LaneHeights)
            error('LaneHeights must be true or false');
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


%%%% The geometry: options first, then the VehicleSpec, then a sedan's
spec = options.VehicleSpec;
wheelbase = fcn_INTERNAL_first(options.Wheelbase, fcn_INTERNAL_field(spec, 'Wheelbase'), 2.8);
trackFront = fcn_INTERNAL_first(options.TrackFront, fcn_INTERNAL_field(spec, 'TrackFront'), 1.6);
trackRear = fcn_INTERNAL_first(options.TrackRear, fcn_INTERNAL_field(spec, 'TrackRear'), trackFront);

%%%% Every point at once: for each pose, 4 tires and the center, each
%%%% with 5 probes (the point, ahead, behind, left, right)
Nposes = size(poses,1);
x = poses(:,1); y = poses(:,2); yaw = poses(:,end);
forward = [cos(yaw) sin(yaw)];
left = [-sin(yaw) cos(yaw)];
alongX = [wheelbase 0 0 wheelbase wheelbase/2];              % FL RL RR FR, center
acrossY = [trackFront/2 trackRear/2 -trackRear/2 -trackFront/2 0];
Nspots = numel(alongX);
probe = options.ProbeDistance;
probeAlong = [0 probe -probe 0 0];
probeAcross = [0 0 0 probe -probe];
spotX = x + forward(:,1).*alongX + left(:,1).*acrossY;        % N x 5
spotY = y + forward(:,2).*alongX + left(:,2).*acrossY;
allX = zeros(Nposes, Nspots, 5); allY = allX;
for ith_probe = 1:5
    allX(:,:,ith_probe) = spotX + forward(:,1)*probeAlong(ith_probe) + left(:,1)*probeAcross(ith_probe);
    allY(:,:,ith_probe) = spotY + forward(:,2)*probeAlong(ith_probe) + left(:,2)*probeAcross(ith_probe);
end
[allZ, allS, allT, allRoad] = fcn_AnimateCar3D_getRoadHeight(road, [allX(:) allY(:)], Spacing=options.Spacing, FigNum=-1);
if options.LaneHeights
    allZ = allZ + fcn_INTERNAL_laneHeights(road, allS, allT, allRoad);
end
allZ = reshape(allZ, Nposes, Nspots, 5);
allS = reshape(allS, Nposes, Nspots, 5);
allT = reshape(allT, Nposes, Nspots, 5);
allRoad = reshape(allRoad, Nposes, Nspots, 5);

%%%% Heights, slopes, and normals
spotZ = allZ(:,:,1);
grade = (allZ(:,:,2) - allZ(:,:,3))/(2*probe);
crossSlope = (allZ(:,:,4) - allZ(:,:,5))/(2*probe);
% (the normal: the cross product of the surface's forward and leftward
% directions, [forward, grade] x [left, crossSlope])
forwardX = repmat(forward(:,1), 1, Nspots); forwardY = repmat(forward(:,2), 1, Nspots);
leftX = repmat(left(:,1), 1, Nspots); leftY = repmat(left(:,2), 1, Nspots);
normalX = forwardY.*crossSlope - grade.*leftY;
normalY = grade.*leftX - forwardX.*crossSlope;
normalZ = forwardX.*leftY - forwardY.*leftX;
normalLength = sqrt(normalX.^2 + normalY.^2 + normalZ.^2);
normals = cat(3, normalX, normalY, normalZ)./normalLength;

%%%% A rigid vehicle on its four contact points: the plane z = a + b*u +
%%%% c*v (u along the heading from the reference point, v to the left),
%%%% by least squares
design = [ones(4,1) alongX(1:4)' acrossY(1:4)'];
planeFit = (design\spotZ(:,1:4)')';                            % N x 3: a, b, c
bodyPitch = -atan(planeFit(:,2));                              % (nose down positive)
bodyRoll = atan(planeFit(:,3));                                % (right side down positive: the left higher)
bodyPose = [x y planeFit(:,1) bodyRoll bodyPitch yaw];

contacts = struct('TireNames',{{'FL','RL','RR','FR'}}, ...
    'TireXY',cat(3, spotX(:,1:4), spotY(:,1:4)), 'TireZ',spotZ(:,1:4), 'TireNormal',normals(:,1:4,:), ...
    'TireGrade',grade(:,1:4), 'TireCrossSlope',crossSlope(:,1:4), ...
    'TireS',allS(:,1:4,1), 'TireT',allT(:,1:4,1), 'TireRoad',allRoad(:,1:4,1), ...
    'CenterXY',[spotX(:,5) spotY(:,5)], 'CenterZ',spotZ(:,5), 'CenterNormal',squeeze(normals(:,5,:)), ...
    'CenterGrade',grade(:,5), 'CenterCrossSlope',crossSlope(:,5), ...
    'Pose',bodyPose, 'Wheelbase',wheelbase, 'TrackFront',trackFront, 'TrackRear',trackRear);
if Nposes==1
    contacts.CenterNormal = reshape(contacts.CenterNormal, 1, 3);
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
    tireColors = [0.10 0.35 0.85; 0.20 0.60 0.30; 0.80 0.15 0.12; 0.55 0.25 0.65];   % (no yellow)
    poseNumbers = (1:size(poses,1))';
    subplot(3,1,1);
    hold on;
    for ith_tire = 1:4
        plot(poseNumbers, contacts.TireZ(:,ith_tire), '-', 'Color', tireColors(ith_tire,:), 'LineWidth', 1.5, ...
            'DisplayName', contacts.TireNames{ith_tire});
    end
    ylabel('Height [m]');
    legend('Location','best');
    grid on;
    title(sprintf('Road under the tires, %d poses', size(poses,1)));
    subplot(3,1,2);
    hold on;
    for ith_tire = 1:4
        plot(poseNumbers, 100*contacts.TireGrade(:,ith_tire), '-', 'Color', tireColors(ith_tire,:), 'LineWidth', 1.5);
    end
    ylabel('Grade [%]');
    grid on;
    subplot(3,1,3);
    hold on;
    for ith_tire = 1:4
        plot(poseNumbers, 100*contacts.TireCrossSlope(:,ith_tire), '-', 'Color', tireColors(ith_tire,:), 'LineWidth', 1.5);
    end
    ylabel('Cross slope [%]');
    xlabel('Pose number');
    grid on;
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

%% fcn_INTERNAL_first
function value = fcn_INTERNAL_first(varargin)
% The first non-empty value
value = [];
for ith_value = 1:nargin
    if ~isempty(varargin{ith_value})
        value = varargin{ith_value};
        return;
    end
end
end % Ends fcn_INTERNAL_first

%% fcn_INTERNAL_field
function value = fcn_INTERNAL_field(spec, fieldName)
% A field of the vehicle spec, or [] if there is none
value = [];
if isstruct(spec) && isfield(spec, fieldName)
    value = spec.(fieldName);
end
end % Ends fcn_INTERNAL_field

%% fcn_INTERNAL_laneHeights
function heights = fcn_INTERNAL_laneHeights(road, sValues, tValues, roadIndex)
% The height of the lane at each road point (OpenDRIVE lane <height>):
% from the lane's inner edge to its outer edge, linearly; beyond the
% outermost lane, its outer height
if isfield(road, 'Roads')
    roads = road.Roads;
else
    roads = road;
end
heights = zeros(size(sValues));
for ith_road = unique(roadIndex)'
    thisRoad = roads(ith_road);
    sections = thisRoad.LaneSections;
    sectionStarts = [sections.S];
    rows = find(roadIndex==ith_road);
    sectionIndex = discretize(sValues(rows), [sectionStarts, Inf]);
    sectionIndex(isnan(sectionIndex)) = 1;
    for ith_section = unique(sectionIndex)'
        here = rows(sectionIndex==ith_section);
        thisSection = sections(ith_section);
        ds = sValues(here) - thisSection.S;
        for side = [-1 1]
            if side < 0
                lanes = thisSection.Right;
            else
                lanes = thisSection.Left;
            end
            if isempty(lanes)
                continue;
            end
            [~, order] = sort(abs([lanes.ID]));
            lanes = lanes(order);
            onSide = side*tValues(here) > 0;
            distanceOut = side*tValues(here);
            innerEdge = zeros(numel(here),1);
            for ith_lane = 1:numel(lanes)
                widthCubic = lanes(ith_lane).Width;
                laneWidth = widthCubic(1) + widthCubic(2)*ds + widthCubic(3)*ds.^2 + widthCubic(4)*ds.^3;
                outerEdge = innerEdge + max(laneWidth, 0);
                laneHeight = lanes(ith_lane).Height;
                if isempty(laneHeight)
                    laneHeight = [0 0];
                end
                inLane = onSide & distanceOut >= innerEdge & (distanceOut < outerEdge | ith_lane==numel(lanes));
                fraction = min(max((distanceOut - innerEdge)./max(outerEdge - innerEdge, eps), 0), 1);
                heights(here(inLane)) = laneHeight(1) + (laneHeight(end) - laneHeight(1))*fraction(inLane);
                innerEdge = outerEdge;
            end
        end
    end
end
end % Ends fcn_INTERNAL_laneHeights
