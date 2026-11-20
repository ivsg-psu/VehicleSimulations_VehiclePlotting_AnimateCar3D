function road = fcn_AnimateCar3D_fillRoad(options)
% fcn_AnimateCar3D_fillRoad

% Fills a road description, laid out as an ASAM OpenDRIVE road, from a
% preset. A PROTOTYPE: it is planned to move to a scene-building
% repository, which may read and write OpenDRIVE (.xodr) files. The
% field names follow OpenDRIVE's elements and attributes, so that the
% step to OpenDRIVE files is short.
%
% THE ROAD (OpenDRIVE <road>):
%
%   PlanView: the reference line (OpenDRIVE <planView>): geometry
%       elements, each with S (start, meters along the road), X, Y, Hdg
%       (heading, rad), Length, and Type: 'line'; 'arc' (Curvature,
%       1/m, positive to the left); or 'spiral' (CurvStart, CurvEnd: the
%       curvature changes linearly along it, so that lines and arcs join
%       without a jump in curvature).
%   LaneSections: (OpenDRIVE <laneSection>) each with S (its start), and
%       its lanes in Left (IDs 1, 2, ... outward), Center (ID 0, on the
%       reference line, carrying only a road mark), and Right (IDs -1,
%       -2, ... outward). Traffic on right-hand roads drives on the right
%       lanes in the direction of s. Each lane has:
%         ID, Type ('driving', 'shoulder', 'border', 'median', 'curb',
%           'walking', ... as OpenDRIVE's lane types)
%         Width: [a b c d], width = a + b*ds + c*ds^2 + d*ds^3, ds from
%           the start of the lane section (OpenDRIVE <width>)
%         Height: [inner outer], the surface height above the road at
%           the lane's edges (OpenDRIVE <height>), meters
%         RoadMark: the mark on the lane's OUTER edge (OpenDRIVE
%           <roadMark>): Type ('none', 'solid', 'broken', 'solid solid',
%           'solid broken', 'broken solid', 'broken broken'), Color
%           ('standard' (white), 'white', 'yellow'), Width (meters),
%           LineLength and LineSpace (meters, for broken lines),
%           LaneChange ('both', 'increase', 'decrease', 'none'). In a
%           double mark, the first word is the line on the left (+t).
%   Objects: (OpenDRIVE <object>) each with ID, Type ('barrier',
%       'crosswalk', 'tree', 'building'), Name, S and T (its center),
%       ZOffset, Length (along the road), Width (across), Height, Hdg
%       (relative to the road), Repeat (true: it runs along the road from
%       S for Length, as OpenDRIVE's <repeat>), and Color ([] for the
%       default).
%   Length, Name, ID, TrafficRule ('RHT'), and Units ('meters, radians').
%
% PRESETS (US-style markings, lanes 3.6 m wide):
%
%   'twoLane': a straight undivided road, one lane each way, 300 m: a
%       broken yellow center line, solid white edge lines, 1.8 m
%       shoulders, and grass borders.
%   'curvy': the same road, curving left and right (lines, spirals, and
%       arcs of 60 m and 50 m radius), about 400 m.
%   'interstate': a straight divided highway, 4 lanes each way, 400 m:
%       broken white lines between lanes, a solid yellow line at the
%       inside shoulder and a solid white line at the outside shoulder,
%       and a concrete barrier on the median.
%   'urbanStreet': a straight two-lane street, 200 m: a double yellow
%       center line, curbs 0.15 m high, sidewalks, a crosswalk, block
%       trees, and buildings made at random (repeatably, from Seed), set
%       back BuildingSetback meters behind the sidewalks, on both sides
%       (BuildingSides): tall on the far side, low and drawn see-through
%       on the near side, so a camera following traffic is not hidden.
%   'neighborhood': a straight residential street, two lanes, no center
%       line, 1200 m (three blocks): curbs, a grass strip with street
%       trees, sidewalks, and front lawns; small houses on lots about
%       20 m wide, with an occasional open park (a lawn with block trees)
%       in place of a few lots; and a crosswalk at the end of each block
%       (every BlockLength meters). Houses follow BuildingSetback (their
%       front yard) and BuildingSides.
%   'intersection': four arms (Length each, 80 m) meeting at a junction
%       (OpenDRIVE <junction>): on each arm, 2 lanes out and 2 lanes in
%       (a left-turn lane, and a through and right-turn lane), or with
%       RightTurnLane true, 3 lanes in (left, through, and right); a
%       double yellow center line; curbs and sidewalks, joined at the
%       corners; crosswalks, stop lines, and lane arrows. This preset
%       returns a road NETWORK (see OUTPUTS).
%
% The urban street, neighborhood, and intersection have occasional
% pedestrians standing on the sidewalks (road objects of type
% 'pedestrian', for scenery; moving pedestrians belong in the scenario).
%
% FORMAT:
%
%       road = fcn_AnimateCar3D_fillRoad((Preset=preset), (Length=meters),...
%           (LaneWidth=meters), (LanesEachWay=n), (CenterMark=type),...
%           (Start=[x y heading]), (Seed=seed), (BuildingSetback=meters),...
%           (BuildingSides=sides), (BlockLength=meters),...
%           (RightTurnLane=flag), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Preset: 'twoLane' (default), 'curvy', 'interstate',
%      'urbanStreet', 'neighborhood', or 'intersection'.
%
%      Length: the road length, meters (straight presets). Default: the
%      preset's.
%
%      LaneWidth: meters. Default 3.6.
%
%      LanesEachWay: driving lanes in each direction ('interstate').
%      Default 4.
%
%      CenterMark: the center line's mark type (two-way presets), for
%      example 'solid solid' for no passing. Default: the preset's.
%
%      Start: [x y heading] where the reference line starts. Default
%      [0 0 0].
%
%      Seed: the random number seed for everything placed at random:
%      buildings, houses, parks, and pedestrians. The same Seed always
%      gives the same scene; another Seed, another scene with the same
%      layout. The scene is made with its own random number stream, so it
%      neither depends on nor changes MATLAB's global random numbers
%      (rng). A whole number, 0 or more. Default 1.
%
%      BuildingSetback: meters from the back of the sidewalk to the
%      buildings ('urbanStreet'). Default 6.
%
%      BuildingSides: where the buildings are: 'both', 'left' (the side of
%      oncoming traffic), 'right' (the near side: the side of traffic in
%      the right-hand lanes), or 'none'. Default: 'both' for
%      'urbanStreet', 'left' for 'neighborhood'. Near-side buildings are
%      mostly one story (3.5 to 4.5 m), sometimes two (6.5 to 7.5 m,
%      about 1 in 7), and fcn_AnimateCar3D_plotRoad draws them see-
%      through (NearSideAlpha, 0.3), so a camera beside and behind
%      traffic sees through and over them.
%
%      FigNum: a figure to draw the road in (fcn_AnimateCar3D_plotRoad).
%      Empty (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      road: the road (see above). For 'intersection', a road network: a
%      structure with ID, Name, TrafficRule, Units, Roads (the four arms,
%      each a road as above, starting at the junction and pointing away
%      from it: on each arm, the left lanes come in and the right lanes
%      go out), and Junctions: ID, Type, Center, Surfaces (flat
%      quadrilaterals: Corners 4 x 2, Height, Type) and CurbFaces (Ends
%      2 x 2, Height), for the area where the arms meet.
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_getRoadPoints; for the plot,
%      fcn_AnimateCar3D_plotRoad
%
% EXAMPLES:
%
%       road = fcn_AnimateCar3D_fillRoad(Preset='interstate', LanesEachWay=3);
%       fcn_AnimateCar3D_plotRoad(road, FigNum=1);
%
%       See the script: script_test_fcn_AnimateCar3D_fillRoad.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillRoad
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillRoad
%   % * Intersections (OpenDRIVE junctions); reading and writing OpenDRIVE (.xodr) files (planned for the scene-building repository)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    options.Preset = 'twoLane'      % 'twoLane', 'curvy', 'interstate', 'urbanStreet'
    options.Length = []             % meters (straight presets)
    options.LaneWidth = 3.6         % meters
    options.LanesEachWay = 4        % driving lanes each way ('interstate')
    options.CenterMark = ''         % center line mark type; '' for the preset's
    options.Start = [0 0 0]         % [x y heading] of the reference line start
    options.Seed = 1                % random seed: the same Seed, the same scene
    options.BuildingSetback = 6     % meters behind the sidewalk ('urbanStreet')
    options.BuildingSides = ''      % 'both', 'left', 'right', 'none'; '' for the preset's
    options.BlockLength = 400       % meters between crosswalks ('neighborhood')
    options.RightTurnLane = false   % separate right-turn lanes ('intersection')
    options.FigNum = []             % figure to draw the road; -1 for fast mode
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


        % Check the choices
        presetNames = {'twoLane','curvy','interstate','urbanStreet','neighborhood','intersection'};
        if ~any(strcmpi(options.Preset, presetNames))
            error('Preset must be one of: %s', strjoin(presetNames, ', '));
        end
        markTypes = {'none','solid','broken','solid solid','solid broken','broken solid','broken broken'};
        if ~isempty(options.CenterMark) && ~any(strcmpi(options.CenterMark, markTypes))
            error('CenterMark must be one of: %s', strjoin(markTypes, ', '));
        end

        % Check the numbers
        if ~isempty(options.Length) && ~(isnumeric(options.Length) && isscalar(options.Length) && options.Length > 0)
            error('Length must be a positive number of meters');
        end
        if ~(isnumeric(options.LaneWidth) && isscalar(options.LaneWidth) && options.LaneWidth > 0)
            error('LaneWidth must be a positive number of meters');
        end
        if ~(isnumeric(options.LanesEachWay) && isscalar(options.LanesEachWay) && options.LanesEachWay >= 1 ...
                && options.LanesEachWay==round(options.LanesEachWay))
            error('LanesEachWay must be a whole number, 1 or more');
        end
        if ~((islogical(options.RightTurnLane) || isnumeric(options.RightTurnLane)) && isscalar(options.RightTurnLane))
            error('RightTurnLane must be true or false');
        end
        if ~(isnumeric(options.Seed) && isscalar(options.Seed) && options.Seed >= 0 && options.Seed==round(options.Seed))
            error('Seed must be a whole number, 0 or more');
        end
        if ~(isnumeric(options.BlockLength) && isscalar(options.BlockLength) && options.BlockLength > 0)
            error('BlockLength must be a positive number of meters');
        end
        if ~(isnumeric(options.BuildingSetback) && isscalar(options.BuildingSetback) && options.BuildingSetback >= 0)
            error('BuildingSetback must be a number of meters, 0 or more');
        end
        if ~isempty(options.BuildingSides) && ~any(strcmpi(options.BuildingSides, {'both','left','right','none'}))
            error('BuildingSides must be ''both'', ''left'', ''right'', or ''none''');
        end
        if ~(isnumeric(options.Start) && numel(options.Start)==3)
            error('Start must be [x y heading]');
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


presetName = lower(char(options.Preset));
laneWidth = options.LaneWidth;
if strcmp(presetName, 'intersection')
    % A road network: four arms and a junction
    road = fcn_INTERNAL_intersection(options, laneWidth);
else
    road = struct('ID','1', 'Name',char(options.Preset), 'TrafficRule','RHT', 'Units','meters, radians', ...
        'Length',0, 'PlanView',[], 'LaneSections',[], 'Objects',fcn_INTERNAL_object('', '', 0, 0, 0, 0, 0, 0));
    road.Objects(1) = [];
    white = 'standard';

    switch presetName
        case {'twolane','curvy'}
            centerMark = fcn_INTERNAL_pick(options.CenterMark, 'broken');
            if strcmp(presetName,'twolane')
                segments = fcn_INTERNAL_segment('line', fcn_INTERNAL_pick(options.Length, 300), 0, 0);
            else
                % Left, then right: line, spiral in, arc, spiral out (the
                % spirals keep the curvature from jumping)
                segments = [fcn_INTERNAL_segment('line', 40, 0, 0); ...
                            fcn_INTERNAL_segment('spiral', 30, 0, 1/60); ...
                            fcn_INTERNAL_segment('arc', 60, 1/60, 1/60); ...
                            fcn_INTERNAL_segment('spiral', 30, 1/60, 0); ...
                            fcn_INTERNAL_segment('line', 40, 0, 0); ...
                            fcn_INTERNAL_segment('spiral', 30, 0, -1/50); ...
                            fcn_INTERNAL_segment('arc', 70, -1/50, -1/50); ...
                            fcn_INTERNAL_segment('spiral', 30, -1/50, 0); ...
                            fcn_INTERNAL_segment('line', 80, 0, 0)];
            end
            rightLanes = [fcn_INTERNAL_lane(-1, 'driving', laneWidth, 0, 'solid', white); ...
                          fcn_INTERNAL_lane(-2, 'shoulder', 1.8, 0, 'none', white); ...
                          fcn_INTERNAL_lane(-3, 'border', 4.0, 0, 'none', white)];
            centerLane = fcn_INTERNAL_lane(0, 'none', 0, 0, centerMark, 'yellow');

        case 'interstate'
            segments = fcn_INTERNAL_segment('line', fcn_INTERNAL_pick(options.Length, 400), 0, 0);
            Nlanes = options.LanesEachWay;
            rightLanes = [fcn_INTERNAL_lane(-1, 'median', 0.6, 0, 'none', white); ...
                          fcn_INTERNAL_lane(-2, 'shoulder', 1.2, 0, 'solid', 'yellow')];
            for ith_lane = 1:Nlanes
                if ith_lane < Nlanes
                    markType = 'broken';
                else
                    markType = 'solid';
                end
                rightLanes(end+1,1) = fcn_INTERNAL_lane(-(2+ith_lane), 'driving', laneWidth, 0, markType, white); %#ok<AGROW>
            end
            rightLanes(end+1,1) = fcn_INTERNAL_lane(-(Nlanes+3), 'shoulder', 3.0, 0, 'none', white);
            rightLanes(end+1,1) = fcn_INTERNAL_lane(-(Nlanes+4), 'border', 4.0, 0, 'none', white);
            centerLane = fcn_INTERNAL_lane(0, 'none', 0, 0, 'none', white);

        case 'urbanstreet'
            centerMark = fcn_INTERNAL_pick(options.CenterMark, 'solid solid');
            segments = fcn_INTERNAL_segment('line', fcn_INTERNAL_pick(options.Length, 200), 0, 0);
            rightLanes = [fcn_INTERNAL_lane(-1, 'driving', laneWidth, 0, 'none', white); ...
                          fcn_INTERNAL_lane(-2, 'curb', 0.15, 0.15, 'none', white); ...
                          fcn_INTERNAL_lane(-3, 'walking', 2.5, 0.15, 'none', white); ...
                          fcn_INTERNAL_lane(-4, 'border', 1.5, 0.15, 'none', white)];
            centerLane = fcn_INTERNAL_lane(0, 'none', 0, 0, centerMark, 'yellow');

        case 'neighborhood'
            centerMark = fcn_INTERNAL_pick(options.CenterMark, 'none');
            segments = fcn_INTERNAL_segment('line', fcn_INTERNAL_pick(options.Length, 1200), 0, 0);
            rightLanes = [fcn_INTERNAL_lane(-1, 'driving', laneWidth, 0, 'none', white); ...
                          fcn_INTERNAL_lane(-2, 'curb', 0.15, 0.15, 'none', white); ...
                          fcn_INTERNAL_lane(-3, 'border', 1.5, 0.15, 'none', white); ...
                          fcn_INTERNAL_lane(-4, 'walking', 1.5, 0.15, 'none', white); ...
                          fcn_INTERNAL_lane(-5, 'border', 3.0, 0.15, 'none', white)];
            centerLane = fcn_INTERNAL_lane(0, 'none', 0, 0, centerMark, 'yellow');
    end

    %%%% The reference line: each element starts where the last one ended
    planView = fcn_INTERNAL_planView(segments, options.Start);
    road.PlanView = planView;
    road.Length = planView(end).S + planView(end).Length;

    %%%% One lane section: the left lanes mirror the right ones
    leftLanes = rightLanes;
    for ith_lane = 1:numel(leftLanes)
        leftLanes(ith_lane).ID = -rightLanes(ith_lane).ID;
    end
    road.LaneSections = struct('S',0, 'Left',{leftLanes}, 'Center',centerLane, 'Right',{rightLanes});

    %%%% Objects
    switch presetName
        case 'interstate'
            barrier = fcn_INTERNAL_object('barrier', 'concreteBarrier', 0, 0, road.Length, 0.6, 0.81, 1);
            barrier.Repeat = true;
            road.Objects(end+1) = barrier;
        case 'urbanstreet'
            road.Objects = fcn_INTERNAL_urbanObjects(road, laneWidth, options.Seed, options.BuildingSetback, ...
                lower(char(fcn_INTERNAL_pick(options.BuildingSides, 'both'))));
            % Pedestrians, standing on the outer part of the sidewalks
            curbT = laneWidth + 0.15;
            road.Objects = [road.Objects, fcn_INTERNAL_pedestrians(road.Length, [-1 1]*(curbT + 1.9), 0.3, 12, 0.3, options.Seed)];
        case 'neighborhood'
            road.Objects = fcn_INTERNAL_neighborhoodObjects(road, laneWidth, options.Seed, options.BuildingSetback, ...
                lower(char(fcn_INTERNAL_pick(options.BuildingSides, 'left'))), options.BlockLength);
            curbT = laneWidth + 0.15;
            road.Objects = [road.Objects, fcn_INTERNAL_pedestrians(road.Length, [-1 1]*(curbT + 1.5 + 0.75), 0.3, 25, 0.2, options.Seed)];
    end

    % Number the objects in order
    for ith_object = 1:numel(road.Objects)
        road.Objects(ith_object).ID = ith_object;
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

    fcn_AnimateCar3D_plotRoad(road, FigNum=figNum);
    title(sprintf('Road preset ''%s''', road.Name), 'Interpreter','none');
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

%% fcn_INTERNAL_pick
function value = fcn_INTERNAL_pick(given, defaultValue)
% The given value, or the default if it is empty
if isempty(given)
    value = defaultValue;
else
    value = given;
end
end % Ends fcn_INTERNAL_pick

%% fcn_INTERNAL_segment
function segment = fcn_INTERNAL_segment(segmentType, segmentLength, curvStart, curvEnd)
% One geometry element, before its start point is known
segment = struct('Type',segmentType, 'Length',segmentLength, 'CurvStart',curvStart, 'CurvEnd',curvEnd);
end % Ends fcn_INTERNAL_segment

%% fcn_INTERNAL_planView
function planView = fcn_INTERNAL_planView(segments, startPose)
% The geometry elements, each starting where the last one ended
planView = repmat(struct('S',0, 'X',0, 'Y',0, 'Hdg',0, 'Length',0, 'Type','', 'Curvature',[], ...
    'CurvStart',[], 'CurvEnd',[]), numel(segments), 1);
thisStart = [startPose(1) startPose(2) startPose(3)];
sStart = 0;
for ith_segment = 1:numel(segments)
    thisSegment = segments(ith_segment);
    geometry = struct('S',sStart, 'X',thisStart(1), 'Y',thisStart(2), 'Hdg',thisStart(3), 'Length',thisSegment.Length, ...
        'Type',thisSegment.Type, 'Curvature',[], 'CurvStart',[], 'CurvEnd',[]);
    switch thisSegment.Type
        case 'arc'
            geometry.Curvature = thisSegment.CurvStart;
        case 'spiral'
            geometry.CurvStart = thisSegment.CurvStart;
            geometry.CurvEnd = thisSegment.CurvEnd;
    end
    planView(ith_segment) = geometry;
    thisStart = fcn_AnimateCar3D_getRoadPoints(struct('PlanView',geometry), sStart + thisSegment.Length, FigNum=-1);
    sStart = sStart + thisSegment.Length;
end
end % Ends fcn_INTERNAL_planView

%% fcn_INTERNAL_lane
function lane = fcn_INTERNAL_lane(laneID, laneType, laneWidth, laneHeight, markType, markColor)
% One lane, with a constant width and the road mark on its outer edge.
% Broken lines: 3 m lines and 9 m spaces (about the US 10 ft and 30 ft).
roadMark = struct('Type',markType, 'Color',markColor, 'Width',0.15, 'LineLength',3, 'LineSpace',9, 'LaneChange','both');
if strcmp(markType,'solid') || contains(markType,'solid solid')
    roadMark.LaneChange = 'none';
end
lane = struct('ID',laneID, 'Type',laneType, 'Width',[laneWidth 0 0 0], 'Height',[laneHeight laneHeight], 'RoadMark',roadMark);
end % Ends fcn_INTERNAL_lane

%% fcn_INTERNAL_object
function object = fcn_INTERNAL_object(objectType, objectName, sStart, tCenter, objectLength, objectWidth, objectHeight, objectID)
% One road object (OpenDRIVE <object>): S and T place its center (with
% Repeat true, it runs along the road from S for Length)
% One road object (OpenDRIVE <object>): placed at s (its start along the
% road) and t (its center across)
object = struct('ID',objectID, 'Type',objectType, 'Name',objectName, 'S',sStart, 'T',tCenter, 'ZOffset',0, ...
    'Length',objectLength, 'Width',objectWidth, 'Height',objectHeight, 'Hdg',0, 'Repeat',false, 'Color',[]);
end % Ends fcn_INTERNAL_object

%% fcn_INTERNAL_pedestrians
function objects = fcn_INTERNAL_pedestrians(roadLength, sidewalkT, jitter, spacing, probability, seed)
% Pedestrians standing on sidewalks (centered at each sidewalkT): one
% chance every spacing meters, from their own random numbers (so the
% buildings do not change)
randomStream = RandStream('mt19937ar', 'Seed', seed + 1000);
shirtColors = [0.20 0.30 0.55; 0.55 0.15 0.15; 0.20 0.45 0.30; 0.35 0.35 0.38; 0.45 0.30 0.45; 0.15 0.40 0.50];
objects = fcn_INTERNAL_object('pedestrian', 'standing', 0, 0, 0.35, 0.55, 1.75, 0);
objects(1) = [];
for tSidewalk = sidewalkT
    for sChance = spacing/2:spacing:roadLength-spacing/2
        draws = randomStream.rand(1,5);
        if draws(1) > probability
            continue;
        end
        person = fcn_INTERNAL_object('pedestrian', 'standing', sChance + spacing*(draws(2) - 0.5)*0.6, ...
            tSidewalk + jitter*(2*draws(3) - 1), 0.35, 0.55, 1.6 + 0.25*draws(4), 0);
        person.Hdg = 2*pi*draws(5);
        person.Color = shirtColors(1 + floor(size(shirtColors,1)*draws(2)), :);
        objects(end+1) = person; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_pedestrians

%% fcn_INTERNAL_intersection
function network = fcn_INTERNAL_intersection(options, laneWidth)
% Four arms, each starting at the junction's edge and pointing away from
% it (left lanes in, right lanes out), and the junction between them
armLength = fcn_INTERNAL_pick(options.Length, 80);
Nin = 2 + logical(options.RightTurnLane);
Nout = 2;
widthIn = Nin*laneWidth;
widthOut = Nout*laneWidth;
halfSize = max(widthIn, widthOut);         % the junction's half-size
white = 'standard';

% Lanes: out on the right, in on the left (left-turn lane nearest the
% center line), then curb, sidewalk, and a strip of grass
rightLanes = [fcn_INTERNAL_lane(-1, 'driving', laneWidth, 0, 'broken', white); ...
              fcn_INTERNAL_lane(-2, 'driving', laneWidth, 0, 'none', white); ...
              fcn_INTERNAL_lane(-3, 'curb', 0.15, 0.15, 'none', white); ...
              fcn_INTERNAL_lane(-4, 'walking', 2.5, 0.15, 'none', white); ...
              fcn_INTERNAL_lane(-5, 'border', 1.5, 0.15, 'none', white)];
leftLanes = fcn_INTERNAL_lane(1, 'driving', laneWidth, 0, 'solid', white);
for ith_lane = 2:Nin
    markType = 'none';
    if ith_lane < Nin
        markType = 'solid';
    end
    leftLanes(end+1,1) = fcn_INTERNAL_lane(ith_lane, 'driving', laneWidth, 0, markType, white); %#ok<AGROW>
end
leftLanes = [leftLanes; fcn_INTERNAL_lane(Nin+1, 'curb', 0.15, 0.15, 'none', white); ...
             fcn_INTERNAL_lane(Nin+2, 'walking', 2.5, 0.15, 'none', white); ...
             fcn_INTERNAL_lane(Nin+3, 'border', 1.5, 0.15, 'none', white)];
centerLane = fcn_INTERNAL_lane(0, 'none', 0, 0, 'solid solid', 'yellow');
if Nin==2
    arrowNames = {'left','straightRight'};
else
    arrowNames = {'left','straight','right'};
end

center = options.Start(1:2);
for ith_arm = 1:4
    heading = options.Start(3) + (ith_arm-1)*pi/2;
    armStart = center + halfSize*[cos(heading) sin(heading)];
    arm = struct('ID',sprintf('%d', ith_arm), 'Name',sprintf('arm %d', ith_arm), 'TrafficRule','RHT', ...
        'Units','meters, radians', 'Length',armLength, ...
        'PlanView',fcn_INTERNAL_planView(fcn_INTERNAL_segment('line', armLength, 0, 0), [armStart heading]), ...
        'LaneSections',struct('S',0, 'Left',{leftLanes}, 'Center',centerLane, 'Right',{rightLanes}), ...
        'Objects',fcn_INTERNAL_object('crosswalk', 'continental', 2.5, (widthIn - widthOut)/2, 3.0, widthIn + widthOut, 0, 0), ...
        'Junction','1');
    arm.Objects(end+1) = fcn_INTERNAL_object('stopLine', 'stopLine', 5.4, widthIn/2, 0.4, widthIn, 0, 0);
    for ith_lane = 1:Nin
        arrow = fcn_INTERNAL_object('arrow', arrowNames{ith_lane}, 15, (ith_lane - 0.5)*laneWidth, 5, 0.7, 0, 0);
        arrow.Hdg = pi;                                       % (traffic comes in, toward s = 0)
        arm.Objects(end+1) = arrow;
    end
    arm.Objects = [arm.Objects, fcn_INTERNAL_pedestrians(armLength, [-(widthOut + 0.15 + 1.25), widthIn + 0.15 + 1.25], 0.6, ...
        15, 0.3, options.Seed + ith_arm)];
    for ith_object = 1:numel(arm.Objects)
        arm.Objects(ith_object).ID = ith_object;
    end
    roads(ith_arm) = arm; %#ok<AGROW>
end

% The junction: an asphalt square, and at each corner the sidewalk (and
% curb) of an arm's left side carried back to the next arm's curb, when
% the arms are wider coming in than going out
toWorld = @(heading, uv) center + uv(:,1)*[cos(heading) sin(heading)] + uv(:,2)*[-sin(heading) cos(heading)];
squareCorners = [-1 -1; 1 -1; 1 1; -1 1]*halfSize;
junction = struct('ID','1', 'Type','default', 'Center',center, ...
    'Surfaces',struct('Corners',toWorld(options.Start(3), squareCorners), 'Height',0, 'Type','driving'), ...
    'CurbFaces',struct('Ends',{}, 'Height',{}));
uFrom = widthOut + 0.15;
if halfSize - uFrom > 1e-9
    for ith_arm = 1:4
        heading = options.Start(3) + (ith_arm-1)*pi/2;
        curbStrip = [uFrom widthIn; halfSize widthIn; halfSize widthIn+0.15; uFrom widthIn+0.15];
        walkStrip = [uFrom widthIn+0.15; halfSize widthIn+0.15; halfSize widthIn+2.65; uFrom widthIn+2.65];
        junction.Surfaces(end+1) = struct('Corners',toWorld(heading, curbStrip), 'Height',0.15, 'Type','curb');
        junction.Surfaces(end+1) = struct('Corners',toWorld(heading, walkStrip), 'Height',0.15, 'Type','walking');
        junction.CurbFaces(end+1) = struct('Ends',toWorld(heading, [uFrom widthIn; halfSize widthIn]), 'Height',0.15);
    end
end
network = struct('ID','intersection', 'Name','intersection', 'TrafficRule','RHT', 'Units','meters, radians', ...
    'Roads',roads, 'Junctions',junction);
end % Ends fcn_INTERNAL_intersection

%% fcn_INTERNAL_nearSideHeight
function buildingHeight = fcn_INTERNAL_nearSideHeight(heightDraw, storyDraw)
% Buildings on the near side (the side of traffic in the right-hand
% lanes, where cameras follow it): mostly one story (3.5 to 4.5 m),
% sometimes two (6.5 to 7.5 m, about 1 in 7)
if storyDraw < 0.15
    buildingHeight = 6.5 + heightDraw;
else
    buildingHeight = 3.5 + heightDraw;
end
end % Ends fcn_INTERNAL_nearSideHeight

%% fcn_INTERNAL_neighborhoodObjects
function objects = fcn_INTERNAL_neighborhoodObjects(road, laneWidth, seed, setback, buildingSides, blockLength)
% Crosswalks at the block ends; street trees in the grass strip; houses
% on lots about 20 m wide, with an occasional park (a lawn with block
% trees) in place of a few lots
randomStream = RandStream('mt19937ar', 'Seed', seed);
curbT = laneWidth + 0.15;                  % the grass strip's inner edge
lotFrontT = curbT + 1.5 + 1.5;             % the back of the sidewalk
crosswalkS = blockLength:blockLength:road.Length-1;
objects = fcn_INTERNAL_object('crosswalk', 'continental', 0, 0, 3.0, 2*laneWidth, 0, 0);
objects(1) = [];
objectID = 0;
for sCross = crosswalkS
    objectID = objectID + 1;
    objects(end+1) = fcn_INTERNAL_object('crosswalk', 'continental', sCross, 0, 3.0, 2*laneWidth, 0, objectID); %#ok<AGROW>
end
houseShades = [0.66 0.60 0.52; 0.58 0.62 0.66; 0.62 0.48 0.42; 0.55 0.58 0.50; 0.70 0.66 0.60; 0.50 0.52 0.58];
for side = [-1 1]
    % Street trees, every 20 m in the grass strip, not at crosswalks
    for sTree = 10:20:road.Length-5
        if any(abs(sTree - crosswalkS) < 8)
            continue;
        end
        objectID = objectID + 1;
        objects(end+1) = fcn_INTERNAL_object('tree', 'blockTree', sTree, side*(curbT + 0.75), 2.4, 2.4, 5.0, objectID); %#ok<AGROW>
    end
    % Lots. (The random numbers are drawn for both sides always, so one
    % side's houses do not change with BuildingSides.)
    flagBuildHere = strcmp(buildingSides,'both') || (side > 0 && strcmp(buildingSides,'left')) || ...
        (side < 0 && strcmp(buildingSides,'right'));
    sLot = 0;
    while true
        flagPark = randomStream.rand < 0.12;
        if flagPark
            lotLength = 40 + 20*randomStream.rand;
        else
            lotLength = 18 + 6*randomStream.rand;
        end
        if sLot + lotLength > road.Length
            break;
        end
        if flagPark
            % A park: block trees on the lawn
            Ntrees = 3 + floor(3*randomStream.rand);
            treeS = sLot + 5 + (lotLength - 10)*randomStream.rand(Ntrees,1);
            treeT = lotFrontT + setback + 3 + 20*randomStream.rand(Ntrees,1);
            for ith_tree = 1:Ntrees
                objectID = objectID + 1;
                parkTree = fcn_INTERNAL_object('tree', 'blockTree', treeS(ith_tree), side*treeT(ith_tree), 3.0, 3.0, ...
                    5 + 2*randomStream.rand, objectID);
                if flagBuildHere
                    objects(end+1) = parkTree; %#ok<AGROW>
                end
            end
        else
            % A house: about 10 m by 10 m, 5 to 8 m tall, in the middle of
            % its lot, behind its front yard
            houseLength = 9 + 5*randomStream.rand;
            houseDepth = 8 + 4*randomStream.rand;
            objectID = objectID + 1;
            heightDraw = randomStream.rand;
            storyDraw = randomStream.rand;
            if side < 0
                houseHeight = fcn_INTERNAL_nearSideHeight(heightDraw, storyDraw);
            else
                houseHeight = 5 + 3*heightDraw;
            end
            house = fcn_INTERNAL_object('building', 'house', sLot + lotLength/2, side*(lotFrontT + setback + houseDepth/2), ...
                houseLength, houseDepth, houseHeight, objectID);
            house.Color = houseShades(1 + floor(size(houseShades,1)*randomStream.rand), :);
            if flagBuildHere
                objects(end+1) = house; %#ok<AGROW>
            end
        end
        sLot = sLot + lotLength;
    end
end
end % Ends fcn_INTERNAL_neighborhoodObjects

%% fcn_INTERNAL_urbanObjects
function objects = fcn_INTERNAL_urbanObjects(road, laneWidth, seed, setback, buildingSides)
% A crosswalk, block trees along the sidewalks, and buildings made at
% random (repeatably) behind them
randomStream = RandStream('mt19937ar', 'Seed', seed);
curbT = laneWidth + 0.15;                  % the sidewalk's inner edge
objects = fcn_INTERNAL_object('crosswalk', 'continental', 60, 0, 3.0, 2*laneWidth, 0, 1);
objectID = 1;
for side = [-1 1]
    % Trees, every 15 m, in the sidewalk 0.8 m from the curb
    for sTree = 8:15:road.Length-5
        if abs(sTree - 60) < 6
            continue;                      % (not at the crosswalk)
        end
        objectID = objectID + 1;
        objects(end+1) = fcn_INTERNAL_object('tree', 'blockTree', sTree, side*(curbT + 0.8), 2.4, 2.4, 4.4, objectID); %#ok<AGROW>
    end
    % Buildings: random widths, depths, heights, and gaps, set back
    % behind the sidewalk. (The random numbers are drawn for both sides
    % always, so one side's buildings do not change with BuildingSides.)
    flagBuildHere = strcmp(buildingSides,'both') || (side > 0 && strcmp(buildingSides,'left')) || ...
        (side < 0 && strcmp(buildingSides,'right'));
    sBuilding = 2*randomStream.rand;
    while true
        buildingLength = 10 + 15*randomStream.rand;
        if sBuilding + buildingLength > road.Length
            break;
        end
        buildingDepth = 12 + 8*randomStream.rand;
        objectID = objectID + 1;
        heightDraw = randomStream.rand;
        storyDraw = randomStream.rand;
        if side < 0
            buildingHeight = fcn_INTERNAL_nearSideHeight(heightDraw, storyDraw);
        else
            buildingHeight = 6 + 24*heightDraw^2;
        end
        building = fcn_INTERNAL_object('building', 'block', sBuilding + buildingLength/2, side*(curbT + 2.5 + setback + buildingDepth/2), ...
            buildingLength, buildingDepth, buildingHeight, objectID);
        shade = 0.55 + 0.3*randomStream.rand;
        building.Color = shade*[1 0.95 0.88] .* (0.9 + 0.1*randomStream.rand(1,3));
        if flagBuildHere
            objects(end+1) = building; %#ok<AGROW>
        end
        sBuilding = sBuilding + buildingLength + 2 + 4*randomStream.rand;
    end
end
end % Ends fcn_INTERNAL_urbanObjects
