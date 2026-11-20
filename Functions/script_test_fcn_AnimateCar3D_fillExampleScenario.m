% script_test_fcn_AnimateCar3D_fillExampleScenario.m
% Tests fcn_AnimateCar3D_fillExampleScenario
% Fills one of the example scenarios: a scene, its paths, and the objects' motions.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillExampleScenario
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillExampleScenario
%   % * (fill in items here)


%% Set up the workspace
close all


%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: The lane change
figNum = 10001;
titleString = sprintf('DEMO case: The lane change');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

scenario = fcn_AnimateCar3D_fillExampleScenario('laneChange', FigNum=figNum);

% Check variable types
assert(isstruct(scenario) && iscell(scenario.Motions) && iscell(scenario.CenterlineOptions));

% Check variable sizes
assert(isscalar(scenario.Motions) && numel(scenario.SceneList)==1);

% Check variable values: from the right lane (y = -1.8) to the left lane
% (y = +1.8) between 100 m and 160 m; heading back to straight after; the
% turn signal on before and during the change
motion = scenario.Motions{1};
assert(all(abs(motion.Pose(motion.Pose(:,1) < 100,2) + 1.8) < 1e-9) && all(abs(motion.Pose(motion.Pose(:,1) > 160,2) - 1.8) < 1e-9));
assert(max(abs(motion.Pose(:,3))) < 0.15 && abs(motion.Pose(end,3)) < 1e-9);
signalTimes = motion.Time([motion.LightStates.TurnLeft]);
assert(abs(signalTimes(1) - (100/15 - 1.5)) < 0.06 && abs(signalTimes(end) - 160/15) < 0.06);
assert(abs(scenario.Duration - 300/15) < 0.06);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: The list of examples
figNum = 20001;
titleString = sprintf('TEST case: The list of examples');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

exampleList = fcn_AnimateCar3D_fillExampleScenario();
assert(isequal({exampleList.Name}, {'laneChange','curvyConstantSpeed','curvyVaryingSpeed','curvyHills','mountainRoad'}));
printed = evalc('fcn_AnimateCar3D_fillExampleScenario()');
assert(contains(printed, 'curvyVaryingSpeed'));

%% TEST case: The curvy road, constant and varying speed
figNum = 20002;
titleString = sprintf('TEST case: The curvy road, constant and varying speed');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

constant = fcn_AnimateCar3D_fillExampleScenario('curvyConstantSpeed');
varying = fcn_AnimateCar3D_fillExampleScenario('curvyVaryingSpeed');
assert(norm(constant.Motions{1}.Pose(end,1:2) - varying.Motions{1}.Pose(end,1:2)) < 1e-6);   % (the same path)
speedConstant = hypot(diff(constant.Motions{1}.Pose(:,1)), diff(constant.Motions{1}.Pose(:,2)))./diff(constant.Motions{1}.Time);
assert(all(abs(speedConstant - 12) < 0.05));
motion = varying.Motions{1};
speeds = hypot(diff(motion.Pose(:,1)), diff(motion.Pose(:,2)))./diff(motion.Time);
assert(max(speeds) > 16 && min(speeds) < 11);                            % (fast on straights, slower in curves)
assert(any(strcmp({motion.LightStates.Tail}, 'brake')) && any(strcmp({motion.LightStates.Tail}, 'on')));
% (no more than about 2 m/s^2 sideways)
yawRate = gradient(unwrap(motion.Pose(:,end)))./gradient(motion.Time);
speedPerRow = [speeds; speeds(end)];
assert(max(abs(yawRate(2:end-1).*speedPerRow(2:end-1))) < 2.5);

%% TEST case: On hills: the curvy road with hills, and the mountain road
figNum = 20003;
titleString = sprintf('TEST case: On hills: the curvy road with hills, and the mountain road');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

hills = fcn_AnimateCar3D_fillExampleScenario('curvyHills');
assert(size(hills.Motions{1}.Pose,2)==6 && max(abs(hills.Motions{1}.Pose(:,3))) > 2);
mountain = fcn_AnimateCar3D_fillExampleScenario('mountainRoad');
motion = mountain.Motions{1};
assert(strcmp(mountain.RoadPreset,'mountain') && size(motion.Pose,2)==6 && max(motion.Pose(:,3)) > 50);
assert(strcmp(mountain.CameraPitch,'road') && strcmp(hills.CameraPitch,'none'));
assert(max(abs(motion.BodyRoll)) > 6*deg2rad(4)*1.5/9.81 && max(motion.BodyPitch) > 0 && min(motion.BodyPitch) < 0);   % (exaggerated body motion)
speeds = hypot(diff(motion.Pose(:,1)), diff(motion.Pose(:,2)))./diff(motion.Time);
assert(min(speeds) < 8 && max(speeds) > 15);                             % (slow in hairpins)

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
scenario = fcn_AnimateCar3D_fillExampleScenario('curvyConstantSpeed', FigNum=[]);
assert(strcmp(scenario.RoadPreset,'curvy'));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
scenario = fcn_AnimateCar3D_fillExampleScenario('curvyConstantSpeed', FigNum=-1);
assert(strcmp(scenario.RoadPreset,'curvy'));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: An example that does not exist
if 1==0
    fcn_AnimateCar3D_fillExampleScenario('rollerCoaster');
end
