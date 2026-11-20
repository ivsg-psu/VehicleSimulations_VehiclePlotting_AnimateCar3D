% script_test_fcn_AnimateCar3D_fillPathMotion.m
% Tests fcn_AnimateCar3D_fillPathMotion
% Makes a vehicle's motion from a path and a speed.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillPathMotion
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_fillPathMotion
%   % * (fill in items here)


%% Set up the workspace
close all

straightPath = [(0:1:100)', zeros(101,1)];
circlePath = 20*[cos(linspace(-pi/2, pi/2, 200))', sin(linspace(-pi/2, pi/2, 200))' + 1];

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

%% DEMO case: A curvy road's lane at 12 m/s
figNum = 10001;
titleString = sprintf('DEMO case: A curvy road''s lane at 12 m/s');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[~, centerlineOptions] = fcn_AnimateCar3D_fillRoad(Preset='curvy');
motion = fcn_AnimateCar3D_fillPathMotion(centerlineOptions{1}.XY, Speed=12, FigNum=figNum);

% Check variable types
assert(isstruct(motion) && ischar(motion.Instance) && isstruct(motion.LightStates));

% Check variable sizes
K = numel(motion.Time);
assert(isequal(size(motion.Pose), [K 3]) && isequal(size(motion.WheelSpin), [K 4]) && isequal(size(motion.SteerAngle), [K 2]));

% Check variable values: 12 m/s throughout; the end of the path reached
assert(all(abs(motion.Speed - 12) < 1e-9));
assert(abs(motion.Distance(end) - centerlineOptions{1}.S(end)) < 1e-6);
assert(norm(motion.Pose(end,1:2) - centerlineOptions{1}.XY(end,:)) < 1e-6);

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

%% TEST case: A straight path: time, spin, and no steering
figNum = 20001;
titleString = sprintf('TEST case: A straight path: time, spin, and no steering');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

motion = fcn_AnimateCar3D_fillPathMotion(straightPath, Speed=10, TimeStep=0.1, StartTime=2, Instance='car1');
assert(abs(motion.Time(1) - 2) < 1e-12 && abs(motion.Time(end) - 12) < 1e-9 && strcmp(motion.Instance,'car1'));
spec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
assert(abs(motion.WheelSpin(end,1) - 100/(spec.TireDiameter/2)) < 1e-9);
assert(all(abs(motion.SteerAngle(:)) < 1e-9) && all(abs(motion.Pose(:,3)) < 1e-12));

%% TEST case: A circle of radius 20 m: Ackermann steering, inside tire more
figNum = 20002;
titleString = sprintf('TEST case: A circle of radius 20 m: Ackermann steering, inside tire more');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

motion = fcn_AnimateCar3D_fillPathMotion(circlePath, Speed=8);
middle = round(numel(motion.Time)/2);
bicycleAngle = atan(spec.Wheelbase/20);
assert(motion.SteerAngle(middle,1) > bicycleAngle && motion.SteerAngle(middle,2) < bicycleAngle);   % (left turn: left tire inside)
assert(abs(mean(motion.SteerAngle(middle,:)) - bicycleAngle) < 0.01);
% (the body leans out of the turn: 8^2/20 = 3.2 m/s^2 sideways, 4 deg per g)
assert(abs(motion.BodyRoll(middle) - deg2rad(4)*3.2/9.81) < 0.002 && all(abs(motion.BodyPitch(2:end-1)) < 1e-6));
exaggerated = fcn_AnimateCar3D_fillPathMotion(circlePath, Speed=8, BodyMotionScale=3, FigNum=-1);
assert(abs(exaggerated.BodyRoll(middle) - 3*motion.BodyRoll(middle)) < 1e-9);

%% TEST case: Speed as values or a function; brake lights when slowing
figNum = 20003;
titleString = sprintf('TEST case: Speed as values or a function; brake lights when slowing');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

slowing = fcn_AnimateCar3D_fillPathMotion(straightPath, Speed=@(s) 15 - 0.1*s);
assert(abs(slowing.Speed(1) - 15) < 1e-9 && abs(slowing.Speed(end) - 5) < 1e-6);
assert(all(strcmp({slowing.LightStates(2:end-1).Tail}, 'brake')));
middle = round(numel(slowing.Time)/2);
assert(slowing.BodyPitch(middle) > 0 && all(abs(slowing.BodyRoll) < 1e-9));   % (nose down when braking)
byPoint = fcn_AnimateCar3D_fillPathMotion(straightPath, Speed=linspace(5, 10, 101)');
assert(all(strcmp({byPoint.LightStates.Tail}, 'on')) && abs(byPoint.Speed(end) - 10) < 1e-6);

%% TEST case: On a mountain road: height, pitch, and roll from the road
figNum = 20009;
titleString = sprintf('TEST case: On a mountain road: height, pitch, and roll from the road');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

[mountainRoad, mountainOptions] = fcn_AnimateCar3D_fillRoad(Preset='mountain', FigNum=-1);
motion = fcn_AnimateCar3D_fillPathMotion(mountainOptions{1}.XY, Speed=15, TimeStep=0.5, Road=mountainRoad, FigNum=-1);
assert(size(motion.Pose,2)==6);
roadZ = fcn_AnimateCar3D_getRoadHeight(mountainRoad, motion.Pose(:,1:2));
assert(max(abs(motion.Pose(:,3) - roadZ)) < 1e-9);
climbing = motion.Distance > 100 & motion.Distance < 0.4*motion.Distance(end);
descending = motion.Distance > 0.6*motion.Distance(end) & motion.Distance < motion.Distance(end) - 100;
assert(all(motion.Pose(climbing,5) < 0) && all(motion.Pose(descending,5) > 0));    % (nose up climbing, down descending)
assert(max(abs(motion.Pose(:,4))) > 0.02 && max(abs(motion.Pose(:,4))) < atan(0.06) + 0.01);   % (rolls on the banking)
flatMotion = fcn_AnimateCar3D_fillPathMotion(mountainOptions{1}.XY, Speed=15, TimeStep=0.5, FigNum=-1);
assert(size(flatMotion.Pose,2)==3 && max(abs(flatMotion.Pose(:,[1 2 3]) - motion.Pose(:,[1 2 6])), [], 'all') < 1e-12);

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
motion = fcn_AnimateCar3D_fillPathMotion(straightPath, FigNum=[]);
assert(abs(motion.Time(end) - 10) < 1e-9);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
motion = fcn_AnimateCar3D_fillPathMotion(straightPath, FigNum=-1);
assert(abs(motion.Time(end) - 10) < 1e-9);

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

%% FAIL case: A path of one point
if 1==0
    fcn_AnimateCar3D_fillPathMotion([0 0]);
end
