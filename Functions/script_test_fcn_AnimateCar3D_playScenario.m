% script_test_fcn_AnimateCar3D_playScenario.m
% Tests fcn_AnimateCar3D_playScenario
% Plays a scenario held in memory in one call.
%
% Run script_demo_AnimateCar3D first, so that CarMesh3D is on the path.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_playScenario
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_AnimateCar3D_playScenario
%   % * (fill in items here)


%% Set up the workspace
close all

scenario = fcn_AnimateCar3D_fillExampleScenario('laneChange', FigNum=-1);

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

%% DEMO case: The lane change, with the camera following the ego
figNum = 10001;
titleString = sprintf('DEMO case: The lane change, with the camera following the ego');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

playResult = fcn_AnimateCar3D_playScenario(scenario, TimeStep=0.5, FigNum=figNum);

% Check variable types
assert(isstruct(playResult) && isstruct(playResult.Catalog) && isgraphics(playResult.Axes, 'axes'));

% Check variable sizes
assert(numel(playResult.Times)==numel(0:0.5:20));

% Check variable values: the camera ends behind and to the right of the
% ego at its last pose (300, 1.8); the centerline options are drawn; a
% caption with the name
cameraPosition = campos(playResult.Axes);
assert(norm(cameraPosition - [300-22, 1.8-16, 10]) < 0.5);           % (within the catalog's pose rounding)
assert(numel(findobj(playResult.Axes, 'Tag', 'AnimateCar3D centerline option'))==2);
caption = findall(playResult.Figure, 'Tag', 'AnimateCar3D scenario caption');
assert(contains(caption.String{1}, 'laneChange: t = 20.0 s') && contains(caption.String{1}, 'ego speed 15.0 m/s'));

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

%% TEST case: A GIF, no options drawn, no caption
figNum = 20001;
titleString = sprintf('TEST case: A GIF, no options drawn, no caption');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

gifFile = [tempname '.gif'];
playResult = fcn_AnimateCar3D_playScenario(scenario, TimeStep=2, ShowOptions=false, Caption=false, GifFile=gifFile, FigNum=figNum);
assert(playResult.GifFrames==11 && numel(imfinfo(gifFile))==11);
assert(isempty(findobj(playResult.Axes, 'Tag', 'AnimateCar3D centerline option')) && ...
    isempty(findall(playResult.Figure, 'Tag', 'AnimateCar3D scenario caption')));
delete(gifFile);

%% TEST case: Another camera, kept as set ([])
figNum = 20002;
titleString = sprintf('TEST case: Another camera, kept as set ([])');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

playResult = fcn_AnimateCar3D_playScenario(scenario, TimeStep=5, CameraSettings=fcn_CarMesh3D_fillCameraSettings(Mode='chase', FigNum=-1), FigNum=figNum);
chasePosition = campos(playResult.Axes);
assert(chasePosition(1) < 300 && abs(chasePosition(2) - 1.8) < 1e-6);   % (chase: straight behind)

%% Fast Mode Tests

%% Basic fast mode - FAST MODE (draws in the current figure)
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum);
playResult = fcn_AnimateCar3D_playScenario(scenario, TimeStep=10, FigNum=-1);
assert(isequal(playResult.Figure.Number, figNum));
close(figNum);

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

%% FAIL case: Not a scenario
if 1==0
    fcn_AnimateCar3D_playScenario(struct('Road',[]));
end
