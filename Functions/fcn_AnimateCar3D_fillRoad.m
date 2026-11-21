function [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(options)
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
%   'mountain': a mountain road, about 2 km (Length), random but
%       repeatable (Seed): straight runs between bends of 30 to 120 m
%       radius, now and then a hairpin (18 to 25 m radius, 150 to 180
%       degrees), with spirals into and out of every bend, never passing
%       within 30 m of itself; one lane each way, a double yellow center
%       line, 1 m shoulders. By default it climbs and descends
%       (Elevation='mountain') with banked curves (CrossSlope='banked').
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
%   'urbanGrid': the urban street with cross streets: a main street
%       crossed by CrossStreets (default 3) cross streets, BlockLength
%       apart (center to center, default 100 m), each crossing a junction
%       like the intersection's (2 lanes each way; coming in, a left-turn
%       lane and a through-and-right lane, solid-marked over the last
%       30 m); the main street's roads run from junction to junction,
%       with the approach road (Length, 60 m) ending at the first and the
%       exit road starting at the last; each cross street is two arms
%       (Length each) pointing away from its junction. City blocks: block
%       trees and buildings made at random (from Seed), set back
%       BuildingSetback behind the sidewalks: tall north of the main
%       street (on its left), low and see-through to its south. A road
%       NETWORK (see OUTPUTS); the ego starts on the approach road's
%       through lane, heading for the first junction.
%   'intersection': four arms (Length each, 80 m) meeting at a junction
%       (OpenDRIVE <junction>): on each arm, 2 lanes out and 2 lanes in
%       (a left-turn lane, and a through and right-turn lane), or with
%       RightTurnLane true, 3 lanes in (left, through, and right); a
%       double yellow center line; curbs and sidewalks, joined at the
%       corners; crosswalks, stop lines, and lane arrows. This preset
%       returns a road NETWORK (see OUTPUTS).
%
% HEIGHTS (OpenDRIVE <elevationProfile> and <lateralProfile>), for any
% preset but the intersection (which stays flat):
%
%   ElevationProfile: the road's height along s, piecewise cubics (S, A,
%       B, C, D: height = A + B*ds + C*ds^2 + D*ds^3, ds from S). With
%       Elevation='hilly', random hills (from Seed) made from the grade,
%       as road designers do: the grade is set at knots spaced randomly
%       along the road (normally distributed, about 50 m apart, from 20
%       to 100 m), starts at 0, changes by at most MaxGradeChange per 100
%       m of road, never passes MaxGrade, and is level wherever asked; it
%       is linear between knots, and the height follows from it
%       (piecewise quadratic), starting at 0. MaxHeightRange caps the
%       height from lowest to highest (by scaling the grades down).
%       Elevation='mountain' is the same, but the road climbs all the way
%       to a summit at mid-road (each knot's grade a random 40 to 100% of
%       the limit), then descends all the way, as over a mountain.
%       As road designers do on mountain roads, the grade eases on sharp
%       curves, so that most of the climbing is on the straighter parts:
%       on a curve of radius R tighter than CurveGradeRadius, the limit
%       is MaxGrade*R/CurveGradeRadius (never below 20% of MaxGrade), with
%       knots at each curve's ends so the whole curve keeps to it.
%   LateralProfile.Superelevation: the road's roll angle (radians,
%       positive: the left side higher), in the same cubic form. With
%       CrossSlope='banked', the road tilts down toward the inside of each
%       curve, in proportion to the curvature, up to MaxCrossSlope (a
%       rise over run) at the tightest curve; it changes smoothly along
%       the spirals.
%   Flat roads have one record of zeros for each.
%
% The urban street, neighborhood, and intersection have occasional
% pedestrians standing on the sidewalks (road objects of type
% 'pedestrian', for scenery; moving pedestrians belong in the scenario).
%
% FORMAT:
%
%       [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad((Preset=preset), (Length=meters),...
%           (LaneWidth=meters), (LanesEachWay=n), (CenterMark=type),...
%           (Start=[x y heading]), (Seed=seed), (BuildingSetback=meters),...
%           (BuildingSides=sides), (BlockLength=meters), (CrossStreets=n),...
%           (RightTurnLane=flag), (Elevation=elevation),...
%           (MaxGrade=grade), (MaxGradeChange=gradePer100m), (ConfirmSteep=flag),...
%           (CurveGradeRadius=meters), (MaxHeightRange=meters), (CrossSlope=crossSlope),...
%           (MaxCrossSlope=slope), (FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Preset: 'twoLane' (default), 'curvy', 'mountain', 'interstate',
%      'urbanStreet', 'urbanGrid', 'neighborhood', 'intersection', or
%      'raceCourse'.
%      'raceCourse' is a closed course (about 452 m) traced from a photo
%      of a race track, scaled so its straights are two 12 ft lanes; it
%      reads Data/raceCourse_trace.csv, _planView.csv, and _features.csv
%      (no toolbox needed), keeps the photo's layout, and ignores the
%      other options. Its lanes on each side: a driving lane of smooth
%      width, an unmarked asphalt pseudo-lane out to the real edge (with
%      the white edge line), and a red/white curb banked at 8 degrees
%      where the photo has one; a pit lane beside the bottom straight
%      (one 12 ft lane: wider than the photo's, about 2 m, so normal
%      cars fit); walls 1.35 m high; pit stripes; a start line. The
%      road has Loop = true (s wraps at Length). Its variants:
%      Elevation='hilly' (about 4 m from lowest to highest, set by
%      MaxHeightRange, a warning above 10 m; grades up to MaxGrade, the
%      straights level; no easing on curves unless CurveGradeRadius is
%      given) and CrossSlope='banked' (down to the inside of each curve,
%      MaxCrossSlope; the bottom-rightmost curve banked the other way);
%      the two together for hilly and banked.
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
%      BlockLength: meters between crosswalks ('neighborhood', default
%      400), or between cross streets ('urbanGrid', center to center,
%      default 100, at least 40).
%
%      CrossStreets: the number of cross streets ('urbanGrid'). Default 3.
%
%      RightTurnLane: true for a separate right-turn lane on each arm
%      ('intersection'). Default false.
%
%      Elevation: 'flat', 'hilly', or 'mountain' (see HEIGHTS). Default:
%      'mountain' for the 'mountain' preset, 'flat' for the others.
%      MaxGrade: the steepest grade, rise over run. Default: 0.12 for the
%      'mountain' preset, 0.06 for the others.
%      MaxGradeChange: the fastest change of grade, as a fraction, per
%      100 m of road (0.35 means the grade may change by 35 percentage
%      points over 100 m, about 20 degrees, close to AASHTO design for
%      25 mph roads). Default 0.35.
%      Above 0.5 (15% per 100 ft, about the steepest in US federal
%      guidance), a warning is given; with ConfirmSteep true, a dialog
%      also asks whether to go on.
%      ConfirmSteep: true to ask, in a dialog, before using a
%      MaxGradeChange above 0.5. Default false.
%      CurveGradeRadius: meters; curves tighter than this get a lower
%      grade limit (see HEIGHTS): a hairpin of 20 m radius on a 12% road
%      is at most 2.4%. Default 150; 0 for no easing.
%      MaxHeightRange: meters from the lowest to the highest point; Inf
%      (default) for no cap.
%
%      CrossSlope: 'none' or 'banked' (see HEIGHTS). Default: 'banked'
%      for the 'mountain' preset, 'none' for the others.
%      MaxCrossSlope: the steepest cross-slope, rise over run. Default
%      0.06.
%
%      FigNum: a figure to draw the road in (fcn_AnimateCar3D_plotRoad).
%      Empty (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      road: the road (see above), with EgoStart: the scene's fixed
%      starting point for a vehicle (Road, LaneID, S, Direction: +1 along
%      s, -1 against it): the first driving lane on the right, at s = 0;
%      at the intersection, the west arm's through lane, at its far end,
%      heading in; on the urban grid, the approach road's through lane (-2)
%      at s = 0, heading for the first junction. For 'intersection' and
%      'urbanGrid', a road network: a
%      structure with ID, Name, TrafficRule, Units, Roads (the four arms,
%      each a road as above, starting at the junction and pointing away
%      from it: on each arm, the left lanes come in and the right lanes
%      go out; on the urban grid, the main street's roads run along it,
%      from junction to junction, so the right lanes come in at s =
%      Length; each road there also has Predecessor and Successor, the
%      junction at s = 0 and at s = Length, ElementType 'junction' and
%      ElementID, or empty), and Junctions: ID, Type, Center, Surfaces (flat
%      quadrilaterals: Corners 4 x 2, Height, Type) and CurbFaces (Ends
%      2 x 2, Height), for the area where the arms meet, and Connections
%      (OpenDRIVE <connection>: IncomingRoad, IncomingLane, OutgoingRoad,
%      OutgoingLane, Turn ('left', 'straight', 'right'), and Path: a road
%      whose reference line is the lane's center through the junction,
%      a line, or a line and an arc).
%
%      centerlineOptions: the paths a vehicle can take from EgoStart, from
%      fcn_AnimateCar3D_fillCenterlineOptions (computed only if asked
%      for).
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_getRoadPoints,
%      fcn_AnimateCar3D_fillCenterlineOptions (second output); for the
%      plot, fcn_AnimateCar3D_plotRoad
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
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillRoad
%   % * Added the 'urbanGrid' preset: the urban street with cross streets (CrossStreets, BlockLength), a junction at each

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillRoad
%   % * Reading and writing OpenDRIVE (.xodr) files (planned for the scene-building repository); a full grid (parallel main streets)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    options.Preset = 'twoLane'      % 'twoLane', 'curvy', 'mountain', 'interstate', 'urbanStreet', 'urbanGrid', 'neighborhood', 'intersection', 'raceCourse'
    options.Length = []             % meters (straight presets)
    options.LaneWidth = 3.6         % meters
    options.LanesEachWay = 4        % driving lanes each way ('interstate')
    options.CenterMark = ''         % center line mark type; '' for the preset's
    options.Start = [0 0 0]         % [x y heading] of the reference line start
    options.Seed = 1                % random seed: the same Seed, the same scene
    options.BuildingSetback = 6     % meters behind the sidewalk ('urbanStreet')
    options.BuildingSides = ''      % 'both', 'left', 'right', 'none'; '' for the preset's
    options.BlockLength = []        % meters between crosswalks ('neighborhood', 400) or cross streets ('urbanGrid', 100)
    options.CrossStreets = 3        % cross streets ('urbanGrid')
    options.RightTurnLane = false   % separate right-turn lanes ('intersection')
    options.Elevation = ''          % 'flat', 'hilly', or 'mountain'; '' for the preset's
    options.MaxGrade = []           % rise over run ('hilly'); [] for the preset's (0.12 'mountain', else 0.06)
    options.MaxGradeChange = 0.35   % grade change per 100 m, as a fraction ('hilly'): about 20 degrees
    options.ConfirmSteep = false    % ask before a MaxGradeChange above 0.5
    options.CurveGradeRadius = []   % meters: the grade eases on curves tighter than this; 0 for none; [] for 150 (race course: 0)
    options.MaxHeightRange = Inf    % meters, lowest to highest ('hilly'); Inf for no cap
    options.CrossSlope = ''         % 'none' or 'banked'; '' for the preset's
    options.MaxCrossSlope = 0.06    % rise over run ('banked')
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
        presetNames = {'twoLane','curvy','mountain','interstate','urbanStreet','urbanGrid','neighborhood','intersection','raceCourse'};
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
        if ~isempty(options.Elevation) && ~any(strcmpi(options.Elevation, {'flat','hilly','mountain'}))
            error('Elevation must be ''flat'', ''hilly'', or ''mountain''');
        end
        if ~isempty(options.CrossSlope) && ~any(strcmpi(options.CrossSlope, {'none','banked'}))
            error('CrossSlope must be ''none'' or ''banked''');
        end
        heightNames = {'MaxGradeChange','MaxHeightRange','MaxCrossSlope'};
        if ~isempty(options.CurveGradeRadius) && ~(isnumeric(options.CurveGradeRadius) && isscalar(options.CurveGradeRadius) && options.CurveGradeRadius >= 0)
            error('CurveGradeRadius must be a number, 0 or more, or []');
        end
        if ~isempty(options.MaxGrade) && ~(isnumeric(options.MaxGrade) && isscalar(options.MaxGrade) && options.MaxGrade >= 0)
            error('MaxGrade must be a number, 0 or more');
        end
        for ith_name = 1:numel(heightNames)
            thisValue = options.(heightNames{ith_name});
            if ~(isnumeric(thisValue) && isscalar(thisValue) && thisValue >= 0)
                error('%s must be a number, 0 or more', heightNames{ith_name});
            end
        end
        if options.MaxGradeChange > 0.5
            warning('AnimateCar3D:fillRoad:steepGradeChange', ['MaxGradeChange %.2f is above 0.5 per 100 m ' ...
                '(15%% per 100 ft, about the steepest in US federal guidance).'], options.MaxGradeChange);
            if options.ConfirmSteep && usejava('desktop')
                answer = questdlg(sprintf('MaxGradeChange %.2f per 100 m is steeper than federal guidance (0.5). Go on?', ...
                    options.MaxGradeChange), 'Steep grade change', 'Go on', 'Stop', 'Stop');
                if ~strcmp(answer, 'Go on')
                    error('Stopped: MaxGradeChange above 0.5 per 100 m');
                end
            end
        end
        if ~(isnumeric(options.Seed) && isscalar(options.Seed) && options.Seed >= 0 && options.Seed==round(options.Seed))
            error('Seed must be a whole number, 0 or more');
        end
        if ~isempty(options.BlockLength) && ~(isnumeric(options.BlockLength) && isscalar(options.BlockLength) && options.BlockLength > 0)
            error('BlockLength must be a positive number of meters');
        end
        if strcmpi(options.Preset, 'urbanGrid') && ~isempty(options.BlockLength) && options.BlockLength < 40
            error('BlockLength must be at least 40 m on the urban grid');
        end
        if ~(isnumeric(options.CrossStreets) && isscalar(options.CrossStreets) && options.CrossStreets >= 1 && options.CrossStreets==round(options.CrossStreets))
            error('CrossStreets must be a whole number, 1 or more');
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
elseif strcmp(presetName, 'urbangrid')
    % A road network: a main street and cross streets, a junction at each
    road = fcn_INTERNAL_urbanGrid(options, laneWidth);
elseif strcmp(presetName, 'racecourse')
    % A closed race course, traced from a photo (Data/raceCourse_*.csv)
    road = fcn_INTERNAL_raceCourse(options);
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

        case 'mountain'
            centerMark = fcn_INTERNAL_pick(options.CenterMark, 'solid solid');
            segments = fcn_INTERNAL_mountainSegments(fcn_INTERNAL_pick(options.Length, 2000), options.Seed, options.Start);
            rightLanes = [fcn_INTERNAL_lane(-1, 'driving', laneWidth, 0, 'solid', white); ...
                          fcn_INTERNAL_lane(-2, 'shoulder', 1.0, 0, 'none', white); ...
                          fcn_INTERNAL_lane(-3, 'border', 3.0, 0, 'none', white)];
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

    %%%% Heights: elevation along s, and superelevation (cross-slope)
    road.ElevationProfile = fcn_INTERNAL_flatCubics(0);
    road.LateralProfile = struct('Superelevation', fcn_INTERNAL_flatCubics(0));
    elevationChoice = fcn_INTERNAL_pick(options.Elevation, 'flat');
    crossSlopeChoice = fcn_INTERNAL_pick(options.CrossSlope, 'none');
    maxGrade = fcn_INTERNAL_pick(options.MaxGrade, 0.06);
    if strcmp(presetName, 'mountain')
        elevationChoice = fcn_INTERNAL_pick(options.Elevation, 'mountain');
        crossSlopeChoice = fcn_INTERNAL_pick(options.CrossSlope, 'banked');
        maxGrade = fcn_INTERNAL_pick(options.MaxGrade, 0.12);
        road.TerrainShape = 'mountain';                 % (fcn_AnimateCar3D_fillTerrain: a mountain around it)
    end
    if strcmpi(elevationChoice, 'mountain')
        road.ElevationProfile = fcn_INTERNAL_hillyProfile(road.Length, options.Seed, maxGrade, options.MaxGradeChange, ...
            options.MaxHeightRange, zeros(0,2), 'mountain', planView, fcn_INTERNAL_pick(options.CurveGradeRadius, 150));
    end
    if strcmpi(elevationChoice, 'hilly')
        road.ElevationProfile = fcn_INTERNAL_hillyProfile(road.Length, options.Seed, maxGrade, options.MaxGradeChange, ...
            options.MaxHeightRange, zeros(0,2), 'hilly', planView, fcn_INTERNAL_pick(options.CurveGradeRadius, 150));
    end
    if strcmpi(crossSlopeChoice, 'banked')
        road.LateralProfile.Superelevation = fcn_INTERNAL_bankedProfile(planView, options.MaxCrossSlope);
    end

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
                lower(char(fcn_INTERNAL_pick(options.BuildingSides, 'left'))), fcn_INTERNAL_pick(options.BlockLength, 400));
            curbT = laneWidth + 0.15;
            road.Objects = [road.Objects, fcn_INTERNAL_pedestrians(road.Length, [-1 1]*(curbT + 1.5 + 0.75), 0.3, 25, 0.2, options.Seed)];
    end

    % Number the objects in order
    for ith_object = 1:numel(road.Objects)
        road.Objects(ith_object).ID = ith_object;
    end

    % The fixed starting point: the first driving lane on the right, at s = 0
    drivingIDs = [rightLanes(strcmp({rightLanes.Type},'driving')).ID];
    road.EgoStart = struct('Road',road.ID, 'LaneID',max(drivingIDs), 'S',0, 'Direction',1);
end

%%%% The paths from the starting point, if asked for
if nargout > 1
    centerlineOptions = fcn_AnimateCar3D_fillCenterlineOptions(road, FigNum=-1);
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

%% fcn_INTERNAL_raceCourse
function road = fcn_INTERNAL_raceCourse(options)
% The race course traced from a photo (see Data/README_raceCourse.md):
% Data/raceCourse_trace.csv has the centerline every 0.25 m from the
% start line (s, x, y), the track's half-widths to each edge, and the
% curb widths; Data/raceCourse_planView.csv has the reference line as
% lines and arcs; Data/raceCourse_features.csv has the walls and the pit
% stripes as world polylines. The course keeps the photo's layout (north
% up); the start is at the origin, heading west on the bottom straight.
dataFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Data');
trace = readmatrix(fullfile(dataFolder, 'raceCourse_trace.csv'), 'NumHeaderLines', 1);
features = readcell(fullfile(dataFolder, 'raceCourse_features.csv'), 'NumHeaderLines', 1);
laneWidth = 12*0.3048;                                   % (the straights: two 12 ft lanes)

%%%% The reference line: lines and arcs every 2 m (Data/raceCourse_planView.csv:
%%%% curvature from the trace's headings, corrected a little on each
%%%% winding half so the straights are exactly straight and the loop
%%%% closes; within 0.3 m of the trace)
planRows = readmatrix(fullfile(dataFolder, 'raceCourse_planView.csv'), 'NumHeaderLines', 1);   % s x y heading length curvature
Ngeometry = size(planRows,1);
planView = repmat(struct('S',0, 'X',0, 'Y',0, 'Hdg',0, 'Length',0, 'Type','line', 'Curvature',[], ...
    'CurvStart',[], 'CurvEnd',[]), Ngeometry, 1);
for ith_geometry = 1:Ngeometry
    thisRow = planRows(ith_geometry,:);
    planView(ith_geometry) = struct('S',thisRow(1), 'X',thisRow(2), 'Y',thisRow(3), 'Hdg',thisRow(4), 'Length',thisRow(5), ...
        'Type','line', 'Curvature',[], 'CurvStart',[], 'CurvEnd',[]);
    if abs(thisRow(6)) > 1e-9
        planView(ith_geometry).Type = 'arc';
        planView(ith_geometry).Curvature = thisRow(6);
    end
end
sNow = planRows(end,1) + planRows(end,5);
road = struct('ID','1', 'Name','raceCourse', 'TrafficRule','RHT', 'Units','meters, radians', ...
    'Length',sNow, 'PlanView',planView, 'LaneSections',[], 'Objects',fcn_INTERNAL_object('', '', 0, 0, 0, 0, 0, 0));
road.Objects(1) = [];
road.ElevationProfile = fcn_INTERNAL_flatCubics(0);
road.LateralProfile = struct('Superelevation', fcn_INTERNAL_flatCubics(0));

%%%% Each trace row's s on the reference line (the trace's s, scaled to
%%%% the reference line's length)
traceLength = trace(end,1) + norm(trace(end,2:3) - trace(1,2:3));
rowS = trace(:,1)*sNow/traceLength;

%%%% Widths along s: the driving lanes smooth (a 15 m moving average,
%%%% never past the edge), an unmarked asphalt pseudo-lane out to the real
%%%% edge, the curbs, and the pit lane (one 12 ft lane beside the bottom
%%%% straight, between the pit stripes, tapering in over 6 m at each end)
edgeLeft = trace(:,4); edgeRight = trace(:,5);
% (the straights: where the trace is exactly level for 10 m or more; two
% 12 ft lanes each)
flagLevelRow = [abs(diff(trace(:,3))) < 1e-9; abs(trace(1,3) - trace(end,3)) < 1e-9];
runStarts = find(diff([0; flagLevelRow])==1); runEnds = find(diff([flagLevelRow; 0])==-1);
flagStraight = false(size(flagLevelRow));
for ith_run = 1:numel(runStarts)
    if runEnds(ith_run) - runStarts(ith_run) >= 40
        flagStraight(runStarts(ith_run):runEnds(ith_run)) = true;
    end
end
flagStraight(1) = flagStraight(end) || flagStraight(1);
edgeLeft(flagStraight) = laneWidth; edgeRight(flagStraight) = laneWidth;
driveLeft = min(edgeLeft, fcn_INTERNAL_loopMean(edgeLeft, 61));
driveRight = min(edgeRight, fcn_INTERNAL_loopMean(edgeRight, 61));
widths = struct('driveLeft',driveLeft, 'driveRight',driveRight, 'pseudoLeft',edgeLeft - driveLeft, ...
    'pseudoRight',edgeRight - driveRight, 'curbLeft',trace(:,6), 'curbRight',trace(:,7));
stripes = features(strcmp(features(:,2), 'stripe'), :);
stripeX = cell2mat(stripes(:,3));
pitX = [min(stripeX) max(stripeX)];                       % (the bottom straight runs west from the start, along -x)
pitS = sort(mod(-pitX, sNow));                            % [exit, entry]: the pit wraps past the start line
rowsPit = rowS <= pitS(1) | rowS >= pitS(2);
toEnds = min(mod(pitS(1) - rowS, sNow), mod(rowS - pitS(2), sNow));
widths.pit = rowsPit.*laneWidth.*min(1, toEnds/6);
names = fieldnames(widths);
for ith_name = 1:numel(names)
    widths.(names{ith_name}) = fcn_INTERNAL_loopMean(widths.(names{ith_name}), 9);   % (2 m: smooth joins, and slopes)
end
flagTopStraight = flagStraight & trace(:,3) > 10;

%%%% Lane sections every 5 m: each lane's width a cubic through the
%%%% widths and slopes at the section's ends (so the widths join smoothly)
sectionStarts = (0:5:sNow - 2.5)';
sectionEnds = [sectionStarts(2:end); sNow];
curbBank = tan(8*pi/180);
white = 'standard';
for ith_section = 1:numel(sectionStarts)
    s0 = sectionStarts(ith_section); s1 = sectionEnds(ith_section);
    cubic = @(name) fcn_INTERNAL_hermite(rowS, widths.(name), s0, s1, sNow);
    sides = struct();
    for side = [-1 1]
        if side < 0
            suffix = 'Right';
        else
            suffix = 'Left';
        end
        curbCubic = cubic(['curb' suffix]);
        curbMean = max(0, mean(polyval(fliplr(curbCubic), linspace(0, s1 - s0, 6))));
        lanes = [fcn_INTERNAL_lane(side*1, 'driving', 0, 0, 'none', white); ...
                 fcn_INTERNAL_lane(side*2, 'shoulder', 0, 0, 'solid', white); ...
                 fcn_INTERNAL_lane(side*3, 'curb', 0, 0, 'none', white)];
        lanes(1).Width = cubic(['drive' suffix]);
        lanes(2).Width = cubic(['pseudo' suffix]);
        lanes(3).Width = curbCubic;
        lanes(3).Height = [0 curbMean*curbBank];              % (banked up and away from the track, 8 degrees)
        if side > 0 && any(rowsPit(rowS >= s0 & rowS < s1))
            lanes(4,1) = fcn_INTERNAL_lane(4, 'driving', 0, 0, 'solid', white);
            lanes(4).Width = cubic('pit');
        end
        sides.(suffix) = lanes;
    end
    centerMark = 'none';
    if any(flagTopStraight(rowS >= s0 & rowS < s1))
        centerMark = 'broken';
    end
    centerLane = fcn_INTERNAL_lane(0, 'none', 0, 0, centerMark, white);
    road.LaneSections(ith_section,1).S = s0;
    road.LaneSections(ith_section,1).Left = sides.Left;
    road.LaneSections(ith_section,1).Center = centerLane;
    road.LaneSections(ith_section,1).Right = sides.Right;
end

%%%% Objects: the walls (1.35 m, as in the photo's red/white dashed lines),
%%%% the pit stripes, and the start line, each with an outline in the
%%%% road's local frame at its S and T (OpenDRIVE <outline> cornerLocal)
wallIDs = unique(cell2mat(features(strcmp(features(:,2), 'wall'), 1)));
for ith_wall = wallIDs'
    rows = strcmp(features(:,2), 'wall') & cell2mat(features(:,1))==ith_wall;
    road.Objects(end+1) = fcn_INTERNAL_outlined(road, 'wall', sprintf('wall %d', ith_wall), ...
        cell2mat(features(rows, 3:4)), 0.25, 1.35);
end
for ith_stripe = unique(cell2mat(stripes(:,1)))'
    rows = cell2mat(stripes(:,1))==ith_stripe;
    road.Objects(end+1) = fcn_INTERNAL_outlined(road, 'stripe', sprintf('pit stripe %d', ith_stripe), ...
        cell2mat(stripes(rows, 3:4)), 0.30, 0);
end
startLine = fcn_INTERNAL_object('stripe', 'start line', 0, 0, 0.3, 2*laneWidth, 0, 0);
startLine.Outline = [-0.15 -laneWidth; 0.15 -laneWidth; 0.15 laneWidth; -0.15 laneWidth];
road.Objects(end+1) = startLine;
for ith_object = 1:numel(road.Objects)
    road.Objects(ith_object).ID = ith_object;
end

%%%% Heights (the race course variants): 'hilly' (about 4 m, never more
%%%% than 10 m from lowest to highest by default; grades up to MaxGrade,
%%%% the straights level; the loop's heights close), and 'banked' (down
%%%% to the inside of each curve, MaxCrossSlope; the bottom-rightmost
%%%% curve the other way)
if strcmpi(fcn_INTERNAL_pick(options.Elevation, 'flat'), 'hilly')
    road.ElevationProfile = fcn_INTERNAL_raceHills(road, rowS(flagStraight), options);
end
if strcmpi(fcn_INTERNAL_pick(options.CrossSlope, 'none'), 'banked')
    road.LateralProfile.Superelevation = fcn_INTERNAL_raceBanking(road, options.MaxCrossSlope);
end

road.Loop = true;                                         % (a closed course: s wraps at Length)
road.SampleSpacing = 0.5;
road.TreesPerHectare = 0;                                 % (no trees around a race course)
road.TerrainGridSpacing = 1;                              % (fcn_AnimateCar3D_fillTerrain: fine ground between close track parts)
road.TerrainMargin = 30;                                 % (tight curves: fcn_AnimateCar3D_plotRoad samples every 0.5 m)
road.Colors = struct('shoulder', [0.33 0.33 0.34]);       % (the pseudo-lanes: plain asphalt)
road.EgoStart = struct('Road',road.ID, 'LaneID',-1, 'S',0, 'Direction',1);
end % Ends fcn_INTERNAL_raceCourse

%% fcn_INTERNAL_raceHills
function records = fcn_INTERNAL_raceHills(road, straightS, options)
% Hills for the race course: fcn_INTERNAL_hillyProfile with the straights
% held level (no easing on curves unless CurveGradeRadius is given:
% the whole course is curves), then closed (the height back to 0 at the
% end, by a correction that is zero on the straights) and capped at
% MaxHeightRange (default 4 m here; above 10 m a warning)
L = road.Length;
maxRange = options.MaxHeightRange;
if isinf(maxRange)
    maxRange = 4;
end
if maxRange > 10
    warning('AnimateCar3D:fillRoad:raceHills', 'MaxHeightRange %.1f m is more than the 10 m asked for the race course.', maxRange);
end
% (the straights' s-ranges, as rows of [sFrom sTo])
straightS = sort(straightS(:));
breaks = find(diff(straightS) > 1);
flatRanges = [straightS([1; breaks+1]), straightS([breaks; end])];
curveRadius = options.CurveGradeRadius;
if isempty(curveRadius)
    curveRadius = 0;
end
raw = fcn_INTERNAL_hillyProfile(L, options.Seed, fcn_INTERNAL_pick(options.MaxGrade, 0.06), options.MaxGradeChange, ...
    Inf, flatRanges, 'hilly', road.PlanView, curveRadius);
grid = unique([(0:0.5:L)'; L]);
z = fcn_INTERNAL_cubicValues(raw, grid);
offStraight = true(size(grid));
for ith_range = 1:size(flatRanges,1)
    offStraight(grid >= flatRanges(ith_range,1) - 0.5 & grid <= flatRanges(ith_range,2) + 0.5) = false;
end
closing = cumsum(double(offStraight))/max(sum(offStraight), 1);
z = z - z(end)*closing;                                   % (back to 0 at the end; level where it was level)
span = max(z) - min(z);
if span > maxRange
    z = z*maxRange/span;
end
% (cubic pieces every 2 m through the heights and their slopes)
knots = (0:2:L)';
if knots(end) < L
    knots = [knots; L];
end
zKnots = interp1(grid, z, knots);
slope = gradient(z, grid);
dKnots = interp1(grid, slope, knots);
records = repmat(fcn_INTERNAL_flatCubics(0), numel(knots)-1, 1);
for ith_piece = 1:numel(knots)-1
    h = knots(ith_piece+1) - knots(ith_piece);
    z0 = zKnots(ith_piece); z1 = zKnots(ith_piece+1); d0 = dKnots(ith_piece); d1 = dKnots(ith_piece+1);
    records(ith_piece) = struct('S',knots(ith_piece), 'A',z0, 'B',d0, 'C',(3*(z1 - z0)/h - 2*d0 - d1)/h, 'D',(2*(z0 - z1)/h + d0 + d1)/h^2);
end
end % Ends fcn_INTERNAL_raceHills

%% fcn_INTERNAL_raceBanking
function records = fcn_INTERNAL_raceBanking(road, maxCrossSlope)
% Banking for the race course: down to the inside of each curve, the full
% maxCrossSlope on curves tighter than 20 m radius (less on gentler ones),
% ramped over about 10 m; the bottom-rightmost curve banked the other way
planView = road.PlanView;
N = numel(planView);
curvature = zeros(N,1);
for ith_geometry = 1:N
    if strcmp(planView(ith_geometry).Type, 'arc')
        curvature(ith_geometry) = planView(ith_geometry).Curvature;
    end
end
smoothCurvature = movmean([curvature(end-2:end); curvature; curvature(1:3)], 5);
smoothCurvature = smoothCurvature(4:end-3);
roll = -sign(smoothCurvature).*atan(maxCrossSlope).*min(1, abs(smoothCurvature)*20);
% (the bottom-rightmost curve: of the runs of one turning direction, the
% one whose middle is farthest right and down)
flagCurve = abs(smoothCurvature) > 1/40;
turnSign = sign(smoothCurvature).*flagCurve;
runStarts = find(turnSign ~= 0 & [true; diff(turnSign) ~= 0]);
bestScore = -Inf; bestRun = [];
for ith_run = 1:numel(runStarts)
    runEnd = runStarts(ith_run);
    while runEnd < N && turnSign(runEnd+1)==turnSign(runStarts(ith_run))
        runEnd = runEnd + 1;
    end
    middle = round((runStarts(ith_run) + runEnd)/2);
    score = planView(middle).X - planView(middle).Y;
    if score > bestScore
        bestScore = score; bestRun = runStarts(ith_run):runEnd;
    end
end
flip = zeros(N,1); flip(bestRun) = 1;
flip = movmean([flip(end-2:end); flip; flip(1:3)], 5); flip = flip(4:end-3);
roll = roll.*(1 - 2*flip);
roll = movmean([roll(end-2:end); roll; roll(1:3)], 5); roll = roll(4:end-3);   % (about 10 m ramps)
rollNext = [roll(2:end); roll(1)];
records = repmat(fcn_INTERNAL_flatCubics(0), N, 1);
for ith_geometry = 1:N
    records(ith_geometry) = struct('S',planView(ith_geometry).S, 'A',roll(ith_geometry), ...
        'B',(rollNext(ith_geometry) - roll(ith_geometry))/planView(ith_geometry).Length, 'C',0, 'D',0);
end
end % Ends fcn_INTERNAL_raceBanking

%% fcn_INTERNAL_loopMean
function values = fcn_INTERNAL_loopMean(values, windowRows)
% A moving average around a closed loop
half = floor(windowRows/2);
padded = [values(end-half+1:end); values; values(1:half)];
values = movmean(padded, windowRows);
values = values(half+1:end-half);
end % Ends fcn_INTERNAL_loopMean

%% fcn_INTERNAL_hermite
function coefficients = fcn_INTERNAL_hermite(rowS, values, s0, s1, loopLength)
% Cubic [a b c d] in (s - s0) through the values and slopes at s0 and s1
% (from the samples, around the loop)
wrappedS = [rowS - loopLength; rowS; rowS + loopLength];
wrappedV = [values; values; values];
h = 0.5;
v0 = interp1(wrappedS, wrappedV, s0); v1 = interp1(wrappedS, wrappedV, s1);
d0 = (interp1(wrappedS, wrappedV, s0 + h) - interp1(wrappedS, wrappedV, s0 - h))/(2*h);
d1 = (interp1(wrappedS, wrappedV, s1 + h) - interp1(wrappedS, wrappedV, s1 - h))/(2*h);
L = s1 - s0;
coefficients = [v0, d0, (3*(v1 - v0)/L - 2*d0 - d1)/L, (2*(v0 - v1)/L + d0 + d1)/L^2];
end % Ends fcn_INTERNAL_hermite

%% fcn_INTERNAL_outlined
function object = fcn_INTERNAL_outlined(road, objectType, objectName, polyline, thickness, objectHeight)
% An object with an outline: anchored at the road point nearest the
% polyline's first vertex; the outline in that point's frame (u along the
% road's heading, v to its left)
[~, anchorS, anchorT] = fcn_AnimateCar3D_getRoadHeight(road, polyline(1,:), FigNum=-1);
anchor = fcn_AnimateCar3D_getRoadPoints(road, anchorS, T=anchorT, FigNum=-1);
relative = polyline - anchor(1:2);
outline = [relative(:,1)*cos(anchor(3)) + relative(:,2)*sin(anchor(3)), ...
          -relative(:,1)*sin(anchor(3)) + relative(:,2)*cos(anchor(3))];
object = fcn_INTERNAL_object(objectType, objectName, anchorS, anchorT, 0, thickness, objectHeight, 0);
object.Outline = outline;
end % Ends fcn_INTERNAL_outlined

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
    'Length',objectLength, 'Width',objectWidth, 'Height',objectHeight, 'Hdg',0, 'Repeat',false, 'Color',[], 'Outline',[]);
end % Ends fcn_INTERNAL_object

%% fcn_INTERNAL_flatCubics
function records = fcn_INTERNAL_flatCubics(sStart)
% One piecewise-cubic record of zeros (OpenDRIVE S, A, B, C, D)
records = struct('S',sStart, 'A',0, 'B',0, 'C',0, 'D',0);
end % Ends fcn_INTERNAL_flatCubics

%% fcn_INTERNAL_hillyProfile
function records = fcn_INTERNAL_hillyProfile(roadLength, seed, maxGrade, maxGradeChange, maxHeightRange, flatRanges, profileShape, planView, curveGradeRadius)
% Random hills made from the grade, from their own random numbers: knots
% spaced randomly (normal, mean 50 m, standard deviation 15 m, kept from
% 20 to 100 m), with every range end a knot; the grade at each knot is a
% random walk, each step no more than maxGradeChange per 100 m of the
% distance, within +/- maxGrade, starting level ('mountain': climbing all
% the way to a summit at mid-road, then descending all the way: each
% knot's grade a random 40 to 100% of maxGrade, uphill before the
% summit and downhill after, reached as fast as the limit allows). Inside
% flatRanges (rows of [sFrom sTo]) the grade is 0, and the knots around
% are pulled back so every step stays within the limit. The grade is
% linear between knots, so the height is quadratic (an OpenDRIVE cubic
% with D = 0). If the heights span more than maxHeightRange, all grades
% are scaled down. With curveGradeRadius > 0, each curve's ends are knots
% too, and the limit at each knot is lower on tight curves:
% maxGrade*R/curveGradeRadius, at least 0.2*maxGrade.
randomStream = RandStream('mt19937ar', 'Seed', seed + 2000);
curveEnds = zeros(0,1);
if curveGradeRadius > 0
    for ith_geometry = 1:numel(planView)
        if ~strcmp(planView(ith_geometry).Type, 'line')
            curveEnds = [curveEnds; planView(ith_geometry).S; planView(ith_geometry).S + planView(ith_geometry).Length]; %#ok<AGROW>
        end
    end
end
breaks = unique([0; roadLength; flatRanges(:); curveEnds(curveEnds > 0 & curveEnds < roadLength)]);
knotS = 0;
for ith_break = 1:numel(breaks)-1
    sHere = breaks(ith_break);
    while true
        spacing = min(max(50 + 15*randomStream.randn, 20), 100);
        if breaks(ith_break+1) - sHere < spacing + 20
            break;                                      % (the last piece of this stretch: to its end)
        end
        sHere = sHere + spacing;
        knotS(end+1,1) = sHere; %#ok<AGROW>
    end
    knotS(end+1,1) = breaks(ith_break+1); %#ok<AGROW>
end
knotS = unique(knotS);
Nknots = numel(knotS);
flagLevel = false(Nknots,1);
for ith_range = 1:size(flatRanges,1)
    flagLevel = flagLevel | (knotS >= flatRanges(ith_range,1) - 1e-9 & knotS <= flatRanges(ith_range,2) + 1e-9);
end
flagLevel(1) = true;                                    % (starts level)
gradePerMeter = maxGradeChange/100;
% (each knot's limit: lower on tight curves)
knotLimit = maxGrade*ones(Nknots,1);
if curveGradeRadius > 0
    knotCurvature = fcn_INTERNAL_curvatureAt(planView, knotS);
    knotLimit = maxGrade*max(0.2, min(1, 1./(max(knotCurvature, eps)*curveGradeRadius)));
end
knotGrade = zeros(Nknots,1);
draws = randomStream.rand(Nknots,1);
for ith_knot = 2:Nknots
    stepLimit = gradePerMeter*(knotS(ith_knot) - knotS(ith_knot-1));
    if strcmp(profileShape, 'mountain')
        target = knotLimit(ith_knot)*(0.4 + 0.6*draws(ith_knot))*sign(roadLength/2 - knotS(ith_knot));
        step = min(max(target - knotGrade(ith_knot-1), -stepLimit), stepLimit);
    else
        step = stepLimit*(2*draws(ith_knot) - 1);
    end
    knotGrade(ith_knot) = min(max(knotGrade(ith_knot-1) + step, -knotLimit(ith_knot)), knotLimit(ith_knot));
end
knotGrade(flagLevel) = 0;
for pass = 1:4                                          % (every step within the limit, level knots level)
    knotGrade = min(max(knotGrade, -knotLimit), knotLimit);
    for ith_knot = [2:Nknots, Nknots-1:-1:1]
        for neighbor = ith_knot + [-1 1]
            if neighbor >= 1 && neighbor <= Nknots
                stepLimit = gradePerMeter*abs(knotS(ith_knot) - knotS(neighbor));
                knotGrade(ith_knot) = min(max(knotGrade(ith_knot), knotGrade(neighbor) - stepLimit), knotGrade(neighbor) + stepLimit);
            end
        end
        if flagLevel(ith_knot)
            knotGrade(ith_knot) = 0;
        end
    end
end
records = fcn_INTERNAL_gradeCubics(knotS, knotGrade);
fineHeights = fcn_INTERNAL_cubicValues(records, linspace(0, roadLength, 4000)');
heightRange = max(fineHeights) - min(fineHeights);
if heightRange > maxHeightRange
    records = fcn_INTERNAL_gradeCubics(knotS, knotGrade*maxHeightRange/heightRange);
end
end % Ends fcn_INTERNAL_hillyProfile

%% fcn_INTERNAL_curvatureAt
function curvatures = fcn_INTERNAL_curvatureAt(planView, sValues)
% The largest curvature magnitude at each s (of the geometries touching
% it, within 0.5 m)
curvatures = zeros(size(sValues));
for ith_geometry = 1:numel(planView)
    geometry = planView(ith_geometry);
    rows = sValues >= geometry.S - 0.5 & sValues <= geometry.S + geometry.Length + 0.5;
    switch geometry.Type
        case 'arc'
            here = abs(geometry.Curvature)*ones(nnz(rows),1);
        case 'spiral'
            fraction = min(max((sValues(rows) - geometry.S)/geometry.Length, 0), 1);
            here = abs(geometry.CurvStart + fraction*(geometry.CurvEnd - geometry.CurvStart));
        otherwise
            here = zeros(nnz(rows),1);
    end
    curvatures(rows) = max(curvatures(rows), here(:));
end
end % Ends fcn_INTERNAL_curvatureAt

%% fcn_INTERNAL_gradeCubics
function records = fcn_INTERNAL_gradeCubics(knotS, knotGrade)
% Heights from grades that are linear between knots: quadratic pieces,
% starting at height 0, each starting where the last ended
Npieces = numel(knotS) - 1;
records = repmat(fcn_INTERNAL_flatCubics(0), Npieces, 1);
height = 0;
for ith_piece = 1:Npieces
    L = knotS(ith_piece+1) - knotS(ith_piece);
    curvatureTerm = (knotGrade(ith_piece+1) - knotGrade(ith_piece))/(2*L);
    records(ith_piece) = struct('S',knotS(ith_piece), 'A',height, 'B',knotGrade(ith_piece), 'C',curvatureTerm, 'D',0);
    height = height + knotGrade(ith_piece)*L + curvatureTerm*L^2;
end
end % Ends fcn_INTERNAL_gradeCubics

%% fcn_INTERNAL_cubicValues
function values = fcn_INTERNAL_cubicValues(records, sValues)
% Piecewise cubics' values
pieceIndex = max(sum(sValues >= [records.S], 2), 1);
ds = sValues - [records(pieceIndex).S]';
values = [records(pieceIndex).A]' + [records(pieceIndex).B]'.*ds + [records(pieceIndex).C]'.*ds.^2 + [records(pieceIndex).D]'.*ds.^3;
end % Ends fcn_INTERNAL_cubicValues

%% fcn_INTERNAL_bankedProfile
function records = fcn_INTERNAL_bankedProfile(planView, maxCrossSlope)
% Superelevation following the curvature: down to the inside of each
% curve (a left curve, curvature > 0, lowers the left side: a negative
% roll), proportional to the curvature, maxCrossSlope at the tightest.
% Linear in s along spirals, constant on arcs, zero on lines.
curvatureEnds = zeros(numel(planView), 2);
for ith_geometry = 1:numel(planView)
    switch planView(ith_geometry).Type
        case 'arc'
            curvatureEnds(ith_geometry,:) = planView(ith_geometry).Curvature;
        case 'spiral'
            curvatureEnds(ith_geometry,:) = [planView(ith_geometry).CurvStart planView(ith_geometry).CurvEnd];
    end
end
tightest = max(abs(curvatureEnds(:)));
records = repmat(fcn_INTERNAL_flatCubics(0), numel(planView), 1);
if tightest==0
    records = fcn_INTERNAL_flatCubics(0);
    return;
end
rollPerCurvature = -atan(maxCrossSlope)/tightest;
for ith_geometry = 1:numel(planView)
    records(ith_geometry) = struct('S',planView(ith_geometry).S, 'A',rollPerCurvature*curvatureEnds(ith_geometry,1), ...
        'B',rollPerCurvature*diff(curvatureEnds(ith_geometry,:))/planView(ith_geometry).Length, 'C',0, 'D',0);
end
end % Ends fcn_INTERNAL_bankedProfile

%% fcn_INTERNAL_mountainSegments
function segments = fcn_INTERNAL_mountainSegments(targetLength, seed, startPose)
% A random winding road: a straight run, then a bend (spiral in, arc,
% spiral out), repeated until targetLength. Bends are 30 to 120 m radius,
% turning 20 to 100 degrees; about one in six is a hairpin (18 to 25 m
% radius, 150 to 180 degrees). The road keeps a general direction: once
% the net turn passes 90 degrees, bends turn back (so hairpins come in
% switchback pairs, as up a mountainside); otherwise they mostly
% alternate. Each new bend is tried up to 20 times so that every point
% stays 30 m from the road more than 150 m back along it; if none fits,
% the bend before is taken back and tried again.
randomStream = RandStream('mt19937ar', 'Seed', seed + 4000);
segments = fcn_INTERNAL_segment('line', 40, 0, 0);
blockTurns = 0;                                         % (the net turn after each block, radians)
turnDirection = 1;
backtracks = 0;
while sum([segments.Length]) < targetLength
    netTurn = blockTurns(end);
    flagPlaced = false;
    for attempt = 1:20
        draws = randomStream.rand(1,5);
        if abs(netTurn) > pi/2
            turnDirection = -sign(netTurn);             % (turn back toward the general direction)
        elseif draws(5) < 0.75
            turnDirection = -turnDirection;             % (mostly alternating)
        end
        if draws(1) < 1/6 && abs(netTurn) <= pi/2
            radius = 18 + 7*draws(2);
            turnAngle = deg2rad(150 + 30*draws(3));
        else
            radius = 30 + 90*draws(2);
            turnAngle = deg2rad(20 + 80*draws(3));
        end
        straightLength = 15 + 65*draws(4);
        spiralLength = min(25, 0.8*radius*turnAngle);
        arcLength = radius*turnAngle - spiralLength;     % (the two spirals turn spiralLength/radius in all)
        curvature = turnDirection/radius;
        block = [fcn_INTERNAL_segment('line', straightLength, 0, 0); ...
                 fcn_INTERNAL_segment('spiral', spiralLength, 0, curvature); ...
                 fcn_INTERNAL_segment('arc', arcLength, curvature, curvature); ...
                 fcn_INTERNAL_segment('spiral', spiralLength, curvature, 0)];
        if fcn_INTERNAL_clearOfItself([segments; block], sum([segments.Length]), startPose)
            segments = [segments; block]; %#ok<AGROW>
            blockTurns(end+1) = netTurn + turnDirection*turnAngle; %#ok<AGROW>
            flagPlaced = true;
            break;
        end
    end
    if ~flagPlaced
        backtracks = backtracks + 1;
        if numel(segments) > 1 && backtracks < 200
            segments = segments(1:end-4);               % (take the last bend back)
            blockTurns(end) = [];
        else
            error('Could not lay out a mountain road clear of itself; try another Seed or Length');
        end
    end
end
segments(end+1) = fcn_INTERNAL_segment('line', 40, 0, 0);
end % Ends fcn_INTERNAL_mountainSegments

%% fcn_INTERNAL_clearOfItself
function flagClear = fcn_INTERNAL_clearOfItself(segments, sNew, startPose)
% True if every point of the road after sNew stays 30 m from every point
% more than 150 m before it along the road
planView = fcn_INTERNAL_planView(segments, startPose);
roadLength = planView(end).S + planView(end).Length;
sAll = (0:5:roadLength)';
allPoints = fcn_AnimateCar3D_getRoadPoints(struct('PlanView',planView), sAll, FigNum=-1);
newRows = find(sAll >= sNew);
distances = hypot(allPoints(newRows,1) - allPoints(:,1)', allPoints(newRows,2) - allPoints(:,2)');
farBack = sAll(newRows) - sAll' > 150;
flagClear = ~any(distances(farBack) <= 30);
end % Ends fcn_INTERNAL_clearOfItself

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
    'CurbFaces',struct('Ends',{}, 'Height',{}), 'Connections',[]);
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
% Connections through the junction (OpenDRIVE <connection>): from each
% lane coming in, to the lane going out that its arrow allows. Arm k's
% traffic comes in heading opposite to the arm; a left turn leaves on arm
% k-1, straight on arm k+2, a right turn on arm k+1.
connections = struct('ID',{}, 'IncomingRoad',{}, 'IncomingLane',{}, 'OutgoingRoad',{}, 'OutgoingLane',{}, ...
    'Turn',{}, 'Path',{});
for ith_arm = 1:4
    for ith_lane = 1:Nin
        if ith_lane==1
            turns = {'left'};
        elseif ith_lane==Nin && Nin==2
            turns = {'straight','right'};
        elseif ith_lane==Nin
            turns = {'right'};
        else
            turns = {'straight'};
        end
        for thisTurn = turns
            switch thisTurn{1}
                case 'left'
                    outArm = mod(ith_arm - 2, 4) + 1;
                    outLane = -1;
                case 'straight'
                    outArm = mod(ith_arm + 1, 4) + 1;
                    outLane = -ith_lane;
                case 'right'
                    outArm = mod(ith_arm, 4) + 1;
                    outLane = -Nout;
            end
            pointIn = fcn_AnimateCar3D_getRoadPoints(roads(ith_arm), 0, LaneID=ith_lane, FigNum=-1);
            pointOut = fcn_AnimateCar3D_getRoadPoints(roads(outArm), 0, LaneID=outLane, FigNum=-1);
            headingIn = pointIn(3) + pi;
            segments = fcn_INTERNAL_turnSegments(pointIn(1:2), headingIn, pointOut(1:2), pointOut(3));
            pathView = fcn_INTERNAL_planView(segments, [pointIn(1:2) headingIn]);
            path = struct('ID',sprintf('c%d', numel(connections)+1), 'PlanView',pathView, ...
                'Length',pathView(end).S + pathView(end).Length);
            connections(end+1) = struct('ID',numel(connections)+1, 'IncomingRoad',roads(ith_arm).ID, ...
                'IncomingLane',ith_lane, 'OutgoingRoad',roads(outArm).ID, 'OutgoingLane',outLane, ...
                'Turn',thisTurn{1}, 'Path',path); %#ok<AGROW>
        end
    end
end
junction.Connections = connections;

network = struct('ID','intersection', 'Name','intersection', 'TrafficRule','RHT', 'Units','meters, radians', ...
    'Roads',roads, 'Junctions',junction, ...
    'EgoStart',struct('Road','3', 'LaneID',2, 'S',armLength, 'Direction',-1));
end % Ends fcn_INTERNAL_intersection

%% fcn_INTERNAL_urbanGrid
function network = fcn_INTERNAL_urbanGrid(options, laneWidth)
% A main street (heading Start(3)) crossed by CrossStreets cross streets,
% BlockLength apart: a junction at each crossing, built as the
% intersection's (2 lanes each way); the main street's roads run from
% junction to junction (the approach road ends at the first, the exit
% road starts at the last), and each cross street is two arms pointing
% away from its junction; city blocks of trees and buildings between
Njunctions = options.CrossStreets;
blockLength = fcn_INTERNAL_pick(options.BlockLength, 100);
armLength = fcn_INTERNAL_pick(options.Length, 60);
Nlanes = 2;                                % (each way)
halfSize = Nlanes*laneWidth;               % the junction's half-size
markLength = 30;                           % (solid lane line before each junction)
white = 'standard';
heading = options.Start(3);
along = [cos(heading) sin(heading)];
across = [-sin(heading) cos(heading)];     % (north: the main street's left)
centers = options.Start(1:2) + (armLength + halfSize + (0:Njunctions-1)'*blockLength)*along;

% The roads: approach, links, exit (along the main street), then the
% cross streets' arms (north, then south, at each junction). For each:
% start point, heading, length, and the junction at each end
starts = [options.Start(1:2); centers + halfSize*along];
headings = heading*ones(Njunctions+1, 1);
lengths = [armLength; (blockLength - 2*halfSize)*ones(Njunctions-1, 1); armLength];
fromJunction = [0, 1:Njunctions];
toJunction = [1:Njunctions, 0];
names = [{'approach'}, arrayfun(@(j) sprintf('main street, block %d', j), 1:Njunctions-1, 'UniformOutput', false), {'exit'}];
for ith_junction = 1:Njunctions
    for side = [1 -1]
        starts(end+1,:) = centers(ith_junction,:) + side*halfSize*across; %#ok<AGROW>
        headings(end+1,1) = heading + side*pi/2; %#ok<AGROW>
        lengths(end+1,1) = armLength; %#ok<AGROW>
        fromJunction(end+1) = ith_junction; %#ok<AGROW>
        toJunction(end+1) = 0; %#ok<AGROW>
        if side > 0
            names{end+1} = sprintf('cross street %d, north', ith_junction); %#ok<AGROW>
        else
            names{end+1} = sprintf('cross street %d, south', ith_junction); %#ok<AGROW>
        end
    end
end
Nroads = numel(lengths);

% Lanes: as the intersection's arms (2 driving lanes each way, curb,
% sidewalk, grass); the lane line between a side's two lanes is solid
% over the last markLength meters before a junction, broken elsewhere
centerLane = fcn_INTERNAL_lane(0, 'none', 0, 0, 'solid solid', 'yellow');
laneSet = @(rightMark, leftMark) deal( ...
    [fcn_INTERNAL_lane(-1, 'driving', laneWidth, 0, rightMark, white); ...
     fcn_INTERNAL_lane(-2, 'driving', laneWidth, 0, 'none', white); ...
     fcn_INTERNAL_lane(-3, 'curb', 0.15, 0.15, 'none', white); ...
     fcn_INTERNAL_lane(-4, 'walking', 2.5, 0.15, 'none', white); ...
     fcn_INTERNAL_lane(-5, 'border', 1.5, 0.15, 'none', white)], ...
    [fcn_INTERNAL_lane(1, 'driving', laneWidth, 0, leftMark, white); ...
     fcn_INTERNAL_lane(2, 'driving', laneWidth, 0, 'none', white); ...
     fcn_INTERNAL_lane(3, 'curb', 0.15, 0.15, 'none', white); ...
     fcn_INTERNAL_lane(4, 'walking', 2.5, 0.15, 'none', white); ...
     fcn_INTERNAL_lane(5, 'border', 1.5, 0.15, 'none', white)]);
noLink = struct('ElementType','', 'ElementID','');
for ith_road = 1:Nroads
    roadLength = lengths(ith_road);
    % (lane sections: where each side's traffic comes in to a junction)
    flagInAtStart = fromJunction(ith_road) > 0;       % (left lanes come in at s = 0)
    flagInAtEnd = toJunction(ith_road) > 0;           % (right lanes come in at s = Length)
    breaks = 0;
    if flagInAtStart
        breaks(end+1) = min(markLength, roadLength/2); %#ok<AGROW>
    end
    if flagInAtEnd
        breaks(end+1) = max(roadLength - markLength, roadLength/2); %#ok<AGROW>
    end
    breaks = unique(breaks);
    sections = struct('S',{}, 'Left',{}, 'Center',{}, 'Right',{});
    for ith_section = 1:numel(breaks)
        nextBreaks = [breaks(ith_section+1:end), roadLength];
        sectionMid = (breaks(ith_section) + nextBreaks(1))/2;
        rightMark = 'broken'; leftMark = 'broken';
        if flagInAtEnd && sectionMid > roadLength - markLength
            rightMark = 'solid';
        end
        if flagInAtStart && sectionMid < markLength
            leftMark = 'solid';
        end
        [rightLanes, leftLanes] = laneSet(rightMark, leftMark);
        sections(end+1) = struct('S',breaks(ith_section), 'Left',{leftLanes}, 'Center',centerLane, 'Right',{rightLanes}); %#ok<AGROW>
    end
    predecessor = noLink; successor = noLink;
    if flagInAtStart
        predecessor = struct('ElementType','junction', 'ElementID',sprintf('%d', fromJunction(ith_road)));
    end
    if flagInAtEnd
        successor = struct('ElementType','junction', 'ElementID',sprintf('%d', toJunction(ith_road)));
    end
    thisRoad = struct('ID',sprintf('%d', ith_road), 'Name',names{ith_road}, 'TrafficRule','RHT', ...
        'Units','meters, radians', 'Length',roadLength, ...
        'PlanView',fcn_INTERNAL_planView(fcn_INTERNAL_segment('line', roadLength, 0, 0), [starts(ith_road,:) headings(ith_road)]), ...
        'LaneSections',sections, 'Objects',[], 'Junction','-1', 'Predecessor',predecessor, 'Successor',successor);
    thisRoad.Objects = fcn_INTERNAL_gridObjects(thisRoad, laneWidth, Nlanes, flagInAtStart, flagInAtEnd, ...
        ith_road > Njunctions + 1, options, ith_road, across);
    roads(ith_road) = thisRoad; %#ok<AGROW>
end

% The junctions: an asphalt square, a square of sidewalk at each corner
% (joining the arms' sidewalks), and the connections from each lane
% coming in to the lanes it may go to
toWorld = @(center, uv) center + uv(:,1)*along + uv(:,2)*across;
squareCorners = [-1 -1; 1 -1; 1 1; -1 1]*halfSize;
cornerSquare = [0 0; 1 0; 1 1; 0 1]*2.65;
headingError = @(a) atan2(sin(a), cos(a));
for ith_junction = 1:Njunctions
    center = centers(ith_junction,:);
    junction = struct('ID',sprintf('%d', ith_junction), 'Type','default', 'Center',center, ...
        'Surfaces',struct('Corners',toWorld(center, squareCorners), 'Height',0, 'Type','driving'), ...
        'CurbFaces',struct('Ends',{}, 'Height',{}), 'Connections',[]);
    for cornerSigns = [1 1; -1 1; -1 -1; 1 -1]'
        uv = halfSize*cornerSigns' + cornerSquare.*cornerSigns';
        junction.Surfaces(end+1) = struct('Corners',toWorld(center, uv), 'Height',0.15, 'Type','walking');
    end
    % (the legs: each road end at this junction, with the direction
    % pointing away from the junction along it)
    legRoads = [find(fromJunction==ith_junction), find(toJunction==ith_junction)];
    legAtStart = [true(1, sum(fromJunction==ith_junction)), false(1, sum(toJunction==ith_junction))];
    legAngles = headings(legRoads)' + pi*~legAtStart;
    connections = struct('ID',{}, 'IncomingRoad',{}, 'IncomingLane',{}, 'OutgoingRoad',{}, 'OutgoingLane',{}, ...
        'Turn',{}, 'Path',{});
    for ith_leg = 1:numel(legRoads)
        inRoad = roads(legRoads(ith_leg));
        for ith_lane = 1:Nlanes
            if ith_lane==1
                turns = {'left'};
            else
                turns = {'straight','right'};
            end
            for thisTurn = turns
                turnAngle = pi/2*(strcmp(thisTurn{1},'left') - strcmp(thisTurn{1},'right'));
                relative = headingError(legAngles - (legAngles(ith_leg) + pi) - turnAngle);
                outLeg = find(abs(relative) < 0.1, 1);
                if isempty(outLeg)
                    continue;
                end
                outRoad = roads(legRoads(outLeg));
                outIndex = ith_lane;
                if strcmp(thisTurn{1}, 'left')
                    outIndex = 1;
                elseif strcmp(thisTurn{1}, 'right')
                    outIndex = Nlanes;
                end
                % (lane numbers: coming in, the left lanes at s = 0, the
                % right lanes at s = Length; going out, the opposite)
                if legAtStart(ith_leg)
                    inLane = ith_lane; inS = 0; inTurn = pi;
                else
                    inLane = -ith_lane; inS = inRoad.Length; inTurn = 0;
                end
                if legAtStart(outLeg)
                    outLane = -outIndex; outS = 0; outTurn = 0;
                else
                    outLane = outIndex; outS = outRoad.Length; outTurn = pi;
                end
                pointIn = fcn_AnimateCar3D_getRoadPoints(inRoad, inS, LaneID=inLane, FigNum=-1);
                pointOut = fcn_AnimateCar3D_getRoadPoints(outRoad, outS, LaneID=outLane, FigNum=-1);
                headingIn = pointIn(3) + inTurn;
                segments = fcn_INTERNAL_turnSegments(pointIn(1:2), headingIn, pointOut(1:2), pointOut(3) + outTurn);
                pathView = fcn_INTERNAL_planView(segments, [pointIn(1:2) headingIn]);
                path = struct('ID',sprintf('j%dc%d', ith_junction, numel(connections)+1), 'PlanView',pathView, ...
                    'Length',pathView(end).S + pathView(end).Length);
                connections(end+1) = struct('ID',numel(connections)+1, 'IncomingRoad',inRoad.ID, ...
                    'IncomingLane',inLane, 'OutgoingRoad',outRoad.ID, 'OutgoingLane',outLane, ...
                    'Turn',thisTurn{1}, 'Path',path); %#ok<AGROW>
            end
        end
    end
    junction.Connections = connections;
    junctions(ith_junction) = junction; %#ok<AGROW>
end

network = struct('ID','urbanGrid', 'Name','urbanGrid', 'TrafficRule','RHT', 'Units','meters, radians', ...
    'Roads',roads, 'Junctions',junctions, ...
    'EgoStart',struct('Road','1', 'LaneID',-Nlanes, 'S',0, 'Direction',1));
end % Ends fcn_INTERNAL_urbanGrid

%% fcn_INTERNAL_gridObjects
function objects = fcn_INTERNAL_gridObjects(road, laneWidth, Nlanes, flagInAtStart, flagInAtEnd, flagCrossStreet, options, roadIndex, north)
% One urban-grid road's objects: at each junction end, a crosswalk, a stop
% line, and lane arrows; block trees along the sidewalks; buildings at
% random (repeatably) behind them, tall north of the main street and low
% to its south; and pedestrians standing on the sidewalks
roadLength = road.Length;
width = Nlanes*laneWidth;
curbT = width + 0.15;                      % (the sidewalk's inner edge)
objects = fcn_INTERNAL_object('', '', 0, 0, 0, 0, 0, 0);
objects(1) = [];
arrowNames = {'left','straightRight'};
if flagInAtStart                           % (traffic comes in on the left lanes, toward s = 0)
    objects(end+1) = fcn_INTERNAL_object('crosswalk', 'continental', 2.5, 0, 3.0, 2*width, 0, 0);
    objects(end+1) = fcn_INTERNAL_object('stopLine', 'stopLine', 5.4, width/2, 0.4, width, 0, 0);
    for ith_lane = 1:Nlanes
        arrow = fcn_INTERNAL_object('arrow', arrowNames{ith_lane}, 15, (ith_lane - 0.5)*laneWidth, 5, 0.7, 0, 0);
        arrow.Hdg = pi;
        objects(end+1) = arrow; %#ok<AGROW>
    end
end
if flagInAtEnd                             % (traffic comes in on the right lanes, toward s = Length)
    objects(end+1) = fcn_INTERNAL_object('crosswalk', 'continental', roadLength - 2.5, 0, 3.0, 2*width, 0, 0);
    objects(end+1) = fcn_INTERNAL_object('stopLine', 'stopLine', roadLength - 5.4, -width/2, 0.4, width, 0, 0);
    for ith_lane = 1:Nlanes
        objects(end+1) = fcn_INTERNAL_object('arrow', arrowNames{ith_lane}, roadLength - 15, -(ith_lane - 0.5)*laneWidth, 5, 0.7, 0, 0); %#ok<AGROW>
    end
end

% Block trees every 15 m, 0.8 m from the curb, clear of the crosswalks
randomStream = RandStream('mt19937ar', 'Seed', options.Seed + 37*roadIndex);
sFirst = 8*flagInAtStart + 4*~flagInAtStart;
sLast = roadLength - (8*flagInAtEnd + 4*~flagInAtEnd);
for side = [-1 1]
    for sTree = sFirst:15:sLast
        objects(end+1) = fcn_INTERNAL_object('tree', 'blockTree', sTree, side*(curbT + 0.8), 2.4, 2.4, 4.4, 0); %#ok<AGROW>
    end
end

% Buildings, set back behind the sidewalk, clear of the cross streets (a
% cross street's arms start past the main street's buildings, which turn
% the corners)
heading = road.PlanView(1).Hdg;
setback = options.BuildingSetback;
if flagCrossStreet
    sClear = curbT + 2.5 + setback + 20 + 2 - width;   % (past the main street's deepest buildings)
else
    sClear = 2.65 + 1.5 + setback;                     % (past the cross street's sidewalk and grass)
end
sFrom = sClear*flagInAtStart;
sTo = roadLength - sClear*flagInAtEnd;
buildingSides = lower(char(fcn_INTERNAL_pick(options.BuildingSides, 'both')));
for side = [-1 1]
    flagBuildHere = strcmp(buildingSides,'both') || (side > 0 && strcmp(buildingSides,'left')) || ...
        (side < 0 && strcmp(buildingSides,'right'));
    sBuilding = sFrom + 2*randomStream.rand;
    while true
        buildingLength = 10 + 15*randomStream.rand;
        if sBuilding + buildingLength > sTo
            break;
        end
        buildingDepth = 12 + 8*randomStream.rand;
        heightDraw = randomStream.rand;
        storyDraw = randomStream.rand;
        buildingT = side*(curbT + 2.5 + setback + buildingDepth/2);
        % (north of the main street: tall; south: low)
        if flagCrossStreet
            flagNorth = dot([cos(heading) sin(heading)], north) > 0;
        else
            flagNorth = side > 0;
        end
        if flagNorth
            buildingHeight = 6 + 24*heightDraw^2;
        else
            buildingHeight = fcn_INTERNAL_nearSideHeight(heightDraw, storyDraw);
        end
        building = fcn_INTERNAL_object('building', 'block', sBuilding + buildingLength/2, buildingT, ...
            buildingLength, buildingDepth, buildingHeight, 0);
        shade = 0.55 + 0.3*randomStream.rand;
        building.Color = shade*[1 0.95 0.88] .* (0.9 + 0.1*randomStream.rand(1,3));
        if flagBuildHere
            objects(end+1) = building; %#ok<AGROW>
        end
        sBuilding = sBuilding + buildingLength + 2 + 4*randomStream.rand;
    end
end
objects = [objects, fcn_INTERNAL_pedestrians(roadLength, [-1 1]*(curbT + 1.25), 0.6, 15, 0.3, options.Seed + 7*roadIndex)];
for ith_object = 1:numel(objects)
    objects(ith_object).ID = ith_object;
end
end % Ends fcn_INTERNAL_gridObjects

%% fcn_INTERNAL_turnSegments
function segments = fcn_INTERNAL_turnSegments(pointIn, headingIn, pointOut, headingOut)
% The path through a junction: a line (straight on), or for a quarter
% turn a line and an arc (or an arc and a line) that join the lane
% centers at both ends, with matching headings
offset = [cos(headingIn) sin(headingIn); -sin(headingIn) cos(headingIn)]*(pointOut(:) - pointIn(:));
along = offset(1);
sideways = offset(2);
turnAngle = atan2(sin(headingOut - headingIn), cos(headingOut - headingIn));
if abs(turnAngle) < 1e-6
    segments = fcn_INTERNAL_segment('line', hypot(along, sideways), 0, 0);
    return;
end
radius = min(along, abs(sideways));
curvature = sign(sideways)/radius;
arc = fcn_INTERNAL_segment('arc', radius*abs(turnAngle), curvature, curvature);
if along - abs(sideways) > 1e-9
    segments = [fcn_INTERNAL_segment('line', along - abs(sideways), 0, 0); arc];
elseif abs(sideways) - along > 1e-9
    segments = [arc; fcn_INTERNAL_segment('line', abs(sideways) - along, 0, 0)];
else
    segments = arc;
end
end % Ends fcn_INTERNAL_turnSegments

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
