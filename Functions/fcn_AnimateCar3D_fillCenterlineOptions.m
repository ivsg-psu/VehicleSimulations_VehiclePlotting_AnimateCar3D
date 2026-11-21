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
%     leads to; when that road ends at another junction, on through it
%     too (up to MaxJunctions junctions), in each lane going that way
%     (changing lanes smoothly, over LaneChangeLength meters at the
%     middle of the road, when the lane is not the one the turn led to).
%     Every combination is listed (a road is not used twice).
%
% Each path also lists the roads and lanes it uses (as an ASAM
% OpenSCENARIO route would).
%
% FORMAT:
%
%       centerlineOptions = fcn_AnimateCar3D_fillCenterlineOptions(road,...
%           (Start=start), (Spacing=meters), (MaxJunctions=n),...
%           (LaneChangeLength=meters), (FigNum=figNum))
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
%      MaxJunctions: the most junctions a path goes through. Default Inf
%      (all of them, to the edge of the scene); 1 for the first only.
%
%      LaneChangeLength: meters over which a path changes lanes between
%      junctions (a smooth step across, at the middle of the road; no
%      longer than 60% of the road). Default 30.
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
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillCenterlineOptions
%   % * Paths through more than one junction (MaxJunctions), with smooth lane changes between them (LaneChangeLength)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillCenterlineOptions
%   % * Lane-change paths with a chosen length on the starting road (now: that lane's center from the start)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    road
    options.Start = []            % Road, LaneID, S, Direction; [] for road.EgoStart
    options.Spacing = 1           % meters between points
    options.MaxJunctions = Inf    % the most junctions a path goes through
    options.LaneChangeLength = 30 % meters, for a lane change between junctions
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
        if ~(isnumeric(options.MaxJunctions) && isscalar(options.MaxJunctions) && options.MaxJunctions >= 1 && ...
                (isinf(options.MaxJunctions) || options.MaxJunctions==round(options.MaxJunctions)))
            error('MaxJunctions must be a whole number, 1 or more, or Inf');
        end
        if ~(isnumeric(options.LaneChangeLength) && isscalar(options.LaneChangeLength) && options.LaneChangeLength > 0)
            error('LaneChangeLength must be a positive number of meters');
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
lanesToFollow = [sameLanes, oncomingLanes];
if isfield(startRoad, 'Loop') && startRoad.Loop
    % A closed course (road.Loop): one lap from the start, along the
    % track's center and along the center of each half
    loopIDs = [0 -1 1];
    loopNames = {'track center', 'right half', 'left half'};
    for ith_path = 1:numel(loopIDs)
        lapS = mod(start.S + fcn_INTERNAL_steps(0, startRoad.Length, spacing), startRoad.Length);
        lapS(end) = start.S;                                % (back to the start: s wraps at Length)
        lapPoints = fcn_AnimateCar3D_getRoadPoints(startRoad, lapS, LaneID=loopIDs(ith_path), FigNum=-1);
        lapStep = struct('Road',startRoad.ID, 'LaneID',loopIDs(ith_path), 'Direction',1, 'SFrom',start.S, 'STo',start.S);
        centerlineOptions{end+1} = fcn_INTERNAL_option(loopNames{ith_path}, ...
            sprintf('one lap, along the %s', loopNames{ith_path}), lapPoints, lapStep); %#ok<AGROW>
    end
    lanesToFollow = [];
end
for laneID = lanesToFollow
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

    % At a junction (where the lane comes in to one), each turn, and on
    % through the junctions after it
    if flagOncoming || isempty(connections)
        continuations = [];
    else
        continuations = fcn_INTERNAL_continue(roads, connections, startRoad.ID, laneID, options.MaxJunctions, ...
            {startRoad.ID}, spacing, options.LaneChangeLength);
    end
    if isempty(continuations)
        centerlineOptions{end+1} = fcn_INTERNAL_option(laneName, laneWords, firstPiece, routeStep); %#ok<AGROW>
        continue;
    end
    for ith_continuation = 1:numel(continuations)
        thisContinuation = continuations(ith_continuation);
        pieces = [firstPiece; thisContinuation.Points];
        route = [routeStep; thisContinuation.Route];
        turnName = strjoin(thisContinuation.Names, ', ');
        if laneID~=start.LaneID
            turnName = sprintf('lane %d, %s', laneID, turnName);
        end
        words = sprintf('%s, then %s', laneWords, strjoin(thisContinuation.Words, ', then '));
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

%% fcn_INTERNAL_continue
function continuations = fcn_INTERNAL_continue(roads, connections, roadID, laneID, junctionsLeft, roadsUsed, spacing, changeLength)
% Every way on from the end of a lane that comes in to a junction:
% through each turn its lane allows, then along the lane the turn leads
% to; if that road ends at another junction too (and junctionsLeft > 1),
% in each of its lanes going that way, on through that junction as well.
% Each continuation has Points (N x 3, x y heading, without the lane's
% last point), Route, Names (one per junction: 'left turn', 'straight',
% 'right turn', after 'lane k' for a lane change), and Words.
roadIDs = {roads.ID};
continuations = struct('Points',{}, 'Route',{}, 'Names',{}, 'Words',{});
laneConnections = connections(strcmp({connections.IncomingRoad}, roadID) & [connections.IncomingLane]==laneID);
for ith_connection = 1:numel(laneConnections)
    thisConnection = laneConnections(ith_connection);
    if any(strcmp(roadsUsed, thisConnection.OutgoingRoad))
        continue;                                   % (no road twice)
    end
    pathPoints = fcn_AnimateCar3D_getRoadPoints(thisConnection.Path, fcn_INTERNAL_steps(0, thisConnection.Path.Length, spacing), FigNum=-1);
    pathStep = struct('Road',thisConnection.Path.ID, 'LaneID',0, 'Direction',1, 'SFrom',0, 'STo',thisConnection.Path.Length);
    outRoad = roads(strcmp(roadIDs, thisConnection.OutgoingRoad));
    outLane = thisConnection.OutgoingLane;
    % (going out: the right lanes run along s from 0, the left lanes
    % against it from the road's end)
    direction = -sign(outLane);
    if direction > 0
        outS = 0;
    else
        outS = outRoad.Length;
    end
    turnName = sprintf('%s turn', thisConnection.Turn);
    if strcmp(thisConnection.Turn, 'straight')
        turnName = 'straight';
    end
    turnWords = sprintf('%s onto road %s (lane %d)', thisConnection.Turn, outRoad.ID, outLane);

    % The lanes going this way on the next road that come in to a junction
    nextLanes = [];
    if junctionsLeft > 1
        section = outRoad.LaneSections(1);
        if direction > 0
            sameSide = section.Right;
        else
            sameSide = section.Left;
        end
        sameLanes = [sameSide(strcmp({sameSide.Type},'driving')).ID];
        [~, order] = sort(abs(sameLanes - outLane));
        sameLanes = sameLanes(order);                 % (the turn's own lane first)
        flagIn = arrayfun(@(lane) any(strcmp({connections.IncomingRoad}, outRoad.ID) & [connections.IncomingLane]==lane), sameLanes);
        nextLanes = sameLanes(flagIn);
    end
    if isempty(nextLanes)
        [lastPiece, lastStep] = fcn_INTERNAL_lanePiece(outRoad, outLane, outS, direction, spacing);
        continuations(end+1) = struct('Points',[pathPoints(2:end,:); lastPiece(2:end,:)], 'Route',[pathStep; lastStep], ...
            'Names',{{turnName}}, 'Words',{{turnWords}}); %#ok<AGROW>
        continue;
    end
    for nextLane = nextLanes
        [lastPiece, lastStep] = fcn_INTERNAL_changePiece(outRoad, outLane, nextLane, outS, direction, spacing, changeLength);
        laterOnes = fcn_INTERNAL_continue(roads, connections, outRoad.ID, nextLane, junctionsLeft - 1, ...
            [roadsUsed, {outRoad.ID}], spacing, changeLength);
        words = turnWords;
        if nextLane ~= outLane
            words = sprintf('%s, changing to lane %d', turnWords, nextLane);
        end
        if isempty(laterOnes)
            continuations(end+1) = struct('Points',[pathPoints(2:end,:); lastPiece(2:end,:)], 'Route',[pathStep; lastStep], ...
                'Names',{{turnName}}, 'Words',{{words}}); %#ok<AGROW>
            continue;
        end
        for ith_later = 1:numel(laterOnes)
            laterNames = laterOnes(ith_later).Names;
            if nextLane ~= outLane
                laterNames{1} = sprintf('lane %d, %s', nextLane, laterNames{1});
            end
            continuations(end+1) = struct('Points',[pathPoints(2:end,:); lastPiece(2:end,:); laterOnes(ith_later).Points], ...
                'Route',[pathStep; lastStep; laterOnes(ith_later).Route], 'Names',{[{turnName}, laterNames]}, ...
                'Words',{[{words}, laterOnes(ith_later).Words]}); %#ok<AGROW>
        end
    end
end
end % Ends fcn_INTERNAL_continue

%% fcn_INTERNAL_changePiece
function [points, routeStep] = fcn_INTERNAL_changePiece(road, fromLane, toLane, sStart, direction, spacing, changeLength)
% A lane's center from sStart to the road's end, changing from fromLane
% to toLane over changeLength meters (a smooth step) at the road's middle
[points, routeStep] = fcn_INTERNAL_lanePiece(road, toLane, sStart, direction, spacing);
if fromLane==toLane
    return;
end
sValues = fcn_INTERNAL_steps(sStart, routeStep.STo, spacing);
[~, fromT] = fcn_AnimateCar3D_getRoadPoints(road, sValues, LaneID=fromLane, FigNum=-1);
[~, toT] = fcn_AnimateCar3D_getRoadPoints(road, sValues, LaneID=toLane, FigNum=-1);
traveled = abs(sValues - sStart);
roadLength = abs(routeStep.STo - sStart);
changeLength = min(changeLength, 0.6*roadLength);
progress = min(max((traveled - (roadLength - changeLength)/2)/changeLength, 0), 1);
blend = 3*progress.^2 - 2*progress.^3;
points = fcn_AnimateCar3D_getRoadPoints(road, sValues, T=fromT + (toT - fromT).*blend, FigNum=-1);
% (the heading of travel, from the points themselves)
points(:,3) = atan2(gradient(points(:,2)), gradient(points(:,1)));
routeStep.LaneID = toLane;
end % Ends fcn_INTERNAL_changePiece

%% fcn_INTERNAL_option
function option = fcn_INTERNAL_option(optionName, words, points, route)
% One path: points, headings (wrapped to -pi..pi), and distance along it
heading = atan2(sin(points(:,3)), cos(points(:,3)));
distance = [0; cumsum(hypot(diff(points(:,1)), diff(points(:,2))))];
option = struct('Name',optionName, 'Description',words, 'XY',points(:,1:2), 'Heading',heading, 'S',distance, ...
    'Route',route);
end % Ends fcn_INTERNAL_option
