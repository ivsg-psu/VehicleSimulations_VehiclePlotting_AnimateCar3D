function [points, tValues] = fcn_AnimateCar3D_getRoadPoints(road, sValues, options)
% fcn_AnimateCar3D_getRoadPoints

% Finds world points on a road from road coordinates, as in ASAM
% OpenDRIVE: s is the distance along the road's reference line, and t
% the distance across it, positive to the left. A point can be given
% from the reference line (T only), or from a lane (LaneID, with T
% measured from the lane's center, inner edge, or outer edge), as an
% ASAM OpenSCENARIO LanePosition is.
%
% The reference line is made of geometry elements (line, arc, and
% spiral, whose curvature changes linearly along it), each starting at
% its own s, x, y, and heading (see fcn_AnimateCar3D_fillRoad).
%
% FORMAT:
%
%       [points, tValues] = fcn_AnimateCar3D_getRoadPoints(road, sValues,...
%           (T=t), (LaneID=laneID), (DrivingLane=k), (LaneEdge=edge),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      road: from fcn_AnimateCar3D_fillRoad (only its PlanView is needed
%      when LaneID is not given).
%
%      sValues: N distances along the reference line, meters. Values
%      outside the road are moved to its nearest end.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      T: offset across the road, meters, positive to the left: one value
%      or N values. Measured from the reference line, or from the lane
%      edge given by LaneID and LaneEdge. Default 0.
%
%      LaneID: an OpenDRIVE lane number (negative on the right of the
%      reference line, positive on the left). Default [] (none).
%
%      DrivingLane: the k-th DRIVING lane from the reference line,
%      counting only lanes of type 'driving': -1 is the first driving lane
%      on the right, -2 the next, 1 the first on the left. Use this to
%      put a vehicle in a lane without knowing the road's medians and
%      shoulders (on the interstate, DrivingLane=-1 is LaneID -3). Given
%      in place of LaneID. Default [] (none).
%
%      LaneEdge: 'center' (default), 'inner' (the edge nearer the
%      reference line), or 'outer'.
%
%      FigNum: a figure to plot the points in, from above. Empty
%      (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      points: N x 3, [x y heading] of each point. The heading is the
%      reference line's at that s.
%
%      tValues: N x 1, each point's t from the reference line.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       road = fcn_AnimateCar3D_fillRoad(Preset='curvy');
%       sValues = (0:1:road.Length)';
%       rightLane = fcn_AnimateCar3D_getRoadPoints(road, sValues, LaneID=-1);
%
%       See the script: script_test_fcn_AnimateCar3D_getRoadPoints.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_getRoadPoints
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_getRoadPoints
%   % * (fill in items here)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    road
    sValues
    options.T = 0                 % offset across the road, meters (left +)
    options.LaneID = []           % OpenDRIVE lane number
    options.DrivingLane = []      % k-th driving lane (-1: first on the right)
    options.LaneEdge = 'center'   % 'center', 'inner', or 'outer'
    options.FigNum = []           % figure to plot the points; -1 for fast mode
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


        % Check the road and sValues inputs
        if ~(isstruct(road) && isfield(road,'PlanView') && ~isempty(road.PlanView))
            error('road must come from fcn_AnimateCar3D_fillRoad');
        end
        if ~isnumeric(sValues) || ~isvector(sValues) || any(~isfinite(sValues))
            error('sValues must be a vector of distances along the road');
        end
        if ~isnumeric(options.T) || ~(isscalar(options.T) || numel(options.T)==numel(sValues))
            error('T must be one value or one per s value');
        end
        if ~isempty(options.DrivingLane)
            if ~isempty(options.LaneID)
                error('Give LaneID or DrivingLane, not both');
            end
            if ~(isnumeric(options.DrivingLane) && isscalar(options.DrivingLane) && options.DrivingLane==round(options.DrivingLane) ...
                    && options.DrivingLane~=0)
                error('DrivingLane must be a whole number other than 0');
            end
            if ~isfield(road,'LaneSections')
                error('A DrivingLane needs a road with lanes (fcn_AnimateCar3D_fillRoad)');
            end
        end
        if ~isempty(options.LaneID)
            if ~isfield(road,'LaneSections')
                error('A LaneID needs a road with lanes (fcn_AnimateCar3D_fillRoad)');
            end
            if ~(isnumeric(options.LaneID) && isscalar(options.LaneID) && options.LaneID==round(options.LaneID))
                error('LaneID must be a whole number');
            end
        end
        if ~any(strcmpi(options.LaneEdge, {'center','inner','outer'}))
            error('LaneEdge must be ''center'', ''inner'', or ''outer''');
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


sValues = sValues(:);
Npoints = numel(sValues);
planView = road.PlanView;
roadLength = planView(end).S + planView(end).Length;
sValues = min(max(sValues, 0), roadLength);

%%%% The reference line at each s
geometryStarts = [planView.S];
geometryIndex = sum(sValues >= geometryStarts, 2);
geometryIndex = max(geometryIndex, 1);
reference = zeros(Npoints, 3);
for ith_geometry = unique(geometryIndex)'
    rows = geometryIndex==ith_geometry;
    reference(rows,:) = fcn_INTERNAL_geometryPoints(planView(ith_geometry), sValues(rows) - planView(ith_geometry).S);
end

%%%% A driving lane, counted among driving lanes only: its lane ID (from
%%%% the first lane section)
laneID = options.LaneID;
if ~isempty(options.DrivingLane)
    if options.DrivingLane < 0
        sideLanes = road.LaneSections(1).Right;
    else
        sideLanes = road.LaneSections(1).Left;
    end
    [~, order] = sort(abs([sideLanes.ID]));
    sideLanes = sideLanes(order);
    drivingIDs = [sideLanes(strcmp({sideLanes.Type}, 'driving')).ID];
    if abs(options.DrivingLane) > numel(drivingIDs)
        error('The road has %d driving lane(s) on that side, not %d', numel(drivingIDs), abs(options.DrivingLane));
    end
    laneID = drivingIDs(abs(options.DrivingLane));
end

%%%% The offset across the road
tOffset = options.T(:) .* ones(Npoints,1);
if ~isempty(laneID)
    tOffset = tOffset + fcn_INTERNAL_laneT(road.LaneSections, sValues, laneID, lower(options.LaneEdge));
end
tValues = tOffset;
points = [reference(:,1) - tValues.*sin(reference(:,3)), reference(:,2) + tValues.*cos(reference(:,3)), reference(:,3)];

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
    referenceLine = fcn_AnimateCar3D_getRoadPoints(road, linspace(0, roadLength, 400)', FigNum=-1);
    plot(referenceLine(:,1), referenceLine(:,2), '-', 'Color', [0.5 0.5 0.5], 'DisplayName', 'reference line');
    plot(points(:,1), points(:,2), '.-', 'Color', [0.10 0.35 0.85], 'DisplayName', 'points');
    axis equal;
    grid on;
    xlabel('X [m]');
    ylabel('Y [m]');
    legend('Location','best');
    title(sprintf('%d road points', Npoints));
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

%% fcn_INTERNAL_geometryPoints
function points = fcn_INTERNAL_geometryPoints(geometry, ds)
% [x y heading] at distances ds along one geometry element
ds = ds(:);
switch geometry.Type
    case 'line'
        heading = geometry.Hdg*ones(size(ds));
        points = [geometry.X + ds*cos(geometry.Hdg), geometry.Y + ds*sin(geometry.Hdg), heading];
    case 'arc'
        curvature = geometry.Curvature;
        if abs(curvature) < 1e-12
            geometry.Type = 'line';
            points = fcn_INTERNAL_geometryPoints(geometry, ds);
            return;
        end
        heading = geometry.Hdg + curvature*ds;
        points = [geometry.X + (sin(heading) - sin(geometry.Hdg))/curvature, ...
                  geometry.Y - (cos(heading) - cos(geometry.Hdg))/curvature, heading];
    case 'spiral'
        % Curvature changes linearly from CurvStart to CurvEnd: integrate
        % the heading on a fine grid (0.05 m)
        curvatureRate = (geometry.CurvEnd - geometry.CurvStart)/geometry.Length;
        headingAt = @(u) geometry.Hdg + geometry.CurvStart*u + 0.5*curvatureRate*u.^2;
        gridEnd = max([ds; 0]);
        fineGrid = linspace(0, gridEnd, max(2, ceil(gridEnd/0.05)+1))';
        fineX = geometry.X + cumtrapz(fineGrid, cos(headingAt(fineGrid)));
        fineY = geometry.Y + cumtrapz(fineGrid, sin(headingAt(fineGrid)));
        if gridEnd==0
            points = repmat([geometry.X geometry.Y geometry.Hdg], numel(ds), 1);
        else
            points = [interp1(fineGrid, fineX, ds), interp1(fineGrid, fineY, ds), headingAt(ds)];
        end
    otherwise
        error('Geometry type ''%s'' is not known (line, arc, or spiral)', geometry.Type);
end
end % Ends fcn_INTERNAL_geometryPoints

%% fcn_INTERNAL_laneT
function tValues = fcn_INTERNAL_laneT(laneSections, sValues, laneID, laneEdge)
% The t of a lane's center or edge at each s. Lane widths are cubic
% polynomials in the distance from the start of their lane section.
sectionStarts = [laneSections.S];
sectionIndex = max(sum(sValues >= sectionStarts, 2), 1);
tValues = NaN(size(sValues));
if laneID==0
    tValues(:) = 0;
    return;
end
for ith_section = unique(sectionIndex)'
    rows = sectionIndex==ith_section;
    ds = sValues(rows) - sectionStarts(ith_section);
    if laneID < 0
        lanes = laneSections(ith_section).Right;
        side = -1;
    else
        lanes = laneSections(ith_section).Left;
        side = 1;
    end
    laneIDs = [lanes.ID];
    if ~any(laneIDs==laneID)
        error('Lane %d is not in the lane section starting at s = %g m', laneID, sectionStarts(ith_section));
    end
    innerT = zeros(size(ds));
    for thisID = side*(1:abs(laneID))
        thisLane = lanes(laneIDs==thisID);
        laneWidth = polyval(fliplr(thisLane.Width), ds);
        if thisID==laneID
            switch laneEdge
                case 'inner'
                    tValues(rows) = side*innerT;
                case 'outer'
                    tValues(rows) = side*(innerT + laneWidth);
                otherwise
                    tValues(rows) = side*(innerT + laneWidth/2);
            end
        end
        innerT = innerT + laneWidth;
    end
end
end % Ends fcn_INTERNAL_laneT
