function scenario = fcn_AnimateCar3D_fillExampleScenario(scenarioName, options)
% fcn_AnimateCar3D_fillExampleScenario

% Fills one of the example scenarios: a scene (a road from
% fcn_AnimateCar3D_fillRoad, procedural from Seed), its centerline
% options, and the objects and their motions, ready for
% fcn_AnimateCar3D_playScenario. The examples go from simplest up. With
% no inputs, lists the examples.
%
% ONE VEHICLE, ONE MANEUVER (all visuals at their defaults):
%
%   'laneChange'          the two-lane road: a lane change to the left at
%                         a constant 15 m/s, over 60 m, with the left turn
%                         signal on from 1.5 s before
%   'curvyConstantSpeed'  the curvy road: following the right lane's
%                         center at a constant 12 m/s
%   'curvyVaryingSpeed'   the curvy road: following the right lane's
%                         center, slowing for the curves (no more than 2
%                         m/s^2 sideways, up to 20 m/s on the straights,
%                         speeding up at 1.5 m/s^2 and braking at 2 m/s^2;
%                         brake lights while slowing)
%
% ONE VEHICLE ON HILLS (the vehicle pitches and rolls with the road; the
% ground is drawn around it):
%
%   'curvyHills'          the curvy road with hills and banked curves:
%                         following the right lane's center at 12 m/s
%   'mountainRoad'        the mountain road: up to the summit and down,
%                         grades up to 12%, banked curves and hairpins,
%                         slowing for the curves as above (hairpins at
%                         about 6 m/s); the body's pitch and roll on its
%                         wheels exaggerated 6 times so they show; the
%                         camera tilts with the road (CameraPitch 'road')
%
% ONE VEHICLE ON THE RACE COURSE:
%
%   'raceCourse'          one lap of the race course traced from a photo
%                         (fcn_AnimateCar3D_fillRoad 'raceCourse'), along
%                         the track's center: up to 22 m/s on the
%                         straights, no more than 6 m/s^2 sideways in the
%                         corners, braking at up to 6 m/s^2
%   'raceCourseHills'     the same lap on the race course with hills
%                         (about 4 m, the straights level) and banked
%                         curves (the bottom-rightmost the other way):
%                         the vehicle rides the surface, the ground is
%                         drawn around it
%
% SEVERAL OBJECTS:
%
%   'following'           the two-lane road: a lead car (red) starts 30 m
%                         ahead at 14 m/s, brakes to 5 m/s, and speeds up
%                         again; the ego follows it 1.5 s behind (its own
%                         brake lights as it slows)
%   'passing'             the two-lane road: a slow car (gray) at 8 m/s,
%                         40 m ahead; the ego, at 15 m/s, signals left,
%                         moves into the oncoming lane, passes, signals
%                         right, and moves back
%   'pedestrianCrossing'  the urban street: the ego (12 m/s) brakes to a
%                         stop 2 m before a crosswalk while a pedestrian
%                         crosses it, waits until the pedestrian is clear
%                         of its lane, and drives on
%   'urbanGrid'           the urban grid (three cross streets): the ego
%                         goes straight through the first junction,
%                         changes to the left-turn lane, and turns left
%                         at the second (centerline option 'straight,
%                         lane -1, left turn'), slowing for the turns; a
%                         car (dark green) drives the main street the
%                         other way
%
% Each vehicle is the CarMesh3D sample car ('sample'), named 'ego'.
%
% FORMAT:
%
%       scenario = fcn_AnimateCar3D_fillExampleScenario(scenarioName,...
%           (Seed=seed), (TimeOfDay=timeOfDay), (FigNum=figNum))
%
%       exampleList = fcn_AnimateCar3D_fillExampleScenario()
%
% INPUTS:
%
%      scenarioName: one of the names above. Empty or left out: the list
%      of examples (printed if no output is asked for).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Seed: the scene's random seed (fcn_AnimateCar3D_fillRoad).
%      Default 1.
%
%      TimeOfDay: 'day' (default) or 'night': the night version of the
%      example (fcn_AnimateCar3D_playScenario plays it at night: a dark
%      sky, night colors, lit windows, and the vehicles' headlights and
%      taillights glowing, with pools of light). Every example has one.
%
%      FigNum: a figure to draw the scene and the paths from above.
%      Empty (default) for no figure; -1 for fast mode (no input checks).
%
% OUTPUTS:
%
%      scenario: Name, Description, RoadPreset, Seed, Road,
%      CenterlineOptions (from the scene's fixed start), SceneList (for
%      fcn_AnimateCar3D_buildCatalog), Motions (a cell array, one per
%      object), Duration (seconds), and MeshIDs.
%
%      With no scenarioName: a structure array of the examples (Name,
%      Description).
%
% DEPENDENCIES:
%
%      fcn_AnimateCar3D_fillRoad, fcn_AnimateCar3D_fillPathMotion,
%      fcn_AnimateCar3D_loadSceneList; for the plot,
%      fcn_AnimateCar3D_fillCenterlineOptions
%
% EXAMPLES:
%
%       scenario = fcn_AnimateCar3D_fillExampleScenario('laneChange');
%       fcn_AnimateCar3D_playScenario(scenario);
%
%       See the script: script_test_fcn_AnimateCar3D_fillExampleScenario.m
%       for a full test suite, and script_examples_AnimateCar3D.m.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillExampleScenario
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillExampleScenario
%   % * Added the several-object examples: following, passing, pedestrianCrossing

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillExampleScenario
%   % * Cross traffic at an intersection (after the cross streets)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    scenarioName = ''
    options.Seed = 1              % the scene's random seed
    options.TimeOfDay = 'day'     % 'day' or 'night'
    options.FigNum = []           % figure to draw the scene; -1 for fast mode
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


        % Check the scenario name
        if ~((ischar(options.TimeOfDay) || isstring(options.TimeOfDay)) && any(strcmpi(char(options.TimeOfDay), {'day','night'})))
            error('TimeOfDay must be ''day'' or ''night''');
        end
        exampleNames = {'laneChange','curvyConstantSpeed','curvyVaryingSpeed','curvyHills','mountainRoad','raceCourse','raceCourseHills','following','passing','pedestrianCrossing','urbanGrid'};
        if ~(ischar(scenarioName) || isstring(scenarioName)) || (~isempty(char(scenarioName)) && ~any(strcmp(char(scenarioName), exampleNames)))
            error('scenarioName must be one of: %s', strjoin(exampleNames, ', '));
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


exampleList = struct('Name',{'laneChange','curvyConstantSpeed','curvyVaryingSpeed','curvyHills','mountainRoad','raceCourse','raceCourseHills','following','passing','pedestrianCrossing','urbanGrid'}, ...
    'Description',{'One vehicle on the two-lane road: a lane change to the left at a constant 15 m/s', ...
                   'One vehicle on the curvy road, following its lane at a constant 12 m/s', ...
                   'One vehicle on the curvy road, following its lane, slowing for the curves', ...
                   'One vehicle on the curvy road with hills and banked curves, at a constant 12 m/s', ...
                   'One vehicle up and over the mountain road (12% grades, banking, hairpins), slowing for the curves', ...
                   'One lap of the race course traced from a photo, along the track''s center, braking for the corners', ...
                   'One lap of the race course with hills (about 4 m) and banked curves, riding the surface', ...
                   'Following: a lead car speeds up and brakes; the ego follows it, 1.5 s behind', ...
                   'Passing: the ego overtakes a slow car through the oncoming lane, signaling', ...
                   'Stopping for a pedestrian: the ego stops at a crosswalk while a pedestrian crosses, then drives on', ...
                   'Urban grid: straight through one junction, a lane change, a left turn at the next; a car going the other way'});

%%%% No name: the list
if isempty(char(scenarioName))
    if nargout==0
        fprintf(1, '\nExample scenarios (fcn_AnimateCar3D_fillExampleScenario):\n');
        for ith_example = 1:numel(exampleList)
            fprintf(1, '  %-20s %s\n', exampleList(ith_example).Name, exampleList(ith_example).Description);
        end
    else
        scenario = exampleList;
    end
    return;
end
scenarioName = char(scenarioName);

%%%% The scene, its paths, and the ego's motion
egoRow = struct('instance','ego', 'role','ego', 'meshID','sample', 'color',[0.10 0.35 0.85]);
switch scenarioName
    case 'laneChange'
        roadPreset = 'twoLane';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Seed=options.Seed, FigNum=-1);
        % Blend from the lane's center to the next lane's center, smoothly
        % (a quintic in distance: no jump in heading or curvature)
        stayPath = centerlineOptions{1};
        otherPath = centerlineOptions{2};
        changeStart = 100;
        changeLength = 60;
        blendPosition = min(max((stayPath.S - changeStart)/changeLength, 0), 1);
        blend = 10*blendPosition.^3 - 15*blendPosition.^4 + 6*blendPosition.^5;
        pathXY = (1 - blend).*stayPath.XY + blend.*otherPath.XY;
        speed = 15;
        egoMotion = fcn_AnimateCar3D_fillPathMotion(pathXY, Speed=speed, Instance='ego', FigNum=-1);
        signalOn = egoMotion.Distance >= changeStart - 1.5*speed & egoMotion.Distance <= changeStart + changeLength;
        [egoMotion.LightStates(signalOn).TurnLeft] = deal(true);
    case 'curvyConstantSpeed'
        roadPreset = 'curvy';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Seed=options.Seed, FigNum=-1);
        egoMotion = fcn_AnimateCar3D_fillPathMotion(centerlineOptions{1}.XY, Speed=12, Instance='ego', FigNum=-1);
    case 'curvyVaryingSpeed'
        roadPreset = 'curvy';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Seed=options.Seed, FigNum=-1);
        pathXY = centerlineOptions{1}.XY;
        pathS = centerlineOptions{1}.S;
        egoMotion = fcn_AnimateCar3D_fillPathMotion(pathXY, Speed=fcn_INTERNAL_curveSpeeds(pathXY, pathS, 20, 2.0, 1.5, 2.0, 12), ...
            Instance='ego', FigNum=-1);
    case 'curvyHills'
        roadPreset = 'curvy';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Seed=options.Seed, Elevation='hilly', ...
            CrossSlope='banked', FigNum=-1);
        egoMotion = fcn_AnimateCar3D_fillPathMotion(centerlineOptions{1}.XY, Speed=12, Instance='ego', Road=road, FigNum=-1);
    case 'mountainRoad'
        roadPreset = 'mountain';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Seed=options.Seed, FigNum=-1);
        pathXY = centerlineOptions{1}.XY;
        pathS = centerlineOptions{1}.S;
        egoMotion = fcn_AnimateCar3D_fillPathMotion(pathXY, Speed=fcn_INTERNAL_curveSpeeds(pathXY, pathS, 20, 2.0, 1.5, 2.0, 12), ...
            Instance='ego', Road=road, BodyMotionScale=6, FigNum=-1);
    case 'raceCourse'
        roadPreset = 'raceCourse';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, FigNum=-1);
        pathXY = centerlineOptions{1}.XY;
        pathS = centerlineOptions{1}.S;
        egoMotion = fcn_AnimateCar3D_fillPathMotion(pathXY, Speed=fcn_INTERNAL_curveSpeeds(pathXY, pathS, 22, 6.0, 3.0, 6.0, 15), ...
            Instance='ego', FigNum=-1);
    case 'raceCourseHills'
        roadPreset = 'raceCourse';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Elevation='hilly', CrossSlope='banked', ...
            Seed=options.Seed, FigNum=-1);
        pathXY = centerlineOptions{1}.XY;
        pathS = centerlineOptions{1}.S;
        egoMotion = fcn_AnimateCar3D_fillPathMotion(pathXY, Speed=fcn_INTERNAL_curveSpeeds(pathXY, pathS, 22, 6.0, 3.0, 6.0, 15), ...
            Instance='ego', Road=road, FigNum=-1);
    case 'following'
        roadPreset = 'twoLane';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Length=400, Seed=options.Seed, FigNum=-1);
        pathXY = centerlineOptions{1}.XY; pathS = centerlineOptions{1}.S;
        % (the lead's distance over time: 14 m/s, braking to 5 m/s at 3 m/s^2
        % from 6 s, then speeding up at 2 m/s^2 to 14 m/s from 11 s)
        timeGrid = (-3:0.05:30)';
        leadSpeed = 14 - min(9, 3*max(0, timeGrid - 6)) + min(9, 2*max(0, timeGrid - 11));
        leadS = 30 + cumtrapz(timeGrid, leadSpeed) - interp1(timeGrid, cumtrapz(timeGrid, leadSpeed), 0);
        leadRows = pathS >= 30;
        leadMotion = fcn_AnimateCar3D_fillPathMotion(pathXY(leadRows,:), Speed=interp1(leadS, leadSpeed, pathS(leadRows), 'linear', 14), ...
            Instance='lead', FigNum=-1);
        % (the ego: where the lead was 1.5 s before, 9 m back: a 30 m gap at 14 m/s)
        egoS = interp1(timeGrid, leadS, timeGrid - 1.5, 'linear', 'extrap') - 9;
        egoSpeed = interp1(timeGrid, leadSpeed, timeGrid - 1.5, 'linear', 14);
        valid = egoS >= 0 & timeGrid >= 0;
        egoMotion = fcn_AnimateCar3D_fillPathMotion(pathXY(pathS <= 330,:), Speed=interp1(egoS(valid), egoSpeed(valid), pathS(pathS <= 330), 'linear', 14), ...
            Instance='ego', FigNum=-1);
        extraRows = struct('instance','lead', 'role','traffic', 'meshID','sample', 'color',[0.80 0.15 0.12]);
        extraMotions = {leadMotion};
    case 'passing'
        roadPreset = 'twoLane';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Length=320, Seed=options.Seed, FigNum=-1);
        pathXY = centerlineOptions{1}.XY; pathS = centerlineOptions{1}.S;
        [~, rightT] = fcn_AnimateCar3D_getRoadPoints(road, 10, LaneID=-1, FigNum=-1);
        [~, leftT] = fcn_AnimateCar3D_getRoadPoints(road, 10, LaneID=1, FigNum=-1);
        % (the ego's offset across the road: out over 25-65 m, back over 125-165 m)
        smoothStep = @(u) 3*min(max(u,0),1).^2 - 2*min(max(u,0),1).^3;
        egoT = rightT + (leftT - rightT)*(smoothStep((pathS - 25)/40) - smoothStep((pathS - 125)/40));
        passingPoints = fcn_AnimateCar3D_getRoadPoints(road, pathS, T=egoT, FigNum=-1);
        passingXY = passingPoints(:,1:2);
        keep = pathS <= 290;
        egoMotion = fcn_AnimateCar3D_fillPathMotion(passingXY(keep,:), Speed=15, Instance='ego', FigNum=-1);
        signalLeft = egoMotion.Distance >= 15 & egoMotion.Distance <= 65;
        signalRight = egoMotion.Distance >= 115 & egoMotion.Distance <= 165;
        [egoMotion.LightStates(signalLeft).TurnLeft] = deal(true);
        [egoMotion.LightStates(signalRight).TurnRight] = deal(true);
        slowRows = pathS >= 40 & pathS <= 185;   % (ends before the ego does)
        slowMotion = fcn_AnimateCar3D_fillPathMotion(pathXY(slowRows,:), Speed=8, Instance='slow', FigNum=-1);
        extraRows = struct('instance','slow', 'role','traffic', 'meshID','sample', 'color',[0.45 0.45 0.48]);
        extraMotions = {slowMotion};
    case 'pedestrianCrossing'
        roadPreset = 'urbanStreet';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Seed=options.Seed, FigNum=-1);
        pathXY = centerlineOptions{1}.XY; pathS = centerlineOptions{1}.S;
        crosswalks = road.Objects(strcmp({road.Objects.Type}, 'crosswalk'));
        crosswalkS = min([crosswalks([crosswalks.S] > 40).S]);
        crosswalkLength = crosswalks([crosswalks.S]==crosswalkS).Length;
        stopS = crosswalkS - crosswalkLength/2 - 2 - 2.4;      % (the front bumper 2 m before the crosswalk; half a car is about 2.4 m)
        egoSpeed = @(s) max(0.1, min(12, sqrt(2*2.5*abs(s - stopS))));   % (braking and pulling away at 2.5 m/s^2)
        % (the pedestrian: waits on the right sidewalk, 2 m from the curb,
        % starts across at 1.3 m/s 2 s before the ego would reach the stop,
        % and waits on the left sidewalk afterwards)
        [~, laneEdgeT] = fcn_AnimateCar3D_getRoadPoints(road, crosswalkS, LaneID=-1, LaneEdge='outer', FigNum=-1);
        laneWidth = abs(laneEdgeT);
        walkT = [-(laneWidth + 2), laneWidth + 2];
        walkSpeed = 1.3;
        arrival = fcn_AnimateCar3D_fillPathMotion(pathXY, Speed=egoSpeed, Instance='ego', FigNum=-1);
        arriveTime = arrival.Time(find(arrival.Distance >= stopS - 0.05, 1));
        walkStart = arriveTime - 2;
        clearTime = walkStart + (2 + laneWidth + 0.15 + 0.5)/walkSpeed;   % (past the center line by 0.5 m)
        egoMotion = fcn_AnimateCar3D_fillPathMotion(pathXY, Speed=egoSpeed, Stops=[stopS, max(1, clearTime - arriveTime + 0.5)], ...
            Instance='ego', FigNum=-1);
        walkDuration = diff(walkT)/walkSpeed;
        walkTime = unique([0; (walkStart:0.1:walkStart + walkDuration)'; walkStart + walkDuration; egoMotion.Time(end)]);
        walkerT = walkT(1) + walkSpeed*min(max(walkTime - walkStart, 0), walkDuration);
        walkPoints = fcn_AnimateCar3D_getRoadPoints(road, crosswalkS*ones(size(walkTime)), T=walkerT, FigNum=-1);
        walkerMotion = struct('Instance','walker', 'Time',walkTime, 'Pose',[walkPoints(:,1:2), walkPoints(:,3) + pi/2]);
        extraRows = struct('instance','walker', 'role','pedestrian', 'meshID','pedestrian', 'color',[0.85 0.25 0.20]);
        extraMotions = {walkerMotion};
    case 'urbanGrid'
        roadPreset = 'urbanGrid';
        [road, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset=roadPreset, Seed=options.Seed, FigNum=-1);
        optionNames = cellfun(@(o) o.Name, centerlineOptions, 'UniformOutput', false);
        chosen = centerlineOptions{strcmp(optionNames, 'straight, lane -1, left turn')};
        pathXY = chosen.XY; pathS = chosen.S;
        egoMotion = fcn_AnimateCar3D_fillPathMotion(pathXY, Speed=fcn_INTERNAL_curveSpeeds(pathXY, pathS, 12, 2.5, 2.0, 3.0, 10), ...
            Instance='ego', FigNum=-1);
        signalLeft = pathXY(:,1) > 110 & pathXY(:,1) < 175;            % (signal for the lane change and the turn)
        [egoMotion.LightStates(interp1(pathS, double(signalLeft), egoMotion.Distance, 'previous', 0) > 0.5).TurnLeft] = deal(true);
        % (the other car: from the exit road's far end, west along the main
        % street, straight through all three junctions)
        exitRoad = road.Roads(strcmp({road.Roads.Name}, 'exit'));
        otherOptions = fcn_AnimateCar3D_fillCenterlineOptions(road, Start=struct('Road',exitRoad.ID, 'LaneID',2, ...
            'S',exitRoad.Length, 'Direction',-1), FigNum=-1);
        otherNames = cellfun(@(o) o.Name, otherOptions, 'UniformOutput', false);
        westward = otherOptions{strcmp(otherNames, 'straight, straight, straight')};
        keepRows = westward.S <= 11*egoMotion.Time(end);                % (ends when the ego does)
        otherMotion = fcn_AnimateCar3D_fillPathMotion(westward.XY(keepRows,:), Speed=11, Instance='other', FigNum=-1);
        extraRows = struct('instance','other', 'role','traffic', 'meshID','sample', 'color',[0.10 0.40 0.25]);
        extraMotions = {otherMotion};
    otherwise
        error('Unknown example ''%s''; the examples are: %s', scenarioName, strjoin({'laneChange','curvyConstantSpeed','curvyVaryingSpeed','curvyHills','mountainRoad','raceCourse','raceCourseHills','following','passing','pedestrianCrossing','urbanGrid'}, ', '));
end
egoMotion = rmfield(egoMotion, {'Speed','Distance'});
if ~exist('extraRows', 'var')
    extraRows = struct('instance',{}, 'role',{}, 'meshID',{}, 'color',{});
    extraMotions = {};
end
for ith_extra = 1:numel(extraMotions)
    extraMotions{ith_extra} = rmfield(extraMotions{ith_extra}, intersect({'Speed','Distance'}, fieldnames(extraMotions{ith_extra}))); %#ok<AGROW>
end
allMotions = [{egoMotion}, extraMotions(:)'];
startTimes = cellfun(@(m) m.Time(1), allMotions); endTimes = cellfun(@(m) m.Time(end), allMotions);
description = exampleList(strcmp({exampleList.Name}, scenarioName)).Description;
scenario = struct('Name',scenarioName, 'Description',description, 'RoadPreset',roadPreset, 'Seed',options.Seed, ...
    'Road',road, 'CenterlineOptions',{centerlineOptions}, 'SceneList',fcn_AnimateCar3D_loadSceneList([egoRow, extraRows], FigNum=-1), ...
    'Motions',{allMotions}, 'Duration',max(endTimes) - min(startTimes), 'MeshIDs',{unique([{'sample'}, {extraRows.meshID}])}, ...
    'CameraPitch',fcn_INTERNAL_cameraPitch(scenarioName), 'TimeOfDay',lower(char(options.TimeOfDay)));

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

    fcn_AnimateCar3D_fillCenterlineOptions(scenario.Road, FigNum=figNum);
    hold on;
    plot3(egoMotion.Pose(:,1), egoMotion.Pose(:,2), 0.5*ones(size(egoMotion.Time)), '-', 'LineWidth', 1.5, ...
        'Color', [0.10 0.10 0.10], 'DisplayName', 'ego motion');
    title(sprintf('%s: %s', scenario.Name, scenario.Description), 'Interpreter','none');
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

%% fcn_INTERNAL_cameraPitch
function cameraPitch = fcn_INTERNAL_cameraPitch(scenarioName)
% How fcn_AnimateCar3D_playScenario tilts the camera for this example:
% with the road's grade at the camera on the mountain road, else level
cameraPitch = 'none';
if strcmp(scenarioName, 'mountainRoad')
    cameraPitch = 'road';
end
end % Ends fcn_INTERNAL_cameraPitch

%% fcn_INTERNAL_curveSpeeds
function pathSpeed = fcn_INTERNAL_curveSpeeds(pathXY, pathS, topSpeed, sidewaysLimit, speedUpLimit, brakeLimit, startSpeed)
% Speeds along a path: no more than sidewaysLimit m/s^2 sideways in the
% curves (speed^2 * curvature), no more than topSpeed, and reached by
% speeding up at speedUpLimit and braking at brakeLimit (m/s^2)
heading = unwrap(atan2(gradient(pathXY(:,2)), gradient(pathXY(:,1))));
curvature = movmean(abs(gradient(heading)./gradient(pathS)), 9);
pathSpeed = min(topSpeed, sqrt(sidewaysLimit./max(curvature, 1e-6)));
pathSpeed(1) = min(pathSpeed(1), startSpeed);
stepLengths = diff(pathS);
for ith_point = 2:numel(pathSpeed)                      % (speeding up)
    pathSpeed(ith_point) = min(pathSpeed(ith_point), sqrt(pathSpeed(ith_point-1)^2 + 2*speedUpLimit*stepLengths(ith_point-1)));
end
for ith_point = numel(pathSpeed)-1:-1:1                 % (braking, looking ahead)
    pathSpeed(ith_point) = min(pathSpeed(ith_point), sqrt(pathSpeed(ith_point+1)^2 + 2*brakeLimit*stepLengths(ith_point)));
end
end % Ends fcn_INTERNAL_curveSpeeds
