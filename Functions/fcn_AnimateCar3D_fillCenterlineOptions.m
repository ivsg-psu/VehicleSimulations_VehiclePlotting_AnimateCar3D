function centerlineOptions = fcn_AnimateCar3D_fillCenterlineOptions(road, options)
% fcn_AnimateCar3D_fillCenterlineOptions

% Lists the paths a vehicle can take from a starting point in a scene, as
% lane centerlines in XY, for testing centerline-following and
% decision-making methods. Each path follows lane centers in the
% direction of travel, from the start to the end of the scene:
%
%   - staying in the starting lane;
%   - in each other lane going the same way (a lane change is the
%     user's to plan: the path is that lane's center from the start);
%   - on a road whose center line may be crossed (no median, and not a
%     solid line), in each oncoming lane, against its traffic (passing);
%   - at a junction, through each turn its lane allows (OpenDRIVE
%     connections: left, straight, right), then on along the lane it
%     leads to.
%
% Each path also lists the roads and lanes it uses (as an ASAM
% OpenSCENARIO route would).
%
% FORMAT:
%
%       centerlineOptions = fcn_AnimateCar3D_fillCenterlineOptions(road,...
%           (Start=start), (Spacing=meters), (FigNum=figNum))
%
% INPUTS:
%
%      road: a road or a road network, from fcn_AnimateCar3D_fillRoad.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Start: where the vehicle starts: a structure with Road (the road's
%      ID), LaneID, S, and Direction (+1 along s, -1 against it).
%      Default: the scene's fixed start, road.EgoStart.
%
%      Spacing: meters between points along each path. Default 1.
%
%      FigNum: a figure to draw the road and the paths in, from above.
%      Empty (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      centerlineOptions: a cell array, one structure per path, with:
%           Name: a short name ('stay in lane', 'lane -2', 'oncoming
%               lane 1', 'left turn', ...)
%           Description: in words, with the lanes and roads used
%           XY: N x 2 points along the lane centers
%           Heading: N x 1, the direction of travel, radians
%           S: N x 1, distance along the path from the start, meters
%           Route: the roads and lanes in order (Road, LaneID, Direction,
%               SFrom, STo; junction paths have Road set to the
%               connection's path ID and LaneID 0)
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_getRoadPoints; for the plot,
%      fcn_AnimateCar3D_plotRoad
%
% EXAMPLES:
%
%       [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset='intersection');
%       firstPath = centerlineOptions{1};
%       plot(firstPath.XY(:,1), firstPath.XY(:,2));
%
%       See the script: script_test_fcn_AnimateCar3D_fillCenterlineOptions.m
%       for a full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillCenterlineOptions
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillCenterlineOptions
%   % * Paths through more than one junction (all combinations, or one list per junction); lane-change paths with a chosen length



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    road
    options.Start = []            % Road, LaneID, S, Direction; [] for road.EgoStart
    options.Spacing = 1           % meters between points
    options.FigNum = []           % figure to draw the paths; -1 for fast mode
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


        % Check the road input
        if ~(isstruct(road) && (isfield(road,'PlanView') || isfield(road,'Roads')))
            error('road must come from fcn_AnimateCar3D_fillRoad');
        end
        if isempty(options.Start) && ~isfield(road,'EgoStart')
            error('The road has no EgoStart: give Start');
        end
        if ~isempty(options.Start) && ~(isstruct(options.Start) && all(isfield(options.Start, {'Road','LaneID','S','Direction'})))
            error('Start must have fields Road, LaneID, S, and Direction');
        end
        if ~(isnumeric(options.Spacing) && isscalar(options.Spacing) && options.Spacing > 0)
            error('Spacing must be a positive number of meters');
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


%%%% The roads, the junction connections, and the start
if isfield(road, 'Roads')
    roads = road.Roads;
    connections = [];
    for ith_junction = 1:numel(road.Junctions)
        connections = [connections, road.Junctions(ith_junction).Connections]; %#ok<AGROW>
    end
else
    roads = road;
    connections = [];
end
start = options.Start;
if isempty(start)
    start = road.EgoStart;
end
spacing = options.Spacing;
roadIDs = {roads.ID};
startRoad = roads(strcmp(roadIDs, start.Road));
if isempty(startRoad)
    error('Start road ''%s'' is not in the scene', start.Road);
end

%%%% The lanes to follow: the same-direction driving lanes (the start
%%%% lane first), then any oncoming lanes that may be used for passing
section = startRoad.LaneSections(1);
if start.LaneID < 0
    sameSide = section.Right;
    otherSide = section.Left;
else
    sameSide = section.Left;
    otherSide = section.Right;
end
sameLanes = [sameSide(strcmp({sameSide.Type},'driving')).ID];
[~, order] = sort(abs(sameLanes));
sameLanes = sameLanes(order);
sameLanes = [start.LaneID, sameLanes(sameLanes~=start.LaneID)];
oncomingLanes = [];
flagCrossable = ~strcmp(section.Center.RoadMark.LaneChange, 'none') && ...
    any(strcmp({sameSide(abs([sameSide.ID])==1).Type}, 'driving')) && any(strcmp({otherSide(abs([otherSide.ID])==1).Type}, 'driving'));
if flagCrossable
    oncomingLanes = [otherSide(strcmp({otherSide.Type},'driving')).ID];
    [~, order] = sort(abs(oncomingLanes));
    oncomingLanes = oncomingLanes(order);
end

%%%% Each path
centerlineOptions = {};
for laneID = [sameLanes, oncomingLanes]
    flagOncoming = ismember(laneID, oncomingLanes);
    [firstPiece, routeStep] = fcn_INTERNAL_lanePiece(startRoad, laneID, start.S, start.Direction, spacing);
    if laneID==start.LaneID
        laneName = 'stay in lane';
        laneWords = sprintf('stay in lane %d', laneID);
    elseif flagOncoming
        laneName = sprintf('oncoming lane %d', laneID);
        laneWords = sprintf('oncoming lane %d, against its traffic (passing)', laneID);
    else
        laneName = sprintf('lane %d', laneID);
        laneWords = sprintf('change to lane %d', laneID);
    end

    % At a junction (the lane ends at s = 0, going against s), each turn
    flagAtJunction = start.Direction < 0 && ~isempty(connections) && ~flagOncoming;
    if flagAtJunction
        laneConnections = connections(strcmp({connections.IncomingRoad}, startRoad.ID) & [connections.IncomingLane]==laneID);
    else
        laneConnections = [];
    end
    if isempty(laneConnections)
        centerlineOptions{end+1} = fcn_INTERNAL_option(laneName, laneWords, firstPiece, routeStep); %#ok<AGROW>
        continue;
    end
    for ith_connection = 1:numel(laneConnections)
        thisConnection = laneConnections(ith_connection);
        pathPoints = fcn_AnimateCar3D_getRoadPoints(thisConnection.Path, fcn_INTERNAL_steps(0, thisConnection.Path.Length, spacing), FigNum=-1);
        outRoad = roads(strcmp(roadIDs, thisConnection.OutgoingRoad));
        [lastPiece, lastStep] = fcn_INTERNAL_lanePiece(outRoad, thisConnection.OutgoingLane, 0, 1, spacing);
        pieces = [firstPiece; pathPoints(2:end,:); lastPiece(2:end,:)];
        route = [routeStep; struct('Road',thisConnection.Path.ID, 'LaneID',0, 'Direction',1, 'SFrom',0, ...
            'STo',thisConnection.Path.Length); lastStep];
        if laneID==start.LaneID
            turnName = sprintf('%s turn', thisConnection.Turn);
        else
            turnName = sprintf('lane %d, %s turn', laneID, thisConnection.Turn);
        end
        if strcmp(thisConnection.Turn,'straight')
            turnName = strrep(turnName, 'straight turn', 'straight');
        end
        words = sprintf('%s, then %s onto road %s (lane %d)', laneWords, thisConnection.Turn, outRoad.ID, thisConnection.OutgoingLane);
        centerlineOptions{end+1} = fcn_INTERNAL_option(turnName, words, pieces, route); %#ok<AGROW>
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
    handles = fcn_AnimateCar3D_plotRoad(road, FigNum=figNum);
    hold on;
    pathColors = lines(7);
    pathColors = pathColors([1 2 4 5 6 7],:);          % (no yellow)
    for ith_option = 1:numel(centerlineOptions)
        thisOption = centerlineOptions{ith_option};
        plot3(thisOption.XY(:,1), thisOption.XY(:,2), 0.3*ones(size(thisOption.S)), '-', 'LineWidth', 2.5, ...
            'Color', pathColors(mod(ith_option-1, size(pathColors,1))+1,:), 'DisplayName', thisOption.Name);
    end
    plot3(centerlineOptions{1}.XY(1,1), centerlineOptions{1}.XY(1,2), 0.4, 'o', 'MarkerSize', 10, 'LineWidth', 2, ...
        'Color', [0.10 0.10 0.10], 'DisplayName', 'start');
    view(2);
    axis equal;
    legend(findobj(gca, 'Type', 'line'), 'Location', 'eastoutside', 'Interpreter', 'none');
    title(sprintf('%d path options from the start', numel(centerlineOptions)));
    delete(handles.SeeThrough);                         % (from above, see-through objects would only dim the paths)
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

%% fcn_INTERNAL_steps
function sValues = fcn_INTERNAL_steps(sFrom, sTo, spacing)
% Distances from sFrom to sTo (either way), every spacing meters, with both ends
if sTo >= sFrom
    sValues = unique([sFrom:spacing:sTo, sTo])';
else
    sValues = flipud(unique([sTo, sFrom:-spacing:sTo, sFrom])');
end
end % Ends fcn_INTERNAL_steps

%% fcn_INTERNAL_lanePiece
function [points, routeStep] = fcn_INTERNAL_lanePiece(road, laneID, sStart, direction, spacing)
% A lane's center from sStart to the road's end in the given direction,
% with the heading of travel
if direction > 0
    sEnd = road.Length;
else
    sEnd = 0;
end
sValues = fcn_INTERNAL_steps(sStart, sEnd, spacing);
points = fcn_AnimateCar3D_getRoadPoints(road, sValues, LaneID=laneID, FigNum=-1);
if direction < 0
    points(:,3) = points(:,3) + pi;
end
routeStep = struct('Road',road.ID, 'LaneID',laneID, 'Direction',direction, 'SFrom',sStart, 'STo',sEnd);
end % Ends fcn_INTERNAL_lanePiece

%% fcn_INTERNAL_option
function option = fcn_INTERNAL_option(optionName, words, points, route)
% One path: points, headings (wrapped to -pi..pi), and distance along it
heading = atan2(sin(points(:,3)), cos(points(:,3)));
distance = [0; cumsum(hypot(diff(points(:,1)), diff(points(:,2))))];
option = struct('Name',optionName, 'Description',words, 'XY',points(:,1:2), 'Heading',heading, 'S',distance, ...
    'Route',route);
end % Ends fcn_INTERNAL_option
