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
% Each vehicle is the CarMesh3D sample car ('sample'), named 'ego'.
%
% FORMAT:
%
%       scenario = fcn_AnimateCar3D_fillExampleScenario(scenarioName,...
%           (Seed=seed), (FigNum=figNum))
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

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_AnimateCar3D_fillExampleScenario
%   % * Multi-object examples: passing, following, stopping for a pedestrian at a crosswalk



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_ANIMATECAR3D_FLAG_CHECK_INPUTS environment variable.
arguments

    scenarioName = ''
    options.Seed = 1              % the scene's random seed
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
        exampleNames = {'laneChange','curvyConstantSpeed','curvyVaryingSpeed'};
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


exampleList = struct('Name',{'laneChange','curvyConstantSpeed','curvyVaryingSpeed'}, ...
    'Description',{'One vehicle on the two-lane road: a lane change to the left at a constant 15 m/s', ...
                   'One vehicle on the curvy road, following its lane at a constant 12 m/s', ...
                   'One vehicle on the curvy road, following its lane, slowing for the curves'});

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
end
egoMotion = rmfield(egoMotion, {'Speed','Distance'});
description = exampleList(strcmp({exampleList.Name}, scenarioName)).Description;
scenario = struct('Name',scenarioName, 'Description',description, 'RoadPreset',roadPreset, 'Seed',options.Seed, ...
    'Road',road, 'CenterlineOptions',{centerlineOptions}, 'SceneList',fcn_AnimateCar3D_loadSceneList(egoRow, FigNum=-1), ...
    'Motions',{{egoMotion}}, 'Duration',egoMotion.Time(end) - egoMotion.Time(1), 'MeshIDs',{{'sample'}});

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
